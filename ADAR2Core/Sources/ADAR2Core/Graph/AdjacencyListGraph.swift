//
//  AdjacencyListGraph.swift
//  Graph
//
//  Created by Andrew McKnight on 5/13/16.
//

import Foundation

private class EdgeList<T, U> where T: Hashable, U: Hashable & Equatable & OptionSet {

    var vertex: Vertex<T>
    var edges: [Edge<T, U>]?

    init(vertex: Vertex<T>) {
        self.vertex = vertex
    }

    func addEdge(_ edge: Edge<T, U>) {
        edges?.append(edge)
    }

}

open class AdjacencyListGraph<T, U>: AbstractGraph<T, U> where T: Hashable, U: Hashable & OptionSet {

    fileprivate var adjacencyList: [EdgeList<T, U>] = []

    public required init() {
        super.init()
    }

    public required init(fromGraph graph: AbstractGraph<T, U>) {
        super.init(fromGraph: graph)
    }

    open override var vertices: [Vertex<T>] {
        var vertices = [Vertex<T>]()
        for edgeList in adjacencyList {
            vertices.append(edgeList.vertex)
        }
        return vertices
    }

    open override var edges: [Edge<T, U>] {
        var allEdges = Set<Edge<T, U>>()
        for edgeList in adjacencyList {
            guard let edges = edgeList.edges else {
                continue
            }

            for edge in edges {
                allEdges.insert(edge)
            }
        }
        return Array(allEdges)
    }

    open override func createVertex(_ data: T) -> Vertex<T> {
        // check if the vertex already exists
        let matchingVertices = vertices.filter { vertex in
            return vertex.data == data
        }

        if matchingVertices.count > 0 {
            return matchingVertices.last!
        }

        // if the vertex doesn't exist, create a new one
        let vertex = Vertex(data: data, index: adjacencyList.count)
        adjacencyList.append(EdgeList(vertex: vertex))
        return vertex
    }

    open override func addDirectedEdge(_ from: Vertex<T>, to: Vertex<T>, withWeight weight: Double?, userInfo: U?) {
        // works
        let edge = Edge(from: from, to: to, weight: weight, userInfo: userInfo)
        let edgeList = adjacencyList[from.index]
        if edgeList.edges != nil {
            // TODO: might optimize this
            /*
             If the edge already exists, add weight
             */
            if let existingIndex = edgeList.edges!.firstIndex(
                where: { $0.from == from && $0.to == to }
            ) {
                let existingEdge = edgeList.edges![existingIndex]

                // TODO: refactor (remove optionals)
                let newWeight = switch (existingEdge.weight, weight) {
                case (nil, nil): Double?.none
                case (nil, let w): w
                case (let w, nil): w
                case (let w1, let w2): w1! + w2!
                }

                // TODO: refactor (remove optionals)
                let newUserInfo = switch (existingEdge.userInfo, userInfo) {
                case (nil, nil): U?.none
                case (nil, let w): w
                case (let w, nil): w
                case (let w1, let w2): w1!.union(w2!)
                }

                let newEdge = Edge(from: from, to: to, weight: newWeight, userInfo: newUserInfo)
                edgeList.edges![existingIndex] = newEdge
            } else {
                edgeList.addEdge(edge)
            }
        } else {
            edgeList.edges = [edge]
        }
    }

    open override func addUndirectedEdge(_ vertices: (Vertex<T>, Vertex<T>), withWeight weight: Double?, userInfo: U?) {
        addDirectedEdge(vertices.0, to: vertices.1, withWeight: weight, userInfo: userInfo)
        addDirectedEdge(vertices.1, to: vertices.0, withWeight: weight, userInfo: userInfo)
    }

    open override func weightFrom(_ sourceVertex: Vertex<T>, to destinationVertex: Vertex<T>) -> Double? {
        guard let edges = adjacencyList[sourceVertex.index].edges else {
            return nil
        }

        for edge: Edge<T, U> in edges {
            if edge.to == destinationVertex {
                return edge.weight
            }
        }

        return nil
    }

    open override func edgesFrom(_ sourceVertex: Vertex<T>) -> [Edge<T, U>] {
        return adjacencyList[sourceVertex.index].edges ?? []
    }

    /**
     - Warning: O(N^2) time complexity
     */
    open override func mapEdges(_ transform: (Edge<T, U>) -> Edge<T, U>) {
        for i in 0..<adjacencyList.count {
            for j in 0..<(adjacencyList[i].edges?.count ?? 0) {
                adjacencyList[i].edges![j] = transform(adjacencyList[i].edges![j])
            }
        }
    }

    open override var description: String {
        var rows = [String]()
        for edgeList in adjacencyList {

            guard let edges = edgeList.edges else {
                continue
            }

            var row = [String]()
            for edge in edges {
                var value = "\(edge.to.data)"
                if edge.weight != nil {
                    value = "(\(value): \(edge.weight!))"
                }
                row.append(value)
            }

            rows.append("\(edgeList.vertex.data) -> [\(row.joined(separator: ", "))]")
        }

        return rows.joined(separator: "\n")
    }
}
