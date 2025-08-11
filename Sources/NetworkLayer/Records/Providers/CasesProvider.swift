//
//  RecordsProvider 2.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Foundation

protocol CasesProvider {
  var networkService: Networking { get }
  
  /// Create a new case
  func createCases(
    oid: String?,
    request: CasesCreateRequest,
    _ completion: @escaping (Result<CasesCreateResponse, Error>, Int?) -> Void
  )
  
  /// Fetch list of cases
  func fetchCasesList(
    token: String?,
    updatedAt: String?,
    oid: String?,
    _ completion: @escaping (Result<CasesListFetchResponse, Error>, Int?) -> Void
  )
  
  /// Delete a case by ID
  func delete(
    caseId: String,
    oid: String?,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
  
  /// Update an existing case
  func updateCases(
    caseId: String,
    oid: String?,
    request: CasesUpdateRequest,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
}

extension CasesProvider {
  /// Create a new case
  func createCases(
    oid: String?,
    request: CasesCreateRequest,
    _ completion: @escaping (Result<CasesCreateResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(
      CasesEndpoint.createCases(oid: oid, request: request),
      completion: completion
    )
  }
  
  /// Fetch list of cases
  func fetchCasesList(
    token: String?,
    updatedAt: String?,
    oid: String?,
    _ completion: @escaping (Result<CasesListFetchResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(
      CasesEndpoint.fetchCasesList(
        token: token,
        updatedAt: updatedAt,
        oid: oid
      ),
      completion: completion
    )
  }
  
  /// Delete a case by ID
  func delete(
    caseId: String,
    oid: String?,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(
      CasesEndpoint.delete(caseId: caseId, oid: oid),
      completion: completion
    )
  }
  
  /// Update an existing case
  func updateCases(
    caseId: String,
    oid: String?,
    request: CasesUpdateRequest,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(
      CasesEndpoint.updateCases(caseId: caseId, oid: oid, request: request),
      completion: completion
    )
  }
}
