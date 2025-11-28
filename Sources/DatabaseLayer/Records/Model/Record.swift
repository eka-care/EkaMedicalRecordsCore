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
      self.documentType = documentType
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
   
    if let updatedAt = record.updatedAt {
      self.updatedAt = updatedAt
    }
    
    if let uploadDate = record.uploadDate {
      self.uploadDate = uploadDate
    }
    
    oid = record.oid
    if let isEdited = record.isEdited {
      self.isEdited = isEdited
    }
    
    // Handle array of case models directly
    if let caseModels = record.caseModels {
      associateCaseModels(caseModels)
    }
    
    // Handle array of case IDs (for lazy loading)
    if let caseIDs = record.caseIDs {
      associateCaseModels(with: caseIDs)
    }
    
    if let tags = record.tags {
      associateTags(with: tags)
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
  
  /// Used to associate multiple case models with this record directly
  /// - Parameter caseModels: Array of CaseModel objects to associate with this record
  private func associateCaseModels(_ caseModels: [CaseModel]) {
    guard !caseModels.isEmpty else { return }
    
    // Ensure we're using the background context from RecordsDatabaseManager
    let backgroundContext = RecordsDatabaseManager.shared.backgroundContext
    
    // Verify this record is in the background context
    guard self.managedObjectContext == backgroundContext else {
      EkaMedicalRecordsCoreLogger.capture("Warning: Record is not in background context, skipping case association")
      return
    }
    
    //  Fix cross-context issue: fetch case models in the correct context
    let caseIDs = caseModels.compactMap { $0.caseID }
    let fetchRequest = QueryHelper.fetchCases(caseIDs: caseIDs)
    
    do {
      let backgroundCaseModels = try backgroundContext.fetch(fetchRequest)
      
      // Associate all fetched case models
      for caseModel in backgroundCaseModels {
        addToToCaseModel(caseModel)
      }
      
      EkaMedicalRecordsCoreLogger.capture("Successfully associated \(backgroundCaseModels.count) case(s) with record \(self.documentID ?? "unknown") on background context")
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Error fetching case models in background context: \(error.localizedDescription)")
    }
  }
  
  /// Used to associate multiple case models with this record using case IDs
  /// - Parameter caseIDs: Array of case ID strings to associate with this record
  private func associateCaseModels(with caseIDs: [String]) {
    guard !caseIDs.isEmpty else { return }
    
    // Ensure we're using the background context from RecordsDatabaseManager
    let backgroundContext = RecordsDatabaseManager.shared.backgroundContext
    
    // Verify this record is in the background context
    guard self.managedObjectContext == backgroundContext else {
      EkaMedicalRecordsCoreLogger.capture("Warning: Record is not in background context, skipping case association")
      return
    }
    
    // Use batch fetch for better performance
    let fetchRequest = QueryHelper.fetchCases(caseIDs: caseIDs)
    
    do {
      let caseModels = try backgroundContext.fetch(fetchRequest)
      
      // Associate all fetched case models
      for caseModel in caseModels {
        addToToCaseModel(caseModel)
      }
      
      // Log if some cases were not found
      let foundCaseIDs = caseModels.compactMap { $0.caseID }
      let missingCaseIDs = Set(caseIDs).subtracting(Set(foundCaseIDs))
      if !missingCaseIDs.isEmpty {
        EkaMedicalRecordsCoreLogger.capture("Warning: Cases with IDs \(Array(missingCaseIDs)) not found in database during association")
      }
      
      EkaMedicalRecordsCoreLogger.capture("Successfully associated \(caseModels.count) case(s) with record \(self.documentID ?? "unknown") on background context")
    } catch {
      let errorMessage = "Error fetching cases with IDs \(caseIDs): \(error.localizedDescription)"
      EkaMedicalRecordsCoreLogger.capture(errorMessage)
    }
  }
}

// MARK: - Case Relationship Management

extension Record {
  /// Get all associated case models as an array
  /// - Returns: Array of CaseModel objects associated with this record
  public func getCaseModels() -> [CaseModel] {
    return toCaseModel?.allObjects as? [CaseModel] ?? []
  }
  
  /// Get all associated case IDs as an array
  /// - Returns: Array of case ID strings associated with this record
  public func getCaseIDs() -> [String] {
    let caseModels = getCaseModels()
    return caseModels.compactMap { $0.caseID }
  }
  
  /// Add a single case model to this record
  /// - Parameter caseModel: The CaseModel to associate with this record
  public func addCaseModel(_ caseModel: CaseModel) {
    addToToCaseModel(caseModel)
  }
  
  /// Remove a single case model from this record
  /// - Parameter caseModel: The CaseModel to disassociate from this record
  public func removeCaseModel(_ caseModel: CaseModel) {
    removeFromToCaseModel(caseModel)
  }
  
  /// Add multiple case models to this record
  /// - Parameter caseModels: Array of CaseModel objects to associate with this record
  public func addCaseModels(_ caseModels: [CaseModel]) {
    associateCaseModels(caseModels)
  }
  
  /// Remove multiple case models from this record
  /// - Parameter caseModels: Array of CaseModel objects to disassociate from this record
  public func removeCaseModels(_ caseModels: [CaseModel]) {
    caseModels.forEach { removeFromToCaseModel($0) }
  }
  
  /// Check if this record is associated with a specific case
  /// - Parameter caseModel: The CaseModel to check for association
  /// - Returns: True if the record is associated with the case, false otherwise
  public func isAssociatedWith(caseModel: CaseModel) -> Bool {
    return toCaseModel?.contains(caseModel) ?? false
  }
  
  /// Check if this record is associated with a case by ID
  /// - Parameter caseID: The case ID to check for association
  /// - Returns: True if the record is associated with the case, false otherwise
  public func isAssociatedWith(caseID: String) -> Bool {
    let caseIDs = getCaseIDs()
    return caseIDs.contains(caseID)
  }
  
  /// Remove all case associations from this record
  public func removeAllCaseAssociations() {
    let caseModels = getCaseModels()
    removeCaseModels(caseModels)
  }
}

// MARK: - Tag Relationship Management

extension Record {
  /// Used to associate tags with this record
  /// - Parameter tagNames: Array of tag names to associate with this record
  private func associateTags(with tagNames: [String]) {
    guard !tagNames.isEmpty else { return }
    
    // Ensure we're using the background context from RecordsDatabaseManager
    let backgroundContext = RecordsDatabaseManager.shared.backgroundContext
    
    // Verify this record is in the background context
    guard self.managedObjectContext == backgroundContext else {
      EkaMedicalRecordsCoreLogger.capture("Warning: Record is not in background context, skipping tag association")
      return
    }
    
    // Remove existing tag associations first to avoid duplicates
    removeAllTags()
    
    // Create or find existing Tags entities for each tag name
    for tagName in tagNames {
      let trimmedTagName = tagName.trimmingCharacters(in: .whitespaces)
      guard !trimmedTagName.isEmpty else { continue }
      
      // Check if a Tag with this name already exists in the database
      let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "name == %@", trimmedTagName)
      fetchRequest.fetchLimit = 1
      
      do {
        let existingTags = try backgroundContext.fetch(fetchRequest)
        let tagEntity: Tags
        
        if let existingTag = existingTags.first {
          // Use existing tag
          tagEntity = existingTag
        } else {
          // Create new tag
          tagEntity = Tags(context: backgroundContext)
          tagEntity.name = trimmedTagName
        }
        
        // Associate the tag with this record
        addToToTags(tagEntity)
        
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Error fetching/creating tag '\(trimmedTagName)': \(error.localizedDescription)")
      }
    }
    
    EkaMedicalRecordsCoreLogger.capture("Associated \(tagNames.count) tags with record \(self.documentID ?? "unknown") on background context")
  }
  
  /// Get all tag names associated with this record
  /// - Returns: Array of tag name strings
  public func getTagNames() -> [String] {
    guard let tags = toTags else { return [] }
    let tagEntities = tags.allObjects as? [Tags] ?? []
    return tagEntities.compactMap { $0.name }.sorted()
  }
  
  /// Get all tag entities associated with this record
  /// - Returns: Array of Tags entities
  public func getTags() -> [Tags] {
    guard let tags = toTags else { return [] }
    return tags.allObjects as? [Tags] ?? []
  }
  
  /// Add or update tags for this record
  /// - Parameter tagNames: Array of tag names to set for this record
  public func setTags(_ tagNames: [String]) {
    associateTags(with: tagNames)
  }
  
  /// Add a single tag to this record
  /// - Parameter tagName: The tag name to add
  public func addTag(_ tagName: String) {
    let trimmedTagName = tagName.trimmingCharacters(in: .whitespaces)
    guard !trimmedTagName.isEmpty else { return }
    
    // Ensure we're using the background context from RecordsDatabaseManager
    let backgroundContext = RecordsDatabaseManager.shared.backgroundContext
    
    // Verify this record is in the background context
    guard self.managedObjectContext == backgroundContext else {
      EkaMedicalRecordsCoreLogger.capture("Warning: Record is not in background context, skipping tag addition")
      return
    }
    
    // Check if this record already has this tag
    if hasTag(named: trimmedTagName) {
      return // Tag already exists for this record
    }
    
    // Check if a Tag with this name already exists in the database
    let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name == %@", trimmedTagName)
    fetchRequest.fetchLimit = 1
    
    do {
      let existingTags = try backgroundContext.fetch(fetchRequest)
      let tagEntity: Tags
      
      if let existingTag = existingTags.first {
        // Use existing tag
        tagEntity = existingTag
      } else {
        // Create new tag
        tagEntity = Tags(context: backgroundContext)
        tagEntity.name = trimmedTagName
      }
      
      // Associate the tag with this record
      addToToTags(tagEntity)
      
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Error adding tag '\(trimmedTagName)': \(error.localizedDescription)")
    }
  }
  
  /// Remove a specific tag from this record
  /// - Parameter tagName: The tag name to remove
  public func removeTag(_ tagName: String) {
    guard let tags = toTags else { return }
    let tagEntities = tags.allObjects as? [Tags] ?? []
    
    for tagEntity in tagEntities {
      if tagEntity.name == tagName {
        removeFromToTags(tagEntity)
        
        // If this tag is not associated with any other records, delete it
        if let tagRecords = tagEntity.toRecords, tagRecords.count == 0 {
          managedObjectContext?.delete(tagEntity)
        }
        break
      }
    }
  }
  
  /// Remove multiple tags from this record
  /// - Parameter tagNames: Array of tag names to remove
  public func removeTags(_ tagNames: [String]) {
    for tagName in tagNames {
      removeTag(tagName)
    }
  }
  
  /// Remove all tags from this record
  public func removeAllTags() {
    guard let tags = toTags else { return }
    let tagEntities = tags.allObjects as? [Tags] ?? []
    
    for tagEntity in tagEntities {
      removeFromToTags(tagEntity)
      
      // If this tag is not associated with any other records, delete it
      if let tagRecords = tagEntity.toRecords, tagRecords.count == 0 {
        managedObjectContext?.delete(tagEntity)
      }
    }
  }
  
  /// Check if this record has any tags
  /// - Returns: True if the record has tags, false otherwise
  public func hasTags() -> Bool {
    guard let tags = toTags else { return false }
    return tags.count > 0
  }
  
  /// Check if this record has a specific tag
  /// - Parameter tagName: The tag name to check for
  /// - Returns: True if the record has the specified tag, false otherwise
  public func hasTag(named tagName: String) -> Bool {
    guard let tags = toTags else { return false }
    let tagEntities = tags.allObjects as? [Tags] ?? []
    return tagEntities.contains { $0.name == tagName }
  }
  
  /// Check if this record has all of the specified tags
  /// - Parameter tagNames: Array of tag names to check for
  /// - Returns: True if the record has all specified tags, false otherwise
  public func hasAllTags(_ tagNames: [String]) -> Bool {
    for tagName in tagNames {
      if !hasTag(named: tagName) {
        return false
      }
    }
    return true
  }
  
  /// Check if this record has any of the specified tags
  /// - Parameter tagNames: Array of tag names to check for
  /// - Returns: True if the record has any of the specified tags, false otherwise
  public func hasAnyTags(_ tagNames: [String]) -> Bool {
    for tagName in tagNames {
      if hasTag(named: tagName) {
        return true
      }
    }
    return false
  }
}
