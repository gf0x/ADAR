// The Swift Programming Language
// https://docs.swift.org/swift-book

import ADAR2Core
import ADAR2Shared
import os.log
import CoreML

import ADAR2NaiveForceDirectedVisualizer
import ADAR2AdvancedForceDirectedVisualizer

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2MLVisualizer", category: "general")

// MARK: - Const
private enum Const {
    static let modelExtension = "mlpackage" // loaded at runtime; MLModel accepts .mlpackage on iOS & macOS
}

public final class ADAR2MLVisualizer<CoreVisualizer: ADARForceDirectedVisualizer>: ADARForceDirectedVisualizer {

    // MARK: - Protocol (ADARVisualizer)
    public typealias NodeData = CoreVisualizer.NodeData
    public typealias EdgeData = CoreVisualizer.EdgeData

    // MARK: - Properties
    private let model: ADAR2MLVisualizerModel
    private let coreVisualizer: CoreVisualizer

    // MARK: - Init
    public init(with model: ADAR2MLVisualizerModel, coreVisualizer: CoreVisualizer) {
        self.model = model
        self.coreVisualizer = coreVisualizer
    }

    // MARK: - Methods (Public)
    public func prepareVisualRepresentation(
        of graph: AbstractGraph<NodeData, EdgeData>,
        withPredefinedHeuristics heuristics: [NodeData: ADARVisualizerHeuristicsItem]? = nil,
        withConfiguration configuration: ADARForceDirectedVisualizerConfiguration = .default
    ) -> (graph: ADARGraph, iterationsRun: Int) {

        if heuristics != nil {
            logger.warning("Heuristics is not supported for this visualiser yet!")
        }

        let model = self.getModel()

        logger.info("Preparing input for the model...")
        let input = prepareInput(from: graph)

        logger.info("Running the model prediction...")
        let prediction = try! model.prediction(from: input)

        logger.info("Processing the model prediction...")
        guard let outputArray = prediction.featureValue(for: self.model.outputVariableName)?.multiArrayValue else {
            fatalError("Prediction failed!")
        }

        logger.info("Preparing heuristics from the model prediction...")
        let heuristics = graph.generateHeuristicsDictionary(from: outputArray)

        logger.info("Running \(type(of: self.coreVisualizer)) visualiser...")
        return self.coreVisualizer
            .prepareVisualRepresentation(
                of: graph,
                withPredefinedHeuristics: heuristics,
                withConfiguration: configuration
            )
    }

    // MARK: - Methods (Private)
    private func getModel() -> MLModel {
        guard let modelURL = Bundle.module.url(forResource: self.model.rawValue, withExtension: Const.modelExtension)
        else { fatalError("Could not find the Core ML model in the project.") }
        
        let config = MLModelConfiguration() // TODO: (later) check whether extra config is needed
        return try! MLModel(contentsOf: modelURL, configuration: config)
    }

    private func prepareInput(from graph: AbstractGraph<NodeData, EdgeData>) -> MLDictionaryFeatureProvider {
        let (nodeFeatures, edgeIndex, edgeWeight) = graph.prepareModelInput()

        return try! MLDictionaryFeatureProvider(dictionary: [
            "node_features": nodeFeatures,
            "edge_index": edgeIndex,
            "edge_weight": edgeWeight
        ])
    }
}


extension AbstractGraph {

    func prepareModelInput() -> (nodeFeatures: MLMultiArray, edgeIndex: MLMultiArray, edgeWeight: MLMultiArray) {
        var nodeFeaturesArray: [Float] = []
        var edgeIndexArray: [Int] = []
        var edgeWeightArray: [Float] = []

        // Map each vertex to its index for easy lookup
        let vertexIndexMap: [Vertex<T>: Int] = {
            var map: [Vertex<T>: Int] = [:]
            for (index, vertex) in vertices.enumerated() {
                map[vertex] = index
            }
            return map
        }()

        // Calculate the degree (number of edges) for each vertex
        var degreeMap: [Vertex<T>: Int] = [:]
        for edge in edges {
            degreeMap[edge.from, default: 0] += 1
            degreeMap[edge.to, default: 0] += 1
        }

        // Prepare node features (node degree as a feature)
        for vertex in vertices {
            let degree = degreeMap[vertex, default: 0]
            nodeFeaturesArray.append(Float(degree))  // Node degree as the feature
        }

        // Prepare edge index and edge weight
        for edge in edges {
            if let fromIndex = vertexIndexMap[edge.from], let toIndex = vertexIndexMap[edge.to] {
                edgeIndexArray.append(contentsOf: [fromIndex, toIndex])  // Edge between vertices
                edgeWeightArray.append(Float(edge.weight ?? 1))           // Default malformed or legacy edges
            }
        }

        // Convert to MLMultiArray format for Core ML model
        let nodeFeatures = try! MLMultiArray(shape: [NSNumber(value: nodeFeaturesArray.count), 1], dataType: .float32)
        let edgeIndex = try! MLMultiArray(shape: [2, NSNumber(value: edgeIndexArray.count / 2)], dataType: .int32)
        let edgeWeight = try! MLMultiArray(shape: [NSNumber(value: edgeWeightArray.count)], dataType: .float32)

        // Assign values to MLMultiArray
        for (i, value) in nodeFeaturesArray.enumerated() {
            nodeFeatures[i] = NSNumber(value: value)
        }
        for (i, value) in edgeIndexArray.enumerated() {
            edgeIndex[i] = NSNumber(value: value)
        }
        for (i, value) in edgeWeightArray.enumerated() {
            edgeWeight[i] = NSNumber(value: value)
        }

        return (nodeFeatures, edgeIndex, edgeWeight)
    }
}

// Define a dictionary type that maps NodeData to ADARVisualizerHeuristicsItem
//typealias HeuristicsDictionary = [ADARNode.Declaration: ADARVisualizerHeuristicsItem]

// Extension to prepare the dictionary of heuristics items for each node
extension AbstractGraph where T: Hashable {

    func generateHeuristicsDictionary(from coordinates: MLMultiArray) -> [T: ADARVisualizerHeuristicsItem] {
        var heuristicsDictionary: [T: ADARVisualizerHeuristicsItem] = [:]

        for (index, vertex) in vertices.enumerated() {
            // Retrieve the x, y, z coordinates for each node
            let x = coordinates[index * 3].doubleValue
            let y = coordinates[index * 3 + 1].doubleValue
            let z = coordinates[index * 3 + 2].doubleValue

            // Create an ADARVisualizerHeuristicsItem for each node
            let heuristicsItem = ADARVisualizerHeuristicsItem(x: x, y: y, z: z)

            // Add the heuristics item to the dictionary
            heuristicsDictionary[vertex.data] = heuristicsItem
        }

        return heuristicsDictionary
    }
}
