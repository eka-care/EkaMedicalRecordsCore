//
//  RefreshResponse.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

// MARK: - RefreshResponse

struct RefreshResponse: Codable {
  let accessToken: String?
  let expiresIn, refreshExpiresIn: Int?
  let refreshToken: String?
  
  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
    case refreshExpiresIn = "refresh_expires_in"
    case refreshToken = "refresh_token"
  }
}
