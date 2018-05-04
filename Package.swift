// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MinioStorage",
    products: [
        .library(name: "MinioStorage", targets: ["MinioStorage"])
    ],
    dependencies: [],
    targets: [
        .target( name: "MinioStorage", dependencies: []),
        .testTarget(name: "MinioStorageTests", dependencies: ["MinioStorage"])
    ]
)
