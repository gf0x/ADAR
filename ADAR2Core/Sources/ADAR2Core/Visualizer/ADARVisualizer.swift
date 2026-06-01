//
//  File.swift
//  
//
//  Created by Alex Frankiv on 18.01.2024.
//

import Foundation
import ADAR2Shared

public struct ADARVisualizerHeuristicsItem {
    public let x, y, z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public protocol ADARVisualizer {

    associatedtype NodeData: Hashable
    associatedtype EdgeData: Hashable & OptionSet

    func prepareVisualRepresentation(
        of graph: AbstractGraph<NodeData, EdgeData>,
        withPredefinedHeuristics heuristics: [NodeData: ADARVisualizerHeuristicsItem]?
    ) -> ADARGraph
}
