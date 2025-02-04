//
//  RecordsRepo+NetworkHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 24/01/25.
//

import SwiftProtoContracts

// MARK: - Network Call Helper functions

// Syncing
extension RecordsRepo {
  /// Used to make network call to get items in a given page
  func syncRecordsForPage(
    token: String?,
    updatedAt: String?,
    oid: String?,
    completion: @escaping ((String?), [Vault_Records_Record]) -> Void
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
        guard let responseType = response.result else { return }
        switch responseType {
        case .response(let recordsResponse):
          let recordsItems = fetchRecordsFromItems(items: recordsResponse.items)
          let nextPageToken = recordsResponse.hasNextPageToken ? recordsResponse.nextPageToken : nil
          completion(nextPageToken, recordsItems)
        case .error(let error):
          debugPrint("Error in fetching records with message \(error.message)")
        }
      case .failure(let error):
        debugPrint("Error in fetching records -> \(error.localizedDescription)")
      }
    }
  }
  
  /// Used to fetch records and map them into array from all item types array
  /// Vault_Records_Item can be of any type Eg: Lab Nudge or a Google ad
  func fetchRecordsFromItems(items: [Vault_Records_Item]) -> [Vault_Records_Record] {
    var records: [Vault_Records_Record] = []
    items.forEach { item in
      switch item.result {
      case .record(let record):
        records.append(record)
      case .none:
        debugPrint("Different item type received")
      }
    }
    return records
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
