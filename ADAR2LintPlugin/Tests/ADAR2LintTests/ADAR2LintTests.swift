import XCTest
@testable import adar2_lint

final class ADAR2LintTests: XCTestCase {
    func testConfigDefaultsAndOverrides() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try #"{"rules":{"cycle_edge":"error","edge_crossing":"ignore"}}"#
            .write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let config = ADARConfig.load(from: url)

        XCTAssertEqual(config.severity(for: .highDegreeNode), .warning)
        XCTAssertEqual(config.severity(for: .cycleEdge), .error)
        XCTAssertEqual(config.severity(for: .edgeCrossing), .ignore)
    }

    func testScannerFindsNextDeclarationSuppression() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try """
        // adar_disable:next cycle_edge
        final class IntentionalCycle {}
        """.write(to: directory.appendingPathComponent("Example.swift"), atomically: true, encoding: .utf8)

        XCTAssertEqual(
            AnnotationScanner.scan(sourceDir: directory),
            [Suppression(symbolName: "IntentionalCycle", rule: .cycleEdge)]
        )
    }
}
