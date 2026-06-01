import Foundation

// MARK: - ADARConnection
public struct ADARConnection: Codable, Hashable, Equatable {
    public var sourceId: String?
    public let targetId: String
    public let kind: Kind
    public let weight: Double?

    /// Non-failable init for use when kind is guaranteed non-nil.
    public init(sourceId: String? = nil, targetId: String, kind: Kind, weight: Double? = nil) {
        self.sourceId = sourceId
        self.targetId = targetId
        self.kind = kind
        self.weight = weight
    }

    /// Failable convenience init for callers that may have an optional kind (e.g. the Swift analyser).
    public init?(sourceId: String? = nil, targetId: String, kind: Kind?, weight: Double? = nil) {
        guard let kind else { return nil }
        self.init(sourceId: sourceId, targetId: targetId, kind: kind, weight: weight)
    }
}

// MARK: - ADARConnection.Kind
@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSet<RawType>() =
        #externalMacro(module: "SwiftMacros", type: "OptionSetMacro")

extension ADARConnection {

    @OptionSet<Int>
    public struct Kind {

        private enum Options: Int {
            case methodOf
            case propertyOf
            case isOfTypeOf
            case inherits

            case methodUsesProperty
            case methodUsesMethod
            case methodUsesInit
            case methodUsesTypePropertyOrMethod

            case methodUsesTypeInParams
            case methodUsesTypeAsReturnType
        }

        // MARK: - Computed
        public var isDeclaration: Bool {
            [.methodOf, .propertyOf, .isOfTypeOf, .inherits].contains(self)
        }

        public var isUsageKind: Bool {
            !self.isDeclaration
        }
    }
}

extension ADARConnection.Kind: Codable, Hashable {}
