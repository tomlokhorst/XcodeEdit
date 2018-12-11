// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "XcodeEdit",
  products: [
    .library(name: "XcodeEdit", targets: ["XcodeEdit"]),
  ],
  targets: [
    .target(name: "XcodeEdit"),
  ]
)

