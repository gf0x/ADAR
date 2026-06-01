// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import ADAR2Core
import ADAR2SwiftAnalyzer
import os.log

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2ModelBuilder", category: "general")

@main
struct ADAR2ModelBuilderCommand: ParsableCommand {

    // MARK: - Arguments
    @Argument(help: "The ABSOLUTE path to project you want to create model for", completion: .directory)
    var workspacePath: String

    @Argument(help: "The ABSOLUTE path to put output *.adar file at", completion: .directory)
    var outPath: String?

    @Argument(help: "The name of the scheme to build", completion: .file(extensions: ["xcodeproj"]))
    var schemeName: String?

    @Argument(help: "The name of the workspace to build", completion: .file(extensions: ["xcworkspace"]))
    var workspaceName: String?

    @Argument(
        help: "The build configuration to use",
        completion: .list(SystemConfiguration.BuildConfiguration.allCases.map(\.rawValue))
    )
    var buildConfiguration: String?

    @Argument(help: "The system build destination to use")
    var systemBuildDestination: String?

    // MARK: - Run
    mutating func run() throws {
        logger.info("ADAR2 Model Builder launched...")

        let configuration = SystemConfiguration(
            workspacePath: self.workspacePath,
            outputPath: self.outPath,
            schemeName: self.schemeName,
            workspaceName: self.workspaceName,
            buildConfiguration: SystemConfiguration.BuildConfiguration(rawValue: self.buildConfiguration ?? ""),
            systemBuildDestination: self.systemBuildDestination
        )

        logger.warning("Working directory path: \(configuration.workspacePath.path(percentEncoded: false), privacy: .public)")

        logger.info("[TODO] Choosing default model builder (legacy)")
        let modelBuilder: any ADARModelBuilder = ADAR2ModelBuilder(configuration: configuration)
        modelBuilder.buildModel()
        logger.info("Job finished!")
    }
}
