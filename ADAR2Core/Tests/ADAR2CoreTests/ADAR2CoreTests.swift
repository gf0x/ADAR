import XCTest
@testable import ADAR2Core
import ADAR2Shared

final class ADAR2CoreTests: XCTestCase {
    private struct EdgeKind: OptionSet, Hashable {
        let rawValue: Int
        static let usage = EdgeKind(rawValue: 1)
        static let relation = EdgeKind(rawValue: 2)
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

    func testAdjacencyListSupportsEdgeOperations() {
        let graph = AdjacencyListGraph<String, EdgeKind>()
        let a = graph.createVertex("a")
        let duplicateA = graph.createVertex("a")
        let b = graph.createVertex("b")
        let c = graph.createVertex("c")
        XCTAssertEqual(a, duplicateA)
        XCTAssertNil(graph.weightFrom(a, to: b))

        graph.addDirectedEdge(a, to: b, withWeight: nil, userInfo: nil)
        graph.addDirectedEdge(a, to: b, withWeight: 2, userInfo: .usage)
        graph.addDirectedEdge(a, to: b, withWeight: nil, userInfo: .relation)
        graph.addUndirectedEdge((b, c), withWeight: 3, userInfo: .usage)
        graph.mapEdges { Edge(from: $0.from, to: $0.to, weight: ($0.weight ?? 0) + 1, userInfo: $0.userInfo) }

        XCTAssertEqual(graph.vertices.count, 3)
        XCTAssertEqual(graph.edgesFrom(a).count, 1)
        XCTAssertEqual(graph.weightFrom(a, to: b), 3)
        XCTAssertTrue(graph.description.contains("a ->"))
        XCTAssertEqual(graph.shortDescription, "Graph with 3 vertices and 3 edges")

        let copy = AdjacencyListGraph(fromGraph: graph)
        XCTAssertEqual(copy.vertices.count, 3)
        XCTAssertEqual(copy.edges.count, 3)
    }

    func testAdjacencyMatrixSupportsEdgeOperations() {
        let graph = AdjacencyMatrixGraph<String, EdgeKind>()
        let a = graph.createVertex("a")
        XCTAssertEqual(graph.createVertex("a"), a)
        let b = graph.createVertex("b")
        let c = graph.createVertex("c")
        graph.addDirectedEdge(a, to: b, withWeight: -2, userInfo: .usage)
        graph.addUndirectedEdge((b, c), withWeight: 3, userInfo: .relation)

        XCTAssertEqual(graph.edges.count, 3)
        XCTAssertEqual(graph.edgesFrom(b).count, 1)
        XCTAssertEqual(graph.weightFrom(a, to: b), -2)
        XCTAssertNil(graph.weightFrom(a, to: c))
        XCTAssertTrue(graph.description.contains("-2.0"))
        XCTAssertTrue(graph.description.contains("ø"))

        let copy = AdjacencyMatrixGraph(fromGraph: graph)
        XCTAssertEqual(copy.edges.count, 3)
    }

    func testEdgeAndVertexDescriptionsAndEquality() {
        let a = Vertex(data: "a", index: 0)
        let sameA = Vertex(data: "a", index: 0)
        let b = Vertex(data: "b", index: 1)
        XCTAssertEqual(a, sameA)
        XCTAssertNotEqual(a, b)
        XCTAssertEqual(a.description, "0: a")

        let plain = Edge<String, EdgeKind>(from: a, to: b, weight: nil)
        let weighted = Edge<String, EdgeKind>(from: a, to: b, weight: 2, userInfo: .usage)
        XCTAssertEqual(plain.description, "0: a -> 1: b")
        XCTAssertTrue(weighted.description.contains("-(2.0)->"))
        XCTAssertNotEqual(plain, weighted)
        XCTAssertEqual(Set([weighted, weighted]).count, 1)
    }

    func testSimulationStoppingConditionsAndClamping() {
        var progress: [Double] = []
        let graph = ForceDirectedGraph(
            nodes: [NFDNode(position: .zero, velocity: SIMD3<Float>(-2, 12, 5), id: "a")],
            edges: [NFDEdge(source: "missing", target: "a", weight: 1)],
            width: 10, height: 10, depth: 4,
            stoppingCondition: .energyThreshold(1), maxIterations: 3,
            strategy: NoRepulsion()
        )
        XCTAssertEqual(graph.runSimulation { progress.append($0) }, 0)
        XCTAssertEqual(graph.nodes[0].position, SIMD3<Float>(0, 10, 4))
        XCTAssertEqual(progress.last, 1)

        let displacementGraph = ForceDirectedGraph(
            nodes: [], edges: [], width: 1, height: 1, depth: 1,
            stoppingCondition: .displacementThreshold(1), maxIterations: 2,
            strategy: NoRepulsion()
        )
        XCTAssertEqual(displacementGraph.runSimulation(), 0)
    }

    func testBuildPositionedGraphUsesHeuristicsAndDropsMalformedEdges() {
        let graph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        let a = ADARNode.Declaration(id: "a", displayName: "A", kind: .data_type)
        let b = ADARNode.Declaration(id: "b", displayName: "B", kind: .data_type)
        let av = graph.createVertex(a)
        let bv = graph.createVertex(b)
        graph.addDirectedEdge(av, to: bv, withWeight: 2, userInfo: nil)
        let heuristics = [
            a: ADARVisualizerHeuristicsItem(x: 1, y: 1, z: 1),
            b: ADARVisualizerHeuristicsItem(x: 3, y: 1, z: 1),
        ]
        let configuration = ADARForceDirectedVisualizerConfiguration(
            stoppingCondition: .energyThreshold(1), maxIterations: 1
        )

        let result = buildPositionedGraph(
            from: graph, withHeuristics: heuristics, configuration: configuration,
            strategy: NoRepulsion()
        )

        XCTAssertEqual(result.graph.nodes.count, 2)
        XCTAssertTrue(result.graph.connections.isEmpty)
    }

    func testSystemConfigurationDetectsProjectType() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let configuration = SystemConfiguration(
            workspacePath: directory.path, outputPath: directory.path, schemeName: "Scheme",
            workspaceName: "Workspace", buildConfiguration: .debug, systemBuildDestination: "destination"
        )
        XCTAssertEqual(configuration.projectType, .xcode)
        try "".write(to: directory.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        XCTAssertEqual(configuration.projectType, .spm)
        XCTAssertEqual(configuration.schemeName, "Scheme")
    }
}
