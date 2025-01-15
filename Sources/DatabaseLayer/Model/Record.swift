//
//  Record.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 03/01/25.
//

import SwiftProtoContracts
import Foundation
import CoreData

extension Record {
  func update(from record: RecordModel) {
    documentDate = record.documentDate
    documentHash = record.documentHash
    documentID = record.documentID
    if let documentType = record.documentType {
      self.documentType = Int64(documentType)
    }
    if let isAnalyzing = record.isAnalyzing {
      self.isAnalyzing = isAnalyzing
    }
    thumbnail = record.thumbnail
    updatedAt = record.updatedAt
  }
}
