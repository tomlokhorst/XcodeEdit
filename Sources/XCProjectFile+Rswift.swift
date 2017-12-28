//
//  XCProjectFile+Rswift.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2017-12-28.
//  Copyright © 2017 nonstrict. All rights reserved.
//

import Foundation

// Mutation functions needed by R.swift

extension XCProjectFile {
//  public func makeObject<T: PBXObject>(type: T.Type, id: Guid, fields: Fields) throws -> T {
//    return try T(id: id, fields: fields, allObjects: allObjects)
//  }

  public func addReference<Value>(value: Value) -> Reference<Value> {
    return allObjects.createReference(value: value)
  }

  public func createShellScript(name: String, shellScript: String) throws -> PBXShellScriptBuildPhase {
    let fields: [String: Any] = [
      "isa": "PBXShellScriptBuildPhase",
      "files": [],
      "name": name,
      "runOnlyForDeploymentPostprocessing": 0,
      "shellPath": "/bin/sh",
      "inputPaths": [],
      "outputPaths": [],
      "shellScript": shellScript,
      "buildActionMask": 0x7FFFFFFF]

    let guid = allObjects.createFreshGuid(from: project.id)
    let scriptBuildPhase = try PBXShellScriptBuildPhase(id: guid, fields: fields, allObjects: allObjects)

    return scriptBuildPhase
  }

  public func createFileReference(path: String, sourceTree: SourceTree, lastKnownFileType: String = "sourcecode.swift") throws -> PBXFileReference {

    let fields: [String: Any] = [
      "isa": "PBXFileReference",
      "lastKnownFileType": lastKnownFileType,
      "path": path,
      "sourceTree": sourceTree.rawValue
    ]

    let guid = allObjects.createFreshGuid(from: project.id)
    let fileReference = try PBXFileReference(id: guid, fields: fields, allObjects: allObjects)

    return fileReference
  }
}
