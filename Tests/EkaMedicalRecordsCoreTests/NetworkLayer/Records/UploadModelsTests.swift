import XCTest
@testable import EkaMedicalRecordsCore

final class UploadModelsTests: XCTestCase {
    
    // MARK: - DocUploadFormsResponse Tests
    
    func test_DocUploadFormsResponse_decoding() throws {
        let json = """
        {
          "error": false,
          "message": "Upload successful",
          "batch_response": [
            {
              "document_id": "doc-upload-123",
              "forms": [
                {
                  "url": "https://upload.example.com",
                  "fields": {
                    "key": "uploads/file.pdf",
                    "policy": "base64policy"
                  }
                }
              ]
            }
          ],
          "token": "auth-token-abc"
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUploadFormsResponse.self, from: json)
        XCTAssertEqual(decoded.error, false)
        XCTAssertEqual(decoded.message, "Upload successful")
        XCTAssertEqual(decoded.batchResponses?.count, 1)
        XCTAssertEqual(decoded.batchResponses?.first?.documentID, "doc-upload-123")
        XCTAssertEqual(decoded.token, "auth-token-abc")
    }
    
    func test_BatchResponse_decodingWithError() throws {
        let json = """
        {
          "document_id": "doc-error-456",
          "error_details": {
            "message": "Document already exists",
            "code": "409"
          }
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUploadFormsResponse.BatchResponse.self, from: json)
        XCTAssertEqual(decoded.documentID, "doc-error-456")
        XCTAssertEqual(decoded.errorDetails?.message, "Document already exists")
        XCTAssertEqual(decoded.errorDetails?.code, "409")
        XCTAssertNil(decoded.forms)
    }
    
    func test_BatchResponse_decodingWithForms() throws {
        let json = """
        {
          "document_id": "doc-789",
          "forms": [
            {
              "url": "https://s3.amazonaws.com/upload",
              "fields": {
                "AWSAccessKeyId": "key123",
                "policy": "policy456",
                "signature": "sig789"
              }
            }
          ]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUploadFormsResponse.BatchResponse.self, from: json)
        XCTAssertEqual(decoded.documentID, "doc-789")
        XCTAssertEqual(decoded.forms?.count, 1)
        XCTAssertEqual(decoded.forms?.first?.url, "https://s3.amazonaws.com/upload")
        XCTAssertEqual(decoded.forms?.first?.fields?["AWSAccessKeyId"], "key123")
        XCTAssertNil(decoded.errorDetails)
    }
    
    func test_Form_decoding() throws {
        let json = """
        {
          "url": "https://upload.server.com/endpoint",
          "fields": {
            "key": "path/to/file",
            "Content-Type": "application/pdf",
            "acl": "private"
          }
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUploadFormsResponse.Form.self, from: json)
        XCTAssertEqual(decoded.url, "https://upload.server.com/endpoint")
        XCTAssertEqual(decoded.fields?["key"], "path/to/file")
        XCTAssertEqual(decoded.fields?["Content-Type"], "application/pdf")
        XCTAssertEqual(decoded.fields?["acl"], "private")
    }
    
    func test_ErrorDetails_decoding() throws {
        let json = """
        {
          "message": "Invalid file format",
          "code": "400"
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(DocUploadFormsResponse.ErrorDetails.self, from: json)
        XCTAssertEqual(decoded.message, "Invalid file format")
        XCTAssertEqual(decoded.code, "400")
    }
    
    // MARK: - DocumentMetaData Tests
    
    func test_DocumentMetaData_initialization() {
        let url = URL(fileURLWithPath: "/path/to/document.pdf")
        let metadata = DocumentMetaData(
            name: "document.pdf",
            size: 2048,
            url: url,
            type: .pdf
        )
        
        XCTAssertEqual(metadata.name, "document.pdf")
        XCTAssertEqual(metadata.size, 2048)
        XCTAssertEqual(metadata.url, url)
        XCTAssertEqual(metadata.type, .pdf)
    }
    
    func test_DocumentMetaData_equality_sameNameAndURL() {
        let url = URL(fileURLWithPath: "/path/to/file.jpg")
        let metadata1 = DocumentMetaData(name: "file.jpg", size: 1024, url: url, type: .imageJpg)
        let metadata2 = DocumentMetaData(name: "file.jpg", size: 2048, url: url, type: .imageJpg)
        
        XCTAssertEqual(metadata1, metadata2, "Should be equal based on name, url, and type")
    }
    
    func test_DocumentMetaData_equality_differentName() {
        let url = URL(fileURLWithPath: "/path/to/file.pdf")
        let metadata1 = DocumentMetaData(name: "file1.pdf", size: 1024, url: url, type: .pdf)
        let metadata2 = DocumentMetaData(name: "file2.pdf", size: 1024, url: url, type: .pdf)
        
        XCTAssertNotEqual(metadata1, metadata2, "Should not be equal with different names")
    }
    
    func test_DocumentMetaData_equality_differentURL() {
        let url1 = URL(fileURLWithPath: "/path1/file.pdf")
        let url2 = URL(fileURLWithPath: "/path2/file.pdf")
        let metadata1 = DocumentMetaData(name: "file.pdf", size: 1024, url: url1, type: .pdf)
        let metadata2 = DocumentMetaData(name: "file.pdf", size: 1024, url: url2, type: .pdf)
        
        XCTAssertNotEqual(metadata1, metadata2, "Should not be equal with different URLs")
    }
    
    func test_DocumentMetaData_equality_differentType() {
        let url = URL(fileURLWithPath: "/path/file")
        let metadata1 = DocumentMetaData(name: "file", size: 1024, url: url, type: .pdf)
        let metadata2 = DocumentMetaData(name: "file", size: 1024, url: url, type: .imageJpg)
        
        XCTAssertNotEqual(metadata1, metadata2, "Should not be equal with different types")
    }
    
    func test_DocumentMetaData_nilSize() {
        let url = URL(fileURLWithPath: "/path/to/file.mp4")
        let metadata = DocumentMetaData(name: "file.mp4", size: nil, url: url, type: .video)
        
        XCTAssertEqual(metadata.name, "file.mp4")
        XCTAssertNil(metadata.size)
        XCTAssertEqual(metadata.type, .video)
    }
}

