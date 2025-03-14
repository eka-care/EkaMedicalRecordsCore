//
//  DocUpdateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 05/02/25.
//

struct DocUpdateRequest: Codable {
  let oid, documentType, documentDate: String?
  
  enum CodingKeys: String, CodingKey {
    case oid
    case documentType = "dt"
    case documentDate = "dd"
  }
}
