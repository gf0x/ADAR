//
//  ADARForceDirectedVisualizer.swift
//  ADAR2Core
//
//  Created by Alex Frankiv on 02.11.2024.
//

import ADAR2Shared

public protocol ADARForceDirectedVisualizer: ADARVisualizer {

    func prepareVisualRepresentation(
        of graph: AbstractGraph<NodeData, EdgeData>,
        withPredefinedHeuristics heuristics: [NodeData: ADARVisualizerHeuristicsItem]?,
        withConfiguration configuration: ADARForceDirectedVisualizerConfiguration
    ) -> (graph: ADARGraph, iterationsRun: Int)
}

// MARK: - Default implementation
extension ADARForceDirectedVisualizer {

    public func prepareVisualRepresentation(
        of graph: AbstractGraph<NodeData, EdgeData>,
        withPredefinedHeuristics heuristics: [NodeData : ADARVisualizerHeuristicsItem]?
    ) -> ADARGraph {
        self.prepareVisualRepresentation(of: graph, withPredefinedHeuristics: heuristics, withConfiguration: .default)
            .graph
    }
}

// MARK: - Configuration
public struct ADARForceDirectedVisualizerConfiguration {

    // MARK: - StoppingCondition
    public enum StoppingCondition: Sendable {
        case displacementThreshold(Double) // good default is `.displacementThreshold(0.01)`
        case energyThreshold(Double) // good default is `.energyThreshold(0.5)`
    }

    // MARK: - Default
    public static let `default` = ADARForceDirectedVisualizerConfiguration()

    // MARK: - Properties
    public let stoppingCondition: StoppingCondition
    public let maxIterations: Int
    public let simulationBoxSize: Double

    // MARK: - Init
    public init(
        stoppingCondition: StoppingCondition = .displacementThreshold(0.01),
        maxIterations: Int = 10_000,
        simulationBoxSize: Double = 3_000
    ) {
        self.stoppingCondition = stoppingCondition
        self.maxIterations = maxIterations
        self.simulationBoxSize = simulationBoxSize
    }
}
