//
//  AllObjects.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2017-03-27.
//  Copyright © 2017 nonstrict. All rights reserved.
//

import Foundation

public enum AllObjectsError: Error {
  case fieldMissing(key: String)
  case wrongType(key: String)
  case objectMissing(id: Guid)
}

public enum ReferenceError: Error {
  case deadReference(type: String, id: Guid, keyPath: String, ref: Guid)
  case orphanObject(type: String, id: Guid)
}

public struct Guid : Hashable, Comparable {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }

  static public func <(lhs: Guid, rhs: Guid) -> Bool {
    return lhs.value < rhs.value
  }
}

public struct Reference<Value : PBXObject> : Hashable, Comparable {
  internal let allObjects: AllObjects

  public let id: Guid

  internal init(allObjects: AllObjects, id: Guid) {
    self.allObjects = allObjects
    self.id = id
  }

  public var value: Value? {
    guard let object = allObjects.objects[id] as? Value else { return nil }

    return object
  }

  static public func ==(lhs: Reference<Value>, rhs: Reference<Value>) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id.value)
  }

  static public func <(lhs: Reference<Value>, rhs: Reference<Value>) -> Bool {
    return lhs.id < rhs.id
  }
}

public class AllObjects {
  internal var objects: [Guid: PBXObject] = [:]
  internal var fullFilePaths: [Guid: Path] = [:]
  internal var refCounts: [Guid: Int] = [:]

  internal func createReferences<Value>(ids: [Guid]) -> [Reference<Value>] {
    return ids.map(createReference)
  }

  internal func createOptionalReferences<Value>(ids: [Guid]?) -> [Reference<Value>]? {
    ids.map { createReferences(ids: $0) }
  }

  internal func createOptionalReference<Value>(id: Guid?) -> Reference<Value>? {
    guard let id = id else { return nil }
    return createReference(id: id)
  }

  internal func createReference<Value>(id: Guid) -> Reference<Value> {
    refCounts[id, default: 0] += 1

    let ref: Reference<Value> = Reference(allObjects: self, id: id)
    return ref
  }

  internal func createReference<Value>(value: Value) -> Reference<Value> {
    refCounts[value.id, default: 0] += 1

    objects[value.id] = value
    let ref: Reference<Value> = Reference(allObjects: self, id: value.id)
    return ref
  }

  internal func removeReference<Value>(_ ref: Reference<Value>?) {
    guard let ref = ref else { return }
    guard let count = refCounts[ref.id], count > 0 else {
      assertionFailure("refCount[\(ref.id)] is \(refCounts[ref.id]?.description ?? "nil")")
      return
    }

    refCounts[ref.id] = count - 1

    if count == 1 {
      objects[ref.id] = nil
    }
  }

  internal func createFreshGuid(from original: Guid) -> Guid {
    // If original isn't a PBXIdentifier, just return a UUID
    guard let identifier = PBXIdentifier(string: original.value) else {
      return Guid(UUID().uuidString)
    }

    // Ten attempts at generating fresh identifier
    for _ in 0..<10 {
      let guid = Guid(identifier.createFreshIdentifier().stringValue)

      if objects.keys.contains(guid) {
        continue
      }

      return guid
    }

    // Fallback to UUID
    return Guid(UUID().uuidString)
  }

  internal static func createObject(_ id: Guid, fields: Fields, allObjects: AllObjects) throws -> PBXObject {
    let isa = try fields.string("isa")
    if let type = types[isa] {
      return try type.init(id: id, fields: fields, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return try PBXObject(id: id, fields: fields, allObjects: allObjects)
  }

  internal func validateReferences() throws {

    let refKeys = Set(refCounts.keys)
    let objKeys = Set(objects.keys)

    let deadRefs = refKeys.subtracting(objKeys).sorted()
    let orphanObjs = objKeys.subtracting(refKeys).sorted()

    var errors: [ReferenceError] = []

    for (id, object) in objects {
      for (path, guid) in findGuids(object) {

        if !objKeys.contains(guid) {
          let error = ReferenceError.deadReference(type: object.isa, id: id, keyPath: path, ref: guid)
          errors.append(error)
        }
      }
    }

    for id in orphanObjs {
      guard let object = objects[id] else { continue }

      let error = ReferenceError.orphanObject(type: object.isa, id: id)
      errors.append(error)
    }

    if !deadRefs.isEmpty || !orphanObjs.isEmpty {
      if deadRefs.count + orphanObjs.count != errors.count {
        assertionFailure("Error count doesn't equal dead ref count + orphan object count")
      }
      throw ProjectFileError.internalInconsistency(errors)
    }
  }
}

private func referenceGuid(_ obj: Any) -> Guid? {

  // Should figure out a better way to test obj is of type Reference<T>
  let m = Mirror(reflecting: obj)
  guard m.displayStyle == Mirror.DisplayStyle.`struct` else { return nil }

  return m.descendant("id") as? Guid
}

private func findGuids(_ obj: Any, parentPath: String? = nil) -> [(String, Guid)] {

  var result: [(String, Guid)] = []

  var objMirror: Mirror? = Mirror(reflecting: obj)
  while let mirror = objMirror {
    defer { objMirror = objMirror?.superclassMirror }

    for child in mirror.children {

      guard let label = child.label else { continue }
      let path = parentPath.map { "\($0).\(label)" } ?? label
      let value = child.value

      let m = Mirror(reflecting: value)
      if m.displayStyle == Mirror.DisplayStyle.`struct` {
        if let guid = referenceGuid(value) {
          result.append((path, guid))
        }
      }
      if m.displayStyle == Mirror.DisplayStyle.optional
        || m.displayStyle == Mirror.DisplayStyle.collection
      {
        for item in m.children {
          if let guid = referenceGuid(item.value) {
            result.append((path, guid))
          }
        }
      }
      if m.displayStyle == Mirror.DisplayStyle.optional {
        if let element = m.children.first {
          for item in Mirror(reflecting: element.value).children {
            let vals = findGuids(item.value, parentPath: path)
            result.append(contentsOf: vals)
          }
        }
      }
    }
  }

  return result
}

private let types: [String: PBXObject.Type] = [
  "PBXProject": PBXProject.self,
  "PBXContainerItemProxy": PBXContainerItemProxy.self,
  "PBXBuildFile": PBXBuildFile.self,
  "PBXCopyFilesBuildPhase": PBXCopyFilesBuildPhase.self,
  "PBXFrameworksBuildPhase": PBXFrameworksBuildPhase.self,
  "PBXHeadersBuildPhase": PBXHeadersBuildPhase.self,
  "PBXResourcesBuildPhase": PBXResourcesBuildPhase.self,
  "PBXShellScriptBuildPhase": PBXShellScriptBuildPhase.self,
  "PBXSourcesBuildPhase": PBXSourcesBuildPhase.self,
  "PBXBuildRule": PBXBuildRule.self,
  "PBXBuildStyle": PBXBuildStyle.self,
  "XCBuildConfiguration": XCBuildConfiguration.self,
  "PBXAggregateTarget": PBXAggregateTarget.self,
  "PBXLegacyTarget": PBXLegacyTarget.self,
  "PBXNativeTarget": PBXNativeTarget.self,
  "PBXTargetDependency": PBXTargetDependency.self,
  "XCSwiftPackageProductDependency": XCSwiftPackageProductDependency.self,
  "XCRemoteSwiftPackageReference": XCRemoteSwiftPackageReference.self,
  "XCLocalSwiftPackageReference": XCLocalSwiftPackageReference.self,
  "XCConfigurationList": XCConfigurationList.self,
  "PBXReference": PBXReference.self,
  "PBXReferenceProxy": PBXReferenceProxy.self,
  "PBXFileReference": PBXFileReference.self,
  "PBXGroup": PBXGroup.self,
  "PBXVariantGroup": PBXVariantGroup.self,
  "PBXFileSystemSynchronizedRootGroup": PBXFileSystemSynchronizedRootGroup.self,
  "PBXFileSystemSynchronizedBuildFileExceptionSet": PBXFileSystemSynchronizedBuildFileExceptionSet.self,
  "XCVersionGroup": XCVersionGroup.self
]
