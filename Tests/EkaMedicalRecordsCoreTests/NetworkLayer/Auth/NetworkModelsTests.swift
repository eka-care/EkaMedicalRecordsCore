import XCTest
@testable import EkaMedicalRecordsCore

final class NetworkModelsTests: XCTestCase {
    // MARK: - EkaFileMimeType Tests
    
    func test_EkaFileMimeType_rawValues() {
        XCTAssertEqual(EkaFileMimeType.imageJpg.rawValue, "image/jpeg")
        XCTAssertEqual(EkaFileMimeType.pdf.rawValue, "application/pdf")
        XCTAssertEqual(EkaFileMimeType.audio.rawValue, "audio/aac")
        XCTAssertEqual(EkaFileMimeType.video.rawValue, "video/mp4")
    }
    
    func test_EkaFileMimeType_uiHelperValue() {
        XCTAssertEqual(EkaFileMimeType.imageJpg.uiHelperValue, "imageJpg")
        XCTAssertEqual(EkaFileMimeType.pdf.uiHelperValue, "pdf")
        XCTAssertEqual(EkaFileMimeType.audio.uiHelperValue, "audio")
        XCTAssertEqual(EkaFileMimeType.video.uiHelperValue, "video")
    }
    
    func test_EkaFileMimeType_fileExtension() {
        XCTAssertEqual(EkaFileMimeType.imageJpg.fileExtension, ".jpg")
        XCTAssertEqual(EkaFileMimeType.pdf.fileExtension, ".pdf")
        XCTAssertEqual(EkaFileMimeType.audio.fileExtension, ".m4a")
        XCTAssertEqual(EkaFileMimeType.video.fileExtension, ".mp4")
    }
    
    // MARK: - RecordDocumentTagType Tests
    
    func test_RecordDocumentTagType_networkName() {
        XCTAssertEqual(RecordDocumentTagType.smartTag.networkName, "1")
    }
    
    // MARK: - RefreshRequest Tests
    
    func test_RefreshRequest_encoding() throws {
        let request = RefreshRequest(refresh: "refresh-token", sess: "access-token")
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertEqual(json?["refresh_token"] as? String, "refresh-token")
        XCTAssertEqual(json?["access_token"] as? String, "access-token")
    }
    
    func test_RefreshRequest_decoding() throws {
        let json = """
        {
          "refresh_token": "refresh-123",
          "access_token": "access-456"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(RefreshRequest.self, from: json)
        XCTAssertEqual(decoded.refresh, "refresh-123")
        XCTAssertEqual(decoded.sess, "access-456")
    }
    
    // MARK: - RefreshResponse Tests
    
    func test_RefreshResponse_decoding() throws {
        let json = """
        {
          "access_token": "new-access-token",
          "expires_in": 3600,
          "refresh_expires_in": 7200,
          "refresh_token": "new-refresh-token"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: json)
        XCTAssertEqual(decoded.accessToken, "new-access-token")
        XCTAssertEqual(decoded.expiresIn, 3600)
        XCTAssertEqual(decoded.refreshExpiresIn, 7200)
        XCTAssertEqual(decoded.refreshToken, "new-refresh-token")
    }
    
    func test_RefreshResponse_decodingPartial() throws {
        let json = """
        {
          "access_token": "token"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: json)
        XCTAssertEqual(decoded.accessToken, "token")
        XCTAssertNil(decoded.expiresIn)
        XCTAssertNil(decoded.refreshToken)
    }
}

