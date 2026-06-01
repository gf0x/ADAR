//
//  TimeMeasurement.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 04.11.2024.
//

import Foundation

func measureExecutionTime<T>(_ block: () -> T) -> (T, Double) {
    let start = DispatchTime.now()
    let result = block()
    let end = DispatchTime.now()

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    let durationInSeconds = Double(nanoTime) / 1_000_000_000 // Convert to seconds
    return (result, durationInSeconds)
}
