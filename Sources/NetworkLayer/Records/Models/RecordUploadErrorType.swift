//
//  RecordUploadErrorType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

public enum RecordUploadErrorType: Equatable {
  case failedToUploadFiles
  case emptyFormResponse
  case recordCountMetaDataMismatch
  case uploadLimitReached
  case duplicateDocumentUpload
  case unknown(message: String, statusCode: Int)
  
  var errorDescription: String {
    switch self {
    case .failedToUploadFiles:
      return "Failed to Upload Files"
    case .emptyFormResponse:
      return "Empty form response"
    case .recordCountMetaDataMismatch:
      return "Record Count meta data mismatch"
    case .uploadLimitReached:
      return "Upload limit has been exceeded"
    case .duplicateDocumentUpload:
      return "Document already uploaded"
    case .unknown(let message, let code):
      return "(Status Code: \(code)) Error: \(message)"
    }
  }
  
  var isUploadLimitReached: Bool {
    self == .uploadLimitReached
  }
  
  var isDocumentAlreadyUploaded: Bool {
    self == .duplicateDocumentUpload
  }
  
  var isEmptyFormResponse: Bool {
    self == .emptyFormResponse
  }
  
  var isfailedToUploadFiles: Bool {
    self == .failedToUploadFiles
  }
  
  var code: String {
    switch self {
    case .uploadLimitReached:
      return "STORAGE_LIMIT_EXCEEDED"
    default:
      return ""
    }
  }
}
