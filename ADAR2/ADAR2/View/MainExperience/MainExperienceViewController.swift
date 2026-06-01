//
//  MainExperienceViewController.swift
//  ADAR
//
//  Created by Alex Frankiv on 27.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity
import ADAR2Shared

class MainExperienceViewController: UIViewController {

	// MARK: - IBOutlets
    @IBOutlet private(set) var sceneView: ARSCNView!
    @IBOutlet private(set) weak var messageLabel: MessageLabel!

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private(set) weak var restartButton: UIButton!
    @IBOutlet private(set) weak var toggleModeButton: UIButton!
    @IBOutlet private(set) weak var placementModeButton: UIButton!
    @IBOutlet private(set) weak var subgraphModeButton: UIButton!

    let coachingOverlay = ARCoachingOverlayView()

	// MARK: - Properties
    private(set) var mode: DisplayMode = .default
    var isInPlacementMode: Bool = true {
        didSet { self.placementModeButton.isSelected = self.isInPlacementMode }
    }

    private(set) lazy var itemSizeScalar: CGFloat = {
        let n = max(1, fullGraph.nodes.count)
        return CGFloat(min(2.0, max(0.3, 5.0 / pow(Double(n), 1.0 / 3.0))))
    }()

	// remembering rotations
	var lastRotationX: Float = 0
	var lastRotationY: Float = 0
	var lastRotationZ: Float = 0

	lazy var graphNode: SCNNode = {
		return initNode()
	}()

    // Subgraph state
    var isSubgraphSelectionEnabled: Bool = false {
        didSet { subgraphModeButton?.isSelected = isSubgraphSelectionEnabled }
    }
    var isInSubgraphMode: Bool = false
    var subgraphBackButton: UIButton?
    var _cachedFullGraph: ADARGraph?
    var selectedNodeSCNNode: SCNNode?

	// for slave only
	var fileData: ADARGraph? {
		didSet {
			guard SettingsProvider.shared.userRole == .slave
				else { fatalError("Should be used for slave only") }
		}
	}

	override var prefersHomeIndicatorAutoHidden: Bool {
        // Request that iOS hide the home indicator to improve immersiveness of the AR experience.
        return true
    }

	// multipeer
    var multipeerSession: MultipeerSession?
	var sessionIDObservation: NSKeyValueObservation?
    var peerSessionIDs = [MCPeerID: String]()

	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

		guard SettingsProvider.shared.userRole != .undefined else {
			fatalError("Undefined fole of user in \(#file)")
		}
		// Prevent the screen from being dimmed to avoid interrupting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
		self.enableGestures()
        subgraphModeButton.addTarget(self, action: #selector(toggleSubgraphSelection), for: .touchUpInside)

        // Set the view's delegate
        sceneView.delegate = self
		sceneView.session.delegate = self

#if ADAR_DEMO_MODE
        sceneView.scene.background.contents = UIColor.white
#endif

#if DEBUG
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
#else
        sceneView.showsStatistics = false
#endif

		sessionIDObservation = observe(\.sceneView.session.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue!)")
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }

		self.setupCoachingOverlay()

        // Start looking for other players via MultiPeerConnectivity.
        multipeerSession = MultipeerSession(delegate: self)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
		if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
			configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
		configuration.isCollaborationEnabled = true
		configuration.environmentTexturing = .automatic

        configuration.isLightEstimationEnabled = true

		self.initExperience()
        // Run the view's session

        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        sessionIDObservation?.invalidate()
        sessionIDObservation = nil
        FileSession.shared.reset()
        _cachedFullGraph = nil
    }

    // TODO: should make this smoother
    func forceRedrawGraph() {
        self.sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }; self.graphNode = initNode()
    }

	// MARK: - IBActions
	@IBAction func resetTracking() {
        guard let configuration = sceneView.session.configuration else { print("A configuration is required"); return }
        sceneView.session.run(configuration, options: [.resetTracking])
    }

    @IBAction func toggleMenu() {
        self.stackView.isHidden.toggle()
    }

    @IBAction func goback() {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func toggleMode() {
        self.mode.toggle()
        self.toggleModeButton.setImage(self.mode.icon, for: .normal)
        self.graphNode.update(for: self.mode)
    }

    @IBAction func togglePlacement(_ sender: Any) {
        self.isInPlacementMode.toggle()
    }

    @objc func toggleSubgraphSelection() {
        isSubgraphSelectionEnabled.toggle()
    }

    @IBAction func showEdgeLegend() {
        let sheet = EdgeLegendSheetViewController()
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    @IBAction func showItemSizeScalarSheet() {
        let sheet = ItemSizeScalarSheetViewController()
        sheet.initialValue = self.itemSizeScalar
        sheet.valueChanged = { [weak self] value in
            self?.itemSizeScalar = value
        }
        if let sheetPresentation = sheet.sheetPresentationController {
            sheetPresentation.detents = [.medium()]
        }
        present(sheet, animated: true)
    }
}

extension MainExperienceViewController {

    func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                sceneView.session.remove(anchor: anchor)
            }
        }
    }

    func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = multipeerSession else { return }
        let idString = sceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }

    func sendGraphFile(to peers: [MCPeerID]) {
        guard let fileData = FileSession.shared.graphData else { return }
        multipeerSession?.sendToPeers(fileData, reliably: true, peers: peers)
    }

    func send(_ nodeTransform: NodeTransformData) {
        guard SettingsProvider.shared.userRole == .master else { return }
        guard let data = try? JSONEncoder().encode(nodeTransform) else { return }
        multipeerSession?.sendToAllPeers(data, reliably: true)
    }

    func updateNodeBrightness(from frame: ARFrame, node: SCNNode) {
        SCNNode.traverse(node: node) { node in
            guard let m = node.geometry?.firstMaterial else { return }
            guard let estimate = frame.lightEstimate else { return }

            // Зберігаємо базовий колір один раз
            if m.baseColorStored == nil {
                if let current = m.diffuse.contents as? UIColor {
                    m.baseColorStored = current
                } else {
                    return
                }
            }

            guard let base = m.baseColorStored else { return }

            // Нелінійна адаптація яскравості
            let intensity = CGFloat(estimate.ambientIntensity)
            let raw = max(0.0, min(intensity / 1000.0, 1.0))
            let norm = 0.25 + sqrt(raw) * 0.75

            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

            let adjusted = UIColor(
                hue: h,
                saturation: s,
                brightness: b * norm,
                alpha: a
            )

            m.diffuse.contents = adjusted
        }
    }
}
