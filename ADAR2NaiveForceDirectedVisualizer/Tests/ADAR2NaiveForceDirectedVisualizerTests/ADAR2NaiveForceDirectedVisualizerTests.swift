import XCTest
@testable import ADAR2NaiveForceDirectedVisualizer
import ADAR2Core

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
}
