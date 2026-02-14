import XCTest
@testable import EkaMedicalRecordsCore

final class ModelsDecodingTests: XCTestCase {
    func test_decode_DocFetchResponse_minimal() throws {
        let json = """
        {
          "document_id": "doc-1",
          "document_type": "LAB",
          "files": [
            { "asset_url": "https://example.com/a.pdf", "file_type": "pdf" }
          ]
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(DocFetchResponse.self, from: json)
        XCTAssertEqual(decoded.documentID, "doc-1")
        XCTAssertEqual(decoded.documentType, "LAB")
        XCTAssertEqual(decoded.files?.count, 1)
        XCTAssertEqual(decoded.files?.first?.assetURL, "https://example.com/a.pdf")
    }

    func test_verified_hashAndEquality_useVitalID() {
        let a = Verified(name: "Glucose", value: "100", vitalID: "v1")
        let b = Verified(name: "Hemoglobin", value: "15", vitalID: "v1")
        let c = Verified(name: "Glucose", value: "120", vitalID: "v2")
        // Equality and hash are based on vitalID only
        XCTAssertEqual(a, b) // Same vitalID
        XCTAssertNotEqual(a, c) // Different vitalID
        
        // Test Set behavior (uses hash)
        var set: Set<Verified> = []
        set.insert(a)
        set.insert(b) // Same vitalID, should not add
        XCTAssertEqual(set.count, 1, "Set should contain only 1 item since vitalID is same")
        set.insert(c) // Different vitalID, should add
        XCTAssertEqual(set.count, 2, "Set should contain 2 items with different vitalIDs")
    }

    func test_coordinate_hashable() {
        let c1 = Coordinate(x: 1.0, y: 2.0)
        let c2 = Coordinate(x: 1.0, y: 2.0)
        XCTAssertEqual(c1, c2)
        var set = Set<Coordinate>()
        set.insert(c1)
        set.insert(c2)
        XCTAssertEqual(set.count, 1)
    }
}
