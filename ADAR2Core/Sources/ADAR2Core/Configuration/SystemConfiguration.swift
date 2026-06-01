//
//  SystemConfiguration.swift
//  ADAR2Core
//
//  Created by Alex Frankiv on 19.09.2024.
//

import Foundation

public struct SystemConfiguration {

    // MARK: - Const
    private enum Const {
        static let genericiOSSystemBuildDestination = "generic/platform=iOS"
    }

    // MARK: - Build configuration
    public enum BuildConfiguration: String, CaseIterable {
        case debug = "Debug"
        case release = "Release"
    }

    // MARK: - Project type
    public enum ProjectType {
        case xcode
        case spm
    }

    // MARK: - Properties
    public let workspacePath: URL
    public let outputPath: URL
    public let schemeName: String
    public let workspaceName: String?
    public let buildConfiguration: BuildConfiguration
    public let systemBuildDestination: String

    public var projectType: ProjectType {
        let packageSwift = workspacePath.appendingPathComponent("Package.swift")
        return FileManager.default.fileExists(atPath: packageSwift.path) ? .spm : .xcode
    }

    // MARK: - Init
    public init(
        workspacePath: String,
        outputPath: String?,
        schemeName: String?,
        workspaceName: String?,
        buildConfiguration: BuildConfiguration?,
        systemBuildDestination: String?
    ) {
        self.workspacePath = URL(filePath: workspacePath)
        if let outputPath {
            self.outputPath = URL(filePath: outputPath)
        } else {
            // FIXME: should handle safely
            self.outputPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        self.schemeName = schemeName ?? self.workspacePath.lastPathComponent
        self.workspaceName = workspaceName
        self.buildConfiguration = buildConfiguration ?? .release
        self.systemBuildDestination = systemBuildDestination ?? Const.genericiOSSystemBuildDestination
    }
}
