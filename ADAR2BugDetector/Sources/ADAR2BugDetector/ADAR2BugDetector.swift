import Foundation
import ADAR2Shared

public typealias NumType = Float

public final class ADAR2BugDetector {

    public init() {}

    public func detect(in graph: ADARGraph) -> DetectionResults {
        // TODO: parallel computation
        return DetectionResults(
            highDegreeNodes: self.computeHighDegreeNodes(from: graph),
            lowCohesionEdges: self.computeLowCohesionEdges(from: graph),
            cycleEdges: self.findCycles(in: graph),
            edgesWithCrossing: self.findEdgeCrossings(in: graph)
        )
    }

    /// Runs detection and returns a Codable report suitable for embedding in the `.adar` file.
    public func detectForFile(in graph: ADARGraph) -> ADARBugReport {
        let results = detect(in: graph)
        return ADARBugReport(
            highDegreeNodeIds: Set(results.highDegreeNodes.map(\.id)),
            lowCohesionEdges: results.lowCohesionEdges,
            cycleEdges: results.cycleEdges,
            edgesWithCrossing: results.edgesWithCrossing
        )
    }
}

// MARK: - Compute high degree
extension ADAR2BugDetector {

    private func computeHighDegreeNodes(from graph: ADARGraph) -> Set<ADARNode> {
        Dictionary(grouping: graph.nodes, by: { $0.declaration.kind })
            .values
            .map { computeHighDegreeNodes(for: $0, in: graph) }
            .reduce(into: [], { all, part in part.forEach { all.insert($0) } })
    }

    private func computeHighDegreeNodes(for nodes: [ADARNode], in graph: ADARGraph) -> Set<ADARNode> {
        let nodesWithDegrees = nodes.map { node in
            let numOfAllConnections = graph.connections
                .filter({ $0.sourceId == node.id || $0.targetId == node.id })
                .count
            return (node,  NumType(numOfAllConnections))
        }
        let allDegrees = nodesWithDegrees.map(\.1)
        let degreeDistibution = DistributionSummary(for: allDegrees)

        return Set(nodesWithDegrees
            .filter({ $0.1.isAnomaly(in: degreeDistibution) })
            .map(\.0)
        )
    }
}

// MARK: - Compute low cohesion
extension ADAR2BugDetector {

    private func computeLowCohesionEdges(from graph: ADARGraph) -> Set<ADARConnection> {
        let isMemberEdges = graph.connections.filter { [.propertyOf, .methodOf].contains($0.kind) }
        let distribution = DistributionSummary(for: isMemberEdges.compactMap(\.weight).map({ NumType($0) }))

        return Set(isMemberEdges.filter {
            guard let weight = $0.weight else { return false }
            return NumType(weight).isAnomaly(in: distribution)
        })
    }
}

// MARK: - Discover cycles
extension ADAR2BugDetector {

    private func findCycles(in graph: ADARGraph) -> Set<ADARConnection> {
        return graph.findDirectedCycles().reduce(into: Set<ADARConnection>()) { partialResult, subset in
            subset.forEach { partialResult.insert($0) }
        }
    }
}

// MARK: - Discover edge crossings
extension ADAR2BugDetector {

    private func findEdgeCrossings(in graph: ADARGraph) -> Set<ADARConnection> {
        return graph.findEdgeCrossings().reduce(into: Set<ADARConnection>()) { partialResult, subset in
            partialResult.insert(subset.0); partialResult.insert(subset.1)
        }
    }
}

// MARK: - Result
extension ADAR2BugDetector {

    public struct DetectionResults {
        public let highDegreeNodes: Set<ADARNode>
        public let lowCohesionEdges: Set<ADARConnection>
        public let cycleEdges: Set<ADARConnection>
        public let edgesWithCrossing: Set<ADARConnection>
    }
}
