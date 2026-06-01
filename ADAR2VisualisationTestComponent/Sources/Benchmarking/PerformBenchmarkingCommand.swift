//
//  PerformBenchmarkingCommand.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 02.11.2024.
//

import Foundation
import ArgumentParser
import ADAR2Core
import ADAR2Shared

import ADAR2NaiveForceDirectedVisualizer
import ADAR2AdvancedForceDirectedVisualizer
import ADAR2MLVisualizer

struct PerformBenchmarkingCommand: ParsableCommand {

    // MARK: - Command
    static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Prepare the new visualisation for the existing ADAR2 visualisation and benchmark it",
        discussion: "benchmark <source-directory> <destination-file>",
        version: "1.0.0"
    )

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the directory where the visualisations are located", completion: .directory
    )
    var sourceDirectory: String

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the file where the report should be located"
    )
    var destinationFile: String

    // MARK: - Const
    private enum Const {
        static let allStoppingConditions: [ADARForceDirectedVisualizerConfiguration.StoppingCondition] = [
            .displacementThreshold(0.01)//, .energyThreshold(0.5)
        ]

        static let maxIterations: Int = 10_000
    }

    // MARK: - Run
    func run() throws {
        let fileManager = FileManager.default
        let sourceFiles = try fileManager.contentsOfDirectory(atPath: self.sourceDirectory)

        var benchmarks = [BenchmarkItem]()

        let totalCount = sourceFiles.count
        for (index, sourceFilePath) in sourceFiles.enumerated() where sourceFilePath.hasSuffix(".adar") {

            logger.info("Processing \(sourceFilePath) (\(index + 1)/\(totalCount))...")
            let fullSourcePath = "\(self.sourceDirectory)/\(sourceFilePath)"

            let abstractGraph = try abstractGraph(fromAdarFileAt: fullSourcePath)
            let graphInfo = BenchmarkItem.GraphInfo(
                name: sourceFilePath,
                numberOfVertices: abstractGraph.vertices.count,
                numberOfEdges: abstractGraph.edges.count
            )


            for (visualizerName, visualizer) in prepareAllVisualizers() {
                for condition in Const.allStoppingConditions {
                    for _ in 0..<3 {
                        benchmarks.append(self.benchmark(
                            graphInfo: graphInfo,
                            abstractGraph: abstractGraph,
                            visualizerName: visualizerName,
                            visualizer: visualizer,
                            stopCondition: condition
                        ))
                    }
                }
            }
        }

        let encodedGraph = try JSONEncoder().encode(benchmarks)
        try encodedGraph.write(to: URL(fileURLWithPath: destinationFile))
    }

    private func prepareAllVisualizers() -> [(name: String, v: any BenchmarkableVisualizer)] {
        var visualizers = [(name: String, v: any BenchmarkableVisualizer)]()

        let originalVisualizers: [any BenchmarkableVisualizer] = [ADAR2NaiveForceDirectedVisualizer(), ADAR2AdvancedForceDirectedVisualizer()]
        for v in originalVisualizers {
            visualizers.append((name: String(describing: type(of: v)), v: v))
        }

        for mlModel in ADAR2MLVisualizerModel.allCases {
            let coreNaiveVisualizer = ADAR2NaiveForceDirectedVisualizer()
            visualizers.append((
                name: "ML(\(mlModel.rawValue))+\(String(describing: type(of: coreNaiveVisualizer)))",
                v: ADAR2MLVisualizer(with: mlModel, coreVisualizer: coreNaiveVisualizer)
            ))

            let coreAdvancedVisualizer = ADAR2AdvancedForceDirectedVisualizer()
            visualizers.append((
                name: "ML(\(mlModel.rawValue))+\(String(describing: type(of: coreAdvancedVisualizer)))",
                v: ADAR2MLVisualizer(with: mlModel, coreVisualizer: coreAdvancedVisualizer)
            ))
        }

        return visualizers
    }

    private func benchmark<V: BenchmarkableVisualizer>(
        graphInfo: BenchmarkItem.GraphInfo,
        abstractGraph: AbstractGraph<V.NodeData, V.EdgeData>,
        visualizerName: String,
        visualizer: V,
        stopCondition: ADARForceDirectedVisualizerConfiguration.StoppingCondition
    ) -> BenchmarkItem {
        let (graphAndSteps, time) = measureExecutionTime {
            visualizer.prepareVisualRepresentation(
                of: abstractGraph,
                withPredefinedHeuristics: nil,
                withConfiguration: .init(stoppingCondition: stopCondition, maxIterations: Const.maxIterations)
            )
        }
        return .init(
            graphInfo: graphInfo,
            visualizerName: visualizerName,
            stoppingCondition: stopCondition,
            numberOfIterations: graphAndSteps.iterationsRun,
            durationInSeconds: time
        )
    }
}
