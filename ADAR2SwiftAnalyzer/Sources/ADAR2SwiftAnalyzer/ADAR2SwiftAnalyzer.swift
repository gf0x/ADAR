//
//  ADAR2SwiftAnalyzer.swift
//  ADAR_project
//
//  Created by Alex Frankiv on 10.01.2020.
//  Copyright © 2020 g_f0x. All rights reserved.
//

import Foundation
import SwiftyJSON
import ADAR2Shared
import ADAR2Core
import os.log
import SymbolKit
import SwiftSyntax
import SwiftParser

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2SwiftAnalyzer", category: "general")

// TODO: refactor to reduce number of similar blocks
final public class ADAR2SwiftAnalyzer: ADARAnalyzer {

    public typealias DataGraph = AbstractGraph<ADARNode.Declaration, ADARConnection.Kind>

    // MARK: - Const
    private enum Const {
        enum File {
            static let tempDirectoryName = ".adar_temp"
            static let symbolsDirectoryName = "\(tempDirectoryName)/symbols"
        }

        enum Graph {
            static let dataTypeMemberWeight: Double = 1 // TODO: make correct for the properties
            static let isOfTypeWeight: Double = sigmoid(1) ?? 0
            static let inheritanceWeight: Double = 10 // TODO: check if this is OK
        }
    }

    // MARK: - Properties
    private let fsAdapter = FileSystemAdapter()
    private let shellAdapter = ShellAdapter()

    // MARK: - Init
    public init() {}

    // MARK: - Methods
    public func analyze(with configuration: SystemConfiguration) -> DataGraph {

        // MARK: Prepare URLs and paths; create temp directory
        let workingDirURL = configuration.workspacePath
        let tempDirURL = workingDirURL.appendingPathComponent(Const.File.tempDirectoryName)
        let symbolDirURL = workingDirURL.appendingPathComponent(Const.File.symbolsDirectoryName)

        // MARK: Sandbox data in temp directory
        do {
            try self.fsAdapter.createTempDirIfNeeded(at: symbolDirURL)
        } catch {
            logger.error("Failed to create temporary symbol directory: \(error.localizedDescription, privacy: .public)")
            return AdjacencyListGraph()
        }
        defer { self.fsAdapter.removeTempDirIfExists(at: tempDirURL) }

        // MARK: Emit symbol graph
        let symbolGraphs = self.retreiveSymbolGraph(configuration: configuration, symbolDirURL: symbolDirURL)

        // MARK: Populate data structure
        var combinedGraph = AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>()
        for graph in symbolGraphs {
            self.dumpGraph(from: graph, into: &combinedGraph)
        }
        return combinedGraph
    }

    // MARK: - Emit graph
    private func retreiveSymbolGraph(configuration: SystemConfiguration, symbolDirURL: URL) -> [SymbolGraph] {
        let workingDirURL = configuration.workspacePath
        logger.info("Starting analysis in \(String(describing: workingDirURL.path), privacy: .public)")

        // MARK: Emit symbol graph
        let (out, err, status) = self.shellAdapter.execute(
            shellCommand: .emitSymbolGraph(configuration: configuration, symbolDirName: Const.File.symbolsDirectoryName),
            at: workingDirURL
        )
        out.forEach { logger.debug("\($0, privacy: .public)") }
        err.forEach { logger.error("\($0, privacy: .public)") }
        logger.info("Did emit symbol graph with status code: \(status, privacy: .public)")
        guard status == 0 else {
            logger.error("Failed to emit symbol graph due to xcodebuild exit code: \(status, privacy: .public)")
            exit(status)
        }

        // MARK: Read symbol graph
        var symbolGraphs: [SymbolGraph] = []
        guard let urls = try? FileManager.default.contentsOfDirectory(at: symbolDirURL, includingPropertiesForKeys: nil) else {
            logger.error("Failed to read symbol graphs at \(symbolDirURL.path, privacy: .public)")
            return []
        }
        for url in urls {
            guard
                url.lastPathComponent.hasSuffix(".symbols.json"),
                let data = try? Data(contentsOf: url),
                let symbolGraph = try? JSONDecoder().decode(SymbolGraph.self, from: data)
            else { continue }
            symbolGraphs.append(symbolGraph)
        }
        return symbolGraphs
    }

    // MARK: - Analysis
    private func dumpGraph(
        from symbolGraph: SymbolGraph,
        into dataGraph: inout AdjacencyListGraph<ADARNode.Declaration, ADARConnection.Kind>
    ) {
        // MARK: - Add vertices & edges according to kind (Using Symbol Graph from SymbolKit)
        logger.info("Adding structural connections...")
        self.dumpSymbolKitRelationsOfInterest(from: symbolGraph, into: dataGraph)

        // MARK: - Add edges according to kind (deep method analysis) (Using SwiftSyntax)
        logger.info("Adding method connections...")
        let methodSymbols = dataGraph.vertices.map(\.data) // get decarations
            .filter { $0.kind == .method } // filter only methods
            .compactMap { symbolGraph.symbols[$0.id] } // get symbols for these declarations
            // ignore synthesized symbols as we can not analyze source for them
            .filter { !$0.isVirtual && !$0.identifier.precise.contains("::SYNTHESIZED::") }

        self.dumpConnections(forSignaturesOf: methodSymbols, using: symbolGraph, into: dataGraph)

        let undefinedPathDummyKey = "undefined_path_dummy_key"
        var filesWithMethods = Dictionary(
            grouping: methodSymbols,
            by: { ($0?.mixins["location"] as? SymbolGraph.Symbol.Location)?.uri ?? undefinedPathDummyKey }
        )
            .mapValues({ methodSymbols in methodSymbols.compactMap { $0 } })

        if filesWithMethods.keys.contains(undefinedPathDummyKey) {
            logger.warning("Some method symbols are missing information about symbol location (file)")
//            assertionFailure()
            filesWithMethods.removeValue(forKey: undefinedPathDummyKey)
        }

        logger.info("Analyzing methods (bodies). Adding connections...")
        for (filePath, methodSymbols) in filesWithMethods {
            do {
                try self.dumpConnections(forBodiesOf: methodSymbols, at: filePath, using: symbolGraph, into: dataGraph)
            } catch {
                logger.warning("Failed to analyze method symbols at \(filePath, privacy: .public). Error: \(error.localizedDescription, privacy: .public)")
                assertionFailure()
            }
        }

        logger.info("Fixing weights for methods...")
        // Use sigmoid to make weight in 0...1 range
        dataGraph.mapEdges { originalEdge in
            let fixedWeight = originalEdge.userInfo?.isUsageKind == true ? sigmoid(originalEdge.weight) : originalEdge.weight
            return Edge(from: originalEdge.from, to: originalEdge.to, weight: fixedWeight, userInfo: originalEdge.userInfo)
        }

        // Make correct weights for `propertyOf`
        logger.info("Fixing weights for properties...")
        dataGraph.mapEdges { originalEdge in
            guard originalEdge.userInfo == .propertyOf else { return originalEdge }
            let totalMethods = dataGraph.edges
                .filter { $0.userInfo == .methodOf && $0.to.data.id == originalEdge.to.data.id }
                .map(\.from.data.id)
            let methodsUsingProperty = totalMethods
                .filter { m in dataGraph.edges.contains(
                    where: { $0.userInfo == .methodUsesProperty && $0.from.data.id == m && $0.to.data.id == originalEdge.to.data.id }
                ) }
            let fixedWeight = self.classToPropertyWeight(
                methodsUsingProperty: methodsUsingProperty.count,
                totalMethods: totalMethods.count
            )

            return Edge(from: originalEdge.from, to: originalEdge.to, weight: fixedWeight, userInfo: originalEdge.userInfo)
        }

        // Make correct weights for `methodOf`
        logger.info("Fixing weights for methods...")
        dataGraph.mapEdges { originalEdge in
            guard originalEdge.userInfo == .methodOf else { return originalEdge }

            let selfId = originalEdge.from.data.id
            let parentId = originalEdge.to.data.id

            let allMethodsOfParent = dataGraph.edges
                .filter { $0.userInfo == .methodOf && $0.to.data.id == parentId }
            let allMethodsOfParentIds = Set(allMethodsOfParent.map(\.from.data.id))

            let allPropertiesOfParent = dataGraph.edges
                .filter { $0.userInfo == .propertyOf && $0.to.data.id == parentId }
            let allPropertiesOfParentIds = Set(allPropertiesOfParent.map(\.from.data.id))

            let methodsUsedBySelf = dataGraph.edges
                .filter { $0.userInfo == .methodUsesMethod && $0.from.data.id == selfId && allMethodsOfParentIds.contains($0.to.data.id) }
            let propertiesUsedBySelf = dataGraph.edges
                .filter { $0.userInfo == .methodUsesProperty && $0.from.data.id == selfId && allPropertiesOfParentIds.contains($0.to.data.id) }

            let fixedWeight = Double(methodsUsedBySelf.count + propertiesUsedBySelf.count) / Double(allMethodsOfParent.count + allMethodsOfParent.count)
            return Edge(from: originalEdge.from, to: originalEdge.to, weight: sigmoid(fixedWeight), userInfo: originalEdge.userInfo)
        }

        let graphShortDescription = dataGraph.shortDescription
        logger.info("Did dump \(graphShortDescription, privacy: .public)")
    }

    private func dumpSymbolKitRelationsOfInterest(from symbolGraph: SymbolGraph, into dataGraph: DataGraph) {
        
        for relationship in symbolGraph.relationships {


            // MARK: - Inheritance relation
            if
                relationship.kind == .inheritsFrom,
                let sourceSymbol = symbolGraph.symbols[relationship.source],
                let sourceDeclaration = ADARNode.Declaration(from: sourceSymbol),

                let targetSymbol = symbolGraph.symbols[relationship.target],
                let targetDeclaration = ADARNode.Declaration(from: targetSymbol)
            {
                let sourceNode = dataGraph.createVertex(sourceDeclaration)
                let targetNode = dataGraph.createVertex(targetDeclaration)

                dataGraph.addDirectedEdge(
                    sourceNode, to: targetNode,
                    withWeight: Const.Graph.inheritanceWeight,
                    userInfo: .inherits
                )
            }

            /*
             Note: using only realtionship kind and symbols of our interest;
             - relationship kind is simply checked
             - symbols of none of our interest will not be build due to the lack of corresponding ADAR Declaration Kind
             */
            guard relationship.kind == .memberOf || relationship.kind.rawValue == "optionalMemberOf" else { continue }

            // MARK: - Method-type relation
            if
                let sourceSymbol = symbolGraph.symbols[relationship.source],
                let sourceDeclaration = ADARNode.Declaration(from: sourceSymbol),

                let targetSymbol = symbolGraph.symbols[relationship.target],
                let targetDeclaration = ADARNode.Declaration(from: targetSymbol),

                sourceDeclaration.kind == .method
            {
                let sourceNode = dataGraph.createVertex(sourceDeclaration)
                let targetNode = dataGraph.createVertex(targetDeclaration)

                dataGraph.addDirectedEdge(
                    sourceNode, to: targetNode,
                    withWeight: Const.Graph.dataTypeMemberWeight,
                    userInfo: .methodOf
                )
            }

            // MARK: - Type-property-type relation
            if
                let sourceSymbol = symbolGraph.symbols[relationship.source],
                [.property, .typeProperty].contains(sourceSymbol.kind.identifier),
                /*
                 Remove to reduce property to its type
                 */
                let propertyDeclaration = ADARNode.Declaration(from: sourceSymbol),

                let sourceTypeSymbol = symbolGraph.getTypeSymbol(of: sourceSymbol),
                let sourceTypeDeclaration = ADARNode.Declaration(from: sourceTypeSymbol),


                let targetSymbol = symbolGraph.symbols[relationship.target],
                let targetDeclaration = ADARNode.Declaration(from: targetSymbol),
                targetDeclaration.kind == .data_type,

                // ignore singletons, static self-members, etc.
                sourceTypeDeclaration.id != targetDeclaration.id
            {
                let sourceNode = dataGraph.createVertex(sourceTypeDeclaration)
                /*
                 Remove to reduce property to its type
                 */
                let propertyNode = dataGraph.createVertex(propertyDeclaration)
                let targetNode = dataGraph.createVertex(targetDeclaration)

                /*
                 To reduce property to its type change two edges
                 source -> property -> target
                 to
                 source -> target
                 */
                dataGraph.addDirectedEdge(
                    propertyNode, to: sourceNode,
                    withWeight: Const.Graph.isOfTypeWeight,
                    userInfo: .isOfTypeOf
                )

                dataGraph.addDirectedEdge(
                    propertyNode, to: targetNode,
                    withWeight: Const.Graph.dataTypeMemberWeight,
                    userInfo: .propertyOf
                )
            }
        }
    }

    private func dumpConnections(
        forSignaturesOf methods: [SymbolGraph.Symbol], using symbolGraph: SymbolGraph, into dataGraph: DataGraph
    ) {
        for method in methods {
            let funcSignatureMixinKey = SymbolGraph.Symbol.FunctionSignature.mixinKey
            guard
                let signature = (method.mixins[funcSignatureMixinKey] as? SymbolGraph.Symbol.FunctionSignature)
            else { logger.warning("No function signature of method \(method.names.title, privacy: .public)!"); continue }

            // MARK: `Method` -> `Parameter Type` connection
            for fragment in signature.parameters.flatMap(\.declarationFragments) where fragment.kind == .typeIdentifier {
                if
                    let sourceDeclaration = ADARNode.Declaration(from: method),

                    let targetPreciseId = fragment.preciseIdentifier,
                    let targetSymbol = symbolGraph.symbols[targetPreciseId],
                    let targetDeclaration = ADARNode.Declaration(from: targetSymbol)
                {
                    let sourceNode = dataGraph.createVertex(sourceDeclaration)
                    let targetNode = dataGraph.createVertex(targetDeclaration)

                    dataGraph.addDirectedEdge(
                        sourceNode, to: targetNode,
                        withWeight: 1,
                        userInfo: .methodUsesTypeInParams
                    )
                }
            }

            // MARK: `Method` -> `Return Type` connection
            for fragment in signature.returns where fragment.kind == .typeIdentifier {
                if
                    let sourceDeclaration = ADARNode.Declaration(from: method),

                    let targetPreciseId = fragment.preciseIdentifier,
                    let targetSymbol = symbolGraph.symbols[targetPreciseId],
                    let targetDeclaration = ADARNode.Declaration(from: targetSymbol)
                {
                    let sourceNode = dataGraph.createVertex(sourceDeclaration)
                    let targetNode = dataGraph.createVertex(targetDeclaration)

                    dataGraph.addDirectedEdge(
                        sourceNode, to: targetNode,
                        withWeight: 1,
                        userInfo: .methodUsesTypeAsReturnType
                    )
                }
            }
        }
    }

    private func dumpConnections(
        forBodiesOf methods: [SymbolGraph.Symbol], at filePath: String, using symbolGraph: SymbolGraph, into dataGraph: DataGraph
    ) throws {
        guard let fileURL = URL(string: filePath) else { return }
        let fileData = try Data(contentsOf: fileURL)
        guard let sourceString = String(data: fileData, encoding: .utf8) else { return }

        let sourceFileSyntax = Parser.parse(source: sourceString)

        let visitor = MethodConnectionVisitor(
            methodSelectors: methods.map(\.names.title)
        )
        visitor.walk(sourceFileSyntax)

        // Handle received results
        for (methodSelector, partialResult) in visitor.results {
            guard 
                let methodSymbol = methods.first(where: { $0.names.title == methodSelector }),
                let methodDeclaration = ADARNode.Declaration(from: methodSymbol)
            else { continue }

            // TODO: unify handling (Prioritized!)
            // Handle static method invokation results
            for possibleUsedType in partialResult[.staicPropertyInvokation] ?? [] {
                // TODO: handle possible two and more due to namespaces
                guard let targetNode = dataGraph.vertices.first(where: { $0.data.displayName == possibleUsedType })
                else { continue }

                dataGraph.addDirectedEdge(
                    dataGraph.createVertex(methodDeclaration),
                    to: targetNode,
                    withWeight: 1,
                    userInfo: .methodUsesTypePropertyOrMethod
                )
            }

            for possibleUsedType in partialResult[.instanceInit] ?? [] {
                // TODO: handle possible two and more due to namespaces
                guard let targetNode = dataGraph.vertices.first(where: { $0.data.displayName == possibleUsedType })
                else { continue }

                dataGraph.addDirectedEdge(
                    dataGraph.createVertex(methodDeclaration),
                    to: targetNode,
                    withWeight: 1,
                    userInfo: .methodUsesInit
                )
            }
        }

        // MARK: Property & Method usages from Method
        for method in methods {
            guard
                let methodSymbol = methods.first(where: { $0.names.title == method.names.title }),
                let methodDeclaration = ADARNode.Declaration(from: methodSymbol)
            else { continue }

            // MARK: Property usages
            for property in symbolGraph.symbols.values.filter({ $0.kind.adarKind == .property }) {
                guard let propertyDecl = ADARNode.Declaration(from: property) else { continue }

                let propertyUsagesVisitor = PropertyUsageFinder(method: method.names.title, property: property.names.title)
                propertyUsagesVisitor.walk(sourceFileSyntax)

                guard propertyUsagesVisitor.isPropertyUsed && propertyUsagesVisitor.insideTargetMethod else { continue }

                dataGraph.addDirectedEdge(
                    dataGraph.createVertex(methodDeclaration),
                    to: dataGraph.createVertex(propertyDecl),
                    withWeight: 1,
                    userInfo: .methodUsesProperty
                )
            }

            // MARK: Method usages
            for method in symbolGraph.symbols.values.filter({ $0.kind.adarKind == .method }) {
                guard let methodDecl = ADARNode.Declaration(from: method) else { continue }

                let methodUsagesVisitor = MethodUsageFinder(targetMethod: method.names.title)
                methodUsagesVisitor.walk(sourceFileSyntax)
                
                for methodThatCalls in methodUsagesVisitor.methodsThatUseTarget {
                    guard
                        let methodThatCallsSymbol = methods.first(where: { $0.names.title == methodThatCalls }),
                        let methodThatCallsDeclaration = ADARNode.Declaration(from: methodThatCallsSymbol)
                    else { continue }

                    dataGraph.addDirectedEdge(
                        dataGraph.createVertex(methodThatCallsDeclaration),
                        to: dataGraph.createVertex(methodDecl),
                        withWeight: 1,
                        userInfo: .methodUsesMethod
                    )
                }
            }
        }
    }

    // MARK: - Util
    func classToPropertyWeight(methodsUsingProperty: Int, totalMethods: Int) -> Double {
        guard totalMethods > 0 else { return 0 }
        let ratio = Double(methodsUsingProperty) / Double(totalMethods)
        return 1 / (1 + exp(-((ratio * 12) - 6))) // maps 0–1 range to sigmoid
    }
}

// MARK: - SymbolGraph + PropertySymbol
fileprivate extension SymbolGraph {

    func getTypeSymbol(of propertySymbol: Symbol) -> Symbol? {
        guard 
            [.property, .typeProperty].contains(propertySymbol.kind.identifier),
            let typePreciseIdentifier =
                propertySymbol.names.subHeading?.first(where: { $0.kind == .typeIdentifier })?.preciseIdentifier
        else { return nil }

        return self.symbols[typePreciseIdentifier]
    }
}

// MARK: - MethodConnectionVisitor
fileprivate class MethodConnectionVisitor: SyntaxVisitor {

    enum MethodConnectionType {
        case staicPropertyInvokation
        case instanceInit
    }

    // MARK: - Properties
    // MARK: In
    private var methodSelectors: [String]
    // MARK: Out
    private(set) var results = [String: [MethodConnectionType: [String]]]()

    // MARK: - Init
    init(methodSelectors: [String]) {
        self.methodSelectors = methodSelectors
        super.init(viewMode: .fixedUp)
    }

    // MARK: - Visit
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let nodeSelector = node.selector
        guard self.methodSelectors.contains(nodeSelector) else {
            logger.debug("Found method declaration not known as symbol")
            return .skipChildren
        }

        let staticMethodInvokationVisitor = TypeInvokationVisitor(viewMode: .fixedUp)
        staticMethodInvokationVisitor.walk(node)

        let probUsedTypes = staticMethodInvokationVisitor.probableUsedTypeNames
        results[nodeSelector] = [
            .staicPropertyInvokation: probUsedTypes.staticPropertyOrMethod,
            .instanceInit: probUsedTypes.instanceInit,
        ]

        return .skipChildren
    }
}

// MARK: - TypeInvokationVisitor
fileprivate class TypeInvokationVisitor: SyntaxVisitor {

    struct ProbableUsedTypeNames {
        var staticPropertyOrMethod = [String]()
        var instanceInit = [String]()
    }

    private(set) var probableUsedTypeNames = ProbableUsedTypeNames()

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let baseName = node.firstToken(viewMode: .fixedUp)?.text
        guard let baseName, baseName.first?.isUppercase == true else { return .skipChildren }

        let secondTokenDescription = node.tokens(viewMode: .fixedUp).map(\.description).dropFirst().first

        switch secondTokenDescription {
        case ".":
            self.probableUsedTypeNames.staticPropertyOrMethod.append(baseName)
        case "(":
            self.probableUsedTypeNames.instanceInit.append(baseName)

        default: break
        }

        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let baseName = node.firstToken(viewMode: .fixedUp)?.text
        guard let baseName, baseName.first?.isUppercase == true else { return .skipChildren }

        self.probableUsedTypeNames.staticPropertyOrMethod.append(baseName)

        return .skipChildren
    }
}

extension FunctionDeclSyntax {
    var selector: String {
        let functionName = self.name.text

        let parameterNames = self.signature.parameterClause.parameters.map { parameter -> String in
            parameter.firstName.text + ":"
        }

        return "\(functionName)(\(parameterNames.joined()))"
    }
}

// MARK: - PropertyUsage
final class PropertyUsageFinder: SyntaxVisitor {
    let targetMethod: String
    let targetProperty: String
    var isPropertyUsed = false
    var insideTargetMethod = false

    init(method: String, property: String) {
        self.targetMethod = method
        self.targetProperty = property
        super.init(viewMode: .fixedUp)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.text == targetMethod {
            insideTargetMethod = true
            return .visitChildren
        }
        return .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        insideTargetMethod = false
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if insideTargetMethod && node.declName.baseName.text == targetProperty {
            isPropertyUsed = true
        }
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if insideTargetMethod && node.baseName.text == targetProperty {
            isPropertyUsed = true
        }
        return .skipChildren
    }
}

// MARK: - MethodUsage
final class MethodUsageFinder: SyntaxVisitor {
    let targetMethod: String
    var methodsThatUseTarget: Set<String> = []
    private var currentMethod: String?

    init(targetMethod: String) {
        self.targetMethod = targetMethod
        super.init(viewMode: .fixedUp)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        currentMethod = node.name.text
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        currentMethod = nil
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let methodName = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              let currentMethod
        else {
            return .skipChildren
        }

        if methodName == targetMethod {
            methodsThatUseTarget.insert(currentMethod)
        }

        return .skipChildren
    }
}
