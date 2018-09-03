// swift-tools-version:4.0
import PackageDescription

let package = Package(
  name: "XcodeEdit",
  products: [
    .library(name: "XcodeEdit", targets: ["XcodeEdit"]),
  ],
  targets: [
    .target(name: "XcodeEdit"),
  ],
  swiftLanguageVersions: [4]
)

