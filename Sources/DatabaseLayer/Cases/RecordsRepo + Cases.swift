//
//  RecordsRepo + Cases.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 21/07/25.
//
import Foundation

extension RecordsRepo {
  
  /// Adds a new case to the local database and attempts to sync it to the server.
  /// - Parameter caseArguementModel: Model describing the case to be added.
  /// - Returns: The case model that was added.
  /// On API success, the case is marked as remotely created and updated with the server response.
  /// On API failure, the case is marked as not synced.
  public func addCase(caseArguementModel: CaseArguementModel) {
    // Create locally
    let localCase = databaseManager.createCase(from: caseArguementModel)
    
    // Try syncing with server
    createCaseOnServer(createCase: localCase) { [weak self] result in
      guard let self else { return }
      
      let isRemoteCreated: Bool
      switch result {
      case .success:
        isRemoteCreated = true
      case .failure(let error):
        isRemoteCreated = false
        EkaMedicalRecordsCoreLogger.capture(
          "Failed to create case on server: \(error.localizedDescription)"
        )
      }
      
      let updateModel = CaseArguementModel(
        caseId: localCase.caseID,
        isRemoteCreated: isRemoteCreated
      )
      self.databaseManager.updateCase(
        caseModel: localCase,
        caseArguementModel: updateModel
      )
    }
  }
  
  /// Updates an existing case locally and attempts to sync it to the server.
  /// - Parameters:
  ///   - caseModel: The case model to be updated.
  ///   - caseArguementModel: Model describing the case updates.
  /// On API success, the case is updated with the new values.
  /// On API failure, an error is logged.
  public func updateCase(
    caseModel: CaseModel,
    caseArguementModel: CaseArguementModel
  ) {
    
    databaseManager.updateCase(
      caseModel: caseModel,
      caseArguementModel: caseArguementModel
    )
   
    
    guard let caseId = caseModel.caseID else {
      EkaMedicalRecordsCoreLogger.capture("Case ID is missing, skipping server update.")
      return
    }
    guard let oid = caseModel.oid else {
      EkaMedicalRecordsCoreLogger.capture("Case OID is missing, skipping server update.")
      return
    }
    
    var updatedArg = caseArguementModel
    
    // Try syncing with server
    updateCaseOnServer(caseId: caseId, oid: oid, updateCase: caseModel) { [weak self] result in
      switch result {
      case .success:
        EkaMedicalRecordsCoreLogger.capture("Case \(caseId) updated successfully on server.")
        updatedArg.isEdited = false
        self?.databaseManager.updateCase(
          caseModel: caseModel,
          caseArguementModel: updatedArg
        )
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failed to update case \(caseId) on server: \(error.localizedDescription)")
        updatedArg.isEdited = true
        self?.databaseManager.updateCase(
          caseModel: caseModel,
          caseArguementModel: updatedArg
        )
      }
    }
  }
  
  /// Deletes a case locally and then attempts to delete it on the server (if caseId and oid exist).
  /// - Parameter caseModel: The case to be deleted.
  public func deleteCase(
    _ caseModel: CaseModel,
  ) {
    guard let caseId = caseModel.caseID else {
      EkaMedicalRecordsCoreLogger.capture("Case ID is missing, skipping server deletion.")
      return
    }
    guard let oid = caseModel.oid else {
      EkaMedicalRecordsCoreLogger.capture("Case OID is missing, skipping server deletion.")
      return
    }
    
    deleteCaseOnServer(caseId: caseId, oid: oid) {[weak self] result in
      guard let self else { return }
      switch result {
      case .success:
        // Delete locally
        databaseManager.deleteCase(caseModel: caseModel)
        EkaMedicalRecordsCoreLogger.capture("Case \(caseId) deleted successfully from server.")
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failed to delete case \(caseId) from server: \(error.localizedDescription)")
      }
    }
  }
}




extension RecordsRepo {
  
  
  /// Creates a case on the server using the provided CaseModel.
  /// - Parameters:
  ///   - createCase: CaseModel to create on server.
  ///   - completion: Completion handler with Result<CasesCreateResponse, Error>.
  private func createCaseOnServer(
    createCase: CaseModel,
    completion: @escaping (Result<CasesCreateResponse, Error>) -> Void
  ) {
    guard let caseId = createCase.caseID, let oid = createCase.oid else {
      EkaMedicalRecordsCoreLogger.capture("Case ID is missing. Cannot create case on server.")
      let missingFields = [
        createCase.caseID == nil ? "caseID" : nil,
        createCase.oid == nil ? "oid" : nil
      ].compactMap { $0 }
      completion(.failure(ErrorHelper.validationError(missingFields: missingFields)))
      return
    }
    
    guard let caseName = createCase.caseName, !caseName.isEmpty  else {
      EkaMedicalRecordsCoreLogger.capture("Case name is missing. Cannot create case on server.")
      completion(.failure(ErrorHelper.validationError(missingFields: ["caseName"])))
      return
    }
    
    let request = CasesCreateRequest(
      id: caseId,
      displayName: caseName,
      hiType: nil,
      occurredAt: createCase.occuredAt?.toEpochInt() ?? Date().toEpochInt(),
      type: createCase.caseType ?? "",
      partnerMeta: nil,
    )
    
    casesService.createCases(oid: oid, request: request) {  result, statusCode in
      switch result {
      case .success(let caseDetails):
        EkaMedicalRecordsCoreLogger.capture("Case successfully created on the server.")
        completion(.success(caseDetails))
        
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failed to create case on server: \(error.localizedDescription)")
        completion(.failure(error))
      }
    }
  }
  
  /// Deletes a case from the server.
  /// - Parameters:
  ///   - caseId: The case ID to delete.
  ///   - oid: Organization ID.
  ///   - completion: Completion handler with Result<Bool, Error>.
  func deleteCaseOnServer(
    caseId: String,
    oid: String,
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    casesService.delete(caseId: caseId, oid: oid) { result, error in
      switch result {
      case .success:
        EkaMedicalRecordsCoreLogger.capture("Case deleted successfully")
        completion(.success(true))
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failed to delete Case: \(error.localizedDescription)")
        completion(.failure(error))
      }
    }
  }
  
  /// Updates a case on the server.
  /// - Parameters:
  ///   - caseId: The case ID to update.
  ///   - oid: Organization ID.
  ///   - updateCase: The updated CaseModel.
  ///   - completion: Completion handler with Result<Bool, Error>.
  func updateCaseOnServer(
    caseId: String,
    oid: String,
    updateCase: CaseModel,
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    let request = CasesUpdateRequest(
      displayName: updateCase.caseName,
      type: updateCase.caseType,
      hiType: nil,
      occuredAt: updateCase.occuredAt?.toEpochInt()
    )
    
    casesService.updateCases(caseId: caseId, oid: oid, request: request) { result, error in
      switch result {
      case .success:
        EkaMedicalRecordsCoreLogger.capture("Case updated successfully")
        completion(.success(true))
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failed to update Case: \(error.localizedDescription)")
        completion(.failure(error))
      }
    }
  }
}




extension RecordsRepo {
  
  /// Fetches the latest updated timestamp for all configured OIDs and starts case  sync from server.
  /// - Parameter completion: Completion handler called after records sync for each OID.
  public func getUpdatedAtAndStartCases(completion: @escaping (Bool) -> Void) {
    guard let oids = CoreInitConfigurations.shared.filterID, !oids.isEmpty else {
      completion(false)
      return
    }
    
    let dispatchGroup = DispatchGroup()
    var hasError = false
    
    for oid in oids {
      dispatchGroup.enter()
      fetchLatestCasesUpdatedAtString(oid: oid) { [weak self] updatedAt in
        guard let self else {
          hasError = true
          dispatchGroup.leave()
          return
        }
        casesUpdateEpoch = updatedAt
        fetchCasesFromServer(oid: oid, pageOffsetTokenCases: nil) { [weak self] success in
          guard self != nil else {
            hasError = true
            dispatchGroup.leave()
            return
          }
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
  
  /// Fetches the latest case for the given OID and returns its updatedAt as string.
  /// - Parameters:
  ///   - oid: Organization ID.
  ///   - completion: Completion handler with updatedAt string.
  func fetchLatestCasesUpdatedAtString(oid: String, completion: @escaping (String?) -> Void) {
    fetchLatestCases(oid: oid) { [weak self] recievedCase in
      guard let self else { return }
      let updatedAt = fetchUpdatedAtFromCases(recievedCase: recievedCase)
      completion(updatedAt)
    }
  }
  
  /// Extracts the updatedAt property from a CaseModel as epoch string.
  /// - Parameter recievedCase: The case to extract from.
  /// - Returns: Epoch string of updatedAt.
  func fetchUpdatedAtFromCases(recievedCase: CaseModel?) -> String? {
    let updatedAt = recievedCase?.updatedAt
    return updatedAt?.toEpochString()
  }
  
  /// Fetches the latest case for the given OID from the local database.
  /// - Parameters:
  ///   - oid: Organization ID.
  ///   - completion: Completion handler with CaseModel.
  func fetchLatestCases(oid: String, completion: @escaping (CaseModel?) -> Void) {
    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchLastCaseUpdatedAt(oid: oid), completion: {  cases in
      completion(cases.first)
    })
  }
  
  /// Fetches cases from server for the given OID and updates the local database in batches.
  /// Handles pagination via nextPageToken.
  /// - Parameters:
  ///   - oid: Organization ID.
  ///   - completion: Completion handler called after all batches are added.
    public func fetchCasesFromServer(oid: String, pageOffsetTokenCases: String? = nil, completion: @escaping (Bool) -> Void) {
    syncCasesForPage(
      token: pageOffsetTokenCases,
      updatedAt: casesUpdateEpoch,
      oid: oid
    ) { [weak self] nextPageToken, caseItems, error in
      guard let self else { 
        completion(false)
        return 
      }
      guard  error == nil  else {
        completion(false)
        return
      }
      /// Add cases to the database in batches
      databaseAdapter.convertNetworkToCaseDatabaseModel(from: caseItems) { [weak self] databaseInsertModels in
        guard let self else { 
          completion(false)
          return 
        }
        
        databaseManager.upsertCases(from: databaseInsertModels) {
          EkaMedicalRecordsCoreLogger.capture("Batch added to database, count -> \(databaseInsertModels.count)")
          /// If it was last page means all batches are added to database, hence send completion
          if nextPageToken == nil {
            completion(true)
          }
        }
      }
      /// Call for next page if available
      if let nextPageToken {
        /// Call for next page with the new token
        self.fetchCasesFromServer(oid: oid, pageOffsetTokenCases: nextPageToken, completion: completion)
      }
    }
  }
  
  /// Syncs cases for a given page token, updatedAt, and oid.
  /// Used for paginated case fetching from server.
  /// - Parameters:
  ///   - token: Page token for pagination.
  ///   - updatedAt: Fetch cases updated after this timestamp.
  ///   - oid: Organization ID.
  ///   - completion: Completion handler with nextPageToken, items, and error.
  private func syncCasesForPage(
    token: String?,
    updatedAt: String?,
    oid: String,
    completion: @escaping (_ nextPageToken: String?, _ items: [CaseElement], _ error: Error?) -> Void
  ) {
    casesService.fetchCasesList(
      token: token,
      updatedAt: updatedAt,
      oid: oid
    ) { result, metaData in
      switch result {
      case .success(let response):
        let casesItems = response.cases
        let nextPageToken = response.nextToken
        completion(nextPageToken, casesItems, nil)
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Error in fetching Cases -> \(error.localizedDescription)")
        completion(nil, [], error)
      }
    }
  }
}

