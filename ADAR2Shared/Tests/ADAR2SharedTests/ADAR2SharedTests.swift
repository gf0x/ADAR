import XCTest
@testable import ADAR2Shared

final class ADAR2SharedTests: XCTestCase {
    func testGraphRoundTripsThroughJSON() throws {
        let declaration = ADARNode.Declaration(id: "Type", displayName: "Type", kind: .data_type)
        let node = ADARNode(declaration: declaration, position: SIMD3<Float>(1, 2, 3))
        let edge = ADARConnection(sourceId: "Type", targetId: "Other", kind: .inherits, weight: 2)
        let report = ADARBugReport(
            highDegreeNodeIds: ["Type"],
            lowCohesionEdges: [],
            cycleEdges: [edge],
            edgesWithCrossing: []
        )
        let graph = ADARGraph(nodes: [node], connections: [edge], bugReport: report)

        let decoded = try JSONDecoder().decode(ADARGraph.self, from: JSONEncoder().encode(graph))

        XCTAssertEqual(decoded.nodes, [node])
        XCTAssertEqual(decoded.connections, [edge])
        XCTAssertEqual(decoded.bugReport?.cycleEdges, [edge])
    }
}
