//
//  PBXIdentifier.swift
//  XcodeEdit
//
//  Created by Tom Lokhorst on 2017-12-27.
//  Copyright © 2017 nonstrict. All rights reserved.
//

import Foundation

// Based on: https://pewpewthespells.com/blog/pbxproj_identifiers.html

public struct PBXIdentifier {
  let user: UInt8            // encoded username
  let pid: UInt8             // encoded current pid #
  var _random: UInt16        // encoded random value
  var _time: UInt32          // encoded time value
  let zero: UInt8            // zero
  let host_shift: UInt8      // encoded, shifted hostid
  let host_h: UInt8          // high byte of lower bytes of hostid
  let host_l: UInt8          // low byte of lower bytes of hostid

  public init?(string stringValue: String) {
    guard
      let user = stringValue.uint8(at: 0),
      let pid = stringValue.uint8(at: 2),
      let _random = stringValue.uint16(at: 4),
      let _time = stringValue.uint32(at: 8),
      let zero = stringValue.uint8(at: 16),
      let host_shift = stringValue.uint8(at: 18),
      let host_h = stringValue.uint8(at: 20),
      let host_l = stringValue.uint8(at: 22)
    else { return nil}

    self.user = user
    self.pid = pid
    self._random = _random
    self._time = _time
    self.zero = zero
    self.host_shift = host_shift
    self.host_h = host_h
    self.host_l = host_l
  }

  public var stringValue: String {
    let parts = [
      String(format: "%02X", user),
      String(format: "%02X", pid),
      String(format: "%04X", _random),
      String(format: "%08X", _time),
      String(format: "%02X", zero),
      String(format: "%02X", host_shift),
      String(format: "%02X", host_h),
      String(format: "%02X", host_l)
    ]

    return parts.joined()
  }

  public func createFreshIdentifier() -> PBXIdentifier {
    var result = self
    result._time = UInt32(Date.timeIntervalSinceReferenceDate)
    result._random = UInt16(arc4random_uniform(UInt32(UInt16.max)))

    return result
  }
}

private extension String {
  func uint8(at index: Int) -> UInt8? {
    guard let str = self.substring(from: index, length: 2) else { return nil }
    return UInt8(str, radix: 16)
  }

  func uint16(at index: Int) -> UInt16? {
    guard let str = self.substring(from: index, length: 4) else { return nil }
    return UInt16(str, radix: 16)
  }

  func uint32(at index: Int) -> UInt32? {
    guard let str = self.substring(from: index, length: 8) else { return nil }
    return UInt32(str, radix: 16)
  }

  private func substring(from: Int, length: Int) -> String.SubSequence? {
    guard from + length <= self.count else { return nil }

    let start = self.index(startIndex, offsetBy: from)
    let end = self.index(start, offsetBy: length)

    return self[start..<end]
  }
}
