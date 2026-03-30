//
//  RecordDocumentTagType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

import Foundation

enum SmartReportStatus: String, Codable {
  case processing = "0"
  case smart = "1"
  case notSmart = "2"
  
  var isSmart: Bool {
    self == .smart
  }
  
  var isProcessing: Bool {
    self == .processing
  }

}
