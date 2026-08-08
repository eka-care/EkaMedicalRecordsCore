import XCTest
@testable import EkaMedicalRecordsCore

final class ErrorHelperTests: XCTestCase {
    func test_selfDeallocatedError_defaults() {
        let error = ErrorHelper.selfDeallocatedError()
        XCTAssertEqual(error.domain, ErrorHelper.Domain.recordsRepo.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.selfDeallocated.rawValue)
        XCTAssertEqual(error.localizedDescription, "Object was deallocated during operation")
    }

    func test_validationError_containsMissingFields() {
        let error = ErrorHelper.validationError(missingFields: ["caseID", "oid"])
        XCTAssertEqual(error.domain, ErrorHelper.Domain.validation.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.validationFailed.rawValue)
        XCTAssertEqual(error.missingFields!, ["caseID", "oid"])
        XCTAssertTrue(error.localizedDescription.contains("caseID"))
    }

    func test_syncOperationError_metadata() {
        let underlying = NSError(domain: "t", code: 1)
        let error = ErrorHelper.syncOperationError(operation: "sync new records", failureCount: 2, errors: [underlying])
        XCTAssertEqual(error.domain, ErrorHelper.Domain.sync.rawValue)
        XCTAssertEqual(error.failureCount, 2)
        XCTAssertEqual(error.underlyingErrors?.count, 1)
        XCTAssertEqual(error.operationName, "sync new records")
    }

    func test_configurationMissingError() {
        let error = ErrorHelper.configurationMissingError(configName: "primaryFilterID")
        XCTAssertEqual(error.domain, ErrorHelper.Domain.recordsRepo.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.configurationMissing.rawValue)
        XCTAssertEqual(error.userInfo["configurationName"] as? String, "primaryFilterID")
    }

    func test_networkRequestError_includesStatusCode() {
        let error = ErrorHelper.networkRequestError(endpoint: "/docs", statusCode: 404)
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.networkRequestFailed.rawValue)
        XCTAssertEqual(error.userInfo["endpoint"] as? String, "/docs")
        XCTAssertEqual(error.userInfo["statusCode"] as? Int, 404)
    }
    
    func test_databaseOperationError() {
        let underlyingError = NSError(domain: "CoreData", code: 1, userInfo: nil)
        let error = ErrorHelper.databaseOperationError(
            operation: "fetch records",
            underlyingError: underlyingError
        )
        XCTAssertEqual(error.domain, ErrorHelper.Domain.databaseManager.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.databaseOperationFailed.rawValue)
        XCTAssertEqual(error.userInfo["operation"] as? String, "fetch records")
        XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey])
    }
    
    func test_downloadError() {
        let error = ErrorHelper.downloadError(reason: "Network timeout")
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.downloadFailed.rawValue)
        XCTAssertTrue(error.localizedDescription.contains("Network timeout"))
    }
    
    func test_serializationError() {
        let error = ErrorHelper.serializationError(operation: "JSON encoding failed")
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.serializationFailed.rawValue)
        XCTAssertTrue(error.localizedDescription.contains("JSON encoding failed"))
    }
    
    func test_responseParsingError() {
        let error = ErrorHelper.responseParsingError(reason: "Invalid JSON format")
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.responseParsingFailed.rawValue)
        XCTAssertTrue(error.localizedDescription.contains("Invalid JSON format"))
    }
    
    func test_missingResponseDataError() {
        let error = ErrorHelper.missingResponseDataError()
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.missingResponseData.rawValue)
        XCTAssertEqual(error.localizedDescription, "Response data is missing or empty")
    }
    
    func test_createError_withAllParameters() {
        let underlying = NSError(domain: "Test", code: 1)
        let customUserInfo = ["customKey": "customValue"]
        let error = ErrorHelper.createError(
            domain: .networkService,
            code: .unknown,
            message: "Custom error message",
            underlyingError: underlying,
            userInfo: customUserInfo
        )
        
        XCTAssertEqual(error.domain, ErrorHelper.Domain.networkService.rawValue)
        XCTAssertEqual(error.code, ErrorHelper.Code.unknown.rawValue)
        XCTAssertEqual(error.localizedDescription, "Custom error message")
        XCTAssertNotNil(error.userInfo[NSUnderlyingErrorKey])
        XCTAssertEqual(error.userInfo["customKey"] as? String, "customValue")
    }
    
    func test_NSError_operationName_extension() {
        let error = ErrorHelper.syncOperationError(
            operation: "test operation",
            failureCount: 3,
            errors: []
        )
        XCTAssertEqual(error.operationName, "test operation")
    }
    
    func test_allDomainRawValues() {
        XCTAssertEqual(ErrorHelper.Domain.recordsRepo.rawValue, "RecordsRepo")
        XCTAssertEqual(ErrorHelper.Domain.databaseManager.rawValue, "DatabaseManager")
        XCTAssertEqual(ErrorHelper.Domain.networkService.rawValue, "NetworkService")
        XCTAssertEqual(ErrorHelper.Domain.validation.rawValue, "Validation")
        XCTAssertEqual(ErrorHelper.Domain.sync.rawValue, "Sync")
    }
    
    func test_allErrorCodeRawValues() {
        XCTAssertEqual(ErrorHelper.Code.unknown.rawValue, -1)
        XCTAssertEqual(ErrorHelper.Code.selfDeallocated.rawValue, -2)
        XCTAssertEqual(ErrorHelper.Code.missingRequiredData.rawValue, -3)
        XCTAssertEqual(ErrorHelper.Code.syncNewCasesFailed.rawValue, -4)
        XCTAssertEqual(ErrorHelper.Code.syncEditedCasesFailed.rawValue, -5)
        XCTAssertEqual(ErrorHelper.Code.validationFailed.rawValue, -6)
        XCTAssertEqual(ErrorHelper.Code.networkRequestFailed.rawValue, -7)
        XCTAssertEqual(ErrorHelper.Code.databaseOperationFailed.rawValue, -8)
        XCTAssertEqual(ErrorHelper.Code.configurationMissing.rawValue, -9)
        XCTAssertEqual(ErrorHelper.Code.downloadFailed.rawValue, -10)
        XCTAssertEqual(ErrorHelper.Code.serializationFailed.rawValue, -11)
        XCTAssertEqual(ErrorHelper.Code.responseParsingFailed.rawValue, -12)
        XCTAssertEqual(ErrorHelper.Code.missingResponseData.rawValue, -13)
    }
}
