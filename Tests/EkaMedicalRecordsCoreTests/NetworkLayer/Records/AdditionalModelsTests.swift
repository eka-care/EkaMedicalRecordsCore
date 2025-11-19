import XCTest
@testable import EkaMedicalRecordsCore

final class AdditionalModelsTests: XCTestCase {
    
    // MARK: - DocsListFetchResponse Tests
    
    func test_DocsListFetchResponse_decoding() throws {
        let json = """
        {
          "items": [
            {
              "record": {
                "item": {
                  "document_id": "doc-1",
                  "upload_date": 1726000000,
                  "document_type": "LAB",
                  "patient_id": "patient-123",
                  "u_at": 1726000100
                }
              }
            }
          ],
          "next_token": "token-abc",
          "source_refreshed_at": 1726000200
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocsListFetchResponse.self, from: json)
        XCTAssertEqual(decoded.items.count, 1)
        XCTAssertEqual(decoded.nextToken, "token-abc")
        XCTAssertEqual(decoded.sourceRefreshedAt, 1726000200)
        XCTAssertEqual(decoded.items.first?.recordDocument.item.documentID, "doc-1")
    }
    
    func test_RecordItem_decodingWithMetadata() throws {
        let json = """
        {
          "document_id": "doc-456",
          "upload_date": 1600000000,
          "document_type": "PRESCRIPTION",
          "metadata": {
            "thumbnail": "thumb.jpg",
            "document_date": 1600000000,
            "tags": ["urgent", "followup"],
            "auto_tags": ["1"],
            "title": "Medical Report"
          },
          "patient_id": "patient-456",
          "u_at": 1600000100,
          "cases": ["case-1", "case-2"]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(RecordItem.self, from: json)
        XCTAssertEqual(decoded.documentID, "doc-456")
        XCTAssertEqual(decoded.documentType, "PRESCRIPTION")
        XCTAssertEqual(decoded.metadata?.tags?.count, 2)
        XCTAssertEqual(decoded.metadata?.title, "Medical Report")
        XCTAssertEqual(decoded.cases?.count, 2)
    }
    
    func test_Metadata_decodingWithAbha() throws {
        let json = """
        {
          "thumbnail": "thumb.png",
          "document_date": 1726000000,
          "tags": ["test"],
          "auto_tags": ["1", "2"],
          "title": "Lab Report",
          "abha": {
            "health_id": "abha-123",
            "link_status": "linked"
          }
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(Metadata.self, from: json)
        XCTAssertEqual(decoded.thumbnail, "thumb.png")
        XCTAssertEqual(decoded.title, "Lab Report")
        XCTAssertEqual(decoded.abha?.healthID, "abha-123")
        XCTAssertEqual(decoded.abha?.linkStatus, "linked")
    }
    
    // MARK: - DocUpdateRequest Tests
    
    func test_DocUpdateRequest_encoding() throws {
        let request = DocUpdateRequest(
            oid: "oid-123",
            documentType: "LAB",
            documentDate: 1726000000,
            cases: ["case-1"],
            tags: ["urgent"]
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        
        XCTAssertEqual(json?["oid"] as? String, "oid-123")
        XCTAssertEqual(json?["dt"] as? String, "LAB")
        XCTAssertEqual(json?["dd_e"] as? Int, 1726000000)
        XCTAssertNotNil(json?["cases"])
        XCTAssertNotNil(json?["tg"])
    }
    
    func test_DocUpdateRequest_decoding() throws {
        let json = """
        {
          "oid": "oid-456",
          "dt": "PRESCRIPTION",
          "dd_e": 1600000000,
          "cases": ["case-2", "case-3"],
          "tg": ["followup", "urgent"]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUpdateRequest.self, from: json)
        XCTAssertEqual(decoded.oid, "oid-456")
        XCTAssertEqual(decoded.documentType, "PRESCRIPTION")
        XCTAssertEqual(decoded.documentDate, 1600000000)
        XCTAssertEqual(decoded.cases?.count, 2)
        XCTAssertEqual(decoded.tags?.count, 2)
    }
    
    // MARK: - DocUploadRequest Tests
    
    func test_DocUploadRequest_BatchRequest_initialization() {
        let batchRequest = DocUploadRequest.BatchRequest(
            documentID: "doc-789",
            documentType: "LAB",
            documentDate: 1726000000,
            patientOID: "patient-789",
            cases: ["case-1"],
            tags: ["urgent"],
            files: [
                DocUploadRequest.FileMetaData(contentType: "application/pdf", fileSize: 1024)
            ]
        )
        
        XCTAssertEqual(batchRequest.documentID, "doc-789")
        XCTAssertEqual(batchRequest.documentType, "LAB")
        XCTAssertEqual(batchRequest.patientOID, "patient-789")
        XCTAssertEqual(batchRequest.files?.count, 1)
    }
    
    func test_DocUploadRequest_encoding() throws {
        let fileMetaData = DocUploadRequest.FileMetaData(contentType: "application/pdf", fileSize: 2048)
        let batchRequest = DocUploadRequest.BatchRequest(
            documentID: "doc-upload-1",
            documentType: "PRESCRIPTION",
            documentDate: 1726000000,
            patientOID: "patient-upload-1",
            cases: nil,
            tags: ["test"],
            files: [fileMetaData]
        )
        let request = DocUploadRequest(batchRequest: [batchRequest])
        
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        
        XCTAssertNotNil(json?["batch_request"])
        let batchArray = json?["batch_request"] as? [[String: Any]]
        XCTAssertEqual(batchArray?.count, 1)
        XCTAssertEqual(batchArray?.first?["document_id"] as? String, "doc-upload-1")
    }
    
    func test_DocUploadRequest_FileMetaData_encoding() throws {
        let fileMetaData = DocUploadRequest.FileMetaData(contentType: "image/jpeg", fileSize: 512)
        let encoded = try JSONEncoder().encode(fileMetaData)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        
        XCTAssertEqual(json?["contentType"] as? String, "image/jpeg")
        XCTAssertEqual(json?["file_size"] as? Int, 512)
    }
    
    // MARK: - RecordUploadErrorType Tests
    
    func test_RecordUploadErrorType_errorDescriptions() {
        XCTAssertEqual(
            RecordUploadErrorType.failedToUploadFiles.errorDescription,
            "Failed to Upload Files"
        )
        XCTAssertEqual(
            RecordUploadErrorType.emptyFormResponse.errorDescription,
            "Empty form response"
        )
        XCTAssertEqual(
            RecordUploadErrorType.recordCountMetaDataMismatch.errorDescription,
            "Record Count meta data mismatch"
        )
    }
    
    // MARK: - Abha Tests
    
    func test_Abha_decoding() throws {
        let json = """
        {
          "health_id": "abha-456",
          "link_status": "pending"
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(Abha.self, from: json)
        XCTAssertEqual(decoded.healthID, "abha-456")
        XCTAssertEqual(decoded.linkStatus, "pending")
    }
    
    func test_Abha_encoding() throws {
        let abha = Abha(healthID: "abha-789", linkStatus: "linked")
        let encoded = try JSONEncoder().encode(abha)
        let decoded = try JSONDecoder().decode(Abha.self, from: encoded)
        
        XCTAssertEqual(decoded.healthID, "abha-789")
        XCTAssertEqual(decoded.linkStatus, "linked")
    }
}

