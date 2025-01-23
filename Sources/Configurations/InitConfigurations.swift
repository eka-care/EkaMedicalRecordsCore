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
  
  public var authToken: String? {
    didSet {
      AuthTokenHolder.shared.authToken = authToken
    }
  }
  public var refreshToken: String? {
    didSet {
      AuthTokenHolder.shared.refreshToken = refreshToken
    }
  }
  public weak var delegate: EkaMedicalRecordsDelegate?
  
  // MARK: - Init
  
  private init() {}
}
