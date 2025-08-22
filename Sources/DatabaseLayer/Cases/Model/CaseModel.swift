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
      associateCaseType(with: caseType)
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
    
    if let occuredAt = caseArguementModel.occuredAt {
      self.occuredAt = occuredAt
    }
    
    if let isRemoteCreated = caseArguementModel.isRemoteCreated {
      self.isRemoteCreated = isRemoteCreated
    }
    
    if let isEdited = caseArguementModel.isEdited {
      self.isEdited = isEdited
    }
    
    if let status = caseArguementModel.status {
      self.status = status.rawValue
    }
  }
}

// MARK: - CaseType Association

extension CaseModel {
  /// Used to associate a case type with this case model using case type name
  /// - Parameter caseTypeName: Case type name string to associate with this case model
  private func associateCaseType(with caseTypeName: String) {
    guard let managedContext = managedObjectContext else { return }
    guard !caseTypeName.isEmpty else { return }
    
    // Use batch fetch for better performance
    let fetchRequest: NSFetchRequest<CaseType> = CaseType.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name == %@", caseTypeName)
    
    do {
      let caseTypes = try managedContext.fetch(fetchRequest)
      
      if let existingCaseType = caseTypes.first {
        // Use existing CaseType
        self.addToToCaseType(existingCaseType)
      } else {
        // Create new CaseType if not found and add to database
        let newCaseType = CaseType(context: managedContext)
        newCaseType.name = caseTypeName
        self.addToToCaseType(newCaseType)
        
        // Save the new CaseType to the database
        do {
          try managedContext.save()
          debugPrint("Created and saved new CaseType with name: \(caseTypeName)")
        } catch {
          debugPrint("Error saving new CaseType: \(error.localizedDescription)")
        }
      }
    } catch {
      debugPrint("Error fetching CaseType with name \(caseTypeName): \(error.localizedDescription)")
      
      // Fallback: create new CaseType if fetch fails and save to database
      let newCaseType = CaseType(context: managedContext)
      newCaseType.name = caseTypeName
      self.addToToCaseType(newCaseType)
      
      // Save the new CaseType to the database
      do {
        try managedContext.save()
        debugPrint("Created and saved new CaseType (fallback) with name: \(caseTypeName)")
      } catch {
        debugPrint("Error saving new CaseType (fallback): \(error.localizedDescription)")
      }
    }
  }
}
