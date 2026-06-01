import Foundation
import simd
import ADAR2Core
import ADAR2Shared
import os.log

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2NaiveForceDirectedVisualizer", category: "general")

public final class ADAR2NaiveForceDirectedVisualizer: ADARForceDirectedVisualizer {

    public typealias NodeData = ADARNode.Declaration
    public typealias EdgeData = ADARConnection.Kind

    public init() {}

    public func prepareVisualRepresentation(
        of graph: AbstractGraph<NodeData, EdgeData>,
        withPredefinedHeuristics heuristics: [NodeData: ADARVisualizerHeuristicsItem]? = nil,
        withConfiguration configuration: ADARForceDirectedVisualizerConfiguration = .default
    ) -> (graph: ADARGraph, iterationsRun: Int) {
        let result = buildPositionedGraph(
            from: graph,
            withHeuristics: heuristics,
            configuration: configuration,
            strategy: NaiveRepulsionStrategy()
        )
        logger.info("Simulation did \(result.iterationsRun, privacy: .public) steps")
        return result
    }
}

// MARK: - ADARGraph convenience re-visualizer

extension ADAR2NaiveForceDirectedVisualizer {

    /// Re-runs force-directed layout on an already-positioned `ADARGraph`.
    /// Useful for re-laying out a subgraph with fresh positions.
    /// The original `bugReport` is preserved in the result.
    public func reVisualize(_ graph: ADARGraph, progressHandler: ((Double) -> Void)? = nil) -> ADARGraph {
        let abstractGraph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        var nodeIndex: [String: Vertex<ADARNode.Declaration>] = [:]

        for node in graph.nodes {
            let vertex = abstractGraph.createVertex(node.declaration)
            nodeIndex[node.id] = vertex
        }
        for connection in graph.connections {
            guard let sourceId = connection.sourceId,
                  let from = nodeIndex[sourceId],
                  let to = nodeIndex[connection.targetId] else { continue }
            abstractGraph.addDirectedEdge(from, to: to, withWeight: connection.weight, userInfo: connection.kind)
        }

        let (positioned, _) = buildPositionedGraph(
            from: abstractGraph,
            withHeuristics: nil,
            configuration: .default,
            strategy: NaiveRepulsionStrategy(),
            progressHandler: progressHandler
        )
        return ADARGraph(nodes: positioned.nodes, connections: positioned.connections, bugReport: graph.bugReport)
    }
}

// MARK: - O(n²) all-pairs repulsion

struct NaiveRepulsionStrategy: RepulsionStrategy {

    mutating func applyRepulsion(
        nodes: inout [NFDNode],
        repulsionStrength: Double,
        width: Double, height: Double, depth: Double,
        totalEnergy: inout Double
    ) {
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let delta = nodes[i].position - nodes[j].position
                let distance = max(1.0, delta.length())
                let force = repulsionStrength / (distance * distance)
                let direction = delta / distance
                nodes[i].velocity = nodes[i].velocity + direction * force
                nodes[j].velocity = nodes[j].velocity - direction * force
                totalEnergy += 0.5 * force * force
            }
        }
    }
}
