//
//  Case.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 17/07/25.
//

import CoreData

extension CaseModel {
  func update(from caseArguementModel: CaseArguementModel) {
    if let caseId = caseArguementModel.caseId {
      self.caseID = caseId
    }
    
    if let caseName = caseArguementModel.name {
      self.caseName = caseName
    }
    
    if let caseType = caseArguementModel.caseType {
      self.caseType = caseType
    }
    
    if let updatedAt = caseArguementModel.updatedAt {
      self.updatedAt = updatedAt
    }
    
    if let createdAt = caseArguementModel.createdAt {
      self.createdAt = createdAt
    }
    
    if let oid = caseArguementModel.oid {
      self.oid = oid
    }
    
    if let userDate = caseArguementModel.userDate {
      self.userAddedDate = userDate
    }
  }
}
