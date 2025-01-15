//
//  AuthEndpoint.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Alamofire

enum AuthEndpoint {
  case tokenRefresh(refreshRequest: RefreshRequest)
}

extension AuthEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
    case .tokenRefresh(let refreshRequest):
      AF.request(
        "\(DomainConfigurations.authURL)/auth/refresh",
        method: .post,
        parameters: refreshRequest,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
