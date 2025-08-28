//
//  DocUploadRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

import Foundation

// MARK: - Welcome
struct DocUploadRequest: Codable {
  let batchRequest: [BatchRequest]
  
  enum CodingKeys: String, CodingKey {
    case batchRequest = "batch_request"
  }
  
  
  // MARK: - BatchRequest
  struct BatchRequest: Codable {
    let documentType: String?
    let documentDate: Int?
    let patientOID: String?
    let documentID: String
    let cases: [String]?
    let tags: [String]?
    let files: [FileMetaData]?
    
    enum CodingKeys: String, CodingKey {
      case documentType = "dt"
      case documentDate = "dd_e"
      case cases
      case tags = "tg"
      case patientOID = "patient_oid"
      case files
      case documentID = "document_id"
    }
    
    init(
      documentID: String,
      documentType: String? = nil,
      documentDate: Int? = nil,
      patientOID: String? = nil,
      cases: [String]? = nil,
      tags: [String]? = nil,
      files: [DocUploadRequest.FileMetaData]? = nil
    ) {
      self.documentID = documentID
      self.documentType = documentType
      self.documentDate = documentDate
      self.patientOID = patientOID
      self.cases = cases
      self.tags = tags
      self.files = files
    }
  }
  
  // MARK: - File
  struct FileMetaData: Codable {
    let contentType: String?
    let fileSize: Int?
    
    enum CodingKeys: String, CodingKey {
      case contentType
      case fileSize = "file_size"
    }
  }
}
