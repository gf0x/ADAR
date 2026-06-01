//
//  FileSystemHelper.swift
//
//
//  Created by Alex Frankiv on 19.01.2024.
//

import Foundation
import ADAR2Shared
import ADAR2Core

final class FileSystemHelper {

    // MARK: - Properties
    let configuration: SystemConfiguration

    // MARK: - Init
    init(configuration: SystemConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Methods
    func write(_ graph: ADARGraph) {
        let pathURL = self.configuration.outputPath
        let projectName = self.configuration.schemeName
        let path = pathURL.appendingPathComponent("\(projectName).adar")
        logger.info("Please check out file at: \(path, privacy: .public)")
        do {
            try FileManager.default.createDirectory(at: pathURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(graph)
            try data.write(to: path)
        } catch {
            logger.error("Error occured during file write: \(error.localizedDescription, privacy: .public)")
        }
    }
}
