//
//  MainExperienceViewController+ARSCNDelegate.swift
//  ADAR
//
//  Created by Alex Frankiv on 01.02.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import ARKit

extension MainExperienceViewController: ARSCNViewDelegate, ARSessionDelegate {

	// MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
		guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

        DispatchQueue.main.async {
            // Present the error that occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

	func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//		guard SettingsProvider.shared.userRole == .master else {
//			print("###\(UIDevice.current.name): \(anchor) \(node) \(node.childNodes.count)")
//			return
//		}
		guard anchor.name == "world_center" else { return }
		node.addChildNode(graphNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else { return }
        updateNodeBrightness(from: frame, node: self.graphNode)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if anchors.contains(where: { $0 is ARParticipantAnchor }) {
			messageLabel.displayMessage("Established joint experience with a peer.")
		}
		for anchor in anchors.filter({ !($0 is ARParticipantAnchor) }) {
			sceneView.session.add(anchor: anchor)
//			if let participantAnchor = anchor as? ARParticipantAnchor {
//				messageLabel.displayMessage("Established joint experience with a peer.")
//				...
//				let anchorEntity = AnchorEntity(anchor: participantAnchor)
//
//				let coordinateSystem = MeshResource.generateCoordinateSystemAxes()
//				anchorEntity.addChild(coordinateSystem)
//
//				let color = participantAnchor.sessionIdentifier?.toRandomColor() ?? .white
//				let coloredSphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.03),
//												materials: [SimpleMaterial(color: color, isMetallic: true)])
//				anchorEntity.addChild(coloredSphere)
//
//				sceneView.scene.addAnchor(anchorEntity)
//			}
//			else if anchor.name == "Anchor for object placement" {
//				// Create a cube at the location of the anchor.
//				let boxLength: Float = 0.05
//				// Color the cube based on the user that placed it.
//				let color = anchor.sessionIdentifier?.toRandomColor() ?? .white
//				let coloredCube = ModelEntity(mesh: MeshResource.generateBox(size: boxLength),
//											  materials: [SimpleMaterial(color: color, isMetallic: true)])
//				// Offset the cube by half its length to align its bottom with the real-world surface.
//				coloredCube.position = [0, boxLength / 2, 0]
//
//				// Attach the cube to the ARAnchor via an AnchorEntity.
//				//   World origin -> ARAnchor -> AnchorEntity -> ModelEntity
//				let anchorEntity = AnchorEntity(anchor: anchor)
//				anchorEntity.addChild(coloredCube)
//				sceneView.scene.addAnchor(anchorEntity)
//			}
		}
	}
}
