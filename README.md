# Eka Medical Records Core



### Installation
------------

#### Swift Package Manager

The [Swift Package Manager](http:///www.swift.org/documentation/package-manager/ "Swift Package Manager") is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Add EkaMedicalRecordsUI as a dependency in your `Package.swift` file.

```swift
dependencies: [
.package(url: "https://github.com/eka-care/EkaMedicalRecordsCore.git", branch: "main")
]
```

Add `EkaMedicalRecordsCore` in the target.

```swift
.product(name: "EkaMedicalRecordsCore", package: "EkaMedicalRecordsCore")
```

### Initialisation

------------

Initialise the sdk with the required tokens from Auth Sdk.

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

1. **Auth Token**: Eka's authentication token that you can get from Eka's Auth Sdk APIs.
```swift
    CoreInitConfigurations.shared.authToken = AuthSdk.authToken
```
2. **Refresh Token**: Eka's refresh token that you can get from Eka's Auth Sdk APIs.
```swift
    CoreInitConfigurations.shared.refreshToken = AuthSdk.refreshToken
```
3. **OwnerID**: Owner ID is the OID for the person for whom you want the records for.
```swift
    CoreInitConfigurations.shared.ownerID = "xxxxxABCDEFGH"
```
4. **FilterID(optional)**: FilterID is the OID of the person for whom you want to filter the records for.
```swift
    CoreInitConfigurations.shared.filterID = "xxxxxABCDEFGH"
```
`Note: You need to write and set all these three properties from wherever you want to open the records screen from. FilterID field is optional and will be used only when you need to filter records attached to an ownerID.`

### Database Models

------------

##### Record Model

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

##### RecordMeta Model:

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

##### SmartReportModel:

```swift
extension SmartReport {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SmartReport> {
        return NSFetchRequest<SmartReport>(entityName: "SmartReport")
    }

    @NSManaged public var data: Data?
    @NSManaged public var toRecord: Record?

}
```

- Record Model has one to many relationship with record meta data.
- Record Model has one to one relationship with smart report.

### CRUD operations:

------------

For all communications with record database we do not directly use db model. For that purpose the following model has been created.

`RecordsRepo` class will contain all the crud operations.

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

### Create:

------------



###### Single Record : 

Function:
```swift
   /// Used to add a single record to the database
  /// - Parameter record: record to be added
  public func addSingleRecord(
    record: RecordModel,
    completion didUploadRecord: @escaping (Record?) -> Void
  )
```

Usage:

```swift
    recordsRepo.addSingleRecord(record: recordModel) { uploadedRecord in
      /// Action to be done after record upload
    }
```

### Read:

------------

Function to fetch records from database using fetch query

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

Function to fetch records from server and store in database.

```swift
  /// Used to fetch records from the server and store them in the database
  /// - Parameter completion: completion block to be executed after fetching
  public func fetchRecordsFromServer(completion: @escaping () -> Void)
```

Function to get file details

```swift
  /// Used to get file details and save in database
  /// This will have both smart report and original record
  private func getFileDetails(
    record: Record,
    completion: @escaping (DocFetchResponse?) -> Void
  )
```

Response

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
}
```

### Update:

------------

Function
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

Usage

```swift
    /// Update record in database
    recordsRepo.updateRecord(
      recordID: record.objectID,
      documentID: record.documentID,
      documentDate: documentDate,
      documentType: selectedDocumentType?.rawValue
    )
```

### Delete:

------------

Function to delete record from database and server
```swift
  /// Used to delete a specific record from the database as well as server
  /// - Parameter record: record to be deleted
  public func deleteRecord(
    record: Record
  )
```

