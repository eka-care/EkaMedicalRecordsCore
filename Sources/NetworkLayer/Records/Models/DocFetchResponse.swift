//
//  DocFetchResponse.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 04/02/25.
//

import Foundation

// MARK: - DocFetchResponse

struct DocFetchResponse: Codable, Hashable {
  let documentID: String?
  let description: String?
  let patientName, authorizer: String?
  let documentDate: String?
  let documentType: String?
  let tags: [String]?
  let canDelete: Bool?
  let files: [File]?
  let smartReport: SmartReportInfo?
  let userTags: [String]?
  let derivedTags: [String]?
  let thumbnail: String?
  let fileExtension: String?
  let sharedWith: [String]?
  let uploadedByMe: Bool?
  
  enum CodingKeys: String, CodingKey {
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
  
  static func == (lhs: DocFetchResponse, rhs: DocFetchResponse) -> Bool {
    return lhs.documentID == rhs.documentID
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(documentID)
  }
}

// MARK: - File

struct File: Codable {
  let assetURL: String?
  let fileType, shareText: String?
  let maskedFile: MaskedFile?
  
  enum CodingKeys: String, CodingKey {
    case assetURL = "asset_url"
    case fileType = "file_type"
    case shareText = "share_text"
    case maskedFile = "masked_file"
  }
}

// MARK: - MaskedFile
struct MaskedFile: Codable {
  let assetURL: String?
  let fileType, shareText, title, body: String?
  let tagline: String?
  
  enum CodingKeys: String, CodingKey {
    case assetURL = "asset_url"
    case fileType = "file_type"
    case shareText = "share_text"
    case title, body, tagline
  }
}

// MARK: - SmartReport
public struct SmartReportInfo: Codable, Equatable {
  public let verified, unverified: [Verified]?
}

// MARK: - Verified
public struct Verified: Codable, Hashable, Identifiable {
  public let id = UUID()
  public let name, value, unit: String?
  public let vitalID: String?
  public let ekaID: String?
  public let isResultEditable: Bool?
  public let pageNum, fileIndex: Int?
  public let coordinates: [Coordinate]?
  public let range, result, resultID, displayResult: String?
  public let date: Int?
  
  enum CodingKeys: String, CodingKey {
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
}

// MARK: - Coordinate
public struct Coordinate: Codable, Hashable {
  public let x: Double?
  public let y: Double?
}
