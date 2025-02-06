//
//  RecordDatabaseAdapter.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 02/01/25.
//

import Foundation
import SwiftProtoContracts
import UIKit

/**
 This file is an adapter for the database layer. It handles any model conversion from network to database layer and vice versa.
 */

/// Model used for record insert
public struct RecordModel {
  var documentID: String?
  var documentDate: Date?
  var documentHash: String?
  var documentType: Int?
  var hasSyncedEdit: Bool?
  var isAnalyzing: Bool?
  var isSmart: Bool?
  var oid: String?
  var thumbnail: String?
  var updatedAt: Date?
  var uploadDate: Date?
  var documentURIs: [String]?
  var contentType: String?
  
  init(
    documentID: String? = nil,
    documentDate: Date? = nil,
    documentHash: String? = nil,
    documentType: Int? = nil,
    hasSyncedEdit: Bool? = nil,
    isAnalyzing: Bool? = nil,
    isSmart: Bool? = nil,
    oid: String? = nil,
    thumbnail: String? = nil,
    updatedAt: Date? = nil,
    uploadDate: Date? = nil,
    documentURIs: [String]? = nil,
    contentType: String? = nil
  ) {
    self.documentID = documentID
    self.documentDate = documentDate
    self.documentHash = documentHash
    self.documentType = documentType
    self.hasSyncedEdit = hasSyncedEdit
    self.isAnalyzing = isAnalyzing
    self.isSmart = isSmart
    self.oid = oid
    self.thumbnail = thumbnail
    self.updatedAt = updatedAt
    self.uploadDate = uploadDate
    self.documentURIs = documentURIs
    self.contentType = contentType
  }
}

// MARK: - Model Conversion

public final class RecordDatabaseAdapter {
  // MARK: - Properties
  
  private let thumbnailHelper = ThumbnailHelper()
  
  /// This is to convert network array of models to database models
  func convertNetworkToDatabaseModels(
    from networkModels: [Vault_Records_Record],
    completion: @escaping ([RecordModel]) -> Void
  ) {
    var insertModels = [RecordModel]()
    /// Dispatch group to handle async conversion
    let dispatchGroup = DispatchGroup()
    networkModels.forEach { networkModel in
      dispatchGroup.enter()
      convertNetworkModelToInsertModel(from: networkModel) { insertModel in
        insertModels.append(insertModel)
        dispatchGroup.leave()
      }
    }
    /// Once we have all insert models we send in completion
    dispatchGroup.notify(queue: .main) {
      completion(insertModels)
    }
  }
}

// MARK: - UI to Database

extension RecordDatabaseAdapter {
  /// Used to convert to the common record Model from the given images
  /// - Parameters:
  ///   - data: Array of items within the record
  ///   - contentType: Type of content like for pdf it will be .pdf
  /// - Returns: RecordModel which will be used to insert in the database
  public func formRecordModelFromAddedData(
    data: [Data],
    contentType: FileType
  ) -> RecordModel {
    let contentTypeString: String = contentType.fileExtension
    /// Form record local path
    guard let recordsPath = FileHelper.writeMultipleDataToDocumentDirectoryAndGetFileNames(
      data,
      fileExtension: contentTypeString
    ) else { return RecordModel() }
    
    /// Add document to database
    /// Generate thumbnail for the record
    let thumbnail = thumbnailHelper.generateThumbnail(
      fromImageData: data.first,
      fromPdfUrl: recordsPath.first,
      mimeType: contentType
    )
    guard let thumbnail,
          let thumbnailData = thumbnail.jpegData(compressionQuality: 1),
          let thumbnailUrl = FileHelper.writeDataToDocumentDirectoryAndGetFileName(
            thumbnailData,
            fileExtension: contentType.fileExtension
          ) else {
      
      debugPrint("Database entry denied as record thumbnail is not present")
      return RecordModel()
    }
    
    return RecordModel(
      thumbnail: thumbnailUrl,
      updatedAt: Date(), // Current date
      uploadDate: Date(), // Current date
      documentURIs: recordsPath,
      contentType: contentType.fileExtension
    )
  }
}

// MARK: - Helpers

extension RecordDatabaseAdapter {
  /// This is to convert single network model to database model
  private func convertNetworkModelToInsertModel(
    from networkModel: Vault_Records_Record,
    completion: @escaping (RecordModel) -> Void
  ) {
    var insertModel = RecordModel()
    if networkModel.item.metadata.hasDocumentDate {
      insertModel.documentDate = networkModel.item.metadata.documentDate.toDate()
    }
    if networkModel.item.hasUploadDate {
      insertModel.uploadDate = networkModel.item.uploadDate.toDate()
    }
    insertModel.documentHash = UUID().uuidString /// To update ui
    insertModel.documentID = networkModel.item.documentID
    insertModel.documentType = networkModel.item.documentType.rawValue
    /// Form analysing status of the document
    if let availableDocument = networkModel.item.availableDocument {
      switch availableDocument {
      case .inTransit:
        insertModel.isAnalyzing = true
      case .metadata:
        insertModel.isAnalyzing = false
      }
    }
    insertModel.updatedAt = Date()
    /// Form Thumbnail asynchronously
    if networkModel.item.metadata.hasThumbnail {
      formLocalThumbnailFileNameFromNetworkURL(networkUrlString: networkModel.item.metadata.thumbnail) { localFileName in
        guard let localFileName else { return }
        insertModel.thumbnail = localFileName
        completion(insertModel)
      }
    } else {
      completion(insertModel)
    }
  }
  
  private func formLocalThumbnailFileNameFromNetworkURL(
    networkUrlString: String,
    completion: @escaping (String?) -> Void
  ) {
    guard let networkUrl = URL(string: networkUrlString) else { return }
    FileHelper.downloadData(from: networkUrl) { thumbnailData, error in
      if let thumbnailData {
        let localThumbnailURL = FileHelper.writeDataToDocumentDirectoryAndGetFileName(
          thumbnailData,
          fileExtension: FileType.image.fileExtension
        )
        completion(localThumbnailURL)
      }
    }
  }
}

// MARK: - Smart Report

extension RecordDatabaseAdapter {
  /// Used to serialize smart report info
  /// - Parameter smartReport: smartReportInfo object that is to be serialized
  /// - Returns: serialized data for the smart report
  func serializeSmartReportInfo(smartReport: SmartReportInfo?) -> Data? {
    guard let smartReport else { return nil }
    let smartReportData = try? JSONEncoder().encode(smartReport)
    return smartReportData
  }
  
  /// Used to deserialize the smart report info
  /// - Parameter data: data that is to be deserialized
  /// - Returns: object of smart report info
  func deserializeSmartReportInfo(data: Data?) -> SmartReportInfo? {
    guard let data else { return nil }
    let smartReportObject = try? JSONDecoder().decode(SmartReportInfo.self, from: data)
    return smartReportObject
  }
}
