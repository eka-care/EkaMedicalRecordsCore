//
//  String+Extension.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Foundation

extension String {
  func epochStringToDate(_ epochString: String) -> Date? {
      guard let epochInt = Int(epochString) else {
          return nil
      }
      return Date(timeIntervalSince1970: TimeInterval(epochInt))
  }
}
