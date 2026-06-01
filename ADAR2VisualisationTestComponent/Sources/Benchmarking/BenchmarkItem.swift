//
//  BenchmarkItem.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 04.11.2024.
//

import Foundation
import ADAR2Core

struct BenchmarkItem: Codable {

    struct GraphInfo: Codable {
        let name: String
        let numberOfVertices, numberOfEdges: Int
    }

    let graphInfo: GraphInfo
    let visualizerName: String
    let stoppingCondition: String
    let numberOfIterations: Int
    let durationInSeconds: Double

    init(
        graphInfo: GraphInfo,
        visualizerName: String,
        stoppingCondition: ADARForceDirectedVisualizerConfiguration.StoppingCondition,
        numberOfIterations: Int,
        durationInSeconds: Double
    ) {
        self.graphInfo = graphInfo
        self.visualizerName = visualizerName
        self.stoppingCondition = switch stoppingCondition {
        case .displacementThreshold: "displacement_threshold"
        case .energyThreshold: "energy_threshold"
        }
        self.numberOfIterations = numberOfIterations
        self.durationInSeconds = durationInSeconds
    }
}
