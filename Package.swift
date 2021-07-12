// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MovieContentService",
    platforms: [
        .macOS("12"),
        .iOS("15"),
    ],
    products: [
        .library(
            name: "MovieContentService",
            targets: ["MovieContentService"]),
    ],
    dependencies: [
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "MovieContentService",
            dependencies: [
                "OpenCombine",
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
                .product(name: "OpenCombineDispatch", package: "OpenCombine")
            ]),
    ]
)
