//
//  Edge.swift
//  Graph
//
//  Created by Andrew McKnight on 5/8/16.
//

import Foundation

public struct Edge<T, U>: Equatable where T: Hashable, U: Hashable & OptionSet {

    public let from: Vertex<T>
    public let to: Vertex<T>
    public let weight: Double?
    public let userInfo: U?

    public init(from: Vertex<T>, to: Vertex<T>, weight: Double?, userInfo: U? = nil) {
        self.from = from
        self.to = to
        self.weight = weight
        self.userInfo  = userInfo
    }
    
}

extension Edge: CustomStringConvertible {
    
    public var description: String {
        guard let unwrappedWeight = weight else {
            return "\(from.description) -> \(to.description)"
        }
        return "\(from.description) -(\(unwrappedWeight))-> \(to.description)"
    }
    
}

extension Edge: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(to)
        if weight != nil {
            hasher.combine(weight)
        }
        if userInfo != nil {
            hasher.combine(userInfo)
        }
    }
    
}

public func == <T, U>(lhs: Edge<T, U>, rhs: Edge<T, U>) -> Bool {
    guard lhs.from == rhs.from else {
        return false
    }
    
    guard lhs.to == rhs.to else {
        return false
    }
    
    guard lhs.weight == rhs.weight else {
        return false
    }

    guard lhs.userInfo == rhs.userInfo else {
        return false
    }

    return true
}
