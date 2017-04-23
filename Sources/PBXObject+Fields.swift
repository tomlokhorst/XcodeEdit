//
//  PBXObject+Fields.swift
//  Example
//
//  Created by Tom Lokhorst on 2017-04-23.
//  Copyright © 2017 nonstrict. All rights reserved.
//

import Foundation

extension Dictionary where Key == Guid, Value == AnyObject {
  mutating func set<Value>(key: Guid, reference: Reference<Value>?) {
    if let reference = reference {
      self[key] = reference.id.value as NSString
    }
    else {
      self[key] = nil
    }
  }
}

extension Dictionary where Key == String {

  func id(_ key: String) throws -> Guid {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return Guid(value)
  }

  func optionalId(_ key: String) throws -> Guid? {
    guard let val = self[key] else {
      return nil
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return Guid(value)
  }

  func ids(_ key: String) throws -> [Guid] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [String] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value.map(Guid.init)
  }

  func bool(_ key: String) throws -> Bool {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    switch value {
    case "0":
      return false

    case "1":
      return true

    default:
      throw AllObjectsError.wrongType(key: key)
    }
  }

  func optionalString(_ key: String) throws -> String? {
    guard let val = self[key] else {
      return nil
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func string(_ key: String) throws -> String {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? String else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func strings(_ key: String) throws -> [String] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [String] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }

  func fields(_ key: String) throws -> [Fields] {
    guard let val = self[key] else {
      throw AllObjectsError.fieldMissing(key: key)
    }
    guard let value = val as? [Fields] else {
      throw AllObjectsError.wrongType(key: key)
    }

    return value
  }
}
