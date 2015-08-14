//
//  XCProjectFile.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-12.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

typealias JsonObject = [String: AnyObject]

extension Array {
  func ofType<T>(type: T.Type) -> [T] {
    return self.filter { $0 is T }.map { $0 as! T }
  }
}

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

class AllObjects {
  var dict: [String: PBXObject] = [:]
  var fullFilePaths: [String: String] = [:]

  subscript(key: String) -> PBXObject? {
    get { return dict[key] }
  }

  func object<T : PBXObject>(key: String) -> T {
    let obj = dict[key]!
    if let t = obj as? T {
      return t
    }

    return T(id: key, dict: obj.dict, allObjects: self)
  }
}

public class XCProjectFile {
  public let project: PBXProject
  let dict: JsonObject
  let allObjects = AllObjects()

  public init(jsonString: String) {

    let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding)
    let obj : AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments, error: nil)

    self.dict = obj as! JsonObject
    let objects = dict["objects"] as! [String: JsonObject]

    for (key, obj) in objects {
      allObjects.dict[key] = XCProjectFile.createObject(key, dict: obj, allObjects: allObjects)
    }

    let rootObjectId = dict["rootObject"]! as! String
    let projDict = objects[rootObjectId]!
    self.project = PBXProject(id: rootObjectId, dict: projDict, allObjects: allObjects)
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func createObject(id: String, dict: JsonObject, allObjects: AllObjects) -> PBXObject {
    let isa = dict["isa"] as? String

    if isa == "PBXNativeTarget" {
      return PBXNativeTarget(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildPhase" {
      return PBXBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXResourcesBuildPhase" {
      return PBXResourcesBuildPhase(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXBuildFile" {
      return PBXBuildFile(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXVariantGroup" {
      return PBXVariantGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXGroup" {
      return PBXGroup(id: id, dict: dict, allObjects: allObjects)
    }
    if isa == "PBXFileReference" {
      return PBXFileReference(id: id, dict: dict, allObjects: allObjects)
    }

    // Fallback
    return PBXObject(id: id, dict: dict, allObjects: allObjects)
  }

  func paths(current: PBXGroup, prefix: String) -> [String: String] {
    var ps: [String: String] = [:]

    for file in current.fileRefs {
      ps[file.id] = prefix + "/" + file.path
    }

    for group in current.subGroups {
      if let path = group.path {
        ps += paths(group, prefix: prefix + "/" + path)
      }
      else {
        ps += paths(group, prefix: prefix)
      }
    }

    return ps
  }
}

public class PBXObject {
  let id: String
  let dict: JsonObject
  let allObjects: AllObjects

  init(id: String, dict: AnyObject, allObjects: AllObjects) {
    self.id = id
    self.dict = dict as! JsonObject
    self.allObjects = allObjects
  }

  func string(key: String) -> String? {
    return dict[key] as? String
  }

  func object<T : PBXObject>(key: String) -> T {
    let objectKey = dict[key] as! String
    return allObjects.object(objectKey)
  }

  func objects<T : PBXObject>(key: String) -> [T] {
    let objectKeys = dict[key] as! [String]
    return objectKeys.map(allObjects.object)
  }
}

public class PBXProject : PBXObject {
  public lazy var targets: [PBXNativeTarget] = self.objects("targets")
  public lazy var mainGroup: PBXGroup = self.object("mainGroup")
}

public class PBXNativeTarget : PBXObject {
  public lazy var productName: String = self.string("productName")!
  public lazy var buildPhases: [PBXBuildPhase] = self.objects("buildPhases")
}

public class PBXBuildPhase : PBXObject {
  public lazy var files: [PBXBuildFile] = self.objects("files")
}

public class PBXResourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildFile : PBXObject {
  public lazy var fileRef: PBXReference = self.object("fileRef")
}

public class PBXReference : PBXObject {
}

public class PBXGroup : PBXReference {
  public lazy var name: String = self.string("name")!
  public lazy var path: String? = self.string("path")
  public lazy var children: [PBXReference] = self.objects("children")

  // convenience accessors
  public lazy var subGroups: [PBXGroup] = self.children.ofType(PBXGroup.self)
  public lazy var fileRefs: [PBXFileReference] = self.children.ofType(PBXFileReference)

}

public class PBXVariantGroup : PBXGroup {
}

public class PBXFileReference : PBXReference {
  public lazy var path: String = self.string("path")!

  // convenience accessor
  public lazy var fullPath: String = self.allObjects.fullFilePaths[self.id]!
}
