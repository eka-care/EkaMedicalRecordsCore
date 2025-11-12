import XCTest
@testable import EkaMedicalRecordsCore

final class DatabaseOperationTests: XCTestCase {
    
    func test_DatabaseOperation_allCases() {
        let allCases = DatabaseOperation.allCases
        XCTAssertEqual(allCases.count, 8, "Should have 8 database operations")
        
        XCTAssertTrue(allCases.contains(.upsertRecords))
        XCTAssertTrue(allCases.contains(.addSingleRecord))
        XCTAssertTrue(allCases.contains(.addRecordMetaData))
        XCTAssertTrue(allCases.contains(.addSmartReport))
        XCTAssertTrue(allCases.contains(.cleanupOrphanedTags))
        XCTAssertTrue(allCases.contains(.updateRecord))
        XCTAssertTrue(allCases.contains(.deleteRecords))
        XCTAssertTrue(allCases.contains(.deleteRecord))
    }
    
    func test_DatabaseOperation_rawValues() {
        XCTAssertEqual(DatabaseOperation.upsertRecords.rawValue, "upsertRecords")
        XCTAssertEqual(DatabaseOperation.addSingleRecord.rawValue, "addSingleRecord")
        XCTAssertEqual(DatabaseOperation.addRecordMetaData.rawValue, "addRecordMetaData")
        XCTAssertEqual(DatabaseOperation.addSmartReport.rawValue, "addSmartReport")
        XCTAssertEqual(DatabaseOperation.cleanupOrphanedTags.rawValue, "cleanupOrphanedTags")
        XCTAssertEqual(DatabaseOperation.updateRecord.rawValue, "updateRecord")
        XCTAssertEqual(DatabaseOperation.deleteRecords.rawValue, "deleteRecords")
        XCTAssertEqual(DatabaseOperation.deleteRecord.rawValue, "deleteRecord")
    }
    
    func test_DatabaseOperation_description() {
        XCTAssertEqual(DatabaseOperation.upsertRecords.description, "upsertRecords")
        XCTAssertEqual(DatabaseOperation.addSingleRecord.description, "addSingleRecord")
        XCTAssertEqual(DatabaseOperation.addRecordMetaData.description, "addRecordMetaData")
        XCTAssertEqual(DatabaseOperation.addSmartReport.description, "addSmartReport")
        XCTAssertEqual(DatabaseOperation.cleanupOrphanedTags.description, "cleanupOrphanedTags")
        XCTAssertEqual(DatabaseOperation.updateRecord.description, "updateRecord")
        XCTAssertEqual(DatabaseOperation.deleteRecords.description, "deleteRecords")
        XCTAssertEqual(DatabaseOperation.deleteRecord.description, "deleteRecord")
    }
    
    func test_RecordsDatabaseVersion_containerName() {
        XCTAssertEqual(RecordsDatabaseVersion.containerName, "EkaMedicalRecordsCoreSdkV2")
    }
}

