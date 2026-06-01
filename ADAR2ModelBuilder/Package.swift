// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ADAR2ModelBuilder",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0"),
        .package(path: "../ADAR2Shared"),
        .package(path: "../ADAR2Core"),
        .package(path: "../ADAR2SwiftAnalyzer"),
        .package(path: "../ADAR2AdvancedForceDirectedVisualizer"),
        .package(path: "../ADAR2NaiveForceDirectedVisualizer"),
        .package(path: "../ADAR2MLVisualizer"),
        .package(path: "../ADAR2BugDetector"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ADAR2ModelBuilder",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ADAR2Shared", package: "ADAR2Shared"),
                .product(name: "ADAR2Core", package: "ADAR2Core"),
                .product(name: "ADAR2SwiftAnalyzer", package: "ADAR2SwiftAnalyzer"),
                .product(name: "ADAR2AdvancedForceDirectedVisualizer", package: "ADAR2AdvancedForceDirectedVisualizer"),
                .product(name: "ADAR2NaiveForceDirectedVisualizer", package: "ADAR2NaiveForceDirectedVisualizer"),
                .product(name: "ADAR2MLVisualizer", package: "ADAR2MLVisualizer"),
                .product(name: "ADAR2BugDetector", package: "ADAR2BugDetector"),
            ]
        ),
    ]
)
