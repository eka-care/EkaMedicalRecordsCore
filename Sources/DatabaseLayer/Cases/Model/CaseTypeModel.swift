//
//  CaseType.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//

extension CaseType {
  func update(from caseTypeModel: CaseTypeModel) {
    self.name = caseTypeModel.name
    self.icon = caseTypeModel.icon
    self.backgroundColor = caseTypeModel.backgroundColor
  }
}
