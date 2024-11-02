//
//  PBXObject.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

public typealias Fields = [String: Any]

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
  public let attributes: Fields?
  public let developmentRegion: String
  public let hasScannedForEncodings: Bool
  public let knownRegions: [String]?
  public let knownAssetTags: [String]?
  public let mainGroup: Reference<PBXGroup>
  public let packageReferences: [Reference<XCSwiftPackageReference>]?
  public let targets: [Reference<PBXTarget>]
  public let projectReferences: [ProjectReference]?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.attributes = try fields.optionalFields("attributes")
    self.developmentRegion = try fields.string("developmentRegion")
    self.hasScannedForEncodings = try fields.bool("hasScannedForEncodings")
    self.knownRegions = try fields.optionalStrings("knownRegions")
    self.knownAssetTags = try attributes?.optionalStrings("KnownAssetTags")
    self.buildConfigurationList = allObjects.createReference(id: try fields.id("buildConfigurationList"))
    self.mainGroup = allObjects.createReference(id: try fields.id("mainGroup"))
    self.packageReferences = allObjects.createOptionalReferences(ids: try fields.optionalIds("packageReferences"))
    self.targets = allObjects.createReferences(ids: try fields.ids("targets"))
    self.projectReferences = try fields.optionalFieldsArray("projectReferences")?
      .map { try ProjectReference(fields: $0, allObjects: allObjects) }

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public class ProjectReference {
    public let ProductGroup: Reference<PBXGroup>?
    public let ProjectRef: Reference<PBXFileReference>

    public required init(fields: Fields, allObjects: AllObjects) throws {
      self.ProductGroup = allObjects.createOptionalReference(id: try fields.optionalId("ProductGroup"))
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
  public let productRef: Reference<XCSwiftPackageProductDependency>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.fileRef = allObjects.createOptionalReference(id: try fields.optionalId("fileRef"))
    self.productRef = allObjects.createOptionalReference(id: try fields.optionalId("productRef"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}


public /* abstract */ class PBXBuildPhase : PBXProjectItem {
  private var _files: [Reference<PBXBuildFile>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self._files = allObjects.createReferences(ids: try fields.ids("files"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public var files: [Reference<PBXBuildFile>] {
    return _files
  }

  // Custom function for R.swift
  public func insertFile(_ reference: Reference<PBXBuildFile>, at index: Int) {
    if _files.contains(reference) { return }

    _files.insert(reference, at: index)
    fields["files"] = _files.map { $0.id.value }
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
  public let alwaysOutOfDate: Bool?
  public let inputFileListPaths: [String]?
  public let inputPaths: [String]?
  public let outputFileListPaths: [String]?
  public let outputPaths: [String]?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.optionalString("name")
    self.shellScript = try fields.string("shellScript")
    self.alwaysOutOfDate = try fields.optionalBool("alwaysOutOfDate")
    self.inputFileListPaths = try fields.optionalStrings("inputFileListPaths")
    self.inputPaths = try fields.optionalStrings("inputPaths")
    self.outputFileListPaths = try fields.optionalStrings("outputFileListPaths")
    self.outputPaths = try fields.optionalStrings("outputPaths")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXSourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildRule: PBXProjectItem {
}

public class PBXBuildStyle : PBXProjectItem {
}

public class XCBuildConfiguration : PBXBuildStyle {
  public let name: String
  public let buildSettings: [String: Any]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.name = try fields.string("name")
    self.buildSettings = try fields.fields("buildSettings")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public /* abstract */ class PBXTarget : PBXProjectItem {

  public let buildConfigurationList: Reference<XCConfigurationList>
  public let name: String
  public let productName: String?
  private var _buildPhases: [Reference<PBXBuildPhase>]
  public let dependencies: [Reference<PBXTargetDependency>]
  public let fileSystemSynchronizedGroups: [Reference<PBXFileSystemSynchronizedRootGroup>]?
  public let packageProductDependencies: [Reference<XCSwiftPackageProductDependency>]?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildConfigurationList = allObjects.createReference(id: try fields.id("buildConfigurationList"))
    self.name = try fields.string("name")
    self.productName = try fields.optionalString("productName")
    self._buildPhases = allObjects.createReferences(ids: try fields.ids("buildPhases"))
    self.dependencies = allObjects.createReferences(ids: try fields.ids("dependencies"))
    self.fileSystemSynchronizedGroups = allObjects.createOptionalReferences(ids: try fields.optionalIds("fileSystemSynchronizedGroups"))
    self.packageProductDependencies = allObjects.createOptionalReferences(ids: try fields.optionalIds("packageProductDependencies"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public var buildPhases: [Reference<PBXBuildPhase>] {
    return _buildPhases
  }

  // Custom function for R.swift
  public func insertBuildPhase(_ reference: Reference<PBXBuildPhase>, at index: Int) {
    if _buildPhases.contains(reference) { return }

    _buildPhases.insert(reference, at: index)
    fields["buildPhases"] = _buildPhases.map { $0.id.value }
  }
}

public class PBXAggregateTarget : PBXTarget {
}

public class PBXLegacyTarget : PBXTarget {
}

public class PBXNativeTarget : PBXTarget {
  public let buildRules: [Reference<PBXBuildRule>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildRules = allObjects.createReferences(ids: try fields.ids("buildRules"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXTargetDependency : PBXProjectItem {
  public let targetProxy: Reference<PBXContainerItemProxy>?

  // Note: Not sure if productRefs should only reference XCSwiftPackageProductDependency
  // or if it should refer to an extra superclass
  public let productRef: Reference<XCSwiftPackageProductDependency>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.targetProxy = allObjects.createOptionalReference(id: try fields.optionalId("targetProxy"))
    self.productRef = allObjects.createOptionalReference(id: try fields.optionalId("productRef"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

// Note: Not sure if ProjectItem is correct superclass
public class XCSwiftPackageProductDependency : PBXProjectItem {

  public let productName: String?
  public private(set) var package: Reference<XCRemoteSwiftPackageReference>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.productName = try fields.optionalString("productName")
    self.package = allObjects.createOptionalReference(id: try fields.optionalId("package"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  // Custom function for R.swift
  public func removePackage() {
    package = nil
    fields["package"] = nil
  }
}

// Note: Not sure if ProjectItem is correct superclass
public /* abstract */ class XCSwiftPackageReference : PBXProjectItem {
}

public class XCRemoteSwiftPackageReference : XCSwiftPackageReference {
  public let repositoryURL: URL?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.repositoryURL = try fields.optionalURL("repositoryURL")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class XCLocalSwiftPackageReference : XCSwiftPackageReference {
  public let relativePath: Path
  let pathString: String

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
      pathString = try fields.string("relativePath")
      self.relativePath = .relativeTo(.sourceRoot, pathString)
      
    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}


public class XCConfigurationList : PBXProjectItem {
  public let buildConfigurations: [Reference<XCBuildConfiguration>]
  public let defaultConfigurationName: String?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildConfigurations = allObjects.createReferences(ids: try fields.ids("buildConfigurations"))
    self.defaultConfigurationName = try fields.optionalString("defaultConfigurationName")

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public var defaultConfiguration: XCBuildConfiguration? {
    for configuration in buildConfigurations {
      if let configuration = configuration.value, configuration.name == defaultConfigurationName {
        return configuration
      }
    }

    return nil
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
    guard let sourceTree = SourceTree(rawValue: sourceTreeString) else {
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
  private var _children: [Reference<PBXReference>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self._children = allObjects.createReferences(ids: try fields.ids("children"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  public var children: [Reference<PBXReference>] {
    return _children
  }

  public var subGroups: [Reference<PBXGroup>] {
    return _children.compactMap { childRef in
      guard let _ = childRef.value as? PBXGroup else { return nil }
      return Reference(allObjects: childRef.allObjects, id: childRef.id)
    }
  }

  public var fileRefs: [Reference<PBXFileReference>] {
    return _children.compactMap { childRef in
      guard let _ = childRef.value as? PBXFileReference else { return nil }
      return Reference(allObjects: childRef.allObjects, id: childRef.id)
    }
  }

  public var syncRoots: [Reference<PBXFileSystemSynchronizedRootGroup>] {
    return _children.compactMap { childRef in
      guard let _ = childRef.value as? PBXFileSystemSynchronizedRootGroup else { return nil }
      return Reference(allObjects: childRef.allObjects, id: childRef.id)
    }
  }

  // Custom function for R.swift
  public func insertFileReference(_ fileReference: Reference<PBXFileReference>, at index: Int) {
    if fileRefs.contains(fileReference) { return }

    let reference = Reference<PBXReference>(allObjects: fileReference.allObjects, id: fileReference.id)
    _children.insert(reference, at: index)
    fields["children"] = _children.map { $0.id.value }
  }
}

public class PBXVariantGroup : PBXGroup {
}

public class PBXFileSystemSynchronizedRootGroup : PBXReference {
  public let exceptions: [Reference<PBXFileSystemSynchronizedBuildFileExceptionSet>]?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.exceptions = allObjects.createOptionalReferences(ids: try fields.optionalIds("exceptions"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }

  // convenience accessor
  public var fullPath: Path? {
    return self.allObjects.fullFilePaths[self.id]
  }
}

public class PBXFileSystemSynchronizedBuildFileExceptionSet : PBXObject {
  public let membershipExceptions: [String]?
  public let target: Reference<PBXTarget>

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.membershipExceptions = try fields.optionalStrings("membershipExceptions")
    self.target = allObjects.createReference(id: try fields.id("target"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet : PBXObject {
  public let buildPhase: Reference<PBXBuildPhase>?

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.buildPhase = allObjects.createOptionalReference(id: try fields.id("buildPhase"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}

public class XCVersionGroup : PBXReference {
  public let children: [Reference<PBXFileReference>]

  public required init(id: Guid, fields: Fields, allObjects: AllObjects) throws {
    self.children = allObjects.createReferences(ids: try fields.ids("children"))

    try super.init(id: id, fields: fields, allObjects: allObjects)
  }
}


public enum SourceTree: RawRepresentable {
  case absolute
  case group
  case relativeTo(SourceTreeFolder)

  public init?(rawValue: String) {
    switch rawValue {
    case "<absolute>":
      self = .absolute

    case "<group>":
      self = .group

    default:
      guard let sourceTreeFolder = SourceTreeFolder(rawValue: rawValue) else { return nil }
      self = .relativeTo(sourceTreeFolder)
    }
  }

  public var rawValue: String {
    switch self {
    case .absolute:
      return "<absolute>"
    case .group:
      return "<group>"
    case .relativeTo(let folter):
      return folter.rawValue
    }
  }
}

public enum SourceTreeFolder: String, Equatable {
  case sourceRoot = "SOURCE_ROOT"
  case buildProductsDir = "BUILT_PRODUCTS_DIR"
  case developerDir = "DEVELOPER_DIR"
  case sdkRoot = "SDKROOT"
  case platformDir = "PLATFORM_DIR"

  public static func ==(lhs: SourceTreeFolder, rhs: SourceTreeFolder) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

public enum Path: Equatable {
  case absolute(String)
  case relativeTo(SourceTreeFolder, String)

  @available(OSX 10.11, *)
  public func url(with urlForSourceTreeFolder: (SourceTreeFolder) -> URL) -> URL {
    switch self {
    case let .absolute(absolutePath):
      return URL(fileURLWithPath: absolutePath).standardizedFileURL

    case let .relativeTo(sourceTreeFolder, relativePath):
      let sourceTreeURL = urlForSourceTreeFolder(sourceTreeFolder)
      return URL(fileURLWithPath: relativePath, relativeTo: sourceTreeURL).standardizedFileURL
    }
  }

  public static func ==(lhs: Path, rhs: Path) -> Bool {
    switch (lhs, rhs) {
    case let (.absolute(lpath), .absolute(rpath)):
      return lpath == rpath

    case let (.relativeTo(lfolder, lpath), .relativeTo(rfolder, rpath)):
      let lurl = URL(string: lfolder.rawValue)!.appendingPathComponent(lpath).standardized
      let rurl = URL(string: rfolder.rawValue)!.appendingPathComponent(rpath).standardized

      return lurl == rurl

    default:
      return false
    }
  }
}
