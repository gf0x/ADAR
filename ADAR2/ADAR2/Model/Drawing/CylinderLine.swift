//
//  CylinderLine.swift
//  ADAR
//
//  Created by Alex Frankiv on 28.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import SceneKit

extension SCNGeometry {

    class func arrow(
        from: SCNVector3,
        to: SCNVector3,
        segments: Int,
        arrowRadius: CGFloat = 0.01,
        arrowHeight: CGFloat = 0.04,
        color: UIColor = .white,
        space: Float = 0.01
    ) -> SCNNode {

        let x1 = from.x
        let x2 = to.x

        let y1 = from.y
        let y2 = to.y

        let z1 = from.z
        let z2 = to.z

        let distance =  sqrtf( (x2-x1) * (x2-x1) +
                               (y2-y1) * (y2-y1) +
                               (z2-z1) * (z2-z1) )

        // Cylinder geometry for the arrow shaft
        let cylinder = SCNCylinder(radius: arrowRadius / 10,
                                   height: CGFloat(distance) - arrowHeight)

        cylinder.radialSegmentCount = segments

        cylinder.firstMaterial?.cleverSet(color)

        let lineNode = SCNNode(geometry: cylinder)

        lineNode.position = SCNVector3(x: (from.x + to.x) / 2,
                                       y: (from.y + to.y) / 2,
                                       z: (from.z + to.z) / 2)

        lineNode.eulerAngles = SCNVector3(Float.pi / 2,
                                          acos((to.z-from.z)/distance),
                                          atan2((to.y-from.y),(to.x-from.x)))

        // Cone geometry for the arrowhead
        let cone = SCNCone(topRadius: 0, bottomRadius: arrowRadius, height: arrowHeight)
        cone.radialSegmentCount = segments
        cone.firstMaterial?.cleverSet(color)

        let arrowheadNode = SCNNode(geometry: cone)
        let direction = SCNVector3(
            (to.x - from.x) / distance,
            (to.y - from.y) / distance,
            (to.z - from.z) / distance
        )
        arrowheadNode.position = SCNVector3(
            x: to.x - direction.x * (Float(arrowHeight) / 2 + space),
            y: to.y - direction.y * (Float(arrowHeight) / 2 + space),
            z: to.z - direction.z * (Float(arrowHeight) / 2 + space)
        )

        // Adjust the arrowhead orientation
        arrowheadNode.eulerAngles = SCNVector3(Float.pi / 2,
                                               acos((to.z-from.z)/distance),
                                               atan2((to.y-from.y),(to.x-from.x)))

        // Create a parent node to hold both the line and the arrowhead
        let arrowNode = SCNNode()
        arrowNode.addChildNode(lineNode)
        arrowNode.addChildNode(arrowheadNode)

        return arrowNode
    }
}
