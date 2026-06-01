//
//  MainExperienceViewController+Gestures.swift
//  ADAR
//
//  Created by Alex Frankiv on 01.02.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension MainExperienceViewController {

	// MARK: - Init
	func enableGestures() {
		// only `master` controls the position
		guard SettingsProvider.shared.userRole == .master else { return }
		self.addTapGesture()
		self.addPinchGesture()
		// not used so far as it can be easily treated wrongly as scaling and scaling is quite expensive in terms of performance
		//		self.addRotationGesture()
		self.addPanGesture()
	}

	// MARK: - GestureRecognizers
	private func addTapGesture() {
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
		self.sceneView.addGestureRecognizer(tapGesture)
	}

	private func addPinchGesture() {
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
		self.sceneView.addGestureRecognizer(pinchGesture)
	}

	private func addRotationGesture() {
		let panGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
		self.sceneView.addGestureRecognizer(panGesture)
	}

	private func addPanGesture() {
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
		self.sceneView.addGestureRecognizer(panGesture)
	}

	@objc func didTap(_ gesture: UIPanGestureRecognizer) {
        let tapLocation = gesture.location(in: self.sceneView)
        if self.graphNode.parent == nil || self.isInPlacementMode {
            if isInSubgraphMode {
                isInSubgraphMode = false
                isSubgraphSelectionEnabled = false
                hideBackToFullGraphButton()
            }
            self.forceRedrawGraph()
            self.placeGraph(at: tapLocation)
        } else {
            self.tapNode(at: tapLocation)
        }

	}

    private func placeGraph(at tapLocation: CGPoint) {
        defer { self.isInPlacementMode = false }

//        guard sceneView.session.currentFrame?.anchors.isEmpty ?? false else { return }
        guard let query = self.sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
            else {
                self.messageLabel.displayMessage("Cannot put graph there", duration: 1.0)
                return
        }
        let results = self.sceneView.session.raycast(query)
        guard let result = results.first else {
            self.messageLabel.displayMessage("Cannot put graph there", duration: 1.0)
            return
        }
        let anchor = ARAnchor(name: "world_center",
                              transform: result.worldTransform)
        sceneView.session.add(anchor: anchor)
    }

    private func tapNode(at tapLocation: CGPoint) {
        // Walk hit results looking for a tagged node
        let hitResults = sceneView.hitTest(tapLocation, options: nil)
        for hit in hitResults {
            var scanned: SCNNode? = hit.node
            while let n = scanned {
                if case .node(let id) = n.adarInfo {
                    if isSubgraphSelectionEnabled {
                        highlightNode(n)
                        showSubgraphSheet(for: id)
                    }
                    return
                }
                scanned = n.parent
            }
        }

        guard isSubgraphSelectionEnabled else {
            hitResults.first?.node.toggleShowTextIfHasOne()
            return
        }

        // No direct hit — find the nearest graph node within 44 pt on screen
        let tapRadius: CGFloat = 44
        var nearestNode: SCNNode?
        var nearestDistance = tapRadius

        graphNode.enumerateChildNodes { node, _ in
            guard case .node = node.adarInfo else { return }
            let projected = self.sceneView.projectPoint(node.worldPosition)
            guard projected.z > 0, projected.z < 1 else { return }
            let dx = CGFloat(projected.x) - tapLocation.x
            let dy = CGFloat(projected.y) - tapLocation.y
            let dist = hypot(dx, dy)
            if dist < nearestDistance {
                nearestDistance = dist
                nearestNode = node
            }
        }

        if let node = nearestNode, case .node(let id) = node.adarInfo {
            highlightNode(node)
            showSubgraphSheet(for: id)
            return
        }

        hitResults.first?.node.toggleShowTextIfHasOne()
    }

	@objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
		switch gesture.state {
		case .began:
			gesture.scale = CGFloat(graphNode.scale.x)
		case .changed:
			self.commitScale(scalar: gesture.scale)
			self.send(NodeTransformData(scalar: gesture.scale))
		default: break
		}
	}

	func commitScale(scalar: CGFloat) {
        let scalar = Float(scalar)
        graphNode.scale = SCNVector3(x: scalar, y: scalar, z: scalar)
	}

	@objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
		switch gesture.state {
		case .changed:
			self.commitRotate(angle: gesture.rotation)
			self.send(NodeTransformData(zRotationAngle: gesture.rotation))
		case .ended:
			self.lastRotationZ += -Float(gesture.rotation)
		default:
			break
		}
	}

	func commitRotate(angle: CGFloat) {
		self.graphNode.eulerAngles.z = self.lastRotationZ - Float(angle)
	}

	@objc func didPan(_ gesture: UIPanGestureRecognizer) {
		switch gesture.state {
		case .changed:
			self.commitPan(translation: gesture.translation(in: nil))
			self.send(NodeTransformData(xyRotationTranslation: gesture.translation(in: nil)))
		case .ended:
			self.lastRotationX += Float(-gesture.translation(in: self.sceneView).y / self.sceneView.bounds.width)
			self.lastRotationY += Float(-gesture.translation(in: self.sceneView).x / self.sceneView.bounds.height)
		default:
			break
		}
	}

    func commitPan(translation: CGPoint) {
        self.graphNode.eulerAngles.x = self.lastRotationX + Float(-translation.y / self.sceneView.bounds.width)
        self.graphNode.eulerAngles.y = self.lastRotationY + Float(-translation.x / self.sceneView.bounds.height)
	}
}
