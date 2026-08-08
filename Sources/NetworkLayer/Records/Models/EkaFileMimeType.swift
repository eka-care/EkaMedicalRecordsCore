//
//  EkaFileMimeType.swift
//  EkaMedicalRecordsCore
//
//  Created by Arya Vashisht on 27/01/25.
//

enum EkaFileMimeType: String {
  case imageJpg = "image/jpeg"
  case pdf = "application/pdf"
  case audio = "audio/aac"
  case video = "video/mp4"
  case html = "text/html"
  
  public var uiHelperValue: String {
    switch self {
    case .imageJpg:
      return "imageJpg"
    case .pdf:
      return "pdf"
    case .audio:
      return "audio"
    case .video:
      return "video"
    case .html:
      return "html"
    }
  }
  
  public var fileExtension: String {
    switch self {
    case .audio:
      return ".m4a"
    case .video:
      return ".mp4"
    case .imageJpg:
      return ".jpg"
    case .pdf:
      return ".pdf"
    case .html:
      return ".html"
    }
  }
}
