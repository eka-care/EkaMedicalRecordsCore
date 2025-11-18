//
//  EventLog.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

/// Event Log structure
public struct EventLog {
  /// Any extra information
  public let params: [String: Any]?
  /// Event type
  public let eventType: EventType
  /// Entity type (Record or Case)
  public let entityType: EventEntityType
  /// Any message for the event
  public let message: String?
  /// Status in which event is in
  public let status: EventStatusMonitor
  /// Platform on which event took place
  public let platform: EventPlatform
  /// User Oid
  public let userOid: String
  
  public init(
    params: [String : Any]? = nil,
    eventType: EventType,
    entityType: EventEntityType,
    message: String? = nil,
    status: EventStatusMonitor,
    platform: EventPlatform,
    userOid: String
  ) {
    self.params = params
    self.eventType = eventType
    self.entityType = entityType
    self.message = message
    self.status = status
    self.platform = platform
    self.userOid = userOid
  }
}

/// Event Type
public enum EventType: String {
  // Database events
  case dbCreate
  case dbRead
  case dbUpdate
  case dbDelete
  
  // Server events
  case serverCreate
  case serverRead
  case serverUpdate
  case serverDelete
  
  public func eventName(entityType: EventEntityType) -> String {
    let entityPrefix = entityType == .record ? "Records" : "Cases"
    switch self {
    case .dbCreate:
      return "\(entityPrefix)_iOS_SDK_DB_CREATE"
    case .dbRead:
      return "\(entityPrefix)_iOS_SDK_DB_READ"
    case .dbUpdate:
      return "\(entityPrefix)_iOS_SDK_DB_UPDATE"
    case .dbDelete:
      return "\(entityPrefix)_iOS_SDK_DB_DELETE"
    case .serverCreate:
      return "\(entityPrefix)_iOS_SDK_SERVER_CREATE"
    case .serverRead:
      return "\(entityPrefix)_iOS_SDK_SERVER_READ"
    case .serverUpdate:
      return "\(entityPrefix)_iOS_SDK_SERVER_UPDATE"
    case .serverDelete:
      return "\(entityPrefix)_iOS_SDK_SERVER_DELETE"
    }
  }
}

/// Event Status
public enum EventStatusMonitor: String {
  case success
  case failure
}

/// Event platform
public enum EventPlatform: String {
  case database
  case network
}

/// Event Entity Type
public enum EventEntityType: String {
  case record
  case caseEntity
}
