import XCTest
@testable import EkaMedicalRecordsCore

final class HTTPHeaderAndDomainTests: XCTestCase {
    func test_httpHeader_rawValues() {
        XCTAssertEqual(HTTPHeader.contentTypeJson.rawValue, "application/json")
        XCTAssertEqual(HTTPHeader.multipartFormData.rawValue, "multipart/form-data")
        XCTAssertEqual(HTTPHeader.protobuf.rawValue, "application/x-protobuf")
    }

    func test_domainConfigurations_constants() {
        XCTAssertTrue(DomainConfigurations.apiURL.contains("eka.care"))
        XCTAssertTrue(DomainConfigurations.vaultURL.contains("vault.eka.care"))
        XCTAssertEqual(DomainConfigurations.ekaURL, "https://api.eka.care")
    }
}
