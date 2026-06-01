//
//  ADAR1ModelBuilder.swift
//
//
//  Created by Alex Frankiv on 17.01.2024.
//

import Foundation
import ADAR2Core
import ADAR2SwiftAnalyzer

import ADAR2NaiveForceDirectedVisualizer
import ADAR2AdvancedForceDirectedVisualizer
import ADAR2MLVisualizer

/// The default model builder with legacy visualizer and new analyzer
final class ADAR2ModelBuilder: ADARModelBuilder {

    // MARK: - Properties
    let configuration: SystemConfiguration

    let analyzer = ADAR2SwiftAnalyzer()

    let visualizer = ADAR2NaiveForceDirectedVisualizer()
//    let visualizer = ADAR2AdvancedForceDirectedVisualizer()
//    let visualizer = ADAR2MLVisualizer(with: .gnn_3L_5000, coreVisualizer: ADAR2NaiveForceDirectedVisualizer())

    // MARK: - Init
    init(configuration: SystemConfiguration) {
        self.configuration = configuration
    }
}
