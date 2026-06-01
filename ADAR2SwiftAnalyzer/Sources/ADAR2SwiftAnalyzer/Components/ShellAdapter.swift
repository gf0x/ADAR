//
//  ShellAdapter.swift
//
//
//  Created by Alex Frankiv on 17.01.2024.
//

import Foundation

final class ShellAdapter {

    struct ShellCommand {
        enum ExecEnv: String {
            case zsh = "/bin/zsh"
        }

        let command: String
        let env: ExecEnv
    }

    @discardableResult
    func execute(shellCommand: ShellCommand, at path: URL) -> (output: [String], error: [String], status: Int32) {
        let task = Process()
        task.arguments = ["-c", shellCommand.command]

        let outpipe = Pipe()
        task.standardOutput = outpipe

        let errpipe = Pipe()
        task.standardError = errpipe

        if #available(macOS 10.13, *) {
            task.executableURL = URL(fileURLWithPath: shellCommand.env.rawValue)
            task.currentDirectoryURL = path
            do {
                try task.run()
            } catch {
                fatalError("SEVERE: internal error with process launching: \(shellCommand); error: \(error.localizedDescription)")
            }
        } else {
            task.launchPath = shellCommand.env.rawValue
            task.launch()
        }

        // Read stdout and stderr concurrently to prevent deadlock when the subprocess
        // writes more to one stream than the pipe buffer (~64 KB) can hold while we are
        // blocked reading the other. This matters for heavy commands like `swift build`
        // which stream large volumes of progress text to stderr.
        var stdoutData = Data()
        var stderrData = Data()
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            stdoutData = outpipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            stderrData = errpipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        task.waitUntilExit()
        group.wait()

        try? outpipe.fileHandleForWriting.close()
        try? outpipe.fileHandleForReading.close()
        try? errpipe.fileHandleForWriting.close()
        try? errpipe.fileHandleForReading.close()

        let output = String(decoding: stdoutData, as: UTF8.self)
            .split(separator: "\n").map { String($0) }
        let error = String(decoding: stderrData, as: UTF8.self)
            .split(separator: "\n").map { String($0) }

        return (output: output, error: error, status: task.terminationStatus)
    }
}
