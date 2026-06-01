//
//  Graph.swift
//  Graph
//
//  Created by Andrew McKnight on 5/8/16.
//

import Foundation

open class AbstractGraph<T, U>: CustomStringConvertible where T: Hashable, U: Hashable & OptionSet {

    public required init() {}
    
    public required init(fromGraph graph: AbstractGraph<T, U>) {
        for edge in graph.edges {
            let from = createVertex(edge.from.data)
            let to = createVertex(edge.to.data)
            
            addDirectedEdge(from, to: to, withWeight: edge.weight, userInfo: edge.userInfo)
        }
    }
    
    open var description: String {
        fatalError("abstract property accessed")
    }
    
    open var vertices: [Vertex<T>] {
        fatalError("abstract property accessed")
    }
    
    open var edges: [Edge<T, U>] {
        fatalError("abstract property accessed")
    }
    
    // Adds a new vertex to the matrix.
    // Performance: possibly O(n^2) because of the resizing of the matrix.
    open func createVertex(_ data: T) -> Vertex<T> {
        fatalError("abstract function called")
    }
    
    open func addDirectedEdge(_ from: Vertex<T>, to: Vertex<T>, withWeight weight: Double?, userInfo: U?) {
        fatalError("abstract function called")
    }
    
    open func addUndirectedEdge(_ vertices: (Vertex<T>, Vertex<T>), withWeight weight: Double?, userInfo: U?) {
        fatalError("abstract function called")
    }
    
    open func weightFrom(_ sourceVertex: Vertex<T>, to destinationVertex: Vertex<T>) -> Double? {
        fatalError("abstract function called")
    }
    
    open func edgesFrom(_ sourceVertex: Vertex<T>) -> [Edge<T, U>] {
        fatalError("abstract function called")
    }

    open func mapEdges(_ transform: (Edge<T, U>) -> Edge<T, U>) {
        fatalError("abstract function called")
    }
}

extension AbstractGraph {

    public var shortDescription: String {
        "Graph with \(self.vertices.count) vertices and \(self.edges.count) edges"
    }
}
