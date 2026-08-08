# EkaMedicalRecordsCore Tests

This directory contains comprehensive unit tests for the EkaMedicalRecordsCore package.

## Overview

The test suite is structured to mirror the source code organization, making it easy to find and maintain tests for specific components.

## Test Statistics

- **Total Test Files**: 27
- **Total Test Methods**: 243
- **Estimated Coverage**: ~70%

## Directory Structure

```
EkaMedicalRecordsCoreTests/
├── Common/                         # Tests for common extensions
│   ├── DateExtensionTests.swift
│   ├── IntExtensionTests.swift
│   └── StringExtensionTests.swift
├── Configurations/                 # Tests for SDK configuration
│   └── CoreInitConfigurationsTests.swift
├── Constants/                      # Tests for constants and logger
│   └── ConstantsAndLoggerTests.swift
├── DatabaseLayer/                  # Tests for database layer
│   ├── Cases/
│   │   ├── CaseModelAndAdapterTests.swift
│   │   └── CaseTypeTests.swift
│   └── Records/
│       ├── DatabaseOperationTests.swift
│       ├── QueryHelperTests.swift
│       └── RecordModelAndAdapterTests.swift
├── Helpers/                        # Tests for helper utilities
│   ├── ErrorHelperTests.swift
│   ├── FileHelperTests.swift
│   ├── FileTypeTests.swift
│   ├── LoggerTests.swift
│   ├── PredicateHelperTests.swift
│   ├── ThumbnailHelperTests.swift
│   └── UserDefaultsHelperTests.swift
├── Managers/                       # Tests for managers
│   └── RecordUploadManagerTests.swift
└── NetworkLayer/                   # Tests for networking layer
    ├── Auth/
    │   └── NetworkModelsTests.swift
    ├── HTTPHeaderAndDomainTests.swift
    ├── NetworkRequestInterceptorTests.swift
    ├── NetworkingSerializerTests.swift
    ├── NetworkingSmallTests.swift
    └── Records/
        ├── AdditionalModelsTests.swift
        ├── ApiServicesTests.swift
        ├── CasesModelsTests.swift
        ├── EndpointsTests.swift
        ├── ModelsDecodingTests.swift
        └── UploadModelsTests.swift
```

## Running Tests

### Prerequisites
- **Xcode 15+** (or compatible version)
- **iOS 16+ Simulator** (required due to UIKit dependencies)

### In Xcode
1. Open `Package.swift` in Xcode
2. Select an iOS simulator as the run destination
3. Press `Cmd+U` to run all tests
4. Or right-click on specific test file/class/method → "Run"

### Command Line
⚠️ **Not supported** - The package depends on `UIKit` which is not available in macOS command-line environments. Use Xcode instead.

## Test Coverage

### ✅ Fully Covered Components
- **Common Extensions**: Date, String, Int utilities
- **Helpers**: Error handling, file operations, predicates, thumbnails, user defaults, logging
- **Constants**: Application constants, screen dimensions, event logging
- **Configurations**: SDK initialization, token management, domain configuration
- **Network Models**: All request/response models for docs, cases, auth
- **Network Endpoints**: All API endpoint builders
- **Network Services**: API service implementations
- **Database Models**: Record models, case models, adapters
- **Managers**: Upload manager

### ⚠️ Partially Covered
- **Core Data Operations**: Require integration tests with live Core Data stack
- **Repository Layer**: Requires network mocking for full coverage
- **Network Service**: Tested structurally; full integration requires mocked endpoints

### Known Limitations
1. **Core Data Entity Extensions**: Cannot be fully unit tested without managed object context
2. **NSPredicate Evaluation**: Some predicate tests are commented out due to runtime crashes in test environment
3. **Network Integration**: Full network flow testing requires mocked HTTP endpoints

See [COVERAGE_SUMMARY.md](./COVERAGE_SUMMARY.md) for detailed coverage information.

## Test Conventions

### Naming
- Test files: `[SourceFile]Tests.swift`
- Test methods: `test_[component]_[scenario]_[expectedResult]()`

### Organization
- Tests are grouped by the component they test
- Each test file mirrors the structure of its source file
- Related tests are grouped using `// MARK: -` comments

### Best Practices
- ✅ Test both positive and negative scenarios
- ✅ Test edge cases (nil, empty, invalid input)
- ✅ Use descriptive test method names
- ✅ Include assertions with meaningful messages
- ✅ Clean up test state in `tearDown()` when needed
- ✅ Use `XCTestExpectation` for async operations

## Contributing

When adding new tests:
1. Place test file in the directory that mirrors the source location
2. Follow the naming conventions
3. Include both positive and negative test cases
4. Test edge cases and error conditions
5. Update this README and COVERAGE_SUMMARY.md if adding new test categories

## Documentation

- [COVERAGE_SUMMARY.md](./COVERAGE_SUMMARY.md) - Detailed coverage report
- [TEST_NOTES.md](./TEST_NOTES.md) - Known issues and workarounds

## Support

For questions or issues with tests, please refer to:
1. The main [README.md](../README.md) in the project root
2. The [COVERAGE_SUMMARY.md](./COVERAGE_SUMMARY.md) for detailed coverage info
3. The [TEST_NOTES.md](./TEST_NOTES.md) for known limitations

---

*Last Updated: January 30, 2025*

