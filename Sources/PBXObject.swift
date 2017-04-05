//
//  PBXObject.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

public typealias Fields = [String: AnyObject]

public /* abstract */ class PBXObject {
  let id: String
  var fields: Fields
  let allObjects: AllObjects

  public let isa: String

  public required init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
    self.allObjects = allObjects

    self.isa = try self.fields.field("isa")
  }

  func object<T : PBXObject>(_ key: String) -> T? {
    guard let objectKey = fields[key] as? String else {
      return nil
    }

    let obj: T = allObjects.object(objectKey)
    return obj
  }

  func object<T : PBXObject>(_ key: String) -> T {
    let objectKey = fields[key] as! String
    return allObjects.object(objectKey)
  }

  func objects<T : PBXObject>(_ key: String) -> [T] {
    let objectKeys = fields[key] as! [String]
    return objectKeys.map(allObjects.object)
  }
}

public /* abstract */ class PBXContainer : PBXObject {
}

public class PBXProject : PBXContainer {
  public let developmentRegion: String
  public let hasScannedForEncodings: Bool
  public let knownRegions: [String]
  public let targets: [PBXNativeTarget]
  public let mainGroup: PBXGroup
  public let buildConfigurationList: XCConfigurationList

  public required init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.developmentRegion = try fields.string2("developmentRegion")
    self.hasScannedForEncodings = try fields.bool("hasScannedForEncodings")
    self.knownRegions = try fields.strings2("knownRegions")

    self.targets = try allObjects.objects2(try fields.strings2("targets"))
    self.mainGroup = try allObjects.object2(try fields.string2("mainGroup"))
    self.buildConfigurationList = try allObjects.object2(try fields.string2("buildConfigurationList"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public /* abstract */ class PBXContainerItem : PBXObject {
}

public class PBXContainerItemProxy : PBXContainerItem {
}

public /* abstract */ class PBXProjectItem : PBXContainerItem {
}

public class PBXBuildFile : PBXProjectItem {
  public var fileRef: Reference<PBXReference>? {
    didSet {
      if let oldValue = oldValue {
        allObjects.removeReference(oldValue)
      }

      if let fileRef = fileRef {
        self.fields["fileRef"] = fileRef.id as NSObject
      }
      else {
        self.fields["fileRef"] = nil
      }
    }
  }

  public required init(id: String, fields: Fields, allObjects: AllObjects) throws {
    if let fileRefId = try fields.optionalKey("fileRef") {
      self.fileRef = allObjects.createReference(id: fileRefId)
    }
    else {
      self.fileRef = nil
    }

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}


public /* abstract */ class PBXBuildPhase : PBXProjectItem {
  public lazy var files: [PBXBuildFile] = self.objects("files")
}

public class PBXCopyFilesBuildPhase : PBXBuildPhase {
  public lazy var name: String? = self.fields.string("name")
}

public class PBXFrameworksBuildPhase : PBXBuildPhase {
}

public class PBXHeadersBuildPhase : PBXBuildPhase {
}

public class PBXResourcesBuildPhase : PBXBuildPhase {
}

public class PBXShellScriptBuildPhase : PBXBuildPhase {
  public lazy var name: String? = self.fields.string("name")
  public lazy var shellScript: String = self.fields.string("shellScript")!
}

public class PBXSourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildStyle : PBXProjectItem {
}

public class XCBuildConfiguration : PBXBuildStyle {
  public lazy var name: String = self.fields.string("name")!
}

public /* abstract */ class PBXTarget : PBXProjectItem {
  public lazy var buildConfigurationList: XCConfigurationList = self.object("buildConfigurationList")
  public lazy var name: String = self.fields.string("name")!
  public lazy var productName: String = self.fields.string("productName")!
  public lazy var buildPhases: [PBXBuildPhase] = self.objects("buildPhases")
}

public class PBXAggregateTarget : PBXTarget {
}

public class PBXNativeTarget : PBXTarget {
}

public class PBXTargetDependency : PBXProjectItem {
}

public class XCConfigurationList : PBXProjectItem {
}

public class PBXReference : PBXContainerItem {
  public let name: String?
  public let path: String?
  public let sourceTree: SourceTree

  public required init(id: String, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.optionalString("name")
    self.path = try fields.optionalString("path")

    let sourceTreeString = try fields.string2("sourceTree")
    guard let sourceTree = SourceTree(sourceTreeString: sourceTreeString) else {
      throw AllObjectsError.wrongType(key: sourceTreeString)
    }
    self.sourceTree = sourceTree

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXFileReference : PBXReference {

  // convenience accessor
  public lazy var fullPath: Path = self.allObjects.fullFilePaths[self.id]!
}

public class PBXReferenceProxy : PBXReference {

  // convenience accessor
  public lazy var remoteRef: PBXContainerItemProxy = self.object("remoteRef")
}

public class PBXGroup : PBXReference {
  public lazy var children: [PBXReference] = self.objects("children")

  // convenience accessors
  public lazy var subGroups: [PBXGroup] = self.children.ofType(PBXGroup.self)
  public lazy var fileRefs: [PBXFileReference] = self.children.ofType(PBXFileReference.self)
}

public class PBXVariantGroup : PBXGroup {
}

public class XCVersionGroup : PBXReference {
}


public enum SourceTree {
  case absolute
  case group
  case relativeTo(SourceTreeFolder)

  init?(sourceTreeString: String) {
    switch sourceTreeString {
    case "<absolute>":
      self = .absolute

    case "<group>":
      self = .group

    default:
      guard let sourceTreeFolder = SourceTreeFolder(rawValue: sourceTreeString) else { return nil }
      self = .relativeTo(sourceTreeFolder)
    }
  }
}

public enum SourceTreeFolder: String {
  case sourceRoot = "SOURCE_ROOT"
  case buildProductsDir = "BUILT_PRODUCTS_DIR"
  case developerDir = "DEVELOPER_DIR"
  case sdkRoot = "SDKROOT"
}

public enum Path {
  case absolute(String)
  case relativeTo(SourceTreeFolder, String)

  public func url(with urlForSourceTreeFolder: (SourceTreeFolder) -> URL) -> URL {
    switch self {
    case let .absolute(absolutePath):
      return URL(fileURLWithPath: absolutePath).standardizedFileURL

    case let .relativeTo(sourceTreeFolder, relativePath):
      let sourceTreeURL = urlForSourceTreeFolder(sourceTreeFolder)
      return sourceTreeURL.appendingPathComponent(relativePath).standardizedFileURL
    }
  }

}

