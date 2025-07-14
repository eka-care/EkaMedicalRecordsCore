//
//  RefreshRequest.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

struct RefreshRequest: Codable {
  let refresh: String
  let sess: String
  
  enum CodingKeys: String, CodingKey {
    case refresh = "refresh_token"
    case sess = "access_token"
  }
}
