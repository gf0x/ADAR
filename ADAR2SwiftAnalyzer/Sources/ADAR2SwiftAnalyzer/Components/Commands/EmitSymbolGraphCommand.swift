//
//  EmitSymbolGraphCommand.swift
//
//
//  Created by Alex Frankiv on 30.01.2024.
//

import Foundation
import ADAR2Core

extension ShellAdapter.ShellCommand {

    static func emitSymbolGraph(configuration: SystemConfiguration, symbolDirName: String) -> Self {
        switch configuration.projectType {
        case .xcode:
            return emitSymbolGraphXcode(configuration: configuration, symbolDirName: symbolDirName)
        case .spm:
            return emitSymbolGraphSPM(configuration: configuration, symbolDirName: symbolDirName)
        }
    }

    private static func emitSymbolGraphXcode(configuration: SystemConfiguration, symbolDirName: String) -> Self {
        let workspaceArgument = configuration.workspaceName.map { #"-workspace "\#($0)" "# } ?? ""
        let command = "" +
        #"cd "\#(configuration.workspacePath.path(percentEncoded: false))" "# + // Navigate to work directory
        "&& " +
        "xcodebuild clean build " + // Clean build
        #"CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO "# + // Disable code signing as we don't need it actually
        #"-scheme "\#(configuration.schemeName)" "# + // Set scheme
        "-configuration \(configuration.buildConfiguration.rawValue) " + // Set config
        "-destination \(configuration.systemBuildDestination) " + // Set destination
        workspaceArgument + // Set workspace if available
        #"OTHER_SWIFT_FLAGS=""# +
        "-emit-symbol-graph " + // Build symbol graph
        "-emit-symbol-graph-dir '\(symbolDirName)' " + // Export to temp folder
        "-symbol-graph-minimum-access-level private " + // Set lowest access level to be able to analyze code
        "-swift-version 5" +
        #"" "# +
        "IPHONEOS_DEPLOYMENT_TARGET=17.0 " +
        "ADAR_RUNNING=1"  // Prevents recursive invocation when ADAR2ModelBuilder is used in a Run Script phase

        logger.warning("Will build project with command: \(command, privacy: .public)")

        return ShellAdapter.ShellCommand(command: command, env: .zsh)
    }

    private static func emitSymbolGraphSPM(configuration: SystemConfiguration, symbolDirName: String) -> Self {
        let absoluteSymbolDir = configuration.workspacePath
            .appendingPathComponent(symbolDirName)
            .path(percentEncoded: false)

        let command = "" +
        #"cd "\#(configuration.workspacePath.path(percentEncoded: false))" "# + // Navigate to work directory
        "&& " +
        "ADAR_RUNNING=1 " + // Prevents recursive invocation via the ADAR2LintPlugin build tool
        "swift build " +
        "-Xswiftc -emit-symbol-graph " +
        #"-Xswiftc -emit-symbol-graph-dir -Xswiftc "\#(absoluteSymbolDir)" "# +
        "-Xswiftc -symbol-graph-minimum-access-level -Xswiftc private"

        logger.warning("Will build SPM project with command: \(command, privacy: .public)")

        return ShellAdapter.ShellCommand(command: command, env: .zsh)
    }
}
