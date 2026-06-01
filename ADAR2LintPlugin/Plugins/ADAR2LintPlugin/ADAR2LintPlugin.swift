import PackagePlugin
import Foundation

/// SPM Build Tool Plugin that invokes `adar2-lint` before each build.
///
/// The plugin looks for the .adar file at:
///   `<package-root>/.adar/<target-name>.adar`
///
/// That file is produced by running ADAR2ModelBuilder separately (see README).
/// If the file doesn't exist, `adar2-lint` emits a note (not an error) and exits cleanly.
///
/// The plugin also scans the target's source directory for `.adarconfig` and
/// `adar_disable` / `adar_enable` source annotations.
@main
struct ADAR2LintPlugin: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard target is SwiftSourceModuleTarget else { return [] }

        let tool = try context.tool(named: "adar2-lint")

        // Convention: .adar files live in <package-root>/.adar/
        let adarDir  = context.package.directory.appending(".adar")
        let adarFile = adarDir.appending("\(target.name).adar")

        // Config file is looked up in the target's source directory (or package root as fallback).
        let configFile = target.directory.appending(".adarconfig")

        return [
            .prebuildCommand(
                displayName: "ADAR2 Lint — \(target.name)",
                executable: tool.path,
                arguments: [
                    "--adar-file",  adarFile.string,
                    "--source-dir", target.directory.string,
                    "--config",     configFile.string,
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ADAR2LintPlugin: XcodeBuildToolPlugin {

    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let tool = try context.tool(named: "adar2-lint")

        let projectDir = context.xcodeProject.directory
        let adarFile   = projectDir.appending(".adar").appending("\(target.displayName).adar")
        let configFile = projectDir.appending(".adarconfig")

        return [
            .prebuildCommand(
                displayName: "ADAR2 Lint — \(target.displayName)",
                executable: tool.path,
                arguments: [
                    "--adar-file",  adarFile.string,
                    "--source-dir", projectDir.string,
                    "--config",     configFile.string,
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
#endif
