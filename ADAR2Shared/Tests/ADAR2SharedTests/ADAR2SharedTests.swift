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

    func testConnectionKindsAndOptionalInitializer() {
        XCTAssertTrue(ADARConnection.Kind.methodOf.isDeclaration)
        XCTAssertFalse(ADARConnection.Kind.methodUsesMethod.isDeclaration)
        XCTAssertTrue(ADARConnection.Kind.methodUsesMethod.isUsageKind)
        XCTAssertNil(ADARConnection(sourceId: "a", targetId: "b", kind: nil))

        let declaration = ADARNode.Declaration(
            id: "id", displayName: "Display", kind: .method,
            sourceFile: "/tmp/File.swift", sourceLine: 3
        )
        XCTAssertEqual(declaration.description, "Display(method)")
        XCTAssertEqual(ADARNode(declaration: declaration, position: .zero).id, "id")
    }
}
