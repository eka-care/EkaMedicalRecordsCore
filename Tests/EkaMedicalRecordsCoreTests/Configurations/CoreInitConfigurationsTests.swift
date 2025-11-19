import XCTest
@testable import EkaMedicalRecordsCore

final class CoreInitConfigurationsTests: XCTestCase {
    func test_blockedFeatureTypes_mapping() {
        let config = CoreInitConfigurations.shared
        config.blockedFeatures = [
            "UPLOAD_MEDICAL_RECORDS",
            "CREATE_MEDICAL_RECORDS_CASES",
            "UNKNOWN"
        ]
        let types = config.blockedFeatureTypes
        XCTAssertTrue(types.contains(.uploadRecords))
        XCTAssertTrue(types.contains(.createMedicalRecordsCases))
        XCTAssertEqual(types.count, 2) // UNKNOWN filtered out
    }

    func test_authToken_sideEffect_to_AuthTokenHolder() {
        let config = CoreInitConfigurations.shared
        config.authToken = "token-abc"
        config.refreshToken = "refresh-xyz"
        XCTAssertEqual(AuthTokenHolder.shared.authToken, "token-abc")
        XCTAssertEqual(AuthTokenHolder.shared.refreshToken, "refresh-xyz")
    }
}
