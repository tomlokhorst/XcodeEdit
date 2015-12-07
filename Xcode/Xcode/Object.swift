//
//  Object.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-30.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

public struct Object : PBXObject {
  /* PBXObject fields */
  public let isa = "PBXObject"
  public let id: String
  public let fields: Fields
}

extension Object : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
  }
}

public struct Project : PBXProject {

  /* PBXObject fields */
  public let isa = "PBXProject"
  public let id: String
  public let fields: Fields

  /* PBXProject fields */
  public var targets: [PBXTarget]
  public var mainGroup: PBXGroup
  public var buildConfigurationList: XCConfigurationList
}

extension Project : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields

    let targetKeys = try fields.field("targets") as [String]
    self.targets = targetKeys.map { key in allObjects.target(key) }
    self.mainGroup = allObjects.group(try fields.field("mainGroup") as String)
    self.buildConfigurationList = allObjects.object(try fields.field("buildConfigurationList") as String) as ConfigurationList
  }
}

public struct ContainerItemProxy : PBXContainerItemProxy {

  /* PBXObject fields */
  public let isa = "PBXContainerItemProxy"
  public let id: String
  public let fields: Fields
}

extension ContainerItemProxy : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
  }
}

public struct BuildFile : PBXBuildFile {
  /* PBXObject fields */
  public let isa = "PBXBuildFile"
  public let id: String
  public let fields: Fields

  /* PBXBuildFile fields */
  public let fileRef: PBXReference?
}

extension BuildFile : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let fileRefKey = fields.optionalField("fileRef") as String?

    self.id = id
    self.fields = fields

    if let fileRefKey = fileRefKey {
      self.fileRef = allObjects.reference(fileRefKey)
    }
    else {
      self.fileRef = nil
    }
  }
}

public struct CopyFilesBuildPhase : PBXCopyFilesBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXCopyFilesBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public let files: [PBXBuildFile]

  /* PBXCopyFilesBuildPhase fields */
  public let name: String?
}

extension CopyFilesBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let fileKeys = try fields.field("files") as [String]
    let files = fileKeys.map { key in allObjects.buildFile(key) }
    let name = try fields.field("name") as String

    self.id = id
    self.fields = fields

    self.files = files

    self.name = name
  }
}

public struct FrameworksBuildPhase : PBXFrameworksBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXFrameworksBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public let files: [PBXBuildFile]
}

extension FrameworksBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let fileKeys = try fields.field("files") as [String]
    let files = fileKeys.map { key in allObjects.buildFile(key) }

    self.id = id
    self.fields = fields

    self.files = files
  }
}

public struct HeadersBuildPhase : PBXHeadersBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXHeadersBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public let files: [PBXBuildFile]
}

extension HeadersBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let fileKeys = try fields.field("files") as [String]
    let files = fileKeys.map { key in allObjects.buildFile(key) }

    self.id = id
    self.fields = fields

    self.files = files
  }
}

public struct ResourcesBuildPhase : PBXResourcesBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXResourcesBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public let files: [PBXBuildFile]
}

extension ResourcesBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let fileKeys = try fields.field("files") as [String]
    let files = fileKeys.map { key in allObjects.buildFile(key) }

    self.id = id
    self.fields = fields

    self.files = files
  }
}

public struct ShellScriptBuildPhase : PBXShellScriptBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXShellScriptBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public let files: [PBXBuildFile]

  /* PBXShellScriptBuildPhase fields */
  public let name: String?
  public let shellScript: String
}

extension ShellScriptBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let filesKeys = try fields.field("files") as [String]
    let files = filesKeys.map { key in allObjects.buildFile(key) }

    let name = fields.optionalField("name") as String?
    let shellScript = try fields.field("shellScript") as String

    self.id = id
    self.fields = fields

    self.files = files

    self.name = name
    self.shellScript = shellScript
  }
}

public struct SourcesBuildPhase : PBXSourcesBuildPhase {
  /* PBXObject fields */
  public let isa = "PBXSourcesBuildPhase"
  public let id: String
  public let fields: Fields

  /* PBXBuildPhase fields */
  public var files: [PBXBuildFile]
}

extension SourcesBuildPhase : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let filesKeys = try fields.field("files") as [String]
    let files = filesKeys.map { key in allObjects.buildFile(key) }

    self.id = id
    self.fields = fields

    self.files = files
  }
}

public struct BuildStyle : PBXBuildStyle {
  /* PBXObject fields */
  public let isa = "PBXBuildStyle"
  public let id: String
  public let fields: Fields
}

extension BuildStyle : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.init(
      id: id,
      fields: fields)
  }
}

public struct BuildConfiguration : XCBuildConfiguration {
  /* PBXObject fields */
  public let isa = "XCBuildConfiguration"
  public let id: String
  public let fields: Fields

  /* XCBuildConfiguration fields */
  public var name: String
}

extension BuildConfiguration : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = try fields.field("name") as String

    self.init(
      id: id,
      fields: fields,
      name: name)
  }
}

public struct AggregateTarget : PBXAggregateTarget {
  /* PBXObject fields */
  public let isa = "PBXAggregateTarget"
  public let id: String
  public let fields: Fields

  /* PBXTarget fields */
  public var buildConfigurationList: XCConfigurationList
  public var name: String
  public var productName: String
  public var buildPhases: [PBXBuildPhase]
}

extension AggregateTarget : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let buildConfigurationListKey = try fields.field("buildConfigurationList") as String
    let name = try fields.field("name") as String
    let productName = try fields.field("productName") as String
    let buildPhasesKeys = try fields.field("buildPhases") as [String]
    let buildPhases = buildPhasesKeys.map { key in allObjects.buildPhase(key) }

    self.init(
      id: id,
      fields: fields,
      buildConfigurationList: allObjects.object(buildConfigurationListKey) as ConfigurationList,
      name: name,
      productName: productName,
      buildPhases: buildPhases)
  }
}

public struct NativeTarget : PBXNativeTarget {
  /* PBXObject fields */
  public let isa = "PBXNativeTarget"
  public let id: String
  public let fields: Fields

  /* PBXTarget fields */
  public var buildConfigurationList: XCConfigurationList
  public var name: String
  public var productName: String
  public var buildPhases: [PBXBuildPhase]
}

extension NativeTarget : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let buildConfigurationListKey = try fields.field("buildConfigurationList") as String
    let name = try fields.field("name") as String
    let productName = try fields.field("productName") as String
    let buildPhasesKeys = try fields.field("buildPhases") as [String]
    let buildPhases = buildPhasesKeys.map { key in allObjects.buildPhase(key) }

    self.init(
      id: id,
      fields: fields,
      buildConfigurationList: allObjects.object(buildConfigurationListKey) as ConfigurationList,
      name: name,
      productName: productName,
      buildPhases: buildPhases)
  }
}

public struct TargetDependency : PBXTargetDependency {
  /* PBXObject fields */
  public let isa = "PBXTargetDependency"
  public let id: String
  public let fields: Fields
}

extension TargetDependency : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
  }
}

public struct ConfigurationList : XCConfigurationList {
  /* PBXObject fields */
  public let isa = "XCConfigurationList"
  public let id: String
  public let fields: Fields
}

extension ConfigurationList : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
  }
}

public struct Reference : PBXReference {
  /* PBXObject fields */
  public let isa = "PBXReference"
  public let id: String
  public let fields: Fields

  /* PBXReference fields */
  public var name: String?
  public var path: String?
  public var sourceTree: SourceTree
}

extension Reference : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = fields.optionalField("name") as String?
    let path = fields.optionalField("path") as String?
    let sourceTreeString = try fields.field("sourceTree") as String
    let sourceTree = try SourceTree(string: sourceTreeString)

    self.id = id
    self.fields = fields

    self.name = name
    self.path = path
    self.sourceTree = sourceTree
  }
}

public struct FileReference : PBXFileReference {
  /* PBXObject fields */
  public let isa = "PBXFileReference"
  public let id: String
  public let fields: Fields

  /* PBXReference fields */
  public var name: String?
  public var path: String?
  public var sourceTree: SourceTree

  /* PBXFileReference fields */

  // convenience accessor
  private let allObjects: AllObjects
  public var fullPath: Path {
    return allObjects.fullFilePaths[self.id]!
  }
}

extension FileReference : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = fields.optionalField("name") as String?
    let path = fields.optionalField("path") as String?
    let sourceTreeString = try fields.field("sourceTree") as String
    let sourceTree = try SourceTree(string: sourceTreeString)

    self.id = id
    self.fields = fields

    self.name = name
    self.path = path
    self.sourceTree = sourceTree

    self.allObjects = allObjects
  }
}

public struct Group : PBXGroup {
  /* PBXObject fields */
  public let isa = "PBXGroup"
  public let id: String
  public let fields: Fields

  /* PBXReference fields */
  public var name: String?
  public var path: String?
  public var sourceTree: SourceTree

  /* PBXGroup fields */
  public var children: [PBXReference]

  // convenience accessors
  public var subGroups: [PBXGroup] { return self.children.ofType(PBXGroup.self) }
  public var fileRefs: [PBXFileReference] { return self.children.ofType(PBXFileReference) }
}

extension Group : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = fields.optionalField("name") as String?
    let path = fields.optionalField("path") as String?
    let sourceTreeString = try fields.field("sourceTree") as String
    let sourceTree = try SourceTree(string: sourceTreeString)
    let childrenKeys = try fields.field("children") as [String]
    let children = childrenKeys.map { key in allObjects.reference(key) }

    self.id = id
    self.fields = fields

    self.name = name
    self.path = path
    self.sourceTree = sourceTree

    self.children = children
  }
}

public struct VariantGroup : PBXVariantGroup {
  /* PBXObject fields */
  public let isa = "PBXVariantGroup"
  public let id: String
  public let fields: Fields

  /* PBXReference fields */
  public var name: String?
  public var path: String?
  public var sourceTree: SourceTree

  /* PBXGroup fields */
  public var children: [PBXReference]

  // convenience accessors
  public var subGroups: [PBXGroup] { return self.children.ofType(PBXGroup.self) }
  public var fileRefs: [PBXFileReference] { return self.children.ofType(PBXFileReference) }
}

extension VariantGroup : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = fields.optionalField("name") as String?
    let path = fields.optionalField("path") as String?
    let sourceTreeString = try fields.field("sourceTree") as String
    let sourceTree = try SourceTree(string: sourceTreeString)
    let childrenKeys = try fields.field("children") as [String]
    let children = childrenKeys.map { key in allObjects.reference(key) }

    self.id = id
    self.fields = fields

    self.name = name
    self.path = path
    self.sourceTree = sourceTree

    self.children = children
  }
}

public struct VersionGroup : XCVersionGroup {
  /* PBXObject fields */
  public let isa = "XCVersionGroup"
  public let id: String
  public let fields: Fields

  /* PBXReference fields */
  public var name: String?
  public var path: String?
  public var sourceTree: SourceTree
}

extension VersionGroup : PropertyListEncodable {
  init(id: String, fields: Fields, allObjects: AllObjects) throws {
    let name = fields.optionalField("name") as String?
    let path = fields.optionalField("path") as String?
    let sourceTreeString = try fields.field("sourceTree") as String
    let sourceTree = try SourceTree(string: sourceTreeString)

    self.id = id
    self.fields = fields

    self.name = name
    self.path = path
    self.sourceTree = sourceTree
  }
}

extension SourceTree {
  init(string sourceTreeString: String) throws {
    guard let sourceTree = SourceTree(sourceTreeString: sourceTreeString) else {
      throw AllObjectsError.InvalidValue(key: "sourceTree", value: sourceTreeString)
    }

    self = sourceTree
  }
}
