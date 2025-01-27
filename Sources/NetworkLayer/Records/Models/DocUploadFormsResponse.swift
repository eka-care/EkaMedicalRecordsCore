//
//  DocUploadFormsResponse.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

struct DocUploadFormsResponse: Codable {
  let error: Bool?
  let message: String?
  let batchResponses: [BatchResponse]?
  let token: String?
  
  enum CodingKeys: String, CodingKey {
    case error, message
    case batchResponses = "batch_response"
    case token
  }
  
  struct BatchResponse: Codable {
    let documentID: String?
    let forms: [Form]?
    
    enum CodingKeys: String, CodingKey {
      case documentID = "document_id"
      case forms
    }
  }
  
  struct Form: Codable {
    let url: String?
    let fields: [String: String]?
  }
  
  typealias Fields = [String: String]?
}
