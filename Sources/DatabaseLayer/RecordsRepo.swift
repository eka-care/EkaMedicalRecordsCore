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
  let databaseAdapter = RecordDatabaseAdapter()
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
  
  // MARK: - Sync Records
  
  /// Used to fetch records from the server and store them in the database
  /// - Parameter completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(completion: @escaping () -> Void) {
    syncRecordsForPage(
      token: pageOffsetToken,
      updatedAt: recordsUpdateEpoch
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
        UserDefaultsHelper.save(customValue: recordsUpdateEpoch, withKey: Constants.lastUpdatedRecordAt)
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
      debugPrint("Records added to database")
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
  
  /// Updates a specific record in the database.
  /// - Parameters:
  ///   - recordID: The unique identifier of the record to be updated.
  ///   - updatedData: A closure that provides the updated data for the record.
  ///   - completion: Completion block executed after updating the record.
  public func updateRecord(
    recordID: NSManagedObjectID,
    updatedData: @escaping (Record) -> Void,
    completion: @escaping () -> Void
  ) {
    databaseManager.updateRecord(
      recordID: recordID,
      updatedData: updatedData,
      completion: completion
    )
  }
  
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
}

// MARK: - Network Call Helper functions

extension RecordsRepo {
  /// Used to make network call to get items in a given page
  private func syncRecordsForPage(
    token: String?,
    updatedAt: String?,
    completion: @escaping ((String?), [Vault_Records_Record]) -> Void
  ) {
    service.fetchRecords(
      token: token,
      updatedAt: updatedAt
    ) { [weak self] result, metaData in
      guard let self else { return }
      switch result {
      case .success(let response):
        /// Store the epoch in var first, update the UserDefaults ony once the last page is reached
        recordsUpdateEpoch = metaData.allHeaders?["Eka-Uat"]
        guard let responseType = response.result else { return }
        switch responseType {
        case .response(let recordsResponse):
          let recordsItems = fetchRecordsFromItems(items: recordsResponse.items)
          let nextPageToken = recordsResponse.hasNextPageToken ? recordsResponse.nextPageToken : nil
          completion(nextPageToken, recordsItems)
        case .error(let error):
          debugPrint("Error in fetching records with message \(error.message)")
        }
      case .failure(let error):
        debugPrint("Error in fetching records -> \(error.localizedDescription)")
      }
    }
  }
  
  /// Used to fetch records and map them into array from all item types array
  /// Vault_Records_Item can be of any type Eg: Lab Nudge or a Google ad
  private func fetchRecordsFromItems(items: [Vault_Records_Item]) -> [Vault_Records_Record] {
    var records: [Vault_Records_Record] = []
    items.forEach { item in
      switch item.result {
      case .record(let record):
        records.append(record)
      case .none:
        debugPrint("Different item type received")
      }
    }
    return records
  }
}
