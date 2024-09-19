//
//  main.swift
//  Example
//
//  Created by Tom Lokhorst on 2015-08-14.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

let args = CommandLine.arguments

if args.count < 2 {
  print("Call with a .xcodeproj, e.g.: \"$SRCROOT/../Test projects/HelloCpp.xcodeproj\"")
}

let start = Date()

// The xcodeproj file to load, test this with your own project!
let xcodeproj = URL(fileURLWithPath: args[1])
let proj = try! XCProjectFile(xcodeprojURL: xcodeproj)

for obj in proj.allObjects.objects.values {
  if let dep = obj as? XCSwiftPackageProductDependency {
    if dep.productName?.hasPrefix("plugin:") == true {
      dep.removePackage()
    }
  }
}

// Write out a new pbxproj file
//try! proj.write(to: xcodeproj, format: .plist(.openStep))


public struct Xcodeproj {
    static public let supportedExtensions: Set<String> = ["xcodeproj"]

    private let projectFile: XCProjectFile

    public let developmentRegion: String
    public let knownAssetTags: [String]?

    public init(url: URL, warning: (String) -> Void) throws {
//        try Xcodeproj.throwIfUnsupportedExtension(url)
        let projectFile: XCProjectFile

        // Parse project file
        do {
            do {
                projectFile = try XCProjectFile(xcodeprojURL: url, ignoreReferenceErrors: false)
            }
            catch let error as ProjectFileError {
                warning(error.localizedDescription)

                projectFile = try XCProjectFile(xcodeprojURL: url, ignoreReferenceErrors: true)
            }
        }
        catch {
            fatalError("Project file at '\(url)' could not be parsed, is this a valid Xcode project file ending in *.xcodeproj?\n\(error.localizedDescription)")
        }

        self.projectFile = projectFile
        self.developmentRegion = projectFile.project.developmentRegion
        self.knownAssetTags = projectFile.project.knownAssetTags
    }

    public var allTargets: [PBXTarget] {
        projectFile.project.targets.compactMap { $0.value }
    }

    private func findTarget(name: String) throws -> PBXTarget {
        // Look for target in project file
        let allTargets = projectFile.project.targets.compactMap { $0.value }
        guard let target = allTargets.filter({ $0.name == name }).first else {
            let availableTargets = allTargets.compactMap { $0.name }.joined(separator: ", ")
            fatalError("Target '\(name)' not found in project file, available targets are: \(availableTargets)")
        }

        return target
    }

    public func resourcePaths(forTarget targetName: String) throws -> [Path] {
        let target = try findTarget(name: targetName)

        let resourcesFileRefs = target.buildPhases
            .compactMap { $0.value as? PBXResourcesBuildPhase }
            .flatMap { $0.files }
            .compactMap { $0.value?.fileRef }

        let fileRefPaths = resourcesFileRefs
            .compactMap { $0.value as? PBXFileReference }
            .compactMap { $0.fullPath }

        let variantGroupPaths = resourcesFileRefs
            .compactMap { $0.value as? PBXVariantGroup }
            .flatMap { $0.fileRefs }
            .compactMap { $0.value?.fullPath }

        return fileRefPaths + variantGroupPaths
    }

    public func buildConfigurations(forTarget targetName: String) throws -> [XCBuildConfiguration] {
        let target = try findTarget(name: targetName)

        guard let buildConfigurationList = target.buildConfigurationList.value else { return [] }

        let buildConfigurations = buildConfigurationList.buildConfigurations
            .compactMap { $0.value }

        return buildConfigurations
    }
}

extension PBXReference {
  func fileSystemSynchronizedGroups(path: URL) -> [(URL, PBXFileSystemSynchronizedRootGroup)] {
    if let root = self as? PBXFileSystemSynchronizedRootGroup {
      let newPath = root.path.map { path.appending(path: $0) } ?? path
      return [(newPath, root)]
    } else if let group = self as? PBXGroup {
      let newPath = group.path.map { path.appending(path: $0) } ?? path

      let children = group.children.compactMap(\.value)

      return children.flatMap { $0.fileSystemSynchronizedGroups(path: newPath) }

    } else {
      return []
    }
  }
}


let the = try Xcodeproj(url: xcodeproj, warning: { fatalError($0)})

print(proj.project.mainGroup.value!.fileSystemSynchronizedGroups(path: xcodeproj.deletingLastPathComponent()))

print(try the.resourcePaths(forTarget: "RswiftUIAppClip"))

let time = Date().timeIntervalSince(start)
print("Timeinterval: \(time)")

exit(0)

// Print paths for all files in Resources build phases
//for target in proj.project.targets.flatMap({ $0.value }) {
//  for resourcesBuildPhase in target.buildPhases.flatMap({ $0.value }) {
//    let files = resourcesBuildPhase.files.flatMap { $0.value }
//    for file in files {
//      if let fileReference = file.fileRef?.value as? PBXFileReference {
//        print(fileReference.fullPath!)
//      }
//      // Variant groups are localizable
//      else if let variantGroup = file.fileRef?.value as? PBXVariantGroup {
//        let fileRefs = variantGroup.fileRefs.flatMap { $0.value }
//        for variantFileReference in fileRefs {
//          print(variantFileReference.fullPath!)
//        }
//      }
//    }
//  }
//}

// Print shells
for target in proj.project.targets.compactMap({ $0.value }) {

  print("Target \(target.name) - \(target.isa): \(target.buildPhases.count)")
  for bc in target.buildConfigurationList.value!.buildConfigurations.map({ $0.value! }) {
    print(bc.fields)
  }
  print("--")

  for buildPhase in target.buildPhases {
    print(buildPhase.value!)
//    if let shellScriptPhase = buildPhase.value as? PBXShellScriptBuildPhase {
//      print(shellScriptPhase.shellScript)
//    }
    print()
  }

}

