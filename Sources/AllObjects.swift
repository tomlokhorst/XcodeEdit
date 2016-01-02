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
