import XCTest
@testable import EkaMedicalRecordsCore

final class StringExtensionTests: XCTestCase {
    func test_epochStringToDate_valid() {
        let epoch = "1726000000" // deterministic epoch
        let date = "".epochStringToDate(epoch)
        XCTAssertNotNil(date)
        XCTAssertEqual(Int(date!.timeIntervalSince1970), 1_726_000_000)
    }

    func test_epochStringToDate_invalid() {
        let invalid = "abc"
        XCTAssertNil("".epochStringToDate(invalid))
    }
}
