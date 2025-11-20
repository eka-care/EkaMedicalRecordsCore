//
//  RecordDatabaseAdapter.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 02/01/25.
//

import Foundation
import UIKit

/**
 This file is an adapter for the database layer. It handles any model conversion from network to database layer and vice versa.
 */

/// Model used for record insert
public struct RecordModel {
  public var documentID: String
  public var documentDate: Date?
  public var documentHash: String?
  public var documentType: String?
  public var syncState: RecordSyncState?
  public var isAnalyzing: Bool?
  public var isSmart: Bool?
  public var oid: String?
  public var thumbnail: String?
  public var updatedAt: Date?
  public var uploadDate: Date?
  public var documentURIs: [String]?
  public var contentType: String?
  public var isEdited: Bool?
  public var caseModels: [CaseModel]? // Array of case models for many-to-many relationship
  public var caseIDs: [String]? // Array of case IDs for lazy loading
  public var tags: [String]?
  
  public init(
    documentDate: Date? = nil,
    documentHash: String? = nil,
    documentType: String? = nil,
    syncState: RecordSyncState? = nil,
    isAnalyzing: Bool? = nil,
    isSmart: Bool? = nil,
    oid: String? = nil,
    thumbnail: String? = nil,
    updatedAt: Date? = nil,
    uploadDate: Date? = nil,
    documentURIs: [String]? = nil,
    contentType: String? = nil,
    isEdited: Bool? = nil,
    caseModels: [CaseModel]? = nil,
    caseIDs: [String]? = nil,
    tags: [String]? = nil
  ) {
    self.documentID = UUID().uuidString
    self.documentDate = documentDate
    self.documentHash = documentHash
    self.documentType = documentType
    self.syncState = syncState
    self.isAnalyzing = isAnalyzing
    self.isSmart = isSmart
    self.oid = oid
    self.thumbnail = thumbnail
    self.updatedAt = updatedAt
    self.uploadDate = uploadDate
    self.documentURIs = documentURIs
    self.isEdited = isEdited
    self.contentType = contentType
    self.caseModels = caseModels
    self.caseIDs = caseIDs
    self.tags = tags
  }
}

/// Used to get the records sync state
public enum RecordSyncState: Equatable {
  
  case uploading
  case upload(success: Bool)
  
  public var stringValue: String {
    switch self {
    case .uploading:
      return "uploading"
    case .upload(let success):
      return success ? "upload_success" : "upload_failure"
    }
  }
  
  public init?(from string: String) {
    switch string {
    case "uploading":
      self = .uploading
    case "upload_success":
      self = .upload(success: true)
    case "upload_failure":
      self = .upload(success: false)
    default:
      return nil
    }
  }
}

// MARK: - Model Conversion

public final class RecordDatabaseAdapter {
  // MARK: - Properties
  
  private let thumbnailHelper = ThumbnailHelper()
  
  /// This is to convert network array of models to database models
  func convertNetworkToDatabaseModels(
    from networkModels: [RecordItemElement],
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
  ///   - caseModels: Array of CaseModels to which the record will be attached
  /// - Returns: RecordModel which will be used to insert in the database
  public func formRecordModelFromAddedData(
    data: [Data],
    contentType: FileType,
    documentType: String? = nil,
    caseModels: [CaseModel]? = nil,
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
      
      EkaMedicalRecordsCoreLogger.capture("Database entry denied as record thumbnail is not present")
      return RecordModel()
    }
    
    return RecordModel(
      documentType: documentType, // other type
      oid: CoreInitConfigurations.shared.primaryFilterID,
      thumbnail: thumbnailUrl,
      updatedAt: Date(), // Current date
      uploadDate: Date(), // Current date
      documentURIs: recordsPath,
      contentType: contentType.fileExtension,
      caseModels: caseModels
    )
  }
  
//  /// Backward compatibility function for single case model
//  /// - Parameters:
//  ///   - data: Array of items within the record
//  ///   - contentType: Type of content like for pdf it will be .pdf
//  ///   - caseModel: Single CaseModel to which the record will be attached
//  /// - Returns: RecordModel which will be used to insert in the database
//  public func formRecordModelFromAddedData(
//    data: [Data],
//    contentType: FileType,
//    caseModel: CaseModel?
//  ) -> RecordModel {
//    let caseModels = caseModel != nil ? [caseModel!] : nil
//    return formRecordModelFromAddedData(
//      data: data,
//      contentType: contentType,
//      caseModels: caseModels
//    )
//  }
}

// MARK: - Helpers

extension RecordDatabaseAdapter {
  /// This is to convert single network model to database model
  private func convertNetworkModelToInsertModel(
    from networkModel: RecordItemElement,
    completion: @escaping (RecordModel) -> Void
  ) {
    var insertModel = RecordModel()

    if let documentDate = networkModel.recordDocument.item.metadata?.documentDate {
      insertModel.documentDate = documentDate.toDate()
    }
    if let uploadDate = networkModel.recordDocument.item.uploadDate {
      insertModel.uploadDate = uploadDate.toDate()
    }
    insertModel.documentHash = UUID().uuidString /// To update ui
    insertModel.documentID = networkModel.recordDocument.item.documentID
    if let documentType = networkModel.recordDocument.item.documentType {
      insertModel.documentType = documentType
    }
    /// Form smart of the document
    insertModel.isSmart = networkModel.recordDocument.item.metadata?.autoTags?.contains(where: { $0 == RecordDocumentTagType.smartTag.networkName }) ?? false
    if let oid = networkModel.recordDocument.item.patientID {
      insertModel.oid = oid
    }
    
    // Extract tags from metadata
    if let tags = networkModel.recordDocument.item.metadata?.tags {
      insertModel.tags = tags
    }
    
    if let updatedAt = networkModel.recordDocument.item.updatedAt {
      insertModel.updatedAt = updatedAt.toDate()
    }
    insertModel.syncState = RecordSyncState.upload(success: true)
    /// Assign cases array if available
    insertModel.caseIDs = networkModel.recordDocument.item.cases
    /// Form Thumbnail asynchronously
    if let thumbnail = networkModel.recordDocument.item.metadata?.thumbnail, !thumbnail.isEmpty {
      formLocalThumbnailFileNameFromNetworkURL(
        networkUrlString: thumbnail
      ) { localFileName in
        if let localFileName {
          insertModel.thumbnail = localFileName
        }
        // Always call completion even if thumbnail download failed
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
    guard let networkUrl = URL(string: networkUrlString) else {
      EkaMedicalRecordsCoreLogger.capture("Invalid thumbnail URL: \(networkUrlString)")
      completion(nil)
      return
    }
    FileHelper.downloadData(from: networkUrl) { thumbnailData, error in
      if let thumbnailData {
        let localThumbnailURL = FileHelper.writeDataToDocumentDirectoryAndGetFileName(
          thumbnailData,
          fileExtension: FileType.image.fileExtension
        )
        completion(localThumbnailURL)
      } else {
        EkaMedicalRecordsCoreLogger.capture("Failed to download thumbnail: \(error?.localizedDescription ?? "Unknown error")")
        completion(nil)
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

// MARK: - Cases

extension RecordDatabaseAdapter {
  /// Used to serialize smart report info
  /// - Parameter smartReport: smartReportInfo object that is to be serialized
  /// - Returns: serialized data for the smart report
  func convertNetworkToCaseDatabaseModel(
    from networkModels: [CaseElement],
    completion: @escaping ([CaseArguementModel]) -> Void
  ) {
    var insertModels = [CaseArguementModel]()
    /// Dispatch group to handle async conversion
    let dispatchGroup = DispatchGroup()
    networkModels.forEach { networkModel in
      dispatchGroup.enter()
      convertNetworkModelToInsertCaseModel(from: networkModel) { insertModel in
        insertModels.append(insertModel)
        dispatchGroup.leave()
      }
    }
    /// Once we have all insert models we send in completion
    dispatchGroup.notify(queue: .main) {
      completion(insertModels)
    }
  }
  
  private func convertNetworkModelToInsertCaseModel(
      from networkModel: CaseElement,
      completion: @escaping (CaseArguementModel) -> Void
    ) {
      var insertModel = CaseArguementModel()
      
      // Map the network model properties to CaseArguementModel properties
      insertModel.caseId = networkModel.id
      //TODO: - shekhar need to check how to get oid
      insertModel.oid = CoreInitConfigurations.shared.filterID?.first
      
      // Map document type to case type if available
      if let caseTypeString = networkModel.item?.type {
        insertModel.caseType = caseTypeString
      }
      
      // Map dates
      if let createdDate = networkModel.item?.createdAt {
        insertModel.createdAt = createdDate.toDate()
      }
      
      if let occuredAt = networkModel.item?.occuredAt {
        insertModel.occuredAt = occuredAt.toDate()
      }
      
      if let updatedAt = networkModel.updatedAt {
        insertModel.updatedAt = updatedAt.toDate()
      }
      
      if let name = networkModel.item?.displayName {
        insertModel.name = name
      }
      
      if let status = networkModel.status {
        insertModel.status = status
      }
      
      // Set remote creation flag
      insertModel.isRemoteCreated = true
      insertModel.isEdited = false
      
      completion(insertModel)
    }
}

