import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ImageIO
import TranscodePilotCore

struct MainView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            if model.items.isEmpty {
                VStack(spacing: Design.Spacing.lg) {
                    if let icon = emptyStateIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 76, height: 76)
                            .accessibilityHidden(true)
                    }
                    Text(L("Drop files here")).font(.title2.weight(.medium))
                    Text("SVG · PNG · JPEG · HEIC · MP4 · MKV").font(.callout.monospaced()).foregroundStyle(.secondary)
                    Text(L("Files stay on this Mac. Sources and existing outputs are never overwritten."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                    Button(L("Choose files")) { model.chooseFiles() }
                        .buttonStyle(.borderedProminent)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    VStack(spacing: 0) {
                        List(selection: $model.selection) {
                            ForEach(model.items) { item in
                                HStack(spacing: 10) {
                                    if let thumbnail = model.thumbnails[item.id] {
                                        Image(nsImage: thumbnail)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .accessibilityHidden(true)
                                    } else {
                                        Image(systemName: item.options.format == .mp3 ? "film" : "photo")
                                            .font(.title3).foregroundStyle(.secondary).frame(width: 25)
                                    }
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.source.lastPathComponent).lineLimit(1).fontWeight(.medium)
                                        Text(item.source.pathExtension.uppercased() + " → " + item.options.format.rawValue.uppercased())
                                            .font(.caption.monospaced()).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let validation = item.validationError {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                            .help(validation)
                                    } else if item.status == "Converting" {
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text("\(progressPercent(item.progress))%")
                                                .font(.caption2.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                            ProgressView(value: min(max(item.progress, 0), 1))
                                                .frame(width: 72)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel(L("Converting") + " \(progressPercent(item.progress))%")
                                    }
                                    else { Text(L(item.status)).font(.caption).foregroundStyle(statusColor(item.status)) }
                                }
                                .padding(.vertical, 8)
                                .tag(item.id)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(item.source.lastPathComponent), \(L(item.status))")
                            }
                        }.listStyle(.inset)
                        HStack(spacing: Design.Spacing.xs) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.items.count == 1 ? "1 " + L("file") : "\(model.items.count) " + L("files")).font(.caption).foregroundStyle(.secondary)
                                Text("\(model.completedCount) " + L("Done") + " · \(model.failedCount) " + L("Failed") + " · \(model.pendingCount) " + L("Pending"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button { model.removeSelected() } label: { Image(systemName: "minus") }
                                .disabled(model.running || model.selection == nil)
                                .help(L("Remove"))
                                .accessibilityLabel(L("Remove"))
                            Menu {
                                Button(L("Clear Completed")) { model.clearCompleted() }
                                    .disabled(model.running || model.completedCount == 0)
                                Button(L("Clear All")) { model.clearAll() }
                                    .disabled(model.running || model.items.isEmpty)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                            .help(L("Queue actions"))
                            .accessibilityLabel(L("Queue actions"))
                        }.padding(12)
                    }.frame(minWidth: 290, idealWidth: 350)
                    if let index = model.selectedIndex {
                        inspector(model.items[index]).frame(minWidth: 320, idealWidth: 360)
                    } else {
                        Text(L("Select a file")).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            Divider()
            HStack(spacing: Design.Spacing.sm) {
                if let folder = model.outputFolder {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(folder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(folder.path)
                } else {
                    Text(L("Choose output folder")).font(.caption).foregroundStyle(.secondary)
                }
                if let engineWarning = model.engineWarning {
                    Label(engineWarning, systemImage: "exclamationmark.triangle")
                        .accessibilityLabel(engineWarning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .help(engineWarning)
                }
                Spacer()
                if model.running {
                    if let active = model.activeItem {
                        VStack(alignment: .trailing, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(phaseLabel(active.progressPhase)).font(.caption2).foregroundStyle(.secondary)
                                Text("\(progressPercent(active.progress))%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: min(max(active.progress, 0), 1))
                                .frame(width: 180)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(L("Converting") + " \(progressPercent(active.progress))%")
                    }
                    Button(L("Cancel")) { model.cancel() }.keyboardShortcut(.cancelAction)
                } else {
                    Button(L(model.items.contains { $0.status == "Failed" || $0.status == "Cancelled" } ? "Retry remaining" : "Convert")) { model.start() }
                        .buttonStyle(.borderedProminent).keyboardShortcut(.return, modifiers: .command)
                        .disabled(!model.canStart)
                }
            }.padding(Design.Spacing.md)
        }
        .frame(minWidth: 760, minHeight: 540)
        .background(model.targeted ? Design.Palette.accent.opacity(0.08) : Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $model.targeted) { providers in
            let collector = DropCollector(count: providers.count)
            for (index, provider) in providers.enumerated() {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    collector.complete(index: index, url: url)
                }
            }
            collector.group.notify(queue: .main) {
                model.add(collector.urls)
            }
            return true
        }
        .alert(L("Notice"), isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button(L("OK")) { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }

    private var emptyStateIcon: NSImage? {
        AppIcon.image ?? NSApp.applicationIconImage
    }

    func setting<T>(_ item: ConversionItem, _ keyPath: WritableKeyPath<ConversionOptions, T>) -> Binding<T> {
        Binding(get: { item.options[keyPath: keyPath] }, set: { value in
            var options = item.options
            options[keyPath: keyPath] = value
            model.update(options)
        })
    }

    @ViewBuilder func inspector(_ item: ConversionItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L("SOURCE")).font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.source.lastPathComponent).font(.headline).lineLimit(2).textSelection(.enabled)
                    Text(sourceSummary(item)).font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text(L("Source is read-only; existing outputs are never overwritten."))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if let output = item.output {
                    resultCard(item, output)
                    Divider()
                }
                Text(L("OUTPUT")).font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
                Picker(L("Format"), selection: setting(item, \.format)) {
                    ForEach(Converter.formats(for: item.source)) { Text($0.rawValue.uppercased()).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(L("Format"))
                if item.options.format == .mp3 {
                    Picker(L("Audio quality"), selection: setting(item, \.audioBitrate)) {
                        Text("128 kbps").tag(128)
                        Text("192 kbps").tag(192)
                        Text("320 kbps").tag(320)
                    }
                    .accessibilityLabel(L("Audio quality"))
                    validationView(item)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("Width in pixels")).font(.callout.weight(.medium))
                        TextField("0", value: setting(item, \.width), format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(L("Width in pixels"))
                        Text(L("0 uses scale; aspect ratio is preserved.")).font(.caption).foregroundStyle(.secondary)
                        Picker(L("Scale"), selection: setting(item, \.scale)) {
                            Text("1×").tag(1.0); Text("2×").tag(2.0); Text("4×").tag(4.0)
                        }
                        .pickerStyle(.segmented)
                        .disabled(item.options.width != 0)
                        .accessibilityLabel(L("Scale"))
                    }
                    validationView(item)
                    if item.options.format == .png {
                        Toggle(L("White background"), isOn: setting(item, \.whiteBackground))
                    } else {
                        VStack(alignment: .leading) {
                            HStack { Text(L("Quality")); Spacer(); Text(qualityText(item.options.jpegQuality)).monospacedDigit() }
                            Slider(value: setting(item, \.jpegQuality), in: 0.1...1)
                            Text(L("Transparent areas become white.")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button(L("Apply to similar files")) { model.applyToSimilar() }
                Divider()
                if let error = item.error {
                    Label(L("Failed"), systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                    Text(error).font(.caption).textSelection(.enabled)
                    HStack(spacing: Design.Spacing.xs) {
                        Button(L("Retry")) { model.retrySelected() }
                        if item.failureCode == .outputNotWritable || item.failureCode == .outputVolumeUnsupported {
                            Button(L("Choose output folder")) { model.chooseFolder() }
                        }
                    }
                }
                if item.output == nil, item.options.format != .mp3 {
                    Label(L("Preview appears after conversion"), systemImage: "photo").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(24)
        }.disabled(model.running)
    }

    @ViewBuilder func resultCard(_ item: ConversionItem, _ output: URL) -> some View {
        let exists = FileManager.default.fileExists(atPath: output.path)
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            if exists {
                Label(L("Exported"), systemImage: "checkmark.circle.fill").font(.callout.weight(.medium))
            } else {
                Label(L("Output file is no longer available."), systemImage: "exclamationmark.triangle")
                    .font(.callout.weight(.medium)).foregroundStyle(.orange)
            }
            if exists, item.options.format != .mp3, let image = ThumbnailLoader.load(output, maxPixelSize: 512) {
                ZStack {
                    PreviewCheckerboard()
                    Image(nsImage: image).resizable().scaledToFit().padding(8)
                        .accessibilityLabel(L("Output preview"))
                }
                .frame(maxWidth: .infinity, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2)))
            }
            Text(output.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                .font(.caption.monospaced()).textSelection(.enabled).lineLimit(2)
            if exists, let source = CGImageSourceCreateWithURL(output as CFURL, nil),
               let info = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
               let width = info[kCGImagePropertyPixelWidth] as? Int,
               let height = info[kCGImagePropertyPixelHeight] as? Int {
                Text("\(width) × \(height) px").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            if exists, let size = (try? FileManager.default.attributesOfItem(atPath: output.path))?[.size] as? NSNumber {
                Text(ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file))
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            HStack {
                if exists {
                    Button(L("Show in Finder")) { NSWorkspace.shared.activateFileViewerSelecting([output]) }
                    Button(L("Open")) { NSWorkspace.shared.open(output) }
                }
                Button(L("Convert again")) { model.reconvertSelected() }
            }
        }
    }

    func sourceSummary(_ item: ConversionItem) -> String {
        let ext = item.source.pathExtension.uppercased()
        switch item.metadata?.dimensions {
        case .pixels(let width, let height):
            return "\(ext) · \(width) × \(height) px"
        case .svg(let width, let height):
            return "\(ext) · \(Int(width)) × \(Int(height))"
        case .unknown, .none:
            if item.metadata?.kind == .video, let duration = model.durations[item.id] {
                return "\(ext) · \(formatDuration(duration)) → MP3"
            }
            return item.options.format == .mp3 ? "\(ext) → MP3" : ext
        }
    }

    func progressPercent(_ value: Double) -> Int {
        Int((min(max(value, 0), 1) * 100).rounded())
    }

    func phaseLabel(_ phase: ConversionPhase?) -> String {
        switch phase {
        case .preparing: return L("Preparing")
        case .reading: return L("Reading media")
        case .rendering: return L("Rendering SVG")
        case .decoding: return L("Decoding image")
        case .encoding: return L("Encoding")
        case .verifying: return L("Verifying output")
        case .publishing: return L("Publishing")
        case .none: return L("Converting")
        }
    }

    func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return total >= 3600 ? String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
                             : String(format: "%d:%02d", total / 60, total % 60)
    }

    func statusColor(_ status: String) -> Color {
        switch status { case "Failed": return .red; case "Done": return .blue; case "Cancelled": return .orange; default: return .secondary }
    }

    func qualityText(_ value: Double) -> String {
        let safe = value.isFinite ? min(max(value, 0), 1) : 0.9
        return "\(Int((safe * 100).rounded()))%"
    }

    @ViewBuilder func validationView(_ item: ConversionItem) -> some View {
        if let validation = item.validationError {
            Label(validation, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
        } else if item.options.format != .mp3, let estimate = item.estimate {
            HStack {
                Text(L("Estimated output"))
                Spacer()
                Text("\(estimate.width) × \(estimate.height) px").monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}


/// Collects asynchronous drop providers in their original order.
private final class DropCollector: @unchecked Sendable {
    let group = DispatchGroup()
    private let lock = NSLock()
    private var collected: [URL?]

    init(count: Int) {
        collected = Array(repeating: nil, count: count)
        for _ in 0..<count { group.enter() }
    }

    func complete(index: Int, url: URL?) {
        lock.lock()
        collected[index] = url
        lock.unlock()
        group.leave()
    }

    var urls: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return collected.compactMap { $0 }
    }
}


/// Neutral checkerboard so transparent PNG content is distinguishable from the
/// surrounding window background in both light and dark appearances.
private struct PreviewCheckerboard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let square: CGFloat = 10
            let light = colorScheme == .light ? Color(white: 1) : Color(white: 0.18)
            let dark = colorScheme == .light ? Color(white: 0.88) : Color(white: 0.26)
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                var column = 0
                var x: CGFloat = 0
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: square, height: square)
                    context.fill(Path(rect), with: .color((row + column).isMultiple(of: 2) ? light : dark))
                    x += square
                    column += 1
                }
                y += square
                row += 1
            }
        }
    }
}
