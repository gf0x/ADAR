import XCTest
@testable import ADAR2SwiftAnalyzer
import ADAR2Core
import SwiftParser
import SwiftyJSON

final class ADAR2SwiftAnalyzerTests: XCTestCase {
    func testClassToPropertyWeightHandlesEmptyClass() {
        XCTAssertEqual(ADAR2SwiftAnalyzer().classToPropertyWeight(methodsUsingProperty: 0, totalMethods: 0), 0)
    }

    func testClassToPropertyWeightIncreasesWithUsage() {
        let analyzer = ADAR2SwiftAnalyzer()
        let unused = analyzer.classToPropertyWeight(methodsUsingProperty: 0, totalMethods: 4)
        let used = analyzer.classToPropertyWeight(methodsUsingProperty: 4, totalMethods: 4)
        XCTAssertLessThan(unused, used)
    }

    func testUtilityHelpers() throws {
        XCTAssertNil(sigmoid(nil))
        XCTAssertLessThan(sigmoid(0)!, sigmoid(5)!)

        let json = JSON([
            "root": ["children": [["kind": "first"], ["kind": "second"]]]
        ])
        XCTAssertEqual(json.firstChild(havingValue: "second", forKey: "kind")?["kind"].string, "second")
        XCTAssertNil(json.firstChild(havingValue: "missing", forKey: "kind"))

        let source = Parser.parse(source: """
        func caller(value: Int) {
            property = value
            self.property = value
            target()
        }
        func target() {}
        """)
        let propertyFinder = PropertyUsageFinder(method: "caller", property: "property")
        propertyFinder.walk(source)
        XCTAssertTrue(propertyFinder.isPropertyUsed)

        let methodFinder = MethodUsageFinder(targetMethod: "target")
        methodFinder.walk(source)
        XCTAssertEqual(methodFinder.methodsThatUseTarget, ["caller"])
    }

    func testAdaptersAndSymbolGraphCommands() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let fs = FileSystemAdapter()
        try fs.createTempDirIfNeeded(at: directory)
        try fs.createTempDirIfNeeded(at: directory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))

        let result = ShellAdapter().execute(
            shellCommand: .init(command: "printf output; printf error >&2; exit 3", env: .zsh),
            at: directory
        )
        XCTAssertEqual(result.output, ["output"])
        XCTAssertEqual(result.error, ["error"])
        XCTAssertEqual(result.status, 3)

        let spmConfiguration = SystemConfiguration(
            workspacePath: directory.path, outputPath: nil, schemeName: nil,
            workspaceName: nil, buildConfiguration: nil, systemBuildDestination: nil
        )
        try "// fixture".write(to: directory.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        let spm = ShellAdapter.ShellCommand.emitSymbolGraph(configuration: spmConfiguration, symbolDirName: "symbols")
        XCTAssertTrue(spm.command.contains("swift build"))
        XCTAssertTrue(spm.command.contains("ADAR_RUNNING=1"))

        try FileManager.default.removeItem(at: directory.appendingPathComponent("Package.swift"))
        let xcode = ShellAdapter.ShellCommand.emitSymbolGraph(configuration: spmConfiguration, symbolDirName: "symbols")
        XCTAssertTrue(xcode.command.contains("xcodebuild clean build"))

        fs.removeTempDirIfExists(at: directory)
        fs.removeTempDirIfExists(at: directory)
    }

    func testAnalyzeSwiftPackageEndToEnd() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ADARAnalyzerFixture-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let sources = directory.appendingPathComponent("Sources/Fixture")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try """
        // swift-tools-version: 5.9
        import PackageDescription
        let package = Package(name: "Fixture", targets: [.target(name: "Fixture")])
        """.write(to: directory.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try """
        public class Base {}
        public struct Value {}
        public final class Service: Base {
            public var value = Value()
            public override init() {}
            public func consume(_ input: Value) -> Value {
                helper()
                return Value()
            }
            public func helper() { _ = value }
        }
        """.write(to: sources.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)

        let configuration = SystemConfiguration(
            workspacePath: directory.path, outputPath: nil, schemeName: nil,
            workspaceName: nil, buildConfiguration: nil, systemBuildDestination: nil
        )
        let graph = ADAR2SwiftAnalyzer().analyze(with: configuration)

        XCTAssertGreaterThan(graph.vertices.count, 0)
        XCTAssertTrue(graph.vertices.contains { $0.data.displayName == "Service" })
        XCTAssertTrue(graph.edges.contains { $0.userInfo == .inherits })
        XCTAssertTrue(graph.edges.contains { $0.userInfo == .methodOf })
    }
}
