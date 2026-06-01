//
//  SCNVector3+Operators.swift
//  ADAR_project
//
//  Created by Alex Frankiv on 27.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import SceneKit

@inline(__always)
func / (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
	return SCNVector3(lhs.x / rhs,
					  lhs.y / rhs,
					  lhs.z / rhs)
}

@inline(__always)
func * (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
	return SCNVector3(lhs.x * rhs.x,
					  lhs.y * rhs.y,
					  lhs.z * rhs.z)
}
