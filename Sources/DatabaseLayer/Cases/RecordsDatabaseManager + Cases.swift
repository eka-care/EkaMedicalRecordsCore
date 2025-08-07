//
//  RecordsDatabaseManager + Cases.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 17/07/25.
//

import CoreData

// MARK: - Create / Insert

extension RecordsDatabaseManager {
  /// Used to create a case
  /// - Parameter model: model from which we will read a case
  /// - Returns: case model which had been created
  func createCase(from model: CaseArguementModel) -> CaseModel {
    let newCase = CaseModel(context: container.viewContext)
    newCase.update(from: model)
    do {
      try container.viewContext.save()
      debugPrint("Case added successfully!")
      return newCase
    } catch {
      debugPrint("Error saving record: \(error.localizedDescription)")
      return newCase
    }
  }
}

// MARK: - Read

extension RecordsDatabaseManager {
  /// Used to read a case
  /// - Parameter fetchRequest: fetch request for filtering
  /// - Parameter completion: completion block to be executed after fetching cases
  func fetchCase(
    fetchRequest: NSFetchRequest<CaseModel>,
    completion: @escaping ([CaseModel]) -> Void
  ) {
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      let cases = try? backgroundContext.fetch(fetchRequest)
      completion(cases ?? [])
    }
  }
  
  /// Used to fetch record with given object id
  /// - Parameter id: Id of the case
  /// - Returns: The case model which was fetched using given object id
  func fetchCase(with id: NSManagedObjectID) -> CaseModel? {
    do {
      let caseModel = try container.viewContext.existingObject(with: id) as? CaseModel
      return caseModel
    } catch {
      debugPrint("Not able to fetch case with given id \(error.localizedDescription)")
    }
    return nil
  }
}

// MARK: - Update

extension RecordsDatabaseManager {
  /// Used to update case model
  /// - Parameters:
  ///   - caseModel: referenced to the existing case model which needs to be update
  ///   - caseArguementModel: argument which will update the case model
  func updateCase(
    caseModel: CaseModel,
    caseArguementModel: CaseArguementModel
  ) {
    caseModel.update(from: caseArguementModel)
    do {
      try container.viewContext.save()
    } catch {
      debugPrint("No able to update case \(error.localizedDescription)")
    }
  }
}

// MARK: - Delete

extension RecordsDatabaseManager {
  /// Used to delete a given case object
  /// - Parameter caseModel: the reference to the given case model
  func deleteCase(
    caseModel: CaseModel
  ) {
    container.viewContext.delete(caseModel)
    do {
      try container.viewContext.save()
    } catch {
      debugPrint("Error in deleting case \(error.localizedDescription)")
    }
  }
}
