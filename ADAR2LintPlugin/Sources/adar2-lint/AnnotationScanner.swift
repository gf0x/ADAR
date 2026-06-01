import Foundation

// MARK: - Suppression

/// Represents a single `// adar_disable <rule>` annotation matched to a declaration name.
struct Suppression: Hashable {
    /// The symbol's `displayName` as it appears in the `.adar` file (e.g. `"MyClass"`).
    let symbolName: String
    let rule: RuleName
}

// MARK: - AnnotationScanner

/// Scans Swift source files for `// adar_disable <rule>`, `// adar_disable:next <rule>`,
/// and `// adar_enable <rule>` comments.
///
/// **Single declaration** — comment on the line immediately before, or trailing on the same line:
/// ```swift
/// // adar_disable cycle_edge
/// class MyClass { ... }
///
/// class AnotherClass { ... }  // adar_disable high_degree_node
/// ```
///
/// **Next declaration only** — like SwiftLint's `:next`, never opens a region:
/// ```swift
/// // adar_disable:next cycle_edge
/// class MyClass { ... }
/// ```
///
/// **Region** — suppress multiple declarations between disable/enable:
/// ```swift
/// // adar_disable low_cohesion_edge
/// class A { }
/// class B { }
/// // adar_enable low_cohesion_edge
/// class C { }   // not suppressed
/// ```
struct AnnotationScanner {

    static func scan(sourceDir: URL) -> Set<Suppression> {
        let swiftFiles = collectSwiftFiles(in: sourceDir)
        var suppressions = Set<Suppression>()
        for file in swiftFiles {
            suppressions.formUnion(scan(file: file))
        }
        return suppressions
    }

    // MARK: - Per-file scan

    private static func scan(file: URL) -> Set<Suppression> {
        guard let source = try? String(contentsOf: file, encoding: .utf8) else { return [] }
        let lines = source.components(separatedBy: .newlines)

        var suppressions = Set<Suppression>()
        // Rules that are currently open (no declaration paired yet → file-wide until adar_enable)
        var openDisables = Set<RuleName>()

        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check for leading disable/enable/disable:next annotations
            if let (action, rule) = parseAnnotation(from: trimmed) {
                switch action {
                case .disableNext:
                    // Suppress exactly the next declaration — never opens a region
                    if let name = nextDeclarationName(after: i, in: lines) {
                        suppressions.insert(Suppression(symbolName: name, rule: rule))
                    }
                    // If no declaration follows, the annotation is unused (surfaced by DiagnosticEmitter)

                case .disable:
                    // Look ahead for a declaration on the very next non-blank line
                    if let name = nextDeclarationName(after: i, in: lines) {
                        suppressions.insert(Suppression(symbolName: name, rule: rule))
                    } else {
                        // No paired declaration → open region disable
                        openDisables.insert(rule)
                    }

                case .enable:
                    openDisables.remove(rule)
                }
                i += 1
                continue
            }

            // If we're inside an open disable region, check for a declaration
            if !openDisables.isEmpty, let name = extractDeclarationName(from: trimmed) {
                for rule in openDisables {
                    suppressions.insert(Suppression(symbolName: name, rule: rule))
                }
            }

            // Check for trailing inline annotation on the same line as a declaration
            if let name = extractDeclarationName(from: trimmed),
               let (action, rule) = parseTrailingAnnotation(from: trimmed),
               action == .disable || action == .disableNext {
                suppressions.insert(Suppression(symbolName: name, rule: rule))
            }

            i += 1
        }

        return suppressions
    }

    // MARK: - Regex helpers

    private enum AnnotationAction { case disable, disableNext, enable }

    /// Matches full-line `// adar_disable <rule>`, `// adar_disable:next <rule>`, or `// adar_enable <rule>`.
    private static func parseAnnotation(from line: String) -> (AnnotationAction, RuleName)? {
        let pattern = #"^\s*//\s*adar_(disable(?::next)?|enable)\s+(\w+)"#
        return matchAnnotation(pattern: pattern, in: line)
    }

    /// Matches trailing `// adar_disable <rule>` or `// adar_disable:next <rule>` appended after code.
    private static func parseTrailingAnnotation(from line: String) -> (AnnotationAction, RuleName)? {
        let pattern = #"//\s*adar_(disable(?::next)?|enable)\s+(\w+)"#
        return matchAnnotation(pattern: pattern, in: line)
    }

    private static func matchAnnotation(pattern: String, in line: String) -> (AnnotationAction, RuleName)? {
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
            let actionRange = Range(match.range(at: 1), in: line),
            let ruleRange  = Range(match.range(at: 2), in: line)
        else { return nil }

        let actionStr = String(line[actionRange])
        let ruleStr   = String(line[ruleRange])

        guard let rule = RuleName(rawValue: ruleStr) else { return nil }
        let action: AnnotationAction
        switch actionStr {
        case "disable":       action = .disable
        case "disable:next":  action = .disableNext
        default:              action = .enable
        }
        return (action, rule)
    }

    /// Extracts the declared symbol name from a Swift declaration line.
    private static func extractDeclarationName(from line: String) -> String? {
        let pattern = #"(?:class|struct|enum|protocol|actor|func|var|let|typealias|extension)\s+(\w+)"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
            let range = Range(match.range(at: 1), in: line)
        else { return nil }
        return String(line[range])
    }

    /// Scans forward from `lineIndex` to find the first non-blank line with a declaration.
    private static func nextDeclarationName(after lineIndex: Int, in lines: [String]) -> String? {
        let lookahead = 2 // lines to look ahead
        for j in (lineIndex + 1)..<min(lineIndex + 1 + lookahead, lines.count) {
            let trimmed = lines[j].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if let name = extractDeclarationName(from: trimmed) { return name }
            break // non-blank, non-declaration line → stop
        }
        return nil
    }

    // MARK: - File enumeration

    private static func collectSwiftFiles(in dir: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return enumerator
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
    }
}
