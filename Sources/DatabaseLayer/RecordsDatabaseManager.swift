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
  static let containerName = "EkaMedicalRecordsCoreSdk"
  static let entityName = "Record"
}

public final class RecordsDatabaseManager {
  
  // MARK: - Properties
  
  public var container: NSPersistentContainer = {
    /// Loading model from package resources
    let bundle = Bundle.module
    let modelURL = bundle.url(forResource: RecordsDatabaseVersion.containerName, withExtension: "mom")!
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
  /// Current batch index for batch insert
  var batchIndex: Int = 0
  private let databaseAdapter = RecordDatabaseAdapter()
  
  // MARK: - Init
  
  private init() {
    /// Observe Core Data remote change notifications on the queue where the changes were made.
    notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { [weak self] note in
      guard let self else { return }
      debugPrint("Received a persistent store remote change notification.")
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
  /// Used to upsert records to the database
  /// - Parameters:
  ///   - records: list of records to be added
  ///   - completion: completion block to be executed after adding records
//  func upsertRecords(
//    from records: [RecordModel],
//    completion: @escaping () -> Void
//  ) {
//    let documentIDs = records.compactMap { $0.documentID }.filter { !$0.isEmpty }
//    deleteExistingDocumentIdsRecordsFirst(documentIds: documentIDs) { [weak self] in
//      guard let self else { return }
//      batchInsertRecords(from: records, completion: completion)
//    }
//  }
//  
//  private func batchInsertRecords(
//    from records: [RecordModel],
//    completion: @escaping () -> Void
//  ) {
//    // Batch Insert
//    let finalIndex = records.count - 1
//    backgroundContext.perform { [weak self] in
//      guard let self else { return }
//      let batchRequest = NSBatchInsertRequest(
//        entityName: RecordsDatabaseVersion.entityName,
//        managedObjectHandler: { [weak self] object in
//          guard let self,
//                let recordModel = object as? Record else { return false }
//          if batchIndex <= finalIndex {
//            let record = records[batchIndex]
//            // Insert new record
//            recordModel.update(from: record)
//            
//            batchIndex += 1
//            return false
//          } else {
//            batchIndex = 0 // Resetting the index for next batch
//            return true
//          }
//        })
//      do {
//        try backgroundContext.execute(batchRequest)
//        DispatchQueue.main.async {
//          completion()
//        }
//      } catch {
//        debugPrint("Batch insert failed: \(error)")
//      }
//    }
//  }
//  
//  private func deleteExistingDocumentIdsRecordsFirst(
//    documentIds: [String],
//    completion: @escaping () -> Void
//  ) {
//    deleteRecords(
//      request: QueryHelper.fetchRecordsByDocumentIDs(
//        documentIDs: documentIds
//      ),
//      completion: completion
//    )
//  }
  
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
            print("Document id of document being updated is \(record.documentID ?? "")")
            existingRecord.update(from: record)
          } else {
            // Create new record
            let newRecord = Record(context: self.backgroundContext)
            newRecord.update(from: record)
          }
        } catch {
          debugPrint("Error fetching record: \(error)")
        }
      }
      
      // Save all changes at once
      do {
        try self.backgroundContext.save()
        DispatchQueue.main.async {
          completion()
        }
      } catch {
        debugPrint("Error saving records: \(error)")
      }
    }
  }

  
  /// Used to add single record to the database, this will be faster than batch insert for single record
  func addSingleRecord(
    from record: RecordModel
  ) -> Record {
    let newRecord = Record(context: container.viewContext)
    newRecord.update(from: record)
    do {
      try container.viewContext.save()
      /// Add record meta data after saving record entity
      addRecordMetaData(
        to: newRecord,
        documentURIs: record.documentURIs
      )
      debugPrint("Record added successfully!")
      return newRecord
    } catch {
      let nsError = error as NSError
      debugPrint("Error saving record: \(nsError), \(nsError.userInfo)")
      return newRecord
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
      debugPrint("Record meta data added successfully!")
    } catch {
      let nsError = error as NSError
      debugPrint("Error saving record meta data: \(nsError), \(nsError.userInfo)")
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
      debugPrint("Smart report saved successfully")
    } catch {
      let nsError = error as NSError
      debugPrint("Error saving smart report \(nsError)")
    }
  }
}

// MARK: - Read

extension RecordsDatabaseManager {
  /// Used to fetch record entity items
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Parameter completion: completion block to be executed after fetching records
  func fetchRecords(
    fetchRequest: NSFetchRequest<Record>,
    completion: @escaping ([Record]) -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      let records = try? backgroundContext.fetch(fetchRequest)
      completion(records ?? [])
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
      debugPrint("Not able to fetch record with given id")
    }
    return nil
  }
  
  /// Get document type counts
  func getDocumentTypeCounts(oid: String?) -> [RecordDocumentType: Int] {
    let fetchRequest = QueryHelper.fetchRecordCountsByDocumentTypeFetchRequest(oid: oid)
    var counts: [RecordDocumentType: Int] = [:]
    
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      var totalDocumentsCount = 0
      
      for result in results {
        if let resultDict = result as? [String: Any],
           let documentTypeInt = resultDict["documentType"] as? Int,
           let recordDocumentType = RecordDocumentType.from(intValue: documentTypeInt),
           let count = resultDict["count"] as? Int {
          totalDocumentsCount += count
          counts[recordDocumentType] = count
        }
      }
      
      /// Add totalDocumentsCount in all
      counts[.typeAll] = totalDocumentsCount
      
    } catch {
      print("Failed to fetch grouped document type counts: \(error)")
    }
    
    return counts
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
  func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String? = nil,
    documentDate: Date? = nil,
    documentType: Int? = nil,
    documentOid: String? = nil
  ) {
    do {
      guard let record = try container.viewContext.existingObject(with: recordID) as? Record else {
        debugPrint("Record not found")
        return
      }
      record.documentID = documentID
      record.documentDate = documentDate
      if let documentType {
        record.documentType = Int64(documentType)
      }
      if let documentOid {
        record.oid = documentOid
      }
      try container.viewContext.save()
    } catch {
      debugPrint("Failed to update record: \(error)")
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
      guard let self else { return }
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
      do {
        try backgroundContext.execute(deleteRequest)
      } catch {
        debugPrint("There was an error deleting entity")
      }
    }
  }
  
  /// Used to delete a given record
  /// - Parameter record: record object that is to be deleted
  func deleteRecord(record: Record) {
    container.viewContext.delete(record)
    do {
      try container.viewContext.save()
    } catch {
      debugPrint("Error deleting record: \(error)")
    }
  }
}

// MARK: - Fetch History

extension RecordsDatabaseManager {
  func fetchPersistentHistory() async {
    do {
      try await fetchPersistentHistoryTransactionsAndChanges()
    } catch {
      debugPrint("\(error.localizedDescription)")
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
    debugPrint("Start fetching persistent history changes from the store...")
    
    try await backgroundContext.perform { [weak self] in
      guard let self else { return }
      // Execute the persistent history change since the last transaction.
      /// - Tag: fetchHistory
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
      let historyResult = try backgroundContext.execute(changeRequest) as? NSPersistentHistoryResult
      if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
         !history.isEmpty {
        self.mergePersistentHistoryChanges(from: history)
        return
      }
    }
    
    debugPrint("Finished merging history changes.")
  }
  
  private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
    debugPrint("Received \(history.count) persistent history transactions.")
    // Update view context with objectIDs from history change request.
    /// - Tag: mergeChanges
    let viewContext = container.viewContext
    viewContext.perform {
      for transaction in history {
        viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        self.lastToken = transaction.token
      }
    }
  }
}
