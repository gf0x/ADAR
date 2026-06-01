import Foundation
import simd
import os.log

private let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2Core", category: "simulation")

/// Generic force-directed graph simulator.
/// The repulsion strategy is injected so Naive (O(n²)) and Advanced (Barnes-Hut)
/// implementations share all spring-force and position-update code.
public class ForceDirectedGraph<Strategy: RepulsionStrategy> {

    public var nodes: [NFDNode]
    public var edges: [NFDEdge]

    public let width: Double
    public let height: Double
    public let depth: Double
    public let repulsionStrength: Double
    public let springLength: Double
    public let springStrength: Double
    public let damping: Double
    public let stoppingCondition: ADARForceDirectedVisualizerConfiguration.StoppingCondition
    public let maxIterations: Int

    private var strategy: Strategy

    public init(
        nodes: [NFDNode],
        edges: [NFDEdge],
        width: Double,
        height: Double,
        depth: Double,
        repulsionStrength: Double = 100,
        springLength: Double = 25.0,
        springStrength: Double = 0.025,
        damping: Double = 0.9,
        stoppingCondition: ADARForceDirectedVisualizerConfiguration.StoppingCondition,
        maxIterations: Int,
        strategy: Strategy
    ) {
        self.nodes = nodes
        self.edges = edges
        self.width = width
        self.height = height
        self.depth = depth
        self.repulsionStrength = repulsionStrength
        self.springLength = springLength
        self.springStrength = springStrength
        self.damping = damping
        self.stoppingCondition = stoppingCondition
        self.maxIterations = maxIterations
        self.strategy = strategy
    }

    public func applyForces() -> (totalDisplacement: Double, totalEnergy: Double) {
        var totalEnergy: Double = 0.0

        // Repulsion — delegated to the injected strategy
        strategy.applyRepulsion(
            nodes: &nodes,
            repulsionStrength: repulsionStrength,
            width: width,
            height: height,
            depth: depth,
            totalEnergy: &totalEnergy
        )

        // Spring forces — shared for all strategies
        for edge in edges {
            if let si = nodes.firstIndex(where: { $0.id == edge.source }),
               let ti = nodes.firstIndex(where: { $0.id == edge.target }) {
                let delta = nodes[si].position - nodes[ti].position
                let distance = max(1.0, delta.length())
                let force = springStrength * (distance - springLength) * edge.weight
                let direction = delta / distance
                nodes[si].velocity = nodes[si].velocity - direction * force
                nodes[ti].velocity = nodes[ti].velocity + direction * force
                totalEnergy += 0.5 * force * force
            }
        }

        // Position update + damping + boundary clamping — shared for all strategies
        var totalDisplacement: Double = 0.0
        for i in 0..<nodes.count {
            let old = nodes[i].position
            nodes[i].position = nodes[i].position + nodes[i].velocity
            nodes[i].velocity = nodes[i].velocity * damping
            nodes[i].position.x = min(max(nodes[i].position.x, 0), Float(width))
            nodes[i].position.y = min(max(nodes[i].position.y, 0), Float(height))
            nodes[i].position.z = min(max(nodes[i].position.z, 0), Float(depth))
            totalDisplacement += (nodes[i].position - old).length()
        }

        return (totalDisplacement, totalEnergy)
    }

    public func runSimulation(progressHandler: ((Double) -> Void)? = nil) -> Int {
        let reportEvery = max(1, maxIterations / 100)
        var initialDisplacement: Double = 0
        var lastReportedProgress: Double = -1

        for step in 0..<maxIterations {
            logger.debug("[SIMULATION] Step \(step) of \(self.maxIterations)")
            let (totalDisplacement, totalEnergy) = applyForces()

            if let handler = progressHandler, step % reportEvery == 0 {
                let progress: Double
                if step == 0 {
                    initialDisplacement = max(totalDisplacement, 1e-6)
                    progress = 0
                } else {
                    progress = min(0.99, max(0, 1.0 - totalDisplacement / initialDisplacement))
                }
                if progress > lastReportedProgress + 0.005 {
                    handler(progress)
                    lastReportedProgress = progress
                }
            }

            switch stoppingCondition {
            case .displacementThreshold(let threshold):
                if totalDisplacement < threshold {
                    logger.debug("Converged after \(step) steps (displacement)")
                    progressHandler?(1.0)
                    return step
                }
            case .energyThreshold(let threshold):
                if totalEnergy < threshold {
                    logger.debug("Converged after \(step) steps (energy)")
                    progressHandler?(1.0)
                    return step
                }
            }
        }
        logger.debug("Reached max iterations (\(self.maxIterations)) without convergence")
        progressHandler?(1.0)
        return maxIterations
    }
}
