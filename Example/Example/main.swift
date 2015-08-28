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


// Call plutil to convert pbxproj file to JSON
let task = NSTask()
task.launchPath = "/usr/bin/plutil"
task.arguments = ["-convert", "json", "-o", "-", projectFile]

let pipe = NSPipe()
task.standardOutput = pipe
task.launch()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = NSString(data: data, encoding: NSUTF8StringEncoding) as! String


// Parse JSON to XCProjectFile object
let proj = XCProjectFile(filename: "project.pbxproj")!

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

