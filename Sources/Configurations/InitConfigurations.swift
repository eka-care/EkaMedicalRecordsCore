//
//  InitConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 06/01/25.
//

protocol EkaMedicalRecordsDelegate: AnyObject {}

class InitConfigurations {
  
  // MARK: - Properties
  
  static let shared = InitConfigurations()
  
  var authToken: String? {
    didSet {
      AuthTokenHolder.shared.authToken = authToken
    }
  }
  var refreshToken: String? {
    didSet {
      AuthTokenHolder.shared.refreshToken = refreshToken
    }
  }
  weak var delegate: EkaMedicalRecordsDelegate?
  
  // MARK: - Init
  
  private init() {}
}
