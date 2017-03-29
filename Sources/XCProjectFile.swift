//
//  XCProjectFile.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-12.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

enum ProjectFileError : Error, CustomStringConvertible {
  case invalidData
  case notXcodeproj
  case missingPbxproj

  var description: String {
    switch self {
    case .invalidData:
      return "Data in .pbxproj file not in expected format"

    case .notXcodeproj:
      return "Path is not a .xcodeproj package"

    case .missingPbxproj:
      return "project.pbxproj file missing"
    }
  }
}

public class XCProjectFile {
  public let project: PBXProject
  let dict: Fields
  var format: PropertyListSerialization.PropertyListFormat
  let allObjects = AllObjects()

  public convenience init(xcodeprojURL: URL) throws {
    let pbxprojURL = xcodeprojURL.appendingPathComponent("project.pbxproj", isDirectory: false)
    let data = try Data(contentsOf: pbxprojURL)

    try self.init(propertyListData: data)
  }

  public convenience init(propertyListData data: Data) throws {

    let options = PropertyListSerialization.MutabilityOptions()
    var format: PropertyListSerialization.PropertyListFormat = PropertyListSerialization.PropertyListFormat.binary
    let obj = try PropertyListSerialization.propertyList(from: data, options: options, format: &format)

    guard let dict = obj as? Fields else {
      throw ProjectFileError.invalidData
    }

    self.init(dict: dict, format: format)
  }

  init(dict: Fields, format: PropertyListSerialization.PropertyListFormat) {
    self.dict = dict
    self.format = format
    let objects = dict["objects"] as! [String: Fields]

    for (key, obj) in objects {
      allObjects.dict[key] = try! AllObjects.createObject(key, fields: obj, allObjects: allObjects)
    }

    let rootObjectId = dict["rootObject"]! as! String
    let projDict = objects[rootObjectId]!
    self.project = PBXProject(id: rootObjectId, fields: projDict, allObjects: allObjects)
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func projectName(from url: URL) throws -> String {

    let subpaths = url.pathComponents
    guard let last = subpaths.last,
          let range = last.range(of: ".xcodeproj")
    else {
      throw ProjectFileError.notXcodeproj
    }

    return last.substring(to: range.lowerBound)
  }

  func paths(_ current: PBXGroup, prefix: String) -> [String: Path] {

    var ps: [String: Path] = [:]

    for file in current.fileRefs {
      switch file.sourceTree {
      case .group:
        switch current.sourceTree {
        case .absolute:
          ps[file.id] = .absolute(prefix + "/" + file.path!)

        case .group:
          ps[file.id] = .relativeTo(.sourceRoot, prefix + "/" + file.path!)

        case .relativeTo(let sourceTreeFolder):
          ps[file.id] = .relativeTo(sourceTreeFolder, prefix + "/" + file.path!)
        }

      case .absolute:
        ps[file.id] = .absolute(file.path!)

      case let .relativeTo(sourceTreeFolder):
        ps[file.id] = .relativeTo(sourceTreeFolder, file.path!)
      }
    }

    for group in current.subGroups {
      if let path = group.path {
        
        let str: String

        switch group.sourceTree {
        case .absolute:
          str = path

        case .group:
          str = prefix + "/" + path

        case .relativeTo(.sourceRoot):
          str = path

        case .relativeTo(.buildProductsDir):
          str = path

        case .relativeTo(.developerDir):
          str = path

        case .relativeTo(.sdkRoot):
          str = path
        }

        ps += paths(group, prefix: str)
      }
      else {
        ps += paths(group, prefix: prefix)
      }
    }

    return ps
  }
    
}
