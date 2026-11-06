import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ImageIO
import TranscodePilotCore

struct MainView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 24)).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("TranscodePilot").font(.title3.weight(.semibold))
                    Text(L("Local media conversion")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { model.chooseFiles() } label: { Label(L("Add files"), systemImage: "plus") }
                    .keyboardShortcut("o")
            }.padding(20)
            Divider()
            if model.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down").font(.system(size: 48, weight: .ultraLight)).foregroundStyle(.orange)
                    Text(L("Drop files here")).font(.title2.weight(.medium))
                    Text("SVG · PNG · JPEG · HEIC · MP4").font(.callout.monospaced()).foregroundStyle(.secondary)
                    Button(L("Choose files")) { model.chooseFiles() }.buttonStyle(.borderedProminent).tint(.orange)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    VStack(spacing: 0) {
                        List(selection: $model.selection) {
                            ForEach(model.items) { item in
                                HStack(spacing: 10) {
                                    Image(systemName: item.options.format == .mp3 ? "film" : "photo")
                                        .font(.title3).foregroundStyle(.secondary).frame(width: 25)
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
                                    } else if item.status == "Converting" { ProgressView().controlSize(.small) }
                                    else { Text(L(item.status)).font(.caption).foregroundStyle(statusColor(item.status)) }
                                }.padding(.vertical, 8).tag(item.id)
                            }
                        }.listStyle(.inset)
                        HStack {
                            Text("\(model.items.count) " + L("files")).font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button { model.removeSelected() } label: { Image(systemName: "minus") }
                                .disabled(model.running || model.selection == nil).help(L("Remove"))
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
            HStack(spacing: 12) {
                Button { model.chooseFolder() } label: {
                    Label(model.outputFolder?.lastPathComponent ?? L("Choose output folder"), systemImage: "folder")
                        .lineLimit(1)
                }.disabled(model.running).help(model.outputFolder?.path ?? L("Choose output folder"))
                Spacer()
                if model.running {
                    Text(L("Converting")).font(.caption).foregroundStyle(.secondary)
                    Button(L("Cancel")) { model.cancel() }.keyboardShortcut(.cancelAction)
                } else {
                    Button(L(model.items.contains { $0.status == "Failed" || $0.status == "Cancelled" } ? "Retry remaining" : "Convert")) { model.start() }
                        .buttonStyle(.borderedProminent).tint(.orange).keyboardShortcut(.return, modifiers: .command)
                        .disabled(!model.canStart)
                }
            }.padding(16)
        }
        .frame(minWidth: 760, minHeight: 540)
        .background(model.targeted ? Color.orange.opacity(0.08) : Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $model.targeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url { Task { @MainActor in model.add([url]) } }
                }
            }
            return true
        }
        .alert(L("Notice"), isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button(L("OK")) { model.notice = nil }
        } message: { Text(model.notice ?? "") }
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
                Text(L("OUTPUT")).font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
                Picker(L("Format"), selection: setting(item, \.format)) {
                    ForEach(Converter.formats(for: item.source)) { Text($0.rawValue.uppercased()).tag($0) }
                }.pickerStyle(.segmented)
                if item.options.format == .mp3 {
                    Picker(L("Audio quality"), selection: setting(item, \.audioBitrate)) {
                        Text("128 kbps").tag(128)
                        Text("192 kbps").tag(192)
                        Text("320 kbps").tag(320)
                    }
                    validationView(item)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("Width in pixels")).font(.callout.weight(.medium))
                        TextField("0", value: setting(item, \.width), format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                        Text(L("0 uses scale; aspect ratio is preserved.")).font(.caption).foregroundStyle(.secondary)
                        Picker(L("Scale"), selection: setting(item, \.scale)) {
                            Text("1×").tag(1.0); Text("2×").tag(2.0); Text("4×").tag(4.0)
                        }.pickerStyle(.segmented).disabled(item.options.width != 0)
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
                }
                if let output = item.output {
                    Text(L("Exported")).font(.callout.weight(.medium))
                    if item.options.format != .mp3, let image = NSImage(contentsOf: output) {
                        Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 190)
                            .padding(12).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    }
                    Text(output.lastPathComponent).font(.caption.monospaced()).textSelection(.enabled)
                    if let source = CGImageSourceCreateWithURL(output as CFURL, nil),
                       let info = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                       let width = info[kCGImagePropertyPixelWidth] as? Int,
                       let height = info[kCGImagePropertyPixelHeight] as? Int {
                        Text("\(width) × \(height) px").font(.caption.monospaced()).foregroundStyle(.secondary)
                    }
                    HStack {
                        Button(L("Show in Finder")) { NSWorkspace.shared.activateFileViewerSelecting([output]) }
                        Button(L("Open")) { NSWorkspace.shared.open(output) }
                    }
                } else if item.options.format != .mp3 {
                    Label(L("Preview appears after conversion"), systemImage: "photo").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(24)
        }.disabled(model.running)
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
