// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "XcodeEdit",
  platforms: [
    .macOS(.v10_10)
  ],
  products: [
    .library(name: "XcodeEdit", targets: ["XcodeEdit"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "XcodeEdit"),
  ]
)

