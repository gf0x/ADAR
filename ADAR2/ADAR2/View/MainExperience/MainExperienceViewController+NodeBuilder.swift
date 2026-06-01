import ARKit
import SceneKit
import ADAR2Shared
import ADAR2BugDetector

extension MainExperienceViewController {

    func initExperience() {}

    // MARK: - Init of main node

    func initNode(with graphOverride: ADARGraph? = nil) -> SCNNode {
        guard let graph = resolveGraph(override: graphOverride) else {
            messageLabel?.displayMessage("No graph data available", duration: 3.0)
            return SCNNode()
        }
        let report = graph.bugReport ?? computeBugReport(for: graph)
        return GraphSceneBuilder(mode: mode, itemSizeScalar: itemSizeScalar, bugReport: report).build(from: graph)
    }

    // MARK: - Graph resolution

    func resolveGraph(override: ADARGraph?) -> ADARGraph? {
        if let override { return override }
        if let data = FileSession.shared.graphData {
            do {
                return try JSONDecoder().decode(ADARGraph.self, from: data)
            } catch {
                print("Failed to decode graph: \(error)")
                return nil
            }
        }
        return fileData
    }

    private func computeBugReport(for graph: ADARGraph) -> ADARBugReport {
        let results = ADAR2BugDetector().detect(in: graph)
        return ADARBugReport(
            highDegreeNodeIds: Set(results.highDegreeNodes.map(\.id)),
            lowCohesionEdges: results.lowCohesionEdges,
            cycleEdges: results.cycleEdges,
            edgesWithCrossing: results.edgesWithCrossing
        )
    }
}
