//
//  UserDefaultsHelper.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 06/01/25.
//

import Foundation

final class UserDefaultsHelper {
  
  /// Use this generic func to encode and save an Codable object to UserDefaults
  /// - Parameters:
  ///   - value: Any Codable type
  ///   - key: The corresponding key
  /// - Returns: true if it is saved successfully, else false
  @discardableResult
  static func save<T: Codable>(customValue value: T, withKey key: String) -> Bool {
    if let encoded = try? JSONEncoder().encode(value) {
      let defaults = UserDefaults.standard
      defaults.set(encoded, forKey: key)
      return true
    }
    return false
  }
  
  /// Use this generic func to fetch and decode a Codable object from UserDefaults
  /// - Parameters:
  ///   - type: Any Codable type
  ///   - key: The key used to look-up the object
  /// - Returns: An optional object of any Codable type
  static func fetch<T: Codable>(valueOfType type: T.Type, usingKey key: String) -> T? {
    if let savedValue = UserDefaults.standard.object(forKey: key) as? Data {
      if let loadedValue = try? JSONDecoder().decode(T.self, from: savedValue) {
        return loadedValue
      }
    }
    return nil
  }
  
}
