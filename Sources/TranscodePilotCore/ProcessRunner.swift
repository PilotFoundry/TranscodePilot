import Foundation

public enum Tools {
    public static func find(_ name: String) -> URL? {
        let bundled = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/\(name)")
        let paths = [bundled.path, "/opt/homebrew/bin/\(name)", "/usr/local/bin/\(name)"]
        return paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }).map(URL.init(fileURLWithPath:))
    }
}

public enum ProcessRunner {
    public static func run(_ executable: URL, _ arguments: [String], timeout: TimeInterval = 300) async throws -> Data {
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
                if Date() > deadline { throw ConversionError.message("Conversion timed out.") }
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        } catch {
            if process.isRunning { process.interrupt() }
            // This task is already cancelled on the cancellation path, where
            // Task.sleep throws immediately. Give the child a real grace period
            // with a wait that is not tied to this task's cancellation.
            let deadline = Date().addingTimeInterval(1)
            while process.isRunning && Date() < deadline {
                if Task.isCancelled { usleep(20_000) }
                else { try? await Task.sleep(nanoseconds: 20_000_000) }
            }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()
            throw error
        }
        guard process.terminationStatus == 0 else {
            let handle = try FileHandle(forReadingFrom: errorURL)
            defer { try? handle.close() }
            let detail = String(data: try handle.read(upToCount: 4096) ?? Data(), encoding: .utf8) ?? ""
            throw ConversionError.message(detail.isEmpty ? "Conversion engine failed." : detail)
        }
        return try Data(contentsOf: outputURL)
    }
}
