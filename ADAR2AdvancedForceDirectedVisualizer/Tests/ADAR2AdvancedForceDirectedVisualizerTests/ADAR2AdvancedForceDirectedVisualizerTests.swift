import XCTest
@testable import ADAR2AdvancedForceDirectedVisualizer
import ADAR2Core

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
}
