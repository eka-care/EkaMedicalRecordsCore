import XCTest
import CoreData
@testable import EkaMedicalRecordsCore

final class QueryHelperTests: XCTestCase {
    func test_fetchLastUpdatedAt_configuration() {
        let fetchRequest = QueryHelper.fetchLastUpdatedAt(oid: "test-oid")
        XCTAssertEqual(fetchRequest.fetchLimit, 1)
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertNotNil(fetchRequest.sortDescriptors)
        XCTAssertEqual(fetchRequest.sortDescriptors?.first?.key, "updatedAt")
        XCTAssertEqual(fetchRequest.sortDescriptors?.first?.ascending, false)
    }
    
    func test_fetchRecordsWithNilDocumentID_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithNilDocumentID()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("documentID == nil"))
    }
    
    func test_fetchRecordsWithUploadingOrFailedState_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithUploadingOrFailedState()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("OR"))
    }
    
    func test_fetchRecordsForEditedRecordSync_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsForEditedRecordSync()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("isEdited"))
    }
    
    func test_fetchRecordWith_documentID() {
        let fetchRequest = QueryHelper.fetchRecordWith(documentID: "doc-123")
        XCTAssertEqual(fetchRequest.fetchLimit, 1)
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("documentID"))
    }
    
    // MARK: - Cases Tests
    
    func test_fetchCase_withCaseID() {
        let fetchRequest = QueryHelper.fetchCase(caseID: "case-123")
        XCTAssertEqual(fetchRequest.fetchLimit, 1)
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchCase_withNilCaseID() {
        let fetchRequest = QueryHelper.fetchCase(caseID: nil)
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchCases_withMultipleCaseIDs() {
        let fetchRequest = QueryHelper.fetchCases(caseIDs: ["case1", "case2"])
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("IN"))
    }
    
    func test_fetchCases_withEmptyArray() {
        let fetchRequest = QueryHelper.fetchCases(caseIDs: [])
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchLastCaseUpdatedAt_configuration() {
        let fetchRequest = QueryHelper.fetchLastCaseUpdatedAt(oid: "oid-123")
        XCTAssertEqual(fetchRequest.fetchLimit, 1)
        XCTAssertNotNil(fetchRequest.sortDescriptors)
        XCTAssertEqual(fetchRequest.sortDescriptors?.first?.key, "updatedAt")
    }
    
    func test_fetchCasesForEditedSync_configuration() {
        let fetchRequest = QueryHelper.fetchCasesForEditedSync()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("isEdited"))
    }
    
    func test_fetchCasesForUncreatedOnServerSync_configuration() {
        let fetchRequest = QueryHelper.fetchCasesForUncreatedOnServerSync()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("isRemoteCreated"))
    }
    
    // MARK: - Tags Tests
    
    func test_fetchRecordsWithTags_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithTags(tagNames: ["tag1", "tag2"])
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("ANY"))
    }
    
    func test_fetchRecordsWithTags_emptyArray() {
        let fetchRequest = QueryHelper.fetchRecordsWithTags(tagNames: [])
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchRecordsWithAllTags_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithAllTags(tagNames: ["tag1", "tag2"])
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchRecordsWithTag_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithTag(tagName: "important")
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("ANY"))
    }
    
    func test_fetchRecordsWithAnyTags_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithAnyTags()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("@count > 0"))
    }
    
    func test_fetchRecordsWithoutTags_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithoutTags()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("@count == 0"))
    }
    
    func test_fetchAllUniqueTagNames_configuration() {
        let fetchRequest = QueryHelper.fetchAllUniqueTagNames()
        XCTAssertEqual(fetchRequest.resultType, .dictionaryResultType)
        XCTAssertTrue(fetchRequest.returnsDistinctResults)
    }
    
    func test_fetchAllTags_configuration() {
        let fetchRequest = QueryHelper.fetchAllTags()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertNotNil(fetchRequest.sortDescriptors)
    }
    
    func test_fetchTag_withName() {
        let fetchRequest = QueryHelper.fetchTag(withName: "urgent")
        XCTAssertEqual(fetchRequest.fetchLimit, 1)
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchTagsForRecords_configuration() {
        let fetchRequest = QueryHelper.fetchTagsForRecords(documentIDs: ["doc1", "doc2"])
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchRecords_withOidAndTags() {
        let fetchRequest = QueryHelper.fetchRecords(oid: ["oid1"], tagNames: ["tag1"], requireAllTags: false)
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchRecords_withOidAndRequireAllTags() {
        let fetchRequest = QueryHelper.fetchRecords(oid: ["oid1"], tagNames: ["tag1", "tag2"], requireAllTags: true)
        XCTAssertNotNil(fetchRequest.predicate)
    }
    
    func test_fetchRecordsWithTagCount_configuration() {
        let fetchRequest = QueryHelper.fetchRecordsWithTagCount(3)
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("@count == 3"))
    }
    
    func test_fetchOrphanedTags_configuration() {
        let fetchRequest = QueryHelper.fetchOrphanedTags()
        XCTAssertNotNil(fetchRequest.predicate)
        XCTAssertTrue(fetchRequest.predicate!.predicateFormat.contains("@count == 0"))
    }
}
