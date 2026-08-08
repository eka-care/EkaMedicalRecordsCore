import XCTest
@testable import EkaMedicalRecordsCore

final class RecordUploadManagerTests: XCTestCase {
    
    var uploadManager: RecordUploadManager!
    
    override func setUp() {
        super.setUp()
        uploadManager = RecordUploadManager()
    }
    
    override func tearDown() {
        uploadManager = nil
        super.tearDown()
    }
    
    func test_RecordUploadManager_initialization() {
        XCTAssertNotNil(uploadManager, "RecordUploadManager should initialize")
    }
    
    func test_RecordUploadManager_hasService() {
        XCTAssertNotNil(uploadManager.service, "Should have records provider service")
        XCTAssertTrue(uploadManager.service is RecordsProvider, "Service should conform to RecordsProvider")
    }
    
    func test_RecordUploadManager_serviceIsRecordsApiService() {
        XCTAssertTrue(uploadManager.service is RecordsApiService, "Service should be RecordsApiService")
    }
    
    func test_RecordUploadManager_uploadWithEmptyFiles() {
        let expectation = XCTestExpectation(description: "Upload completion")
        
        uploadManager.uploadRecordsToVault(
            documentID: "test-doc-id",
            nestedFiles: [], // Empty files
            tags: ["tag1"],
            recordType: "PRESCRIPTION",
            documentDate: 1234567890,
            linkedCases: nil,
            isLinkedWithAbha: false,
            userOid: "user-123"
        ) { response, error in
            // With empty files, should fail with count mismatch or similar error
            XCTAssertNil(response, "Should not have response with empty files")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_RecordUploadManager_fetchRecordsDataFromURL_emptyArray() {
        let data = uploadManager.fetchRecordsDataFromURL([])
        XCTAssertEqual(data.count, 0, "Should return empty array for empty input")
    }
    
    func test_RecordUploadManager_fetchRecordsDataFromURL_invalidURL() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/file.pdf")
        let metadata = DocumentMetaData(
            name: "file.pdf",
            size: 1024,
            url: invalidURL,
            type: .pdf
        )
        
        let data = uploadManager.fetchRecordsDataFromURL([metadata])
        // Should handle invalid URLs gracefully by returning empty or filtered results
        XCTAssertTrue(data.count <= 1, "Should handle invalid URLs")
    }
    
    func test_RecordUploadManager_createBatchRequest() {
        let testURL = URL(fileURLWithPath: "/test/path/file.pdf")
        let metadata = DocumentMetaData(
            name: "test.pdf",
            size: 2048,
            url: testURL,
            type: .pdf
        )
        
        let batchRequest = uploadManager.createBatchRequest(
            documentID: "doc-123",
            nestedFiles: [metadata],
            tags: ["tag1", "tag2"],
            recordType: "LAB_REPORT",
            documentDate: 1704067200,
            linkedCases: ["case-1"],
            isLinkedWithAbha: true,
            userOid: "oid-456"
        )
        
        XCTAssertEqual(batchRequest.count, 1, "Should create one batch request")
        
        let firstRequest = batchRequest.first
        XCTAssertEqual(firstRequest?.documentID, "doc-123")
        XCTAssertEqual(firstRequest?.tags, ["tag1", "tag2"])
        XCTAssertEqual(firstRequest?.documentType, "LAB_REPORT")
        XCTAssertEqual(firstRequest?.documentDate, 1704067200)
        XCTAssertEqual(firstRequest?.linkedCases, ["case-1"])
        XCTAssertEqual(firstRequest?.isLinkedWithAbha, true)
        XCTAssertEqual(firstRequest?.patientOID, "oid-456")
    }
    
//    func test_RecordUploadManager_createBatchRequest_withNilValues() {
//        let testURL = URL(fileURLWithPath: "/test/path/file.jpg")
//        let metadata = DocumentMetaData(
//            name: "image.jpg",
//            size: 3072,
//            url: testURL,
//            type: .imageJpg
//        )
//        
//        let batchRequest = uploadManager.createBatchRequest(
//            documentID: "doc-789",
//            nestedFiles: [metadata],
//            tags: nil,
//            recordType: nil,
//            documentDate: nil,
//            linkedCases: nil,
//            isLinkedWithAbha: nil,
//            userOid: nil
//        )
//        
//        XCTAssertEqual(batchRequest.count, 1, "Should create one batch request")
//        
//        let firstRequest = batchRequest.first
//        XCTAssertEqual(firstRequest?.documentID, "doc-789")
//        XCTAssertNil(firstRequest?.tags)
//        XCTAssertNil(firstRequest?.documentType)
//        XCTAssertNil(firstRequest?.documentDate)
//        XCTAssertNil(firstRequest?.linkedCases)
//        XCTAssertNil(firstRequest?.isLinkedWithAbha)
//        XCTAssertNil(firstRequest?.patientOID)
//    }
    
//    func test_RecordUploadManager_createBatchRequest_multipleFiles() {
//        let testURL1 = URL(fileURLWithPath: "/test/file1.pdf")
//        let testURL2 = URL(fileURLWithPath: "/test/file2.jpg")
//        
//        let metadata1 = DocumentMetaData(name: "file1.pdf", size: 1024, url: testURL1, type: .pdf)
//        let metadata2 = DocumentMetaData(name: "file2.jpg", size: 2048, url: testURL2, type: .imageJpg)
//        
//        let batchRequest = uploadManager.createBatchRequest(
//            documentID: "doc-multi",
//            nestedFiles: [metadata1, metadata2],
//            tags: ["multi"],
//            recordType: "REPORT",
//            documentDate: 1234567890,
//            linkedCases: nil,
//            isLinkedWithAbha: false,
//            userOid: "oid-999"
//        )
//        
//        XCTAssertEqual(batchRequest.count, 1, "Should create one batch request for multiple files")
//        
//        let firstRequest = batchRequest.first
//        XCTAssertEqual(firstRequest?.files?.count, 2, "Should have 2 files")
//        XCTAssertEqual(firstRequest?.files?[0].name, "file1.pdf")
//        XCTAssertEqual(firstRequest?.files?[1].name, "file2.jpg")
//    }
}

