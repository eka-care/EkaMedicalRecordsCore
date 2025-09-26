//
//  MRDocumentType.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 23/09/25.
//


public struct MRDocumentType: Codable, Hashable, Identifiable {
  public let hex: String?
  public let bgHex: String?
  public let archive: Bool?
  public let id: String?
  public let displayName: String?

  // MARK: - Coding Keys
  enum CodingKeys: String, CodingKey {
      case hex
      case bgHex = "bg_hex"
      case archive
      case id
      case displayName = "display_name"
  }
  
  public init (
    hex: String? = nil,
    bgHex: String? = nil,
    archive: Bool? = nil,
    id: String? = nil,
    displayName: String? = nil
  ) {
    self.hex = hex
    self.bgHex = bgHex
    self.archive = archive
    self.id = id
    self.displayName = displayName
  }

  // MARK: - Hashable
  public static func == (lhs: MRDocumentType, rhs: MRDocumentType) -> Bool {
      lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }

  // MARK: - Identifiable
  public var intValue: String {
      id ?? ""
  }

  public var filterName: String {
      displayName ?? "Unknown"
  }

  // MARK: - Helpers
  /// Special "All" type for filters
  public static var typeAll: MRDocumentType {
      MRDocumentType(
          hex: nil,
          bgHex: nil,
          archive: false,
          id: "",
          displayName: "All"
      )
  }
}
