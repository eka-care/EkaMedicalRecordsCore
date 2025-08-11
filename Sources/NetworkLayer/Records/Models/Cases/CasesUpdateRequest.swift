//
//  CasesUpdateRequest.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//




import Foundation

/// Path Parameters will be Unique case ID
struct CasesUpdateRequest: Codable {
    let displayName: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case type
    }
}
