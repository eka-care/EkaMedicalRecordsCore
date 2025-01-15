//
//  RequestProvider.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Alamofire

public protocol RequestProvider {
  var urlRequest: DataRequest { get }
}
