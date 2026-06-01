import XCTest
@testable import ADAR2NaiveForceDirectedVisualizer
import ADAR2Core
import ADAR2Shared

final class ADAR2NaiveForceDirectedVisualizerTests: XCTestCase {
    func testRepulsionMovesNodesApart() {
        var strategy = NaiveRepulsionStrategy()
        var nodes = [
            NFDNode(position: SIMD3<Float>(1, 0, 0), velocity: .zero, id: "left"),
            NFDNode(position: SIMD3<Float>(3, 0, 0), velocity: .zero, id: "right"),
        ]
        var energy = 0.0

        strategy.applyRepulsion(
            nodes: &nodes, repulsionStrength: 100,
            width: 10, height: 10, depth: 10, totalEnergy: &energy
        )

        XCTAssertLessThan(nodes[0].velocity.x, 0)
        XCTAssertGreaterThan(nodes[1].velocity.x, 0)
        XCTAssertGreaterThan(energy, 0)
    }

    func testVisualizerAndRevisualizerProduceGraphs() {
        let graph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        let a = graph.createVertex(.init(id: "a", displayName: "A", kind: .data_type))
        let b = graph.createVertex(.init(id: "b", displayName: "B", kind: .data_type))
        graph.addDirectedEdge(a, to: b, withWeight: 1, userInfo: .inherits)
        let configuration = ADARForceDirectedVisualizerConfiguration(
            stoppingCondition: .energyThreshold(1_000_000), maxIterations: 1
        )

        let positioned = ADAR2NaiveForceDirectedVisualizer()
            .prepareVisualRepresentation(of: graph, withConfiguration: configuration)
            .graph
        XCTAssertEqual(positioned.nodes.count, 2)
        XCTAssertEqual(positioned.connections.count, 1)
        XCTAssertEqual(
            ADAR2NaiveForceDirectedVisualizer()
                .prepareVisualRepresentation(of: graph, withPredefinedHeuristics: nil)
                .nodes.count,
            2
        )

        let report = ADARBugReport(
            highDegreeNodeIds: ["a"], lowCohesionEdges: [],
            cycleEdges: [], edgesWithCrossing: []
        )
        let malformed = ADARConnection(targetId: "a", kind: .inherits)
        let graphWithReport = ADARGraph(
            nodes: positioned.nodes, connections: positioned.connections + [malformed], bugReport: report
        )
        var progress: [Double] = []
        let revisualized = ADAR2NaiveForceDirectedVisualizer()
            .reVisualize(graphWithReport) { progress.append($0) }
        XCTAssertEqual(revisualized.nodes.count, 2)
        XCTAssertEqual(revisualized.connections.count, 1)
        XCTAssertEqual(revisualized.bugReport?.highDegreeNodeIds, ["a"])
        XCTAssertEqual(progress.last, 1)
    }
}
