//
//  ThumbnailHelper.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 23/01/25.
//

import UIKit
import PDFKit

final class ThumbnailHelper {
  /// Function to convert PDF Data to UIImage
  func generatePdfThumbnail(for documentUrl: URL?, atPage pageIndex: Int) -> UIImage? {
    guard let documentUrl else { return nil }
    let pdfThumbnailSize = CGSize(width: ScreenConstants.width * 0.93, height: ScreenConstants.height * 0.8)
    let pdfDocument = PDFDocument(url: documentUrl)
    let pdfDocumentPage = pdfDocument?.page(at: pageIndex)
    return pdfDocumentPage?.thumbnail(of: pdfThumbnailSize, for: PDFDisplayBox.trimBox)
  }
  
  /// Function to crop UIImage to top half
  func cropTopHalf(of image: UIImage) -> UIImage? {
    let cropRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height/2)
    guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }
  
  /// Main function to generate and crop image
  func generateThumbnail(
    fromImageData data: Data? = nil,
    fromPdfUrl pdfFileName: String? = nil,
    mimeType: FileType
  ) -> UIImage? {
    guard let data else { return nil}
    var image: UIImage?
    switch mimeType {
    case .pdf:
      guard let pdfFileName else { return nil }
      let pdfUrl = FileHelper.getDocumentDirectoryURL().appendingPathComponent(pdfFileName)
      image = generatePdfThumbnail(for: pdfUrl, atPage: 0)
    case .image:
      image = UIImage(data: data)
    }
    guard let image else {
      return nil
    }
    return cropTopHalf(of: image)
  }
}
