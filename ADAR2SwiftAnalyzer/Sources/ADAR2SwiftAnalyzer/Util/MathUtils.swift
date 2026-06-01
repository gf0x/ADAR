//
//  MathUtils.swift
//
//
//  Created by Alex Frankiv on 05.06.2024.
//

import Foundation

/// **CUSTOM** sigmoid
func sigmoid(_ x: Double?, stretchValue: Double = 5) -> Double? {
    guard let x else { return nil }
    // Adjust the x value to shift the sigmoid function
    let adjustedX = (x / stretchValue) * 12 - 6 // This scales x to -6 to 6 when x is 0 to stretchValue
    // Standard sigmoid function: 1 / (1 + exp(-adjustedX))
    return 1 / (1 + exp(-adjustedX))
}
