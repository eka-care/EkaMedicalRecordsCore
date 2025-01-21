//
//  RecordDatabaseAdapter.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 02/01/25.
//

import Foundation
import SwiftProtoContracts

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
  var thumbnail: String?
  var updatedAt: Date?
  
  init(
    documentID: String? = nil,
    documentDate: Date? = nil,
    documentHash: String? = nil,
    documentType: Int? = nil,
    hasSyncedEdit: Bool? = nil,
    isAnalyzing: Bool? = nil,
    isSmart: Bool? = nil,
    thumbnail: String? = nil,
    updatedAt: Date? = nil
  ) {
    self.documentID = documentID
    self.documentDate = documentDate
    self.documentHash = documentHash
    self.documentType = documentType
    self.hasSyncedEdit = hasSyncedEdit
    self.isAnalyzing = isAnalyzing
    self.isSmart = isSmart
    self.thumbnail = thumbnail
    self.updatedAt = updatedAt
  }
}

// MARK: - Model Conversion

final class RecordDatabaseAdapter {
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
