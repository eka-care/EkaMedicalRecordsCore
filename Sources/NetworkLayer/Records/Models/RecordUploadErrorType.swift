//
//  RecordUploadErrorType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

public enum RecordUploadErrorType {
  case failedToUploadFiles
  case emptyFormResponse
  case recordCountMetaDataMismatch
  case uploadLimitReached
  case duplicateDocumentUpload
  
  var errorDescription: String {
    switch self {
    case .failedToUploadFiles:
      return "Failed to Upload Files"
    case .emptyFormResponse:
      return "Empty form response"
    case .recordCountMetaDataMismatch:
      return "Record Count meta data mismatch"
    case .uploadLimitReached:
      return "upload limit has been exceeded"
    case .duplicateDocumentUpload:
      return "Document already uploaded"
    }
  }
  
  var code: String {
    switch self {
    case .uploadLimitReached:
      return "STORAGE_LIMIT_EXCEEDED"
    default :
      return ""
    }
  }
}
