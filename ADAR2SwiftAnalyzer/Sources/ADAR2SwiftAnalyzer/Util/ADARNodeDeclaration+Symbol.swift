//
//  ADARNodeDeclaration+Symbol.swift
//
//
//  Created by Alex Frankiv on 30.01.2024.
//

import Foundation

import ADAR2Shared
import SymbolKit

private let swiftuiViewSynthesizedMethodRegex = try! Regex("s:7SwiftUI4View.*::SYNTHESIZED::.*")

extension ADARNode.Declaration {

    init?(from symbol: SymbolGraph.Symbol) {
        guard
            // ignore SwiftUI synthesized View method implementations
            try! swiftuiViewSynthesizedMethodRegex.firstMatch(in: symbol.identifier.precise) == nil,
            let kind = symbol.kind.adarKind
        else { return nil }

        let location = symbol.mixins["location"] as? SymbolGraph.Symbol.Location
        let sourceFile = location.flatMap { URL(string: $0.uri)?.path }
        let sourceLine = location.map { $0.position.line + 1 } // symbol graph uses 0-indexed lines

        self.init(
            id: symbol.identifier.precise,
            displayName: symbol.names.title,
            kind: kind,
            sourceFile: sourceFile,
            sourceLine: sourceLine
        )
    }
}
