//
//  AllObjects.swift
//  Example
//
//  Created by Tom Lokhorst on 2015-12-27.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

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

    if let proxy = obj as? ReferenceProxy {
      return proxy
    }

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

func orderedObjects(allObjects: Objects) -> [(String, Fields)] {
  var result: [(String, Fields)] = []

  let grouped = groupedObjectsByType(allObjects)

  for objects in grouped {
    result += orderedObjectsPerGroup(objects)
  }

  return result
}

func groupedObjectsByType(allObjects: Objects) -> [Objects] {
  var prefix: Objects = [:]
  var references: Objects = [:]
  var groups: Objects = [:]
  var buildFiles: Objects = [:]
  var suffix: Objects = [:]

  for (id, object) in allObjects {
    let isa = object["isa"] as! String
    let group = typeGroups[isa] ?? .Prefix

    switch group {
    case .Prefix:
      prefix[id] = object
    case .Reference:
      references[id] = object
    case .Group:
      groups[id] = object
    case .BuildFile:
      buildFiles[id] = object
    case .Suffix:
      suffix[id] = object
    }
  }

  var result: [Objects] = []

  result.append(prefix)
  result.append(references)
  result.append(groups)
  result.append(buildFiles)
  result.append(suffix)

  return result
}

func orderedObjectsPerGroup(objects: Objects) -> [(String, Fields)] {

  var depths: [String: Int] = [:]

  func computeDepths(key: String, obj: Fields) -> Int {

    if let depth = depths[key] {
      return depth
    }

    var maxDepth : Int?

    for (_, field) in obj {
      if let str = field as? String {
        if let obj = objects[str] {

          let depth = computeDepths(str, obj: obj)
          maxDepth = max(depth, maxDepth ?? 0)
        }
      }
      if let arr = field as? [String] {
        for str in arr {
          if let obj = objects[str] {

            let depth = computeDepths(str, obj: obj)
            maxDepth = max(depth, maxDepth ?? 0)
          }
        }
      }
    }


    let depth: Int
    if let maxDepth = maxDepth {
      depth = maxDepth + 1
    }
    else {
      depth = 0
    }

    depths[key] = depth
    return depth
  }

  for (id, obj) in objects {
    computeDepths(id, obj: obj)
  }

  let sorted = objects
    .map { (depth: depths[$0.0] ?? 0, object: $0) }
    .sort { $0.depth < $1.depth }
    .map { $0.object }

  return sorted
}


enum TypeGroup : Int {
  case Prefix = 0
  case Reference = 1
  case Group = 2
  case BuildFile = 3
  case Suffix = 4
}

let typeGroups: [String: TypeGroup] = [
  "PBXObject" : .Prefix,
  "XCConfigurationList" : .Prefix,
  "PBXProject" : .Prefix,
  "PBXContainerItemProxy" : .Prefix,
  "PBXReference" : .Reference,
  "PBXReferenceProxy" : .Reference,
  "PBXFileReference" : .Reference,
  "XCVersionGroup" : .Reference,
  "PBXGroup" : .Group,
  "PBXVariantGroup" : .Group,
  "PBXBuildFile" : .BuildFile,
  "PBXCopyFilesBuildPhase" : .Suffix,
  "PBXFrameworksBuildPhase" : .Suffix,
  "PBXHeadersBuildPhase" : .Suffix,
  "PBXResourcesBuildPhase" : .Suffix,
  "PBXShellScriptBuildPhase" : .Suffix,
  "PBXSourcesBuildPhase" : .Suffix,
  "PBXBuildStyle" : .Suffix,
  "XCBuildConfiguration" : .Suffix,
  "PBXAggregateTarget" : .Suffix,
  "PBXNativeTarget" : .Suffix,
  "PBXTargetDependency" : .Suffix,
]

let types: [String: PropertyListEncodable.Type] = [
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
  "PBXReferenceProxy": ReferenceProxy.self,
  "PBXFileReference": FileReference.self,
  "XCVersionGroup": VersionGroup.self,
  "PBXGroup": Group.self,
  "PBXVariantGroup": VariantGroup.self,
]
