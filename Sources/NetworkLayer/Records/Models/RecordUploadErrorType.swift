//
//  RecordUploadErrorType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

enum RecordUploadErrorType {
  case failedToUploadFiles
  case emptyFormResponse
  case recordCountMetaDataMismatch
  
  var errorDescription: String {
    switch self {
    case .failedToUploadFiles:
      return "Failed to Upload Files"
    case .emptyFormResponse:
      return "Empty form response"
    case .recordCountMetaDataMismatch:
      return "Record Count meta data mismatch"
    }
  }
}
