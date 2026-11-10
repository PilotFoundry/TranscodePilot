import AppKit
import SwiftUI
import UniformTypeIdentifiers
import TranscodePilotCore

func L(_ key: String) -> String {
    guard let packaged = Bundle.main.resourceURL else { return key }
    let root: URL
    if FileManager.default.fileExists(atPath: packaged.appendingPathComponent("en.lproj").path) {
        root = packaged
    } else if let module = Bundle.module.url(forResource: "Resources", withExtension: nil) {
        root = module
    } else {
        return key
    }
    let language = Bundle.preferredLocalizations(from: ["en", "zh-Hans", "zh-Hant", "ja"]).first ?? "en"
    guard let bundle = Bundle(url: root.appendingPathComponent("\(language).lproj")) else { return key }
    return bundle.localizedString(forKey: key, value: key, table: nil)
}

struct ConversionItem: Identifiable {
    let id = UUID()
    let source: URL
    var options: ConversionOptions
    var metadata: SourceMetadata?
    var status = "Ready"
    var output: URL?
    var error: String?
    var failureCode: ConversionErrorCode?
    var estimate: ConversionEstimate?
    var validationError: String?

    init(source: URL, options: ConversionOptions, metadata: SourceMetadata? = nil) {
        self.source = source
        self.options = options
        self.metadata = metadata
    }
}

@MainActor final class AppModel: ObservableObject {
    @Published var items: [ConversionItem] = []
    @Published var selection: UUID?
    @Published var running = false
    @Published var outputFolder: URL?
    @Published var notice: String?
    @Published var targeted = false
    @Published var engineWarning: String?
    @Published var thumbnails: [UUID: NSImage] = [:]
    @Published var durations: [UUID: Double] = [:]
    private var worker: Task<Void, Never>?
    var selectedIndex: Int? { items.firstIndex(where: { $0.id == selection }) }

    var canStart: Bool {
        guard !running else { return false }
        let pending = items.filter { $0.status != "Done" }
        return !pending.isEmpty && pending.allSatisfy { $0.validationError == nil }
    }

    var completedCount: Int { items.filter { $0.status == "Done" }.count }
    var failedCount: Int { items.filter { $0.status == "Failed" }.count }
    var pendingCount: Int { items.filter { $0.status != "Done" && $0.status != "Failed" }.count }

    init() {
        let missing = ["ffmpeg", "ffprobe", "rsvg-convert"].filter { Tools.find($0) == nil }
        if !missing.isEmpty {
            engineWarning = L("Some conversion engines are missing.") + " " + missing.joined(separator: ", ")
        }
        if let path = UserDefaults.standard.string(forKey: "outputFolder") {
            let url = URL(fileURLWithPath: path)
            if let values = try? url.resourceValues(forKeys: [.isDirectoryKey]), values.isDirectory == true {
                outputFolder = url
            }
        }
        _ = TemporaryCleanup.removeStaleProcessTemps()
        if let outputFolder {
            _ = TemporaryCleanup.removeStaleOutputTemps(in: outputFolder)
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
            options.scale = PreferenceDefaults.sanitizedScale(defaults.object(forKey: "scale") as? Double)
            options.jpegQuality = PreferenceDefaults.sanitizedJPEGQuality(defaults.object(forKey: "quality") as? Double)
            options.whiteBackground = defaults.bool(forKey: "whiteBackground")
            options.audioBitrate = PreferenceDefaults.sanitizedAudioBitrate(defaults.object(forKey: "bitrate") as? Int)
            var metadata: SourceMetadata?
            var inspectionError: String?
            do { metadata = try SourceInspector.inspect(url) }
            catch { inspectionError = localizedErrorText(error) }
            if let storedScale = defaults.object(forKey: "scale") as? Double {
                options.scale = PreferenceDefaults.preferredScale(storedScale, kind: metadata?.kind)
            } else {
                options.scale = PreferenceDefaults.preferredScale(nil, kind: metadata?.kind)
            }
            options.width = PreferenceDefaults.sanitizedWidth(defaults.object(forKey: "width") as? Int)
            var item = ConversionItem(source: url, options: options, metadata: metadata)
            item.validationError = inspectionError
            items.append(item)
            requestThumbnail(for: item)
            requestDuration(for: item)
            selection = item.id
            refreshValidation(at: items.count - 1)
        }
        if !rejected.isEmpty { notice = L("Unsupported files") + ": " + rejected.joined(separator: ", ") }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        var types = ["svg", "png", "jpg", "jpeg", "heic", "mp4"].compactMap { UTType(filenameExtension: $0) }
        let mkv = UTType(filenameExtension: "mkv") ?? UTType(importedAs: "org.matroska.mkv")
        types.append(mkv)
        panel.allowedContentTypes = types
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
            _ = TemporaryCleanup.removeStaleOutputTemps(in: url)
        }
    }

    func update(_ options: ConversionOptions) {
        guard !running, let index = selectedIndex else { return }
        items[index].options = options
        // Keep the previous result reachable while the next run is prepared.
        items[index].error = nil
        items[index].failureCode = nil
        items[index].status = "Ready"
        refreshValidation(at: index)
        let defaults = UserDefaults.standard
        if options.format != .mp3 { defaults.set(options.format.rawValue, forKey: "imageFormat") }
        defaults.set(options.scale, forKey: "scale")
        defaults.set(options.width, forKey: "width")
        defaults.set(options.jpegQuality, forKey: "quality")
        defaults.set(options.whiteBackground, forKey: "whiteBackground")
        defaults.set(options.audioBitrate, forKey: "bitrate")
    }

    func applyToSimilar() {
        guard let index = selectedIndex, !running else { return }
        let options = items[index].options
        for i in items.indices where Converter.formats(for: items[i].source).contains(options.format)
            && items[i].status != "Done" {
            items[i].options = options
            items[i].status = "Ready"
            items[i].output = nil
            items[i].error = nil
            refreshValidation(at: i)
        }
    }

    func start() {
        guard canStart else { return }
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
                items[index].failureCode = nil
                do {
                    let result = try await Task.detached { try await Converter.convert(job.source, to: directory, options: job.options) }.valueWithCancellation()
                    items[index].output = result
                    items[index].status = "Done"
                } catch is CancellationError {
                    items[index].status = "Cancelled"
                    break
                } catch {
                    items[index].status = "Failed"
                    items[index].error = localizedErrorText(error)
                    items[index].failureCode = (error as? ConversionError)?.errorCode
                }
            }
            running = false
            worker = nil
        }
    }

    func cancel() { worker?.cancel() }

    private func requestThumbnail(for item: ConversionItem) {
        guard item.metadata?.kind == .image, thumbnails[item.id] == nil else { return }
        let id = item.id
        let source = item.source
        Task.detached(priority: .utility) {
            let image = ThumbnailLoader.load(source, maxPixelSize: 64)
            guard let image else { return }
            await MainActor.run { [weak self] in
                self?.thumbnails[id] = image
            }
        }
    }

    private func requestDuration(for item: ConversionItem) {
        guard item.metadata?.kind == .video, durations[item.id] == nil,
              let probe = Tools.find("ffprobe") else { return }
        let id = item.id
        let source = item.source
        let demuxer = source.pathExtension.lowercased() == "mkv" ? "matroska" : "mov"
        Task {
            let arguments = ["-v", "error", "-protocol_whitelist", "file,pipe", "-f", demuxer,
                             "-show_entries", "format=duration", "-of", "csv=p=0", source.path]
            guard let data = try? await ProcessRunner.run(probe, arguments, timeout: 30),
                  let value = Double(String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)),
                  value > 0 else { return }
            self.durations[id] = value
        }
    }

    func retrySelected() {
        reconvertSelected(requireFailure: true)
    }

    func reconvertSelected(requireFailure: Bool = false) {
        guard !running, let index = selectedIndex else { return }
        if requireFailure {
            guard items[index].status == "Failed" || items[index].status == "Cancelled" else { return }
        }
        items[index].status = "Ready"
        items[index].error = nil
        items[index].failureCode = nil
        refreshValidation(at: index)
        start()
    }

    func clearCompleted() {
        guard !running else { return }
        let removed = items.filter { $0.status == "Done" }.map(\.id)
        for id in removed { thumbnails[id] = nil; durations[id] = nil }
        items.removeAll { $0.status == "Done" }
        selection = items.first?.id
    }

    func clearAll() {
        guard !running else { return }
        items.removeAll()
        thumbnails.removeAll()
        durations.removeAll()
        selection = nil
    }
    func removeSelected() {
        guard !running else { return }
        items.removeAll { $0.id == selection }
        selection = items.first?.id
    }

    private func refreshValidation(at index: Int) {
        guard items.indices.contains(index) else { return }
        guard let metadata = items[index].metadata else {
            items[index].estimate = nil
            return
        }
        guard items[index].options.format != .mp3 else {
            items[index].estimate = nil
            items[index].validationError = nil
            return
        }
        let width = items[index].options.width
        guard width >= 0, width <= 16_384 else {
            items[index].estimate = nil
            items[index].validationError = L("Width must be 0 or between 1 and 16,384 pixels.")
            return
        }
        do {
            items[index].estimate = try ConversionPlanner.estimate(metadata, options: items[index].options)
            items[index].validationError = nil
        } catch {
            items[index].estimate = nil
            items[index].validationError = localizedErrorText(error)
        }
    }
}

extension Task where Failure == Error {
    func valueWithCancellation() async throws -> Success {
        try await withTaskCancellationHandler(operation: { try await value }, onCancel: { cancel() })
    }
}
