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
        "\(DomainConfigurations.apiURL)/connect-auth/v1/account/refresh",
        method: .post,
        parameters: refreshRequest,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
    }
  }
}
