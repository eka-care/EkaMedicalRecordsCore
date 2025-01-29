//
//  InitConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 06/01/25.
//

public protocol EkaMedicalRecordsDelegate: AnyObject {}

public class InitConfigurations {
  
  // MARK: - Properties
  
  public static let shared = InitConfigurations()
  
  /// Auth token for backend layer
  public var authToken: String? {
    didSet {
      AuthTokenHolder.shared.authToken = authToken
    }
  }
  
  /// Refresh token for backend layer
  public var refreshToken: String? {
    didSet {
      AuthTokenHolder.shared.refreshToken = refreshToken
    }
  }
  
  public var filterOID: String?
  public weak var delegate: EkaMedicalRecordsDelegate?
  
  // MARK: - Init
  
  private init() {}
}
