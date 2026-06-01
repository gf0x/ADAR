//
//  ADARAnalyzer.swift
//
//
//  Created by Alex Frankiv on 17.01.2024.
//

import Foundation

public protocol ADARAnalyzer {

    associatedtype NodeData: Hashable
    associatedtype EdgeData: Hashable & OptionSet

    func analyze(with configuration: SystemConfiguration) -> AbstractGraph<NodeData, EdgeData>
}
