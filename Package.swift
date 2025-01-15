// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EkaMedicalRecordsCore",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(
      name: "EkaMedicalRecordsCore",
      targets: ["EkaMedicalRecordsCore"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/eka-care/proto-contracts.git", branch: "main"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2"))
  ],
  targets: [
    .target(
      name: "EkaMedicalRecordsCore",
      dependencies: [
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "SwiftProtoContracts", package: "proto-contracts")
      ]
    ),
    .testTarget(
      name: "EkaMedicalRecordsCoreTests",
      dependencies: ["EkaMedicalRecordsCore"]
    ),
  ]
)
