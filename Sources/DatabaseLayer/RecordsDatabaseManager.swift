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
  
  public var container: NSPersistentContainer
  public let backgroundContext: NSManagedObjectContext
//  public var mainContext: NSManagedObjectContext
  var batchIndex: Int = 0
  
  public static let shared = RecordsDatabaseManager()
  
  // MARK: - Init
  
  private init() {
    let bundle = Bundle.module
    let modelURL = bundle.url(forResource: RecordsDatabaseVersion.containerName, withExtension: "mom")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!
    container = NSPersistentContainer(name: RecordsDatabaseVersion.containerName, managedObjectModel: model)
    // Loading of persistent stores
    container.loadPersistentStores { (storeDescription, error) in
      if let error {
        fatalError("Failed to load store: \(error)")
      }
    }
    
    // Setup background context
    backgroundContext = container.newBackgroundContext()
    backgroundContext.automaticallyMergesChangesFromParent = true
    
    /**
     https://stackoverflow.com/questions/70404998/coredata-can-we-always-use-backgroundcontext-regardless-of-main-or-background
     A known good strategy is to make your main thread context be a child context of a background context. Then saves are fast and done on the background. Reads are frequently serviced from the main thread. If you have some large insertions to perform, then perform them on a background child context of the main context. As the save is percolated up the context chain, the UI remains responsive.
     */
    
//    // Setup main context as child of background context
//    mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//    mainContext.automaticallyMergesChangesFromParent = true
//    mainContext.parent = backgroundContext
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
  ///   - recordID: The unique identifier of the record to be updated.
  ///   - updatedData: A closure that provides the updated data for the record.
  ///   - completion: Completion block executed after updating the record.
//  func updateRecord(
//    recordID: NSManagedObjectID,
//    updatedData: @escaping (Record) -> Void,
//    completion: @escaping () -> Void
//  ) {
//    /// This operation is done on main thread since its single item update
//    mainContext.perform { [weak self] in
//      guard let self else { return }
//      
//      do {
//        /// Fetch the record by ID
//        guard let record = try self.mainContext.existingObject(with: recordID) as? Record else {
//          debugPrint("Record not found")
//          return
//        }
//        
//        /// Apply updates
//        updatedData(record)
//        
//        /// Save the main context (automatic merge will sync changes to background context)
//        try self.mainContext.save()
//        
//        /// Call the completion block on the main thread
//        completion()
//      } catch {
//        debugPrint("Failed to update record: \(error)")
//      }
//    }
//  }
}

// MARK: - Delete

extension RecordsDatabaseManager {
  func deleteRecord() {
    
  }
  
  /// Used to delete records fot the given fetch request
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
}

