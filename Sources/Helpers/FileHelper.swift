//
//  FileHelper.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 03/01/25.
//

import Foundation

enum FileType: String {
  case pdf = "PDF"
  case image = "IMG"
  
  var fileExtension: String {
    switch self {
    case .pdf:
      return ".pdf"
    case .image:
      return ".jpg"
    }
  }
  
  static func getTypeFromFileExtension(fileExtension: String) -> FileType? {
    switch fileExtension {
    case ".pdf":
      return .pdf
    case ".jpg":
      return .image
    default:
      return nil
    }
  }
}

final class FileHelper {
  /// Get Document directory url
  static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  /// To Download data from URL
  static func downloadData(
    from url: URL,
    completion: @escaping (Data?, Error?) -> Void
  ) {
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      if let error = error {
        /// Handle the error
        completion(nil, error)
      } else if let data = data {
        /// Data downloaded successfully
        DispatchQueue.main.async {
          completion(data, nil)
        }
      }
    }
    task.resume()
  }
  
  /// To write data to document directory and get file name
  static func writeDataToDocumentDirectoryAndGetFileName(
    _ data: Data,
    fileExtension: String
  ) -> String? {
    let fileName = UUID().uuidString + fileExtension
    let fileURL = FileHelper.getDocumentDirectoryURL().appendingPathComponent(fileName)
    print("File Url is -> \(fileURL)")
    do {
      try data.write(to: fileURL, options: .atomic)
      return fileName
    } catch {
      print("Couldn't write data to document directory \(error)")
      return nil
    }
  }
}
