import XCTest
import Alamofire
@testable import EkaMedicalRecordsCore

final class EndpointsTests: XCTestCase {
    
    // MARK: - RecordsEndpoint Tests
    
    func test_RecordsEndpoint_fetchRecords_createsValidRequest() {
        let endpoint = RecordsEndpoint.fetchRecords(
            token: "next-page-token",
            updatedAt: "2025-01-01T00:00:00Z",
            oid: "patient-123"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
    }
    
    func test_RecordsEndpoint_fetchRecords_withNilParameters() {
        let endpoint = RecordsEndpoint.fetchRecords(
            token: nil,
            updatedAt: nil,
            oid: nil
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
    }
    
    func test_RecordsEndpoint_uploadRecords_createsValidRequest() {
        let uploadRequest = DocUploadRequest(batchRequests: [])
        let endpoint = RecordsEndpoint.uploadRecords(
            request: uploadRequest,
            oid: "patient-456"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "POST")
    }
    
    func test_RecordsEndpoint_uploadRecords_withNilOid() {
        let uploadRequest = DocUploadRequest(batchRequests: [])
        let endpoint = RecordsEndpoint.uploadRecords(
            request: uploadRequest,
            oid: nil
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
    }
    
    func test_RecordsEndpoint_delete_createsValidRequest() {
        let endpoint = RecordsEndpoint.delete(
            documentId: "doc-789",
            oid: "patient-oid"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "DELETE")
    }
    
    func test_RecordsEndpoint_delete_withSpecialCharacters() {
        let endpoint = RecordsEndpoint.delete(
            documentId: "doc@#$%&123",
            oid: "patient-oid"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
    }
    
    func test_RecordsEndpoint_fetchDocDetails_createsValidRequest() {
        let endpoint = RecordsEndpoint.fetchDocDetails(
            documentID: "doc-detail-123",
            oid: "patient-xyz"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
    }
    
    func test_RecordsEndpoint_editDocDetails_createsValidRequest() {
        let updateRequest = DocUpdateRequest(
            documentName: "Updated Name",
            documentDate: "2025-01-15",
            documentType: "Lab Report",
            tags: nil,
            masked: nil,
            caseIDs: nil
        )
        let endpoint = RecordsEndpoint.editDocDetails(
            documentID: "doc-edit-456",
            filterOID: "filter-oid",
            request: updateRequest
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "PATCH")
    }
    
    func test_RecordsEndpoint_editDocDetails_withNilFilterOID() {
        let updateRequest = DocUpdateRequest(
            documentName: "Updated Name",
            documentDate: nil,
            documentType: nil,
            tags: nil,
            masked: nil,
            caseIDs: nil
        )
        let endpoint = RecordsEndpoint.editDocDetails(
            documentID: "doc-edit-789",
            filterOID: nil,
            request: updateRequest
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
    }
    
    func test_RecordsEndpoint_refreshSourceRequest_createsValidRequest() {
        let endpoint = RecordsEndpoint.refreshSourceRequest(oid: "patient-refresh-123")
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
    }
    
    // MARK: - CasesEndpoint Tests
    
    func test_CasesEndpoint_createCases_createsValidRequest() {
        let createRequest = CasesCreateRequest(
            name: "New Case",
            description: "Case description",
            caseTypeID: "type-1",
            partnerMeta: nil
        )
        let endpoint = CasesEndpoint.createCases(
            oid: "patient-case-123",
            request: createRequest
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "POST")
    }
    
    func test_CasesEndpoint_fetchCasesList_createsValidRequest() {
        let endpoint = CasesEndpoint.fetchCasesList(
            token: "next-token",
            updatedAt: "2025-01-01",
            oid: "patient-list-456"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
    }
    
    func test_CasesEndpoint_fetchCasesList_withNilTokenAndUpdatedAt() {
        let endpoint = CasesEndpoint.fetchCasesList(
            token: nil,
            updatedAt: nil,
            oid: "patient-list-789"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
    }
    
    func test_CasesEndpoint_delete_createsValidRequest() {
        let endpoint = CasesEndpoint.delete(
            caseId: "case-delete-123",
            oid: "patient-del-456"
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "DELETE")
    }
    
    func test_CasesEndpoint_updateCases_createsValidRequest() {
        let updateRequest = CasesUpdateRequest(
            name: "Updated Case",
            description: "Updated description",
            caseTypeID: "type-2"
        )
        let endpoint = CasesEndpoint.updateCases(
            caseId: "case-update-789",
            oid: "patient-upd-123",
            request: updateRequest
        )
        
        let request = endpoint.urlRequest
        XCTAssertNotNil(request)
        XCTAssertEqual(request.request?.httpMethod, "PATCH")
    }
    
    // MARK: - RequestProvider Protocol Tests
    
    func test_RecordsEndpoint_conformsToRequestProvider() {
        let endpoint = RecordsEndpoint.fetchRecords(token: nil, updatedAt: nil, oid: nil)
        XCTAssertTrue(endpoint is RequestProvider)
    }
    
    func test_CasesEndpoint_conformsToRequestProvider() {
        let endpoint = CasesEndpoint.fetchCasesList(token: nil, updatedAt: nil, oid: "test")
        XCTAssertTrue(endpoint is RequestProvider)
    }
}

