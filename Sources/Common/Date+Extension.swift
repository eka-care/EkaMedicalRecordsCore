//
//  Date+Extension.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 24/01/25.
//

import Foundation

extension Date {
  /// Get the epoch of the current Date()
  func getCurrentEpoch() -> String {
    let wholeSecondEpoch: Int = Int(floor(Date().timeIntervalSince1970))
    let stringEpoch: String = String(wholeSecondEpoch)
    return stringEpoch
  }
}
