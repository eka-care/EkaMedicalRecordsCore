//
//  CaseType.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//

import Foundation

extension CaseType {
  func update(from caseTypeModel: CaseTypeModel) {
    self.name = caseTypeModel.name
  }
}
