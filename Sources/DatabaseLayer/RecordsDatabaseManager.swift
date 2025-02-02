//
//  RecordsDatabaseManager.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 31/12/24.
//

import Foundation
import CoreData
import SwiftProtoContracts

/**
 This file contains CRUD functions for the database layer.
 */

enum RecordsDatabaseVersion {
  static let containerName = "EkaMedicalRecordsCoreSdk"
  static let entityName = "Record"
}

public final class RecordsDatabaseManager {
  
  // MARK: - Properties
  
  public lazy var container: NSPersistentContainer = {
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
  /// Used to add records to the database
  /// - Parameters:
  ///   - records: list of records to be added
  ///   - completion: completion block to be executed after adding records
  func addRecords(
    from records: [RecordModel],
    completion: @escaping () -> Void
  ) {
    // Batch Insert
    let finalIndex = records.count - 1
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      let batchRequest = NSBatchInsertRequest(
        entityName: RecordsDatabaseVersion.entityName,
        managedObjectHandler: { [weak self] object in
          guard let self,
                /// Get the database object
                let recordModel = object as? Record else { return false }
          if batchIndex <= finalIndex {
            /// Get the network object
            let record = records[batchIndex]
            /// Update the model with data from network
            recordModel.update(from: record)
            batchIndex += 1
            return false
          } else {
            batchIndex = 0 // Resetting the index for next batch
            return true
          }
        })
      do {
        try backgroundContext.execute(batchRequest)
        DispatchQueue.main.async {
          completion()
        }
      } catch {
        debugPrint("Batch insert failed: \(error)")
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
        record: newRecord,
        recordModel: record
      )
      debugPrint("Record added successfully!")
      return newRecord
    } catch {
      let nsError = error as NSError
      debugPrint("Error saving record: \(nsError), \(nsError.userInfo)")
      return newRecord
    }
  }
  
  /// Used to add record meta data as a one to many relationship to record entity
  /// - Parameters:
  ///   - record: Entity Model to which meta data is to be attached
  ///   - recordModel: Record Model that has all the data
  private func addRecordMetaData(
    record: Record,
    recordModel: RecordModel
  ) {
    guard let documentURIs = recordModel.documentURIs else { return }
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
}

// MARK: - Update

extension RecordsDatabaseManager {
  /// Updates a specific record in the database.
  /// - Parameters:
  ///   - recordID: The unique identifier of the record to be updated
  func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String?
  ) {
    do {
      guard let record = try container.viewContext.existingObject(with: recordID) as? Record else {
        debugPrint("Record not found")
        return
      }
      record.documentID = documentID
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
