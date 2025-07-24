//
//  RecordsRepo + CaseType.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//



extension RecordsRepo {
  
  /// Used to add new casetype
  public func createCaseType (
    caseTypeModel: CaseTypeModel
  ) -> CaseType {
    return databaseManager.createCaseType(from: caseTypeModel)
  }
  
  ///  Used to fetch all casetypes
  public func fetchCaseTypes() -> [CaseType] {
      return databaseManager.fetchAllCases()
  }
}
