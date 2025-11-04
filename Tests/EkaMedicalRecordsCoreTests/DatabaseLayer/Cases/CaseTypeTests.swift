import XCTest
@testable import EkaMedicalRecordsCore

final class CaseTypeTests: XCTestCase {
    func test_CaseTypeModel_initialization() {
        let model = CaseTypeModel(name: "Surgery")
        XCTAssertEqual(model.name, "Surgery")
    }
    
    func test_CaseTypeModel_withDifferentNames() {
        let consultation = CaseTypeModel(name: "Consultation")
        let treatment = CaseTypeModel(name: "Treatment")
        let followup = CaseTypeModel(name: "Follow-up")
        
        XCTAssertEqual(consultation.name, "Consultation")
        XCTAssertEqual(treatment.name, "Treatment")
        XCTAssertEqual(followup.name, "Follow-up")
    }
}

