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

    public func addReference<Value>(value: Value) -> Reference<Value> {
        return allObjects.createReference(value: value)
    }

    public func createShellScript(name: String, shellScript: String) throws -> PBXShellScriptBuildPhase {
        let fields: [String: Any] = [
            "isa": "PBXShellScriptBuildPhase",
            "files": [] as [String],
            "name": name,
            "runOnlyForDeploymentPostprocessing": 0,
            "shellPath": "/bin/sh",
            "inputPaths": [] as [String],
            "outputPaths": [] as [String],
            "shellScript": shellScript,
            "buildActionMask": 0x7FFFFFFF
        ]

        let guid = allObjects.createFreshGuid(from: project.id)
        let scriptBuildPhase = try PBXShellScriptBuildPhase(id: guid, fields: fields, allObjects: allObjects)

        return scriptBuildPhase
    }

    public func createFileReference(path: String, name: String, sourceTree: SourceTree, lastKnownFileType: String = "sourcecode.swift") throws -> PBXFileReference {

        var fields: [String: Any] = [
            "isa": "PBXFileReference",
            "lastKnownFileType": lastKnownFileType,
            "path": path,
            "sourceTree": sourceTree.rawValue
        ]

        if name != path {
            fields["name"] = name
        }

        let guid = allObjects.createFreshGuid(from: project.id)
        let fileReference = try PBXFileReference(id: guid, fields: fields, allObjects: allObjects)

        return fileReference
    }

    public func createBuildFile(fileReference: Reference<PBXFileReference>) throws -> PBXBuildFile {

        let fields: [String: Any] = [
            "isa": "PBXBuildFile",
            "fileRef": fileReference.id.value
        ]

        let guid = allObjects.createFreshGuid(from: project.id)
        let buildFile = try PBXBuildFile(id: guid, fields: fields, allObjects: allObjects)

        return buildFile
    }
}
