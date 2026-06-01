import PackagePlugin
import Foundation

/// SPM Command Plugin that invokes ADAR2ModelBuilder to generate (or refresh) the
/// `.adar/<TargetName>.adar` graph file for each Swift source module target.
///
/// Usage (CLI):
///   swift package generate-adar-model
///   swift package generate-adar-model --target MyTarget
///
/// Usage (Xcode):
///   Product → Perform Action → Generate ADAR Model
///
/// ADAR2ModelBuilder is resolved in order:
///   1. As a declared plugin tool (the public ADAR package builds it from source).
///   2. ADAR_MODELBUILDER_PATH environment variable.
///   3. Anywhere on PATH.
@main
struct GenerateADARModel: CommandPlugin {

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let modelBuilderPath = try resolveModelBuilder(context: context)

        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")

        let targets = context.package.targets
            .compactMap { $0 as? SwiftSourceModuleTarget }
            .filter { targetNames.isEmpty || targetNames.contains($0.name) }

        guard !targets.isEmpty else {
            print("warning: [ADAR] No Swift source module targets found in package '\(context.package.displayName)'.")
            return
        }

        let adarDir = context.package.directory.appending(".adar").string

        for target in targets {
            print("▶ [ADAR] Generating model for target '\(target.name)'...")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: modelBuilderPath)
            process.arguments = [
                context.package.directory.string, // workspacePath
                adarDir,                           // outputPath (.adar/ subdirectory)
                target.name,                       // schemeName / target name
            ]
            process.standardOutput = FileHandle.standardOutput
            process.standardError  = FileHandle.standardError

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw PluginError.modelBuilderFailed(target: target.name, code: process.terminationStatus)
            }
            print("✓ [ADAR] Model written to \(adarDir)/\(target.name).adar")
        }
    }

    // MARK: - Tool resolution

    private func resolveModelBuilder(context: PluginContext) throws -> String {
        // 1. Declared plugin tool, available from the root public package.
        if let tool = try? context.tool(named: "ADAR2ModelBuilder") {
            return tool.path.string
        }

        // 2. Explicit override via environment variable.
        if let envPath = ProcessInfo.processInfo.environment["ADAR_MODELBUILDER_PATH"],
           FileManager.default.isExecutableFile(atPath: envPath) {
            return envPath
        }

        // 3. Search PATH.
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            for dir in pathEnv.split(separator: ":").map(String.init) {
                let candidate = (dir as NSString).appendingPathComponent("ADAR2ModelBuilder")
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }

        throw PluginError.modelBuilderNotFound
    }
}

// MARK: - Errors

enum PluginError: Error, CustomStringConvertible {
    case modelBuilderNotFound
    case modelBuilderFailed(target: String, code: Int32)

    var description: String {
        switch self {
        case .modelBuilderNotFound:
            return """
            [ADAR] ADAR2ModelBuilder not found.
            Options:
              • Use the public ADAR package (https://github.com/gf0x/ADAR), which builds the tool from source.
              • Build ADAR2ModelBuilder locally and place it in your PATH, or set ADAR_MODELBUILDER_PATH.
            """
        case .modelBuilderFailed(let target, let code):
            return "[ADAR] ADAR2ModelBuilder failed for target '\(target)' (exit code \(code))."
        }
    }
}
