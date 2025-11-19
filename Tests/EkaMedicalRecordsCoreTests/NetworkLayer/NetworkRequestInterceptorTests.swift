import XCTest
import Alamofire
@testable import EkaMedicalRecordsCore

final class NetworkRequestInterceptorTests: XCTestCase {
    
    var interceptor: NetworkRequestInterceptor!
    
    override func setUp() {
        super.setUp()
        interceptor = NetworkRequestInterceptor(isProto: false)
    }
    
    override func tearDown() {
        interceptor = nil
        super.tearDown()
    }
    
    func test_NetworkRequestInterceptor_initialization_defaultIsProto() {
        let defaultInterceptor = NetworkRequestInterceptor()
        XCTAssertNotNil(defaultInterceptor)
    }
    
    func test_NetworkRequestInterceptor_initialization_withIsProto() {
        let protoInterceptor = NetworkRequestInterceptor(isProto: true)
        XCTAssertNotNil(protoInterceptor)
    }
    
    func test_NetworkRequestInterceptor_retryLimit() {
        XCTAssertEqual(interceptor.retryLimit, 1, "Retry limit should be 1")
    }
    
    func test_NetworkRequestInterceptor_authService_isInitialized() {
        XCTAssertNotNil(interceptor.authService, "Auth service should be initialized")
    }
    
    func test_adapt_addsStaticHeaders() {
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        
        let expectation = XCTestExpectation(description: "Adapt completion")
        
        let session = Session()
        interceptor.adapt(request, for: session) { result in
            switch result {
            case .success(let adaptedRequest):
                // Check that static headers are added
                XCTAssertNotNil(adaptedRequest.headers["client-id"])
                XCTAssertEqual(adaptedRequest.headers["client-id"], "doctor-ipad-ios")
                XCTAssertNotNil(adaptedRequest.headers["make"])
                XCTAssertEqual(adaptedRequest.headers["make"], "Apple")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Adapt should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_addEkaStaticHeaders_defaultHeaders() {
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        XCTAssertEqual(request.headers["client-id"], "doctor-ipad-ios")
        XCTAssertEqual(request.headers["make"], "Apple")
        XCTAssertNotNil(request.headers["flavour"])
        XCTAssertNotNil(request.headers["locale"])
        XCTAssertNotNil(request.headers["device-id"])
    }
    
    func test_addEkaStaticHeaders_withAuthToken() {
        AuthTokenHolder.shared.authToken = "test-auth-token"
        
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: true)
        
        XCTAssertEqual(request.headers["auth"], "test-auth-token")
        
        // Cleanup
        AuthTokenHolder.shared.authToken = nil
    }
    
    func test_addEkaStaticHeaders_withoutAuthToken() {
        AuthTokenHolder.shared.authToken = nil
        
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: true)
        
        XCTAssertNil(request.headers["auth"])
    }
    
    func test_addEkaStaticHeaders_addAuthHeaderFalse() {
        AuthTokenHolder.shared.authToken = "test-token"
        
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        XCTAssertNil(request.headers["auth"])
        
        // Cleanup
        AuthTokenHolder.shared.authToken = nil
    }
    
    func test_addEkaStaticHeaders_protoAcceptHeader() {
        let protoInterceptor = NetworkRequestInterceptor(isProto: true)
        
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        protoInterceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        XCTAssertEqual(request.headers["Accept"], "application/x-protobuf")
    }
    
    func test_addEkaStaticHeaders_nonProtoNoAcceptHeader() {
        let nonProtoInterceptor = NetworkRequestInterceptor(isProto: false)
        
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        nonProtoInterceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        // Should not have the protobuf Accept header
        XCTAssertNotEqual(request.headers["Accept"], "application/x-protobuf")
    }
    
    func test_addEkaStaticHeaders_flavourBasedOnDevice() {
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        let flavour = request.headers["flavour"]
        // Flavour should be either "io" for phone or "ip" for iPad
        XCTAssertTrue(flavour == "io" || flavour == "ip")
    }
    
    func test_addEkaStaticHeaders_localeFromPreferredLanguages() {
        let url = URL(string: "https://test.com")!
        var request = URLRequest(url: url)
        
        interceptor.addEkaStaticHeaders(&request, addAuthHeader: false)
        
        let locale = request.headers["locale"]
        XCTAssertNotNil(locale)
        // Should be at least 2 characters (e.g., "en", "fr", etc.)
        XCTAssertTrue(locale?.count ?? 0 >= 2)
    }
    
    func test_refreshTokens_withNilRefreshToken() {
        let expectation = XCTestExpectation(description: "Refresh completion")
        expectation.isInverted = true // Should NOT be fulfilled
        
        interceptor.refreshTokens(
            refreshToken: nil,
            accessToken: "test-access-token"
        ) { succeeded, accessToken in
            expectation.fulfill()
        }
        
        // Wait briefly to ensure callback is not called
        wait(for: [expectation], timeout: 0.5)
    }
    
    func test_refreshTokens_withNilAccessToken() {
        let expectation = XCTestExpectation(description: "Refresh completion")
        expectation.isInverted = true // Should NOT be fulfilled
        
        interceptor.refreshTokens(
            refreshToken: "test-refresh-token",
            accessToken: nil
        ) { succeeded, accessToken in
            expectation.fulfill()
        }
        
        // Wait briefly to ensure callback is not called
        wait(for: [expectation], timeout: 0.5)
    }
}

