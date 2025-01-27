//
//  DocUploadRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

import Foundation

struct DocUploadRequest: Codable {
  let batchRequests: [BatchRequest]?
  
  enum CodingKeys: String, CodingKey {
    case batchRequests = "batch_request"
  }
  
  struct BatchRequest: Codable {
    let documentDate, documentType: String?
    let tags: [String]?
    let shareable: Bool?
    let fileContentTypes: [FileMetaData]?
    let patientOID: String?
    let saId: String?
    let isEncrypted: Bool?
    let isLinkedWithAbha: Bool?
    
    enum CodingKeys: String, CodingKey {
      case documentDate = "dd"
      case documentType = "dt"
      case tags = "tg"
      case shareable = "sh"
      case patientOID = "patient_oid"
      case fileContentTypes = "files"
      case saId = "sa_id"
      case isEncrypted = "is_encrypted"
      case isLinkedWithAbha = "ndhm"
    }
  }
  
  struct FileMetaData: Codable {
    let contentType: String?
    let fileSize: Int?
    
    enum CodingKeys: String, CodingKey {
      case contentType
      case fileSize = "file_size"
    }
  }
}
