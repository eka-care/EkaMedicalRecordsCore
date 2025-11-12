//
//  ErrorHelper.swift
//  EkaMedicalRecordsCore
//
//  Created by AI Assistant on 31/12/24.
//

import Foundation

/// Generic error handling utility for EkaMedicalRecordsCore
public final class ErrorHelper {
    
    // MARK: - Error Domains
    public enum Domain: String {
        case recordsRepo = "RecordsRepo"
        case databaseManager = "DatabaseManager"
        case networkService = "NetworkService"
        case validation = "Validation"
        case sync = "Sync"
    }
    
    // MARK: - Error Codes
    public enum Code: Int {
        case unknown = -1
        case selfDeallocated = -2
        case missingRequiredData = -3
        case syncNewCasesFailed = -4
        case syncEditedCasesFailed = -5
        case validationFailed = -6
        case networkRequestFailed = -7
        case databaseOperationFailed = -8
        case configurationMissing = -9
        case downloadFailed = -10
        case serializationFailed = -11
        case responseParsingFailed = -12
        case missingResponseData = -13
        case uploadLimitReached = -14
    }
    
    // MARK: - Error Creation Methods
    
    /// Creates a generic NSError with standard domain and code
    /// - Parameters:
    ///   - domain: Error domain
    ///   - code: Error code
    ///   - message: Localized description
    ///   - underlyingError: Optional underlying error
    ///   - userInfo: Additional user info dictionary
    /// - Returns: NSError instance
    public static func createError(
        domain: Domain,
        code: Code,
        message: String,
        underlyingError: Error? = nil,
        userInfo: [String: Any]? = nil
    ) -> NSError {
        var errorUserInfo: [String: Any] = [
            NSLocalizedDescriptionKey: message
        ]
        
        if let underlyingError = underlyingError {
            errorUserInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        if let additionalUserInfo = userInfo {
            errorUserInfo.merge(additionalUserInfo) { _, new in new }
        }
        
        return NSError(
            domain: domain.rawValue,
            code: code.rawValue,
            userInfo: errorUserInfo
        )
    }
    
    /// Creates a self-deallocated error
    /// - Parameter domain: Error domain
    /// - Returns: NSError for self deallocation
    public static func selfDeallocatedError(domain: Domain = .recordsRepo) -> NSError {
        return createError(
            domain: domain,
            code: .selfDeallocated,
            message: "Object was deallocated during operation"
        )
    }
    
    /// Creates a validation error for missing required data
    /// - Parameters:
    ///   - missingFields: Array of missing field names
    ///   - domain: Error domain
    /// - Returns: NSError for validation failure
    public static func validationError(
        missingFields: [String],
        domain: Domain = .validation
    ) -> NSError {
        let message = "Missing required data: \(missingFields.joined(separator: ", "))"
        return createError(
            domain: domain,
            code: .validationFailed,
            message: message,
            userInfo: ["missingFields": missingFields]
        )
    }
    
    /// Creates a sync operation error with multiple underlying errors
    /// - Parameters:
    ///   - operation: Name of the sync operation
    ///   - failureCount: Number of failed operations
    ///   - errors: Array of underlying errors
    ///   - domain: Error domain
    /// - Returns: NSError for sync operation failure
    public static func syncOperationError(
        operation: String,
        failureCount: Int,
        errors: [Error],
        domain: Domain = .sync
    ) -> NSError {
        let message = "Failed to \(operation): \(failureCount) operation(s) failed"
        return createError(
            domain: domain,
            code: operation.contains("new") ? .syncNewCasesFailed : .syncEditedCasesFailed,
            message: message,
            userInfo: [
                "failureCount": failureCount,
                "underlyingErrors": errors,
                "operation": operation
            ]
        )
    }
    
    /// Creates a configuration missing error
    /// - Parameters:
    ///   - configName: Name of the missing configuration
    ///   - domain: Error domain
    /// - Returns: NSError for missing configuration
    public static func configurationMissingError(
        configName: String,
        domain: Domain = .recordsRepo
    ) -> NSError {
        return createError(
            domain: domain,
            code: .configurationMissing,
            message: "Missing required configuration: \(configName)",
            userInfo: ["configurationName": configName]
        )
    }
    
    /// Creates a network request error
    /// - Parameters:
    ///   - endpoint: API endpoint that failed
    ///   - statusCode: HTTP status code (optional)
    ///   - underlyingError: Underlying network error
    ///   - domain: Error domain
    /// - Returns: NSError for network request failure
    public static func networkRequestError(
        endpoint: String,
        statusCode: Int? = nil,
        underlyingError: Error? = nil,
        domain: Domain = .networkService
    ) -> NSError {
        var message = "Network request failed for endpoint: \(endpoint)"
        if let statusCode = statusCode {
            message += " (Status: \(statusCode))"
        }
        
        var userInfo: [String: Any] = ["endpoint": endpoint]
        if let statusCode = statusCode {
            userInfo["statusCode"] = statusCode
        }
        
        return createError(
            domain: domain,
            code: .networkRequestFailed,
            message: message,
            underlyingError: underlyingError,
            userInfo: userInfo
        )
    }
    
    /// Creates a database operation error
    /// - Parameters:
    ///   - operation: Database operation that failed
    ///   - underlyingError: Underlying database error
    ///   - domain: Error domain
    /// - Returns: NSError for database operation failure
    public static func databaseOperationError(
        operation: String,
        underlyingError: Error? = nil,
        domain: Domain = .databaseManager
    ) -> NSError {
        return createError(
            domain: domain,
            code: .databaseOperationFailed,
            message: "Database operation failed: \(operation)",
            underlyingError: underlyingError,
            userInfo: ["operation": operation]
        )
    }
    
    /// Creates a download operation error
    /// - Parameters:
    ///   - reason: Reason for download failure
    ///   - underlyingError: Underlying download error
    ///   - domain: Error domain
    /// - Returns: NSError for download failure
    public static func downloadError(
        reason: String = "Download failed",
        underlyingError: Error? = nil,
        domain: Domain = .networkService
    ) -> NSError {
        return createError(
            domain: domain,
            code: .downloadFailed,
            message: reason,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a serialization error
    /// - Parameters:
    ///   - operation: Serialization operation that failed
    ///   - underlyingError: Underlying serialization error
    ///   - domain: Error domain
    /// - Returns: NSError for serialization failure
    public static func serializationError(
        operation: String = "Serialization failed",
        underlyingError: Error? = nil,
        domain: Domain = .networkService
    ) -> NSError {
        return createError(
            domain: domain,
            code: .serializationFailed,
            message: operation,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a response parsing error
    /// - Parameters:
    ///   - reason: Reason for parsing failure
    ///   - underlyingError: Underlying parsing error
    ///   - domain: Error domain
    /// - Returns: NSError for response parsing failure
    public static func responseParsingError(
        reason: String = "Failed to parse response",
        underlyingError: Error? = nil,
        domain: Domain = .networkService
    ) -> NSError {
        return createError(
            domain: domain,
            code: .responseParsingFailed,
            message: reason,
            underlyingError: underlyingError
        )
    }
    
    /// Creates a missing response data error
    /// - Parameters:
    ///   - domain: Error domain
    /// - Returns: NSError for missing response data
    public static func missingResponseDataError(
        domain: Domain = .networkService
    ) -> NSError {
        return createError(
            domain: domain,
            code: .missingResponseData,
            message: "Response data is missing or empty"
        )
    }
}

// MARK: - Error Extensions
extension NSError {
    
    /// Gets the underlying errors array if available
    public var underlyingErrors: [Error]? {
        return userInfo["underlyingErrors"] as? [Error]
    }
    
    /// Gets the failure count if available
    public var failureCount: Int? {
        return userInfo["failureCount"] as? Int
    }
    
    /// Gets the operation name if available
    public var operationName: String? {
        return userInfo["operation"] as? String
    }
    
    /// Gets missing fields if this is a validation error
    public var missingFields: [String]? {
        return userInfo["missingFields"] as? [String]
    }
}
