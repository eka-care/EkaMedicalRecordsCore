import XCTest
@testable import EkaMedicalRecordsCore

final class IntExtensionTests: XCTestCase {
    func test_toDate_roundTripWithEpoch() {
        let epoch = 1_726_000_000
        let date = epoch.toDate()
        XCTAssertEqual(Int(date.timeIntervalSince1970), epoch)
    }
}
