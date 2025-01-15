//
//  SwiftProtobuf.Google_Protobuf_Timestamp + Extension.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 03/01/25.
//

import SwiftProtobuf
import Foundation

extension SwiftProtobuf.Google_Protobuf_Timestamp {
  func toDate() -> Date {
    return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanos) / 1_000_000_000)
  }
}
