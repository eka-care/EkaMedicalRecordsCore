import XCTest
@testable import EkaMedicalRecordsCore

final class FileHelperTests: XCTestCase {
    func test_FileType_fileExtension() {
        XCTAssertEqual(FileType.pdf.fileExtension, ".pdf")
        XCTAssertEqual(FileType.image.fileExtension, ".jpg")
    }
    
    func test_FileType_getTypeFromFileExtension() {
        XCTAssertEqual(FileType.getTypeFromFileExtension(fileExtension: ".pdf"), .pdf)
        XCTAssertEqual(FileType.getTypeFromFileExtension(fileExtension: ".jpg"), .image)
        XCTAssertNil(FileType.getTypeFromFileExtension(fileExtension: ".unknown"))
    }
    
    func test_FileType_getFileTypeFromFilePath_pdf() {
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "document.pdf"), .pdf)
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "/path/to/file.PDF"), .pdf)
    }
    
    func test_FileType_getFileTypeFromFilePath_images() {
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "photo.jpg"), .image)
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "photo.jpeg"), .image)
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "photo.png"), .image)
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "photo.gif"), .image)
        XCTAssertEqual(FileType.getFileTypeFromFilePath(filePath: "photo.heic"), .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_unknown() {
        XCTAssertNil(FileType.getFileTypeFromFilePath(filePath: "document.txt"))
        XCTAssertNil(FileType.getFileTypeFromFilePath(filePath: "video.mp4"))
    }
    
    func test_FileHelper_getDocumentDirectoryURL() {
        let url = FileHelper.getDocumentDirectoryURL()
        XCTAssertTrue(url.path.contains("Documents"))
    }
    
    func test_FileHelper_updateFileMimeType() {
        XCTAssertEqual(FileHelper.updateFileMimeType(fileExtension: ".pdf"), .pdf)
        XCTAssertEqual(FileHelper.updateFileMimeType(fileExtension: ".mp4"), .video)
        XCTAssertEqual(FileHelper.updateFileMimeType(fileExtension: ".jpg"), .imageJpg)
        XCTAssertEqual(FileHelper.updateFileMimeType(fileExtension: ".m4a"), .audio)
        XCTAssertEqual(FileHelper.updateFileMimeType(fileExtension: ".unknown"), .pdf) // default
    }
    
    func test_FileHelper_writeDataToDocumentDirectoryAndGetFileName() {
        let testData = "test content".data(using: .utf8)!
        let fileName = FileHelper.writeDataToDocumentDirectoryAndGetFileName(testData, fileExtension: ".txt")
        XCTAssertNotNil(fileName)
        XCTAssertTrue(fileName?.hasSuffix(".txt") ?? false)
        
        // Cleanup
        if let fileName = fileName {
            let fileURL = FileHelper.getDocumentDirectoryURL().appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func test_FileHelper_writeMultipleDataToDocumentDirectoryAndGetFileNames() {
        let data1 = "test1".data(using: .utf8)!
        let data2 = "test2".data(using: .utf8)!
        let fileNames = FileHelper.writeMultipleDataToDocumentDirectoryAndGetFileNames([data1, data2], fileExtension: ".txt")
        XCTAssertNotNil(fileNames)
        XCTAssertEqual(fileNames?.count, 2)
        
        // Cleanup
        fileNames?.forEach { fileName in
            let fileURL = FileHelper.getDocumentDirectoryURL().appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

