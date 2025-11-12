import XCTest
@testable import EkaMedicalRecordsCore

final class CaseModelAndAdapterTests: XCTestCase {
    // MARK: - CaseArguementModel Tests
    
    func test_CaseArguementModel_initialization() {
        let model = CaseArguementModel(
            caseId: "case-123",
            caseType: "treatment",
            oid: "oid-456",
            createdAt: Date(),
            name: "Surgery Case",
            updatedAt: Date(),
            occuredAt: Date(),
            isRemoteCreated: true,
            isEdited: false,
            status: .active
        )
        XCTAssertEqual(model.caseId, "case-123")
        XCTAssertEqual(model.caseType, "treatment")
        XCTAssertEqual(model.oid, "oid-456")
        XCTAssertEqual(model.name, "Surgery Case")
        XCTAssertTrue(model.isRemoteCreated ?? false)
        XCTAssertFalse(model.isEdited ?? true)
        XCTAssertEqual(model.status, .active)
    }
    
    func test_CaseArguementModel_defaultInitialization() {
        let model = CaseArguementModel()
        XCTAssertNil(model.caseId)
        XCTAssertNil(model.caseType)
        XCTAssertNil(model.oid)
        XCTAssertFalse(model.isRemoteCreated ?? true)
        XCTAssertFalse(model.isEdited ?? true)
    }
    
    // MARK: - CaseStatus Tests
    
    func test_CaseStatus_rawValues() {
        XCTAssertEqual(CaseStatus.active.rawValue, "A")
        XCTAssertEqual(CaseStatus.deleted.rawValue, "D")
    }
    
    func test_CaseStatus_decoding() throws {
        let jsonActive = "\"A\"".data(using: .utf8)!
        let active = try JSONDecoder().decode(CaseStatus.self, from: jsonActive)
        XCTAssertEqual(active, .active)
        
        let jsonDeleted = "\"D\"".data(using: .utf8)!
        let deleted = try JSONDecoder().decode(CaseStatus.self, from: jsonDeleted)
        XCTAssertEqual(deleted, .deleted)
    }
    
    func test_CaseStatus_encoding() throws {
        let active = CaseStatus.active
        let encoded = try JSONEncoder().encode(active)
        let decoded = try JSONDecoder().decode(CaseStatus.self, from: encoded)
        XCTAssertEqual(decoded, .active)
    }
    
    // MARK: - CasesListFetchResponse Tests
    
    func test_CasesListFetchResponse_decoding() throws {
        let json = """
        {
          "cases": [
            {
              "id": "case-1",
              "status": "A",
              "updated_at": 1726000000,
              "item": {
                "display_name": "Test Case",
                "type": "treatment",
                "hi_type": "OPConsultation",
                "created_at": 1726000000,
                "occurred_at": 1726000000
              }
            }
          ],
          "next_token": "token-123"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CasesListFetchResponse.self, from: json)
        XCTAssertEqual(decoded.cases.count, 1)
        XCTAssertEqual(decoded.cases.first?.id, "case-1")
        XCTAssertEqual(decoded.cases.first?.status, .active)
        XCTAssertEqual(decoded.nextToken, "token-123")
    }
    
    // MARK: - CaseElement Tests
    
    func test_CaseElement_decoding() throws {
        let json = """
        {
          "id": "case-456",
          "status": "D",
          "updated_at": 1600000000,
          "item": {
            "display_name": "Old Case",
            "type": "consultation"
          }
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CaseElement.self, from: json)
        XCTAssertEqual(decoded.id, "case-456")
        XCTAssertEqual(decoded.status, .deleted)
        XCTAssertEqual(decoded.updatedAt, 1600000000)
        XCTAssertEqual(decoded.item?.displayName, "Old Case")
        XCTAssertEqual(decoded.item?.type, "consultation")
    }
    
    // MARK: - Item Tests
    
    func test_Item_decoding() throws {
        let json = """
        {
          "display_name": "Test Item",
          "type": "surgery",
          "hi_type": "IPAdmission",
          "created_at": 1726000000,
          "occurred_at": 1725000000
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Item.self, from: json)
        XCTAssertEqual(decoded.displayName, "Test Item")
        XCTAssertEqual(decoded.type, "surgery")
        XCTAssertEqual(decoded.hiType, "IPAdmission")
        XCTAssertEqual(decoded.createdAt, 1726000000)
        XCTAssertEqual(decoded.occuredAt, 1725000000)
    }
    
    func test_Item_decodingPartial() throws {
        let json = """
        {
          "display_name": "Minimal Item"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Item.self, from: json)
        XCTAssertEqual(decoded.displayName, "Minimal Item")
        XCTAssertNil(decoded.type)
        XCTAssertNil(decoded.hiType)
        XCTAssertNil(decoded.createdAt)
    }
}

