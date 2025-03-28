//
//  Int+Extension.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

import Foundation

extension Int {
  func toDate() -> Date {
    return Date(timeIntervalSince1970: TimeInterval(self))
  }
}
