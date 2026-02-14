import XCTest
@testable import EkaMedicalRecordsCore

final class RecordModelAndAdapterTests: XCTestCase {
    // MARK: - RecordModel Tests
    
    func test_RecordModel_initialization() {
        let model = RecordModel(
            documentDate: Date(),
            documentHash: "hash-123",
            documentType: "LAB",
            syncState: .uploading,
            isAnalyzing: false,
            isSmart: true,
            oid: "oid-123",
            thumbnail: "thumb.jpg",
            updatedAt: Date(),
            uploadDate: Date(),
            documentURIs: ["/path/to/file"],
            contentType: ".pdf",
            isEdited: false,
            caseModels: nil,
            caseIDs: ["case-1"],
            tags: ["urgent"]
        )
        XCTAssertNotNil(model.documentID) // UUID generated
        XCTAssertEqual(model.documentType, "LAB")
        XCTAssertEqual(model.oid, "oid-123")
        XCTAssertEqual(model.caseIDs?.count, 1)
        XCTAssertEqual(model.tags?.count, 1)
    }
    
    // MARK: - RecordSyncState Tests
    
    func test_RecordSyncState_stringValue() {
        XCTAssertEqual(RecordSyncState.uploading.stringValue, "uploading")
        XCTAssertEqual(RecordSyncState.upload(success: true).stringValue, "upload_success")
        XCTAssertEqual(RecordSyncState.upload(success: false).stringValue, "upload_failure")
    }
    
    func test_RecordSyncState_initFromString() {
        XCTAssertEqual(RecordSyncState(from: "uploading"), .uploading)
        XCTAssertEqual(RecordSyncState(from: "upload_success"), .upload(success: true))
        XCTAssertEqual(RecordSyncState(from: "upload_failure"), .upload(success: false))
        XCTAssertNil(RecordSyncState(from: "invalid"))
    }
    
    func test_RecordSyncState_equatable() {
        XCTAssertEqual(RecordSyncState.uploading, RecordSyncState.uploading)
        XCTAssertEqual(RecordSyncState.upload(success: true), RecordSyncState.upload(success: true))
        XCTAssertEqual(RecordSyncState.upload(success: false), RecordSyncState.upload(success: false))
        XCTAssertNotEqual(RecordSyncState.uploading, RecordSyncState.upload(success: true))
        XCTAssertNotEqual(RecordSyncState.upload(success: true), RecordSyncState.upload(success: false))
    }
    
    // MARK: - RecordDatabaseAdapter Tests
    
    func test_RecordDatabaseAdapter_serializeSmartReportInfo() {
        let adapter = RecordDatabaseAdapter()
        let smartReport = SmartReportInfo(
          verified: [Verified( name: "Glucose",value: "100", vitalID: "v1")],
            unverified: nil
        )
        let data = adapter.serializeSmartReportInfo(smartReport: smartReport)
        XCTAssertNotNil(data)
    }
    
    func test_RecordDatabaseAdapter_serializeSmartReportInfo_nil() {
        let adapter = RecordDatabaseAdapter()
        let data = adapter.serializeSmartReportInfo(smartReport: nil)
        XCTAssertNil(data)
    }
    
    func test_RecordDatabaseAdapter_deserializeSmartReportInfo() {
        let adapter = RecordDatabaseAdapter()
        let smartReport = SmartReportInfo(
          verified: [Verified(name: "Glucose",value: "100", vitalID: "v1")],
            unverified: nil
        )
        let data = adapter.serializeSmartReportInfo(smartReport: smartReport)
        let deserialized = adapter.deserializeSmartReportInfo(data: data)
        XCTAssertNotNil(deserialized)
        XCTAssertEqual(deserialized?.verified?.count, 1)
        XCTAssertEqual(deserialized?.verified?.first?.vitalID, "v1")
    }
    
    func test_RecordDatabaseAdapter_deserializeSmartReportInfo_nil() {
        let adapter = RecordDatabaseAdapter()
        let deserialized = adapter.deserializeSmartReportInfo(data: nil)
        XCTAssertNil(deserialized)
    }
    
    func test_RecordDatabaseAdapter_deserializeSmartReportInfo_invalidData() {
        let adapter = RecordDatabaseAdapter()
        let invalidData = "invalid".data(using: .utf8)!
        let deserialized = adapter.deserializeSmartReportInfo(data: invalidData)
        XCTAssertNil(deserialized)
    }
    
//    func test_RecordSyncState_equality() {
//        XCTAssertEqual(RecordSyncState.notSynced, RecordSyncState.notSynced)
//        XCTAssertEqual(RecordSyncState.syncing, RecordSyncState.syncing)
//        XCTAssertEqual(RecordSyncState.synced, RecordSyncState.synced)
//        
//        XCTAssertNotEqual(RecordSyncState.notSynced, RecordSyncState.syncing)
//        XCTAssertNotEqual(RecordSyncState.syncing, RecordSyncState.synced)
//        XCTAssertNotEqual(RecordSyncState.notSynced, RecordSyncState.synced)
//    }
//    
//    func test_RecordSyncState_hashable() {
//        var stateSet = Set<RecordSyncState>()
//        stateSet.insert(.notSynced)
//        stateSet.insert(.syncing)
//        stateSet.insert(.synced)
//        stateSet.insert(.notSynced) // Duplicate
//        
//        XCTAssertEqual(stateSet.count, 3, "Set should contain only unique states")
//        XCTAssertTrue(stateSet.contains(.notSynced))
//        XCTAssertTrue(stateSet.contains(.syncing))
//        XCTAssertTrue(stateSet.contains(.synced))
//    }
}

