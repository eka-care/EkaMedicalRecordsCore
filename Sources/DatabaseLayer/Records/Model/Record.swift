//
//  Record.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 03/01/25.
//

import Foundation
import CoreData

extension Record {
  func update(from record: RecordModel) {
    bid = CoreInitConfigurations.shared.ownerID
    documentDate = record.documentDate
    documentHash = record.documentHash
    documentID = record.documentID
    if let syncState = record.syncState {
      self.syncState = syncState.stringValue
    }
    if let documentType = record.documentType {
      self.documentType = Int64(documentType.intValue)
    }
    if let isAnalyzing = record.isAnalyzing {
      self.isAnalyzing = isAnalyzing
    }
    if let isSmart = record.isSmart {
      self.isSmart = isSmart
    }
    if let thumbnail = record.thumbnail {
      self.thumbnail = thumbnail
    }
    updatedAt = record.updatedAt
    uploadDate = record.uploadDate
    oid = record.oid
    if let isEdited = record.isEdited {
      self.isEdited = isEdited
    }
    /// Add Case Models
    if let caseModel = record.caseModel {
      addToToCaseModel(caseModel)
    }
  }
  
  /// Used to get local paths of file
  public func getLocalPathsOfFile() -> [String] {
    let recordMetaDataItems = getMetaDataItems()
    let paths = recordMetaDataItems.compactMap { $0.documentURI }
    return paths
  }
  
  /// Used to get meta data items from a given record object
  public func getMetaDataItems() -> [RecordMeta] {
    return toRecordMeta?.allObjects as? [RecordMeta] ?? []
  }
}
