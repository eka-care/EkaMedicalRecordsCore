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
  func insertCaseType(from model: CaseTypeModel) -> CaseType {
    var newCasetype: CaseType!
    container.viewContext.performAndWait {
      newCasetype = CaseType(context: container.viewContext)
      newCasetype.update(from: model)
      do {
        try container.viewContext.save()
        EkaMedicalRecordsCoreLogger.capture("CaseType added successfully!")
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Error saving record: \(error.localizedDescription)")
      }
    }
    return newCasetype
  }
  
  // To Upsert CaseType In DB (Update if exists, Insert if not)
  func upsertCaseType(from model: CaseTypeModel, completion: @escaping (CaseType) -> Void) {
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      
      // Check if CaseType with same name already exists
      let fetchRequest: NSFetchRequest<CaseType> = CaseType.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "name == %@", model.name)
      fetchRequest.fetchLimit = 1
      
      do {
        let existingCaseTypes = try self.backgroundContext.fetch(fetchRequest)
        
        if let existingCaseType = existingCaseTypes.first {
          // Update existing CaseType
          existingCaseType.update(from: model)
          EkaMedicalRecordsCoreLogger.capture("CaseType '\(model.name)' updated successfully in background!")
          try self.backgroundContext.save()
          
          DispatchQueue.main.async {
            completion(existingCaseType)
          }
        } else {
          // Create new CaseType
          let newCaseType = CaseType(context: self.backgroundContext)
          newCaseType.update(from: model)
          EkaMedicalRecordsCoreLogger.capture("CaseType '\(model.name)' created successfully in background!")
          try self.backgroundContext.save()
          
          DispatchQueue.main.async {
            completion(newCaseType)
          }
        }
      } catch {
        EkaMedicalRecordsCoreLogger.capture("Error upserting CaseType in background: \(error.localizedDescription)")
        // Fallback to creating new one
        let newCaseType = CaseType(context: self.backgroundContext)
        newCaseType.update(from: model)
        
        DispatchQueue.main.async {
          completion(newCaseType)
        }
      }
    }
  }
  
  // To Fetch  all the CaseTypes from DB
  func fetchAllCasesType(
    fetchRequest: NSFetchRequest<CaseType>,
    completion: @escaping ([CaseType]) -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      let casesType = try? self.backgroundContext.fetch(fetchRequest)
      completion(casesType ?? [])
    }
  }
  
  func bulkInsertCaseTypes(models: [CaseTypeModel]) -> [CaseType] {
      var createdCaseTypes: [CaseType] = []
      
      container.viewContext.performAndWait {
          // Create all entities first
          for model in models {
              let newCaseType = CaseType(context: container.viewContext)
              newCaseType.update(from: model)
              createdCaseTypes.append(newCaseType)
          }
          
          // Save all at once
          do {
              try container.viewContext.save()
              EkaMedicalRecordsCoreLogger.capture("All \(createdCaseTypes.count) CaseTypes added successfully!")
          } catch {
              EkaMedicalRecordsCoreLogger.capture("Error saving CaseTypes: \(error.localizedDescription)")
              container.viewContext.rollback()
              createdCaseTypes = [] // Clear array on failure
          }
      }
      
      return createdCaseTypes
  }
  
  func checkAndPreloadCaseTypes(fetchRequest: NSFetchRequest<CaseType>, preloadData: [CaseTypeModel], completion: @escaping ([CaseType]) -> Void ) {
    fetchAllCasesType(fetchRequest: fetchRequest) { [weak self] caseTypes in
      guard let self else { return }
      if caseTypes.count > 0 {
        completion(caseTypes)
      } else {
        let insertedData = self.bulkInsertCaseTypes(models: preloadData)
        completion(insertedData)
      }
    }
  }
}

