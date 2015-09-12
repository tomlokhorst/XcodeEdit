//
//  XCProjectFile.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-12.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

typealias JsonObject = [String: AnyObject]

extension Array {
  func ofType<T>(type: T.Type) -> [T] {
    return self.filter { $0 is T }.map { $0 as! T }
  }
}

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

public class AllObjects {
  var dict: [String: PBXObject] = [:]
  var fullFilePaths: [String: Path] = [:]

  subscript(key: String) -> PBXObject? {
    get { return dict[key] }
  }

  func object<T : PBXObject>(key: String) -> T {
    let obj = dict[key]!
    if let t = obj as? T {
      return t
    }

    return T(id: key, dict: obj.dict, allObjects: self)
  }
}

enum ProjectFileError : ErrorType, CustomStringConvertible {
  case InvalidData
  case MissingPbxproj

  var description: String {
    switch self {
    case .InvalidData:
      return "Data in .pbxproj file not in expected format"
    case .MissingPbxproj:
      return "project.pbxproj file missing"
    }
  }
}

public class XCProjectFile {
  public let project: PBXProject
  let dict: JsonObject
  let openStepFormat: Bool
  let allObjects = AllObjects()

  public convenience init(xcodeprojPath: String) throws {

    guard let data = NSData(contentsOfFile: xcodeprojPath + "/project.pbxproj") else {
      throw ProjectFileError.MissingPbxproj
    }

    try self.init(propertyListData: data)
  }

  public convenience init(propertyListData data: NSData) throws {

    let options = NSPropertyListReadOptions.Immutable
    var format: NSPropertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
    let obj = try NSPropertyListSerialization.propertyListWithData(data, options: options, format: &format)

    guard let dict = obj as? JsonObject else {
      throw ProjectFileError.InvalidData
    }

    self.init(dict: dict, openStepFormat: format == NSPropertyListFormat.OpenStepFormat)
  }

  init(dict: JsonObject, openStepFormat: Bool) {
    self.dict = dict
    self.openStepFormat = openStepFormat
    let objects = dict["objects"] as! [String: JsonObject]

    for (key, obj) in objects {
      allObjects.dict[key] = XCProjectFile.createObject(key, dict: obj, allObjects: allObjects)
    }

    let rootObjectId = dict["rootObject"]! as! String
    let projDict = objects[rootObjectId]!
    self.project = PBXProject(id: rootObjectId, dict: projDict, allObjects: allObjects)
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func createObject(id: String, dict: JsonObject, allObjects: AllObjects) -> PBXObject {
    let isa = dict["isa"] as? String

    if isa == "PBXNativeTarget" {
      return PBXNativeTarget(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildPhase" {
      return PBXBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXResourcesBuildPhase" {
      return PBXResourcesBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildFile" {
      return PBXBuildFile(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXVariantGroup" {
      return PBXVariantGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXGroup" {
      return PBXGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXFileReference" {
      return PBXFileReference(id: id, dict: dict, allObjects: allObjects)
    }

    // Fallback
    return PBXObject(id: id, dict: dict, allObjects: allObjects)
  }

  func paths(current: PBXGroup, prefix: String) -> [String: Path] {

    var ps: [String: Path] = [:]

    for file in current.fileRefs {
      switch file.sourceTree {
      case .Group:
        ps[file.id] = .RelativeTo(.SourceRoot, prefix + "/" + file.path)
      case .Absolute:
        ps[file.id] = .Absolute(file.path)
      case let .RelativeTo(sourceTreeFolder):
        ps[file.id] = .RelativeTo(sourceTreeFolder, file.path)
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

public class PBXObject {
  let id: String
  let dict: JsonObject
  let allObjects: AllObjects

  public required init(id: String, dict: AnyObject, allObjects: AllObjects) {
    self.id = id
    self.dict = dict as! JsonObject
    self.allObjects = allObjects
  }

  func string(key: String) -> String? {
    return dict[key] as? String
  }

  func object<T : PBXObject>(key: String) -> T {
    let objectKey = dict[key] as! String
    return allObjects.object(objectKey)
  }

  func objects<T : PBXObject>(key: String) -> [T] {
    let objectKeys = dict[key] as! [String]
    return objectKeys.map(allObjects.object)
  }
}

public class PBXProject : PBXObject {
  public lazy var targets: [PBXNativeTarget] = self.objects("targets")
  public lazy var mainGroup: PBXGroup = self.object("mainGroup")
}

public class PBXNativeTarget : PBXObject {
  public lazy var productName: String = self.string("productName")!
  public lazy var buildPhases: [PBXBuildPhase] = self.objects("buildPhases")
}

public class PBXBuildPhase : PBXObject {
  public lazy var files: [PBXBuildFile] = self.objects("files")
}

public class PBXResourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildFile : PBXObject {
  public lazy var fileRef: PBXReference = self.object("fileRef")
}

public class PBXReference : PBXObject {
}

public class PBXGroup : PBXReference {
  public lazy var name: String = self.string("name")!
  public lazy var path: String? = self.string("path")
  public lazy var children: [PBXReference] = self.objects("children")

  // convenience accessors
  public lazy var subGroups: [PBXGroup] = self.children.ofType(PBXGroup.self)
  public lazy var fileRefs: [PBXFileReference] = self.children.ofType(PBXFileReference)
}

public class PBXVariantGroup : PBXGroup {
}

public enum SourceTree {
  case Absolute
  case Group
  case RelativeTo(SourceTreeFolder)

  init?(sourceTreeString: String) {
    switch sourceTreeString {
    case "<absolute>":
      self = .Absolute
    case "<group>":
      self = .Group
    default:
      guard let sourceTreeFolder = SourceTreeFolder(rawValue: sourceTreeString) else { return nil }
      self = .RelativeTo(sourceTreeFolder)
    }
  }
}

public enum SourceTreeFolder: String {
  case SourceRoot = "SOURCE_ROOT"
  case BuildProductsDir = "BUILT_PRODUCTS_DIR"
  case DeveloperDir = "DEVELOPER_DIR"
  case SDKRoot = "SDKROOT"
}

public enum Path {
  case Absolute(String)
  case RelativeTo(SourceTreeFolder, String)
}

public class PBXFileReference : PBXReference {
  public lazy var path: String = self.string("path")!
  public lazy var sourceTree: SourceTree = self.string("sourceTree").flatMap(SourceTree.init)!

  // convenience accessor
  public lazy var fullPath: Path = self.allObjects.fullFilePaths[self.id]!
}
