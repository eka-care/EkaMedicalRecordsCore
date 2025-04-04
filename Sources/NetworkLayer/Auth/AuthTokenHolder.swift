//
//  AuthTokenHolder.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

/**
 This class holds auth token and refresh token until app is running.
 This is set on app launch and removed on app termination.
 */

final class AuthTokenHolder {
  
  // MARK: - Properties
  
  static let shared = AuthTokenHolder()
  var authToken: String?
  var refreshToken: String?
  
  // MARK: - Init
  
  private init() {}
}
