import XCTest
@testable import EkaMedicalRecordsCore

final class CasesModelsTests: XCTestCase {
    // MARK: - CasesCreateRequest Tests
    
    func test_CasesCreateRequest_encoding() throws {
        let request = CasesCreateRequest(
            id: "case-123",
            displayName: "Surgery Case",
            hiType: "OPConsultation",
            occurredAt: 1726000000,
            type: "treatment",
            partnerMeta: PartnerMeta(facilityID: "fac-1", uhid: "uhid-1")
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertEqual(json?["id"] as? String, "case-123")
        XCTAssertEqual(json?["display_name"] as? String, "Surgery Case")
        XCTAssertEqual(json?["hi_type"] as? String, "OPConsultation")
        XCTAssertEqual(json?["occurred_at"] as? Int, 1726000000)
        XCTAssertEqual(json?["type"] as? String, "treatment")
        XCTAssertNotNil(json?["partner_meta"])
    }
    
    func test_CasesCreateRequest_decoding() throws {
        let json = """
        {
          "id": "case-456",
          "display_name": "Test Case",
          "hi_type": "Wellness",
          "occurred_at": 1600000000,
          "type": "consultation"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CasesCreateRequest.self, from: json)
        XCTAssertEqual(decoded.id, "case-456")
        XCTAssertEqual(decoded.displayName, "Test Case")
        XCTAssertEqual(decoded.hiType, "Wellness")
        XCTAssertEqual(decoded.occurredAt, 1600000000)
        XCTAssertEqual(decoded.type, "consultation")
        XCTAssertNil(decoded.partnerMeta)
    }
    
    // MARK: - PartnerMeta Tests
    
    func test_PartnerMeta_encoding() throws {
        let meta = PartnerMeta(facilityID: "facility-789", uhid: "uhid-999")
        let encoded = try JSONEncoder().encode(meta)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertEqual(json?["facility_id"] as? String, "facility-789")
        XCTAssertEqual(json?["uhid"] as? String, "uhid-999")
    }
    
    func test_PartnerMeta_decoding() throws {
        let json = """
        {
          "facility_id": "fac-abc",
          "uhid": "uhid-xyz"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PartnerMeta.self, from: json)
        XCTAssertEqual(decoded.facilityID, "fac-abc")
        XCTAssertEqual(decoded.uhid, "uhid-xyz")
    }
    
    // MARK: - CasesCreateResponse Tests
    
    func test_CasesCreateResponse_decoding() throws {
        let json = """
        {
          "id": "response-case-id"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CasesCreateResponse.self, from: json)
        XCTAssertEqual(decoded.id, "response-case-id")
    }
    
    // MARK: - CasesUpdateRequest Tests
    
    func test_CasesUpdateRequest_encoding() throws {
        let request = CasesUpdateRequest(
            displayName: "Updated Case Name",
            type: "follow-up",
            hiType: "OPConsultation"
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertEqual(json?["display_name"] as? String, "Updated Case Name")
        XCTAssertEqual(json?["type"] as? String, "follow-up")
        XCTAssertEqual(json?["hi_type"] as? String, "OPConsultation")
    }
    
    func test_CasesUpdateRequest_decoding() throws {
        let json = """
        {
          "display_name": "New Name",
          "type": "emergency"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CasesUpdateRequest.self, from: json)
        XCTAssertEqual(decoded.displayName, "New Name")
        XCTAssertEqual(decoded.type, "emergency")
        XCTAssertNil(decoded.hiType)
    }
    
    func test_CasesUpdateRequest_allNil() throws {
        let request = CasesUpdateRequest(displayName: nil, type: nil, hiType: nil)
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertTrue(json?.isEmpty ?? false)
    }
}

