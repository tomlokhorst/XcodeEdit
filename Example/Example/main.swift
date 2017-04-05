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

// Load from a xcodeproj
do {
  let p = try XCProjectFile(xcodeprojURL: xcodeproj)
  print("\(p.project.developmentRegion)")
  print("\(p.project.hasScannedForEncodings)")
  print("\(p.project.knownRegions)")
  print("\(p.project.buildConfigurationList)")
}
catch {
  print(String(describing: error))
  fatalError()
}
let proj = try! XCProjectFile(xcodeprojURL: xcodeproj)

var one = true
for target in proj.project.targets {
  for resourcesBuildPhase in target.buildPhases.ofType(PBXResourcesBuildPhase.self) {
    for file in resourcesBuildPhase.files {
      if file.fileRef?.id == "42A01CB619F4EC63001F2A12" && one {
        one = false

        // BuildFile: 07279C0F1A5AC565005F8996
        let fields : Fields = [
          "isa": "PBXFileReference" as NSString,
          "sourceTree": "<absolute>" as NSString,
          "path": "Tom.jpg" as NSString
        ]
        let fileRef = try! PBXFileReference(id: "TOM", fields: fields, allObjects: AllObjects())

        file.fileRef = file.allObjects.createReference(value: fileRef)
        print("> \(file)")
      }
    }
  }
}

// Write out a new pbxproj file
try! proj.write(to: xcodeproj, format: PropertyListSerialization.PropertyListFormat.openStep)

let time = Date().timeIntervalSince(start)
print("Timeinterval: \(time)")

exit(0)

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

