//
//  NodeTransformData.swift
//  ADAR
//
//  Created by Alex Frankiv on 05.02.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import CoreGraphics

/// Here we need only rotation & scaling as translation is managed by multipeering automatically
struct NodeTransformData: Codable {
	// rotations
	var rotationXY: CGPoint?
	var rotationZ: CGFloat?
	// scaling
	var scalar: CGFloat?

	// MARK: - Utilities

	init(xyRotationTranslation: CGPoint) {
		self.rotationXY = xyRotationTranslation
	}

	init(zRotationAngle: CGFloat) {
		self.rotationZ = zRotationAngle
	}

	init(scalar: CGFloat) {
		self.scalar = scalar
	}
}
