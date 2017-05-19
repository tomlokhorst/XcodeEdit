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
  internal var fields: Fields
  internal let allObjects: AllObjects

  public let id: Guid
  public let isa: String

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.id = id
    self.fields = fields
    self.allObjects = allObjects

    self.isa = try self.fields.string("isa")
  }
}

public /* abstract */ class PBXContainer : PBXObject {
}

public class PBXProject : PBXContainer {
  public let buildConfigurationList: Reference<XCConfigurationList>
  public let developmentRegion: String
  public let hasScannedForEncodings: Bool
  public let knownRegions: [String]
  public let mainGroup: Reference<PBXGroup>
  public let targets: [Reference<PBXNativeTarget>]
  public let projectReferences: [ProjectReference]?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.developmentRegion = try fields.string("developmentRegion")
    self.hasScannedForEncodings = try fields.bool("hasScannedForEncodings")
    self.knownRegions = try fields.strings("knownRegions")

    self.buildConfigurationList = allObjects.createReference(id: try fields.id("buildConfigurationList"))
    self.mainGroup = allObjects.createReference(id: try fields.id("mainGroup"))
    self.targets = allObjects.createReferences(ids: try fields.ids("targets"))

    if fields["projectReferences"] == nil {
      self.projectReferences = nil
    }
    else {
      let projectReferenceFields = try fields.fields("projectReferences")
      self.projectReferences = try projectReferenceFields
        .map { try ProjectReference(fields: $0, allObjects: allObjects) }
    }

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public class ProjectReference {
    public let ProductGroup: Reference<PBXGroup>
    public let ProjectRef: Reference<PBXFileReference>

    public required init(fields: Fields, allObjects: AllObjects) throws {
      self.ProductGroup = allObjects.createReference(id: try fields.id("ProductGroup"))
      self.ProjectRef = allObjects.createReference(id: try fields.id("ProjectRef"))
    }
  }
}

public /* abstract */ class PBXContainerItem : PBXObject {
}

public class PBXContainerItemProxy : PBXContainerItem {
}

public /* abstract */ class PBXProjectItem : PBXContainerItem {
}

public class PBXBuildFile : PBXProjectItem {
  public let fileRef: Reference<PBXReference>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.fileRef = allObjects.createOptionalReference(id: try fields.optionalId("fileRef"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}


public /* abstract */ class PBXBuildPhase : PBXProjectItem {
  public let files: [Reference<PBXBuildFile>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.files = allObjects.createReferences(ids: try fields.ids("files"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXCopyFilesBuildPhase : PBXBuildPhase {
  public let name: String?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.optionalString("name")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXFrameworksBuildPhase : PBXBuildPhase {
}

public class PBXHeadersBuildPhase : PBXBuildPhase {
}

public class PBXResourcesBuildPhase : PBXBuildPhase {
}

public class PBXShellScriptBuildPhase : PBXBuildPhase {
  public let name: String?
  public let shellScript: String

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.optionalString("name")
    self.shellScript = try fields.string("shellScript")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXSourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildStyle : PBXProjectItem {
}

public class XCBuildConfiguration : PBXBuildStyle {
  public let name: String

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.string("name")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public /* abstract */ class PBXTarget : PBXProjectItem {
  public let buildConfigurationList: Reference<XCConfigurationList>
  public let name: String
  public let productName: String
  public let buildPhases: [Reference<PBXBuildPhase>]
  public let dependencies: [Reference<PBXTargetDependency>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildConfigurationList = allObjects.createReference(id: try fields.id("buildConfigurationList"))
    self.name = try fields.string("name")
    self.productName = try fields.string("productName")
    self.buildPhases = allObjects.createReferences(ids: try fields.ids("buildPhases"))
    self.dependencies = allObjects.createReferences(ids: try fields.ids("dependencies"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXAggregateTarget : PBXTarget {
}

public class PBXNativeTarget : PBXTarget {
}

public class PBXTargetDependency : PBXProjectItem {
  public let targetProxy: Reference<PBXContainerItemProxy>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.targetProxy = allObjects.createReference(id: try fields.id("targetProxy"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class XCConfigurationList : PBXProjectItem {
  public let buildConfigurations: [Reference<XCBuildConfiguration>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildConfigurations = allObjects.createReferences(ids: try fields.ids("buildConfigurations"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXReference : PBXContainerItem {
  public let name: String?
  public let path: String?
  public let sourceTree: SourceTree

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.optionalString("name")
    self.path = try fields.optionalString("path")

    let sourceTreeString = try fields.string("sourceTree")
    guard let sourceTree = SourceTree(sourceTreeString: sourceTreeString) else {
      throw AllObjectsError.wrongType(key: sourceTreeString)
    }
    self.sourceTree = sourceTree

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXFileReference : PBXReference {
  public let lastKnownFileType: String?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.lastKnownFileType = try fields.optionalString("lastKnownFileType")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  // convenience accessor
  public var fullPath: Path? {
    return self.allObjects.fullFilePaths[self.id]
  }

}

public class PBXReferenceProxy : PBXReference {

  public let remoteRef: Reference<PBXContainerItemProxy>

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.remoteRef = allObjects.createReference(id: try fields.id("remoteRef"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXGroup : PBXReference {
  public let children: [Reference<PBXReference>]

  // convenience accessors
  public var subGroups: [Reference<PBXGroup>] {
    return self.children.flatMap { childRef in
      guard let _ = childRef.value as? PBXGroup else { return nil }

      return Reference(allObjects: childRef.allObjects, id: childRef.id)
    }
  }

  public var fileRefs: [Reference<PBXFileReference>] {
    return self.children.flatMap { childRef in
      guard let _ = childRef.value as? PBXFileReference else { return nil }

      return Reference(allObjects: childRef.allObjects, id: childRef.id)
    }
  }

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.children = allObjects.createReferences(ids: try fields.ids("children"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXVariantGroup : PBXGroup {
}

public class XCVersionGroup : PBXReference {
  public let children: [Reference<PBXFileReference>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.children = allObjects.createReferences(ids: try fields.ids("children"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
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

