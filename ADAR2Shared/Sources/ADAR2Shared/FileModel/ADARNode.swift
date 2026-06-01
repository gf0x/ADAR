import Foundation
import simd

// MARK: - ADARNode
public struct ADARNode: Equatable, Hashable {

    public let declaration: Declaration
    public let position: SIMD3<Float>

    public init(declaration: Declaration, position: SIMD3<Float>) {
        self.declaration = declaration
        self.position = position
    }
}

// MARK: - Codable
// Manual implementation to encode position as {x,y,z} keys (matching .adar file format)
// instead of Swift's built-in SIMD array encoding.
extension ADARNode: Codable {

    private enum CodingKeys: String, CodingKey { case declaration, position }
    private enum PositionKeys: String, CodingKey { case x, y, z }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        declaration = try c.decode(Declaration.self, forKey: .declaration)
        let p = try c.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        position = SIMD3<Float>(
            try p.decode(Float.self, forKey: .x),
            try p.decode(Float.self, forKey: .y),
            try p.decode(Float.self, forKey: .z)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(declaration, forKey: .declaration)
        var p = c.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        try p.encode(position.x, forKey: .x)
        try p.encode(position.y, forKey: .y)
        try p.encode(position.z, forKey: .z)
    }
}

// MARK: ADARNode + Identifiable
extension ADARNode: Identifiable {
    public var id: String { self.declaration.id }
}

// MARK: - Declaration
extension ADARNode {

    public struct Declaration: Codable, Equatable, Identifiable, Hashable, CustomStringConvertible {

        public let id: String
        public let displayName: String
        public let kind: DeclarationKind
        /// Absolute path to the Swift source file that defines this symbol.
        /// Populated by ADAR2ModelBuilder from the symbol graph; `nil` for synthesized symbols.
        public let sourceFile: String?
        /// 1-indexed line number in `sourceFile` where this symbol is declared.
        public let sourceLine: Int?

        public init(id: String, displayName: String, kind: DeclarationKind, sourceFile: String? = nil, sourceLine: Int? = nil) {
            self.id = id
            self.displayName = displayName
            self.kind = kind
            self.sourceFile = sourceFile
            self.sourceLine = sourceLine
        }

        public var description: String {
            self.displayName + "(\(self.kind.rawValue))"
        }
    }
}

// MARK: - DeclarationKind
extension ADARNode.Declaration {

    public enum DeclarationKind: String, Codable {
        case data_type, property, method
    }
}
