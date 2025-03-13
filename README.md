# Eka Medical Records Core

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.3+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Swift package for integrating with Eka's medical records system.

## Table of Contents

- [Installation](#installation)
- [Initialization](#initialization)
- [Database Models](#database-models)
  - [Record Model](#record-model)
  - [RecordMeta Model](#recordmeta-model)
  - [SmartReport Model](#smartreport-model)
- [CRUD Operations](#crud-operations)
  - [Create](#create)
  - [Read](#read)
  - [Update](#update)
  - [Delete](#delete)
- [API Response Models](#api-response-models)

## Installation

### Swift Package Manager

The [Swift Package Manager](http://www.swift.org/documentation/package-manager/ "Swift Package Manager") is a tool for automating the distribution of Swift code and is integrated into the Swift compiler.

Add EkaMedicalRecordsCore as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/eka-care/EkaMedicalRecordsCore.git", branch: "main")
]
```

Add `EkaMedicalRecordsCore` in the target:

```swift
.product(name: "EkaMedicalRecordsCore", package: "EkaMedicalRecordsCore")
```

## Initialization

Initialize the SDK with the required tokens from Auth SDK:

```swift
@main
struct RecordsAppApp: App {
    
    // MARK: - Init
    
    init() {
        registerCoreSdk()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Core SDK Init

extension RecordsAppApp {
    private func registerCoreSdk() {
        CoreInitConfigurations.shared.authToken = AuthSdk.authToken
        CoreInitConfigurations.shared.refreshToken = AuthSdk.refreshToken
        CoreInitConfigurations.shared.ownerID = "xxxxxABCDEFGH"
    }
}
```

### Required Parameters

1. **Auth Token**: Eka's authentication token that you can get from Eka's Auth SDK APIs.
   ```swift
   CoreInitConfigurations.shared.authToken = AuthSdk.authToken
   ```

2. **Refresh Token**: Eka's refresh token that you can get from Eka's Auth SDK APIs.
   ```swift
   CoreInitConfigurations.shared.refreshToken = AuthSdk.refreshToken
   ```

3. **OwnerID**: Owner ID is the OID for the person for whom you want the records for.
   ```swift
   CoreInitConfigurations.shared.ownerID = "xxxxxABCDEFGH"
   ```

4. **FilterID** (optional): FilterID is the OID of the person for whom you want to filter the records for.
   ```swift
   CoreInitConfigurations.shared.filterID = "xxxxxABCDEFGH"
   ```

> **Note**: You need to set all these properties from wherever you want to open the records screen. FilterID field is optional and will be used only when you need to filter records attached to an ownerID.

## Database Models

### Record Model

```swift
extension Record {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var bid: String?
    @NSManaged public var documentDate: Date?
    @NSManaged public var documentHash: String?
    @NSManaged public var documentID: String?
    @NSManaged public var documentType: Int64
    @NSManaged public var hasSyncedEdit: Bool
    @NSManaged public var isAnalyzing: Bool
    @NSManaged public var isArchived: Bool
    @NSManaged public var isSmart: Bool
    @NSManaged public var oid: String?
    @NSManaged public var thumbnail: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var uploadDate: Date?
    @NSManaged public var toRecordMeta: NSSet?
    @NSManaged public var toSmartReport: SmartReport?
}

// MARK: Generated accessors for toRecordMeta
extension Record {
    @objc(addToRecordMetaObject:)
    @NSManaged public func addToToRecordMeta(_ value: RecordMeta)

    @objc(removeToRecordMetaObject:)
    @NSManaged public func removeFromToRecordMeta(_ value: RecordMeta)

    @objc(addToRecordMeta:)
    @NSManaged public func addToToRecordMeta(_ values: NSSet)

    @objc(removeToRecordMeta:)
    @NSManaged public func removeFromToRecordMeta(_ values: NSSet)
}
```

### RecordMeta Model

```swift
extension RecordMeta {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordMeta> {
        return NSFetchRequest<RecordMeta>(entityName: "RecordMeta")
    }

    @NSManaged public var documentURI: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var toRecord: Record?
}
```

### SmartReport Model

```swift
extension SmartReport {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SmartReport> {
        return NSFetchRequest<SmartReport>(entityName: "SmartReport")
    }

    @NSManaged public var data: Data?
    @NSManaged public var toRecord: Record?
}
```

#### Relationships:
- Record Model has a one-to-many relationship with RecordMeta
- Record Model has a one-to-one relationship with SmartReport

## CRUD Operations

For all communications with the record database, we use the `RecordsRepo` class, which provides the following model:

```swift
/// Model used for record insert
public struct RecordModel {
    var documentID: String?
    var documentDate: Date?
    var documentHash: String?
    var documentType: Int?
    var hasSyncedEdit: Bool?
    var isAnalyzing: Bool?
    var isSmart: Bool?
    var oid: String?
    var thumbnail: String?
    var updatedAt: Date?
    var uploadDate: Date?
    var documentURIs: [String]?
    var contentType: String?
}
```

### Create

#### Adding a Single Record

**Function:**
```swift
/// Used to add a single record to the database
/// - Parameter record: record to be added
public func addSingleRecord(
    record: RecordModel,
    completion didUploadRecord: @escaping (Record?) -> Void
)
```

**Usage:**
```swift
recordsRepo.addSingleRecord(record: recordModel) { uploadedRecord in
    /// Action to be done after record upload
}
```

### Read

#### Fetching Records from Database

```swift
/// Used to fetch record entity items
/// - Parameter fetchRequest: fetch request for filtering
/// - Parameter completion: completion block to be executed after fetching records
public func fetchRecords(
    fetchRequest: NSFetchRequest<Record>,
    completion: @escaping ([Record]) -> Void
) {
    databaseManager.fetchRecords(
        fetchRequest: fetchRequest,
        completion: completion
    )
}
```

#### Fetching Records from Server

```swift
/// Used to fetch records from the server and store them in the database
/// - Parameter completion: completion block to be executed after fetching
public func fetchRecordsFromServer(completion: @escaping () -> Void)
```

#### Getting File Details

```swift
/// Used to get file details and save in database
/// This will have both smart report and original record
private func getFileDetails(
    record: Record,
    completion: @escaping (DocFetchResponse?) -> Void
)
```

### Update

#### Updating a Record

**Function:**
```swift
/// Used to update record
/// - Parameters:
///   - recordID: object Id of the record
///   - documentID: document id of the record
///   - documentDate: document date of the record
///   - documentType: document type of the record
public func updateRecord(
    recordID: NSManagedObjectID,
    documentID: String? = nil,
    documentDate: Date? = nil,
    documentType: Int? = nil
)
```

**Usage:**
```swift
/// Update record in database
recordsRepo.updateRecord(
    recordID: record.objectID,
    documentID: record.documentID,
    documentDate: documentDate,
    documentType: selectedDocumentType?.rawValue
)
```

### Delete

#### Deleting a Record

```swift
/// Used to delete a specific record from the database as well as server
/// - Parameter record: record to be deleted
public func deleteRecord(
    record: Record
)
```

## API Response Models

### Document Fetch Response

```swift
struct DocFetchResponse: Codable, Hashable {
    let documentID: String?
    let description: String?
    let patientName, authorizer: String?
    let documentDate: String?
    let documentType: String?
    let tags: [String]?
    let canDelete: Bool?
    let files: [File]?
    let smartReport: SmartReportInfo?
    let userTags: [String]?
    let derivedTags: [String]?
    let thumbnail: String?
    let fileExtension: String?
    let sharedWith: [String]?
    let uploadedByMe: Bool?
    
    enum CodingKeys: String, CodingKey {
        case documentID = "document_id"
        case description
        case patientName = "patient_name"
        case authorizer
        case documentDate = "document_date"
        case documentType = "document_type"
        case tags
        case canDelete = "can_delete"
        case files
        case smartReport = "smart_report"
        case userTags = "user_tags"
        case derivedTags = "derived_tags"
        case thumbnail = "thumbnail"
        case fileExtension = "file_type"
        case sharedWith = "shared_with"
        case uploadedByMe = "uploaded_by_me"
    }
    
    static func == (lhs: DocFetchResponse, rhs: DocFetchResponse) -> Bool {
        return lhs.documentID == rhs.documentID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(documentID)
    }
}
```

### File Model

```swift
struct File: Codable {
    let assetURL: String?
    let fileType, shareText: String?
    let maskedFile: MaskedFile?
    
    enum CodingKeys: String, CodingKey {
        case assetURL = "asset_url"
        case fileType = "file_type"
        case shareText = "share_text"
        case maskedFile = "masked_file"
    }
}
```

### Masked File Model

```swift
struct MaskedFile: Codable {
    let assetURL: String?
    let fileType, shareText, title, body: String?
    let tagline: String?
    
    enum CodingKeys: String, CodingKey {
        case assetURL = "asset_url"
        case fileType = "file_type"
        case shareText = "share_text"
        case title, body, tagline
    }
}
```

### Smart Report Info Model

```swift
public struct SmartReportInfo: Codable, Equatable {
    public let verified, unverified: [Verified]?
}
```

### Verified Model

```swift
public struct Verified: Codable, Hashable, Identifiable {
    public let id = UUID()
    public let name, value, unit: String?
    public let vitalID: String?
    public let ekaID: String?
    public let isResultEditable: Bool?
    public let pageNum, fileIndex: Int?
    public let coordinates: [Coordinate]?
    public let range, result, resultID, displayResult: String?
    public let date: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, value, unit, date
        case vitalID = "vital_id"
        case ekaID = "eka_id"
        case isResultEditable = "is_result_editable"
        case pageNum = "page_num"
        case fileIndex = "file_index"
        case coordinates, range, result
        case resultID = "result_id"
        case displayResult = "display_result"
    }
    
    public static func == (lhs: Verified, rhs: Verified) -> Bool {
        return lhs.vitalID == rhs.vitalID
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vitalID)
    }
}
```

### Coordinate Model

```swift
public struct Coordinate: Codable, Hashable {
    public let x: Double?
    public let y: Double?
}
```

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For any questions or support, please open an issue in the GitHub repository or contact the Eka Care team.
