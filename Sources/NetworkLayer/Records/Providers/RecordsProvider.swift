//
//  RecordsProvider.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

protocol RecordsProvider {
  var networkService: Networking { get }
  
  /// fetch records
  func fetchRecords(
    token: String?,
    updatedAt: String?,
    oid: String?,
    _ completion: @escaping (Result<DocsListFetchResponse, Error>, Int?) -> Void
  )
  
  /// Upload records v3
  func uploadRecords(
    uploadRequest request: DocUploadRequest,
    oid: String?,
    _ completion: @escaping (Result<DocUploadFormsResponse, MRError>, Int?) -> Void
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
    oid: String?,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
  
  /// fetch document details
  func fetchDocDetails(
    documentId id: String,
    oid: String,
    _ completion: @escaping (Result<DocFetchResponse, Error>, Int?) -> Void
  )
  
  /// edit document details
  func editDocumentDetails(
    documentId id: String,
    filterOID: String?,
    request: DocUpdateRequest,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
  
  func sendSourceRefreshRequest(
    oid: String,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  )
}

extension RecordsProvider {
  /// fetch records
  func fetchRecords(
    token: String?,
    updatedAt: String?,
    oid: String?,
    _ completion: @escaping (Result<DocsListFetchResponse, Error>, Int?) -> Void
  ) {
    networkService
      .execute(
        RecordsEndpoint.fetchRecords(
          token: token,
          updatedAt: updatedAt,
          oid: oid
        ),
        completion: completion
      )
  }
  
  /// Upload Records v3
  func uploadRecords(
    uploadRequest request: DocUploadRequest,
    oid: String?,
    _ completion: @escaping (Result<DocUploadFormsResponse, MRError>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.uploadRecords(request: request, oid: oid), completion: completion)
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
    oid: String?,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.delete(documentId: documentId, oid: oid), completion: completion)
  }
  
  /// fetch document details
  func fetchDocDetails(
    documentId id: String,
    oid: String,
    _ completion: @escaping (Result<DocFetchResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(RecordsEndpoint.fetchDocDetails(documentID: id, oid: oid), completion: completion)
  }
  
  /// edit document details
  func editDocumentDetails(
    documentId id: String,
    filterOID: String?,
    request: DocUpdateRequest,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(
      RecordsEndpoint.editDocDetails(documentID: id, filterOID: filterOID, request: request),
      completion: completion
    )
  }
  
  func sendSourceRefreshRequest(
    oid: String,
    _ completion: @escaping (Result<Bool, Error>, Int?) -> Void
  ) {
    networkService.execute(
      RecordsEndpoint.refreshSourceRequest(oid: oid),
      completion: completion
    )
  }
}
