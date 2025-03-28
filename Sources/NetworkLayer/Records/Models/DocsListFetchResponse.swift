//
//  DocsListFetchResponse.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

import Foundation

// MARK: - Welcome
struct DocsListFetchResponse: Codable {
  let items: [RecordItemElement]
  let nextToken: String?
  
  enum CodingKeys: String, CodingKey {
    case items
    case nextToken = "next_token"
  }
}

// MARK: - ItemElement
struct RecordItemElement: Codable {
  let recordDocument: RecordDocument
  
  enum CodingKeys: String, CodingKey {
    case recordDocument = "record"
  }
}

// MARK: - Record
struct RecordDocument: Codable {
  let item: RecordItem
}

// MARK: - RecordItem
struct RecordItem: Codable {
  let documentID: String?
  let uploadDate: Int?
  let documentType: String?
  let metadata: Metadata?
  let patientID: String?
  
  enum CodingKeys: String, CodingKey {
    case documentID = "document_id"
    case uploadDate = "upload_date"
    case documentType = "document_type"
    case metadata
    case patientID = "patient_id"
  }
}

// MARK: - Metadata
struct Metadata: Codable {
  let thumbnail: String?
  let documentDate: Int?
  let tags: [String]?
  let title: String?
  let abha: Abha?
  
  enum CodingKeys: String, CodingKey {
    case thumbnail
    case documentDate = "document_date"
    case tags, title, abha
  }
}

// MARK: - Abha
struct Abha: Codable {
  let healthID, linkStatus: String?
  
  enum CodingKeys: String, CodingKey {
    case healthID = "health_id"
    case linkStatus = "link_status"
  }
}
