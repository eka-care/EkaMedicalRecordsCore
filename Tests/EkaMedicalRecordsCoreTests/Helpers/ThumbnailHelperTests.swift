import XCTest
@testable import EkaMedicalRecordsCore

final class ThumbnailHelperTests: XCTestCase {
    
    var thumbnailHelper: ThumbnailHelper!
    
    override func setUp() {
        super.setUp()
        thumbnailHelper = ThumbnailHelper()
    }
    
    override func tearDown() {
        thumbnailHelper = nil
        super.tearDown()
    }
    
    func test_generatePdfThumbnail_withNilURL_returnsNil() {
        let thumbnail = thumbnailHelper.generatePdfThumbnail(for: nil, atPage: 0)
        XCTAssertNil(thumbnail, "Should return nil for nil URL")
    }
    
    func test_generatePdfThumbnail_withInvalidURL_returnsNil() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/to/file.pdf")
        let thumbnail = thumbnailHelper.generatePdfThumbnail(for: invalidURL, atPage: 0)
        XCTAssertNil(thumbnail, "Should return nil for invalid PDF URL")
    }
    
    func test_generatePdfThumbnail_withInvalidPageIndex_returnsNil() {
        let url = URL(fileURLWithPath: "/some/path.pdf")
        let thumbnail = thumbnailHelper.generatePdfThumbnail(for: url, atPage: 999)
        XCTAssertNil(thumbnail, "Should return nil for out-of-bounds page index")
    }
    
    func test_cropTopHalf_withValidImage_returnsImage() {
        // Create a simple test image
        let size = CGSize(width: 100, height: 200)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = testImage else {
            XCTFail("Failed to create test image")
            return
        }
        
        let croppedImage = thumbnailHelper.cropTopHalf(of: image)
        XCTAssertNotNil(croppedImage, "Should return cropped image")
        
        if let cropped = croppedImage {
            // The cropped image should be half the height
            XCTAssertEqual(cropped.size.height, image.size.height / 2, accuracy: 1.0)
            XCTAssertEqual(cropped.size.width, image.size.width, accuracy: 1.0)
        }
    }
    
    func test_generateThumbnail_withNilData_returnsNil() {
        let thumbnail = thumbnailHelper.generateThumbnail(
            fromImageData: nil,
            fromPdfUrl: nil,
            mimeType: .image
        )
        XCTAssertNil(thumbnail, "Should return nil for nil data")
    }
    
    func test_generateThumbnail_withInvalidImageData_returnsNil() {
        let invalidData = "invalid image data".data(using: .utf8)
        let thumbnail = thumbnailHelper.generateThumbnail(
            fromImageData: invalidData,
            fromPdfUrl: nil,
            mimeType: .image
        )
        XCTAssertNil(thumbnail, "Should return nil for invalid image data")
    }
    
    func test_generateThumbnail_pdfType_withNilFilename_returnsNil() {
        let someData = Data([0x01, 0x02, 0x03])
        let thumbnail = thumbnailHelper.generateThumbnail(
            fromImageData: someData,
            fromPdfUrl: nil,
            mimeType: .pdf
        )
        XCTAssertNil(thumbnail, "Should return nil for PDF type without filename")
    }
    
    func test_generateThumbnail_imageType_withValidData() {
        // Create valid PNG data
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = testImage,
              let pngData = image.pngData() else {
            XCTFail("Failed to create test PNG data")
            return
        }
        
        let thumbnail = thumbnailHelper.generateThumbnail(
            fromImageData: pngData,
            fromPdfUrl: nil,
            mimeType: .image
        )
        
        // The thumbnail should be created and cropped to top half
        XCTAssertNotNil(thumbnail, "Should return thumbnail for valid image data")
        
        if let thumb = thumbnail {
            // Should be half the original height due to crop
            XCTAssertEqual(thumb.size.height, size.height / 2, accuracy: 1.0)
        }
    }
    
    func test_ThumbnailHelper_initialization() {
        let helper = ThumbnailHelper()
        XCTAssertNotNil(helper, "ThumbnailHelper should initialize")
    }
}

