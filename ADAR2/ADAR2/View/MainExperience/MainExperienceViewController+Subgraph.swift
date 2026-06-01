import UIKit
import SceneKit
import ADAR2Shared
import ADAR2NaiveForceDirectedVisualizer

extension MainExperienceViewController {

    // MARK: - Full graph cache

    /// The original full graph, decoded once and cached for the lifetime of the session.
    var fullGraph: ADARGraph {
        if let cached = _cachedFullGraph { return cached }
        let graph: ADARGraph
        if let data = FileSession.shared.graphData {
            do {
                graph = try JSONDecoder().decode(ADARGraph.self, from: data)
            } catch {
                print("Failed to decode full graph: \(error)")
                graph = self.fileData ?? ADARGraph(nodes: [], connections: [])
            }
        } else {
            graph = self.fileData ?? ADARGraph(nodes: [], connections: [])
        }
        _cachedFullGraph = graph
        return graph
    }

    // MARK: - Sheet

    func showSubgraphSheet(for nodeId: String) {
        guard let node = fullGraph.nodes.first(where: { $0.id == nodeId }) else { return }
        let sheet = SubgraphSheetViewController()
        sheet.nodeDisplayName = node.declaration.displayName
        sheet.onConfirm = { [weak self] depth, progress, completion in
            self?.showSubgraph(centeredOn: nodeId, depth: depth, progress: progress, completion: completion)
        }
        sheet.onDismiss = { [weak self] in
            self?.clearNodeHighlight()
        }
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium()]
        }
        present(sheet, animated: true)
    }

    // MARK: - Enter / exit subgraph

    func showSubgraph(centeredOn nodeId: String, depth: Int, progress: @escaping (Double) -> Void, completion: @escaping () -> Void) {
        isSubgraphSelectionEnabled = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let subgraph = self.computeSubgraph(centeredOn: nodeId, depth: depth, in: self.fullGraph)
            let revisualized = ADAR2NaiveForceDirectedVisualizer().reVisualize(subgraph, progressHandler: progress)
            DispatchQueue.main.async {
                self.applyGraph(revisualized)
                self.isInSubgraphMode = true
                self.showBackToFullGraphButton()
                completion()
            }
        }
    }

    func exitSubgraph() {
        applyGraph(fullGraph)
        isInSubgraphMode = false
        isSubgraphSelectionEnabled = false
        hideBackToFullGraphButton()
    }

    // MARK: - In-place graph content replacement

    /// Replaces the children of `graphNode` without moving it in the scene.
    /// This preserves current position, scale, and rotation.
    func applyGraph(_ graph: ADARGraph) {
        selectedNodeSCNNode = nil   // old node is being removed; no need to restore its material
        graphNode.childNodes.forEach { $0.removeFromParentNode() }
        let tempNode = initNode(with: graph)
        let children = Array(tempNode.childNodes)
        children.forEach { $0.removeFromParentNode(); graphNode.addChildNode($0) }
    }

    // MARK: - Node highlight

    func highlightNode(_ node: SCNNode) {
        clearNodeHighlight()
        node.geometry?.firstMaterial?.emission.contents = UIColor.systemYellow
        selectedNodeSCNNode = node
    }

    func clearNodeHighlight() {
        selectedNodeSCNNode?.geometry?.firstMaterial?.emission.contents = UIColor.black
        selectedNodeSCNNode = nil
    }

    // MARK: - BFS subgraph computation

    private func computeSubgraph(centeredOn nodeId: String, depth: Int, in graph: ADARGraph) -> ADARGraph {
        var visited = Set<String>()
        var frontier: Set<String> = [nodeId]

        for _ in 0..<depth {
            var next = Set<String>()
            for id in frontier {
                for connection in graph.connections {
                    if connection.sourceId == id && !visited.contains(connection.targetId) {
                        next.insert(connection.targetId)
                    }
                    if connection.targetId == id,
                       let src = connection.sourceId, !visited.contains(src) {
                        next.insert(src)
                    }
                }
            }
            visited.formUnion(frontier)
            frontier = next.subtracting(visited)
        }
        visited.formUnion(frontier)

        let subNodes = graph.nodes.filter { visited.contains($0.id) }
        let subConnections = graph.connections.filter {
            visited.contains($0.sourceId ?? "") && visited.contains($0.targetId)
        }

        let subBugReport: ADARBugReport? = graph.bugReport.map { report in
            let subConnectionSet = Set(subConnections)
            return ADARBugReport(
                highDegreeNodeIds: report.highDegreeNodeIds.intersection(visited),
                lowCohesionEdges: report.lowCohesionEdges.intersection(subConnectionSet),
                cycleEdges: report.cycleEdges.intersection(subConnectionSet),
                edgesWithCrossing: report.edgesWithCrossing.intersection(subConnectionSet)
            )
        }

        return ADARGraph(nodes: subNodes, connections: subConnections, bugReport: subBugReport)
    }

    // MARK: - Back button

    func showBackToFullGraphButton() {
        let button = UIButton(type: .system)
        button.setTitle("← Full graph", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backToFullGraphTapped), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        subgraphBackButton = button
    }

    func hideBackToFullGraphButton() {
        subgraphBackButton?.removeFromSuperview()
        subgraphBackButton = nil
    }

    @objc func backToFullGraphTapped() {
        exitSubgraph()
    }
}

