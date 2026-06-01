//
//  ADARModelBuilder.swift
//
//
//  Created by Alex Frankiv on 17.01.2024.
//

import Foundation
import ADAR2Core
import ADAR2Shared
import ADAR2BugDetector

protocol ADARModelBuilder {

    associatedtype AnyADARAnalyzer: ADARAnalyzer
    associatedtype AnyADARVisualyzer: ADARVisualizer 
    where AnyADARAnalyzer.NodeData == AnyADARVisualyzer.NodeData,
          AnyADARAnalyzer.EdgeData == AnyADARVisualyzer.EdgeData

    var configuration: SystemConfiguration { get }
    var analyzer: AnyADARAnalyzer { get }
    var visualizer: AnyADARVisualyzer { get }
}

extension ADARModelBuilder {

    func buildModel() {
        let graphData = self.analyzer.analyze(with: self.configuration)
        let positionedGraph = self.visualizer.prepareVisualRepresentation(of: graphData, withPredefinedHeuristics: nil)
        let bugReport = ADAR2BugDetector().detectForFile(in: positionedGraph)
        let graphWithReport = ADARGraph(
            nodes: positionedGraph.nodes,
            connections: positionedGraph.connections,
            bugReport: bugReport
        )
        FileSystemHelper(configuration: self.configuration).write(graphWithReport)
    }
}
