//
//  RecordsRepo+NetworkHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 24/01/25.
//

import SwiftProtoContracts
import Foundation

// MARK: - Network Call Helper functions

// Syncing
extension RecordsRepo {
  /// Used to make network call to get items in a given page
  func syncRecordsForPage(
    token: String?,
    updatedAt: String?,
    oid: String?,
    completion: @escaping ((String?), [RecordItemElement]) -> Void
  ) {
    service.fetchRecords(
      token: token,
      updatedAt: updatedAt,
      oid: oid
    ) { [weak self] result, metaData in
      guard let self else { return }
      switch result {
      case .success(let response):
//        /// Store the epoch in var first, update the UserDefaults ony once the last page is reached
//        recordsUpdateEpoch = metaData.allHeaders?["Eka-Uat"]
        
        let recordsItems = response.items
        let nextPageToken = response.nextToken
        completion(nextPageToken, recordsItems)
      case .failure(let error):
        debugPrint("Error in fetching records -> \(error.localizedDescription)")
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
  func uploadRecordsV3(
    tags: [String]? = nil,
    recordType: String? = nil,
    recordURLs: [String]?,
    documentDate: String? = nil,
    contentType: String,
    isLinkedWithAbha: Bool? = false,
    completion: @escaping (DocUploadFormsResponse?, RecordUploadErrorType?) -> Void
  ) {
    guard let recordURLs,
          let documentsMetaData = RecordUploadManager.formDocumentsMetaData(recordsPath: recordURLs, contentType: contentType) else { return }
    
    uploadManager.uploadRecordsToVault(
      nestedFiles: documentsMetaData,
      tags: tags,
      recordType: recordType,
      documentDate: documentDate,
      isLinkedWithAbha: isLinkedWithAbha
    ) { response, error in
      if let error {
        completion(nil, error)
        return
      }
      if let response {
        completion(response, error)
      }
    }
  }
}

// Delete

extension RecordsRepo {
  /// Delete record from v3 network
  /// - Parameter documentID: documentID of the document to be deleted
  func deleteRecordV3(
    documentID: String?
  ) {
    guard let documentID else { return }
    service.delete(
      documentId: documentID,
      oid: CoreInitConfigurations.shared.filterID
    ) { result, statusCode in
      switch result {
      case .success:
        debugPrint("Record deleted successfully from v3")
      case .failure(let error):
        debugPrint("Failed to delete record \(error.localizedDescription)")
      }
    }
  }
}

// File Details

extension RecordsRepo {
  func fetchFileDetails(
    documentID: String?,
    completion: @escaping (DocFetchResponse) -> Void
  ) {
    guard let documentID,
          let filterID = CoreInitConfigurations.shared.filterID else { return }
    service.fetchDocDetails(
      documentId: documentID,
      oid: filterID
    ) { result, statusCode in
      switch result {
      case .success(let response):
        completion(response)
      case .failure(let error):
        debugPrint("Error in fetching file details \(error.localizedDescription)")
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
    documentType: Int? = nil
  ) {
    guard let documentID,
    let filterID = CoreInitConfigurations.shared.filterID  else {
      debugPrint("Document ID not found while editing record")
      return
    }
    /// Set document type
    let vaultRecordDocumentType = documentType.flatMap { Vault_Records_DocumentType(rawValue: $0) }
    /// Form request
    let request = DocUpdateRequest(
      oid: filterID,
      documentType: vaultRecordDocumentType?.shortHand,
      documentDate: documentDate?.toUSEnglishString(withFormat: "dd-MM-yyyy") ?? ""
    )
    service.editDocumentDetails(
      documentId: documentID,
      filterOID: filterID,
      request: request) { result, statusCode in
        switch result {
        case .success:
          debugPrint("Updated document")
        case .failure(let error):
          debugPrint("Failure in document update network call \(error.localizedDescription)")
        }
      }
  }
}
