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
    .package(url: "https://github.com/eka-care/proto-contracts.git", .upToNextMajor(from: "1.29.30")),
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2"))
  ],
  targets: [
    .target(
      name: "EkaMedicalRecordsCore",
      dependencies: [
        .product(name: "Alamofire", package: "Alamofire"),
        .product(name: "SwiftProtoContracts", package: "proto-contracts")
      ],
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "EkaMedicalRecordsCoreTests",
      dependencies: ["EkaMedicalRecordsCore"]
    ),
  ]
)
