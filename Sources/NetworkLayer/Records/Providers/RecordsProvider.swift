//
//  RecordsProvider.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import SwiftProtoContracts
import Foundation

protocol RecordsProvider {
  var networkService: Networking { get }
  
  /// fetch records
  func fetchRecords(
    token: String?,
    updatedAt: String?,
    _ completion: @escaping (Result<Vault_Records_RecordsAPIResponse, ProtoError>, RequestMetadata) -> Void
  )
  /// Upload records v3
  func uploadRecords(
    uploadRequest request: DocUploadRequest,
    _ completion: @escaping (Result<DocUploadFormsResponse, Error>, Int?) -> Void
  )
  /// submitting documents
  func submitDocuments(
    file: Data,
    fileName: String,
    mimeType: EkaFileMimeType,
    urlString: String,
    formFields: DocUploadFormsResponse.Fields,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
  /// delete file
  func delete(
    documentId: String,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
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
  
  /// Upload Records v3
  func uploadRecords(
    uploadRequest request: DocUploadRequest,
    _ completion: @escaping (Result<DocUploadFormsResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.uploadRecords(request: request), completion: completion)
  }
  
  /// Submitting documents
  func submitDocuments(
    file: Data,
    fileName: String,
    mimeType: EkaFileMimeType,
    urlString: String,
    formFields: DocUploadFormsResponse.Fields,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.submitDocuments(file: file, fileName: fileName, mimeType: mimeType, urlString: urlString, formFields: formFields), completion: completion)
  }
  
  /// delete file
  func delete(
    documentId: String,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.delete(documentId: documentId), completion: completion)
  }
}
