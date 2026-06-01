import Foundation
import simd
import ADAR2Shared

extension ADARGraph {
    func findEdgeCrossings(threshold: Float = 0.0001) -> [(ADARConnection, ADARConnection)] {
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.declaration.id, $0.position) })
        var crossings: [(ADARConnection, ADARConnection)] = []

        for i in 0..<connections.count {
            for j in (i + 1)..<connections.count {
                let e1 = connections[i], e2 = connections[j]

                // Skip edges that share a node
                let ids1: Set<String?> = [e1.sourceId, e1.targetId]
                let ids2: Set<String?> = [e2.sourceId, e2.targetId]
                guard ids1.intersection(ids2).isEmpty else { continue }

                guard
                    let p1 = nodeMap[e1.sourceId ?? ""],
                    let p2 = nodeMap[e1.targetId],
                    let q1 = nodeMap[e2.sourceId ?? ""],
                    let q2 = nodeMap[e2.targetId]
                else { continue }

                if distanceBetweenSegments(p1, p2, q1, q2) < threshold {
                    crossings.append((e1, e2))
                }
            }
        }
        return crossings
    }

    /// Minimum distance between two 3D line segments using the parametric approach.
    private func distanceBetweenSegments(
        _ p1: SIMD3<Float>, _ p2: SIMD3<Float>,
        _ q1: SIMD3<Float>, _ q2: SIMD3<Float>
    ) -> Float {
        let u = p2 - p1
        let v = q2 - q1
        let w = p1 - q1

        let a = simd_dot(u, u)
        let b = simd_dot(u, v)
        let c = simd_dot(v, v)
        let d = simd_dot(u, w)
        let e = simd_dot(v, w)

        let D = a * c - b * b
        var sN: Float = 0, sD = D
        var tN: Float = 0, tD = D

        if D < Float.ulpOfOne {
            sN = 0; sD = 1; tN = e; tD = c
        } else {
            sN = b * e - c * d
            tN = a * e - b * d
            if sN < 0 { sN = 0; tN = e; tD = c }
            else if sN > sD { sN = sD; tN = e + b; tD = c }
        }

        if tN < 0 {
            tN = 0
            if -d < 0 { sN = 0 } else if -d > a { sN = sD } else { sN = -d; sD = a }
        } else if tN > tD {
            tN = tD
            if (-d + b) < 0 { sN = 0 } else if (-d + b) > a { sN = sD } else { sN = -d + b; sD = a }
        }

        let sc = abs(sN) < Float.ulpOfOne ? 0 : sN / sD
        let tc = abs(tN) < Float.ulpOfOne ? 0 : tN / tD

        let dp = w + u * sc - v * tc
        return simd_length(dp)
    }
}
