//
//  DomainConfigurations.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

public enum DomainConfigurations {
  public enum Environment {
    case release
    case development
  }
  
  public static var environment: Environment = .release
  
  public static var apiURL: String {
    switch environment {
    case .release:
      return "https://api.eka.care"
    case .development:
      return "https://api.dev.eka.care"
    }
  }
  
  public static var vaultURL: String {
    switch environment {
    case .release:
      return "https://vault.eka.care"
    case .development:
      return "https://vault.dev.eka.care"
    }
  }
  
  public static var ekaURL: String {
    switch environment {
    case .release:
      return "https://api.eka.care"
    case .development:
      return "https://api.dev.eka.care"
    }
  }
}
