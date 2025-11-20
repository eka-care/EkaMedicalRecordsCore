//
//  RecordsDatabaseManager+EventHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

// MARK: - Event Helpers for Records

extension RecordsDatabaseManager {
  // MARK: - Create
  
  /// Create record event in database layer
  /// - Parameters:
  ///   - id: document id of the document
  ///   - status: status of create record event
  ///   - message: message describing details if any
  func createRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .create,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .records
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update
  
  /// Update record event in database
  /// - Parameters:
  ///   - id: document id of the document
  ///   - status: status of update record event
  ///   - message: message describing details if any
  func updateRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .update,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .records
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete
  
  /// Delete record event in database
  /// - Parameters:
  ///   - id: document id of the document
  ///   - status: status of delete record event
  ///   - message: message describing details if any
  func deleteRecordEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .delete,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .records
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}

// MARK: - Event Helpers for Cases

extension RecordsDatabaseManager {
  // MARK: - Create
  
  /// Create case event in database layer
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of create case event
  ///   - message: message describing details if any
  func createCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .create,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .cases
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update
  
  /// Update case event in database
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of update case event
  ///   - message: message describing details if any
  func updateCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .update,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .cases
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete
  
  /// Delete case event in database
  /// - Parameters:
  ///   - id: case id of the case
  ///   - status: status of delete case event
  ///   - message: message describing details if any
  func deleteCaseEvent(
    id: String?,
    status: EventStatusMonitor,
    message: String? = nil,
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .delete,
      message: message,
      status: status,
      platform: .database,
      userOid: userOid,
      entityType: .cases
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}

