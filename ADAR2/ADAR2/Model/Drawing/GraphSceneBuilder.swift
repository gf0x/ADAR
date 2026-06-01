import SceneKit
import ADAR2Shared
import ADAR2BugDetector

#if ADAR_DEMO_MODE
let anomalyColor: UIColor = .orange
#else
let anomalyColor: UIColor = .orange
#endif

/// Builds an SCNNode tree from an ADARGraph.
/// Pure value type — no UIViewController dependency.
struct GraphSceneBuilder {

    let mode: DisplayMode
    let itemSizeScalar: CGFloat
    let bugReport: ADARBugReport

    func build(from graph: ADARGraph) -> SCNNode {
        let root = SCNNode()
        let nodeSize: CGFloat = 7 * itemSizeScalar
        let erroneousEdges = bugReport.lowCohesionEdges
            .union(bugReport.cycleEdges)
            .union(bugReport.edgesWithCrossing)

        let nodeMap = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })

        for entity in graph.nodes {
            root.addChildNode(buildNode(entity: entity, nodeSize: nodeSize, erroneousEdges: erroneousEdges))
        }

        for connection in graph.connections {
            guard
                let srcPos = nodeMap[connection.sourceId ?? ""]?.position,
                let dstPos = nodeMap[connection.targetId]?.position
            else { continue }

            let isErroneous = erroneousEdges.contains(connection)
            let posA = SCNVector3(srcPos / 100)
            let posB = SCNVector3(dstPos / 100)
            let line = SCNGeometry.arrow(
                from: posA,
                to: posB,
                segments: 10,
                arrowRadius: 0.01 * itemSizeScalar,
                arrowHeight: 0.04 * itemSizeScalar,
                color: isErroneous ? anomalyColor : connection.kind.color(in: mode),
                space: Float((nodeSize / 4) / 100)
            )
            line.adarInfo = .edge(kind: connection.kind, isErroneous: isErroneous)
            root.addChildNode(line)
        }

        return root
    }

    private func buildNode(
        entity: ADARNode,
        nodeSize: CGFloat,
        erroneousEdges: Set<ADARConnection>
    ) -> SCNNode {
        let hasIssue = bugReport.highDegreeNodeIds.contains(entity.id)
            || erroneousEdges.contains(where: { $0.sourceId == entity.id || $0.targetId == entity.id })

        let geometry: SCNGeometry = switch entity.declaration.kind {
        case .data_type: SCNSphere(radius: nodeSize)
        case .method: SCNBox(width: nodeSize, height: nodeSize, length: nodeSize, chamferRadius: 1)
        case .property: SCNCone(topRadius: 0, bottomRadius: nodeSize / 2, height: nodeSize)
        }

        let node = SCNNode(geometry: geometry)

        let label = SCNNode(geometry: SCNText(string: entity.declaration.displayName, extrusionDepth: 0.1))
        label.position = SCNVector3(5 * itemSizeScalar, 5 * itemSizeScalar, 5 * itemSizeScalar)
        label.isHidden = !mode.requiresTextAlwaysShown
        label.scale = SCNVector3(Float(itemSizeScalar), Float(itemSizeScalar), Float(itemSizeScalar))
        let labelColor: UIColor
#if ADAR_DEMO_MODE
        labelColor = hasIssue ? anomalyColor : .lightGray
#else
        labelColor = hasIssue ? anomalyColor : .white
#endif
        label.geometry?.firstMaterial?.cleverSet(labelColor)
        node.addChildNode(label)

        node.scale = SCNVector3(x: 0.002, y: 0.002, z: 0.002)
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y, .Z]
        node.constraints = [billboard]

        let nodeColor: UIColor
#if ADAR_DEMO_MODE
        nodeColor = hasIssue ? anomalyColor : .lightGray
#else
        nodeColor = hasIssue ? anomalyColor : .white
#endif
        node.geometry?.firstMaterial?.cleverSet(nodeColor)
        node.position = SCNVector3(entity.position.x / 100, entity.position.y / 100, entity.position.z / 100)
        node.adarInfo = .node(id: entity.id)

        return node
    }
}

// MARK: - SCNMaterial helpers

extension SCNMaterial {

    func cleverSet(_ color: UIColor) {
        lightingModel = .physicallyBased
        metalness.contents = 0.0
        roughness.contents = 0.6
        diffuse.contents = color
        baseColorStored = color
    }
}

private var baseColorKey: UInt8 = 0

extension SCNMaterial {
    var baseColorStored: UIColor? {
        get { objc_getAssociatedObject(self, &baseColorKey) as? UIColor }
        set { objc_setAssociatedObject(self, &baseColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
