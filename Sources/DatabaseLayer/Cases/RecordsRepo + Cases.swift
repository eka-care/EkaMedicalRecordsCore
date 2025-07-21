//
//  RecordsRepo + Cases.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 21/07/25.
//

extension RecordsRepo {
  /// Used to add new case
  /// - Parameter caseArguementModel: arguementModel which is description of case
  /// - Returns: caseModel which was added
  public func addCase(
    caseArguementModel: CaseArguementModel
  ) -> CaseModel {
    return databaseManager.createCase(from: caseArguementModel)
  }
  
  /// Used to delete a case
  /// - Parameter caseModel: reference to the model which is to be deleted
  public func deleteCase(
    _ caseModel: CaseModel
  ) {
    databaseManager.deleteCase(caseModel: caseModel)
  }
}
