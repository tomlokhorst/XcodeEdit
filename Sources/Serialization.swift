//
//  Serialization.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

extension XCProjectFile {

  public func write(to url: URL, format: PropertyListSerialization.PropertyListFormat? = nil) throws {

    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

    let name = try XCProjectFile.projectName(from: url)
    let path = url.appendingPathComponent("project.pbxproj", isDirectory: false)

    let serializer = Serializer(projectName: name, projectFile: self)
    let plformat = format ?? self.format

    if plformat == PropertyListSerialization.PropertyListFormat.openStep {
      try serializer.openStepSerialization.write(to: path, atomically: true, encoding: String.Encoding.utf8)
    }
    else {
      let data = try PropertyListSerialization.data(fromPropertyList: fields, format: plformat, options: 0)
      try data.write(to: path)
    }
  }

  public func serialized(projectName: String) throws -> Data {

    let serializer = Serializer(projectName: projectName, projectFile: self)

    if format == PropertyListSerialization.PropertyListFormat.openStep {
      return serializer.openStepSerialization.data(using: String.Encoding.utf8)!
    }
    else {
      return try PropertyListSerialization.data(fromPropertyList: fields, format: format, options: 0)
    }
  }
}

private let nonescapeRegex = try! NSRegularExpression(pattern: "^[a-z0-9_\\$\\.\\/]+$", options: NSRegularExpression.Options.caseInsensitive)
private let specialRegexes = [
  "\\\\": try! NSRegularExpression(pattern: "\\\\", options: []),
  "\\\"": try! NSRegularExpression(pattern: "\"", options: []),
  "\\n": try! NSRegularExpression(pattern: "\\n", options: []),
  "\\r": try! NSRegularExpression(pattern: "\\r", options: []),
  "\\t": try! NSRegularExpression(pattern: "\\t", options: []),
]

internal class Serializer {

  let projectName: String
  let projectFile: XCProjectFile

  init(projectName: String, projectFile: XCProjectFile) {
    self.projectName = projectName
    self.projectFile = projectFile
  }

  lazy var targetsByConfigId: [Guid: PBXNativeTarget] = {
    var dict: [Guid: PBXNativeTarget] = [:]
    for reference in self.projectFile.project.targets {
      if let target = reference.value {
        dict[target.buildConfigurationList.id] = target
      }
    }

    return dict
  }()

  lazy var buildPhaseByFileId: [Guid: PBXBuildPhase] = {

    let buildPhases = self.projectFile.allObjects.objects.values.compactMap { $0 as? PBXBuildPhase }

    var dict: [Guid: PBXBuildPhase] = [:]
    for buildPhase in buildPhases {
      for file in buildPhase.files {
        dict[file.id] = buildPhase
      }
    }

    return dict
  }()

  var openStepSerialization: String {
    var lines = [
      "// !$*UTF8*$!",
      "{",
    ]

    for key in projectFile.fields.keys.sorted() {
      let val = projectFile.fields[key]!

      if key == "objects" {

        lines.append("\tobjects = {")

        let groupedObjects = projectFile.allObjects.objects.values
          .grouped { $0.isa }
          .map { (isa: $0.0, objects: $0.1) }
          .sorted { $0.isa }

        for (isa, objects) in groupedObjects {
          lines.append("")
          lines.append("/* Begin \(isa) section */")

          for object in objects.sorted(by: { $0.id }) {

            let multiline = isa != "PBXBuildFile" && isa != "PBXFileReference"

            let parts = rows(type: isa, objectId: object.id, multiline: multiline, fields: object.fields)
            if multiline {
              for ln in parts {
                lines.append("\t\t" + ln)
              }
            }
            else {
              lines.append("\t\t" + parts.joined(separator: ""))
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
        for line in row.components(separatedBy: "\n") {
          lines.append("\t\(line)")
        }
      }
    }

    lines.append("}\n")

    return lines.joined(separator: "\n")
  }

  func comment(id: Guid) -> String? {
    if id == projectFile.project.id {
      return "Project object"
    }

    if let obj = projectFile.allObjects.objects[id] {
      if let ref = obj as? PBXReference {
        return ref.name ?? ref.path
      }
      if let target = obj as? PBXTarget {
        return target.name
      }
      if let config = obj as? XCBuildConfiguration {
        return config.name
      }
      if let copyFiles = obj as? PBXCopyFilesBuildPhase {
        return copyFiles.name ?? "CopyFiles"
      }
      if obj is PBXFrameworksBuildPhase {
        return "Frameworks"
      }
      if obj is PBXHeadersBuildPhase {
        return "Headers"
      }
      if obj is PBXResourcesBuildPhase {
        return "Resources"
      }
      if let shellScript = obj as? PBXShellScriptBuildPhase {
        return shellScript.name ?? "ShellScript"
      }
      if obj is PBXSourcesBuildPhase {
        return "Sources"
      }
      if let buildFile = obj as? PBXBuildFile {
        if let buildPhase = buildPhaseByFileId[id],
          let group = comment(id: buildPhase.id) {

          if let fileRefId = buildFile.fileRef?.id {
            if let fileRef = comment(id: fileRefId) {
              return "\(fileRef) in \(group)"
            }
          }
          else {
            return "(null) in \(group)"
          }
        }
      }
      if obj is XCConfigurationList {
        if let target = targetsByConfigId[id] {
          return "Build configuration list for \(target.isa) \"\(target.name)\""
        }
        return "Build configuration list for PBXProject \"\(projectName)\""
      }

      return obj.isa
    }

    return nil
  }

  func valStr(_ val: String) -> String {

    var str = val
    for (replacement, regex) in specialRegexes {
      let range = NSRange(location: 0, length: str.utf16.count)
      let template = NSRegularExpression.escapedTemplate(for: replacement)
      str = regex.stringByReplacingMatches(in: str, options: [], range: range, withTemplate: template)
    }

    let range = NSRange(location: 0, length: str.utf16.count)
    if let _ = nonescapeRegex.firstMatch(in: str, options: [], range: range) {
      return str
    }

    return "\"\(str)\""
  }

  func objval(key: String, val: Any, multiline: Bool) -> [String] {
    var parts: [String] = []
    let keyStr = valStr(key)

    if let valArr = val as? [String] {
      parts.append("\(keyStr) = (")

      var ps: [String] = []
      for valItem in valArr {
        let str = valStr(valItem)

        var extraComment = ""
        if let c = comment(id: Guid(valItem)) {
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
        parts.append(ps.map { $0 + " "}.joined(separator: "") + "); ")
      }

    }
    else if let valArr = val as? [Fields] {
      parts.append("\(keyStr) = (")

      for valObj in valArr {
        if multiline {
          parts.append("\t{")
        }

        for valKey in valObj.keys.sorted() {
          let valVal = valObj[valKey]!
          let ps = objval(key: valKey, val: valVal, multiline: multiline)

          if multiline {
            for p in ps {
              parts.append("\t\t\(p)")
            }
          }
          else {
            parts.append("\t" + ps.joined(separator: "") + "}; ")
          }
        }

        if multiline {
          parts.append("\t},")
        }
      }

      parts.append(");")

    }
    else if let valObj = val as? Fields {
      parts.append("\(keyStr) = {")

      for valKey in valObj.keys.sorted() {
        let valVal = valObj[valKey]!
        let ps = objval(key: valKey, val: valVal, multiline: multiline)

        if multiline {
          for p in ps {
            parts.append("\t\(p)")
          }
        }
        else {
          parts.append(ps.joined(separator: "") + "}; ")
        }
      }

      if multiline {
        parts.append("};")
      }

    }
    else {
      let str = valStr("\(val)")

      var extraComment = "";
      if let c = comment(id: Guid(str)) {
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

  func rows(type: String, objectId: Guid, multiline: Bool, fields: Fields) -> [String] {

    var parts: [String] = []
    if multiline {
      parts.append("isa = \(type);")
    }
    else {
      parts.append("isa = \(type); ")
    }

    for key in fields.keys.sorted() {
      if key == "isa" { continue }
      let val = fields[key]!

      for p in objval(key: key, val: val, multiline: multiline) {
        parts.append(p)
      }
    }

    var objComment = ""
    if let c = comment(id: objectId) {
      objComment = " /* \(c) */"
    }

    let opening = "\(objectId.value)\(objComment) = {"
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
      return [opening + parts.joined(separator: "") + closing]
    }
  }
}
