//
//  RecordsEndpoint.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Alamofire

enum RecordsEndpoint {
  /// fetch records
  case fetchRecords(token: String?, updatedAt: String?)
}

extension RecordsEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
      /// Fetch records
    case .fetchRecords(
      let token,
      let updatedAt
    ):
      var params = [String: String]()
      
      if let token {
        params["offset"] = token
      }
      
      if let updatedAt {
        params["u_at__gt"] = updatedAt
      }
      
      return AF.request(
        "\(DomainConfigurations.vaultURL)/api/v4/docs",
        method: .get,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
