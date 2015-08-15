//
//  XCProjectFile.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-12.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

enum ProjectFileError : ErrorType, CustomStringConvertible {
  case InvalidData
  case NotXcodeproj
  case MissingPbxproj

  var description: String {
    switch self {
    case .InvalidData:
      return "Data in .pbxproj file not in expected format"
    case .NotXcodeproj:
      return "Path is not a .xcodeproj package"
    case .MissingPbxproj:
      return "project.pbxproj file missing"
    }
  }
}

public class XCProjectFile {
  public let project: PBXProject
  let dict: JsonObject
  let format: NSPropertyListFormat
  let allObjects: AllObjects

  public convenience init(xcodeprojPath: String) throws {

    guard let data = NSData(contentsOfFile: xcodeprojPath + "/project.pbxproj") else {
      throw ProjectFileError.MissingPbxproj
    }

    let name = try XCProjectFile.projectName(xcodeprojPath)

    try self.init(propertyListData: data, projectName: name)
  }

  public convenience init(propertyListData data: NSData, projectName: String) throws {

    let options = NSPropertyListReadOptions.Immutable
    var format: NSPropertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
    let obj = try NSPropertyListSerialization.propertyListWithData(data, options: options, format: &format)

    guard let dict = obj as? JsonObject else {
      throw ProjectFileError.InvalidData
    }

    self.init(dict: dict, format: format, projectName: projectName)
  }

  init(dict: JsonObject, format: NSPropertyListFormat, projectName: String) {
    self.dict = dict
    self.format = format
    self.allObjects = AllObjects(projectName: projectName)
    let objects = dict["objects"] as! [String: JsonObject]

    for (key, obj) in objects {
      allObjects.dict[key] = XCProjectFile.createObject(key, dict: obj, allObjects: allObjects)
    }

    let rootObjectId = dict["rootObject"]! as! String
    let projDict = objects[rootObjectId]!
    self.project = PBXProject(id: rootObjectId, dict: projDict, allObjects: allObjects)
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func projectName(xcodeprojPath: String) throws -> String {

    let url = NSURL(fileURLWithPath: xcodeprojPath, isDirectory: true)

    guard let subpaths = url.pathComponents,
          let last = subpaths.last,
          let range = last.rangeOfString(".xcodeproj")
    else {
      throw ProjectFileError.NotXcodeproj
    }

    return last.substringToIndex(range.startIndex)
  }

  static func createObject(id: String, dict: JsonObject, allObjects: AllObjects) -> PBXObject {
    let isa = dict["isa"] as? String

    if isa == "PBXProject" {
      return PBXProject(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXContainerItemProxy" {
      return PBXContainerItemProxy(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildFile" {
      return PBXBuildFile(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXCopyFilesBuildPhase" {
      return PBXCopyFilesBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXFrameworksBuildPhase" {
      return PBXFrameworksBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXHeadersBuildPhase" {
      return PBXHeadersBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXResourcesBuildPhase" {
      return PBXResourcesBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXShellScriptBuildPhase" {
      return PBXShellScriptBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXSourcesBuildPhase" {
      return PBXSourcesBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildStyle" {
      return PBXBuildStyle(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "XCBuildConfiguration" {
      return XCBuildConfiguration(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXAggregateTarget" {
      return PBXAggregateTarget(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXNativeTarget" {
      return PBXNativeTarget(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXTargetDependency" {
      return PBXTargetDependency(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "XCConfigurationList" {
      return XCConfigurationList(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXReference" {
      return PBXReference(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXFileReference" {
      return PBXFileReference(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXGroup" {
      return PBXGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXVariantGroup" {
      return PBXVariantGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "XCVersionGroup" {
      return XCVersionGroup(id: id, dict: dict, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return PBXObject(id: id, dict: dict, allObjects: allObjects)
  }

  func paths(current: PBXGroup, prefix: String) -> [String: String] {
    var ps: [String: String] = [:]

    for file in current.fileRefs {
      ps[file.id] = prefix + "/" + file.path!
    }

    for group in current.subGroups {
      if let path = group.path {
        ps += paths(group, prefix: prefix + "/" + path)
      }
      else {
        ps += paths(group, prefix: prefix)
      }
    }

    return ps
  }
}
