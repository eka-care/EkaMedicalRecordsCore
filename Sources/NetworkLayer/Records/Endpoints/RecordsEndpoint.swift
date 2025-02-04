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
  case uploadRecords(request: DocUploadRequest)
  /// Submit documents
  case submitDocuments(file: Data, fileName: String, mimeType: EkaFileMimeType, urlString: String, formFields: DocUploadFormsResponse.Fields)
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
        params["oid"] = oid
      }
      
      return AF.request(
        "\(DomainConfigurations.vaultURL)/api/d/v1/docs",
        method: .get,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      
    case .uploadRecords(let request):
      return AF.request(
        "\(DomainConfigurations.vaultURL)/api/v3/docs",
        method: .post,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        interceptor: NetworkRequestInterceptor()
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
        interceptor: NetworkRequestInterceptor(),
        fileManager: .default,
        requestModifier: nil
      )
      .validate()
      /// delete
    case .delete(let documentID, let oid):
      var params = [String: String]()
      
      if let oid {
        params["oid"] = oid
      }
      
      return AF.request(
        "\(DomainConfigurations.vaultURL)/api/v1/docs/\(documentID)",
        method: .delete,
        parameters: params,
        encoding: URLEncoding.queryString,
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      
      /// Fetch doc details
    case .fetchDocDetails(let documentID, let patientOID):
      var params = [String: String]()
      
      params["oid"] = patientOID
      
      return AF.request(
        "\(DomainConfigurations.vaultURL)/api/v1/docs/\(documentID)",
        method: .get,
        parameters: params,
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
