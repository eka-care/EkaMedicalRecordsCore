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
    fetchRequest.predicate = NSPredicate(
        format: "updatedAt != nil AND oid == %@ AND (syncState != %@ OR syncState != %@)",
        oid as CVarArg,
        RecordSyncState.uploading.stringValue,
        RecordSyncState.upload(success: false).stringValue
    )
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
  
  public static func fetchRecordsWithUploadingOrFailedState() -> NSFetchRequest<Record> {
    // Create a fetch request for the Record entity
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    // Add a predicate to filter records where syncState is uploading or upload_failure
    fetchRequest.predicate = NSPredicate(
      format: "syncState == %@ OR syncState == %@",
      RecordSyncState.uploading.stringValue,
      RecordSyncState.upload(success: false).stringValue
    )
    return fetchRequest
  }
  
  public static func fetchRecordsForEditedRecordSync() -> NSFetchRequest<Record> {
      let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
      fetchRequest.predicate = NSPredicate(
          format: "isEdited == %@ AND syncState == %@",
          NSNumber(value: true),
          RecordSyncState.upload(success: true).stringValue
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
  
  /// Query to fetch all unique document types from the database
  /// - Parameters:
  ///   - oid: Optional array of owner IDs to filter by (Record.oid)
  ///   - bid: Optional array of beneficiary IDs to filter by (Record.bid)
  ///   - caseID: Optional case ID to filter document types by
  /// - Returns: NSFetchRequest configured to fetch unique document types
  public static func fetchAllUniqueDocumentTypes(oid: [String]? = nil, bid: String? = nil, caseID: String? = nil) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entity().name!)
    fetchRequest.resultType = .dictionaryResultType
    fetchRequest.propertiesToFetch = ["documentType"]
    fetchRequest.returnsDistinctResults = true
    
    var predicates: [NSPredicate] = []
    
    // Base predicate to filter out nil and empty document types
    let basePredicate = NSPredicate(format: "documentType != nil")
    predicates.append(basePredicate)
    
    // OID predicate
    if let oid, !oid.isEmpty {
      let oidPredicate = NSPredicate(format: "oid IN %@", oid)
      predicates.append(oidPredicate)
    }
    
    // BID predicate
    if let bid, !bid.isEmpty {
      let bidPredicate = NSPredicate(format: "bid == %@", bid)
      predicates.append(bidPredicate)
    }
    
    // CaseID predicate
    if let caseID = caseID {
      let casePredicate = NSPredicate(format: "ANY toCaseModel.caseID == %@", caseID)
      predicates.append(casePredicate)
    }
    
    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "documentType", ascending: true)]
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
  
  /// Query to fetch multiple cases for given caseIDs
  /// - Parameter caseIDs: Array of case IDs to filter by
  /// - Returns: NSFetchRequest configured to fetch the matching cases
  public static func fetchCases(caseIDs: [String]) -> NSFetchRequest<CaseModel> {
    let fetchRequest: NSFetchRequest<CaseModel> = CaseModel.fetchRequest()
    if !caseIDs.isEmpty {
      fetchRequest.predicate = NSPredicate(format: "caseID IN %@", caseIDs)
    } else {
      // This will match nothing
      fetchRequest.predicate = NSPredicate(value: false)
    }
    return fetchRequest
  }
  
  public static func fetchLastCaseUpdatedAt(oid: String) -> NSFetchRequest<CaseModel> {
    let fetchRequest: NSFetchRequest<CaseModel> = CaseModel.fetchRequest()
    /// Predicate: documentID is not nil AND updatedAt is a valid date AND oid matches
    fetchRequest.predicate = NSPredicate(format: "caseID != nil AND updatedAt != nil AND oid == %@", oid as CVarArg)
    /// Sort by updatedAt in descending order (latest date first)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
    /// Fetch only the latest record
    fetchRequest.fetchLimit = 1
    return fetchRequest
  }
  
  public static func fetchCasesForEditedSync() -> NSFetchRequest<CaseModel> {
      let fetchRequest: NSFetchRequest<CaseModel> = CaseModel.fetchRequest()
      fetchRequest.predicate = NSPredicate(
          format: "isEdited == %@",
          NSNumber(value: true)
      )
      return fetchRequest
  }
  
  public static func fetchCasesForUncreatedOnServerSync() -> NSFetchRequest<CaseModel> {
      let fetchRequest: NSFetchRequest<CaseModel> = CaseModel.fetchRequest()
      fetchRequest.predicate = NSPredicate(
          format: "isRemoteCreated == %@",
          NSNumber(value: false)
      )
      return fetchRequest
  }
}

// MARK: - Tags

extension QueryHelper {
  /// Query to fetch records that have specific tags (ANY of the specified tags)
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: NSFetchRequest configured to fetch records with any of the matching tags
  public static func fetchRecordsWithTags(tagNames: [String]) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    if !tagNames.isEmpty {
      fetchRequest.predicate = NSPredicate(format: "ANY toTags.name IN %@", tagNames)
    } else {
      // This will match nothing
      fetchRequest.predicate = NSPredicate(value: false)
    }
    return fetchRequest
  }
  
  /// Query to fetch records that have ALL of the specified tags
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: NSFetchRequest configured to fetch records with all of the matching tags
  public static func fetchRecordsWithAllTags(tagNames: [String]) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    if !tagNames.isEmpty {
      var subpredicates: [NSPredicate] = []
      for tagName in tagNames {
        let predicate = NSPredicate(format: "ANY toTags.name == %@", tagName)
        subpredicates.append(predicate)
      }
      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    } else {
      // This will match nothing
      fetchRequest.predicate = NSPredicate(value: false)
    }
    return fetchRequest
  }
  
  /// Query to fetch records that have a specific tag
  /// - Parameter tagName: The tag name to filter by
  /// - Returns: NSFetchRequest configured to fetch records with the matching tag
  public static func fetchRecordsWithTag(tagName: String) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "ANY toTags.name == %@", tagName)
    return fetchRequest
  }
  
  /// Query to fetch records that have any tags
  /// - Returns: NSFetchRequest configured to fetch records with any tags
  public static func fetchRecordsWithAnyTags() -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "toTags.@count > 0")
    return fetchRequest
  }
  
  /// Query to fetch records that have no tags
  /// - Returns: NSFetchRequest configured to fetch records without tags
  public static func fetchRecordsWithoutTags() -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "toTags.@count == 0")
    return fetchRequest
  }
  
  /// Query to fetch all unique tag names from the database
  /// - Returns: NSFetchRequest configured to fetch unique tag names
  public static func fetchAllUniqueTagNames() -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tags")
    fetchRequest.resultType = .dictionaryResultType
    fetchRequest.propertiesToFetch = ["name"]
    fetchRequest.returnsDistinctResults = true
    fetchRequest.predicate = NSPredicate(format: "name != nil AND name != %@", "")
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    return fetchRequest
  }
  
  /// Query to fetch all tags from the database
  /// - Returns: NSFetchRequest configured to fetch all tag entities
  public static func fetchAllTags() -> NSFetchRequest<Tags> {
    let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name != nil AND name != %@", "")
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    return fetchRequest
  }
  
  /// Query to fetch a specific tag by name
  /// - Parameter tagName: The tag name to search for
  /// - Returns: NSFetchRequest configured to fetch the tag with the specified name
  public static func fetchTag(withName tagName: String) -> NSFetchRequest<Tags> {
    let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name == %@", tagName)
    fetchRequest.fetchLimit = 1
    return fetchRequest
  }
  
  /// Query to fetch tags that are associated with specific records
  /// - Parameter documentIDs: Array of document IDs to filter by
  /// - Returns: NSFetchRequest configured to fetch tags for the matching records
  public static func fetchTagsForRecords(documentIDs: [String]) -> NSFetchRequest<Tags> {
    let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
    if !documentIDs.isEmpty {
      fetchRequest.predicate = NSPredicate(format: "ANY toRecords.documentID IN %@", documentIDs)
    } else {
      fetchRequest.predicate = NSPredicate(value: false)
    }
    return fetchRequest
  }
  
  /// Query to fetch records filtered by oid and optionally by tags
  /// - Parameters:
  ///   - oid: Array of owner IDs to filter by
  ///   - tagNames: Optional array of tag names to filter by (ANY match)
  ///   - requireAllTags: If true, requires ALL tags; if false, requires ANY tag (default: false)
  /// - Returns: NSFetchRequest configured to fetch matching records
  public static func fetchRecords(oid: [String]?, tagNames: [String]? = nil, requireAllTags: Bool = false) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    var predicates: [NSPredicate] = []
    
    // OID predicate
    if let oid = oid, !oid.isEmpty {
      let oidPredicate = NSPredicate(format: "oid IN %@", oid)
      predicates.append(oidPredicate)
    }
    
    // Tags predicate
    if let tagNames = tagNames, !tagNames.isEmpty {
      let tagPredicate: NSPredicate
      if requireAllTags {
        // Require ALL tags
        var tagSubpredicates: [NSPredicate] = []
        for tagName in tagNames {
          let predicate = NSPredicate(format: "ANY toTags.name == %@", tagName)
          tagSubpredicates.append(predicate)
        }
        tagPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: tagSubpredicates)
      } else {
        // Require ANY tag
        tagPredicate = NSPredicate(format: "ANY toTags.name IN %@", tagNames)
      }
      predicates.append(tagPredicate)
    }
    
    if !predicates.isEmpty {
      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    return fetchRequest
  }
  
  /// Query to fetch records that have a specific number of tags
  /// - Parameter count: The number of tags to filter by
  /// - Returns: NSFetchRequest configured to fetch records with the specified number of tags
  public static func fetchRecordsWithTagCount(_ count: Int) -> NSFetchRequest<Record> {
    let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "toTags.@count == %d", count)
    return fetchRequest
  }
  
  /// Query to fetch orphaned tags (tags not associated with any records)
  /// - Returns: NSFetchRequest configured to fetch orphaned tag entities
  public static func fetchOrphanedTags() -> NSFetchRequest<Tags> {
    let fetchRequest: NSFetchRequest<Tags> = Tags.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "toRecords.@count == 0")
    return fetchRequest
  }
  
  /// Query to fetch total count of all records
  /// - Parameters:
  ///   - oid: Optional array of owner IDs to filter by
  ///   - caseID: Optional case ID to filter records by
  ///   - documentType: Optional document type to filter records by
  /// - Returns: NSFetchRequest configured to fetch total count of records
  public static func fetchAllRecordsCountQuery(oid: [String]? = nil, caseID: String? = nil, documentType: String? = nil) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entity().name!)
    fetchRequest.resultType = .countResultType
    
    var predicates: [NSPredicate] = []
    
    // OID predicate
    if let oid, !oid.isEmpty {
      let oidPredicate = NSPredicate(format: "oid IN %@", oid)
      predicates.append(oidPredicate)
    }
    
    // CaseID predicate
    if let caseID, !caseID.isEmpty {
      let casePredicate = NSPredicate(format: "ANY toCaseModel.caseID == %@", caseID)
      predicates.append(casePredicate)
    }
    
    // DocumentType predicate
    if let documentType, !documentType.isEmpty {
      let documentTypePredicate = NSPredicate(format: "documentType == %@", documentType)
      predicates.append(documentTypePredicate)
    }
    
    if !predicates.isEmpty {
      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    return fetchRequest
  }
}
