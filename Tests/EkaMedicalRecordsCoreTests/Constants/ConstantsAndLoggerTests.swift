import XCTest
@testable import EkaMedicalRecordsCore

final class ConstantsAndLoggerTests: XCTestCase {
    // MARK: - Constants Tests
    
    func test_Constants_lastUpdatedRecordAt() {
        XCTAssertEqual(Constants.lastUpdatedRecordAt, "lastUpdatedRecordAt")
    }
    
    // MARK: - ScreenConstants Tests
    
    func test_ScreenConstants_widthAndHeight() {
        XCTAssertGreaterThan(ScreenConstants.width, 0)
        XCTAssertGreaterThan(ScreenConstants.height, 0)
    }
    
    // MARK: - EventLog Tests
    
    func test_EventLog_initialization() {
        let eventLog = EventLog(
            params: ["key": "value"],
            eventType: .create,
            message: "Test message",
            status: .success,
            platform: .database,
            userOid: "user-123"
        )
        XCTAssertNotNil(eventLog.params)
        XCTAssertEqual(eventLog.eventType, .create)
        XCTAssertEqual(eventLog.message, "Test message")
        XCTAssertEqual(eventLog.status, .success)
        XCTAssertEqual(eventLog.platform, .database)
        XCTAssertEqual(eventLog.userOid, "user-123")
    }
    
    func test_EventLog_initializationWithNils() {
        let eventLog = EventLog(
            params: nil,
            eventType: .read,
            message: nil,
            status: .failure,
            platform: .network,
            userOid: nil
        )
        XCTAssertNil(eventLog.params)
        XCTAssertEqual(eventLog.eventType, .read)
        XCTAssertNil(eventLog.message)
        XCTAssertEqual(eventLog.status, .failure)
        XCTAssertEqual(eventLog.platform, .network)
        XCTAssertNil(eventLog.userOid)
    }
    
    // MARK: - EventType Tests
    
    func test_EventType_rawValues() {
        XCTAssertEqual(EventType.create.rawValue, "create")
        XCTAssertEqual(EventType.read.rawValue, "read")
        XCTAssertEqual(EventType.update.rawValue, "update")
        XCTAssertEqual(EventType.delete.rawValue, "delete")
    }
    
    func test_EventType_eventNames() {
        XCTAssertEqual(EventType.create.eventName, "Records_iOS_SDK_CREATE")
        XCTAssertEqual(EventType.read.eventName, "Records_iOS_SDK_READ")
        XCTAssertEqual(EventType.update.eventName, "Records_iOS_SDK_UPDATE")
        XCTAssertEqual(EventType.delete.eventName, "Records_iOS_SDK_DELETE")
    }
    
    // MARK: - EventStatusMonitor Tests
    
    func test_EventStatusMonitor_rawValues() {
        XCTAssertEqual(EventStatusMonitor.success.rawValue, "success")
        XCTAssertEqual(EventStatusMonitor.failure.rawValue, "failure")
    }
    
    // MARK: - EventPlatform Tests
    
    func test_EventPlatform_rawValues() {
        XCTAssertEqual(EventPlatform.database.rawValue, "database")
        XCTAssertEqual(EventPlatform.network.rawValue, "network")
    }
}

