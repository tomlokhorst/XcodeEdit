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

// Write out a new pbxproj file
try! proj.write(to: xcodeproj, format: PropertyListSerialization.PropertyListFormat.openStep)

let time = Date().timeIntervalSince(start)
print("Timeinterval: \(time)")

//exit(0)

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
for target in proj.project.targets.flatMap({ $0.value }) {

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

