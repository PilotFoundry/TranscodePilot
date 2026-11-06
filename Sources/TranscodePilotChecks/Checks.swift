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
            guard let ffmpeg = Tools.find("ffmpeg"), let probe = Tools.find("ffprobe") else { throw ConversionError.message("FFmpeg required for checks") }
            let video = folder.appendingPathComponent("sample.mp4")
            _ = try await ProcessRunner.run(ffmpeg, ["-v", "error", "-f", "lavfi", "-i", "color=c=blue:s=64x64:d=1", "-f", "lavfi", "-i", "sine=frequency=440:duration=1", "-c:v", "mpeg4", "-c:a", "aac", "-shortest", video.path])
            options = ConversionOptions()
            options.format = .mp3
            let mp3 = try await Converter.convert(video, to: folder, options: options)
            let audioInfo = try await ProcessRunner.run(probe, ["-v", "error", "-show_entries", "stream=codec_name", "-of", "csv=p=0", mp3.path])
            try expect(String(decoding: audioInfo, as: UTF8.self).contains("mp3"), "MP4 audio encoded as MP3")
            let silent = folder.appendingPathComponent("silent.mp4")
            _ = try await ProcessRunner.run(ffmpeg, ["-v", "error", "-i", video.path, "-an", "-c:v", "copy", silent.path])
            rejected = false
            do { _ = try await Converter.convert(silent, to: folder, options: options) }
            catch { rejected = true }
            try expect(rejected, "video without audio rejected")
            let task = Task { try await ProcessRunner.run(URL(fileURLWithPath: "/bin/sleep"), ["10"]) }
            try await Task.sleep(nanoseconds: 100_000_000)
            task.cancel()
            do { _ = try await task.value; throw ConversionError.message("FAIL: cancellation ignored") }
            catch is CancellationError { }
            let remaining = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            try expect(!remaining.contains(where: { $0.hasPrefix(".transcodepilot-") }), "temporary outputs cleaned up")
            print("PASS: MP4 → MP3, missing audio, child process cancellation and temporary cleanup")
            print("PASS: SVG pixels, transparency, JPEG background, bitmap resize, collision safety, source preservation and unsafe input")
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
