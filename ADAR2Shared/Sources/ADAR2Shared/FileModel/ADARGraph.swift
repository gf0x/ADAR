//
//  ADARFileData.swift
//  ADAR_project
//
//  Created by Alex Frankiv on 26.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import Foundation

public struct ADARGraph: Codable {
	public let nodes: [ADARNode]
	public let connections: [ADARConnection]
    /// Pre-computed bug report, written by the model builder. Absent in older files.
    public let bugReport: ADARBugReport?

    public init(nodes: [ADARNode], connections: [ADARConnection], bugReport: ADARBugReport? = nil) {
        self.nodes = nodes
        self.connections = connections
        self.bugReport = bugReport
    }
}
