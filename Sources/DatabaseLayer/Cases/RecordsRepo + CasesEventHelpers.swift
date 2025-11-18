//
//  RecordsRepo + CasesEventHelpers.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

// MARK: - Case Event Helpers

extension RecordsRepo {
  // MARK: - Create
  
  /// Create case event in network layer
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
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .serverCreate,
      entityType: .caseEntity,
      message: message,
      status: status,
      platform: .network,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update
  
  /// Update case event in network
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
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .serverUpdate,
      entityType: .caseEntity,
      message: message,
      status: status,
      platform: .network,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete
  
  /// Delete case event in network
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
    let eventLog = EventLog(
      params: [
        "id": id
      ],
      eventType: .serverDelete,
      entityType: .caseEntity,
      status: status,
      platform: .network,
      userOid: userOid
    )
    CoreInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}

