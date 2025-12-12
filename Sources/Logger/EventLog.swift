//
//  EventLog.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

/// Entity Type for event logging
public enum EventEntityType: String {
  case records
  case cases
}

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
  /// Entity type (Records or Cases)
  public let entityType: EventEntityType
  
  public let isAbhaLinked: Bool?
  
  public init(
    params: [String : Any]? = nil,
    eventType: EventType,
    message: String? = nil,
    status: EventStatusMonitor,
    platform: EventPlatform,
    userOid: String? = nil,
    entityType: EventEntityType = .records,
    isAbhaLinked: Bool? = nil
  ) {
    self.params = params
    self.eventType = eventType
    self.message = message
    self.status = status
    self.platform = platform
    self.userOid = userOid
    self.entityType = entityType
    self.isAbhaLinked = isAbhaLinked
  }
}

/// Event Type
public enum EventType: String {
  case create
  case read
  case update
  case delete
  
  public func eventName(for entityType: EventEntityType) -> String {
    let entityPrefix = entityType == .cases ? "Cases" : "Records"
    switch self {
    case .create:
      return "\(entityPrefix)_iOS_SDK_CREATE"
    case .read:
      return "\(entityPrefix)_iOS_SDK_READ"
    case .update:
      return "\(entityPrefix)_iOS_SDK_UPDATE"
    case .delete:
      return "\(entityPrefix)_iOS_SDK_DELETE"
    }
  }
  
  @available(*, deprecated, message: "Use eventName(for:) instead")
  public var eventName: String {
    return eventName(for: .records)
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
