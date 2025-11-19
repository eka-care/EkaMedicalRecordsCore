# EkaMedicalRecordsCore Test Suite

## 📁 Folder Structure

Tests are organized to mirror the source code structure for easy navigation:

```
EkaMedicalRecordsCoreTests/
├── Common/                           # Extension tests (Date, String, Int)
├── Configurations/                   # CoreInitConfigurations tests
├── Constants/                        # Constants, ScreenConstants, EventLog tests
├── DatabaseLayer/                    # Database layer tests
│   ├── Cases/                       # CaseModel and adapter tests
│   └── Records/                     # RecordModel, QueryHelper tests
├── Helpers/                          # Helper utility tests
│   ├── ErrorHelper
│   ├── FileHelper
│   ├── PredicateHelper
│   └── UserDefaultsHelper
├── NetworkLayer/                     # Network layer tests
│   ├── Auth/                        # Auth models (RefreshRequest/Response)
│   ├── Records/                     # Record models (DocFetchResponse, Cases)
│   ├── HTTPHeaderAndDomainTests
│   ├── NetworkingSerializerTests   # EkaErrorResponseSerializer
│   └── NetworkingSmallTests        # DownloadError, etc.
└── TEST_NOTES.md                    # Important notes about test limitations
```

## 🚀 Running Tests

### In Xcode (Recommended)
1. Open `Package.swift` in Xcode
2. Select an iOS simulator (iPhone/iPad)
3. Press `⌘U` (Product → Test)
4. View coverage: Editor → Show Code Coverage

### Enable Code Coverage
1. Edit Scheme → Test → Options
2. Check "Gather coverage for all targets"

### Command Line (Not Supported)
⚠️ Cannot run via `swift test` - requires UIKit (iOS-only package)

## 📊 Test Coverage

- **21 test files** with **128+ test cases**
- **Target: 70%+ code coverage** for testable components

### What's Tested ✅
- All extension methods (Date, String, Int)
- All helper utilities
- All Codable models (encoding/decoding)
- Network serializers and error handling
- Query builders and predicates
- Database adapters and models
- Configuration side-effects
- Enum raw values and computed properties

### What's Not Tested (By Design) ⚠️
- Live network calls (would require mocking)
- Core Data operations (would require in-memory stack)
- UI components (UIKit-dependent)
- Some numeric predicates (crash in unit tests, work in production)

## 🔧 Adding New Tests

### Guidelines
1. **Match the structure**: Place tests in folders matching the source code
2. **Naming convention**: `[SourceFileName]Tests.swift`
3. **Test class naming**: `final class [SourceFileName]Tests: XCTestCase`
4. **Test method naming**: `test_[methodName]_[scenario]()`

### Example
For a source file at `Sources/Helpers/NewHelper.swift`:
```swift
// Tests/EkaMedicalRecordsCoreTests/Helpers/NewHelperTests.swift
import XCTest
@testable import EkaMedicalRecordsCore

final class NewHelperTests: XCTestCase {
    func test_helperMethod_withValidInput() {
        // Test implementation
    }
    
    func test_helperMethod_withInvalidInput() {
        // Test implementation
    }
}
```

## ⚠️ Known Limitations

See `TEST_NOTES.md` for detailed information about:
- Tests that crash without Core Data stack
- Numeric predicate limitations
- Entity name access issues
- Why commented-out tests still work in production

## 📝 Test Categories

### Unit Tests (Current)
- Pure logic testing
- Model encoding/decoding
- Helper functions
- Extensions

### Integration Tests (Future)
- Core Data operations with in-memory stack
- Network layer with URLProtocol mocks
- End-to-end workflows

### UI Tests (Future)
- Screen flows
- User interactions
- UI component behavior

## 🐛 Troubleshooting

### Tests Crash with "Bad Access"
- Check if you're testing numeric predicates
- Verify you're not accessing `Record.entity().name` without Core Data
- See `TEST_NOTES.md` for solutions

### Tests Fail to Compile
- Ensure you're running in Xcode with an iOS target
- Check that UIKit imports are available
- Verify all test files are in the test target

### Coverage is Low
- Enable code coverage in scheme settings
- Run full test suite (⌘U)
- Check TEST_NOTES.md for what's not tested and why

## 📚 Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Package Manager Testing](https://swift.org/package-manager/)
- Project: `TEST_NOTES.md` for detailed test information

