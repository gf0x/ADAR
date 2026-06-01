//
//  ADARConnectionKind+UIColor.swift
//  ADAR
//
//  Created by Alex Frankiv on 28.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import UIKit
import ADAR2Shared

extension ADARConnection.Kind {

#if ADAR_DEMO_MODE
    func color(in mode: DisplayMode) -> UIColor {
        return .lightGray
    }
#else
    func color(in mode: DisplayMode) -> UIColor {
        switch mode {
        case .default: .black
        case .structured: self.structuredColor()
        }

    }

    private func structuredColor() -> UIColor {
        return switch self {
        case .propertyOf: .blue
        case .methodOf: .yellow
        case .isOfTypeOf: .black
        case .inherits: .red

        case .methodUsesProperty: .green
        case .methodUsesInit: .orange
        case .methodUsesTypePropertyOrMethod: .brown

        case .methodUsesTypeInParams, .methodUsesTypeAsReturnType: .magenta

        default: .red // TODO: should differ from value for `inherits`
        }
    }
#endif
}
