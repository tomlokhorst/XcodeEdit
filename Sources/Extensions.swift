//
//  Extensions.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

extension Sequence {
  func ofType<T>(_ type: T.Type) -> [T] {
    return self.flatMap { $0 as? T }
  }

  func grouped<Key: Hashable>(by keySelector: (Iterator.Element) -> Key) -> [Key : [Iterator.Element]] {
    var groupedBy = Dictionary<Key, [Iterator.Element]>()

    for element in self {
      let key = keySelector(element)
      var array = groupedBy.removeValue(forKey: key) ?? []
      array.append(element)
      groupedBy[key] = array
    }

    return groupedBy
  }

  func sorted<U: Comparable>(by keySelector: (Iterator.Element) -> U) -> [Iterator.Element] {
    return self.sorted { keySelector($0) < keySelector($1) }
  }
}
