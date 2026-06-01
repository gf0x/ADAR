//
//  ADARNodeDeclarationKind+SymbolKind.swift
//
//
//  Created by Alex Frankiv on 30.01.2024.
//

import Foundation
import ADAR2Shared
import SymbolKit

extension ADARNode.Declaration.DeclarationKind {

    init?(from symbolKind: SymbolGraph.Symbol.KindIdentifier) {
        switch symbolKind {
        case .class, .struct, .enum: self = .data_type
        case .property, .typeProperty: self = .property
        case .method, .typeMethod,
                .subscript, .typeSubscript,
                .operator,
                .`init`, .deinit: self = .method

        default: return nil
        }
    }
}

extension SymbolGraph.Symbol.KindIdentifier {

    var adarKind: ADARNode.Declaration.DeclarationKind? {
        .init(from: self)
    }
}

extension SymbolGraph.Symbol.Kind {

    var adarKind: ADARNode.Declaration.DeclarationKind? {
        self.identifier.adarKind
    }
}
