//
//  RecordsProvider.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import SwiftProtoContracts

protocol RecordsProvider {
  var networkService: Networking { get }
  
  /// fetch records
  func fetchRecords(
    token: String?,
    updatedAt: String?,
    _ completion: @escaping (Result<Vault_Records_RecordsAPIResponse, ProtoError>, RequestMetadata) -> Void
  )
}

extension RecordsProvider {
  /// fetch records
  func fetchRecords(
    token: String?,
    updatedAt: String?,
    _ completion: @escaping (Result<Vault_Records_RecordsAPIResponse, ProtoError>, RequestMetadata) -> Void
  ) {
    networkService.executeProto(
      RecordsEndpoint.fetchRecords(
        token: token,
        updatedAt: updatedAt
      ),
      completion: completion
    )
  }
}
