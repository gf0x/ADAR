import MultipeerConnectivity
import ARKit
import ADAR2Shared

extension MainExperienceViewController: MultipeerSessionDelegate {

    func multipeerSession(_ session: MultipeerSession, didReceive data: Data, from peer: MCPeerID) {
        // Update AR session if it's collaboration data
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: ARSession.CollaborationData.self, from: data) {
            sceneView.session.update(with: collaborationData)
            return
        }
        // Parse graph if it's a graph
        if let fileData = try? JSONDecoder().decode(ADARGraph.self, from: data) {
            self.fileData = fileData
            return
        }
        // Apply transform if it's a transform
        if let transform = try? JSONDecoder().decode(NodeTransformData.self, from: data),
           SettingsProvider.shared.userRole == .slave {
            if let xyRotation = transform.rotationXY {
                self.commitPan(translation: xyRotation)
            } else if let zRotation = transform.rotationZ {
                self.commitRotate(angle: zRotation)
            } else if let scalar = transform.scalar {
                self.commitScale(scalar: scalar)
            }
        }
        // Handle session ID command
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8),
           commandString.starts(with: sessionIDCommandString) {
            let newSessionID = String(commandString[commandString.index(
                commandString.startIndex, offsetBy: sessionIDCommandString.count)...])
            if let oldSessionID = peerSessionIDs[peer] {
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            peerSessionIDs[peer] = newSessionID
        }
    }

    func multipeerSession(_ session: MultipeerSession, peerDidConnect peer: MCPeerID) {
        messageLabel.displayMessage("""
            A peer wants to join the experience.
            Hold the phones next to each other.
            """, duration: 6.0)
        sendARSessionIDTo(peers: [peer])
        if SettingsProvider.shared.userRole == .master {
            sendGraphFile(to: [peer])
        }
    }

    func multipeerSession(_ session: MultipeerSession, peerDidDisconnect peer: MCPeerID) {
        messageLabel.displayMessage("A peer has left the shared experience.")
        if let sessionID = peerSessionIDs[peer] {
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            peerSessionIDs.removeValue(forKey: peer)
        }
    }

    func multipeerSession(_ session: MultipeerSession, shouldAcceptPeer peer: MCPeerID) -> Bool {
        guard let multipeerSession else { return false }
        if multipeerSession.connectedPeers.count > 3 {
            messageLabel.displayMessage("A fifth peer wants to join the experience.\nThis app is limited to four users.", duration: 6.0)
            return false
        }
        return true
    }
}
