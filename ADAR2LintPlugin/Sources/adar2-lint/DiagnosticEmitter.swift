import Foundation
import ADAR2Shared

// MARK: - DiagnosticEmitter

/// Emits Xcode-compatible diagnostic lines to stdout.
///
/// Xcode parses `<file>:<line>: <severity>: <message>` from Run Script phase
/// output and shows matching entries in the Issue Navigator. Without a file
/// path prefix, warnings only appear in the build log transcript.
///
/// Diagnostics are anchored to the symbol's source file and line number when
/// available (stored in `ADARNode.Declaration`), falling back to the .adar
/// file path so they still land in the Issue Navigator.
struct DiagnosticEmitter {

    let report: ADARBugReport
    let config: ADARConfig
    let suppressions: Set<Suppression>
    /// Path used as the file prefix in diagnostic output when no source location is available.
    let adarFilePath: String
    /// Lookup from symbol ID → Declaration (for resolving source locations and display names).
    let nodeIndex: [String: ADARNode.Declaration]

    func emit() {
        var count = 0
        count += emitHighDegreeNodes()
        count += emitLowCohesionEdges()
        count += emitCycleEdges()
        count += emitEdgeCrossings()
        if count == 0 {
            print("note: [ADAR] No structural issues detected.")
        }
        emitUnusedSuppressions()
    }

    // MARK: - Per-rule emission

    private func emitHighDegreeNodes() -> Int {
        let severity = config.severity(for: .highDegreeNode)
        guard severity != .ignore else { return 0 }
        var count = 0
        for id in report.highDegreeNodeIds.sorted() {
            let decl = nodeIndex[id]
            guard !suppressed(decl, rule: .highDegreeNode) else { continue }
            let kindHint: String
            switch decl?.kind {
            case .method:    kindHint = "potential God method"
            case .property:  kindHint = "potential hub property"
            default:         kindHint = "potential God class / hub type"
            }
            emit(severity,
                 "[high_degree_node] '\(decl?.displayName ?? id)' has anomalously many connections (\(kindHint))",
                 decl: decl)
            count += 1
        }
        return count
    }

    private func emitLowCohesionEdges() -> Int {
        let severity = config.severity(for: .lowCohesionEdge)
        guard severity != .ignore else { return 0 }
        var count = 0
        for edge in report.lowCohesionEdges.sorted(by: edgeOrder) {
            let srcDecl = edge.sourceId.flatMap { nodeIndex[$0] }
            let tgtDecl = nodeIndex[edge.targetId]
            guard !suppressed(srcDecl, rule: .lowCohesionEdge) else { continue }
            let srcName = srcDecl?.displayName ?? edge.sourceId ?? "?"
            let tgtName = tgtDecl?.displayName ?? edge.targetId
            emit(severity,
                 "[low_cohesion_edge] '\(srcName)' → '\(tgtName)' has low membership weight (weak cohesion)",
                 decl: srcDecl)
            count += 1
        }
        return count
    }

    private func emitCycleEdges() -> Int {
        let severity = config.severity(for: .cycleEdge)
        guard severity != .ignore else { return 0 }
        var count = 0
        for edge in report.cycleEdges.sorted(by: edgeOrder) {
            let srcDecl = edge.sourceId.flatMap { nodeIndex[$0] }
            let tgtDecl = nodeIndex[edge.targetId]
            guard !suppressed(srcDecl, rule: .cycleEdge) else { continue }
            let srcName = srcDecl?.displayName ?? edge.sourceId ?? "?"
            let tgtName = tgtDecl?.displayName ?? edge.targetId
            emit(severity,
                 "[cycle_edge] '\(srcName)' → '\(tgtName)' is part of a directed cycle (circular dependency)",
                 decl: srcDecl)
            count += 1
        }
        return count
    }

    private func emitEdgeCrossings() -> Int {
        let severity = config.severity(for: .edgeCrossing)
        guard severity != .ignore else { return 0 }
        var count = 0
        for edge in report.edgesWithCrossing.sorted(by: edgeOrder) {
            let srcDecl = edge.sourceId.flatMap { nodeIndex[$0] }
            let tgtDecl = nodeIndex[edge.targetId]
            guard !suppressed(srcDecl, rule: .edgeCrossing) else { continue }
            let srcName = srcDecl?.displayName ?? edge.sourceId ?? "?"
            let tgtName = tgtDecl?.displayName ?? edge.targetId
            emit(severity,
                 "[edge_crossing] '\(srcName)' → '\(tgtName)' crosses another edge in the 3D graph",
                 decl: srcDecl)
            count += 1
        }
        return count
    }

    // MARK: - Helpers

    /// Returns true if the declaration is suppressed for the given rule.
    /// Matches against both the full displayName (e.g. "confirmAction(_:)") and
    /// the base name before the first "(" (e.g. "confirmAction"), so users can
    /// write `// adar_disable cycle_edge` above `func confirmAction(...)`.
    private func suppressed(_ decl: ADARNode.Declaration?, rule: RuleName) -> Bool {
        guard let name = decl?.displayName else { return false }
        if suppressions.contains(Suppression(symbolName: name, rule: rule)) { return true }
        let baseName = String(name.prefix(while: { $0 != "(" }))
        return suppressions.contains(Suppression(symbolName: baseName, rule: rule))
    }

    private func emit(_ severity: Severity, _ message: String, decl: ADARNode.Declaration?) {
        let prefix: String
        switch severity {
        case .warning: prefix = "warning"
        case .error:   prefix = "error"
        case .ignore:  return
        }
        // File-anchored format: Xcode surfaces these in the Issue Navigator.
        let filePath = decl?.sourceFile ?? adarFilePath
        let line = decl?.sourceLine ?? 1
        print("\(filePath):\(line): \(prefix): [ADAR] \(message)")
    }

    // MARK: - Unused suppression warnings

    /// Emits a warning for every `// adar_disable` annotation that doesn't suppress
    /// anything actually flagged in the current report.
    private func emitUnusedSuppressions() {
        let unused = suppressions.filter { !isActive($0) }
        for suppression in unused.sorted(by: { $0.symbolName < $1.symbolName }) {
            print("\(adarFilePath):1: warning: [ADAR] unused suppression '\(suppression.symbolName)' (\(suppression.rule.rawValue))")
        }
    }

    /// Returns true if the given suppression actually suppresses a flagged diagnostic.
    private func isActive(_ suppression: Suppression) -> Bool {
        switch suppression.rule {
        case .highDegreeNode:
            return report.highDegreeNodeIds.contains(where: { nodeMatches($0, suppression: suppression) })
        case .lowCohesionEdge:
            return report.lowCohesionEdges.contains(where: { edgeSourceMatches($0, suppression: suppression) })
        case .cycleEdge:
            return report.cycleEdges.contains(where: { edgeSourceMatches($0, suppression: suppression) })
        case .edgeCrossing:
            return report.edgesWithCrossing.contains(where: { edgeSourceMatches($0, suppression: suppression) })
        }
    }

    private func nodeMatches(_ id: String, suppression: Suppression) -> Bool {
        guard let decl = nodeIndex[id] else { return false }
        return declMatches(decl, suppression: suppression)
    }

    private func edgeSourceMatches(_ edge: ADARConnection, suppression: Suppression) -> Bool {
        guard let srcId = edge.sourceId, let decl = nodeIndex[srcId] else { return false }
        return declMatches(decl, suppression: suppression)
    }

    private func declMatches(_ decl: ADARNode.Declaration, suppression: Suppression) -> Bool {
        let name = decl.displayName
        if name == suppression.symbolName { return true }
        let baseName = String(name.prefix(while: { $0 != "(" }))
        return baseName == suppression.symbolName
    }

    private func edgeOrder(_ a: ADARConnection, _ b: ADARConnection) -> Bool {
        (a.sourceId ?? "") < (b.sourceId ?? "")
    }
}
