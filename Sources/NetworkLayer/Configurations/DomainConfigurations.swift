//
//  DomainConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

public enum DomainConfigurations {
  public enum Environment {
    case production
    case development
  }
  
  public static var environment: Environment = .production
  
  public static var apiURL: String {
    switch environment {
    case .production:
      return "https://api.eka.care"
    case .development:
      return "https://api.dev.eka.care"
    }
  }
  
  public static var vaultURL: String {
    switch environment {
    case .production:
      return "https://vault.eka.care"
    case .development:
      return "https://vault.dev.eka.care"
    }
  }
  
  public static var ekaURL: String {
    switch environment {
    case .production:
      return "https://api.eka.care"
    case .development:
      return "https://api.dev.eka.care"
    }
  }
}
