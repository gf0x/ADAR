import XCTest
@testable import ADAR2Core

final class ADAR2CoreTests: XCTestCase {
    private struct EdgeKind: OptionSet, Hashable {
        let rawValue: Int
        static let usage = EdgeKind(rawValue: 1)
    }

    private struct NoRepulsion: RepulsionStrategy {
        mutating func applyRepulsion(
            nodes: inout [NFDNode], repulsionStrength: Double,
            width: Double, height: Double, depth: Double, totalEnergy: inout Double
        ) {}
    }

    func testAdjacencyListCombinesDuplicateEdges() {
        let graph = AdjacencyListGraph<String, EdgeKind>()
        let a = graph.createVertex("a")
        let b = graph.createVertex("b")
        graph.addDirectedEdge(a, to: b, withWeight: 2, userInfo: .usage)
        graph.addDirectedEdge(a, to: b, withWeight: 3, userInfo: .usage)

        XCTAssertEqual(graph.edges.count, 1)
        XCTAssertEqual(graph.weightFrom(a, to: b), 5)
    }

    func testSpringForceMovesConnectedNodesTogether() {
        let graph = ForceDirectedGraph(
            nodes: [
                NFDNode(position: .zero, velocity: .zero, id: "a"),
                NFDNode(position: SIMD3<Float>(10, 0, 0), velocity: .zero, id: "b"),
            ],
            edges: [NFDEdge(source: "a", target: "b", weight: 1)],
            width: 20, height: 20, depth: 20,
            springLength: 1, springStrength: 0.1, damping: 1,
            stoppingCondition: .displacementThreshold(0), maxIterations: 1,
            strategy: NoRepulsion()
        )

        _ = graph.applyForces()

        XCTAssertGreaterThan(graph.nodes[0].position.x, 0)
        XCTAssertLessThan(graph.nodes[1].position.x, 10)
    }
}
