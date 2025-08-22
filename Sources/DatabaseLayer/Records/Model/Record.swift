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
    // Handle single case model (backward compatibility)
    if let caseModel = record.caseModel {
      addToToCaseModel(caseModel)
    }
    
    // Handle array of case IDs
    if let caseIDs = record.caseIDs {
      associateCaseModels(with: caseIDs)
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
  
  /// Used to associate multiple case models with this record using case IDs
  /// - Parameter caseIDs: Array of case ID strings to associate with this record
  private func associateCaseModels(with caseIDs: [String]) {
    guard let managedContext = managedObjectContext else { return }
    guard !caseIDs.isEmpty else { return }
    
    // Use batch fetch for better performance
    let fetchRequest = QueryHelper.fetchCases(caseIDs: caseIDs)
    
    do {
      let caseModels = try managedContext.fetch(fetchRequest)
      for caseModel in caseModels {
        addToToCaseModel(caseModel)
      }
      
      // Log if some cases were not found
      let foundCaseIDs = caseModels.compactMap { $0.caseID }
      let missingCaseIDs = Set(caseIDs).subtracting(Set(foundCaseIDs))
      if !missingCaseIDs.isEmpty {
        EkaMedicalRecordsCoreLogger.capture("Cases with IDs \(Array(missingCaseIDs)) not found in database")
      }
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Error fetching cases with IDs \(caseIDs): \(error.localizedDescription)")
    }
  }
}
