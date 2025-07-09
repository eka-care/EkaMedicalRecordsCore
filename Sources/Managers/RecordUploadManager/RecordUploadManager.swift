//
//  RecordUploadManager.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

import Foundation

final class RecordUploadManager {
  let service: RecordsProvider = RecordsApiService()
  typealias RecordUploadCompletion = (DocUploadFormsResponse?, RecordUploadErrorType?) -> Void
  
  /// Upload Records to Vault
  /// - Parameters:
  ///   - nestedFiles: Nested Files within Each document
  ///   - tags: User identifying tag
  ///   - recordType: Document type Eg: "PRESCRIPTION"
  ///   - documentDate: Document date
  ///   - recordUploadCompletion: Completion Block providing submit file status, document IDs, error
  func uploadRecordsToVault(
    nestedFiles: [DocumentMetaData],
    tags: [String]?,
    recordType: String?,
    documentDate: Int?,
    isLinkedWithAbha: Bool? = nil,
    recordUploadCompletion: @escaping RecordUploadCompletion
  ) {
    var documentIDs = [String]()
    
    /// Making Batch Request
    let batchRequests: [DocUploadRequest.BatchRequest] = createBatchRequest(
      nestedFiles: nestedFiles,
      tags: tags,
      recordType: recordType,
      documentDate: documentDate,
      isLinkedWithAbha: isLinkedWithAbha
    )
    
    /// Check if the record Data is Received Properly
    let filesData = fetchRecordsDataFromURL(nestedFiles)
    let recordDataReceivedCount: Int? = filesData.count
    guard recordDataReceivedCount == nestedFiles.count else {
      debugPrint("Count of file data does not match with count of files to be uploaded")
      recordUploadCompletion(nil, nil)
      return
    }
    
    /// Create Upload Request
    let request = DocUploadRequest(batchRequest: batchRequests)
    debugPrint("DocUploadRequestV3 - \(request)")
    
    /// Network Call
    service.uploadRecords(uploadRequest: request, oid: request.batchRequest.first?.patientOID) { [weak self] result, statusCode in
      
      guard let self else { return }
      
      switch result {
      case .success(let response):
        debugPrint("Received DocUploadFormsResponse - \(response)")
        
        guard let batchResponses = response.batchResponses, !batchResponses.isEmpty else {
          debugPrint("Received empty or nil BatchResponse")
          recordUploadCompletion(nil, nil)
          return
        }
        
        let group = DispatchGroup()
        
        /// Here we have urls and document ids in batches from response
        /// Now we have to start submitting files on to these urls
        /// Start submitting files concurrently
        for (batchResponseIndex, response) in batchResponses.enumerated() {
          
          guard let forms = response.forms else {
            debugPrint("Didn't receive form data in the BatchResponse \(response)")
            continue
          }
          
          for (formIndex, form) in forms.enumerated() {
            
            group.enter()
            
            self.submitFile(
              file: filesData[formIndex],
              fileName: nestedFiles[formIndex].name,
              mimeType: nestedFiles[formIndex].type,
              form: form
            ) { success, error in
              
              group.leave()
              
              if !success {
                debugPrint("❌ 📁 Failed to submit file - \(nestedFiles[batchResponseIndex].name) \(error?.localizedDescription ?? "")")
                recordUploadCompletion(nil, .failedToUploadFiles)
                return
              } else {
                debugPrint("Submitted file - \(nestedFiles[batchResponseIndex].name)")
                if let documentID = response.documentID {
                  if !documentIDs.contains(documentID) {
                    documentIDs.append(documentID)
                  }
                }
              }
            }
          }
        }
        
        group.notify(queue: .main) {
          recordUploadCompletion(response, nil)
        }
        
      case .failure(let error):
        debugPrint("❌ 📁 Failed to upload files - \(error.localizedDescription)")
        recordUploadCompletion(nil, .failedToUploadFiles)
      }
    }
  }
  
  // MARK: - Submitting file
  private func submitFile(
    file: Data,
    fileName: String,
    mimeType: EkaFileMimeType,
    form: DocUploadFormsResponse.Form,
    completion: @escaping ((Bool, Error?) -> Void)) {
      guard let urlString = form.url,
            let formFields = form.fields else {
        completion(false, nil)
        return
      }
      
      service.submitDocuments(file: file, fileName: fileName, mimeType: mimeType, urlString: urlString, formFields: formFields) { result, statusCode in
        switch result {
        case .success:
          completion(true, nil)
        case .failure(let error):
          completion(false, error)
        }
      }
    }
  
  // MARK: - Document Meta Data
  static func formDocumentsMetaData(
    recordsPath: [String],
    contentType: String
  ) -> [DocumentMetaData]? {
    
    var filesMetaData: [DocumentMetaData] = []
    
    for path in recordsPath {
      let fileUrl = FileHelper.getDocumentDirectoryURL().appendingPathComponent(path)
      let fileSize = FileHelper.getFileSizeInBytes(from: fileUrl)
      let fileObject = DocumentMetaData(
        name: path,
        size: fileSize,
        url: fileUrl,
        type: FileHelper.updateFileMimeType(fileExtension: contentType)
      )
      filesMetaData.append(fileObject)
    }
    
    return filesMetaData
  }
  
  func fetchRecordsDataFromURL(_ files: [DocumentMetaData]) -> [Data] {
    var recordsData: [Data] = []
    
    for encryptedFile in files {
      do {
        let data = try Data(contentsOf: encryptedFile.url)
        recordsData.append(data)
      } catch {
        debugPrint("Failed to retrieve raw file data for file \(encryptedFile) \(error)")
      }
    }
    
    return recordsData
  }
  
  // MARK: - Create Batch Request
  private func createBatchRequest(
    nestedFiles: [DocumentMetaData],
    tags: [String]?,
    recordType: String?,
    documentDate: Int?,
    isLinkedWithAbha: Bool?
  ) -> [DocUploadRequest.BatchRequest] {
    var batchRequests: [DocUploadRequest.BatchRequest] = []
    var filesMetaData: [DocUploadRequest.FileMetaData] = []
    
    nestedFiles.forEach {
      filesMetaData.append(
        DocUploadRequest.FileMetaData(
          contentType: $0.type.rawValue,
          fileSize: $0.size
        )
      )
    }

    let batchRequest = DocUploadRequest.BatchRequest(
      documentType: recordType,
      documentDate: documentDate,
      patientOID: CoreInitConfigurations.shared.primaryFilterID,
      tags: tags,
      files: filesMetaData
    )
    
    batchRequests.append(batchRequest)
    
    return batchRequests
  }
}
