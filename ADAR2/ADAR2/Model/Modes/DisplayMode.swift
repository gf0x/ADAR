//
//  DisplayMode.swift
//  ADAR2
//
//  Created by Alex Frankiv on 05.07.2025.
//

import Foundation
import UIKit

/// The way the architecture graph is displayed
enum DisplayMode {

    /// The default mode showing architecture monochrome and problematic entities highlighted with color
    case `default`

    /// The mode in which edges colors display the type of edge
    case structured

    mutating func toggle() {
        self = self == .default ? .structured : .default
    }

    var requiresTextAlwaysShown: Bool {
        switch self {
        case .default: false
        case .structured: true
        }
    }

    var icon: UIImage {
        switch self {
        case .default: UIImage(systemName: "point.3.connected.trianglepath.dotted")!
        case .structured: UIImage(systemName: "point.3.filled.connected.trianglepath.dotted")!
        }
    }
}
