//
//  CasesCreateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Foundation

struct CasesCreateRequest: Codable {
  let id, displayName, type: String
  let occurredAt: Int
  
  enum CodingKeys: String, CodingKey {
    case id
    case displayName = "display_name"
    case type
    case occurredAt = "occurred_at"
  }
}
