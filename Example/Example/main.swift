//
//  main.swift
//  Example
//
//  Created by Tom Lokhorst on 2015-08-14.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

// The pbxproj file to load, test this with your own project!
let projectFile = "project.pbxproj"


// Parse JSON to XCProjectFile object
let proj = try! XCProjectFile(filename: projectFile)!

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

