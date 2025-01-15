his SDK will have core records database functionalities like:

1. Sync Records (from the server)
2. Create record (Bulk or Single)
3. Read record (Bulk or Single)
4. Update record (Single)
5. Delete record (Bulk or Single) 

# **SDK INIT:**

```swift
init(
token: String, /// Token for sdk init
refreshToken: String, /// Refresh token for retry
delegate: EkaRecordsDelegate /// For any callbacks like auth refresh done etc
)
```

## Parmeters Explanation: -

1. Token:

• Initial token for API calls

1. Refresh Token: 

Refresh token for API calls retry

1. EkaRecordsDelegate:

• Used for making a connection for callbacks from the sdk to the mobile app

# DATABASE MODEL:

```swift
class RecordsDatabaseModel {
 let id: UUID (Primary Key)
 let documentId: String
 let documentType: Int
 let documentDate: Date
 let updatedAt: Date
 let thumbnail: String
 let isArchived: Bool
 let hasSyncedEdit: Bool
 let documentHash: String
 let isSmart: Bool
 let isAnalyzing: Bool
}
```
