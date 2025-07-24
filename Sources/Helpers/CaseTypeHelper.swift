//
//  CaseTypePreloadData.swift
//  EkaMedicalRecordsCore
//
//  Created by Shekhar Gupta on 24/07/25.
//
struct CaseTypePreloadData {
  static let all: [CaseTypeModel] = [
    CaseTypeModel(name: "Doctor Visit (OPD)", icon: CaseIcon.doctor.rawValue),
    CaseTypeModel(name: "Hospital Visit (IPD)", icon: CaseIcon.hospital.rawValue),
    CaseTypeModel(name: "Health Checkup", icon: CaseIcon.checkup.rawValue),
    CaseTypeModel(name: "Home Visit", icon: CaseIcon.home.rawValue),
    CaseTypeModel(name: "Teleconsultation", icon: CaseIcon.teleconsult.rawValue),
    CaseTypeModel(name: "Emergency", icon: CaseIcon.emergency.rawValue),
    CaseTypeModel(name: "Dental", icon: CaseIcon.dental.rawValue),
    CaseTypeModel(name: "Other", icon: CaseIcon.other.rawValue)
  ]
}

enum CaseIcon: String {
  case doctor = "doctorVisit"
  case hospital = "hospitalVisit"
  case checkup = "healthCheckup"
  case home = "homeVisit"
  case teleconsult = "teleconsultation"
  case emergency = "emergency"
  case dental = "dental"
  case other = "other"
}
