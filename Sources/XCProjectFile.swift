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

protocol PropertyListEncodable : PBXObject {
  init(id: String, fields: Fields, allObjects: AllObjects) throws
}

typealias Objects = [String: Fields]

public class XCProjectFile {
  public let project: PBXProject
  let fields: Fields
  let format: NSPropertyListFormat
  let allObjects = AllObjects()

  public convenience init(xcodeprojURL: NSURL) throws {

    let pbxprojURL = xcodeprojURL.URLByAppendingPathComponent("project.pbxproj")
    guard let data = NSData(contentsOfURL: pbxprojURL) else {
      throw ProjectFileError.MissingPbxproj
    }

    try self.init(propertyListData: data)
  }

  public convenience init(propertyListData data: NSData) throws {

    let options = NSPropertyListReadOptions.Immutable
    var format: NSPropertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
    let obj = try NSPropertyListSerialization.propertyListWithData(data, options: options, format: &format)

    guard let fields = obj as? Fields else {
      throw ProjectFileError.InvalidData
    }

    self.init(fields: fields, format: format)
  }

  init(fields: Fields, format: NSPropertyListFormat) {
    self.fields = fields
    self.format = format
    let rootObjectId = fields["rootObject"]! as! String
    var objects = fields["objects"] as! Objects
    let projDict = objects[rootObjectId]!
    objects.removeValueForKey(rootObjectId)

    for (key, obj) in orderedObjects(objects) {
      do {
        allObjects.dict[key] = try XCProjectFile.createObject(key, fields: obj, allObjects: allObjects)
      }
      catch {
        print("\(obj["isa"]) \(key) error: \(error)")
      }
    }

    let project = try! Project(id: rootObjectId, fields: projDict, allObjects: allObjects)
    allObjects.dict[rootObjectId] = project

    self.project = project
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func projectName(url: NSURL) throws -> String {

    guard let subpaths = url.pathComponents,
          let last = subpaths.last,
          let range = last.rangeOfString(".xcodeproj")
    else {
      throw ProjectFileError.NotXcodeproj
    }

    return last.substringToIndex(range.startIndex)
  }

  static func createObject(id: String, fields: Fields, allObjects: AllObjects) throws -> PBXObject {
    guard let isa = fields["isa"] as? String else {
      throw AllObjectsError.FieldMissing(key: "isa")
    }

    if let Type = types[isa] {
      return try Type.init(id: id, fields: fields, allObjects: allObjects)
    }

    assertionFailure("Unknown PBXObject subclass isa=\(isa)")

    if let fallback = fallbackCreateObject(isa, id: id, fields: fields, allObjects: allObjects) {
      return fallback
    }

    return try Object(id: id, fields: fields, allObjects: allObjects)
  }

  private static func fallbackCreateObject(isa: String, id: String, fields: Fields, allObjects: AllObjects) -> PBXObject?
  {
    // Some heuristics for figuring out a fallback type

    do {
      if isa.hasSuffix("BuildPhase") {
        return try BuildPhase(id: id, fields: fields, allObjects: allObjects)
      }

      if isa.hasSuffix("Target") {
        return try Target(id: id, fields: fields, allObjects: allObjects)
      }

      if isa.hasSuffix("Reference") {
        return try Reference(id: id, fields: fields, allObjects: allObjects)
      }

      if isa.hasSuffix("Group") {
        return try Group(id: id, fields: fields, allObjects: allObjects)
      }
    }
    catch {
    }

    return nil
  }

  func paths(current: PBXGroup, prefix: String) -> [String: Path] {

    var ps: [String: Path] = [:]

    for file in current.fileRefs {
      switch file.sourceTree {
      case .Group:
        ps[file.id] = .RelativeTo(.SourceRoot, prefix + "/" + file.path!)
      case .Absolute:
        ps[file.id] = .Absolute(file.path!)
      case let .RelativeTo(sourceTreeFolder):
        ps[file.id] = .RelativeTo(sourceTreeFolder, file.path!)
      }
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
