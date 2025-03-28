//
//  RecordDocumentTagType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/03/25.
//

enum RecordDocumentTagType {
  case smartTag
  
  var networkName: String {
    switch self {
    case .smartTag:
      return "TYPE_TAG_SMART"
    }
  }
}
