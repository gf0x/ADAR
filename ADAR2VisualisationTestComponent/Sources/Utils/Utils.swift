//
//  Utils.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 04.11.2024.
//

func cartesianProduct<T>(_ arrays: [[T]]) -> [[T]] {
    guard let first = arrays.first else { return [[]] }

    return first.flatMap { element in
        cartesianProduct(Array(arrays.dropFirst())).map { [element] + $0 }
    }
}
