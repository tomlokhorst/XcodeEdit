//
//  Extensions.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

internal func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

internal extension Sequence {
  func grouped<Key>(by keyForValue: (Element) -> Key) -> [Key: [Element]] {
    return Dictionary(grouping: self, by: keyForValue)
  }

  func sorted<U: Comparable>(by comparableForValue: (Element) -> U) -> [Iterator.Element] {
    return self.sorted { comparableForValue($0) < comparableForValue($1) }
  }
}
