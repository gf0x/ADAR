import Foundation

public struct ADARBugReport: Codable {

    /// IDs of nodes identified as having anomalously high degree (hub / God objects)
    public let highDegreeNodeIds: Set<String>

    /// Membership edges (methodOf / propertyOf) with anomalously low weight (low cohesion)
    public let lowCohesionEdges: Set<ADARConnection>

    /// Edges that form directed cycles
    public let cycleEdges: Set<ADARConnection>

    /// Edges that visually cross other edges in 3D space
    public let edgesWithCrossing: Set<ADARConnection>

    public init(
        highDegreeNodeIds: Set<String>,
        lowCohesionEdges: Set<ADARConnection>,
        cycleEdges: Set<ADARConnection>,
        edgesWithCrossing: Set<ADARConnection>
    ) {
        self.highDegreeNodeIds = highDegreeNodeIds
        self.lowCohesionEdges = lowCohesionEdges
        self.cycleEdges = cycleEdges
        self.edgesWithCrossing = edgesWithCrossing
    }
}
