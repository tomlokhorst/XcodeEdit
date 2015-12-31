//
//  PBXObject.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

public typealias Fields = [String: AnyObject]

public /* abstract */ protocol PBXObject {
  var isa: String { get }
  var id: String { get }
  var fields: Fields { get }
}

public /* abstract */ protocol PBXContainer : PBXObject {
}

public protocol PBXProject : PBXContainer {
  var targets: [PBXTarget] { get }
  var mainGroup: PBXGroup { get }
  var buildConfigurationList: XCConfigurationList { get }
}

public /* abstract */ protocol PBXContainerItem : PBXObject {
}

public protocol PBXContainerItemProxy : PBXContainerItem {
}

public /* abstract */ protocol PBXProjectItem : PBXContainerItem {
}

public protocol PBXBuildFile : PBXProjectItem {
  var fileRef: PBXReference? { get }
}


public /* abstract */ protocol PBXBuildPhase : PBXProjectItem {
  var files: [PBXBuildFile] { get }
}

public protocol PBXCopyFilesBuildPhase : PBXBuildPhase {
  var name: String? { get }
}

public protocol PBXFrameworksBuildPhase : PBXBuildPhase {
}

public protocol PBXHeadersBuildPhase : PBXBuildPhase {
}

public protocol PBXResourcesBuildPhase : PBXBuildPhase {
}

public protocol PBXShellScriptBuildPhase : PBXBuildPhase {
  var name: String? { get }
  var shellScript: String { get }
}

public protocol PBXSourcesBuildPhase : PBXBuildPhase {
}

public protocol PBXBuildStyle : PBXProjectItem {
}

public protocol XCBuildConfiguration : PBXBuildStyle {
  var name: String { get }
}

public /* abstract */ protocol PBXTarget : PBXProjectItem {
  var buildConfigurationList: XCConfigurationList { get }
  var name: String { get }
  var productName: String { get }
  var buildPhases: [PBXBuildPhase] { get }
}

public protocol PBXAggregateTarget : PBXTarget {
}

public protocol PBXNativeTarget : PBXTarget {
}

public protocol PBXTargetDependency : PBXProjectItem {
}

public protocol XCConfigurationList : PBXProjectItem {
}

public protocol PBXReference : PBXContainerItem {
  var name: String? { get }
  var path: String? { get }
  var sourceTree: SourceTree { get }
}

public protocol PBXFileReference : PBXReference {

  // convenience accessor
  var fullPath: Path { get }
}

public protocol PBXReferenceProxy : PBXReference {

  var remoteRef: PBXContainerItemProxy { get }
}

public protocol XCVersionGroup : PBXReference {
}

public protocol PBXGroup : PBXReference {
  var children: [PBXReference] { get }

  // convenience accessors
  var subGroups: [PBXGroup] { get }
  var fileRefs: [PBXFileReference] { get }
}

public protocol PBXVariantGroup : PBXGroup {
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

