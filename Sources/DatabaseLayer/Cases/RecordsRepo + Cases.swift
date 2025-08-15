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
  public func addCase(
    caseArguementModel: CaseArguementModel
  ) {
    // Create the case locally first
    
    let createCase = databaseManager.createCase(from: caseArguementModel)
    
    // Attempt to create the case on the server
    createCaseOnServer(createCase: createCase) { [weak self] result in
      switch result {
      case .success(_):
        // API success - update the case with server response details
        let receivedFromServer = CaseArguementModel(
          caseId: createCase.caseID,
          updatedAt: Date(),
          isRemoteCreated: true
        )
        self?.databaseManager.updateCase(
          caseModel: createCase,
          caseArguementModel: receivedFromServer
        )
        
      case .failure(let error):
        // API failure - mark case as not synced
        debugPrint("Failed to create case on server: \(error.localizedDescription)")
        let failedSync = CaseArguementModel(
          caseId: createCase.caseID,
          isRemoteCreated: false
        )
        self?.databaseManager.updateCase(
          caseModel: createCase,
          caseArguementModel: failedSync
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
      debugPrint("Case ID is missing, skipping server deletion.")
      return
    }
    guard let oid = caseModel.oid else {
      debugPrint("Case OID is missing, skipping server deletion.")
      return
    }
    
    deleteCaseOnServer(caseId: caseId, oid: oid) { result in
      switch result {
      case .success:
        debugPrint("Case \(caseId) deleted successfully from server.")
      case .failure(let error):
        debugPrint("Failed to delete case \(caseId) from server: \(error.localizedDescription)")
      }
    }
    // Delete locally
    databaseManager.deleteCase(caseModel: caseModel)
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
      debugPrint("Case ID is missing. Cannot create case on server.")
      completion(.failure(NSError(domain: "CaseError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Case ID or OID is missing"])))
      return
    }
    
    guard let caseName = createCase.caseName, !caseName.isEmpty  else {
      debugPrint("Case name is missing. Cannot create case on server.")
      completion(.failure(NSError(domain: "CaseError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Case name is missing"])))
      return
    }
    
    guard let caseType = createCase.caseType, !caseType.isEmpty  else {
      debugPrint("Case type is missing. Cannot create case on server.")
      completion(.failure(NSError(domain: "CaseError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Case type is missing"])))
      return
    }
    
    let request = CasesCreateRequest(
      id: caseId,
      displayName: caseName,
      type: caseType,
      occurredAt: createCase.createdAt?.toEpochInt() ?? Date().toEpochInt()
    )
    
    casesServeice.createCases(oid: oid, request: request) { [weak self] result, statusCode in
      guard self != nil else { return }
      
      switch result {
      case .success(let caseDetails):
        debugPrint("Case successfully created on the server.")
        completion(.success(caseDetails))
        
      case .failure(let error):
        debugPrint("Failed to create case on server: \(error.localizedDescription)")
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
    casesServeice.delete(caseId: caseId, oid: oid) { [weak self] result, error in
      guard self != nil else { return }
      switch result {
      case .success:
        debugPrint("Case deleted successfully")
        completion(.success(true))
      case .failure(let error):
        debugPrint("Failed to delete Case: \(error.localizedDescription)")
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
      type: updateCase.caseType
    )
    
    casesServeice.updateCases(caseId: caseId, oid: oid, request: request) { [weak self] result, error in
      guard self != nil else { return }
      switch result {
      case .success:
        debugPrint("Case updated successfully")
        completion(.success(true))
      case .failure(let error):
        debugPrint("Failed to update Case: \(error.localizedDescription)")
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
        fetchCasesFromServer(oid: oid) { success in
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
    databaseManager.fetchCase(fetchRequest: QueryHelper.fetchLastCaseUpdatedAt(oid: oid), completion: { cases in
      completion(cases.first)
    })
  }
  
  /// Fetches cases from server for the given OID and updates the local database in batches.
  /// Handles pagination via nextPageToken.
  /// - Parameters:
  ///   - oid: Organization ID.
  ///   - completion: Completion handler called after all batches are added.
  public func fetchCasesFromServer(oid: String, completion: @escaping (Bool) -> Void) {
    var pageOffsetTokenCases: String?
    syncCasesForPage(
      token: pageOffsetTokenCases,
      updatedAt: casesUpdateEpoch,
      oid: oid
    ) { [weak self] nextPageToken, caseItems, error in
      guard let self else { 
        completion(false)
        return 
      }
      if error != nil {
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
          debugPrint("Batch added to database, count -> \(databaseInsertModels.count)")
          /// If it was last page means all batches are added to database, hence send completion
          if nextPageToken == nil {
            pageOffsetTokenCases = nil
            completion(true)
          }
        }
      }
      /// Call for next page if available
      if let nextPageToken {
        /// Update the page offset token
        pageOffsetTokenCases = nextPageToken
        /// Call for next page
        fetchCasesFromServer(oid: oid, completion: completion)
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
    casesServeice.fetchCasesList(
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
        debugPrint("Error in fetching Cases -> \(error.localizedDescription)")
        completion(nil, [], error)
      }
    }
  }
}
