// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ADAR2LintPlugin",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "adar2-lint", targets: ["adar2-lint"]),
        .plugin(name: "ADAR2LintPlugin", targets: ["ADAR2LintPlugin"]),
        .plugin(name: "GenerateADARModel", targets: ["GenerateADARModel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0"),
        .package(path: "../ADAR2Shared"),
    ],
    targets: [
        // The linter executable. Only needs ADAR2Shared to decode the .adar file.
        .executableTarget(
            name: "adar2-lint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ADAR2Shared", package: "ADAR2Shared"),
            ]
        ),
        // SPM Build Tool Plugin — runs adar2-lint before every build.
        .plugin(
            name: "ADAR2LintPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "adar2-lint"),
            ]
        ),
        // SPM Command Plugin — generates .adar model files on demand.
        // In this nested development package the model builder is resolved from PATH
        // or ADAR_MODELBUILDER_PATH. The root public package builds it from source.
        .plugin(
            name: "GenerateADARModel",
            capability: .command(
                intent: .custom(
                    verb: "generate-adar-model",
                    description: "Generate the ADAR architecture model (.adar file) for Swift targets"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes .adar/<TargetName>.adar graph files to the package directory"),
                ]
            )
        ),
        .testTarget(
            name: "ADAR2LintTests",
            dependencies: ["adar2-lint"]
        ),
    ]
)
