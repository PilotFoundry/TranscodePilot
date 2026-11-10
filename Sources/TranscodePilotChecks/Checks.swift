import Foundation
import AppKit
import ImageIO
import TranscodePilotCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw ConversionError.message("FAIL: \(message)") }
}

func pixels(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ConversionError.message("Cannot decode output: \(url.lastPathComponent)")
    }
    return image
}

func rgba(_ image: CGImage, x: Int, y: Int) throws -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
        throw ConversionError.message("Cannot sample output pixel at \(x),\(y).")
    }
    return (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
}

func near(_ value: CGFloat, _ target: CGFloat, _ tolerance: CGFloat) -> Bool {
    abs(value - target) <= tolerance
}

func between(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> Bool {
    value >= low && value <= high
}

func fixtureURL(_ relativePath: String) throws -> URL {
    guard let root = Bundle.module.resourceURL else {
        throw ConversionError.message("Missing test fixture bundle.")
    }
    let url = root.appendingPathComponent(relativePath)
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw ConversionError.message("Missing fixture: \(relativePath)")
    }
    return url
}

func convertFixture(_ name: String, width: Int, format: OutputFormat, in folder: URL) async throws -> CGImage {
    let url = try fixtureURL("Fixtures/SVGEffects/\(name)")
    var options = ConversionOptions()
    options.format = format
    options.width = width
    let output = try await Converter.convert(url, to: folder, options: options)
    return try pixels(output)
}

/// Shared regression corpus for SVG gradients, filters, masks, clipping and
/// transparency. These run on every `make check` and are intentionally kept
/// separate from user-provided fixtures.
func checkSVGEffects(in folder: URL) async throws {
    let linear = try await convertFixture("linear-gradient.svg", width: 200, format: .png, in: folder)
    try expect(linear.width == 200 && linear.height == 100, "linear gradient dimensions")
    let left = try rgba(linear, x: 10, y: 50)
    try expect(left.r > 0.7 && left.b < 0.3 && left.a > 0.9, "linear gradient left stop")
    let middle = try rgba(linear, x: 50, y: 50)
    try expect(between(middle.r, 0.2, 0.8) && between(middle.b, 0.2, 0.8), "linear gradient middle blend")
    let outside = try rgba(linear, x: 150, y: 50)
    try expect(outside.a < 0.05, "linear gradient transparent outside its rect")

    let radial = try await convertFixture("radial-gradient.svg", width: 200, format: .png, in: folder)
    try expect(radial.width == 200 && radial.height == 200, "radial gradient dimensions")
    let center = try rgba(radial, x: 100, y: 100)
    try expect(center.r > 0.9 && center.g > 0.9 && center.b > 0.9 && center.a > 0.9, "radial gradient white center")
    let radialCorner = try rgba(radial, x: 10, y: 10)
    try expect(radialCorner.a < 0.05, "radial gradient transparent corner")

    let blur = try await convertFixture("blur-filter.svg", width: 200, format: .png, in: folder)
    let blurCenter = try rgba(blur, x: 100, y: 100)
    try expect(blurCenter.a > 0.8 && blurCenter.r > 0.5 && blurCenter.g < 0.5, "Gaussian blur center")
    let blurBleed = try rgba(blur, x: 60, y: 100)
    try expect(blurBleed.a > 0.01 && blurBleed.a < 0.99, "Gaussian blur bleeds outside the rect")
    let blurCorner = try rgba(blur, x: 10, y: 10)
    try expect(blurCorner.a < 0.05, "Gaussian blur leaves a transparent corner")

    let matrix = try await convertFixture("color-matrix-filter.svg", width: 200, format: .png, in: folder)
    let matrixCenter = try rgba(matrix, x: 100, y: 50)
    try expect(matrixCenter.r < 0.2 && matrixCenter.g > 0.7 && matrixCenter.b < 0.2 && matrixCenter.a > 0.8, "feColorMatrix red to green")

    let mask = try await convertFixture("mask.svg", width: 200, format: .png, in: folder)
    let maskLeft = try rgba(mask, x: 30, y: 50)
    let maskRight = try rgba(mask, x: 150, y: 50)
    try expect(maskLeft.a < 0.05, "mask hides the left half")
    try expect(maskRight.b > 0.7 && maskRight.a > 0.8, "mask keeps the right half")

    let clip = try await convertFixture("clip-path.svg", width: 200, format: .png, in: folder)
    let clipCorner = try rgba(clip, x: 10, y: 10)
    let clipCenter = try rgba(clip, x: 100, y: 100)
    try expect(clipCorner.a < 0.05, "clip-path transparent corner")
    try expect(clipCenter.r > 0.8 && clipCenter.g > 0.4 && clipCenter.b < 0.2 && clipCenter.a > 0.8, "clip-path orange center")

    let transparent = try await convertFixture("transparency.svg", width: 200, format: .png, in: folder)
    let transparentCorner = try rgba(transparent, x: 10, y: 10)
    let redHalf = try rgba(transparent, x: 40, y: 50)
    let overlap = try rgba(transparent, x: 90, y: 50)
    try expect(transparentCorner.a < 0.05, "transparent PNG corner")
    try expect(between(redHalf.a, 0.2, 0.8), "transparent PNG half-opacity red")
    try expect(overlap.a > 0.6, "transparent PNG overlap accumulates alpha")

    let flattened = try await convertFixture("transparency.svg", width: 200, format: .jpg, in: folder)
    let flattenedCorner = try rgba(flattened, x: 10, y: 10)
    try expect(flattenedCorner.r > 0.95 && flattenedCorner.g > 0.95 && flattenedCorner.b > 0.95, "transparent JPEG flattens onto white")
}

func convertSizingFixture(_ name: String, width: Int = 0, scale: Double = 1, in folder: URL) async throws -> CGImage {
    let url = try fixtureURL("Fixtures/SVGSizing/\(name)")
    var options = ConversionOptions()
    options.format = .png
    options.width = width
    options.scale = scale
    let output = try await Converter.convert(url, to: folder, options: options)
    return try pixels(output)
}

func checkReliabilityHardening(in folder: URL) async throws {
    let observed = folder.appendingPathComponent("signature.txt")
    try Data("one".utf8).write(to: observed)
    guard let signature = InputFile.signature(of: observed) else { throw ConversionError.message("FAIL: missing file signature") }
    try InputFile.verifyUnchanged(observed, against: signature)
    try Data("two-much-longer".utf8).write(to: observed)
    var changed = false
    do { try InputFile.verifyUnchanged(observed, against: signature) }
    catch { changed = true }
    try expect(changed, "source mutation is detected before publication")

    let stale = folder.appendingPathComponent(".transcodepilot-stale-check")
    let fresh = folder.appendingPathComponent(".transcodepilot-fresh-check")
    try FileManager.default.createDirectory(at: stale, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: fresh, withIntermediateDirectories: false)
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -2 * 86_400)], ofItemAtPath: stale.path)
    _ = TemporaryCleanup.removeStaleOutputTemps(in: folder)
    try expect(!FileManager.default.fileExists(atPath: stale.path), "stale conversion temp is removed")
    try expect(FileManager.default.fileExists(atPath: fresh.path), "recent conversion temp is retained")
    try? FileManager.default.removeItem(at: fresh)
}

final class ProgressLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ConversionProgress] = []

    func append(_ value: ConversionProgress) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var values: [ConversionProgress] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

func checkProgress(in folder: URL, svg: URL, video: URL) async throws {
    var imageOptions = ConversionOptions()
    imageOptions.width = 100
    let imageLog = ProgressLog()
    _ = try await Converter.convert(svg, to: folder, options: imageOptions) { imageLog.append($0) }
    let imageValues = imageLog.values
    try expect(!imageValues.isEmpty, "image conversion reports progress")
    try expect(imageValues.last!.fraction >= 0.95, "image progress reaches completion")
    try expect(zip(imageValues, imageValues.dropFirst()).allSatisfy { $0.fraction <= $1.fraction }, "image progress is monotonic")
    try expect(imageValues.contains { $0.phase == .rendering || $0.phase == .decoding }, "image progress reports phases")

    var audioOptions = ConversionOptions()
    audioOptions.format = .mp3
    let audioLog = ProgressLog()
    _ = try await Converter.convert(video, to: folder, options: audioOptions) { audioLog.append($0) }
    let audioValues = audioLog.values
    try expect(!audioValues.isEmpty, "audio conversion reports progress")
    try expect(audioValues.last!.fraction >= 0.95, "audio progress reaches completion")
    try expect(zip(audioValues, audioValues.dropFirst()).allSatisfy { $0.fraction <= $1.fraction }, "audio progress is monotonic")
    try expect(audioValues.contains { $0.phase == .encoding }, "audio progress reports encoding")
}

func checkRegressionExtras(in folder: URL, svg: URL, ffmpeg: URL, probe: URL) async throws {
    var options = ConversionOptions()
    options.width = 100

    // Non-ASCII/space-containing destination and a long but valid filename.
    let unicodeFolder = folder.appendingPathComponent("空格 目录", isDirectory: true)
    try FileManager.default.createDirectory(at: unicodeFolder, withIntermediateDirectories: true)
    let unicodeOutput = try await Converter.convert(svg, to: unicodeFolder, options: options)
    try expect(FileManager.default.fileExists(atPath: unicodeOutput.path), "non-ASCII/space output path works")

    let longStem = String(repeating: "长", count: 60)
    let longSource = folder.appendingPathComponent(longStem + ".svg")
    try FileManager.default.copyItem(at: svg, to: longSource)
    let longOutput = try await Converter.convert(longSource, to: folder, options: options)
    try expect(FileManager.default.fileExists(atPath: longOutput.path), "long source filename converts")
    let veryLong = folder.appendingPathComponent(String(repeating: "长", count: 80) + ".svg")
    try FileManager.default.copyItem(at: svg, to: veryLong)
    let veryLongOutput = try await Converter.convert(veryLong, to: folder, options: options)
    try expect(FileManager.default.fileExists(atPath: veryLongOutput.path), "very long source filename converts")
    try expect(veryLongOutput.lastPathComponent.utf8.count <= 255, "output filename stays within filesystem limits")

    // Multiple audio tracks: the app must still publish the first audio stream.
    let multi = folder.appendingPathComponent("multi-audio.mkv")
    _ = try await ProcessRunner.run(ffmpeg, ["-v", "error",
        "-f", "lavfi", "-i", "color=c=navy:s=64x64:d=1",
        "-f", "lavfi", "-i", "sine=frequency=440:duration=1",
        "-f", "lavfi", "-i", "sine=frequency=880:duration=1",
        "-map", "0:v", "-map", "1:a", "-map", "2:a",
        "-c:v", "mpeg4", "-c:a", "aac", "-shortest", multi.path])
    var audioOptions = ConversionOptions()
    audioOptions.format = .mp3
    let multiMp3 = try await Converter.convert(multi, to: folder, options: audioOptions)
    let multiInfo = String(decoding: try await ProcessRunner.run(probe, ["-v", "error", "-show_entries", "stream=codec_name:format=duration,bit_rate", "-of", "default=noprint_wrappers=1", multiMp3.path]), as: UTF8.self)
    try expect(multiInfo.contains("codec_name=mp3"), "multiple-audio MKV publishes MP3")
    try expect(multiInfo.contains("duration="), "multiple-audio MKV publishes a duration")
    if let bitrateLine = multiInfo.split(whereSeparator: \.isNewline).first(where: { $0.hasPrefix("bit_rate=") }),
       let bitrate = Int(bitrateLine.dropFirst("bit_rate=".count)) {
        try expect((160_000...230_000).contains(bitrate), "MP3 bitrate is near the requested 192 kbps")
    }

    // Timeout and denied-write behavior.
    var timedOut = false
    do { _ = try await ProcessRunner.run(URL(fileURLWithPath: "/bin/sleep"), ["2"], timeout: 0.2) }
    catch { timedOut = error.localizedDescription.contains("timed out") }
    try expect(timedOut, "child process timeout is reported")

    let denied = folder.appendingPathComponent("denied-output", isDirectory: true)
    try FileManager.default.createDirectory(at: denied, withIntermediateDirectories: true)
    try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: denied.path)
    defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: denied.path) }
    var deniedRejected = false
    do { _ = try await Converter.convert(svg, to: denied, options: options) }
    catch { deniedRejected = true }
    try expect(deniedRejected, "read-only output folder is rejected")

    // Concurrent publication must never overwrite either result.
    let collisionFolder = folder.appendingPathComponent("collision", isDirectory: true)
    try FileManager.default.createDirectory(at: collisionFolder, withIntermediateDirectories: true)
    let concurrent = try await withThrowingTaskGroup(of: URL.self) { group in
        for _ in 0..<2 {
            group.addTask { try await Converter.convert(svg, to: collisionFolder, options: options) }
        }
        var outputs: [URL] = []
        for try await output in group { outputs.append(output) }
        return outputs
    }
    try expect(Set(concurrent.map(\.path)).count == 2, "concurrent conversions choose distinct names")
    for output in concurrent { try expect(FileManager.default.fileExists(atPath: output.path), "concurrent output exists") }

    // HEIC and mirrored EXIF are covered when ImageIO can create those fixtures.
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let context = CGContext(data: nil, width: 20, height: 10, bitsPerComponent: 8,
                               bytesPerRow: 0, space: colorSpace,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        context.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
        context.fill(CGRect(x: 10, y: 0, width: 10, height: 10))
        if let image = context.makeImage() {
            let heic = folder.appendingPathComponent("fixture.heic")
            if let destination = CGImageDestinationCreateWithURL(heic as CFURL, "public.heic" as CFString, 1, nil) {
                CGImageDestinationAddImage(destination, image, nil)
                if CGImageDestinationFinalize(destination) {
                    var heicOptions = ConversionOptions()
                    heicOptions.format = .png
                    heicOptions.width = 20
                    let heicOutput = try await Converter.convert(heic, to: folder, options: heicOptions)
                    let decoded = try pixels(heicOutput)
                    try expect(decoded.width == 20 && decoded.height == 10, "HEIC input decodes")
                }
            }
            let mirrored = folder.appendingPathComponent("mirrored.jpg")
            if let destination = CGImageDestinationCreateWithURL(mirrored as CFURL, "public.jpeg" as CFString, 1, nil) {
                CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 2] as CFDictionary)
                if CGImageDestinationFinalize(destination) {
                    var mirrorOptions = ConversionOptions()
                    mirrorOptions.format = .png
                    mirrorOptions.width = 20
                    let mirrorOutput = try await Converter.convert(mirrored, to: folder, options: mirrorOptions)
                    let mirrorImage = try pixels(mirrorOutput)
                    let left = try rgba(mirrorImage, x: 2, y: 5)
                    let right = try rgba(mirrorImage, x: 17, y: 5)
                    try expect(left.b > 0.5 && left.r < 0.5 && right.r > 0.5 && right.b < 0.5,
                               "mirrored EXIF orientation is applied")
                }
            }
        }
    }

    // Display P3 input must be normalized to the documented sRGB output.
    if let p3 = CGColorSpace(name: CGColorSpace.displayP3),
       let context = CGContext(data: nil, width: 20, height: 10, bitsPerComponent: 8,
                               bytesPerRow: 0, space: p3,
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 10))
        if let image = context.makeImage() {
            let p3URL = folder.appendingPathComponent("display-p3.png")
            if let destination = CGImageDestinationCreateWithURL(p3URL as CFURL, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(destination, image, nil)
                if CGImageDestinationFinalize(destination) {
                    var p3Options = ConversionOptions()
                    p3Options.format = .png
                    p3Options.width = 20
                    let p3Output = try await Converter.convert(p3URL, to: folder, options: p3Options)
                    let p3Image = try pixels(p3Output)
                    let name = (p3Image.colorSpace?.name as String?) ?? ""
                    try expect(name.lowercased().contains("srgb"), "Display P3 input is normalized to sRGB")
                }
            }
        }
    }

    // Enlarged SVG edges must stay sharp (one source pixel becomes a crisp band).
    let edge = folder.appendingPathComponent("edge.svg")
    try Data(#"<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="white"/><rect x="50" y="0" width="1" height="100" fill="red"/></svg>"#.utf8).write(to: edge)
    var edgeOptions = ConversionOptions()
    edgeOptions.format = .png
    edgeOptions.width = 800
    let edgeOutput = try await Converter.convert(edge, to: folder, options: edgeOptions)
    let edgeImage = try pixels(edgeOutput)
    let edgeLine = try rgba(edgeImage, x: 400, y: 400)
    let edgeClear = try rgba(edgeImage, x: 420, y: 400)
    try expect(edgeLine.r > 0.8 && edgeLine.g < 0.2, "enlarged SVG edge keeps its color")
    try expect(edgeClear.r > 0.8 && edgeClear.g > 0.8 && edgeClear.b > 0.8, "enlarged SVG edge stays crisp")

    // CJK text must produce visible ink rather than a blank render.
    let cjk = folder.appendingPathComponent("cjk.svg")
    try Data(#"<svg xmlns="http://www.w3.org/2000/svg" width="160" height="48" viewBox="0 0 160 48"><rect width="160" height="48" fill="white"/><text x="8" y="34" font-size="28" font-family="PingFang SC, Hiragino Sans">测试</text></svg>"#.utf8).write(to: cjk)
    let cjkOutput = try await Converter.convert(cjk, to: folder, options: options)
    let cjkImage = try pixels(cjkOutput)
    var dark = false
    let cjkBitmap = NSBitmapImageRep(cgImage: cjkImage)
    for y in stride(from: 0, to: cjkBitmap.pixelsHigh, by: 2) {
        for x in stride(from: 0, to: cjkBitmap.pixelsWide, by: 2) {
            if let color = cjkBitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
               color.redComponent < 0.5, color.greenComponent < 0.5, color.blueComponent < 0.5 {
                dark = true; break
            }
        }
        if dark { break }
    }
    try expect(dark, "CJK SVG text produces visible ink")
}

func checkSVGSecurity(in folder: URL) async throws {
    let safeURL = try fixtureURL("Fixtures/SVGSecurity/safe-media-query.svg")
    var safeOptions = ConversionOptions()
    safeOptions.format = .png
    safeOptions.width = 100
    let safeOutput = try await Converter.convert(safeURL, to: folder, options: safeOptions)
    let safeImage = try pixels(safeOutput)
    let safeCenter = try rgba(safeImage, x: 50, y: 50)
    try expect(safeImage.width == 100 && safeImage.height == 100, "self-contained @media CSS remains accepted")
    try expect(safeCenter.a > 0.5, "self-contained at-rule SVG renders nonblank")

    for fixture in ["foreign-namespace-root.svg", "animate-motion.svg", "animate-color.svg",
                    "discard.svg", "xlink-href.svg"] {
        let url = try fixtureURL("Fixtures/SVGSecurity/\(fixture)")
        var rejected = false
        do { _ = try await Converter.convert(url, to: folder, options: ConversionOptions()) }
        catch { rejected = true }
        try expect(rejected, "trust-boundary fixture rejected: \(fixture)")
    }
}

func checkSVGSizing(in folder: URL) async throws {
    let units = try await convertSizingFixture("units-mm.svg", scale: 1, in: folder)
    try expect(units.width == 96 && units.height == 48, "physical units resolve at 96 dpi")

    let viewBoxOnly = try await convertSizingFixture("viewbox-only.svg", scale: 2, in: folder)
    try expect(viewBoxOnly.width == 200 && viewBoxOnly.height == 100, "viewBox-only SVG scales via zoom")

    let percentage = try await convertSizingFixture("percentage.svg", scale: 2, in: folder)
    try expect(percentage.width == 200 && percentage.height == 100, "percentage dimensions resolve against viewBox")

    let oneDimension = try await convertSizingFixture("one-dimension.svg", scale: 1, in: folder)
    try expect(oneDimension.width == 200 && oneDimension.height == 100, "missing SVG dimension derives from viewBox aspect")

    let fractional = try await convertSizingFixture("fractional.svg", width: 201, in: folder)
    try expect(fractional.width == 201, "explicit requested SVG width stays exact")
    try expect(fractional.height == 101, "fractional SVG height follows the intrinsic ratio")

    let explicitUnits = try await convertSizingFixture("units-mm.svg", width: 200, in: folder)
    try expect(explicitUnits.width == 200 && explicitUnits.height == 100, "explicit width uses the physical-unit aspect ratio")

    let unitsURL = try fixtureURL("Fixtures/SVGSizing/units-mm.svg")
    let metadata = try SourceInspector.inspect(unitsURL)
    var estimateOptions = ConversionOptions()
    estimateOptions.scale = 1
    let estimate = try ConversionPlanner.estimate(metadata, options: estimateOptions)
    try expect(estimate == ConversionEstimate(width: 96, height: 48), "planner agrees with physical-unit intrinsic size")

    for (fixture, reason) in [
        ("unsupported-percent.svg", "percentage"),
        ("no-dimensions.svg", "positive")
    ] {
        let url = try fixtureURL("Fixtures/SVGSizing/\(fixture)")
        var rejected = false
        do { _ = try await Converter.convert(url, to: folder, options: ConversionOptions()) }
        catch {
            rejected = true
            try expect(error.localizedDescription.contains(reason), "\(fixture) reports the expected reason")
        }
        try expect(rejected, "\(fixture) is rejected")
    }
}

@main struct Checks {
    static func main() async {
        do {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("transcodepilot-checks-\(UUID())")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: folder) }
            let svg = folder.appendingPathComponent("drawing with spaces.svg")
            let source = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="50" viewBox="0 0 100 50"><rect x="10" y="10" width="30" height="20" fill="red"/></svg>
            """
            try Data(source.utf8).write(to: svg)
            var options = ConversionOptions()
            options.width = 1000
            let png = try await Converter.convert(svg, to: folder, options: options)
            let image = try pixels(png)
            try expect(image.width == 1000 && image.height == 500, "SVG must render at target pixels")
            try expect(image.alphaInfo != .none, "PNG retains transparency")
            let second = try await Converter.convert(svg, to: folder, options: options)
            try expect(second != png, "existing output is never overwritten")
            let original = try Data(contentsOf: svg)
            try expect(original == Data(source.utf8), "source is untouched")
            options.format = .jpg
            let jpg = try await Converter.convert(svg, to: folder, options: options)
            let jpeg = try pixels(jpg)
            try expect(jpeg.width == 1000 && jpeg.height == 500, "JPEG target size")
            let bitmap = NSBitmapImageRep(cgImage: jpeg)
            let corner = bitmap.colorAt(x: 0, y: 0)!.usingColorSpace(.deviceRGB)!
            try expect(corner.redComponent > 0.95 && corner.greenComponent > 0.95, "JPEG transparency flattens to white")
            options.format = .png
            options.width = 250
            let resized = try await Converter.convert(jpg, to: folder, options: options)
            let small = try pixels(resized)
            try expect(small.width == 250 && small.height == 125, "bitmap resize preserves ratio")
            let rotatedURL = folder.appendingPathComponent("rotated.jpg")
            let rotatedDestination = CGImageDestinationCreateWithURL(rotatedURL as CFURL, "public.jpeg" as CFString, 1, nil)!
            CGImageDestinationAddImage(rotatedDestination, jpeg, [kCGImagePropertyOrientation: 6] as CFDictionary)
            try expect(CGImageDestinationFinalize(rotatedDestination), "orientation fixture saved")
            let rotatedOutput = try await Converter.convert(rotatedURL, to: folder, options: options)
            let rotatedImage = try pixels(rotatedOutput)
            try expect(rotatedImage.width == 250 && rotatedImage.height == 500, "EXIF rotation preserves displayed aspect ratio")
            for malicious in [
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><image href='file:///etc/passwd'/></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><foreignObject/></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><style>@import 'https://example.com/a.css';</style></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><style><![CDATA[ rect { fill: url(https://example.com/x); } ]]></style></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><script/></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'><rect style='fill:u&#114;l(https://example.com/a)'/></svg>",
                "<svg xmlns='http://www.w3.org/2000/svg' width='999999' height='999999'/>"
            ] {
                let bad = folder.appendingPathComponent("unsafe.svg")
                try Data(malicious.utf8).write(to: bad)
                var rejected = false
                do { _ = try await Converter.convert(bad, to: folder, options: ConversionOptions()) }
                catch { rejected = true }
                try expect(rejected, "unsafe or oversized SVG must be rejected")
            }
            options.width = -1
            var rejected = false
            do { _ = try await Converter.convert(svg, to: folder, options: options) }
            catch { rejected = true }
            try expect(rejected, "negative width rejected")

            var imageOptions = ConversionOptions()
            imageOptions.width = 1000
            let svgMetadata = try SourceInspector.inspect(svg)
            try expect(svgMetadata.kind == .svg, "SVG source is identified")
            let svgEstimate = try ConversionPlanner.estimate(svgMetadata, options: imageOptions)
            try expect(svgEstimate == ConversionEstimate(width: 1000, height: 500), "SVG estimate matches target pixels")
            let jpegMetadata = try SourceInspector.inspect(jpg)
            var resizeOptions = ConversionOptions()
            resizeOptions.width = 250
            let resizeEstimate = try ConversionPlanner.estimate(jpegMetadata, options: resizeOptions)
            try expect(resizeEstimate == ConversionEstimate(width: 250, height: 125), "bitmap estimate preserves ratio")
            var invalidOptions = ConversionOptions()
            invalidOptions.width = -1
            var estimateRejected = false
            do { _ = try ConversionPlanner.estimate(svgMetadata, options: invalidOptions) }
            catch { estimateRejected = true }
            try expect(estimateRejected, "invalid width rejected by planner")

            try expect(PreferenceDefaults.sanitizedScale(nil) == 2, "missing scale uses default")
            try expect(PreferenceDefaults.sanitizedScale(3) == 2, "unexpected scale is sanitized")
            try expect(PreferenceDefaults.sanitizedJPEGQuality(.nan) == 0.9, "non-finite quality uses default")
            try expect(PreferenceDefaults.sanitizedJPEGQuality(5) == 1, "quality is clamped")
            try expect(PreferenceDefaults.sanitizedAudioBitrate(999) == 192, "unexpected bitrate is sanitized")
            try expect(PreferenceDefaults.preferredScale(nil, kind: .image) == 1, "photos default to 1x")
            try expect(PreferenceDefaults.preferredScale(nil, kind: .svg) == 2, "SVGs default to 2x")
            try expect(PreferenceDefaults.preferredScale(4, kind: .image) == 4, "explicit scale is retained")
            try expect(PreferenceDefaults.sanitizedWidth(nil) == 0, "missing width uses scale mode")
            try expect(PreferenceDefaults.sanitizedWidth(1200) == 1200, "stored width is retained")
            try expect(PreferenceDefaults.sanitizedWidth(20_000) == 0, "oversized stored width is discarded")

            let empty = folder.appendingPathComponent("empty.svg")
            try Data().write(to: empty)
            let huge = folder.appendingPathComponent("huge.svg")
            FileManager.default.createFile(atPath: huge.path, contents: nil)
            let hugeHandle = try FileHandle(forWritingTo: huge)
            try hugeHandle.truncate(atOffset: UInt64(InputFile.svgSizeLimit + 1))
            try hugeHandle.close()
            let corrupt = folder.appendingPathComponent("corrupt.png")
            try Data(repeating: 0, count: 64).write(to: corrupt)
            let fakeDirectory = folder.appendingPathComponent("fake.png", isDirectory: true)
            try FileManager.default.createDirectory(at: fakeDirectory, withIntermediateDirectories: true)
            let tall = folder.appendingPathComponent("tall.svg")
            try Data(#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 10000"><rect width="1" height="10000" fill="red"/></svg>"#.utf8).write(to: tall)
            var tallOptions = ConversionOptions()
            tallOptions.width = 16_384
            for (label, url, expected) in [
                ("empty source", empty, "empty"),
                ("oversized SVG", huge, "20 MB"),
                ("corrupt PNG", corrupt, "Cannot read this image"),
                ("directory source", fakeDirectory, "regular file"),
                ("extreme aspect ratio", tall, "SVG output exceeds")
            ] {
                var failed = false
                do {
                    let output = try await Converter.convert(url, to: folder, options: url == tall ? tallOptions : imageOptions)
                    _ = output
                } catch {
                    failed = true
                    try expect(error.localizedDescription.contains(expected), "\(label) reports the expected reason")
                }
                try expect(failed, "\(label) is rejected")
            }

            let linked = folder.appendingPathComponent("linked drawing.svg")
            try FileManager.default.createSymbolicLink(at: linked, withDestinationURL: svg)
            let linkedOutput = try await Converter.convert(linked, to: folder, options: imageOptions)
            let linkedImage = try pixels(linkedOutput)
            try expect(linkedImage.width == 1000 && linkedImage.height == 500, "symlinked source converts through its target")

            let (cancelStream, cancelContinuation) = AsyncStream<Void>.makeStream()
            let cancelTask = Task {
                var iterator = cancelStream.makeAsyncIterator()
                _ = await iterator.next()
                return try await Converter.convert(svg, to: folder, options: imageOptions)
            }
            cancelTask.cancel()
            cancelContinuation.yield(())
            cancelContinuation.finish()
            var cancelledBeforePublishing = false
            do { _ = try await cancelTask.value }
            catch is CancellationError { cancelledBeforePublishing = true }
            catch { throw error }
            try expect(cancelledBeforePublishing, "cancelled conversion stops before publishing")
            try await checkSVGEffects(in: folder)
            try await checkSVGSizing(in: folder)
            try await checkSVGSecurity(in: folder)
            try await checkReliabilityHardening(in: folder)

            guard let ffmpeg = Tools.find("ffmpeg"), let probe = Tools.find("ffprobe") else { throw ConversionError.message("FFmpeg required for checks") }
            let video = folder.appendingPathComponent("sample.mp4")
            _ = try await ProcessRunner.run(ffmpeg, ["-v", "error", "-f", "lavfi", "-i", "color=c=blue:s=64x64:d=1", "-f", "lavfi", "-i", "sine=frequency=440:duration=1", "-c:v", "mpeg4", "-c:a", "aac", "-shortest", video.path])
            options = ConversionOptions()
            options.format = .mp3
            let mp3 = try await Converter.convert(video, to: folder, options: options)
            let audioInfo = try await ProcessRunner.run(probe, ["-v", "error", "-show_entries", "stream=codec_name", "-of", "csv=p=0", mp3.path])
            try expect(String(decoding: audioInfo, as: UTF8.self).contains("mp3"), "MP4 audio encoded as MP3")
            for (name, bytes) in [("corrupt.mp4", Data(repeating: 0x41, count: 4096)),
                                  ("corrupt.mkv", Data(repeating: 0x42, count: 4096))] {
                let corrupt = folder.appendingPathComponent(name)
                try bytes.write(to: corrupt)
                var rejected = false
                do { _ = try await Converter.convert(corrupt, to: folder, options: options) }
                catch { rejected = true }
                try expect(rejected, "corrupt container rejected: \(name)")
            }

            let silent = folder.appendingPathComponent("silent.mp4")
            _ = try await ProcessRunner.run(ffmpeg, ["-v", "error", "-i", video.path, "-an", "-c:v", "copy", silent.path])
            let mkv = folder.appendingPathComponent("sample.mkv")
            _ = try await ProcessRunner.run(ffmpeg, ["-v", "error", "-i", video.path, "-c", "copy", mkv.path])
            try expect(Converter.formats(for: mkv) == [.mp3], "MKV exposes MP3 output")
            options = ConversionOptions()
            options.format = .mp3
            let mkvMp3 = try await Converter.convert(mkv, to: folder, options: options)
            let mkvAudioInfo = try await ProcessRunner.run(probe, ["-v", "error", "-show_entries", "stream=codec_name", "-of", "csv=p=0", mkvMp3.path])
            try expect(String(decoding: mkvAudioInfo, as: UTF8.self).contains("mp3"), "MKV audio encoded as MP3")
            rejected = false
            do { _ = try await Converter.convert(silent, to: folder, options: options) }
            catch { rejected = true }
            try expect(rejected, "video without audio rejected")
            try await checkRegressionExtras(in: folder, svg: svg, ffmpeg: ffmpeg, probe: probe)
            try await checkProgress(in: folder, svg: svg, video: video)
            let task = Task { try await ProcessRunner.run(URL(fileURLWithPath: "/bin/sleep"), ["10"]) }
            try await Task.sleep(nanoseconds: 100_000_000)
            let cancellationStart = Date()
            task.cancel()
            do { _ = try await task.value; throw ConversionError.message("FAIL: cancellation ignored") }
            catch is CancellationError { }
            try expect(Date().timeIntervalSince(cancellationStart) < 3, "child process cancellation is prompt")
            let remaining = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            try expect(!remaining.contains(where: { $0.hasPrefix(".transcodepilot-") }), "temporary outputs cleaned up")
            print("PASS: MP4/MKV → MP3, progress, corrupt containers, missing audio, child process cancellation and temporary cleanup")
            print("PASS: SVG pixels, transparency, JPEG background, bitmap resize, collision safety, source preservation and unsafe input")
            print("PASS: input bounds, symlink source, cancelled conversion, planner estimates and preference sanitizing")
            print("PASS: SVG effects, sizing, trust-boundary, reliability-hardening and regression extras")
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
