//
//  MainExperienceController+ARCoachingOverlayViewDelegate.swift
//  ADAR
//
//  Created by Alex Frankiv on 01.02.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import UIKit
import ARKit

extension MainExperienceViewController: ARCoachingOverlayViewDelegate {

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        messageLabel.ignoreMessages = true
        messageLabel.isHidden = true
        restartButton.isHidden = true
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        messageLabel.ignoreMessages = false
        restartButton.isHidden = false
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        resetTracking()
    }

    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        coachingOverlay.goal = .tracking

        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)

        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
    }
}
