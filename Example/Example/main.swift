//
//  main.swift
//  Example
//
//  Created by Tom Lokhorst on 2015-08-14.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

let args = Process.arguments

if args.count < 2 {
  print("Call with a .xcodeproj, e.g.: \"$SRCROOT/../Test projects/HelloCpp.xcodeproj\"")
}

// The xcodeproj file to load, test this with your own project!
let xcodeproj = URL(fileURLWithPath: args[1])

// Load from a xcodeproj
let proj = try! XCProjectFile(xcodeprojURL: xcodeproj)

// Write out a new pbxproj file
try! proj.write(to: xcodeproj, format: PropertyListSerialization.PropertyListFormat.openStep)

// Print paths for all files in Resources build phases
for target in proj.project.targets {
  for resourcesBuildPhase in target.buildPhases.ofType(PBXResourcesBuildPhase.self) {
    for file in resourcesBuildPhase.files {
      if let fileReference = file.fileRef as? PBXFileReference {
        print(fileReference.fullPath)
      }
        // Variant groups are localizable
      else if let variantGroup = file.fileRef as? PBXVariantGroup {
        for variantFileReference in variantGroup.fileRefs {
          print(variantFileReference.fullPath)
        }
      }
    }
  }
}

// Print shells
for target in proj.project.targets {
  for buildPhase in target.buildPhases {
    print(buildPhase)
    if let shellScriptPhase = buildPhase as? PBXShellScriptBuildPhase {
      print(shellScriptPhase.shellScript)
    }
  }
}

