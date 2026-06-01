//
//  AbstractGraph+Utils.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 02.11.2024.
//

import Foundation
import ADAR2Shared
import ADAR2Core

func abstractGraph(fromAdarFileAt sourcePath: String) throws -> AbstractGraph<ADARNode.Declaration, ADARConnection.Kind> {
    let contents = try Data(contentsOf: URL(fileURLWithPath: sourcePath))
    let adarGraph = try JSONDecoder().decode(ADARGraph.self, from: contents)

    let abstractGraph = AdjacencyMatrixGraph<ADARNode.Declaration, ADARConnection.Kind>()
    adarGraph.nodes.map(\.declaration).forEach { _ = abstractGraph.createVertex($0) } // TODO: optimize?
    adarGraph.connections.forEach { connection in
        guard
            let fromNode = abstractGraph.vertices.first(where: { $0.data.id == connection.sourceId }),
            let toNode = abstractGraph.vertices.first(where: { $0.data.id == connection.targetId })
        else {
            fatalError("Failed to prepare graph! Source file: \(sourcePath)")
        }

        abstractGraph.addDirectedEdge(
            fromNode,
            to: toNode,
            withWeight: connection.weight,
            userInfo: connection.kind
        )
    }

    return abstractGraph
}
