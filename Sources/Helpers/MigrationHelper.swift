//
//  MigrationHelper.swift
//  EkaMedicalRecordsCore
//
//  Created by Migration Assistant
//

import Foundation

/// Helper class to manage one-time data migrations
public class MigrationHelper {
  
  // MARK: - Constants
  
  private enum MigrationKeys {
    static let smartReportUnitEkaIdMigration = "smart_report_unit_eka_id_migration_completed"
  }
  
  // MARK: - Public Methods
  
  /// Performs SmartReport migration for unitEkaId property if not already completed
  /// This fetches fresh data from API to ensure latest unitEkaId values are included
  /// This should be called once after app initialization
  /// - Parameter completion: Completion block with success status and message
  public static func performSmartReportMigrationIfNeeded(completion: @escaping (Bool, String?) -> Void) {
    // Check if migration has already been completed
    if UserDefaultsHelper.fetchBool(forKey: MigrationKeys.smartReportUnitEkaIdMigration) {
      EkaMedicalRecordsCoreLogger.capture("SmartReport unitEkaId migration already completed, skipping")
      completion(true, "Migration already completed")
      return
    }
    
    EkaMedicalRecordsCoreLogger.capture("Starting SmartReport unitEkaId API migration...")
    
    // Perform the migration by fetching fresh data from API
    let recordsRepo = RecordsRepo.shared
    recordsRepo.migrateSmartReportData { success, message in
      if success {
        // Mark migration as completed
        UserDefaultsHelper.saveBool(true, forKey: MigrationKeys.smartReportUnitEkaIdMigration)
        EkaMedicalRecordsCoreLogger.capture("SmartReport unitEkaId API migration completed successfully")
        completion(true, message)
      } else {
        EkaMedicalRecordsCoreLogger.capture("SmartReport unitEkaId API migration failed: \(message ?? "Unknown error")")
        completion(false, message)
      }
    }
  }
  
  /// Resets the migration flag (useful for testing or forcing re-migration)
  /// - Warning: This will cause the migration to run again on next app launch
  public static func resetSmartReportMigrationFlag() {
    UserDefaultsHelper.saveBool(false, forKey: MigrationKeys.smartReportUnitEkaIdMigration)
    EkaMedicalRecordsCoreLogger.capture("SmartReport migration flag reset")
  }
  
  /// Checks if SmartReport migration has been completed
  /// - Returns: true if migration is completed, false otherwise
  public static func isSmartReportMigrationCompleted() -> Bool {
    return UserDefaultsHelper.fetchBool(forKey: MigrationKeys.smartReportUnitEkaIdMigration)
  }
}
