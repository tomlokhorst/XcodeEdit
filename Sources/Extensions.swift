//
//  Extensions.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

extension SequenceType {
  func ofType<T>(type: T.Type) -> [T] {
    return self.flatMap { $0 as? T }
  }

  func any(pred: Generator.Element -> Bool) -> Bool {
    for elem in self {
      if pred(elem) {
        return true
      }
    }

    return false
  }

  /// Groups by keySelector of subsequent elements
  func groupBy<Key: Hashable>(keySelector: Generator.Element -> Key) -> [(Key, [Generator.Element])] {
    var groupedBy: [(Key, [Generator.Element])] = []
    var currentKey: Key?
    var currentGroup: [Generator.Element] = []

    for element in self {
      let key = keySelector(element)

      if let _currentKey = currentKey {
        if key != _currentKey {
          groupedBy.append((_currentKey, currentGroup))

          currentGroup = []
          currentKey = key
        }
      }
      else {
        currentKey = key
      }

      currentGroup.append(element)
    }

    if let _currentKey = currentKey {
      groupedBy.append((_currentKey, currentGroup))
    }

    return groupedBy
  }

  func sortBy<U: Comparable>(keySelector: Generator.Element -> U) -> [Generator.Element] {
    return self.sort { keySelector($0) < keySelector($1) }
  }
}