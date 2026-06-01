//
//  PrepareVisualsCommand.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 28.10.2024.
//

import Foundation
import ArgumentParser
import ADAR2Core
import ADAR2Shared
import ADAR2NaiveForceDirectedVisualizer

struct PrepareVisualsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "prepare-visuals",
        abstract: "Prepare new visualisation for the existing ADAR2 visualisation",
        discussion: "prepare-visuals <source-directory> <destination-directory>",
        version: "1.0.0"
    )

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the directory where the visualisations are located", completion: .directory
    )
    var sourceDirectory: String

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the directory where the new prepared visualisations should be located", completion: .directory
    )
    var destinationDirectory: String

    func run() throws {
        let fileManager = FileManager.default
        let trueVisualizer = ADAR2NaiveForceDirectedVisualizer()

        let destinationURL = URL(fileURLWithPath: self.destinationDirectory)
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }

        let sourceFiles = try fileManager.contentsOfDirectory(atPath: self.sourceDirectory)

        let totalCount = sourceFiles.count
        for (index, sourceFilePath) in sourceFiles.enumerated() where sourceFilePath.hasSuffix(".adar") {

            logger.info("Processing \(sourceFilePath) (\(index + 1)/\(totalCount))...")

            let abstractGraph = try abstractGraph(fromAdarFileAt: "\(self.sourceDirectory)/\(sourceFilePath)")

            let newAdarGraph = trueVisualizer.prepareVisualRepresentation(of: abstractGraph).graph
            let encodedGraph = try JSONEncoder().encode(newAdarGraph)
            try encodedGraph.write(to: destinationURL.appendingPathComponent(sourceFilePath))
        }
    }
}
