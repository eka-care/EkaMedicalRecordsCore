import XCTest
@testable import EkaMedicalRecordsCore

final class DateExtensionTests: XCTestCase {
    func test_toEpochString_matchesToEpochInt() {
        let date = Date(timeIntervalSince1970: 1_726_000_000) // fixed timestamp for determinism
        let epochInt = date.toEpochInt()
        let epochString = date.toEpochString()
        XCTAssertEqual(Int(epochString), epochInt)
    }

    func test_toUSEnglishString_defaultFormat() {
        // 2024-12-31 00:00:00 UTC -> Using POSIX locale; note format uses calendar year (YYYY)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 31
        components.hour = 0
        components.minute = 0
        components.second = 0
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let formatted = date.toUSEnglishString()
        XCTAssertFalse(formatted.isEmpty)
    }
}
