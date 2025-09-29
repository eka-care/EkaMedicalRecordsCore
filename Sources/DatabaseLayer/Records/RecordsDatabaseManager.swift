//
//  RecordsDatabaseManager.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 31/12/24.
//

import Foundation
import CoreData

/**
 This file contains CRUD functions for the database layer.
 */

enum RecordsDatabaseVersion {
  static let containerName = "EkaMedicalRecordsCoreSdkV2"
}

public final class RecordsDatabaseManager {
  
  // MARK: - Properties
  
  public var container: NSPersistentContainer = {
    /// Loading model from package resources
    let bundle = Bundle.module
    let modelURL = bundle.url(forResource: RecordsDatabaseVersion.containerName, withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!
    let container = NSPersistentContainer(name: RecordsDatabaseVersion.containerName, managedObjectModel: model)
    
    /// Setting notification tracking
    let description = container.persistentStoreDescriptions.first!
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    /// Loading of persistent stores
    container.loadPersistentStores { (storeDescription, error) in
      if let error {
        fatalError("Failed to load store: \(error)")
      }
    }
    /// Configure the viewContext (main context)
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return container
  }()
  /// Background context for heavy database operations
  public lazy var backgroundContext: NSManagedObjectContext = {
    newTaskContext()
  }()
  public static let shared = RecordsDatabaseManager()
  private var notificationToken: NSObjectProtocol?
  /// A peristent history token used for fetching transactions from the store.
  private var lastToken: NSPersistentHistoryToken?
  /// Queue for thread-safe access to lastToken
  private let tokenQueue = DispatchQueue(label: "com.eka.records.token", attributes: .concurrent)
  /// Flag to indicate if the manager is being cleared (during logout)
  private var isClearing = false
  /// Current batch index for batch insert
  var batchIndex: Int = 0
  private let databaseAdapter = RecordDatabaseAdapter()
  
  // MARK: - Init
  
  private init() {
    /// Observe Core Data remote change notifications on the queue where the changes were made.
    notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { [weak self] note in
      guard let self else { return }
      
      // Check if we're currently clearing data (during logout)
      guard !self.isClearing else {
        EkaMedicalRecordsCoreLogger.capture("Ignoring persistent store change notification during logout")
        return
      }
      
      EkaMedicalRecordsCoreLogger.capture("Received a persistent store remote change notification.")
      Task {
        await self.fetchPersistentHistory()
      }
    }
  }
  
  deinit {
    if let observer = notificationToken {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}

// MARK: - Create

extension RecordsDatabaseManager {
  func upsertRecords(
    from records: [RecordModel],
    completion: @escaping () -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else {
        completion()
        return
      }
      
      for record in records {
        // Check if the record already exists
        let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "documentID == %@", record.documentID ?? "")
        
        do {
          if let existingRecord = try self.backgroundContext.fetch(fetchRequest).first {
            // Update existing record
            EkaMedicalRecordsCoreLogger.capture("Document id of document being updated is \(record.documentID ?? "")")
            existingRecord.update(from: record)
            updateRecordEvent(
              id: record.documentID ?? existingRecord.objectID.uriRepresentation().absoluteString,
              status: .success
            )
          } else {
            // Create new record
            let newRecord = Record(context: self.backgroundContext)
            newRecord.update(from: record)
            createRecordEvent(
              id: record.documentID,
              status: .success
            )
          }
        } catch {
          EkaMedicalRecordsCoreLogger.capture("Error fetching record: \(error)")
        }
      }
      
      // Save all changes at once
      do {
        try self.backgroundContext.save()
        DispatchQueue.main.async {
          completion()
        }
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Error saving records: \(error)")
        DispatchQueue.main.async {
          completion()
        }
      }
    }
  }

  /// Used to add single record to the database, this will be faster than batch insert for single record
  func addSingleRecord(
    from record: RecordModel,
    completion: @escaping (Record?) -> Void
  ) {
    
    backgroundContext.perform { [weak self] in
      guard let self else {
        completion(nil)
        return
      }
      
      let newRecord = Record(context: self.backgroundContext)
      newRecord.update(from: record)
      do {
        try self.backgroundContext.save()
        /// Add record meta data after saving record entity
        addRecordMetaData(
          to: newRecord,
          documentURIs: record.documentURIs
        )
        createRecordEvent(id: newRecord.id.debugDescription, status: .success)
        EkaMedicalRecordsCoreLogger.capture("Record added successfully!")
        completion(newRecord)
      } catch {
        let nsError = error as NSError
        createRecordEvent(id: newRecord.id.debugDescription, status: .failure, message: error.localizedDescription)
        EkaMedicalRecordsCoreLogger.capture("Error saving record: \(nsError), \(nsError.userInfo)")
        completion(nil)
      }
    }
  }
  
  /// Used to add record meta data from api to a record in database
  /// - Parameter record: record to which meta data is to be added
  func addFileDetails(
    to record: Record,
    documentURIs: [String]?,
    smartReportData: Data?
  ) {
    /// Add record meta data to database
    if let documentURIs {
      addRecordMetaData(to: record, documentURIs: documentURIs)
    }
    /// Add smart report data to database
    if let smartReportData {
      addSmartReport(to: record, smartReportData: smartReportData)
    }
  }
  
  /// Used to add record meta data as a one to many relationship to record entity
  /// - Parameters:
  ///   - record: Entity Model to which meta data is to be attached
  ///   - recordModel: Record Model that has all the data
  private func addRecordMetaData(
    to record: Record,
    documentURIs: [String]?
  ) {
    guard let documentURIs else { return }
    documentURIs.forEach { uriPath in
      let recordMeta = RecordMeta(context: container.viewContext)
      recordMeta.documentURI = uriPath
      record.addToToRecordMeta(recordMeta)
    }
    do {
      try container.viewContext.save()
      EkaMedicalRecordsCoreLogger.capture("Record meta data added successfully!")
    } catch {
      let nsError = error as NSError
      EkaMedicalRecordsCoreLogger.capture("Error saving record meta data: \(nsError), \(nsError.userInfo)")
    }
  }
  
  /// Used to add smart report data to a record
  /// - Parameter record: record to which smart report is to be added
  func addSmartReport(
    to record: Record,
    smartReportData: Data
  ) {
    let smartReport = SmartReport(context: container.viewContext)
    smartReport.data = smartReportData
    record.toSmartReport = smartReport
    do {
      try container.viewContext.save()
      EkaMedicalRecordsCoreLogger.capture("Smart report saved successfully")
    } catch {
      let nsError = error as NSError
      EkaMedicalRecordsCoreLogger.capture("Error saving smart report \(nsError)")
    }
  }
}

// MARK: - Read

extension RecordsDatabaseManager {
  /// Used to fetch record entity items
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Parameter completion: completion block to be executed after fetching records
  public func fetchRecords(
    fetchRequest: NSFetchRequest<Record>,
    completion: @escaping ([Record]) -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else { 
        DispatchQueue.main.async {
          completion([])
        }
        return 
      }
      let records = try? backgroundContext.fetch(fetchRequest)
      DispatchQueue.main.async {
        completion(records ?? [])
      }
    }
  }
  
  /// Used to fetch smart report data from database
  func fetchSmartReportData(from record: Record) -> SmartReportInfo? {
    let data = record.toSmartReport?.data
    /// Get smart report from database
    if let smartReportInfo = databaseAdapter.deserializeSmartReportInfo(data: data) {
      return smartReportInfo
    }
    return nil
  }
  
  /// Used to fetch record with given object id
  func fetchRecord(with id: NSManagedObjectID) -> Record?  {
    do {
      let record = try container.viewContext.existingObject(with: id) as? Record
      return record
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Not able to fetch record with given id")
    }
    return nil
  }
  
  /// Used to get record for given fetch request on main thread
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Returns: The given record
  func getRecord(
    fetchRequest: NSFetchRequest<Record>
  ) -> Record? {
    do {
      let record = try container.viewContext.fetch(fetchRequest).first
      return record
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Not able to fetch record with given id")
    }
    return nil
  }
  
  /// Get document type counts
  func getDocumentTypeCounts(
    oid: [String]?,
    caseID: String?
  ) -> [String: Int] {
    let fetchRequest = QueryHelper.fetchRecordCountsByDocumentTypeFetchRequest(oid: oid, caseID: caseID)
    var counts: [String: Int] = [:]
    
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      var totalDocumentsCount = 0
      
      for result in results {
        if let resultDict = result as? [String: Any],
           let documentType = resultDict["documentType"] as? String,
           let count = resultDict["count"] as? Int {
          totalDocumentsCount += count
          counts[documentType] = count
        }
      }
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch grouped document type counts: \(error)")
    }
    
    return counts
  }
  
  /// Get tag counts
  func getTagCounts(
    oid: [String]?,
    caseID: String?,
    documentType: String? = nil
  ) -> [String: Int] {
    // Create a fetch request for records with the specified filters
    let recordFetchRequest = QueryHelper.fetchRecords(oid: oid)
    
    // Build predicates for additional filtering
    var predicates: [NSPredicate] = []
    
    // Add existing predicate if any
    if let existingPredicate = recordFetchRequest.predicate {
      predicates.append(existingPredicate)
    }
    
    // Only include records that have tags
    let hasTagsPredicate = NSPredicate(format: "toTags.@count > 0")
    predicates.append(hasTagsPredicate)
    
    // CaseID predicate
    if let caseID {
      let casePredicate = NSPredicate(format: "ANY toCaseModel.caseID == %@", caseID)
      predicates.append(casePredicate)
    }
    
    // DocumentType predicate
    if let documentType {
      let documentTypePredicate = NSPredicate(format: "documentType == %@", documentType)
      predicates.append(documentTypePredicate)
    }
    
    // Apply combined predicate
    recordFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    
    var counts: [String: Int] = [:]
    var totalRecordsWithTagsCount = 0
    
    do {
      let records = try container.viewContext.fetch(recordFetchRequest)
      
      // Process each record and count its tags
      for record in records {
        if let tags = record.toTags?.allObjects as? [Tags] {
          for tag in tags {
            if let tagName = tag.name, !tagName.isEmpty {
              counts[tagName] = (counts[tagName] ?? 0) + 1
            }
          }
          if !tags.isEmpty {
            totalRecordsWithTagsCount += 1
          }
        }
      }
      
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch records for tag counts: \(error)")
    }
    
    return counts
  }
}

extension RecordsDatabaseManager {
  
  /// Get all unique tag names from the database
  /// - Returns: Array of unique tag names
  func getAllUniqueTagNames() -> [String] {
    let fetchRequest = QueryHelper.fetchAllUniqueTagNames()
    
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      var tagNames: [String] = []
      
      for result in results {
        if let resultDict = result as? [String: Any],
           let tagName = resultDict["name"] as? String {
          tagNames.append(tagName)
        }
      }
      
      return tagNames.sorted()
      
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch unique tag names: \(error)")
      return []
    }
  }
  
  /// Get all unique document types from the database
  /// - Parameter caseID: Optional case ID to filter document types by
  /// - Returns: Array of unique document types
  func getAllUniqueDocumentTypes(caseID: String? = nil) -> [String] {
    let fetchRequest = QueryHelper.fetchAllUniqueDocumentTypes(caseID: caseID)
    
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      var documentTypes: [String] = []
      
      for result in results {
        if let resultDict = result as? [String: Any],
           let documentType = resultDict["documentType"] as? String {
          documentTypes.append(documentType)
        }
      }
      
      return documentTypes.sorted()
      
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch unique document types: \(error)")
      return []
    }
  }
  
  /// Get records with specific tags
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: Array of records that have any of the specified tags
  func getRecordsWithTags(_ tagNames: [String]) -> [Record] {
    let fetchRequest = QueryHelper.fetchRecordsWithTags(tagNames: tagNames)
    
    do {
      return try container.viewContext.fetch(fetchRequest)
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch records with tags \(tagNames): \(error)")
      return []
    }
  }
  
  /// Get records without any tags
  /// - Returns: Array of records that have no tags
  func getRecordsWithoutTags() -> [Record] {
    let fetchRequest = QueryHelper.fetchRecordsWithoutTags()
    
    do {
      return try container.viewContext.fetch(fetchRequest)
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch records without tags: \(error)")
      return []
    }
  }
  
  /// Get records that have ALL of the specified tags
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: Array of records that have all of the specified tags
  func getRecordsWithAllTags(_ tagNames: [String]) -> [Record] {
    let fetchRequest = QueryHelper.fetchRecordsWithAllTags(tagNames: tagNames)
    
    do {
      return try container.viewContext.fetch(fetchRequest)
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch records with all tags \(tagNames): \(error)")
      return []
    }
  }
  
  /// Get all tag entities from the database
  /// - Returns: Array of all tag entities
  func getAllTags() -> [Tags] {
    let fetchRequest = QueryHelper.fetchAllTags()
    
    do {
      return try container.viewContext.fetch(fetchRequest)
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch all tags: \(error)")
      return []
    }
  }
  
  /// Get a specific tag by name
  /// - Parameter tagName: The name of the tag to find
  /// - Returns: The tag entity if found, nil otherwise
  func getTag(withName tagName: String) -> Tags? {
    let fetchRequest = QueryHelper.fetchTag(withName: tagName)
    
    do {
      return try container.viewContext.fetch(fetchRequest).first
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Failed to fetch tag '\(tagName)': \(error)")
      return nil
    }
  }
  
  /// Clean up orphaned tags (tags not associated with any records)
  /// - Parameter completion: Completion handler called when cleanup is finished
  func cleanupOrphanedTags(completion: @escaping (Int) -> Void) {
    backgroundContext.perform { [weak self] in
      guard let self = self else {
        DispatchQueue.main.async {
          completion(0)
        }
        return
      }
      
      let fetchRequest = QueryHelper.fetchOrphanedTags()
      
      do {
        let orphanedTags = try self.backgroundContext.fetch(fetchRequest)
        let count = orphanedTags.count
        
        for tag in orphanedTags {
          self.backgroundContext.delete(tag)
        }
        
        try self.backgroundContext.save()
        
        DispatchQueue.main.async {
          EkaMedicalRecordsCoreLogger.capture("Cleaned up \(count) orphaned tags")
          completion(count)
        }
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Failed to cleanup orphaned tags: \(error)")
        DispatchQueue.main.async {
          completion(0)
        }
      }
    }
  }
}

// MARK: - Update

extension RecordsDatabaseManager {
  /// Updates a specific record in the database.
  /// - Parameters:
  ///   - recordID: The unique identifier of the record to be updated
  ///   - documentID: documentID of the record
  ///   - documentDate: documentDate of the record
  ///   - documentType: documentType of the record
  ///   - documentOid: document oid of the record
  ///   - syncStatus: document sync state of the record
  ///   - caseModel: case to which document is attached to

  func updateRecord(
      documentID: String,
      documentDate: Date? = nil,
      documentType: String? = nil,
      documentOid: String? = nil,
      syncStatus: RecordSyncState? = nil,
      isEdited: Bool? = nil,
      caseModels: [CaseModel]? = nil,
      tags: [String]? = nil
    ) {
      do {
        // Fetch the record by document ID
        let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "documentID == %@", documentID)
        fetchRequest.fetchLimit = 1
        
        let records = try container.viewContext.fetch(fetchRequest)
        guard let record = records.first else {
          EkaMedicalRecordsCoreLogger.capture("Record not found for document ID: \(documentID)")
          updateRecordEvent(
            id: documentID,
            status: .failure,
            message: "Record not found"
          )
          return
        }
        
        // Update the record properties
        record.documentID = documentID
        if let documentDate = documentDate {
          record.documentDate = documentDate
        }
       
        if let documentType {
          record.documentType = documentType
        }
        if let documentOid {
          record.oid = documentOid
        }
        if let syncStatus {
          record.syncState = syncStatus.stringValue
        }
        if let caseModels {
          record.removeAllCaseAssociations()
          record.addCaseModels(caseModels)
        }
        if let isEdited {
          record.isEdited = isEdited
        }
        if let tags {
          record.setTags(tags)
        }
        
        // Save the changes to the database
        try container.viewContext.save()
        updateRecordEvent(
          id: record.documentID,
          status: .success
        )
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Failed to update record: \(error)")
        updateRecordEvent(
          id: documentID,
          status: .failure,
          message: error.localizedDescription
        )
      }
    }
}

// MARK: - Delete

extension RecordsDatabaseManager {
  
  /// Used to delete records for the given fetch request
  /// - Parameters:
  ///   - request: fetch request for records that are to be deleted
  ///   - completion: closure executed after deletion
  func deleteRecords(
    request: NSFetchRequest<NSFetchRequestResult>,
    completion: @escaping () -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else { 
        DispatchQueue.main.async {
          completion()
        }
        return 
      }
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
      do {
        try backgroundContext.execute(deleteRequest)
        try backgroundContext.save()
        DispatchQueue.main.async {
          completion()
        }
      } catch {
        EkaMedicalRecordsCoreLogger.capture("There was an error deleting entity: \(error)")
        DispatchQueue.main.async {
          completion()
        }
      }
    }
  }
  
  /// Used to delete a given record
  /// - Parameter record: record object that is to be deleted
  func deleteRecord(record: Record) {
    container.viewContext.delete(record)
    do {
      try container.viewContext.save()
      deleteRecordEvent(
        id: record.documentID ?? record.objectID.uriRepresentation().absoluteString,
        status: .success
      )
    } catch {
      EkaMedicalRecordsCoreLogger.capture("Error deleting record: \(error)")
      deleteRecordEvent(
        id: record.documentID ?? record.objectID.uriRepresentation().absoluteString,
        status: .failure,
        message: error.localizedDescription
      )
    }
  }
  
  /// Clears all data from the EkaMedicalRecordsCoreSdkV2 database on logout
  /// This function uses batch deletion to remove all entities from the database
  public func onLogoutClearData(completion: @escaping (Result<Void, Error>) -> Void) {
      // Set clearing flag to prevent race conditions with persistent history
      isClearing = true
      
      backgroundContext.perform { [weak self] in
          guard let self else {
              DispatchQueue.main.async {
                  completion(.failure(ErrorHelper.selfDeallocatedError(domain: .databaseManager)))
              }
              return
          }
          
          do {
              // Loop through all entities in the model
              for entity in container.managedObjectModel.entities {
                  guard let entityName = entity.name else { continue }
                  
                  let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                  let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                  batchDeleteRequest.resultType = .resultTypeObjectIDs
                  
                  let result = try self.backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                  if let objectIDs = result?.result as? [NSManagedObjectID] {
                      let changes = [NSDeletedObjectsKey: objectIDs]
                      NSManagedObjectContext.mergeChanges(
                          fromRemoteContextSave: changes,
                          into: [container.viewContext]
                      )
                  }
              }
              
              // Reset tokens & contexts in a thread-safe manner
              tokenQueue.async(flags: .barrier) { [weak self] in
                  guard let self else { return }
                  self.lastToken = nil
              }
              backgroundContext = self.newTaskContext()
              container.viewContext.reset()
              
              // Reset clearing flag
              isClearing = false
              
              DispatchQueue.main.async {
                  completion(.success(()))
              }
          } catch {
              EkaMedicalRecordsCoreLogger.capture("❌ Failed to clear Core Data on logout: \(error)")
              
              // Still reset contexts so app won't be stuck
              tokenQueue.async(flags: .barrier) { [weak self] in
                  guard let self else { return }
                  self.lastToken = nil
              }
              backgroundContext = self.newTaskContext()
              container.viewContext.reset()
              
              // Reset clearing flag
              isClearing = false
              
              DispatchQueue.main.async {
                  completion(.failure(error))
              }
          }
      }
  }
}

// MARK: - Fetch History

extension RecordsDatabaseManager {
  func fetchPersistentHistory() async {
    do {
      try await fetchPersistentHistoryTransactionsAndChanges()
    } catch {
      EkaMedicalRecordsCoreLogger.capture("\(error.localizedDescription)")
    }
  }
  
  /// Creates and configures a private queue context.
  func newTaskContext() -> NSManagedObjectContext  {
    // Create a private queue context.
    /// - Tag: newBackgroundContext
    let taskContext = container.newBackgroundContext()
    taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    // Set unused undoManager to nil for macOS (it is nil by default on iOS)
    // to reduce resource requirements.
    taskContext.undoManager = nil
    return taskContext
  }
  
  func fetchPersistentHistoryTransactionsAndChanges() async throws {
    backgroundContext.name = "persistentHistoryContext"
    EkaMedicalRecordsCoreLogger.capture("Start fetching persistent history changes from the store...")
    
    try await backgroundContext.perform { [weak self] in
      guard let self else { return }
      
      // Check if we're currently clearing data (during logout)
      guard !self.isClearing else {
        EkaMedicalRecordsCoreLogger.capture("Skipping persistent history fetch during logout")
        return
      }
      
      // Get lastToken in a thread-safe manner
      let currentToken = self.tokenQueue.sync { self.lastToken }
      
      // Execute the persistent history change since the last transaction.
      /// - Tag: fetchHistory
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: currentToken)
      let historyResult = try backgroundContext.execute(changeRequest) as? NSPersistentHistoryResult
      if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
         !history.isEmpty {
        self.mergePersistentHistoryChanges(from: history)
        return
      }
    }
    
    EkaMedicalRecordsCoreLogger.capture("Finished merging history changes.")
  }
  
  private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
    EkaMedicalRecordsCoreLogger.capture("Received \(history.count) persistent history transactions.")
    // Update view context with objectIDs from history change request.
    /// - Tag: mergeChanges
    let viewContext = container.viewContext
    viewContext.perform {
      guard !self.isClearing else {
        EkaMedicalRecordsCoreLogger.capture("Skipping history merge during logout")
        return
      }
      
      for transaction in history {
        viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        
        // Update lastToken in a thread-safe manner
        self.tokenQueue.async(flags: .barrier) { [weak self] in
          guard let self else { return }
          self.lastToken = transaction.token
        }
      }
    }
  }
}
