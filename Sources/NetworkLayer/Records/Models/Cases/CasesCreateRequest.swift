//
//  CasesCreateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Foundation

struct CasesCreateRequest: Codable {
    let id: String
    let displayName: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case type
    }
}
