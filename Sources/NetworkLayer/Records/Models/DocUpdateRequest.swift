//
//  DocUpdateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 05/02/25.
//

struct DocUpdateRequest: Codable {
  let oid, documentType: String?
  let documentDate: Int?
  let cases: [String]?
  
  enum CodingKeys: String, CodingKey {
    case oid
    case documentType = "dt"
    case documentDate = "dd_e"
    case cases
  }
}
