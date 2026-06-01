import XCTest
@testable import ADAR2MLVisualizer
import ADAR2Core

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
}
