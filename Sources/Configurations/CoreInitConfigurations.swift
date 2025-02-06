//
//  InitConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 06/01/25.
//

public class CoreInitConfigurations {
  
  // MARK: - Properties
  
  public static let shared = CoreInitConfigurations()
  
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
  
  /// Filter ID for records
  public var filterID: String?
  
  /// Owner ID for records
  public var ownerID: String?
  
  /// Owner name for records
  public var ownerName: String?
  
  // MARK: - Init
  
  private init() {}
}
