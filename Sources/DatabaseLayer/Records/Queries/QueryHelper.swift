//
//  QueryHelper.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 09/01/25.
//

import CoreData

public final class QueryHelper {
  /// Query to fetch the last updated document where documentID is not nil, and updatedAt is a valid date, filtering by given oid
  public static func fetchLastUpdatedAt(oid: String) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    /// Predicate: documentID is not nil AND updatedAt is a valid date AND oid matches
    fetchRequest.predicate = NSPredicate(format: "documentID != nil AND updatedAt != nil AND oid == %@", oid as CVarArg)
    /// Sort by updatedAt in descending order (latest date first)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
    /// Fetch only the latest record
    fetchRequest.fetchLimit = 1
    return fetchRequest
  }
  
  /// Query to fetch records that match the provided array of document IDs
  /// - Parameter documentIDs: Array of document IDs to fetch
  /// - Returns: NSFetchRequest configured to fetch matching records
  public static func fetchRecordsByDocumentIDs(documentIDs: [String]) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entity().name!)
    // Predicate: documentID matches any of the provided IDs
    fetchRequest.predicate = NSPredicate(format: "documentID IN %@", documentIDs as CVarArg)
    // Return all matching records
    return fetchRequest
  }
  
  /// Query to fetch records where documentID is nil
  /// - Returns: NSFetchRequest configured to fetch records with no documentID
  public static func fetchRecordsWithNilDocumentID() -> NSFetchRequest<Record> {
    // Create a fetch request for the Record entity
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    // Add a predicate to filter records where documentID is nil
    fetchRequest.predicate = NSPredicate(format: "documentID == nil")
    return fetchRequest
  }
  
  public static func fetchRecordsForPendingOrUploadingSync() -> NSFetchRequest<Record> {
      let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
      
      // Predicate:
      // (syncState != "update_success" AND syncState != "uploading") OR syncState == "uploading"
      // Which simplifies to just: syncState != "update_success" OR syncState == "uploading"
      fetchRequest.predicate = NSPredicate(
          format: "(syncState != %@ OR syncState == %@ OR syncState == %@) OR documentID == nil",
          RecordSyncState.update(success: false).stringValue,
          RecordSyncState.uploading.stringValue,
          RecordSyncState.upload(success: false).stringValue
      )
      return fetchRequest
  }
  
  /// Query to fetch record for given documentID
  /// - Parameter documentID: The document ID to filter by
  /// - Returns: NSFetchRequest configured to fetch the matching record
  public static func fetchRecordWith(documentID: String) -> NSFetchRequest<Record> {
    // Create a fetch request for the Record entity
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    // Set the predicate to filter records where documentID matches the input
    fetchRequest.predicate = NSPredicate(format: "documentID == %@", documentID)
    // Optionally set a fetch limit since we expect at most one record
    fetchRequest.fetchLimit = 1
    return fetchRequest
  }
  
  public static func fetchRecordCountsByDocumentTypeFetchRequest(oid: [String]?, caseID: String?) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entity().name!)
    fetchRequest.resultType = .dictionaryResultType
    
    // Create count expression
    let countExpression = NSExpressionDescription()
    countExpression.name = "count"
    let keyPathExpression = NSExpression(forKeyPath: "documentType")
    countExpression.expression = NSExpression(forFunction: "count:", arguments: [keyPathExpression])
    countExpression.expressionResultType = .integer32AttributeType
    
    // Set group by and properties to fetch
    fetchRequest.propertiesToFetch = ["documentType", countExpression]
    fetchRequest.propertiesToGroupBy = ["documentType"]
    
    /// Predicates
    var predicates: [NSPredicate] = []
    
    /// Oid Predicate
    if let oid {
      let oidPredicate = NSPredicate(format: "oid IN %@", oid)
      predicates.append(oidPredicate)
    }
    
    /// CaseID predicate
    if let caseID {
      let casePredicate = NSPredicate(format: "ANY toCaseModel.caseID == %@", caseID)
      predicates.append(casePredicate)
    }
    
    if !predicates.isEmpty {
      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    return fetchRequest
  }
}

// MARK: - Cases

extension QueryHelper {
  /// Query to fetch case for given caseID
  /// - Parameter caseID: The case ID to filter by
  /// - Returns: NSFetchRequest configured to fetch the matching record
  public static func fetchCase(caseID: String?) -> NSFetchRequest<CaseModel> {
    // Create a fetch request for the CaseMOdel entity
    let fetchRequest: NSFetchRequest<CaseModel> = CaseModel.fetchRequest()
    // Set the predicate to filter case where caseID matches the input
    if let caseID {
      fetchRequest.predicate = NSPredicate(format: "caseID == %@", caseID)
    } else {
      // This will match nothing
      fetchRequest.predicate = NSPredicate(value: false)
    }
    // Optionally set a fetch limit since we expect at most one case
    fetchRequest.fetchLimit = 1
    return fetchRequest
  }
}
