import Foundation

// MARK: - Rule names (canonical string keys used in .adarconfig and adar_disable/adar_enable comments)

enum RuleName: String, CaseIterable {
    case highDegreeNode  = "high_degree_node"
    case lowCohesionEdge = "low_cohesion_edge"
    case cycleEdge       = "cycle_edge"
    case edgeCrossing    = "edge_crossing"
}

// MARK: - Severity

enum Severity: String, Codable {
    case warning
    case error
    case ignore
}

// MARK: - Config file format (.adarconfig)

/// Loaded from `.adarconfig` (JSON) in the project root.
/// All rules default to `warning` when the file is absent or a key is missing.
///
/// Example `.adarconfig`:
/// ```json
/// {
///   "rules": {
///     "high_degree_node": "warning",
///     "low_cohesion_edge": "warning",
///     "cycle_edge": "error",
///     "edge_crossing": "ignore"
///   }
/// }
/// ```
struct ADARConfig {
    var highDegreeNode:  Severity = .warning
    var lowCohesionEdge: Severity = .warning
    var cycleEdge:       Severity = .warning
    var edgeCrossing:    Severity = .warning

    func severity(for rule: RuleName) -> Severity {
        switch rule {
        case .highDegreeNode:  return highDegreeNode
        case .lowCohesionEdge: return lowCohesionEdge
        case .cycleEdge:       return cycleEdge
        case .edgeCrossing:    return edgeCrossing
        }
    }

    // MARK: - Loading

    static func load(from url: URL) -> ADARConfig {
        guard
            let data = try? Data(contentsOf: url),
            let raw = try? JSONDecoder().decode(RawConfig.self, from: data)
        else {
            return ADARConfig()
        }
        var config = ADARConfig()
        if let v = raw.rules[RuleName.highDegreeNode.rawValue]  { config.highDegreeNode  = v }
        if let v = raw.rules[RuleName.lowCohesionEdge.rawValue] { config.lowCohesionEdge = v }
        if let v = raw.rules[RuleName.cycleEdge.rawValue]       { config.cycleEdge       = v }
        if let v = raw.rules[RuleName.edgeCrossing.rawValue]    { config.edgeCrossing    = v }
        return config
    }

    private struct RawConfig: Decodable {
        let rules: [String: Severity]
    }
}
