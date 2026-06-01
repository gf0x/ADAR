import Foundation
import simd
import CoreGraphics
import ADAR2Shared

/// Shared implementation of `prepareVisualRepresentation` for all force-directed visualisers.
/// Both Naive and Advanced just provide their RepulsionStrategy; everything else is here.
public func buildPositionedGraph<Strategy: RepulsionStrategy>(
    from abstractGraph: AbstractGraph<ADARNode.Declaration, ADARConnection.Kind>,
    withHeuristics heuristics: [ADARNode.Declaration: ADARVisualizerHeuristicsItem]?,
    configuration: ADARForceDirectedVisualizerConfiguration,
    strategy: Strategy,
    progressHandler: ((Double) -> Void)? = nil
) -> (graph: ADARGraph, iterationsRun: Int) {

    // Scale the simulation box with the cube root of node count so there is always
    // enough space between nodes regardless of graph size.  A 100-node graph gets
    // roughly the same box as the old fixed 3 000 default; smaller graphs shrink
    // proportionally; larger graphs expand.
    let nodeCount = max(1, abstractGraph.vertices.count)
    let boxSize = max(500.0, 150.0 * pow(Double(nodeCount), 1.0 / 3.0))

    let nodesDict: [String: ADARNode.Declaration] = Dictionary(
        uniqueKeysWithValues: abstractGraph.vertices.map { ($0.data.id, $0.data) }
    )

    func randomPosition() -> SIMD3<Float> {
        SIMD3<Float>(
            Float.random(in: 0..<Float(boxSize)),
            Float.random(in: 0..<Float(boxSize)),
            Float.random(in: 0..<Float(boxSize))
        )
    }

    func heuristicPosition(_ h: ADARVisualizerHeuristicsItem?) -> SIMD3<Float>? {
        guard let h else { return nil }
        return SIMD3<Float>(Float(h.x), Float(h.y), Float(h.z))
    }

    let placingNodes = abstractGraph.vertices.map { vertex in
        NFDNode(
            position: heuristicPosition(heuristics?[vertex.data]) ?? randomPosition(),
            velocity: .zero,
            id: vertex.data.id
        )
    }
    let edges = abstractGraph.edges.map { edge in
        NFDEdge(source: edge.from.data.id, target: edge.to.data.id, weight: edge.weight ?? 1.0)
    }

    let fdg = ForceDirectedGraph(
        nodes: placingNodes,
        edges: edges,
        width: boxSize, height: boxSize, depth: boxSize,
        stoppingCondition: configuration.stoppingCondition,
        maxIterations: configuration.maxIterations,
        strategy: strategy
    )
    let iterationsRun = fdg.runSimulation(progressHandler: progressHandler)

    // Compute centre and shift all nodes so the cloud is centred at the origin
    let xExts = fdg.nodes.map { CGFloat($0.position.x) }.extremums()
    let yExts = fdg.nodes.map { CGFloat($0.position.y) }.extremums()
    let zExts = fdg.nodes.map { CGFloat($0.position.z) }.extremums()
    let centre = SIMD3<Float>(
        Float((xExts.max + xExts.min) / 2),
        Float((yExts.max + yExts.min) / 2),
        Float((zExts.max + zExts.min) / 2)
    )

    let graph = ADARGraph(
        nodes: fdg.nodes.compactMap { node -> ADARNode? in
            guard let declaration = nodesDict[node.id] else { return nil }
            return ADARNode(declaration: declaration, position: node.position - centre)
        },
        connections: abstractGraph.edges.compactMap { edge in
            ADARConnection(
                sourceId: edge.from.data.id,
                targetId: edge.to.data.id,
                kind: edge.userInfo,   // failable init — drops edges with nil kind
                weight: edge.weight
            )
        }
    )

    return (graph, iterationsRun)
}
