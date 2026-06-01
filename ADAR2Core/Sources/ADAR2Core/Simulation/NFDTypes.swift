import Foundation
import simd

/// A node in the force-directed simulation.
public struct NFDNode {
    public var position: SIMD3<Float>
    public var velocity: SIMD3<Float>
    public let id: String

    public init(position: SIMD3<Float>, velocity: SIMD3<Float>, id: String) {
        self.position = position
        self.velocity = velocity
        self.id = id
    }
}

/// A weighted directed edge in the force-directed simulation.
public struct NFDEdge {
    public let source: String
    public let target: String
    public let weight: Double

    public init(source: String, target: String, weight: Double) {
        self.source = source
        self.target = target
        self.weight = weight
    }
}

/// Strategy that computes repulsion forces between nodes.
/// Implement this protocol to provide different repulsion algorithms.
public protocol RepulsionStrategy {
    mutating func applyRepulsion(
        nodes: inout [NFDNode],
        repulsionStrength: Double,
        width: Double,
        height: Double,
        depth: Double,
        totalEnergy: inout Double
    )
}
