//
//  RecordUploadErrorType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

enum RecordUploadErrorType {
  case failedToUploadFiles
  
  var errorDescription: String {
    switch self {
    case .failedToUploadFiles:
      return "Failed to Upload Files"
    }
  }
}
