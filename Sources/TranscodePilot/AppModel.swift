import AppKit
import SwiftUI
import UniformTypeIdentifiers
import TranscodePilotCore

func L(_ key: String) -> String {
    let packaged = Bundle.main.resourceURL!
    let root = FileManager.default.fileExists(atPath: packaged.appendingPathComponent("en.lproj").path)
        ? packaged : Bundle.module.url(forResource: "Resources", withExtension: nil)!
    let language = Bundle.preferredLocalizations(from: ["en", "zh-Hans", "zh-Hant", "ja"]).first ?? "en"
    let bundle = Bundle(url: root.appendingPathComponent("\(language).lproj"))
    return bundle?.localizedString(forKey: key, value: key, table: nil) ?? key
}

struct ConversionItem: Identifiable {
    let id = UUID()
    let source: URL
    var options: ConversionOptions
    var status = "Ready"
    var output: URL?
    var error: String?
}

@MainActor final class AppModel: ObservableObject {
    @Published var items: [ConversionItem] = []
    @Published var selection: UUID?
    @Published var running = false
    @Published var outputFolder: URL?
    @Published var notice: String?
    @Published var targeted = false
    private var worker: Task<Void, Never>?
    var selectedIndex: Int? { items.firstIndex(where: { $0.id == selection }) }

    init() {
        if let path = UserDefaults.standard.string(forKey: "outputFolder"), FileManager.default.fileExists(atPath: path) {
            outputFolder = URL(fileURLWithPath: path)
        }
    }

    func add(_ urls: [URL]) {
        var rejected: [String] = []
        for url in urls {
            let formats = Converter.formats(for: url)
            guard !formats.isEmpty else { rejected.append(url.lastPathComponent); continue }
            guard !items.contains(where: { $0.source == url }) else { continue }
            var options = ConversionOptions()
            options.format = formats[0]
            let defaults = UserDefaults.standard
            if let saved = defaults.string(forKey: "imageFormat"), let format = OutputFormat(rawValue: saved), formats.contains(format) { options.format = format }
            options.scale = defaults.object(forKey: "scale") as? Double ?? 2
            options.jpegQuality = defaults.object(forKey: "quality") as? Double ?? 0.9
            options.whiteBackground = defaults.bool(forKey: "whiteBackground")
            options.audioBitrate = defaults.object(forKey: "bitrate") as? Int ?? 192
            let item = ConversionItem(source: url, options: options)
            items.append(item)
            selection = item.id
        }
        if !rejected.isEmpty { notice = L("Unsupported files") + ": " + rejected.joined(separator: ", ") }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = ["svg", "png", "jpg", "jpeg", "heic", "mp4"].compactMap { UTType(filenameExtension: $0) }
        if panel.runModal() == .OK { add(panel.urls) }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = L("Choose folder")
        if panel.runModal() == .OK, let url = panel.url {
            outputFolder = url
            UserDefaults.standard.set(url.path, forKey: "outputFolder")
        }
    }

    func update(_ options: ConversionOptions) {
        guard !running, let index = selectedIndex else { return }
        items[index].options = options
        items[index].output = nil
        items[index].error = nil
        items[index].status = "Ready"
        let defaults = UserDefaults.standard
        if options.format != .mp3 { defaults.set(options.format.rawValue, forKey: "imageFormat") }
        defaults.set(options.scale, forKey: "scale")
        defaults.set(options.jpegQuality, forKey: "quality")
        defaults.set(options.whiteBackground, forKey: "whiteBackground")
        defaults.set(options.audioBitrate, forKey: "bitrate")
    }

    func applyToSimilar() {
        guard let index = selectedIndex, !running else { return }
        let options = items[index].options
        for i in items.indices where Converter.formats(for: items[i].source).contains(options.format) {
            items[i].options = options
            items[i].status = "Ready"
            items[i].output = nil
            items[i].error = nil
        }
    }

    func start() {
        guard !running else { return }
        if outputFolder == nil { chooseFolder() }
        guard let directory = outputFolder else { return }
        let jobs = items.filter { $0.status != "Done" }
        guard !jobs.isEmpty else { return }
        running = true
        worker = Task {
            for job in jobs {
                if Task.isCancelled { break }
                guard let index = items.firstIndex(where: { $0.id == job.id }) else { continue }
                items[index].status = "Converting"
                items[index].error = nil
                do {
                    let result = try await Task.detached { try await Converter.convert(job.source, to: directory, options: job.options) }.valueWithCancellation()
                    items[index].output = result
                    items[index].status = "Done"
                } catch is CancellationError {
                    items[index].status = "Cancelled"
                    break
                } catch {
                    items[index].status = "Failed"
                    items[index].error = error.localizedDescription
                }
            }
            running = false
            worker = nil
        }
    }

    func cancel() { worker?.cancel() }
    func removeSelected() {
        guard !running else { return }
        items.removeAll { $0.id == selection }
        selection = items.first?.id
    }
}

extension Task where Failure == Error {
    func valueWithCancellation() async throws -> Success {
        try await withTaskCancellationHandler(operation: { try await value }, onCancel: { cancel() })
    }
}
