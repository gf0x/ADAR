// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ADAR2MLVisualizer",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ADAR2MLVisualizer",
            targets: ["ADAR2MLVisualizer"]),
    ],
    dependencies: [
        .package(path: "../ADAR2Core"),
        .package(path: "../ADAR2AdvancedForceDirectedVisualizer"),
        .package(path: "../ADAR2NaiveForceDirectedVisualizer"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ADAR2MLVisualizer",
            dependencies: [
                .product(name: "ADAR2Core", package: "ADAR2Core"),
                .product(name: "ADAR2AdvancedForceDirectedVisualizer", package: "ADAR2AdvancedForceDirectedVisualizer"),
                .product(name: "ADAR2NaiveForceDirectedVisualizer", package: "ADAR2NaiveForceDirectedVisualizer"),
            ],
            resources: [
                .copy("Resources/gnn_2-L_model_5000.mlpackage"),
                .copy("Resources/gnn_3-L_model_5000.mlpackage"),
                .copy("Resources/gnn_4-L_model_5000.mlpackage"),
            ]
        ),
        .testTarget(
            name: "ADAR2MLVisualizerTests",
            dependencies: ["ADAR2MLVisualizer"]
        ),
    ]
)
