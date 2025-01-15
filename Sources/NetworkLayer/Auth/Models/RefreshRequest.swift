//
//  RefreshRequest.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Foundation

struct RefreshRequest: Codable {
  let refresh: String
  let sess: String
}
