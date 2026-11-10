import Foundation

public enum Tools {
    public static func find(_ name: String) -> URL? {
        let bundled = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/\(name)")
        var paths = [bundled.path, "/opt/homebrew/bin/\(name)", "/usr/local/bin/\(name)"]
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            paths += path.split(separator: ":").map { "\($0)/\(name)" }
        }
        return paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
            .map(URL.init(fileURLWithPath:))
    }
}

public enum ProcessRunner {
    public static func run(_ executable: URL, _ arguments: [String], timeout: TimeInterval = 300,
                           progressFile: URL? = nil,
                           onProgress: (@Sendable (String) -> Void)? = nil) async throws -> Data {
        let process = Process()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("transcodepilot-process-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let outputURL = folder.appendingPathComponent("stdout")
        let errorURL = folder.appendingPathComponent("stderr")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        FileManager.default.createFile(atPath: errorURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        let errors = try FileHandle(forWritingTo: errorURL)
        defer { try? output.close(); try? errors.close() }
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = errors
        process.standardInput = FileHandle.nullDevice
        try Task.checkCancellation()
        try process.run()
        let deadline = Date().addingTimeInterval(timeout)
        do {
            while process.isRunning {
                try Task.checkCancellation()
                if Date() > deadline { throw ConversionError.code(.timeout, detail: "Conversion timed out.") }
                if let progressFile, let onProgress,
                   let text = try? String(contentsOf: progressFile, encoding: .utf8) {
                    onProgress(text)
                }
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        } catch {
            // This task is already cancelled on the cancellation path, where
            // Task.sleep throws immediately. Give the child a bounded grace
            // period; never block the cooperative executor indefinitely on an
            // unresponsive engine.
            if process.isRunning { process.terminate() }
            let graceDeadline = Date().addingTimeInterval(1)
            while process.isRunning && Date() < graceDeadline { usleep(20_000) }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            let forceDeadline = Date().addingTimeInterval(1)
            while process.isRunning && Date() < forceDeadline { usleep(10_000) }
            throw error
        }
        if let progressFile, let onProgress,
           let text = try? String(contentsOf: progressFile, encoding: .utf8) {
            onProgress(text)
        }
        guard process.terminationStatus == 0 else {
            let handle = try FileHandle(forReadingFrom: errorURL)
            defer { try? handle.close() }
            let detail = String(data: try handle.read(upToCount: 4096) ?? Data(), encoding: .utf8) ?? ""
            throw ConversionError.code(.engineFailure, detail: detail.isEmpty ? "Conversion engine failed." : detail)
        }
        return try Data(contentsOf: outputURL)
    }
}
