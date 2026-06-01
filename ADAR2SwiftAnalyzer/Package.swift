// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ADAR2SwiftAnalyzer",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ADAR2SwiftAnalyzer",
            targets: ["ADAR2SwiftAnalyzer"]),
    ],
    dependencies: [
        .package(path: "../ADAR2Core"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", exact: "4.3.0"),
        .package(url: "https://github.com/apple/swift-docc-symbolkit.git", exact: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.1.1"),

    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ADAR2SwiftAnalyzer",
            dependencies: [
                .product(name: "ADAR2Core", package: "ADAR2Core"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "ADAR2SwiftAnalyzerTests",
            dependencies: ["ADAR2SwiftAnalyzer"]
        ),
    ]
)
