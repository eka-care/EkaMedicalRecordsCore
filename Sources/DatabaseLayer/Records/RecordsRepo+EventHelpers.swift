//
//  RecordsRepo+EventHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

// MARK: - Event Helpers

extension RecordsRepo {
  // MARK: - Create
  
  /// Create record event in network layer
  /// - Parameters:
  ///   - id: document id of the document
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
      eventType: .serverCreate,
      platform: .network,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update
  
  /// Update record event in network
  /// - Parameters:
  ///   - id: document id of the document
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
      eventType: .serverUpdate,
      platform: .network,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete
  
  /// Delete record event in network
  /// - Parameters:
  ///   - id: document id of the document
  ///   - status: status of delete record event
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
      eventType: .serverDelete,
      platform: .network,
      status: status,
      message: message,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}
