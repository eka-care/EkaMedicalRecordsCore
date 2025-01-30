//
//  FileHelper.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 03/01/25.
//

import Foundation

public enum FileType: String {
  case pdf = "PDF"
  case image = "IMG"
  
  public var fileExtension: String {
    switch self {
    case .pdf:
      return ".pdf"
    case .image:
      return ".jpg"
    }
  }
  
  public static func getTypeFromFileExtension(fileExtension: String) -> FileType? {
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

public final class FileHelper {
  /// Get Document directory url
  static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  /// Used to get file size in bytes from a url
  static func getFileSizeInBytes(from url: URL) -> Int? {
    do {
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
      if let fileSize = fileAttributes[.size] as? NSNumber {
        return fileSize.intValue
      } else {
        return nil
      }
    } catch {
      print("Error: \(error)")
      return nil
    }
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
  
  /// Writing documents into local document directory
  /// Documents are stored in Local URIs
  static func writeMultipleDataToDocumentDirectoryAndGetFileNames(_ data: [Data], fileExtension: String) -> [String]? {
    var recordsURL: [String] = []
    for datum in data {
      let fileName = UUID().uuidString + fileExtension
      let urlRecordItem = FileHelper.getDocumentDirectoryURL().appendingPathComponent(fileName)
      do {
        try datum.write(to: urlRecordItem, options: .atomic)
        recordsURL.append(fileName)
      } catch {
        debugPrint("Couldn't write data files to document directory \(error.localizedDescription)")
        return nil
      }
    }
    debugPrint("Record file names are \(recordsURL)")
    return recordsURL
  }
  
  /// Used to update file mime type from a given string
  static func updateFileMimeType(fileExtension: String) -> EkaFileMimeType {
    switch fileExtension {
    case ".pdf":
      return .pdf
    case ".mp4":
      return .video
    case ".jpg", "jpeg", "jpg", ".jpeg", "png", ".png", "bpm", ".bpm", "tiff", ".tiff":
      return .imageJpg
    case ".m4a":
      return .audio
    default:
      return .pdf
    }
  }
}
