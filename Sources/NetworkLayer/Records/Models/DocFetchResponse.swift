//
//  DocFetchResponse.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 04/02/25.
//

import Foundation

// MARK: - DocFetchResponse

public struct DocFetchResponse: Codable, Hashable {
  public let documentID: String?
  public let description: String?
  public let patientName: String?
  public let authorizer: String?
  public let documentDate: String?
  public let documentType: String?
  public let tags: [String]?
  public let canDelete: Bool?
  public let files: [File]?
  public let smartReport: SmartReportInfo?
  public let userTags: [String]?
  public let derivedTags: [String]?
  public let thumbnail: String?
  public let fileExtension: String?
  public let sharedWith: [String]?
  public let uploadedByMe: Bool?
  
  public enum CodingKeys: String, CodingKey {
    case documentID = "document_id"
    case description
    case patientName = "patient_name"
    case authorizer
    case documentDate = "document_date"
    case documentType = "document_type"
    case tags
    case canDelete = "can_delete"
    case files
    case smartReport = "smart_report"
    case userTags = "user_tags"
    case derivedTags = "derived_tags"
    case thumbnail = "thumbnail"
    case fileExtension = "file_type"
    case sharedWith = "shared_with"
    case uploadedByMe = "uploaded_by_me"
  }
  
  public static func == (lhs: DocFetchResponse, rhs: DocFetchResponse) -> Bool {
    return lhs.documentID == rhs.documentID
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(documentID)
  }
  
  public init(
    documentID: String? = nil,
    description: String? = nil,
    patientName: String? = nil,
    authorizer: String? = nil,
    documentDate: String? = nil,
    documentType: String? = nil,
    tags: [String]? = nil,
    canDelete: Bool? = nil,
    files: [File]? = nil,
    smartReport: SmartReportInfo? = nil,
    userTags: [String]? = nil,
    derivedTags: [String]? = nil,
    thumbnail: String? = nil,
    fileExtension: String? = nil,
    sharedWith: [String]? = nil,
    uploadedByMe: Bool? = nil
  ) {
    self.documentID = documentID
    self.description = description
    self.patientName = patientName
    self.authorizer = authorizer
    self.documentDate = documentDate
    self.documentType = documentType
    self.tags = tags
    self.canDelete = canDelete
    self.files = files
    self.smartReport = smartReport
    self.userTags = userTags
    self.derivedTags = derivedTags
    self.thumbnail = thumbnail
    self.fileExtension = fileExtension
    self.sharedWith = sharedWith
    self.uploadedByMe = uploadedByMe
  }
}

// MARK: - File

public struct File: Codable {
  public let assetURL: String?
  public let fileType: String?
  public let shareText: String?
  public let maskedFile: MaskedFile?
  
  public enum CodingKeys: String, CodingKey {
    case assetURL = "asset_url"
    case fileType = "file_type"
    case shareText = "share_text"
    case maskedFile = "masked_file"
  }
  
  public init(
    assetURL: String? = nil,
    fileType: String? = nil,
    shareText: String? = nil,
    maskedFile: MaskedFile? = nil
  ) {
    self.assetURL = assetURL
    self.fileType = fileType
    self.shareText = shareText
    self.maskedFile = maskedFile
  }
}

// MARK: - MaskedFile

public struct MaskedFile: Codable {
  public let assetURL: String?
  public let fileType: String?
  public let shareText: String?
  public let title: String?
  public let body: String?
  public let tagline: String?
  
  public enum CodingKeys: String, CodingKey {
    case assetURL = "asset_url"
    case fileType = "file_type"
    case shareText = "share_text"
    case title, body, tagline
  }
  
  public init(
    assetURL: String? = nil,
    fileType: String? = nil,
    shareText: String? = nil,
    title: String? = nil,
    body: String? = nil,
    tagline: String? = nil
  ) {
    self.assetURL = assetURL
    self.fileType = fileType
    self.shareText = shareText
    self.title = title
    self.body = body
    self.tagline = tagline
  }
}

// MARK: - SmartReport

public struct SmartReportInfo: Codable, Equatable {
  public let verified: [Verified]?
  public let unverified: [Verified]?
  
  public init(verified: [Verified]? = nil, unverified: [Verified]? = nil) {
    self.verified = verified
    self.unverified = unverified
  }
}

// MARK: - Verified

public struct Verified: Codable, Hashable, Identifiable {
  public let id = UUID()
  public let name: String?
  public let value: String?
  public let unit: String?
  public let vitalID: String?
  public let ekaID: String?
  public let isResultEditable: Bool?
  public let pageNum: Int?
  public let fileIndex: Int?
  public let coordinates: [Coordinate]?
  public let range: String?
  public let result: String?
  public let resultID: String?
  public let displayResult: String?
  public let date: Int?
  
  public enum CodingKeys: String, CodingKey {
    case name, value, unit, date
    case vitalID = "vital_id"
    case ekaID = "eka_id"
    case isResultEditable = "is_result_editable"
    case pageNum = "page_num"
    case fileIndex = "file_index"
    case coordinates, range, result
    case resultID = "result_id"
    case displayResult = "display_result"
  }
  
  public static func == (lhs: Verified, rhs: Verified) -> Bool {
    return lhs.vitalID == rhs.vitalID
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(vitalID)
  }
  
  public init(
    name: String? = nil,
    value: String? = nil,
    unit: String? = nil,
    vitalID: String? = nil,
    ekaID: String? = nil,
    isResultEditable: Bool? = nil,
    pageNum: Int? = nil,
    fileIndex: Int? = nil,
    coordinates: [Coordinate]? = nil,
    range: String? = nil,
    result: String? = nil,
    resultID: String? = nil,
    displayResult: String? = nil,
    date: Int? = nil
  ) {
    self.name = name
    self.value = value
    self.unit = unit
    self.vitalID = vitalID
    self.ekaID = ekaID
    self.isResultEditable = isResultEditable
    self.pageNum = pageNum
    self.fileIndex = fileIndex
    self.coordinates = coordinates
    self.range = range
    self.result = result
    self.resultID = resultID
    self.displayResult = displayResult
    self.date = date
  }
}

// MARK: - Coordinate

public struct Coordinate: Codable, Hashable {
  public let x: Double?
  public let y: Double?
  
  public init(x: Double? = nil, y: Double? = nil) {
    self.x = x
    self.y = y
  }
}
