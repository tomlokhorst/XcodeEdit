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

public class AllObjects {
  var dict: [String: PBXObject] = [:]
  var fullFilePaths: [String: Path] = [:]

  func object<T where T : PBXObject>(key: String) -> T {
    let obj = dict[key]!

    if let t = obj as? T {
      return t
    }

    fatalError("Unknown PBXObject subclass isa=\(obj.isa)")
  }

  func buildFile(key: String) -> PBXBuildFile {
    return object(key) as BuildFile as PBXBuildFile
  }

  func buildPhase(key: String) -> PBXBuildPhase {
    let obj = dict[key]!

    if let phase = obj as? CopyFilesBuildPhase {
      return phase
    }

    if let phase = obj as? FrameworksBuildPhase {
      return phase
    }

    if let phase = obj as? HeadersBuildPhase {
      return phase
    }

    if let phase = obj as? ResourcesBuildPhase {
      return phase
    }

    if let phase = obj as? FrameworksBuildPhase {
      return phase
    }

    if let phase = obj as? ShellScriptBuildPhase {
      return phase
    }

    if let phase = obj as? SourcesBuildPhase {
      return phase
    }

    // Fallback
    assertionFailure("Unknown PBXBuildPhase subclass isa=\(obj.isa)")
    if let phase = obj as? BuildPhase {
      return phase
    }

    fatalError("Unknown PBXBuildPhase subclass isa=\(obj.isa)")
  }

  func target(key: String) -> PBXTarget {
    let obj = dict[key]!

    if let aggregate = obj as? AggregateTarget {
      return aggregate
    }

    if let native = obj as? NativeTarget {
      return native
    }

    // Fallback
    assertionFailure("Unknown PBXTarget subclass isa=\(obj.isa)")
    if let target = obj as? Target {
      return target
    }

    fatalError("Unknown PBXTarget subclass isa=\(obj.isa)")
  }

  func group(key: String) -> PBXGroup {
    let obj = dict[key]!

    if let variant = obj as? VariantGroup {
      return variant
    }

    if let group = obj as? Group {
      return group
    }

    fatalError("Unknown PBXGroup subclass isa=\(obj.isa)")
  }

  func reference(key: String) -> PBXReference {
    let obj = dict[key]!

    if let file = obj as? FileReference {
      return file
    }

    if let variant = obj as? VariantGroup {
      return variant
    }

    if let group = obj as? Group {
      return group
    }

    if let group = obj as? VersionGroup {
      return group
    }

    // Fallback
    assertionFailure("Unknown PBXReference subclass isa=\(obj.isa)")
    if let reference = obj as? Reference {
      return reference
    }

    fatalError("Unknown PBXReference subclass isa=\(obj.isa)")
  }
}

enum AllObjectsError: ErrorType {
  case FieldMissing(key: String)
  case InvalidValue(key: String, value: String)
  case ObjectMissing(key: String)
}

typealias GuidKey = String

extension Dictionary {
  internal func key(keyString: String) throws -> GuidKey {
    guard let key = keyString as? Key, val = self[key] as? GuidKey else {
      throw AllObjectsError.FieldMissing(key: keyString)
    }

    return val
  }

  internal func keys(keyString: String) throws -> [GuidKey] {
    guard let key = keyString as? Key, val = self[key] as? [GuidKey] else {
      throw AllObjectsError.FieldMissing(key: keyString)
    }

    return val
  }

  internal func field<T>(keyString: String) throws -> T {
    guard let key = keyString as? Key, val = self[key] as? T else {
      throw AllObjectsError.FieldMissing(key: keyString)
    }

    return val
  }

  internal func optionalField<T>(keyString: String) -> T? {
    guard let key = keyString as? Key else { return nil }

    return self[key] as? T
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

func orderedObjects(objects: Objects) -> [(String, Fields)] {

  let refs = deepReferences(objects)

  var cache: [String: Int] = [:]
  func depth(key: String) -> Int {
    if let val = cache[key] {
      return val
    }

    let val = refs[key]?.map(depth).maxElement().map { $0 + 1 } ?? 0
    cache[key] = val

    return val
  }

  // Pre compute cache
  for key in refs.keys {
    cache[key] = depth(key)
  }

//  let sorted = objects.sort { depth($0.0) < depth($1.0) }
  let sorted = objects.sort { cache[$0.0]! < cache[$1.0]! }

  return sorted
}

private func deepReferences(objects: Objects) -> [String: [String]] {
  var result: [String: [String]] = [:]

  for (id, obj) in objects {
    result[id] = deepReferences(obj, objects: objects)
  }

  return result
}

private func deepReferences(obj: Fields, objects: Objects) -> [String] {
  var result: [String] = []

  for (_, field) in obj {
    if let str = field as? String {
      result += deepReferences(str, objects: objects)
    }
    if let arr = field as? [String] {
      for str in arr {
        result += deepReferences(str, objects: objects)
      }
    }
  }

  return result
}

private func deepReferences(key: String, objects: Objects) -> [String] {
  guard let obj = objects[key] else { return [] }

  var result = deepReferences(obj, objects: objects)
  result.append(key)
  return result
}


let typeOrder: [String] = [
  "PBXObject",
  "XCConfigurationList",
  "PBXProject",
  "PBXContainerItemProxy",
  "PBXReference",
  "PBXFileReference",
  "PBXGroup",
  "PBXVariantGroup",
  "XCVersionGroup",
  "PBXBuildFile",
  "PBXCopyFilesBuildPhase",
  "PBXFrameworksBuildPhase",
  "PBXHeadersBuildPhase",
  "PBXResourcesBuildPhase",
  "PBXShellScriptBuildPhase",
  "PBXSourcesBuildPhase",
  "PBXBuildStyle",
  "XCBuildConfiguration",
  "PBXAggregateTarget",
  "PBXNativeTarget",
  "PBXTargetDependency",
]

let types: [String: PropertyListEncodable.Type] = [
//  "PBXProject": PBXProject.self,
  "PBXContainerItemProxy": ContainerItemProxy.self,
  "PBXBuildFile": BuildFile.self,
  "PBXCopyFilesBuildPhase": CopyFilesBuildPhase.self,
  "PBXFrameworksBuildPhase": FrameworksBuildPhase.self,
  "PBXHeadersBuildPhase": HeadersBuildPhase.self,
  "PBXResourcesBuildPhase": ResourcesBuildPhase.self,
  "PBXShellScriptBuildPhase": ShellScriptBuildPhase.self,
  "PBXSourcesBuildPhase": SourcesBuildPhase.self,
  "PBXBuildStyle": BuildStyle.self,
  "XCBuildConfiguration": BuildConfiguration.self,
  "PBXAggregateTarget": AggregateTarget.self,
  "PBXNativeTarget": NativeTarget.self,
  "PBXTargetDependency": TargetDependency.self,
  "XCConfigurationList": ConfigurationList.self,
  "PBXReference": Reference.self,
  "PBXFileReference": FileReference.self,
  "PBXGroup": Group.self,
  "PBXVariantGroup": VariantGroup.self,
  "XCVersionGroup": VersionGroup.self
]
