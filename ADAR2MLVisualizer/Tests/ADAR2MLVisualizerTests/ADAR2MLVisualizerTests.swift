import XCTest
@testable import ADAR2MLVisualizer
import ADAR2Core
import ADAR2Shared
import ADAR2NaiveForceDirectedVisualizer
import CoreML

final class ADAR2MLVisualizerTests: XCTestCase {
    private struct EdgeKind: OptionSet, Hashable {
        let rawValue: Int
        static let relation = EdgeKind(rawValue: 1)
    }

    func testModelInputDefaultsMissingEdgeWeight() {
        let graph = AdjacencyListGraph<String, EdgeKind>()
        let a = graph.createVertex("a")
        let b = graph.createVertex("b")
        graph.addDirectedEdge(a, to: b, withWeight: nil, userInfo: .relation)

        let input = graph.prepareModelInput()

        XCTAssertEqual(input.edgeWeight.count, 1)
        XCTAssertEqual(input.edgeWeight[0].floatValue, 1)
    }

    func testModelInputAndHeuristicsIncludeAllValues() throws {
        let graph = AdjacencyListGraph<String, EdgeKind>()
        let a = graph.createVertex("a")
        let b = graph.createVertex("b")
        graph.addDirectedEdge(a, to: b, withWeight: 2, userInfo: .relation)

        let input = graph.prepareModelInput()
        XCTAssertEqual(input.nodeFeatures.count, 2)
        XCTAssertEqual(input.nodeFeatures[0].floatValue, 1)
        XCTAssertEqual(input.edgeIndex.count, 2)
        XCTAssertEqual(input.edgeWeight[0].floatValue, 2)

        let coordinates = try MLMultiArray(shape: [6], dataType: .double)
        for (index, value) in [1, 2, 3, 4, 5, 6].enumerated() {
            coordinates[index] = NSNumber(value: value)
        }
        let heuristics = graph.generateHeuristicsDictionary(from: coordinates)
        XCTAssertEqual(heuristics["a"]?.x, 1)
        XCTAssertEqual(heuristics["a"]?.z, 3)
        XCTAssertEqual(heuristics["b"]?.y, 5)
    }

    func testModelOutputNames() {
        XCTAssertEqual(ADAR2MLVisualizerModel.gnn_2L_5000.outputVariableName, "var_163")
        XCTAssertEqual(ADAR2MLVisualizerModel.gnn_3L_5000.outputVariableName, "var_241")
        XCTAssertEqual(ADAR2MLVisualizerModel.gnn_4L_5000.outputVariableName, "var_319")
        XCTAssertEqual(ADAR2MLVisualizerModel.allCases.count, 3)
    }

    func testBundledModelProducesPositionedGraph() {
        let graph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        let a = graph.createVertex(.init(id: "a", displayName: "A", kind: .data_type))
        let b = graph.createVertex(.init(id: "b", displayName: "B", kind: .data_type))
        graph.addDirectedEdge(a, to: b, withWeight: 1, userInfo: .inherits)
        let visualizer = ADAR2MLVisualizer(
            with: .gnn_2L_5000,
            coreVisualizer: ADAR2NaiveForceDirectedVisualizer()
        )
        let configuration = ADARForceDirectedVisualizerConfiguration(
            stoppingCondition: .energyThreshold(1_000_000), maxIterations: 1
        )

        let result = visualizer.prepareVisualRepresentation(
            of: graph,
            withPredefinedHeuristics: nil,
            withConfiguration: configuration
        )

        XCTAssertEqual(result.graph.nodes.count, 2)
        XCTAssertEqual(result.graph.connections.count, 1)
    }
}
