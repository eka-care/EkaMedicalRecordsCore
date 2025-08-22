//
//  CasesListFetchResponse.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//


import Foundation

// MARK: - Status Enum
public enum CaseStatus: String, Codable {
    case active = "A"
    case deleted = "D"
}

// MARK: - CasesList
struct CasesListFetchResponse: Codable {
    let cases: [CaseElement]
    let nextToken: String?
    enum CodingKeys: String, CodingKey {
        case cases
        case nextToken = "next_token"
    }
}

// MARK: - Case
struct CaseElement: Codable {
    let id: String
    let status: CaseStatus?
    let updatedAt: Int?
    let item: Item?

    enum CodingKeys: String, CodingKey {
        case id, status
        case updatedAt = "updated_at"
        case item
    }
}

// MARK: - Item
struct Item: Codable {
  let displayName, type, hiType: String?
  let partnerMeta: PartnerMeta?
  let createdAt: Int?

  enum CodingKeys: String, CodingKey {
      case displayName = "display_name"
      case type
      case hiType = "hi_type"
      case partnerMeta = "partner_meta"
      case createdAt = "created_at"
  }
}
