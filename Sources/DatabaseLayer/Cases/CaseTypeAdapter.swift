//
//  CaseTypeAdapter.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//

import Foundation

/**
 This file is an adapter for the database layer. It handles any model conversion from network to database layer and vice versa.
 */

/// Model used for casetype insert
public struct CaseTypeModel {
  public var name: String
  public var icon: String
 
  public init(name: String, icon: String) {
    self.name = name
    self.icon = icon
  }
}
