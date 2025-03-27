//
//  VaultRecordDocumentType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 28/03/25.
//

import SwiftProtoContracts

public extension Vault_Records_DocumentType {
  var title: String {
    switch self {
    case .typeUnspecified: return "Unspecified"
    case .typeLabReport: return "Lab Report"
    case .typePrescription: return "Prescription"
    case .typeDischargeSummary: return "Discharge Summary"
    case .typeVaccineCertificate: return "Vaccine Certificate"
    case .typeInsurance: return "Insurance"
    case .typeInvoice: return "Invoice"
    case .typeScan: return "Scan"
    case .typeOther: return "Other"
    case .UNRECOGNIZED(let rawValue): return "Unknown (\(rawValue))"
    }
  }
  
  var shortHand: String {
    switch self {
    case .typeUnspecified, .UNRECOGNIZED:
      return ""
    case .typeLabReport:
      return "lr"
    case .typePrescription:
      return "ps"
    case .typeDischargeSummary:
      return "ds"
    case .typeVaccineCertificate:
      return "vc"
    case .typeInsurance:
      return "in"
    case .typeInvoice:
      return "iv"
    case .typeScan:
      return "sc"
    case .typeOther:
      return "ot"
    }
  }
}
