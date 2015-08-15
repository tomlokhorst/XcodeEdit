//
//  Extensions.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

extension Array {
  func ofType<T>(type: T.Type) -> [T] {
    return self.filter { $0 is T }.map { $0 as! T }
  }

  func any(pred: Element -> Bool) -> Bool {
    for elem in self {
      if pred(elem) {
        return true
      }
    }

    return false
  }
}

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}
