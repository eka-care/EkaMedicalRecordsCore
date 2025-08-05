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
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .update,
      status: status,
      platform: .database,
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
    userOid: String? = nil
  ) {
    guard let id else { return }
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .delete,
      status: status,
      platform: .database,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}
