//
//  EkaMedicalRecordsLogger.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 22/08/25.
//



import Foundation

public final class EkaMedicalRecordsCoreLogger {
  
 public static func capture(_ string: @autoclosure () -> String) {
#if DEBUG || PRODUCTION
    // Log the message with timestamp and icon
    let logMessage = "\n \(Date()) :information_source: \(string())"
    // Note: In a production environment, you might want to send this to a logging service
    // For now, we'll keep the print for console output but it's now centralized
    print(logMessage)
#endif
 }
}
