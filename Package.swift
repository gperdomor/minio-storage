// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "MinioStorage",
    products: [
        .library(name: "MinioStorage", targets: ["MinioStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/anthonycastelli/simplestoragesigner.git", .branch("master")),
        .package(url: "https://github.com/gperdomor/storage-kit.git", from: "0.2.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.3.0")
    ],
    targets: [
        .target( name: "MinioStorage", dependencies: ["SimpleStorageSigner", "StorageKit", "AEXML"]),
        .testTarget(name: "MinioStorageTests", dependencies: ["MinioStorage"])
    ]
)
