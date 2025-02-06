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
  
  public init() {}
  
  // MARK: - Sync Records
  
  /// Used to get update token and start fetching records
  public func getUpdatedAtAndStartFetchRecords() {
    fetchLatestRecordUpdatedAtString { [weak self] updatedAt in
      guard let self else { return }
      recordsUpdateEpoch = updatedAt
      fetchRecordsFromServer {}
    }
  }
  
  /// Used to fetch records from the server and store them in the database
  /// - Parameter completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(completion: @escaping () -> Void) {
    syncRecordsForPage(
      token: pageOffsetToken,
      updatedAt: recordsUpdateEpoch,
      oid: CoreInitConfigurations.shared.filterID
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
  public func addSingleRecord(
    record: RecordModel,
    completion didUploadRecord: @escaping (Record?) -> Void
  ) {
    /// Add in database and store it in addedRecord
    let addedRecord = databaseManager.addSingleRecord(from: record)
    /// Upload to vault
    if let contentType = record.contentType {
      uploadRecordsV3(
        recordURLs: record.documentURIs,
        documentDate: record.documentDate?.toUSEnglishString(),
        contentType: contentType
      ) { [weak self] uploadFormsResponse, error in
        guard let self else { return }
        /// Update the database with document id
        databaseManager.updateRecord(
          recordID: addedRecord.objectID,
          documentID: uploadFormsResponse?.batchResponses?.first?.documentID
        )
        /// Return the added record in completion handler
        let record = databaseManager.fetchRecord(with: addedRecord.objectID)
        didUploadRecord(record)
      }
    }
  }
  
  /// Used to fetch record meta data
  public func fetchRecordMetaData(
    for record: Record,
    completion: @escaping (_ documentURIs: [String], _ reportInfo: SmartReportInfo?) -> Void
  ) {
    /// If local documents are not present or smart report is not present fetch from network and fill
    if (record.toRecordMeta?.count == 0) || (record.toSmartReport == nil) {
      fillRecordMetaDataFromNetwork(record: record, completion: completion)
    } else { /// if local documents are present give data from there
      let documentURIs = record.getLocalPathsOfFile()
      let smartReport = databaseManager.fetchSmartReportData(from: record)
      completion(documentURIs, smartReport)
    }
  }
  
  /// Used to fill record meta data like document uris and smart report from network
  private func fillRecordMetaDataFromNetwork(
    record: Record,
    completion: @escaping (_ documentURIs: [String], _ reportInfo: SmartReportInfo?) -> Void
  ) {
    getFileDetails(record: record) { [weak self] docResponse in
      guard let self else { return }
      /// Get documentURIs
      fetchDocumentURIs(files: docResponse?.files) { [weak self] documentURIs in
        guard let self else { return }
        databaseManager.addFileDetails(
          to: record,
          documentURIs: documentURIs,
          smartReportData: databaseAdapter.serializeSmartReportInfo(smartReport: docResponse?.smartReport)
        )
        let documentURIs = record.toRecordMeta?.allObjects.compactMap { ($0 as? RecordMeta)?.documentURI } ?? []
        let smartReport = databaseManager.fetchSmartReportData(from: record)
        completion(documentURIs, smartReport)
      }
    }
  }
  
  /// Used to get file details and save in database
  /// This will have both smart report and original record
  private func getFileDetails(
    record: Record,
    completion: @escaping (DocFetchResponse?) -> Void
  ) {
    guard let documentID = record.documentID else { return }
    fetchFileDetails(documentID: documentID, completion: completion)
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
  
  /// Used to update record
  /// - Parameters:
  ///   - recordID: object Id of the record
  ///   - documentID: document id of the record
  ///   - documentDate: document date of the record
  ///   - documentType: document type of the record
  public func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String? = nil,
    documentDate: Date? = nil,
    documentType: Int? = nil
  ) {
    /// Update in database
    databaseManager.updateRecord(
      recordID: recordID,
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType
    )
    /// Update call
    editDocument(
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType
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

extension RecordsRepo {
  
  /// Used to fetch updated at for the latest
  private func fetchLatestRecordUpdatedAtString(completion: @escaping (String?) -> Void) {
    fetchLatestRecord { [weak self] record in
      guard let self else { return }
      let updatedAt = fetchUpdatedAtFromRecord(record: record)
      completion(updatedAt)
    }
  }
  
  /// Used to fetch the latest document synced to server
  private func fetchLatestRecord(completion: @escaping (Record?) -> Void) {
    guard let oid = CoreInitConfigurations.shared.filterID else { return }
    databaseManager.fetchRecords(
      fetchRequest: QueryHelper.fetchLastUpdatedAt(oid: oid)
    ) { records in
      completion(records.first)
    }
  }
  
  /// Get last updated at in string format from a record model
  private func fetchUpdatedAtFromRecord(record: Record?) -> String? {
    let updatedAt = record?.updatedAt
    return updatedAt?.getCurrentEpoch()
  }
}
