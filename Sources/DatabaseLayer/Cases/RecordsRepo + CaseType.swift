//
//  RecordsRepo + CaseType.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//

import CoreData

extension RecordsRepo {
  
  /// Used to add new casetype
  public func createCaseType (
    caseTypeModel: CaseTypeModel
  ) -> CaseType {
    return databaseManager.createCaseType(from: caseTypeModel)
  }
  
  ///  Used to fetch all casetypes
  public func fetchCaseTypes(completion: @escaping ([CaseType]) -> Void) {
      let fetchRequest: NSFetchRequest<CaseType> = CaseType.fetchRequest()
      databaseManager.fetchAllCasesType(fetchRequest: fetchRequest) { caseTypes in
          completion(caseTypes)
      }
  }
}
