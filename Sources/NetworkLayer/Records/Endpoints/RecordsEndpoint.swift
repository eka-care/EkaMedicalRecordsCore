//
//  RecordsEndpoint.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

import Alamofire
import Foundation

enum RecordsEndpoint {
  /// fetch records
  case fetchRecords(
    token: String?,
    updatedAt: String?,
    oid: String?
  )
  /// upload records v3
  case uploadRecords(
    request: DocUploadRequest,
    oid: String?
  )
  /// Submit documents
  case submitDocuments(
    file: Data,
    fileName: String,
    mimeType: EkaFileMimeType,
    urlString: String,
    formFields: DocUploadFormsResponse.Fields
  )
  /// delete
  case delete(
    documentId: String,
    oid: String?
  )
  /// Fetch doc details
  case fetchDocDetails(
    documentID: String,
    oid: String
  )
  /// Edit document details
  case editDocDetails(
    documentID: String,
    filterOID: String?,
    request: DocUpdateRequest
  )
}

extension RecordsEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
      /// Fetch records
    case .fetchRecords(
      let token,
      let updatedAt,
      let oid
    ):
      var params = [String: String]()
      
      if let token {
        params["offset"] = token
      }
      
      if let updatedAt {
        params["u_at__gt"] = updatedAt
      }
      
      if let oid {
        params["p_oid"] = oid
      }
      
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/docs",
        method: .get,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
    case .uploadRecords(let request, let oid):
      let oidQueryParamString = oid != nil ? "?p_oid=\(oid ?? "")" : ""
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/docs\(oidQueryParamString)",
        method: .post,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
    case .submitDocuments(let fileData, let fileName, let mimeType, let urlString, let field):
      return AF.upload(
        multipartFormData: { multipartFormData in
          
          if let field {
            /// Dynamically append fields
            for (key, value) in field {
              if let data = value.data(using: .utf8) {
                multipartFormData.append(data, withName: key)
              }
            }
          }
          
          multipartFormData.append(
            fileData,
            withName: "file",
            fileName: fileName,
            mimeType: mimeType.rawValue
          )
        },
        to: urlString,
        usingThreshold: UInt64.init(),
        method: .post,
        headers: HTTPHeaders([.contentType(HTTPHeader.multipartFormData.rawValue)]),
        interceptor: CoreInitConfigurations.shared.requestInterceptor,
        fileManager: .default,
        requestModifier: nil
      )
      .validate()
      /// delete
    case .delete(let documentID, let oid):
      var params = [String: String]()
      
      if let oid {
        params["p_oid"] = oid
      }
      let encodedDocID = documentID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? documentID
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/docs/\(encodedDocID)",
        method: .delete,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
      /// Fetch doc details
    case .fetchDocDetails(let documentID, let patientOID):
      var params = [String: String]()
      
      params["p_oid"] = patientOID
      let encodedDocID = documentID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? documentID
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/docs/\(encodedDocID)",
        method: .get,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
      
    case .editDocDetails(
      let documentID,
      let filterOID,
      let request
    ):
      let patientOidString = filterOID != nil ? "?p_oid=\(filterOID ?? "")" : ""
      let encodedDocID = documentID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? documentID
      return AF.request(
        "\(DomainConfigurations.ekaURL)/mr/api/v1/docs/\(encodedDocID)\(patientOidString)",
        method: .patch,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        interceptor: CoreInitConfigurations.shared.requestInterceptor
      )
      .validate()
    }
  }
}
