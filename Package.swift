// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ADAR",
    platforms: [.macOS(.v13)],
    products: [
        .plugin(name: "ADAR2LintPlugin", targets: ["ADAR2LintPlugin"]),
        .plugin(name: "GenerateADARModel", targets: ["GenerateADARModel"]),
        .executable(name: "adar2-lint", targets: ["adar2-lint"]),
        .executable(name: "ADAR2ModelBuilder", targets: ["ADAR2ModelBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", exact: "4.3.0"),
        .package(url: "https://github.com/apple/swift-docc-symbolkit.git", exact: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.1.1"),
    ],
    targets: [
        .target(
            name: "ADAR2Shared",
            path: "ADAR2Shared/Sources/ADAR2Shared"
        ),
        .target(
            name: "ADAR2Core",
            dependencies: ["ADAR2Shared"],
            path: "ADAR2Core/Sources/ADAR2Core",
            exclude: ["Graph/README.md"]
        ),
        .target(
            name: "ADAR2SwiftAnalyzer",
            dependencies: [
                "ADAR2Core",
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "ADAR2SwiftAnalyzer/Sources/ADAR2SwiftAnalyzer"
        ),
        .target(
            name: "ADAR2AdvancedForceDirectedVisualizer",
            dependencies: ["ADAR2Core"],
            path: "ADAR2AdvancedForceDirectedVisualizer/Sources/ADAR2AdvancedForceDirectedVisualizer"
        ),
        .target(
            name: "ADAR2NaiveForceDirectedVisualizer",
            dependencies: ["ADAR2Core"],
            path: "ADAR2NaiveForceDirectedVisualizer/Sources/ADAR2NaiveForceDirectedVisualizer"
        ),
        .target(
            name: "ADAR2MLVisualizer",
            dependencies: [
                "ADAR2Core",
                "ADAR2AdvancedForceDirectedVisualizer",
                "ADAR2NaiveForceDirectedVisualizer",
            ],
            path: "ADAR2MLVisualizer/Sources/ADAR2MLVisualizer",
            resources: [
                .copy("Resources/gnn_2-L_model_5000.mlpackage"),
                .copy("Resources/gnn_3-L_model_5000.mlpackage"),
                .copy("Resources/gnn_4-L_model_5000.mlpackage"),
            ]
        ),
        .target(
            name: "ADAR2BugDetector",
            dependencies: ["ADAR2Shared"],
            path: "ADAR2BugDetector/Sources/ADAR2BugDetector"
        ),
        .executableTarget(
            name: "adar2-lint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ADAR2Shared",
            ],
            path: "ADAR2LintPlugin/Sources/adar2-lint"
        ),
        .executableTarget(
            name: "ADAR2ModelBuilder",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ADAR2Shared",
                "ADAR2Core",
                "ADAR2SwiftAnalyzer",
                "ADAR2AdvancedForceDirectedVisualizer",
                "ADAR2NaiveForceDirectedVisualizer",
                "ADAR2MLVisualizer",
                "ADAR2BugDetector",
            ],
            path: "ADAR2ModelBuilder/Sources"
        ),
        .plugin(
            name: "ADAR2LintPlugin",
            capability: .buildTool(),
            dependencies: ["adar2-lint"],
            path: "ADAR2LintPlugin/Plugins/ADAR2LintPlugin"
        ),
        .plugin(
            name: "GenerateADARModel",
            capability: .command(
                intent: .custom(
                    verb: "generate-adar-model",
                    description: "Generate ADAR architecture models for Swift targets"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes .adar graph files to the package directory"),
                ]
            ),
            dependencies: ["ADAR2ModelBuilder"],
            path: "ADAR2LintPlugin/Plugins/GenerateADARModel"
        ),
    ]
)
