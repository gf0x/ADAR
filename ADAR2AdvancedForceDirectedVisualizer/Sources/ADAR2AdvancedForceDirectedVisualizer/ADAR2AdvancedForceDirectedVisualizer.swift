import Foundation
import simd
import ADAR2Core
import ADAR2Shared
import os.log

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2AdvancedForceDirectedVisualizer", category: "general")

public final class ADAR2AdvancedForceDirectedVisualizer: ADARForceDirectedVisualizer {

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
            strategy: OctreeRepulsionStrategy(
                width: configuration.simulationBoxSize,
                height: configuration.simulationBoxSize,
                depth: configuration.simulationBoxSize,
                repulsionStrength: 100
            )
        )
        logger.info("Simulation did \(result.iterationsRun, privacy: .public) steps")
        return result
    }
}

// MARK: - Barnes-Hut octree repulsion

struct OctreeRepulsionStrategy: RepulsionStrategy {

    let width, height, depth, repulsionStrength: Double

    mutating func applyRepulsion(
        nodes: inout [NFDNode],
        repulsionStrength: Double,
        width: Double, height: Double, depth: Double,
        totalEnergy: inout Double
    ) {
        let octree = Octree(
            center: SIMD3<Float>(Float(width / 2), Float(height / 2), Float(depth / 2)),
            size: max(width, height, depth),
            repulsionStrength: repulsionStrength
        )
        for node in nodes { octree.insert(node: node) }

        for i in 0..<nodes.count {
            let force = octree.calculateForce(on: nodes[i])
            nodes[i].velocity = nodes[i].velocity + force
            totalEnergy += 0.5 * force.length() * force.length()
        }
    }
}

// MARK: - Octree

final class Octree {
    var center: SIMD3<Float>
    var size: Double
    let repulsionStrength: Double
    var children: [Octree?] = Array(repeating: nil, count: 8)
    var nodes: [NFDNode] = []
    private(set) var mass = 0
    private(set) var centerOfMass = SIMD3<Float>.zero

    init(center: SIMD3<Float>, size: Double, repulsionStrength: Double) {
        self.center = center
        self.size = size
        self.repulsionStrength = repulsionStrength
    }

    func insert(node: NFDNode) {
        centerOfMass = (centerOfMass * Float(mass) + node.position) / Float(mass + 1)
        mass += 1
        if size <= 1.0 { nodes.append(node); return }

        let index = (node.position.x >= center.x ? 1 : 0) |
                    (node.position.y >= center.y ? 2 : 0) |
                    (node.position.z >= center.z ? 4 : 0)

        if children[index] == nil {
            let offset = Float(size / 4)
            let childCenter = SIMD3<Float>(
                center.x + (index & 1 == 0 ? -offset : offset),
                center.y + (index & 2 == 0 ? -offset : offset),
                center.z + (index & 4 == 0 ? -offset : offset)
            )
            children[index] = Octree(center: childCenter, size: size / 2, repulsionStrength: repulsionStrength)
        }
        children[index]!.insert(node: node)
    }

    func calculateForce(on node: NFDNode, theta: Double = 0.5) -> SIMD3<Float> {
        guard mass > 0 else { return .zero }
        if mass == 1 && nodes.first?.id == node.id { return .zero }

        let delta = node.position - centerOfMass
        let distance = max(1.0, delta.length())
        if (size / distance < theta && !contains(node.position)) || children.allSatisfy({ $0 == nil }) {
            let direction = delta / distance
            let forceMagnitude = repulsionStrength * Double(mass) / (distance * distance)
            return direction * forceMagnitude
        }

        return children.compactMap { $0 }.reduce(SIMD3<Float>.zero) { acc, child in
            acc + child.calculateForce(on: node, theta: theta)
        }
    }

    private func contains(_ position: SIMD3<Float>) -> Bool {
        let halfSize = Float(size / 2)
        return abs(position.x - center.x) <= halfSize
            && abs(position.y - center.y) <= halfSize
            && abs(position.z - center.z) <= halfSize
    }
}
