import XCTest
@testable import EkaMedicalRecordsCore

private struct DummyDTO: Codable, Equatable { let name: String }

final class NetworkingSerializerTests: XCTestCase {
    func test_EkaErrorResponseSerializer_success_2xx() throws {
        let serializer = EkaErrorResponseSerializer<DummyDTO>()
        let url = URL(string: "https://example.com/success")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let body = try JSONEncoder().encode(DummyDTO(name: "ok"))
        let result = try serializer.serialize(request: nil, response: response, data: body, error: nil)
        switch result {
        case .success(let dto):
            XCTAssertEqual(dto, DummyDTO(name: "ok"))
        case .failure:
            XCTFail("Expected success")
        }
    }

    func test_EkaErrorResponseSerializer_error_4xx() throws {
        let serializer = EkaErrorResponseSerializer<DummyDTO>()
        let url = URL(string: "https://example.com/fail")!
        let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil)
        let errorBody = try JSONEncoder().encode(EkaAPIError(error: .init(message: "bad", type: "BAD")))
        let result = try serializer.serialize(request: nil, response: response, data: errorBody, error: nil)
        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let apiError):
            XCTAssertEqual(apiError.error.message, "bad")
            XCTAssertEqual(apiError.error.type, "BAD")
        }
    }

    func test_EkaErrorResponseSerializer_networkError() throws {
        let serializer = EkaErrorResponseSerializer<DummyDTO>()
        let result = try serializer.serialize(request: nil, response: nil, data: nil, error: NSError(domain: "net", code: -1))
        switch result {
        case .success:
            XCTFail("Expected failure due to transport error")
        case .failure(let apiError):
            XCTAssertNotNil(apiError.error.message)
        }
    }
}
