//
//  CasesCreateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Foundation

struct CasesCreateRequest: Codable {
    let id, displayName: String
    let hiType: String?
    let occurredAt: Int
    let type: String?
    let partnerMeta: PartnerMeta? 

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case hiType = "hi_type"
        case occurredAt = "occurred_at"
        case type
        case partnerMeta = "partner_meta"
    }
}

// MARK: - PartnerMeta
struct PartnerMeta: Codable {
    let facilityID, uhid: String

    enum CodingKeys: String, CodingKey {
        case facilityID = "facility_id"
        case uhid
    }
}
