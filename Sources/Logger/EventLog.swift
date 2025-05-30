//
//  EventLog.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

/// Event Log structure
struct EventLog {
  /// Any extra information
  let params: [String: Any]?
  /// Event type
  let eventType: EventType
  /// Any message for the event
  let message: String?
  /// Status in which event is in
  let status: EventStatusMonitor
  /// Platform on which event took place
  let platform: EventPlatform
  
  init(
    params: [String : Any]? = nil,
    eventType: EventType,
    message: String? = nil,
    status: EventStatusMonitor,
    platform: EventPlatform
  ) {
    self.params = params
    self.eventType = eventType
    self.message = message
    self.status = status
    self.platform = platform
  }
}

/// Event Type
enum EventType: String {
  case create
  case read
  case update
  case delete
}

/// Event Status
enum EventStatusMonitor: String {
  case success
  case failure
}

/// Event platform
enum EventPlatform: String {
  case database
  case network
}
