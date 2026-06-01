//
//  ADARGraph+Loops.swift
//  ADAR2BugDetector
//
//  Created by Alex Frankiv on 06.07.2025.
//

import Foundation
import ADAR2Shared

extension ADARGraph {
    func findDirectedCycles() -> [Set<ADARConnection>] {
        // Build adjacency list: id → Set<id>
        var adjList: [String: Set<String>] = [:]
        for edge in connections {
            guard let sourceId = edge.sourceId else { continue }
            adjList[sourceId, default: []].insert(edge.targetId)
        }

        var blocked = Set<String>()
        var B: [String: Set<String>] = [:]
        var stack: [String] = []
        var cycles: [Set<ADARConnection>] = []

        func unblock(_ u: String) {
            blocked.remove(u)
            for w in B[u, default: []] {
                if blocked.contains(w) {
                    unblock(w)
                }
            }
            B[u] = []
        }

        func circuit(start: String, current: String) -> Bool {
            var foundCycle = false
            stack.append(current)
            blocked.insert(current)

            for neighbor in adjList[current, default: []] {
                if neighbor == start {
                    var cycle = Set<ADARConnection>()
                    for i in 0..<stack.count {
                        let from = stack[i]
                        let to = (i + 1 < stack.count) ? stack[i + 1] : start
                        if let edge = connections.first(where: { $0.sourceId == from && $0.targetId == to }) {
                            cycle.insert(edge)
                        }
                    }
                    cycles.append(cycle)
                    foundCycle = true
                } else if !blocked.contains(neighbor) {
                    if circuit(start: start, current: neighbor) {
                        foundCycle = true
                    }
                }
            }

            if foundCycle {
                unblock(current)
            } else {
                for neighbor in adjList[current, default: []] {
                    B[neighbor, default: []].insert(current)
                }
            }

            _ = stack.popLast()
            return foundCycle
        }

        for start in nodes.map(\.declaration.id) {
            blocked = []
            B = [:]
            stack = []

            _ = circuit(start: start, current: start)
        }

        return cycles
    }
}
