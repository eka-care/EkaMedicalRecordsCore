//
//  RecordDocumentType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

enum RecordDocumentType: String {
  case typeLabReport = "lr"
  case typePrescription = "ps"
  case typeDischargeSummary = "ds"
  case typeVaccineCertificate = "vc"
  case typeInsurance = "in"
  case typeInvoice = "iv"
  case typeScan = "sc"
  case typeOther = "ot"
  
  var intValue: Int {
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
    }
  }
}
