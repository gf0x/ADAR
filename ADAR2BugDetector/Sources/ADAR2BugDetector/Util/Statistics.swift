//
//  Statistics.swift
//  ADAR2BugDetector
//
//  Created by Alex Frankiv on 05.07.2025.
//

import Foundation

struct Statistics {
    
    static func expectation(_ values: [NumType]) -> NumType {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / NumType(values.count)
    }

    static func variance(_ values: [NumType]) -> NumType {
        let mean = expectation(values)
        return values.reduce(0) { $0 + pow($1 - mean, 2) } / NumType(values.count)
    }
}
