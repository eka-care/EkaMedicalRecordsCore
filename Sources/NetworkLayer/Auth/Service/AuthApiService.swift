//
//  AuthApiService.swift
//  EkaMedicalRecordsCoreSdk
//
//  Created by Arya Vashisht on 05/01/25.
//

final class AuthApiService: AuthProvider, Sendable {
  let networkService: Networking = NetworkService.shared
}
