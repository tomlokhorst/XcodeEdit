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

  static public func ==(lhs: Guid, rhs: Guid) -> Bool {
    return lhs.value == rhs.value
  }

  public var hashValue: Int {
    return value.hashValue
  }

  static public func <(lhs: Guid, rhs: Guid) -> Bool {
    return lhs.value < rhs.value
  }
}

public struct Reference<Value : PBXObject> {
  let allObjects: AllObjects

  public let id: Guid
  public var value: Value? {
    guard let object = allObjects.objects[id] as? Value else { return nil }

    return object
  }
}

public class AllObjects {
  var objects: [Guid: PBXObject] = [:]
  var fullFilePaths: [Guid: Path] = [:]
  var refCounts: [Guid: Int] = [:]

  func createReferences<Value: PBXObject>(ids: [Guid]) -> [Reference<Value>] {
    return ids.map(createReference)
  }

  func createOptionalReference<Value: PBXObject>(id: Guid?) -> Reference<Value>? {
    guard let id = id else { return nil }
    return createReference(id: id)
  }

  func createReference<Value: PBXObject>(id: Guid) -> Reference<Value> {
    let count = refCounts[id] ?? 0
    refCounts[id] = count + 1

    let ref: Reference<Value> = Reference(allObjects: self, id: id)
    return ref
  }

  func createReference<Value: PBXObject>(value: Value) -> Reference<Value> {
    let count = refCounts[value.id] ?? 0
    refCounts[value.id] = count + 1

    objects[value.id] = value
    let ref: Reference<Value> = Reference(allObjects: self, id: value.id)
    return ref
  }

  func removeReference<Value: PBXObject>(_ ref: Reference<Value>?) {
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

  static func createObject(_ id: Guid, fields: Fields, allObjects: AllObjects) throws -> PBXObject {
    let isa = try fields.string("isa")
    if let type = types[isa] {
      return try type.init(id: id, fields: fields, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return try PBXObject(id: id, fields: fields, allObjects: allObjects)
  }

  func validateReferences() throws {

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


private func findGuids(_ obj: Any) -> [(String, Guid)] {

  var result: [(String, Guid)] = []

  for child in Mirror(reflecting: obj).children {

    guard let label = child.label else { continue }
    let value = child.value

    let m = Mirror(reflecting: value)
    if m.displayStyle == Mirror.DisplayStyle.`struct` {
      if let guid = referenceGuid(value) {
        result.append((label, guid))
      }
    }
    if m.displayStyle == Mirror.DisplayStyle.optional
      || m.displayStyle == Mirror.DisplayStyle.collection
    {
      for item in m.children {
        if let guid = referenceGuid(item.value) {
          result.append((label, guid))
        }
      }
    }
    if m.displayStyle == Mirror.DisplayStyle.optional {
      if let element = m.children.first {
        for item in Mirror(reflecting: element.value).children {
          let vals = findGuids(item.value)
            .map { (l, g) in ("\(label).\(l)", g) }
          result.append(contentsOf: vals)
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
  "PBXBuildStyle": PBXBuildStyle.self,
  "XCBuildConfiguration": XCBuildConfiguration.self,
  "PBXAggregateTarget": PBXAggregateTarget.self,
  "PBXNativeTarget": PBXNativeTarget.self,
  "PBXTargetDependency": PBXTargetDependency.self,
  "XCConfigurationList": XCConfigurationList.self,
  "PBXReference": PBXReference.self,
  "PBXReferenceProxy": PBXReferenceProxy.self,
  "PBXFileReference": PBXFileReference.self,
  "PBXGroup": PBXGroup.self,
  "PBXVariantGroup": PBXVariantGroup.self,
  "XCVersionGroup": XCVersionGroup.self
]
