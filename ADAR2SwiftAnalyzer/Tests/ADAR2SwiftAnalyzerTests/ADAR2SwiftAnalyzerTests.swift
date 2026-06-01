import XCTest
@testable import ADAR2SwiftAnalyzer

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
}
