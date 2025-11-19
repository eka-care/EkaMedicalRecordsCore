//
//  RecordsDatabaseManager+EventHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

import CoreData

// MARK: - Event Helpers

extension RecordsDatabaseManager {
  /// Create record event in database
  /// - Parameters:
  ///   - id: object id url of the document
  ///   - status: status of create record event
  ///   - message: message describing details if any
  func createRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .record,
      eventType: .dbCreate,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  /// Update record event in database
  /// - Parameters:
  ///   - id: document id or local id of the record object
  ///   - status: status of update record event
  ///   - message: message describing details if any
  func updateRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .record,
      eventType: .dbUpdate,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  /// Delete record event in database
  /// - Parameters:
  ///   - id: document id or local id of the record object
  ///   - status: status of update record event
  ///   - message: message describing details if any
  func deleteRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .record,
      eventType: .dbDelete,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Case Events
  
  /// Create case event in database
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of create case event
  ///   - message: message describing details if any
  func createCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .caseEntity,
      eventType: .dbCreate,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  /// Update case event in database
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of update case event
  ///   - message: message describing details if any
  func updateCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .caseEntity,
      eventType: .dbUpdate,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  /// Delete case event in database
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of delete case event
  ///   - message: message describing details if any
  func deleteCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String
  ) {
    guard let id else { return }
    let eventLog = EventLog.create(
      id: id,
      entityType: .caseEntity,
      eventType: .dbDelete,
      platform: .database,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}
