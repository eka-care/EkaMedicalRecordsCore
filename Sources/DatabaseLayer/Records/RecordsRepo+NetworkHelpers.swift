//
//  RecordsRepo+NetworkHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 24/01/25.
//

import Foundation

// MARK: - Network Call Helper functions

// Syncing
extension RecordsRepo {
  /// Used to make network call to get items in a given page
  func syncRecordsForPage(
    token: String?,
    updatedAt: String?,
    oid: String?,
    completion: @escaping (_ nextPageToken: String?,_ lastSourceRefreshedAt: Int? ,_ items: [RecordItemElement], _ error: Error?) -> Void
  ) {
    service.fetchRecords(
      token: token,
      updatedAt: updatedAt,
      oid: oid
    ) { [weak self] result, metaData in
      guard self != nil else { return }
      switch result {
      case .success(let response):
        let recordsItems = response.items
        let nextPageToken = response.nextToken
        let sourceRefreshedAt = response.sourceRefreshedAt
        completion(nextPageToken, sourceRefreshedAt ,recordsItems, nil)
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Error in fetching records -> \(error.localizedDescription)")
        completion(nil,nil ,[], error)
      }
    }
  }
}

// Upload
extension RecordsRepo {
  /// Upload Record to V3
  /// - Parameters:
  ///   - tags: tags for documents Eg: - kidney, blood test etc
  ///   - recordType: Record Type Eg: Lab Test, Prescription, Insurance etc
  ///   - recordURLs: URLs of the documents to be saved
  ///   - documentDate: Document for the record
  ///   - contentType: Extension type of file Eg: .jpeg, .pdf
  ///   - completion: Returns docUploadResponse and Record Upload Error
  public func uploadRecordsV3(
    documentID: String,
    tags: [String]? = nil,
    recordType: String? = nil,
    recordURLs: [String]?,
    documentDate: Int? = nil,
    contentType: String,
    isLinkedWithAbha: Bool? = false,
    userOid: String? = nil,
    linkedCases: [String]? = nil,
    completion: @escaping (DocUploadFormsResponse?, RecordUploadErrorType?) -> Void
  ) {
    guard let recordURLs,
          let documentsMetaData = RecordUploadManager.formDocumentsMetaData(recordsPath: recordURLs, contentType: contentType) else { return }
    
    uploadManager.uploadRecordsToVault(
      documentID: documentID,
      nestedFiles: documentsMetaData,
      tags: tags,
      recordType: recordType,
      documentDate: documentDate,
      linkedCases: linkedCases,
      isLinkedWithAbha: isLinkedWithAbha,
      userOid: userOid
    ) { [weak self] response,error in
      guard let self else { return }
      if let error {
        createRecordEvent(
          id: documentID,
          status: .failure,
          message: error.errorDescription,
          userOid: userOid ?? ""
        )
        completion(response, error)
        return
      }
      if let response {
        createRecordEvent(
          id: documentID,
          status: .success,
          userOid: userOid ?? ""
        )
        completion(response, error)
      }
    }
  }
}

// Delete

extension RecordsRepo {
  /// Delete record from v3 network
  /// - Parameters:
  ///   - documentID: documentID of the document to be deleted
  ///   - oid: organization ID
  ///   - completion: completion handler with success status and status code
  func deleteRecordV3(
    documentID: String?,
    oid: String?,
    completion: @escaping (Bool, Int?) -> Void = { _, _ in }
  ) {
    guard let documentID else { 
      completion(false, nil)
      return 
    }
    service.delete(
      documentId: documentID,
      oid: oid
    ) { [weak self] result, statusCode in
      guard let self else { 
        completion(false, statusCode)
        return 
      }
      switch result {
      case .success:
        deleteRecordEvent(
          id: documentID,
          status: .success,
          userOid: oid ?? ""
        )
        EkaMedicalRecordsCoreLogger.capture("Record deleted successfully from v3")
        completion(true, statusCode)
      case .failure(let error):
        deleteRecordEvent(
          id: documentID,
          status: .failure,
          message: error.localizedDescription,
          userOid: oid ?? ""
        )
        EkaMedicalRecordsCoreLogger.capture("Failed to delete record \(error.localizedDescription)")
        completion(false, statusCode)
      }
    }
  }
}

// File Details

extension RecordsRepo {
  func fetchFileDetails(
    oid: String?,
    documentID: String?,
    completion: @escaping (DocFetchResponse) -> Void
  ) {
    guard let documentID,
          let oid else { return }
    service.fetchDocDetails(
      documentId: documentID,
      oid: oid
    ) { result, statusCode in
      switch result {
      case .success(let response):
        completion(response)
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Error in fetching file details \(error.localizedDescription)")
      }
    }
  }
  
  /// Fetches document uris from the network uris
  func fetchDocumentURIs(
    files: [File]?,
    completion: @escaping ([String]) -> Void
  ) {
    guard let files else { return }
    var documentURIs: [String] = []
    let dispatchGroup = DispatchGroup()
    for file in files {
      guard let urlString = file.assetURL,
            let url = URL(string: urlString),
            let fileType = file.fileType,
            let recordType = FileType(rawValue: fileType) else { continue }
      dispatchGroup.enter()
      /// Get the local directory for the url
      getLocalDirectoryFileNameForDocument(url: url, recordType: recordType) { localURL in
        if let localURL {
          documentURIs.append(localURL)
        }
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      completion(documentURIs)
    }
  }
  
  /// Fetch local directory url for single document
  func getLocalDirectoryFileNameForDocument(
    url: URL,
    recordType: FileType,
    completion: @escaping (String?) -> Void
  ) {
    /// Download data from the network url
    FileHelper.downloadData(from: url) { data, error in
      if let data {
        /// Write the data to local document directory and get the local path url
        let documentFileName = FileHelper.writeDataToDocumentDirectoryAndGetFileName(data, fileExtension: recordType.fileExtension)
        completion(documentFileName)
      }
    }
  }
}

// Update

extension RecordsRepo {
  func editDocument(
    documentID: String?,
    documentDate: Date? = nil,
    documentType: String? = nil,
    documentFilterId: String? = nil,
    linkedCases: [String]? = nil,
    tags: [String]? = nil,
    completion: @escaping (Bool) -> Void
  ) {
    guard let documentID,
          let documentFilterId else {
      EkaMedicalRecordsCoreLogger.capture("Document ID not found while editing record")
      return
    }
    /// Set document type - use the documentType string directly
    /// Form request
    let request = DocUpdateRequest(
      oid: documentFilterId,
      documentType: documentType,
      documentDate: documentDate?.toEpochInt(),
      cases: linkedCases,
      tags: tags
    )
    service.editDocumentDetails(
      documentId: documentID,
      filterOID: documentFilterId,
      request: request
    ) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success:
        EkaMedicalRecordsCoreLogger.capture("Updated document")
        updateRecordEvent(id: documentID, status: .success, userOid: documentFilterId)
        completion(true)
      case .failure(let error):
        EkaMedicalRecordsCoreLogger.capture("Failure in document update network call \(error.localizedDescription)")
        updateRecordEvent(id: documentID, status: .failure, message: error.localizedDescription, userOid: documentFilterId)
        completion(false)
      }
    }
  }
}
