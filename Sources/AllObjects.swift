//
//  AllObjects.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2017-03-27.
//  Copyright © 2017 nonstrict. All rights reserved.
//

import Foundation

enum AllObjectsError: Error {
  case fieldMissing(key: String)
  case invalidValue(key: String, value: String)
  case objectMissing(key: String)
}


public class AllObjects {
  var dict: [String: PBXObject] = [:]
  var fullFilePaths: [String: Path] = [:]

  func object<T : PBXObject>(_ key: String) -> T {
    let obj = dict[key]!
    if let t = obj as? T {
      return t
    }

    return T(id: key, fields: obj.fields, allObjects: self)
  }

  static func createObject(_ id: String, fields: Fields, allObjects: AllObjects) throws -> PBXObject {
    guard let isa = fields["isa"] as? String else {
      throw AllObjectsError.fieldMissing(key: "isa")
    }

    if let type = types[isa] {
      return type.init(id: id, fields: fields, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return PBXObject(id: id, fields: fields, allObjects: allObjects)
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

extension Dictionary {
  internal func key(_ keyString: String) throws -> GuidKey {
    guard let key = keyString as? Key, let val = self[key] as? GuidKey else {
      throw AllObjectsError.fieldMissing(key: keyString)
    }

    return val
  }

  internal func keys(_ keyString: String) throws -> [GuidKey] {
    guard let key = keyString as? Key, let val = self[key] as? [GuidKey] else {
      throw AllObjectsError.fieldMissing(key: keyString)
    }

    return val
  }

  internal func field<T>(_ keyString: String) throws -> T {
    guard let key = keyString as? Key, let val = self[key] as? T else {
      throw AllObjectsError.fieldMissing(key: keyString)
    }

    return val
  }

  internal func optionalField<T>(_ keyString: String) -> T? {
    guard let key = keyString as? Key else { return nil }

    return self[key] as? T
  }
}
