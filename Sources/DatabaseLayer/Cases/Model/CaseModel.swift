//
//  Case.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 17/07/25.
//

import CoreData

extension CaseModel {
  func update(from caseArguementModel: CaseArguementModel) {
    if let caseId = caseArguementModel.caseId {
      self.caseID = caseId
    }
    
    if let caseName = caseArguementModel.name {
      self.caseName = caseName
    }
    
    if let caseType = caseArguementModel.caseType {
      self.caseType = caseType
      associateCaseType(with: caseType)
    }
    
    self.updatedAt = caseArguementModel.updatedAt
    
    if let createdAt = caseArguementModel.createdAt {
      self.createdAt = createdAt
    }
    
    if let oid = caseArguementModel.oid {
      self.oid = oid
    }
    
    if let occuredAt = caseArguementModel.occuredAt {
      self.occuredAt = occuredAt
    }
    
    if let isRemoteCreated = caseArguementModel.isRemoteCreated {
      self.isRemoteCreated = isRemoteCreated
    }
    
    if let isEdited = caseArguementModel.isEdited {
      self.isEdited = isEdited
    }
    
    if let status = caseArguementModel.status {
      self.status = status.rawValue
    }
  }
}

// MARK: - CaseType Association

extension CaseModel {
  /// Used to associate a case type with this case model using case type name
  /// - Parameter caseTypeName: Case type name string to associate with this case model
  private func associateCaseType(with caseTypeName: String) {
    guard let managedContext = managedObjectContext else { return }
    guard !caseTypeName.isEmpty else { return }
    
    // Use batch fetch for better performance
    let fetchRequest: NSFetchRequest<CaseType> = CaseType.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name == %@", caseTypeName)
    
    do {
      let caseTypes = try managedContext.fetch(fetchRequest)
      
      if let existingCaseType = caseTypes.first {
        // Use existing CaseType
        self.addToToCaseType(existingCaseType)
      } else {
        // Create new CaseType if not found and add to database
        let newCaseType = CaseType(context: managedContext)
        newCaseType.name = caseTypeName
        self.addToToCaseType(newCaseType)
        
        // Save the new CaseType to the database
        do {
          try managedContext.save()
          EkaMedicalRecordsCoreLogger.capture("Created and saved new CaseType with name: \(caseTypeName)")
        } catch {
          EkaMedicalRecordsCoreLogger.capture("Error saving new CaseType: \(error.localizedDescription)")
        }
      }
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Error fetching CaseType with name \(caseTypeName): \(error.localizedDescription)")
      
      // Fallback: create new CaseType if fetch fails and save to database
      let newCaseType = CaseType(context: managedContext)
      newCaseType.name = caseTypeName
      self.addToToCaseType(newCaseType)
      
      // Save the new CaseType to the database
      do {
        try managedContext.save()
        EkaMedicalRecordsCoreLogger.capture("Created and saved new CaseType (fallback) with name: \(caseTypeName)")
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Error saving new CaseType (fallback): \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - Record Relationship Management

extension CaseModel {
  /// Get all associated records as an array
  /// - Returns: Array of Record objects associated with this case
  public func getRecords() -> [Record] {
    return toRecord?.allObjects as? [Record] ?? []
  }
  
  /// Get all associated record IDs as an array
  /// - Returns: Array of record document ID strings associated with this case
  public func getRecordIDs() -> [String] {
    let records = getRecords()
    return records.compactMap { $0.documentID }
  }
  
  /// Add a single record to this case
  /// - Parameter record: The Record to associate with this case
  public func addRecord(_ record: Record) {
    addToToRecord(record)
  }
  
  /// Remove a single record from this case
  /// - Parameter record: The Record to disassociate from this case
  public func removeRecord(_ record: Record) {
    removeFromToRecord(record)
  }
  
  /// Add multiple records to this case
  /// - Parameter records: Array of Record objects to associate with this case
  public func addRecords(_ records: [Record]) {
    records.forEach { addToToRecord($0) }
  }
  
  /// Remove multiple records from this case
  /// - Parameter records: Array of Record objects to disassociate from this case
  public func removeRecords(_ records: [Record]) {
    records.forEach { removeFromToRecord($0) }
  }
  
  /// Check if this case is associated with a specific record
  /// - Parameter record: The Record to check for association
  /// - Returns: True if the case is associated with the record, false otherwise
  public func isAssociatedWith(record: Record) -> Bool {
    return toRecord?.contains(record) ?? false
  }
  
  /// Check if this case is associated with a record by document ID
  /// - Parameter documentID: The record document ID to check for association
  /// - Returns: True if the case is associated with the record, false otherwise
  public func isAssociatedWith(documentID: String) -> Bool {
    let recordIDs = getRecordIDs()
    return recordIDs.contains(documentID)
  }
  
  /// Remove all record associations from this case
  public func removeAllRecordAssociations() {
    let records = getRecords()
    removeRecords(records)
  }
}
