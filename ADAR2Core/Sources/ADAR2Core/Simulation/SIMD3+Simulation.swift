import simd

/// Helpers that let the force-directed simulation mix Double physics values
/// with SIMD3<Float> position/velocity vectors without boilerplate casts.
extension SIMD3 where Scalar == Float {

    /// Euclidean length as Double, matching the simulation's Double arithmetic.
    public func length() -> Double { Double(simd_length(self)) }

    public static func * (lhs: SIMD3<Float>, rhs: Double) -> SIMD3<Float> {
        lhs * Float(rhs)
    }

    public static func / (lhs: SIMD3<Float>, rhs: Double) -> SIMD3<Float> {
        lhs / Float(rhs)
    }
}
