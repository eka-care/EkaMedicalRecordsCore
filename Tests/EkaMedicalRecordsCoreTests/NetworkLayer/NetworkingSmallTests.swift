import XCTest
@testable import EkaMedicalRecordsCore

final class NetworkingSmallTests: XCTestCase {
    func test_downloadError_description() {
        let error = DownloadError.missingData
        XCTAssertEqual(error.localizedDescription, "Data not found in response.)")
    }
}
