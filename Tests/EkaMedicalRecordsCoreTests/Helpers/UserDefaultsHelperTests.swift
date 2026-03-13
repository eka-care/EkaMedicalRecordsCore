import XCTest
@testable import EkaMedicalRecordsCore

private struct Dummy: Codable, Equatable { let a: Int; let b: String }

final class UserDefaultsHelperTests: XCTestCase {
    func test_saveAndFetch_roundTrip() {
        let key = "UserDefaultsHelperTests.Dummy"
        let value = Dummy(a: 7, b: "x")
        let saved = UserDefaultsHelper.save(customValue: value, withKey: key)
        XCTAssertTrue(saved)
        let fetched: Dummy? = UserDefaultsHelper.fetch(valueOfType: Dummy.self, usingKey: key)
        XCTAssertEqual(fetched, value)
    }
}
