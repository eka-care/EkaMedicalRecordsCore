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
}
