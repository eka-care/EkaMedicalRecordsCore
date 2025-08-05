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
  /// Any message for the event
  public let message: String?
  /// Status in which event is in
  public let status: EventStatusMonitor
  /// Platform on which event took place
  public let platform: EventPlatform
  /// User Oid
  public let userOid: String?
  
  public init(
    params: [String : Any]? = nil,
    eventType: EventType,
    message: String? = nil,
    status: EventStatusMonitor,
    platform: EventPlatform,
    userOid: String? = nil
  ) {
    self.params = params
    self.eventType = eventType
    self.message = message
    self.status = status
    self.platform = platform
    self.userOid = userOid
  }
}

/// Event Type
public enum EventType: String {
  case create
  case read
  case update
  case delete
  
  public var eventName: String {
    switch self {
    case .create:
      return "Records_iOS_SDK_CREATE"
    case .read:
      return "Records_iOS_SDK_READ"
    case .update:
      return "Records_iOS_SDK_UPDATE"
    case .delete:
      return "Records_iOS_SDK_DELETE"
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
