import Foundation
import SceneKit
import ADAR2Shared

// MARK: - ADARNodeInfo storage (NSMapTable with weak SCNNode keys)

private final class ADARNodeInfoBox {
    let value: ADARNodeInfo
    init(_ value: ADARNodeInfo) { self.value = value }
}

private let nodeInfoStorage = NSMapTable<SCNNode, ADARNodeInfoBox>.weakToStrongObjects()

extension SCNNode {
    var adarInfo: ADARNodeInfo? {
        get { nodeInfoStorage.object(forKey: self)?.value }
        set {
            if let newValue {
                nodeInfoStorage.setObject(ADARNodeInfoBox(newValue), forKey: self)
            } else {
                nodeInfoStorage.removeObject(forKey: self)
            }
        }
    }
}

// MARK: - ADARNodeInfo

enum ADARNodeInfo {
    case node(id: String)
    case edge(kind: ADARConnection.Kind, isErroneous: Bool)
}

// MARK: - SCNNode helpers

extension SCNNode {

    func update(for mode: DisplayMode) {
        SCNNode.traverse(node: self) { node in
            if case .edge(let kind, let isErroneous) = node.adarInfo {
                let color = isErroneous ? anomalyColor : kind.color(in: mode)
                node.childNodes.forEach { $0.geometry?.firstMaterial?.cleverSet(color) }
            }
            if node.geometry is SCNText {
                node.isHidden = !mode.requiresTextAlwaysShown
            }
        }
    }

    func toggleShowTextIfHasOne() {
        SCNNode.traverse(node: self) { node in
            if node.geometry is SCNText {
                node.isHidden.toggle()
            }
        }
    }

    static func traverse(node: SCNNode, action: (SCNNode) -> Void) {
        action(node)
        node.childNodes.forEach { traverse(node: $0, action: action) }
    }
}
