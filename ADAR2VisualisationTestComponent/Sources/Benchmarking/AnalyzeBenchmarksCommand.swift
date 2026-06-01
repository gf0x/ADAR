//
//  AnalyzeBenchmarksCommand.swift
//  ADAR2VisualisationTestComponent
//
//  Created by Alex Frankiv on 04.11.2024.
//

import Foundation
import ArgumentParser
import ADAR2Core
import ADAR2Shared

import ADAR2NaiveForceDirectedVisualizer
import ADAR2AdvancedForceDirectedVisualizer
import ADAR2MLVisualizer

struct AnalyzeBenchmarksCommand: ParsableCommand {

    // MARK: - Command
    static let configuration = CommandConfiguration(
        commandName: "analyze-benchmark",
        abstract: "Analyze the benchmarks for the visualization of ADAR2 visualizations",
        discussion: "analyze-benchmark <source-file> <destination-file>",
        version: "1.0.0"
    )

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the file containing the visualisations benchmarks", completion: .file(extensions: ["json"])
    )
    var sourceFile: String

    @Option(
        name: .shortAndLong,
        help: "The ABSOLUTE path to the file where the report should be located"
    )
    var destinationFile: String

    // MARK: - Run
    func run() throws {
        let contents = try Data(contentsOf: URL(fileURLWithPath: self.sourceFile))
        let benchmarks = try JSONDecoder().decode([BenchmarkItem].self, from: contents)

        print(benchmarks)

        try Exporter.exportToCSV(objects: benchmarks, filename: self.destinationFile)
    }
}

private struct Exporter {
  static func exportToCSV<T: Codable>(objects: [T], filename: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys // Ensures consistent key ordering

    // Get headers from the first object in the array, including nested keys
    guard let firstObject = objects.first else {
      throw NSError(domain: "Exporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty array of objects"])
    }

    let headers = try getHeaders(for: firstObject)

    // Build the CSV string
    var csvString = headers.joined(separator: ",") + "\n"

    for object in objects {
      let rowDict = try flatten(object)
      let rowValues = headers.map { header in
        return rowDict[header] ?? ""
      }
      csvString += rowValues.joined(separator: ",") + "\n"
    }

    // Save to file
    let url = URL(fileURLWithPath: filename)
    try csvString.write(to: url, atomically: true, encoding: .utf8)
    print("CSV file saved at \(url.path)")
  }

  // Helper to recursively flatten objects into a dictionary with keys as "nested.key"
  private static func flatten<T: Codable>(_ object: T) throws -> [String: String] {
    let encoder = JSONEncoder()
    let data = try encoder.encode(object)
    guard let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw NSError(domain: "Exporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
    }
    return flattenDictionary(jsonDict)
  }

  private static func flattenDictionary(_ dictionary: [String: Any], prefix: String = "") -> [String: String] {
    var flatDict = [String: String]()

    for (key, value) in dictionary {
      let newKey = prefix.isEmpty ? key : "\(prefix).\(key)"
      if let nestedDict = value as? [String: Any] {
        let nestedFlatDict = flattenDictionary(nestedDict, prefix: newKey)
        flatDict.merge(nestedFlatDict) { current, _ in current }
      } else {
        flatDict[newKey] = String(describing: value)
      }
    }
    return flatDict
  }

  // Helper to extract headers by flattening the first object
  private static func getHeaders<T: Codable>(for object: T) throws -> [String] {
    let flattenedDict = try flatten(object)
    return Array(flattenedDict.keys).sorted()
  }
}
