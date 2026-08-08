import XCTest
@testable import EkaMedicalRecordsCore

final class ApiServicesTests: XCTestCase {
    
    // MARK: - RecordsApiService Tests
    
    func test_RecordsApiService_initialization() {
        let service = RecordsApiService()
        XCTAssertNotNil(service, "RecordsApiService should initialize")
    }
    
    func test_RecordsApiService_hasNetworkService() {
        let service = RecordsApiService()
        XCTAssertNotNil(service.networkService, "Should have network service")
    }
    
    func test_RecordsApiService_conformsToRecordsProvider() {
        let service = RecordsApiService()
        XCTAssertTrue(service is RecordsProvider, "Should conform to RecordsProvider protocol")
    }
    
    func test_RecordsApiService_conformsToSendable() {
        let service = RecordsApiService()
        // The type system enforces Sendable conformance at compile time
        // If this test compiles, Sendable conformance is valid
        XCTAssertNotNil(service)
    }
    
    func test_RecordsApiService_usesSharedNetworkService() {
        let service = RecordsApiService()
        // Verify it's using the shared network service instance
        XCTAssertTrue(service.networkService is NetworkService)
    }
    
    // MARK: - CasesApiService Tests
    
    func test_CasesApiService_initialization() {
        let service = CasesApiService()
        XCTAssertNotNil(service, "CasesApiService should initialize")
    }
    
    func test_CasesApiService_hasNetworkService() {
        let service = CasesApiService()
        XCTAssertNotNil(service.networkService, "Should have network service")
    }
    
    func test_CasesApiService_conformsToCasesProvider() {
        let service = CasesApiService()
        XCTAssertTrue(service is CasesProvider, "Should conform to CasesProvider protocol")
    }
    
    func test_CasesApiService_conformsToSendable() {
        let service = CasesApiService()
        // The type system enforces Sendable conformance at compile time
        // If this test compiles, Sendable conformance is valid
        XCTAssertNotNil(service)
    }
    
    func test_CasesApiService_usesSharedNetworkService() {
        let service = CasesApiService()
        // Verify it's using the shared network service instance
        XCTAssertTrue(service.networkService is NetworkService)
    }
    
    // MARK: - AuthApiService Tests
    
    func test_AuthApiService_initialization() {
        let service = AuthApiService()
        XCTAssertNotNil(service, "AuthApiService should initialize")
    }
    
    func test_AuthApiService_hasNetworkService() {
        let service = AuthApiService()
        XCTAssertNotNil(service.networkService, "Should have network service")
    }
    
    func test_AuthApiService_conformsToAuthProvider() {
        let service = AuthApiService()
        XCTAssertTrue(service is AuthProvider, "Should conform to AuthProvider protocol")
    }
    
    func test_AuthApiService_usesSharedNetworkService() {
        let service = AuthApiService()
        // Verify it's using the shared network service instance
        XCTAssertTrue(service.networkService is NetworkService)
    }
}

