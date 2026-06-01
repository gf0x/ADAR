import XCTest
import ADAR2Shared
@testable import ADAR2BugDetector

final class ADAR2BugDetectorTests: XCTestCase {
    private func node(_ id: String, _ x: Float, _ y: Float) -> ADARNode {
        ADARNode(
            declaration: .init(id: id, displayName: id, kind: .data_type),
            position: SIMD3<Float>(x, y, 0)
        )
    }

    func testMalformedEdgesAreIgnored() {
        let node = ADARNode(
            declaration: .init(id: "a", displayName: "A", kind: .data_type),
            position: .zero
        )
        let malformed = ADARConnection(targetId: "a", kind: .methodOf)

        let results = ADAR2BugDetector().detect(in: ADARGraph(nodes: [node], connections: [malformed]))

        XCTAssertTrue(results.lowCohesionEdges.isEmpty)
        XCTAssertTrue(results.cycleEdges.isEmpty)
        XCTAssertTrue(results.edgesWithCrossing.isEmpty)
    }

    func testDetectsCyclesAndCrossingEdges() {
        let ab = ADARConnection(sourceId: "a", targetId: "b", kind: .inherits)
        let ba = ADARConnection(sourceId: "b", targetId: "a", kind: .inherits)
        let cd = ADARConnection(sourceId: "c", targetId: "d", kind: .inherits)
        let ef = ADARConnection(sourceId: "e", targetId: "f", kind: .inherits)
        let graph = ADARGraph(
            nodes: [
                node("a", 0, 0), node("b", 1, 0),
                node("c", 0, 0), node("d", 2, 2),
                node("e", 0, 2), node("f", 2, 0),
            ],
            connections: [ab, ba, cd, ef]
        )

        let result = ADAR2BugDetector().detectForFile(in: graph)

        XCTAssertTrue(result.cycleEdges.contains(ab))
        XCTAssertTrue(result.cycleEdges.contains(ba))
        XCTAssertTrue(result.edgesWithCrossing.contains(cd))
        XCTAssertTrue(result.edgesWithCrossing.contains(ef))
    }

    func testFlagsOutlierMemberWeight() {
        let nodes = (0..<10).map { node("\($0)", Float($0), 0) }
        let normal = (1..<10).map {
            ADARConnection(sourceId: "\($0)", targetId: "0", kind: .methodOf, weight: 1)
        }
        let outlier = ADARConnection(sourceId: "0", targetId: "1", kind: .methodOf, weight: 100)

        let result = ADAR2BugDetector().detect(in: ADARGraph(nodes: nodes, connections: normal + [outlier]))

        XCTAssertTrue(result.lowCohesionEdges.contains(outlier))
    }
}
