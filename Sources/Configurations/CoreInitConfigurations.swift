//
//  InitConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 06/01/25.
//

import Alamofire

public enum MedicaRecordsFeatureRestriction: String {
  case uploadRecords = "UPLOAD_MEDICAL_RECORDS"
}

public class CoreInitConfigurations {
  
  public var blockedFeatures: [String] = []
  public var blockedFeatureTypes: [MedicaRecordsFeatureRestriction] {
    blockedFeatures.compactMap({ MedicaRecordsFeatureRestriction(rawValue: $0) })
  }
  
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
  /// Primary FilterId
  public var primaryFilterID: String?
    
  /// Filter ID for records
  public var filterID: [String]?
  
  /// Owner ID for records
  public var ownerID: String?
  
  /// Request Interceptor
  public var requestInterceptor: Alamofire.RequestInterceptor = NetworkRequestInterceptor()
  
  /// Delegate to get events
  public weak var delegate: EventLoggerProtocol?
  
  // MARK: - Init
  
  private init() {}
}
