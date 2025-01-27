//
//  DocumentMetaData.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

import Foundation

struct DocumentMetaData: Equatable {
  let name: String
  let size: Int?
  let url: URL
  let type: EkaFileMimeType
  
  static func == (lhs: DocumentMetaData, rhs: DocumentMetaData) -> Bool {
    return lhs.name == rhs.name
    && lhs.url == rhs.url
    && lhs.type == rhs.type
  }
}
