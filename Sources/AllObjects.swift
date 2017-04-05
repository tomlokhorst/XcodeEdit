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
  case invalidValue(key: String, value: String)
  case objectMissing(key: String)
}

public struct Reference<Value : PBXObject> {
  let allObjects: AllObjects

  public let id: String
  public var value: Value? {
    return try? allObjects.object2(id)
  }
}

public class AllObjects {
  var objects: [String: PBXObject] = [:]
  var fullFilePaths: [String: Path] = [:]
  var refCounts: [GuidKey: Int] = [:]

  func createReference<Value: PBXObject>(id: GuidKey) -> Reference<Value> {
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

  func removeReference<Value: PBXObject>(_ ref: Reference<Value>) {
    guard let count = refCounts[ref.id], count > 0 else {
      assertionFailure("refCount[\(ref.id)] is \(refCounts[ref.id]?.description ?? "nil")")
      return
    }

    refCounts[ref.id] = count - 1

    if count == 1 {
      objects[ref.id] = nil
    }
  }

  func object<T : PBXObject>(_ key: String) -> T {
    let obj = objects[key]!
    if let t = obj as? T {
      return t
    }

    return try! T(id: key, fields: obj.fields, allObjects: self)
  }

  func object2<T : PBXObject>(_ key: String?) throws -> T? {
    guard let key = key else { return nil }

    return try object2(key)
  }

  func object2<T : PBXObject>(_ key: String) throws -> T {
    guard let obj = objects[key] else {
      throw AllObjectsError.objectMissing(key: key)
    }
    guard let object = obj as? T else {
      throw AllObjectsError.wrongType(key: key)
    }

    return object
  }

  func objects2<T : PBXObject>(_ keys: [String]) throws -> [T] {
    return try keys.map(object2)
  }

  static func createObject(_ id: String, fields: Fields, allObjects: AllObjects) throws -> PBXObject {
    guard let isa = fields["isa"] as? String else {
      throw AllObjectsError.fieldMissing(key: "isa")
    }

    if let type = types[isa] {
      return try type.init(id: id, fields: fields, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return try! PBXObject(id: id, fields: fields, allObjects: allObjects)
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


typealias GuidKey = String

extension Dictionary where Key == String {

  internal func value<T>(_ key: String) throws -> T {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? T else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  internal func key(_ key: String) throws -> GuidKey {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? GuidKey else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  internal func keys(_ key: String) throws -> [GuidKey] {
    guard let val = self[key] as? [GuidKey] else {
      throw AllObjectsError.fieldMissing(key: key)
    }

    return val
  }

  internal func field<T>(_ key: String) throws -> T {
    guard let val = self[key] as? T else {
      throw AllObjectsError.fieldMissing(key: key)
    }

    return val
  }

  internal func optionalField<T>(_ key: String) -> T? {
    return self[key] as? T
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

  func string2(_ key: String) throws -> String {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
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

  func optionalKey(_ key: String) throws -> GuidKey? {
    guard let val = self[key] else {
      return nil
    }
    guard let value = val as? GuidKey else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func strings2(_ key: String) throws -> [String] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [String] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func string(_ key: String) -> String? {
    return self[key] as? String
  }

  func strings(_ key: String) -> [String]? {
    return self[key] as? [String]
  }
}
