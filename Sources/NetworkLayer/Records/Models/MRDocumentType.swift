//
//  MRDocumentType.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 23/09/25.
//


// MARK: - MRDocumentType
public struct MRDocumentType: Codable {
  public let hex: String?
  public let bgHex: String?
  public let archive: Bool?
  public let id: String?
  public let displayName: String?

  enum CodingKeys: String, CodingKey {
    case hex = "hex"
    case bgHex = "bg_hex"
    case archive = "archive"
    case id = "id"
    case displayName = "display_name"
  }
}


extension MRDocumentType: Hashable {
  public static func == (lhs: MRDocumentType, rhs: MRDocumentType) -> Bool {
    return lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension MRDocumentType: Identifiable {
  public var intValue: Int {
    return Int(id ?? "0") ?? 0
  }
  
  public var filterName: String {
    return displayName ?? "Unknown"
  }
  
  public static func from(intValue: Int) -> MRDocumentType? {
    return allCases.first { $0.id == String(intValue) }
  }
  
  public static var allCases: [MRDocumentType] {
    // TODO: This should be populated from your data source
    // For now, providing basic document types
    return [
      typeAll,
      MRDocumentType(hex: "#10B981", bgHex: "#ECFDF5", archive: false, id: "1", displayName: "Lab Report"),
      MRDocumentType(hex: "#EF4444", bgHex: "#FEF2F2", archive: false, id: "2", displayName: "Prescription"),
      MRDocumentType(hex: "#10B981", bgHex: "#ECFDF5", archive: false, id: "3", displayName: "Discharge Summary"),
      MRDocumentType(hex: "#3B82F6", bgHex: "#EFF6FF", archive: false, id: "4", displayName: "Vaccine Certificate"),
      MRDocumentType(hex: "#3B82F6", bgHex: "#EFF6FF", archive: false, id: "5", displayName: "Insurance"),
      MRDocumentType(hex: "#EF4444", bgHex: "#FEF2F2", archive: false, id: "6", displayName: "Invoice"),
      MRDocumentType(hex: "#EF4444", bgHex: "#FEF2F2", archive: false, id: "7", displayName: "Scan"),
      MRDocumentType(hex: "#10B981", bgHex: "#ECFDF5", archive: false, id: "8", displayName: "Other")
    ]
  }
  
  public static var typeAll: MRDocumentType {
    return MRDocumentType(hex: nil, bgHex: nil, archive: false, id: "0", displayName: "All")
  }
}
