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
  let casesService: CasesProvider = CasesApiService()
  /// The epoch timestamp of the last update that will come from backend
  var lastSourceRefreshedAt: Double?
  var recordsUpdateEpoch: String?
  var casesUpdateEpoch: String?
  // MARK: - Init
  
  private init() {}
  
  // MARK: - Sync Records
  
  /// Used to get update token and start fetching records
  public func getUpdatedAtAndStartFetchRecords(completion: @escaping (Bool, Int?) -> Void) {
    guard let oids = CoreInitConfigurations.shared.filterID, !oids.isEmpty else {
      EkaMedicalRecordsCoreLogger.capture("Missing or empty filterID configuration")
      completion(false,nil)
      return
    }
    
    let dispatchGroup = DispatchGroup()
    var hasError = false
    var sourceRefreshedAtServer: Int?
    for oid in oids {
      dispatchGroup.enter()
      fetchLatestRecordUpdatedAtString(oid: oid) { [weak self] updatedAt in
        guard let self else {
          hasError = true
          dispatchGroup.leave()
          return
        }
        recordsUpdateEpoch = updatedAt
        fetchRecordsFromServer(oid: oid) {  success , lastSourceRefreshedAt in
          if !success {
            hasError = true
          }
          sourceRefreshedAtServer = lastSourceRefreshedAt
          dispatchGroup.leave()
        }
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      completion(!hasError, sourceRefreshedAtServer)
    }
  }
  
  /// Used to fetch records from the server and store them in the database
  /// - Parameters:
  ///   - oid: Organization ID
  ///   - pageOffsetToken: Token for pagination, pass nil for first page
  ///   - completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(oid: String, pageOffsetToken: String? = nil, completion: @escaping (Bool, Int?) -> Void) {
    syncRecordsForPage(
      token: pageOffsetToken,
      updatedAt: recordsUpdateEpoch,
      oid: oid
    ) { [weak self] nextPageToken, lastSourceRefreshedAt,recordItems, error in
      guard let self else {
        completion(false, nil)
        return
      }
      guard  error == nil else {
        completion(false, nil)
        return
      }
      /// Add records to the database in batches
      databaseAdapter.convertNetworkToDatabaseModels(from: recordItems) { [weak self] databaseInsertModels in
        guard let self else { 
          completion(false, nil)
          return
        }
        
        databaseManager.upsertRecords(from: databaseInsertModels) {
          EkaMedicalRecordsCoreLogger.capture("Batch added to database, count -> \(databaseInsertModels.count)")
          /// If it was last page means all batches are added to database, hence send completion
          if nextPageToken == nil {
            completion(true, lastSourceRefreshedAt)
          }
        }
      }
      /// Call for next page
      if let nextPageToken {
        /// Call for next page with the new token
        self.fetchRecordsFromServer(oid: oid, pageOffsetToken: nextPageToken, completion: completion)
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
      EkaMedicalRecordsCoreLogger.capture("Record added to database")
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
    let casesLinkedToRecord: [String]? = record.toCaseModel?.allObjects.compactMap { ($0 as? CaseModel)?.caseID }
    
    let documentURIs: [String] = record.toRecordMeta?.allObjects.compactMap { ($0 as? RecordMeta)?.documentURI } ?? []
    uploadRecordsV3(
      documentID: record.documentID ?? "",
      recordURLs: documentURIs,
      documentDate: record.documentDate?.toEpochInt(),
      contentType: FileType.getFileTypeFromFilePath(filePath: documentURIs.first ?? "")?.fileExtension ?? "",
      userOid: record.oid,
      linkedCases: casesLinkedToRecord
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
  public func getRecordDocumentTypeCount(caseID: String? = nil) -> [String: Int] {
    let oid = CoreInitConfigurations.shared.filterID
    return databaseManager.getDocumentTypeCounts(oid: oid, caseID: caseID)
  }
  
  /// Used to get record tag count
  /// - Returns: Dictionary with count of each tag
  /// - Parameter caseID: caseID of the case if any
  /// - Parameter documentType: documentType to filter records by
  public func getRecordTagCount(caseID: String? = nil, documentType: String? = nil) -> [String: Int] {
    let oid = CoreInitConfigurations.shared.filterID
    return databaseManager.getTagCounts(oid: oid, caseID: caseID, documentType: documentType)
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
  ///   - tags: array of tag names for the record
  public func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String,
    documentDate: Date? = nil,
    documentType: String? = nil,
    documentOid: String? = CoreInitConfigurations.shared.primaryFilterID,
    isEdited: Bool?,
    caseModels: [CaseModel]? = nil,
    tags: [String]? = nil
  ) {
    /// Update in database
    databaseManager.updateRecord(
//      recordID: recordID,
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType,
      documentOid: documentOid,
      isEdited: isEdited,
      caseModels: caseModels,
      tags: tags
    )
    
    let caseListIds = caseModels?.compactMap(\.caseID) ?? []
    /// Update call
    editDocument(
      documentID: documentID,
      documentDate: documentDate,
      documentType: documentType,
      documentFilterId: documentOid,
      linkedCases: caseListIds,
      tags: tags
    ) { [weak self] isSuccess in
      guard let self = self else { return }
      self.databaseManager.updateRecord(
//        recordID: recordID,
        documentID: documentID,
        documentDate: documentDate,
        documentType: documentType,
        documentOid: documentOid,
        isEdited: !isSuccess,
        caseModels: caseModels,
        tags: tags
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
  
  // MARK: - Case Management
  
  /// Used to delink a case from a record
  /// - Parameters:
  ///   - record: The record from which to remove the case association
  ///   - caseId: The ID of the case to delink from the record
  ///   - completion: Completion handler with success status
  public func delinkCaseFromRecord(
    record: Record,
    caseId: String,
    completion: @escaping (Bool) -> Void
  ) {
    // Validate parameters
    guard !caseId.isEmpty else {
      EkaMedicalRecordsCoreLogger.capture("Cannot delink case: caseId is empty")
      completion(false)
      return
    }
    
    guard let documentID = record.documentID else {
      EkaMedicalRecordsCoreLogger.capture("Cannot delink case: record documentID is nil")
      completion(false)
      return
    }
    
    // Check if the record is actually associated with this case
    guard record.isAssociatedWith(caseID: caseId) else {
      EkaMedicalRecordsCoreLogger.capture("Record is not associated with case ID: \(caseId)")
      completion(false)
      return
    }
    
    // Find the specific case model to remove
    let caseModels = record.getCaseModels()
    guard let caseModelToRemove = caseModels.first(where: { $0.caseID == caseId }) else {
      EkaMedicalRecordsCoreLogger.capture("Case model not found for case ID: \(caseId)")
      completion(false)
      return
    }
    
    // Remove the case association from the database
    record.removeCaseModel(caseModelToRemove)
    
    // Get the updated list of linked cases after removal
    let updatedLinkedCases = record.getCaseIDs()
    
    // Sync the change with the server
    editDocument(
      documentID: documentID,
      documentDate: record.documentDate,
      documentType: record.documentType,
      documentFilterId: record.oid,
      linkedCases: updatedLinkedCases
    ) { [weak self] isSuccess in
      guard let self = self else {
        completion(false)
        return
      }
      
      if isSuccess {
        EkaMedicalRecordsCoreLogger.capture("Successfully delinked case \(caseId) from record \(documentID)")
        // Update the record's edit status to reflect successful sync
        self.databaseManager.updateRecord(
          documentID: documentID,
          documentOid: record.oid,
          isEdited: false
        )
        completion(true)
      } else {
        // If network sync failed, re-add the case association to maintain consistency
        record.addCaseModel(caseModelToRemove)
        EkaMedicalRecordsCoreLogger.capture("Failed to sync delink operation for case \(caseId) from record \(documentID)")
        // Mark record as edited since local and server state are now out of sync
        self.databaseManager.updateRecord(
          documentID: documentID,
          documentOid: record.oid,
          isEdited: true
        )
        completion(false)
      }
    }
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
  
  /// Clears all data from the database on user logout
  /// This function destroys and recreates the entire persistent store for complete data wipe
  /// - Parameter completion: Completion handler with Result<Void, Error> for detailed error handling
  public func clearAllDataOnLogout(completion: @escaping (Result<Void, Error>) -> Void) {
    databaseManager.onLogoutClearData(completion: completion)
  }
}

extension RecordsRepo {
  
  /// Used to fetch updated at for the latest
  func fetchLatestRecordUpdatedAtString(oid: String, completion: @escaping (String?) -> Void) {
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
  public func syncUnuploadedRecords(completion: @escaping (Result<Void, Error>) -> Void) {
      syncNewRecords { [weak self] newRecordsResult in
          guard let self = self else { 
            completion(.failure(ErrorHelper.selfDeallocatedError()))
            return 
          }
          
          switch newRecordsResult {
          case .success:
            self.syncEditedRecords { editedRecordsResult in
              completion(editedRecordsResult)
            }
          case .failure(let error):
            completion(.failure(error))
          }
      }
  }

  private func syncNewRecords(completion: @escaping (Result<Void, Error>) -> Void) {
      fetchRecords(fetchRequest: QueryHelper.fetchRecordsWithUploadingOrFailedState()) { [weak self] records in
          guard let self = self else {
              completion(.failure(ErrorHelper.selfDeallocatedError()))
              return
          }
          
          // Handle case where there are no records to upload
          guard !records.isEmpty else {
              completion(.success(()))
              return
          }
          
          let uploadGroup = DispatchGroup()
          var errors: [Error] = []
          let errorsQueue = DispatchQueue(label: "syncNewRecords.errors", attributes: .concurrent)
          
          for record in records {
              uploadGroup.enter()
              self.uploadRecord(record: record) { uploadedRecord in
                  if uploadedRecord == nil {
                      let uploadError = ErrorHelper.createError(
                          domain: .sync,
                          code: .networkRequestFailed,
                          message: "Failed to upload record: \(record.documentID ?? "unknown")"
                      )
                      errorsQueue.async(flags: .barrier) {
                          errors.append(uploadError)
                      }
                  }
                  uploadGroup.leave()
              }
          }
          
          uploadGroup.notify(queue: .global(qos: .utility)) {
              if errors.isEmpty {
                  completion(.success(()))
              } else {
                  let combinedError = ErrorHelper.syncOperationError(
                      operation: "sync new records",
                      failureCount: errors.count,
                      errors: errors
                  )
                  completion(.failure(combinedError))
              }
          }
      }
  }

  private func syncEditedRecords(completion: @escaping (Result<Void, Error>) -> Void) {
      fetchRecords(fetchRequest: QueryHelper.fetchRecordsForEditedRecordSync()) { [weak self] records in
          guard let self = self else {
              completion(.failure(ErrorHelper.selfDeallocatedError()))
              return
          }
          // Handle case where there are no records to edit
          guard !records.isEmpty else {
              completion(.success(()))
              return
          }
          
          let editGroup = DispatchGroup()
          var errors: [Error] = []
          let errorsQueue = DispatchQueue(label: "syncEditedRecords.errors", attributes: .concurrent)
          
          for record in records {
              // Skip if documentID is missing
              guard let documentID = record.documentID else {
                  let validationError = ErrorHelper.validationError(missingFields: ["documentID"])
                  errorsQueue.async(flags: .barrier) {
                      errors.append(validationError)
                  }
                  continue
              }
              editGroup.enter()
            let linkedCaseIds: [String] = record.getCaseIDs()
            self.editDocument(documentID: documentID, documentType: record.documentType, documentFilterId: record.oid, linkedCases: linkedCaseIds) { [weak self] isSuccess in
                  guard let self = self else {
                      editGroup.leave()
                      return
                  }
                  
                  if !isSuccess {
                      let editError = ErrorHelper.createError(
                          domain: .sync,
                          code: .networkRequestFailed,
                          message: "Failed to edit record: \(documentID)"
                      )
                      errorsQueue.async(flags: .barrier) {
                          errors.append(editError)
                      }
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
              if errors.isEmpty {
                  completion(.success(()))
              } else {
                  let combinedError = ErrorHelper.syncOperationError(
                      operation: "sync edited records",
                      failureCount: errors.count,
                      errors: errors
                  )
                  completion(.failure(combinedError))
              }
          }
      }
  }
}

extension RecordsRepo {
  
  /// Used to sync the unuploaded records
  public func syncUnsyncedCases(completion: @escaping (Result<Void, Error>) -> Void) {
    syncNewCases { [weak self] newCasesResult in
      guard let self  else {
        completion(.failure(ErrorHelper.selfDeallocatedError()))
        return 
      }
      
      switch newCasesResult {
      case .success:
        syncEditedCases { editedCasesResult in
          completion(editedCasesResult)
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  private func syncNewCases(completion: @escaping (Result<Void, Error>) -> Void) {
    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchCasesForUncreatedOnServerSync()) { [weak self] cases in
      guard let self else {
        completion(.failure(ErrorHelper.selfDeallocatedError()))
        return
      }
      
      // Handle case where there are no cases to upload
      guard !cases.isEmpty else {
        completion(.success(()))
        return
      }
      
      let uploadGroup = DispatchGroup()
      var errors: [Error] = []
      let errorsQueue = DispatchQueue(label: "syncNewCases.errors", attributes: .concurrent)
      
      for uploadcase in cases {
        uploadGroup.enter()
        
        // Validate that all required data is available before making the API call
        guard let caseID = uploadcase.caseID, !caseID.isEmpty,
              let caseName = uploadcase.caseName, !caseName.isEmpty,
              let caseType = uploadcase.caseType, !caseType.isEmpty,
              let oid = uploadcase.oid, !oid.isEmpty else {
          let missingFields = [
            uploadcase.caseID?.isEmpty != false ? "caseID" : nil,
            uploadcase.caseName?.isEmpty != false ? "caseName" : nil,
            uploadcase.caseType?.isEmpty != false ? "caseType" : nil,
            uploadcase.oid?.isEmpty != false ? "oid" : nil
          ].compactMap { $0 }
          let validationError = ErrorHelper.validationError(missingFields: missingFields)
          EkaMedicalRecordsCoreLogger.capture("Skipping case creation - missing required data: \(missingFields.joined(separator: ", "))")
          errorsQueue.async(flags: .barrier) {
            errors.append(validationError)
          }
          uploadGroup.leave()
          continue
        }
        
        self.casesService.createCases(oid: oid, request: CasesCreateRequest(id: caseID, displayName: caseName, hiType: nil ,occurredAt: uploadcase.createdAt?.toEpochInt() ?? Date().toEpochInt(), type: caseType, partnerMeta: nil)) { [weak self] result, statusCode in
          guard let self else {
            uploadGroup.leave()
            return
          }
          
          switch result {
          case .success(_):
            EkaMedicalRecordsCoreLogger.capture("Case successfully created on the server.")
            // Update the case to mark it as remotely created
            let updateModel = CaseArguementModel(
              caseId: uploadcase.caseID,
              isRemoteCreated: true
            )
            self.databaseManager.updateCase(
              caseModel: uploadcase,
              caseArguementModel: updateModel
            )
            
          case .failure(let error):
            EkaMedicalRecordsCoreLogger.capture("Failed to create case on server: \(error.localizedDescription)")
            errorsQueue.async(flags: .barrier) {
              errors.append(error)
            }
          }
          uploadGroup.leave()
        }
      }
      
      uploadGroup.notify(queue: .global(qos: .utility)) {
        if errors.isEmpty {
          completion(.success(()))
        } else {
          let combinedError = ErrorHelper.syncOperationError(
            operation: "sync new cases",
            failureCount: errors.count,
            errors: errors
          )
          completion(.failure(combinedError))
        }
      }
    }
  }
  
  private func syncEditedCases(completion: @escaping (Result<Void, Error>) -> Void) {
    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchCasesForEditedSync()) { [weak self] cases in
      guard let self  else {
        completion(.failure(ErrorHelper.selfDeallocatedError()))
        return
      }
      
      // Handle case where there are no cases to edit
      guard !cases.isEmpty else {
        completion(.success(()))
        return
      }
      
      let editGroup = DispatchGroup()
      var errors: [Error] = []
      let errorsQueue = DispatchQueue(label: "syncEditedCases.errors", attributes: .concurrent)
      
      for caseItem in cases {
        editGroup.enter()
        
        // Validate that all required data is available before making the API call
        guard let caseID = caseItem.caseID, !caseID.isEmpty,
              let oid = caseItem.oid, !oid.isEmpty else {
          let missingFields = [
            caseItem.caseID?.isEmpty != false ? "caseID" : nil,
            caseItem.oid?.isEmpty != false ? "oid" : nil
          ].compactMap { $0 }
          let validationError = ErrorHelper.validationError(missingFields: missingFields)
          EkaMedicalRecordsCoreLogger.capture("Skipping case update - missing required data: \(missingFields.joined(separator: ", "))")
          errorsQueue.async(flags: .barrier) {
            errors.append(validationError)
          }
          editGroup.leave()
          continue
        }
        
        self.casesService.updateCases(caseId: caseID, oid: oid, request: CasesUpdateRequest(displayName: caseItem.caseName, type: caseItem.caseType, hiType: nil)) { [weak self] result, statusCode in
          guard let self else {
            editGroup.leave()
            return
          }
          
          switch result {
          case .success(_):
            EkaMedicalRecordsCoreLogger.capture("Case successfully updated on the server.")
            // Update the case to mark it as not edited (sync completed)
            let updateModel = CaseArguementModel(
              caseId: caseItem.caseID,
              isEdited: false
            )
            self.databaseManager.updateCase(
              caseModel: caseItem,
              caseArguementModel: updateModel
            )
            
          case .failure(let error):
            EkaMedicalRecordsCoreLogger.capture("Failed to update case on server: \(error.localizedDescription)")
            errorsQueue.async(flags: .barrier) {
              errors.append(error)
            }
          }
          editGroup.leave()
        }
      }
      
      editGroup.notify(queue: .global(qos: .utility)) {
        if errors.isEmpty {
          completion(.success(()))
        } else {
          let combinedError = ErrorHelper.syncOperationError(
            operation: "sync edited cases",
            failureCount: errors.count,
            errors: errors
          )
          completion(.failure(combinedError))
        }
      }
    }
  }
}

extension RecordsRepo {
  public func requestForceRefresh(completion: @escaping (Result<Bool, Error>, Int?) -> Void) {
    guard let oid = CoreInitConfigurations.shared.primaryFilterID else {
      completion(.failure(ErrorHelper.configurationMissingError(configName: "primaryFilterID")), nil)
      return
    }
    
    self.service.sendSourceRefreshRequest(oid: oid) { result, statusCode in
      switch result {
      case .success(_):
        completion(.success(true), statusCode)
      case .failure(let error):
        completion(.failure(error), statusCode)
      }
    }
  }
}
