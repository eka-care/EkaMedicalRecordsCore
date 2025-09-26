//
//  RecordsRepo+tags.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 17/09/25.
//

// MARK: - Tags
extension RecordsRepo {

  /// Get all unique tag names from the database
  /// - Returns: Array of unique tag names sorted alphabetically
  public func getAllUniqueTagNames() -> [String] {
    return databaseManager.getAllUniqueTagNames()
  }
  
  /// Get records that have specific tags
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: Array of records that have any of the specified tags
  public func getRecordsWithTags(_ tagNames: [String]) -> [Record] {
    return databaseManager.getRecordsWithTags(tagNames)
  }
  
  /// Get records without any tags
  /// - Returns: Array of records that have no tags
  public func getRecordsWithoutTags() -> [Record] {
    return databaseManager.getRecordsWithoutTags()
  }
  
  /// Fetch records with specific tags using async completion
  /// - Parameters:
  ///   - tagNames: Array of tag names to filter by
  ///   - completion: Completion handler with array of matching records
  public func fetchRecordsWithTags(_ tagNames: [String], completion: @escaping ([Record]) -> Void) {
    let fetchRequest = QueryHelper.fetchRecordsWithTags(tagNames: tagNames)
    fetchRecords(fetchRequest: fetchRequest, completion: completion)
  }
  
  /// Fetch records without tags using async completion
  /// - Parameter completion: Completion handler with array of records without tags
  public func fetchRecordsWithoutTags(completion: @escaping ([Record]) -> Void) {
    let fetchRequest = QueryHelper.fetchRecordsWithoutTags()
    fetchRecords(fetchRequest: fetchRequest, completion: completion)
  }
  
  /// Get records that have ALL of the specified tags
  /// - Parameter tagNames: Array of tag names to filter by
  /// - Returns: Array of records that have all of the specified tags
  public func getRecordsWithAllTags(_ tagNames: [String]) -> [Record] {
    return databaseManager.getRecordsWithAllTags(tagNames)
  }
  
  /// Fetch records that have ALL of the specified tags using async completion
  /// - Parameters:
  ///   - tagNames: Array of tag names to filter by
  ///   - completion: Completion handler with array of matching records
  public func fetchRecordsWithAllTags(_ tagNames: [String], completion: @escaping ([Record]) -> Void) {
    let fetchRequest = QueryHelper.fetchRecordsWithAllTags(tagNames: tagNames)
    fetchRecords(fetchRequest: fetchRequest, completion: completion)
  }
  
  /// Get all tag entities from the database
  /// - Returns: Array of all tag entities
  public func getAllTags() -> [Tags] {
    return databaseManager.getAllTags()
  }
  
  /// Get a specific tag by name
  /// - Parameter tagName: The name of the tag to find
  /// - Returns: The tag entity if found, nil otherwise
  public func getTag(withName tagName: String) -> Tags? {
    return databaseManager.getTag(withName: tagName)
  }
  
  /// Clean up orphaned tags (tags not associated with any records)
  /// - Parameter completion: Completion handler called when cleanup is finished with count of cleaned tags
  public func cleanupOrphanedTags(completion: @escaping (Int) -> Void) {
    databaseManager.cleanupOrphanedTags(completion: completion)
  }
}
