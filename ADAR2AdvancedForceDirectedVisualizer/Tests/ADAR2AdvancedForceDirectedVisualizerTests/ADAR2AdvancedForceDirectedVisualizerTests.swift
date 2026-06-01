import XCTest
@testable import ADAR2AdvancedForceDirectedVisualizer
import ADAR2Core
import ADAR2Shared

final class ADAR2AdvancedForceDirectedVisualizerTests: XCTestCase {
    func testOctreeTracksSubtreeMassAndCenterOfMass() {
        let tree = Octree(center: SIMD3<Float>(5, 5, 5), size: 10, repulsionStrength: 100)
        tree.insert(node: NFDNode(position: SIMD3<Float>(1, 1, 1), velocity: .zero, id: "a"))
        tree.insert(node: NFDNode(position: SIMD3<Float>(3, 1, 1), velocity: .zero, id: "b"))

        XCTAssertEqual(tree.mass, 2)
        XCTAssertEqual(tree.centerOfMass, SIMD3<Float>(2, 1, 1))
    }

    func testOctreeRepelsNodeAwayFromOtherSubtree() {
        let tree = Octree(center: SIMD3<Float>(5, 5, 5), size: 10, repulsionStrength: 100)
        let left = NFDNode(position: SIMD3<Float>(1, 1, 1), velocity: .zero, id: "left")
        tree.insert(node: left)
        tree.insert(node: NFDNode(position: SIMD3<Float>(9, 1, 1), velocity: .zero, id: "right"))

        XCTAssertLessThan(tree.calculateForce(on: left).x, 0)
    }

    func testOctreeHandlesEmptyLeafAndStrategy() {
        let empty = Octree(center: .zero, size: 1, repulsionStrength: 100)
        XCTAssertEqual(empty.calculateForce(on: NFDNode(position: .zero, velocity: .zero, id: "a")), .zero)
        empty.insert(node: NFDNode(position: .zero, velocity: .zero, id: "a"))
        XCTAssertEqual(empty.calculateForce(on: NFDNode(position: .zero, velocity: .zero, id: "a")), .zero)

        var nodes = [
            NFDNode(position: SIMD3<Float>(1, 0, 0), velocity: .zero, id: "a"),
            NFDNode(position: SIMD3<Float>(3, 0, 0), velocity: .zero, id: "b"),
        ]
        var energy = 0.0
        var strategy = OctreeRepulsionStrategy(width: 10, height: 10, depth: 10, repulsionStrength: 100)
        strategy.applyRepulsion(
            nodes: &nodes, repulsionStrength: 100,
            width: 10, height: 10, depth: 10, totalEnergy: &energy
        )
        XCTAssertGreaterThan(energy, 0)
    }

    func testVisualizerProducesPositionedGraph() {
        let graph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        let a = graph.createVertex(.init(id: "a", displayName: "A", kind: .data_type))
        let b = graph.createVertex(.init(id: "b", displayName: "B", kind: .data_type))
        graph.addDirectedEdge(a, to: b, withWeight: 1, userInfo: .inherits)
        let configuration = ADARForceDirectedVisualizerConfiguration(
            stoppingCondition: .energyThreshold(1_000_000), maxIterations: 1
        )

        let result = ADAR2AdvancedForceDirectedVisualizer()
            .prepareVisualRepresentation(of: graph, withConfiguration: configuration)

        XCTAssertEqual(result.graph.nodes.count, 2)
        XCTAssertEqual(result.graph.connections.count, 1)
    }
}
