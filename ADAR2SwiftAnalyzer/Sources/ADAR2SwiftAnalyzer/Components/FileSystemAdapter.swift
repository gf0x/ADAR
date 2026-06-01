//
//  FileSystemAdapter.swift
//
//
//  Created by Alex Frankiv on 30.01.2024.
//

import Foundation

final class FileSystemAdapter {

    func createTempDirIfNeeded(at dirURL: URL) throws {
        if !FileManager.default.fileExists(atPath: dirURL.path) {
            try FileManager.default.createDirectory(
                at: dirURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    func removeTempDirIfExists(at dirURL: URL) {
        guard FileManager.default.fileExists(atPath: dirURL.path) else { return }
        try? FileManager.default.removeItem(at: dirURL)
    }
}
