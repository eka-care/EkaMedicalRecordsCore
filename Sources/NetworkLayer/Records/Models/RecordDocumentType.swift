//
//  RecordDocumentType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

public enum RecordDocumentType: String, CaseIterable {
  case typeAll = "all"
  case typeLabReport = "lr"
  case typePrescription = "ps"
  case typeDischargeSummary = "ds"
  case typeVaccineCertificate = "vc"
  case typeInsurance = "in"
  case typeInvoice = "iv"
  case typeScan = "sc"
  case typeOther = "ot"
  
  public var intValue: Int {
    switch self {
    case .typeLabReport:
      return 1
    case .typePrescription:
      return 2
    case .typeDischargeSummary:
      return 3
    case .typeVaccineCertificate:
      return 4
    case .typeInsurance:
      return 5
    case .typeInvoice:
      return 6
    case .typeScan:
      return 7
    case .typeOther:
      return 8
    case .typeAll:
      return 0
    }
  }
  
  public var filterName: String {
    switch self {
    case .typeAll:
      return "All"
    case .typeLabReport:
      return "Lab Report"
    case .typePrescription:
      return "Prescription"
    case .typeDischargeSummary:
      return "Discharge Summary"
    case .typeVaccineCertificate:
      return "Vaccine Certificate"
    case .typeInsurance:
      return "Insurance"
    case .typeInvoice:
      return "Invoice"
    case .typeScan:
      return "Scan"
    case .typeOther:
      return "Other"
    }
  }
  
  public static func from(intValue: Int?) -> RecordDocumentType? {
    guard let intValue else { return nil }
    return RecordDocumentType.allCases.first { $0.intValue == intValue }
  }
  
  public static func from(filterName: String) -> RecordDocumentType? {
    return RecordDocumentType.allCases.first { $0.filterName == filterName }
  }
}


// MARK: - MRDocumentType
public struct MRDocumentType: Codable {
  let hex: String?
  let bgHex: String?
  let archive: Bool?
  let id: String?
  let displayName: String?

  enum CodingKeys: String, CodingKey {
    case hex = "hex"
    case bgHex = "bg_hex"
    case archive = "archive"
    case id = "id"
    case displayName = "display_name"
  }
}
