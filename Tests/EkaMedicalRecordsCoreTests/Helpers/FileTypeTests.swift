import XCTest
@testable import EkaMedicalRecordsCore

final class FileTypeTests: XCTestCase {
    
    func test_FileType_pdf_fileExtension() {
        let fileType = FileType.pdf
        XCTAssertEqual(fileType.fileExtension, ".pdf")
    }
    
    func test_FileType_image_fileExtension() {
        let fileType = FileType.image
        XCTAssertEqual(fileType.fileExtension, ".jpg")
    }
    
    func test_FileType_getTypeFromFileExtension_pdf() {
        let fileType = FileType.getTypeFromFileExtension(fileExtension: ".pdf")
        XCTAssertEqual(fileType, .pdf)
    }
    
    func test_FileType_getTypeFromFileExtension_jpg() {
        let fileType = FileType.getTypeFromFileExtension(fileExtension: ".jpg")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getTypeFromFileExtension_invalid() {
        let fileType = FileType.getTypeFromFileExtension(fileExtension: ".txt")
        XCTAssertNil(fileType)
    }
    
    func test_FileType_getFileTypeFromFilePath_pdf() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/document.pdf")
        XCTAssertEqual(fileType, .pdf)
    }
    
    func test_FileType_getFileTypeFromFilePath_jpg() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.jpg")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_jpeg() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.jpeg")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_png() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.png")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_gif() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.gif")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_heic() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.heic")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_bmp() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.bmp")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_tiff() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.tiff")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_webp() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.webp")
        XCTAssertEqual(fileType, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_caseInsensitive() {
        let fileTypePDF = FileType.getFileTypeFromFilePath(filePath: "/path/to/document.PDF")
        let fileTypeJPG = FileType.getFileTypeFromFilePath(filePath: "/path/to/image.JPG")
        
        XCTAssertEqual(fileTypePDF, .pdf)
        XCTAssertEqual(fileTypeJPG, .image)
    }
    
    func test_FileType_getFileTypeFromFilePath_invalidExtension() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/document.txt")
        XCTAssertNil(fileType)
    }
    
    func test_FileType_getFileTypeFromFilePath_noExtension() {
        let fileType = FileType.getFileTypeFromFilePath(filePath: "/path/to/document")
        XCTAssertNil(fileType)
    }
    
    func test_FileType_rawValue() {
        XCTAssertEqual(FileType.pdf.rawValue, "PDF")
        XCTAssertEqual(FileType.image.rawValue, "IMG")
    }
}

