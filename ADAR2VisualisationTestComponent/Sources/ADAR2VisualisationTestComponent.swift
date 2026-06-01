// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import os.log

let logger = Logger(subsystem: "ua.edu.ukma.adar.ADAR2VisualisationTestComponent", category: "general")

@main
struct ADAR2VisualisationTestComponent: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: nil,
        abstract: "This command is a stub. Nothing should be done.",
        version: "1.0.0",
        subcommands: [PrepareVisualsCommand.self, PerformBenchmarkingCommand.self, AnalyzeBenchmarksCommand.self]
    )

    mutating func run() throws {
        print("This is the stub command. Nothing should be done. \nExiting...")
    }
}
