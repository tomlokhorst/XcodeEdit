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

extension Dictionary where Key == Guid, Value == AnyObject {
  mutating func set<Value>(key: Guid, reference: Reference<Value>?) {
    if let reference = reference {
      self[key] = reference.id.value as NSString
    }
    else {
      self[key] = nil
    }
  }
}

extension Dictionary where Key == String {

  func id(_ key: String) throws -> Guid {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return Guid(value)
  }

  func optionalId(_ key: String) throws -> Guid? {
    guard let val = self[key] else {
      return nil
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return Guid(value)
  }

  func ids(_ key: String) throws -> [Guid] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [String] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value.map(Guid.init)
  }

  func bool(_ key: String) throws -> Bool {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    switch value {
    case "0":
      return false

    case "1":
      return true

    default:
      throw AllObjectsError.wrongType(key: key)
    }
  }

  func optionalString(_ key: String) throws -> String? {
    guard let val = self[key] else {
      return nil
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func string(_ key: String) throws -> String {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func strings(_ key: String) throws -> [String] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [String] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func fields(_ key: String) throws -> [Fields] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [Fields] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

}
