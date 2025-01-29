//
//  RecordsRepo.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 31/12/24.
//

import Foundation
import SwiftProtoContracts
import CoreData

public final class RecordsRepo {
  
  // MARK: - Properties
  
  public let databaseManager = RecordsDatabaseManager.shared
  public let databaseAdapter = RecordDatabaseAdapter()
  let uploadManager = RecordUploadManager()
  let service: RecordsProvider = RecordsApiService()
  /// The offset token for getting the next page of records
  var pageOffsetToken: String?
  /// The epoch timestamp of the last update that will come from backend
  var recordsUpdateEpoch: String?
  
  // MARK: - Init
  
  public init() {
    recordsUpdateEpoch = UserDefaultsHelper.fetch(
      valueOfType: String.self,
      usingKey: Constants.lastUpdatedRecordAt
    )
  }
  
  /** Give a store record function that takes data and makes model that will store records
   We need to fill both record and record meta data for each add record
  */
  
  // MARK: - Sync Records
  
  /// Used to fetch records from the server and store them in the database
  /// - Parameter completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(completion: @escaping () -> Void) {
    syncRecordsForPage(
      token: pageOffsetToken,
      updatedAt: recordsUpdateEpoch,
      oid: InitConfigurations.shared.filterOID
    ) { [weak self] nextPageToken, recordItems in
      guard let self else { return }
      /// Add records to the database in batches
      databaseAdapter.convertNetworkToDatabaseModels(from: recordItems) { [weak self] databaseInsertModels in
        guard let self else { return }
        databaseManager.addRecords(from: databaseInsertModels) {
          debugPrint("Batch added to database, count -> \(databaseInsertModels.count)")
          /// If it was last page means all batcehs are added to database, hence send completion
          if nextPageToken == nil {
            completion()
          }
        }
      }
      /// Call for next page
      if let nextPageToken {
        /// Update the page offset token
        pageOffsetToken = nextPageToken
        /// Call for next page
        fetchRecordsFromServer(completion: completion)
      } else { /// We have reached last page for api calls
        /// Update the epoch in UserDefaults
        let newSyncEpoch: String = Date().getCurrentEpoch()
        recordsUpdateEpoch = newSyncEpoch
        UserDefaultsHelper.save(customValue: newSyncEpoch, withKey: Constants.lastUpdatedRecordAt)
      }
    }
  }
  
  // MARK: - Add Records
  
  /// Used to add records to the database
  /// - Parameters:
  ///   - records: list of records to be added
  ///   - completion: completion block to be executed after adding records
  public func addRecords(
    from records: [RecordModel],
    completion: @escaping () -> Void
  ) {
    databaseManager.addRecords(from: records) {
      completion()
      debugPrint("Record added to database")
    }
  }
  
  /// Used to add a single record to the database
  /// - Parameter record: record to be added
  public func addSingleRecord(record: RecordModel) {
    /// Add in database
    databaseManager.addSingleRecord(from: record)
    /// Upload to vault
    if let contentType = record.contentType {
      uploadRecordsV3(
        recordURLs: record.documentURIs,
        documentDate: record.documentDate?.toUSEnglishString(),
        contentType: contentType
      ) { uploadFormsResponse, error in}
    }
  }
  
  // MARK: - Read
  
  /// Used to fetch record entity items
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Parameter completion: completion block to be executed after fetching records
  public func fetchRecords(
    fetchRequest: NSFetchRequest<Record>,
    completion: @escaping ([Record]) -> Void
  ) {
    databaseManager.fetchRecords(
      fetchRequest: fetchRequest,
      completion: completion
    )
  }
  
  // MARK: - Update
  
//  /// Updates a specific record in the database.
//  /// - Parameters:
//  ///   - recordID: The unique identifier of the record to be updated.
//  ///   - updatedData: A closure that provides the updated data for the record.
//  ///   - completion: Completion block executed after updating the record.
//  public func updateRecord(
//    recordID: NSManagedObjectID,
//    updatedData: @escaping (Record) -> Void,
//    completion: @escaping () -> Void
//  ) {
//    databaseManager.updateRecord(
//      recordID: recordID,
//      updatedData: updatedData,
//      completion: completion
//    )
//  }
  
  // MARK: - Delete
  
  /// Used to delete records fot the given fetch request
  /// - Parameters:
  ///   - request: fetch request for records that are to be deleted
  ///   - completion: closure executed after deletion
  func deleteRecords(
    request: NSFetchRequest<NSFetchRequestResult>,
    completion: @escaping () -> Void
  ) {
    databaseManager.deleteRecords(
      request: request,
      completion: completion
    )
  }
  
  /// Used to delete a specific record from the database
  /// - Parameter record: record to be deleted
  public func deleteRecord(
    record: Record
  ) {
    /// We need to store it before deleting from database as once document is deleted we can't get the documentID
    let documentID = record.documentID
    /// Delete from database
    databaseManager.deleteRecord(record: record)
    /// Delete from vault v3
    deleteRecordV3(documentID: documentID)
  }
}
