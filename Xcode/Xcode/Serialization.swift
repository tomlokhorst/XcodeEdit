//
//  Serialization.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

extension XCProjectFile {

  public func writeToXcodeproj(xcodeprojPath: String) throws -> Bool {

    let url = NSURL(fileURLWithPath: xcodeprojPath, isDirectory: true)
    try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)

    let name = try XCProjectFile.projectName(xcodeprojPath)
    let path = xcodeprojPath + "/project.pbxproj"

    allObjects.projectName = name

    if format == NSPropertyListFormat.OpenStepFormat {
      try openStepSerialization.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
      return true
    }
    else {
      let data = try NSPropertyListSerialization.dataWithPropertyList(dict, format: format, options: 0)
      return data.writeToFile(path, atomically: true)
    }
  }

  public func serialize(projectName: String) throws -> NSData {
    allObjects.projectName = projectName

    if format == NSPropertyListFormat.OpenStepFormat {
      return openStepSerialization.dataUsingEncoding(NSUTF8StringEncoding)!
    }
    else {
      return try NSPropertyListSerialization.dataWithPropertyList(dict, format: format, options: 0)
    }
  }
}

let nonescapeRegex = try! NSRegularExpression(pattern: "^[a-z0-9_\\.\\/]+$", options: NSRegularExpressionOptions.CaseInsensitive)
let specialRegexes = [
  "\\\\": try! NSRegularExpression(pattern: "\\\\", options: []),
  "\\\"": try! NSRegularExpression(pattern: "\"", options: []),
  "\\n": try! NSRegularExpression(pattern: "\\n", options: []),
  "\\r": try! NSRegularExpression(pattern: "\\r", options: []),
  "\\t": try! NSRegularExpression(pattern: "\\t", options: []),
]

extension XCProjectFile {
  var openStepSerialization: String {
    var lines = [
      "// !$*UTF8*$!",
      "{",
    ]

    for key in dict.keys.sort() {
      let val: AnyObject = dict[key]!

      if key == "objects" {

        lines.append("\tobjects = {")

        let isas = Set(allObjects.dict.values.map { $0.isa })

        for isa in isas.sort() {
          lines.append("")
          lines.append("/* Begin \(isa) section */")
          let objects = allObjects.dict.values.filter { $0.isa == isa }

          for object in objects.sort({ $0.id < $1.id }) {

            let multiline = isa != "PBXBuildFile" && isa != "PBXFileReference"

            let parts = rows(isa, objKey: object.id, multiline: multiline, dict: object.dict)
            if multiline {
              for ln in parts {
                lines.append("\t\t" + ln)
              }
            }
            else {
              lines.append("\t\t" + parts.joinWithSeparator(""))
            }
          }

          lines.append("/* End \(isa) section */")
        }
        lines.append("\t};")
      }
      else {
        var comment = "";
        if key == "rootObject" {
          comment = " /* Project object */"
        }

        let row = "\(key) = \(val)\(comment);"
        for line in row.componentsSeparatedByString("\n") {
          lines.append("\t\(line)")
        }
      }
    }

    lines.append("}\n")

    return lines.joinWithSeparator("\n")
  }

  func comment(key: String, verbose: Bool) -> String? {
    if key == project.id {
      return "Project object"
    }

    if let obj = allObjects[key] {
      if let name = obj.dict["name"] as? String {
        return name
      }
      if let path = obj.dict["path"] as? String {
        return path
      }
      if let ref = obj as? PBXReference {
        return ref.name ?? ref.path
      }
      if let nativeTarget = obj as? PBXNativeTarget {
        return verbose ? nativeTarget.name : nil
      }
      if let config = obj as? XCBuildConfiguration {
        return config.name
      }
      if let copyFiles = obj as? PBXCopyFilesBuildPhase {
        return copyFiles.name
      }
      if obj is PBXFrameworksBuildPhase {
        return "Frameworks"
      }
      if obj is PBXSourcesBuildPhase {
        return "Sources"
      }
      if obj is PBXResourcesBuildPhase {
        return "Resources"
      }
      if obj is PBXShellScriptBuildPhase {
        return "ShellScript"
      }
      if let shellScript = obj as? PBXShellScriptBuildPhase {
        return shellScript.name
      }
      if let buildFile = obj as? PBXBuildFile {
        // TODO: move these lookup tables outside of this function
        let objects = Array(allObjects.dict.values)
        let buildPhases = objects.ofType(PBXBuildPhase)
        let buildPhase = buildPhases.filter { $0.files.any { $0.id == key } }.first

        if let buildPhase = buildPhase,
          let fileRef = comment(buildFile.fileRef.id, verbose: verbose),
          let group = comment(buildPhase.id, verbose: verbose) {

            return "\(fileRef) in \(group)"
        }
      }
      if obj is XCConfigurationList {
        // TODO: move these lookup tables outside of this function
        let objects = Array(allObjects.dict.values)
        let targets = objects.ofType(PBXTarget)
        if let target = targets.filter({ $0.buildConfigurationList.id == key }).first {
          return "Build configuration list for \(target.isa) \"\(target.name)\""
        }
        let projects = objects.ofType(PBXProject)
        if let project = projects.filter({ $0.buildConfigurationList.id == key }).first {
          return "Build configuration list for \(project.isa) \"\(allObjects.projectName)\""
        }
      }

      return obj.isa
    }

    return nil
  }

  func valStr(val: String) -> String {

    var str = val
    for (replacement, regex) in specialRegexes {
      let range = NSRange(location: 0, length: str.utf16.count)
      let template = NSRegularExpression.escapedTemplateForString(replacement)
      str = regex.stringByReplacingMatchesInString(str, options: [], range: range, withTemplate: template)
    }

    let range = NSRange(location: 0, length: str.utf16.count)
    if let _ = nonescapeRegex.firstMatchInString(str, options: [], range: range) {
      return str
    }

    return "\"\(str)\""
  }

  func objval(key: String, val: AnyObject, multiline: Bool) -> [String] {
    var parts: [String] = []
    let keyStr = valStr(key)

    if let valArr = val as? [String] {
      parts.append("\(keyStr) = (")

      var ps: [String] = []
      for valItem in valArr {
        let str = valStr(valItem)

        var extraComment = ""
        if let c = comment(valItem, verbose: true) {
          extraComment = " /* \(c) */"
        }

        ps.append("\(str)\(extraComment),")
      }
      if multiline {
        for p in ps {
          parts.append("\t\(p)")
        }
        parts.append(");")
      }
      else {
        parts.append(ps.joinWithSeparator("") + " ); ")
      }

    }
    else if let valObj = val as? [String: AnyObject] {
      parts.append("\(keyStr) = {")

      for valKey in valObj.keys.sort() {
        let valVal: AnyObject = valObj[valKey]!
        let ps = objval(valKey, val: valVal, multiline: multiline)

        if multiline {
          for p in ps {
            parts.append("\t\(p)")
          }
        }
        else {
          parts.append(ps.joinWithSeparator("") + "}; ")
        }
      }

      if multiline {
        parts.append("};")
      }

    }
    else {
      let str = valStr("\(val)")

      var extraComment = "";
      if let c = comment(str, verbose: false) {
        extraComment = " /* \(c) */"
      }

      if key == "remoteGlobalIDString" || key == "TestTargetID" {
        extraComment = ""
      }

      if multiline {
        parts.append("\(keyStr) = \(str)\(extraComment);")
      }
      else {
        parts.append("\(keyStr) = \(str)\(extraComment); ")
      }
    }

    return parts
  }

  func rows(type: String, objKey: String, multiline: Bool, dict: JsonObject) -> [String] {

    var parts: [String] = []
    if multiline {
      parts.append("isa = \(type);")
    }
    else {
      parts.append("isa = \(type); ")
    }

    for key in dict.keys.sort() {
      if key == "isa" { continue }
      let val: AnyObject = dict[key]!

      for p in objval(key, val: val, multiline: multiline) {
        parts.append(p)
      }
    }


    var objComment = ""
    if let c = comment(objKey, verbose: true) {
      objComment = " /* \(c) */"
    }

    let opening = "\(objKey)\(objComment) = {"
    let closing = "};"

    if multiline {
      var lines: [String] = []
      lines.append(opening)
      for part in parts {
        lines.append("\t\(part)")
      }
      lines.append(closing)
      return lines
    }
    else {
      return [opening + parts.joinWithSeparator("") + closing]
    }
  }
}
