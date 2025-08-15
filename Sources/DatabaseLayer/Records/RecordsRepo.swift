//
//  RecordsRepo.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 31/12/24.
//

import Foundation
import CoreData

public final class RecordsRepo {
  
  // MARK: - Properties
  public static let shared = RecordsRepo()
  public let databaseManager = RecordsDatabaseManager.shared
  public let databaseAdapter = RecordDatabaseAdapter()
  private var isSyncing = false
  private var casesSyncing = false
  let uploadManager = RecordUploadManager()
  let service: RecordsProvider = RecordsApiService()
  let casesServeice: CasesProvider = CasesApiService()
  /// The offset token for getting the next page of records
  var pageOffsetToken: String?
  var pageOffsetTokenCases: String?
  /// The epoch timestamp of the last update that will come from backend
  var recordsUpdateEpoch: String?
  var casesUpdateEpoch: String?
  // MARK: - Init
  
  private init() {}
  
  // MARK: - Sync Records
  
  /// Used to get update token and start fetching records
  public func getUpdatedAtAndStartFetchRecords(completion: @escaping (Bool) -> Void) {
    guard let oids = CoreInitConfigurations.shared.filterID, !oids.isEmpty else { 
      completion(false)
      return 
    }
    
    let dispatchGroup = DispatchGroup()
    var hasError = false
    
    for oid in oids {
      dispatchGroup.enter()
      fetchLatestRecordUpdatedAtString(oid: oid) { [weak self] updatedAt in
        guard let self else { 
          hasError = true
          dispatchGroup.leave()
          return 
        }
        recordsUpdateEpoch = updatedAt
        fetchRecordsFromServer(oid: oid) { success in
          if !success {
            hasError = true
          }
          dispatchGroup.leave()
        }
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      completion(!hasError)
    }
  }
  
  /// Used to fetch records from the server and store them in the database
  /// - Parameter completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(oid: String, completion: @escaping (Bool) -> Void) {
    syncRecordsForPage(
      token: pageOffsetToken,
      updatedAt: recordsUpdateEpoch,
      oid: oid
    ) { [weak self] nextPageToken, recordItems, error in
      guard let self else { 
        completion(false)
        return 
      }
      if error != nil {
        completion(false)
        return
      }
      /// Add records to the database in batches
      databaseAdapter.convertNetworkToDatabaseModels(from: recordItems) { [weak self] databaseInsertModels in
        guard let self else { 
          completion(false)
          return 
        }
        
        databaseManager.upsertRecords(from: databaseInsertModels) {
          debugPrint("Batch added to database, count -> \(databaseInsertModels.count)")
          /// If it was last page means all batches are added to database, hence send completion
          if nextPageToken == nil {
            pageOffsetToken = nil
            completion(true)
          }
        }
      }
      /// Call for next page
      if let nextPageToken {
        /// Update the page offset token
        pageOffsetToken = nextPageToken
        /// Call for next page
        fetchRecordsFromServer(oid: oid, completion: completion)
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
    databaseManager.upsertRecords(from: records) {
      completion()
      debugPrint("Record added to database")
    }
  }
  
  /// Used to add a single record to the database
  /// - Parameter record: record to be added
  public func addSingleRecord(
    record: RecordModel,
    completion didAddRecord: @escaping (Record?) -> Void
  ) {
    /// Add in database and store it in addedRecord
    let addedRecord = databaseManager.addSingleRecord(from: record)
    didAddRecord(addedRecord)
    /// Upload to vault
    uploadRecord(record: addedRecord) { _ in
    }
  }
 
  public func uploadRecord(
      record: Record,
      completion didUploadRecord: @escaping (Record?) -> Void
  ) {
    /// Update the upload sync status
    record.syncState = RecordSyncState.uploading.stringValue
    let documentURIs: [String] = record.toRecordMeta?.allObjects.compactMap { ($0 as? RecordMeta)?.documentURI } ?? []
    uploadRecordsV3(
      documentID: record.documentID ?? "",
      recordURLs: documentURIs,
      documentDate: record.documentDate?.toEpochInt(),
      contentType: FileType.getFileTypeFromFilePath(filePath: documentURIs.first ?? "")?.fileExtension ?? "",
      userOid: record.oid
    ) {
      [weak self] uploadFormsResponse,
      error in
      guard let self else {
        didUploadRecord(nil)
        return
      }
      guard let documentId = record.documentID else {
        didUploadRecord(nil)
        return
      }
      
      
      guard error == nil, let uploadFormsResponse else {
        databaseManager.updateRecord(documentID: documentId,syncStatus: RecordSyncState.upload(success: false))
        /// Make delete api record call so that its not availabe on server
        if let docId = uploadFormsResponse?.batchResponses?.first?.documentID  {
          deleteRecordV3(documentID: docId, oid: record.oid)
        }
        didUploadRecord(nil)
        return
      }
      
      guard let documentId = record.documentID else {
        didUploadRecord(nil)
        return
      }
      
      /// Update the database with document id
      databaseManager.updateRecord(
//        recordID: record.objectID,
        documentID: uploadFormsResponse.batchResponses?.first?.documentID ?? documentId,
        documentOid: record.oid,
        syncStatus: RecordSyncState.upload(success: true)
      )
      
      record.documentID = uploadFormsResponse.batchResponses?.first?.documentID
      didUploadRecord(record)
    }
  }
  
  /// Used to fetch record meta data
  public func fetchRecordMetaData(
    for record: Record,
    completion: @escaping (_ documentURIs: [String], _ reportInfo: SmartReportInfo?) -> Void
  ) {
    /// If local documents are not present we fetch
    /// If record is smart and smart report is nil we fetch
    /// We also check document id because without it network call wont be made
    if (record.toRecordMeta?.count == 0) ||
        (record.isSmart && record.toSmartReport == nil) &&
        record.documentID != nil {
      fillRecordMetaDataFromNetwork(record: record, completion: completion)
    } else { /// if local documents are present give data from there
      let documentURIs = record.getLocalPathsOfFile()
      let smartReport = databaseManager.fetchSmartReportData(from: record)
      completion(documentURIs, smartReport)
    }
  }
  
  /// Used to fetch RecordMetaData of multiple records
  /// - Parameters:
  ///   - records: Records for which meta data is to be fetched
  ///   - completion: Gives uris of all the documents
  public func fetchRecordsMetaData(
    for records: [Record],
    completion: @escaping (_ documentURIs: [[String]]) -> Void
  ) {
    var recordDocumentURIs: [[String]] = []
    let dispatchGroup = DispatchGroup()
    records.forEach { record in
      dispatchGroup.enter()
      fetchRecordMetaData(for: record) { documentURIs, _ in
        recordDocumentURIs.append(documentURIs)
        dispatchGroup.leave()
      }
    }
    dispatchGroup.notify(queue: .main) {
      completion(recordDocumentURIs)
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
          documentURIs: record.toRecordMeta?.count == 0 ? documentURIs : nil, /// update document uris only if they are not already present
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
    fetchFileDetails(oid: record.oid ,documentID: documentID, completion: completion)
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
  
  /// Used to get record document type count
  /// - Returns: Dictionary with count of each document type
  /// - Parameter caseID: caseID of the case if any
  public func getRecordDocumentTypeCount(caseID: String? = nil) -> [RecordDocumentType: Int] {
    let oid = CoreInitConfigurations.shared.filterID
    return databaseManager.getDocumentTypeCounts(oid: oid, caseID: caseID)
  }
  
  /// Used to get record in main thread from fetch request
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Returns: Given record
  public func getRecord(fetchRequest: NSFetchRequest<Record>) -> Record? {
    databaseManager.getRecord(fetchRequest: fetchRequest)
  }
  
  // MARK: - Update
  
  /// Used to update record
  /// - Parameters:
  ///   - recordID: object Id of the record
  ///   - documentID: document id of the record
  ///   - documentDate: document date of the record
  ///   - documentType: document type of the record
  ///   - documentOid: document oid of the record
  ///   - caseModel: case model of the record
  public func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String,
    documentDate: Date? = nil,
    documentType: Int? = nil,
    documentOid: String? = CoreInitConfigurations.shared.primaryFilterID,
    isEdited: Bool?,
    caseModel: CaseModel? = nil
  ) {
    /// Update in database
    databaseManager.updateRecord(
//      recordID: recordID,
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType,
      documentOid: documentOid,
      isEdited: isEdited,
      caseModel: caseModel
    )
    /// Update call
    editDocument(
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType,
      documentFilterId: documentOid
    ) { [weak self] isSuccess in
      guard let self = self else { return }
      self.databaseManager.updateRecord(
//        recordID: recordID,
        documentID: documentID,
        documentDate: documentDate,
        documentType: documentType,
        documentOid: documentOid,
        isEdited: !isSuccess,
        caseModel: caseModel
      )
    }
  }
  
  // MARK: - Delete
  
  /// Used to delete records fot the given fetch request
  /// - Parameters:
  ///   - request: fetch request for records that are to be deleted
  ///   - completion: closure executed after deletion
  public func deleteRecords(
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
    /// Delete from vault v3
    deleteRecordV3(documentID: documentID, oid: record.oid)
    /// Delete from database
    databaseManager.deleteRecord(record: record)
  }
}

extension RecordsRepo {
  
  /// Used to fetch updated at for the latest
  private func fetchLatestRecordUpdatedAtString(oid: String, completion: @escaping (String?) -> Void) {
    fetchLatestRecord(oid: oid) { [weak self] record in
      guard let self else { return }
      let updatedAt = fetchUpdatedAtFromRecord(record: record)
      completion(updatedAt)
    }
  }
  
  /// Used to fetch the latest document synced to server
  private func fetchLatestRecord(oid: String, completion: @escaping (Record?) -> Void) {
    databaseManager.fetchRecords(
      fetchRequest: QueryHelper.fetchLastUpdatedAt(oid: oid)
    ) { records in
      completion(records.first)
    }
  }
  
  /// Get last updated at in string format from a record model
  private func fetchUpdatedAtFromRecord(record: Record?) -> String? {
    let updatedAt = record?.updatedAt
    return updatedAt?.toEpochString()
  }
  
  /// Used to sync the unuploaded records
  public func syncUnuploadedRecords(completion: @escaping () -> Void = {}) {
      syncNewRecords { [weak self] in
          guard let self = self else { 
            completion()
            return 
          }
        self.syncEditedRecords { 
          completion()
        }
      }
  }

  private func syncNewRecords(completion: @escaping () -> Void) {
      fetchRecords(fetchRequest: QueryHelper.fetchRecordsWithUploadingOrFailedState()) { [weak self] records in
          guard let self = self else {
              completion()
              return
          }
          
          // Handle case where there are no records to upload
          guard !records.isEmpty else {
              completion()
              return
          }
          
          let uploadGroup = DispatchGroup()
          
          for record in records {
              uploadGroup.enter()
              self.uploadRecord(record: record) { _ in
                  uploadGroup.leave()
              }
          }
          
          uploadGroup.notify(queue: .global(qos: .utility)) {
              completion()
          }
      }
  }

  private func syncEditedRecords(completion: @escaping () -> Void) {
      fetchRecords(fetchRequest: QueryHelper.fetchRecordsForEditedRecordSync()) { [weak self] records in
          guard let self = self else {
              completion()
              return
          }
          // Handle case where there are no records to edit
          guard !records.isEmpty else {
              completion()
              return
          }
          let editGroup = DispatchGroup()
          for record in records {
              // Skip if documentID is missing
              guard let documentID = record.documentID else {
                  continue
              }
              editGroup.enter()
              self.editDocument(documentID: documentID, documentFilterId: record.oid) { [weak self] isSuccess in
                  guard let self = self else {
                      editGroup.leave()
                      return
                  }
                  self.databaseManager.updateRecord(
                      documentID: documentID,
                      documentOid: record.oid,
                      isEdited: !isSuccess // mark as not edited if sync succeeded
                  )
                  
                  editGroup.leave()
              }
          }
          editGroup.notify(queue: .global(qos: .utility)) {
              completion()
          }
      }
  }
}
//
//extension RecordsRepo {
//  
//  /// Used to sync the unuploaded records
//  public func syncUnsyncedcases() {
//    guard !casesSyncing else { return }
//    casesSyncing = true
//    
//    syncNewCases { [weak self] in
//      guard let self = self else { return }
//      self.syncEditedCases { [weak self] in
//        self?.casesSyncing = false
//      }
//    }
//  }
//  
//  private func syncNewCases(completion: @escaping () -> Void) {
//    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchCasesForUnCretedOnServerSync()) { [weak self] cases in
//      guard let self = self else {
//        completion()
//        return
//      }
//      
//      // Handle case where there are no cases to upload
//      guard !cases.isEmpty else {
//        completion()
//        return
//      }
//      
//      let uploadGroup = DispatchGroup()
//      
//      for uploadcase in cases {
//        uploadGroup.enter()
//        
//        self.casesServeice.createCases(oid: uploadcase.oid ?? "", request: CasesCreateRequest(id: uploadcase.caseID ?? "", displayName: uploadcase.caseName ?? "", type: uploadcase.caseType ?? "", occurredAt: uploadcase.createdAt?.toEpochInt() ?? Date().toEpochInt())) { [weak self] result, statusCode in
//          guard self != nil else {
//            uploadGroup.leave()
//            return
//          }
//          
//          switch result {
//          case .success(let caseDetails):
//            debugPrint("Case successfully created on the server.")
//            
//          case .failure(let error):
//            debugPrint("Failed to create case on server: \(error.localizedDescription)")
//          }
//          uploadGroup.leave()
//        }
//      }
//      
//      uploadGroup.notify(queue: .global(qos: .utility)) {
//        completion()
//      }
//    }
//  }
//  
//  private func syncEditedCases(completion: @escaping () -> Void) {
//    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchCasesForEditedSync()) { [weak self] cases in
//      guard let self = self else {
//        completion()
//        return
//      }
//      
//      // Handle case where there are no cases to edit
//      guard !cases.isEmpty else {
//        completion()
//        return
//      }
//      
//      let editGroup = DispatchGroup()
//      
//      for caseItem in cases {
//        editGroup.enter()
//        self.casesServeice.updateCases(caseId: caseItem.caseID ?? "", oid: caseItem.oid ?? "", request: CasesUpdateRequest(displayName: caseItem.caseName, type: caseItem.caseType)) { [weak self] result, statusCode in
//          guard self != nil else {
//            editGroup.leave()
//            return
//          }
//          
//          switch result {
//          case .success(let caseDetails):
//            debugPrint("Case successfully created on the server.")
//            
//          case .failure(let error):
//            debugPrint("Failed to create case on server: \(error.localizedDescription)")
//          }
//          editGroup.leave()
//        }
//      }
//      
//      editGroup.notify(queue: .global(qos: .utility)) {
//        completion()
//      }
//    }
//  }
//}
