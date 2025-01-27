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
  
  func toUSEnglishString(withFormat format: String = "YYYY-MM-dd") -> String {
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    
    // Set Date Format
    dateFormatter.dateFormat = format
    
    // Convert Date to String
    return dateFormatter.string(from: self)
  }
}
