//
//  CaseDatabaseAdapter.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 17/07/25.
//

import Foundation

/**
 This file is an adapter for the database layer. It handles any model conversion from network to database layer and vice versa.
 */

/// Model used for case insert
public struct CaseArguementModel {
  public var caseId: String? /// Id of the case
  public var caseType: String? /// Type of the case
  public var oid: String? /// Oid attached to the case
  public var createdAt: Date? /// Created at of the case
  public var name: String? /// Name of the case
  public var updatedAt: Date? /// Updated at of the case
  public var userDate: Date? /// Date of the folder added by user
  public var isRemoteCreated: Bool?
  public var isEdited: Bool?
  public var status: CaseStatus?
  
  public init(
    caseId: String? = nil,
    caseType: String? = nil,
    oid: String? = nil,
    createdAt: Date? = nil,
    name: String? = nil,
    updatedAt: Date? = nil,
    userDate: Date? = nil,
    isRemoteCreated: Bool = false,
    isEdited: Bool = false,
    status: CaseStatus? = nil
  ) {
    self.caseId = caseId
    self.caseType = caseType
    self.oid = oid
    self.createdAt = createdAt
    self.name = name
    self.updatedAt = updatedAt
    self.userDate = userDate
    self.isRemoteCreated = isRemoteCreated
    self.isEdited = isEdited
    self.status = status
  }
}
