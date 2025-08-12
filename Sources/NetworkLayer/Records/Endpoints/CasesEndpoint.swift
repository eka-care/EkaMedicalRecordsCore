//
//  CasesEndpoint.swift
//  EkaMedicalRecordsCore
//
//  Created by shekhar gupta on 11/08/25.
//

import Alamofire
import Foundation

enum CasesEndpoint {
  
  /// Create a new case
  case createCases(
    oid: String,
    request: CasesCreateRequest
  )
  
  /// Fetch list of cases (supports pagination via token and filtering via updatedAt)
  case fetchCasesList(
    token: String?,
    updatedAt: String?,
    oid: String
  )
  
  // TODO: Shekhar - Need to check how to send `oid` for delete API
  /// Delete a case by ID
  case delete(
    caseId: String,
    oid: String
  )
  
  /// Update an existing case
  case updateCases(
    caseId: String,
    oid: String,
    request: CasesUpdateRequest
  )
}

extension CasesEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
      
      // MARK: Create new case
    case .createCases(let oid, let request):
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/cases",
        method: .post,
        parameters: request,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue), .init(name: "X-Pt-Id", value: oid)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
      // MARK: Fetch list of cases
    case .fetchCasesList(let token, let updatedAt, let oid):
      var params = [String: String]()
      
      if let token {
        params["offset"] = token
      }
      
      if let updatedAt {
        params["u_at__gt"] = updatedAt
      }
      
      //      if let oid {
      //        params["p_oid"] = oid
      //      }
      
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/cases",
        method: .get,
        parameters: params,
        encoding: URLEncoding.queryString,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue), .init(name: "X-Pt-Id", value: oid)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
      // MARK: Delete case
    case .delete(let caseId, let oid):
//      var params = [String: String]()
//      
//      if let oid {
//        params["p_oid"] = oid
//      }
      
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/cases/\(caseId)",
        method: .delete,
        encoding: URLEncoding.queryString,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue), .init(name: "X-Pt-Id", value: oid)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
      
      
      // MARK: Update existing case
    case .updateCases(let caseId, let oid, let request):
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/cases/\(caseId)",
        method: .patch,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue), .init(name: "X-Pt-Id", value: oid)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
    }
  }
}
