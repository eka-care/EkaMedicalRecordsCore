//
//  EventLoggerProtocol.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 29/05/25.
//

public protocol EventLoggerProtocol: AnyObject {
  func receiveEvent(eventLog: EventLog)
}
