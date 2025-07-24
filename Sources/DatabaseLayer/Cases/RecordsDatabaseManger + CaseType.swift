//
//  RecordsDatabaseManger.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//



import CoreData


// MARK: - CASE_TYPE -  Create / Insert , Fetch

extension RecordsDatabaseManager {
  
  // To Insert CaseType In DB
  func createCaseType(from model: CaseTypeModel) -> CaseType {
    let newCasetype = CaseType(context: container.viewContext)
    newCasetype.update(from: model)
    do {
      try container.viewContext.save()
      debugPrint("CaseType added successfully!")
      return newCasetype
    } catch {
      debugPrint("Error saving record: \(error.localizedDescription)")
      return newCasetype
    }
  }
  
  
  // To Fetch  all the CaseTypes from DB
  func fetchAllCases() -> [CaseType] {
      let context = PersistenceController.shared.context
      let request: NSFetchRequest<CaseType> = CaseType.fetchRequest()
      
      do {
          return try context.fetch(request)
      } catch {
          print("Failed to fetch CaseType: \(error)")
          return []
      }
  }

}
