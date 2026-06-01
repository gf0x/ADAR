import XCTest
import ADAR2Shared
@testable import ADAR2BugDetector

final class ADAR2BugDetectorTests: XCTestCase {
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
}
