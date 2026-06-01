//
//  BenchmarkableVisualizer.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 04.11.2024.
//

import ADAR2Shared
import ADAR2Core

import ADAR2NaiveForceDirectedVisualizer
import ADAR2AdvancedForceDirectedVisualizer
import ADAR2MLVisualizer

// MARK: - AnyBenchmarkableVisualizer
protocol BenchmarkableVisualizer: ADARForceDirectedVisualizer
where NodeData == ADARNode.Declaration, EdgeData == ADARConnection.Kind {}

extension ADAR2NaiveForceDirectedVisualizer: BenchmarkableVisualizer {}
extension ADAR2AdvancedForceDirectedVisualizer: BenchmarkableVisualizer {}
extension ADAR2MLVisualizer: BenchmarkableVisualizer
where NodeData == ADARNode.Declaration, EdgeData == ADARConnection.Kind {}
