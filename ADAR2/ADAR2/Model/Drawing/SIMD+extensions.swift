//
//  SIMD+extensions.swift
//  ADAR
//
//  Created by Alex Frankiv on 28.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import simd

extension float4x4 {
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}
