//
//  UIApplication+Env.swift
//  ADAR2
//
//  Created by Alex Frankiv on 19.06.2024.
//

import Foundation
import UIKit

extension UIApplication {
    var isRunningInXcode: Bool {
        ProcessInfo.processInfo.environment["RUNNING_IN_XCODE"] == "YES"
    }

}
