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
