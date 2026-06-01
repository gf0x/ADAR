//
//  DistributionSummary.swift
//  ADAR2BugDetector
//
//  Created by Alex Frankiv on 05.07.2025.
//

import Foundation

public struct DistributionSummary {

    let expectation: NumType
    let variance: NumType

    init(expectation: NumType, variance: NumType) {
        self.expectation = expectation
        self.variance = variance
    }

    init(for list: [NumType]) {
        self.expectation = Statistics.expectation(list)
        self.variance = Statistics.variance(list)
    }
}

public extension NumType {

    func isAnomaly(in summary: DistributionSummary, threshold: NumType = 2) -> Bool {
        let stdDev = summary.variance.squareRoot()
        return abs(self - summary.expectation) > threshold * stdDev
    }
}
