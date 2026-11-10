import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case png, jpg, mp3
    public var id: String { rawValue }
}

public struct ConversionOptions: Sendable {
    public var format: OutputFormat = .png
    public var width = 0
    public var scale = 2.0
    public var whiteBackground = false
    public var jpegQuality = 0.9
    public var audioBitrate = 192
    public init() {}

    public func validate() throws {
        guard (0...16_384).contains(width),
              scale.isFinite, (0.1...8).contains(scale),
              (0...1).contains(jpegQuality),
              [128, 192, 320].contains(audioBitrate) else {
            throw ConversionError.code(.invalidSettings, detail: "Unsupported format or invalid conversion settings.")
        }
    }
}

public enum Converter {
    public static func formats(for input: URL) -> [OutputFormat] {
        switch input.pathExtension.lowercased() {
        case "svg", "png", "jpg", "jpeg", "heic": return [.png, .jpg]
        case "mp4", "mkv": return [.mp3]
        default: return []
        }
    }

    public static func convert(_ input: URL, to directory: URL, options: ConversionOptions) async throws -> URL {
        try options.validate()
        try Task.checkCancellation()
        guard formats(for: input).contains(options.format) else {
            throw ConversionError.code(.invalidSettings, detail: "Unsupported format or invalid conversion settings.")
        }
        let fm = FileManager.default
        let source = try InputFile.regularFileURL(input)
        let resolvedDirectory = directory.resolvingSymlinksInPath()
        let directoryValues = try? resolvedDirectory.resourceValues(forKeys: [.isDirectoryKey, .volumeSupportsHardLinksKey])
        guard directoryValues?.isDirectory == true, fm.isWritableFile(atPath: directory.path) else {
            throw ConversionError.code(.outputNotWritable, detail: "Source or output folder is not accessible.")
        }
        // Publication uses link() for non-overwriting atomic names. Reject
        // destinations whose filesystem cannot provide that guarantee.
        guard directoryValues?.volumeSupportsHardLinks == true else {
            throw ConversionError.code(.outputVolumeUnsupported, detail: "Choose an output folder on a volume that supports hard links (for example APFS).")
        }
        let temporary = directory.appendingPathComponent(".transcodepilot-\(UUID())", isDirectory: true)
        try fm.createDirectory(at: temporary, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: temporary) }
        let result = temporary.appendingPathComponent("output.\(options.format.rawValue)")
        if options.format == .mp3 {
            guard let ffmpeg = Tools.find("ffmpeg"), let probe = Tools.find("ffprobe") else {
                throw ConversionError.code(.missingEngine, detail: "Install FFmpeg: brew install ffmpeg")
            }
            // Pin the demuxer so a renamed/ambiguous container is not probed as
            // an unrelated format. MKV and MP4 take the same audio-only path.
            let demuxer = input.pathExtension.lowercased() == "mkv" ? "matroska" : "mov"
            let probeOptions = ["-v", "error", "-protocol_whitelist", "file,pipe",
                                "-probesize", "64M", "-analyzeduration", "100000000",
                                "-f", demuxer]
            let info = try await ProcessRunner.run(probe, probeOptions + ["-select_streams", "a:0", "-show_entries", "stream=index", "-of", "csv=p=0", source.path], timeout: 60)
            guard !info.isEmpty else { throw ConversionError.code(.noAudioTrack, detail: "This video has no audio track.") }
            _ = try await ProcessRunner.run(ffmpeg, ["-nostdin", "-v", "error", "-n", "-protocol_whitelist", "file,pipe",
                                                      "-probesize", "64M", "-analyzeduration", "100000000",
                                                      "-f", demuxer, "-i", source.path, "-map", "0:a:0", "-vn",
                                                      "-map_metadata", "-1", "-c:a", "libmp3lame", "-b:a", "\(options.audioBitrate)k", result.path], timeout: 3600)
            let verification = try await ProcessRunner.run(probe, ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", result.path], timeout: 60)
            guard let duration = Double(String(decoding: verification, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)), duration > 0 else {
                throw ConversionError.code(.outputVerification, detail: "Output audio could not be verified.")
            }
        } else {
            var sourceURL = source
            if input.pathExtension.lowercased() == "svg" {
                guard let renderer = Tools.find("rsvg-convert") else {
                    throw ConversionError.code(.missingEngine, detail: "Install SVG renderer: brew install librsvg")
                }
                let data = try InputFile.readData(
                    input,
                    limit: InputFile.svgSizeLimit,
                    limitMessage: "SVG must be UTF-8 and smaller than 20 MB."
                )
                let svgSize = try SVGDocument.validate(data)
                let renderWidth: Double
                let renderHeight: Double
                var args = ["--format", "png"]
                if options.width > 0 {
                    // Width-only lets the renderer derive height from the intrinsic
                    // aspect ratio; the requested width stays exact.
                    renderWidth = Double(options.width)
                    renderHeight = (svgSize.height * renderWidth / svgSize.width).rounded()
                    guard renderWidth >= 1, renderHeight >= 1, renderWidth <= 16_384, renderHeight <= 16_384,
                          renderWidth * renderHeight <= 40_000_000 else {
                        throw ConversionError.code(.outputLimit, detail: "SVG output exceeds the 40 megapixel or 16,384 pixel limit.")
                    }
                    args += ["--keep-aspect-ratio", "--width", String(options.width)]
                } else {
                    renderWidth = (svgSize.width * options.scale).rounded()
                    renderHeight = (svgSize.height * options.scale).rounded()
                    guard renderWidth >= 1, renderHeight >= 1, renderWidth <= 16_384, renderHeight <= 16_384,
                          renderWidth * renderHeight <= 40_000_000 else {
                        throw ConversionError.code(.outputLimit, detail: "SVG output exceeds the 40 megapixel or 16,384 pixel limit.")
                    }
                    args += ["--zoom", String(options.scale)]
                }
                try Task.checkCancellation()
                let isolated = temporary.appendingPathComponent("input.svg")
                try data.write(to: isolated)
                sourceURL = temporary.appendingPathComponent("render.png")
                args += ["--output", sourceURL.path, isolated.path]
                _ = try await ProcessRunner.run(renderer, args, timeout: 30)
            }
            guard let sourceImage = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) as? [CFString: Any],
                  let sourceWidth = properties[kCGImagePropertyPixelWidth] as? Int,
                  let sourceHeight = properties[kCGImagePropertyPixelHeight] as? Int,
                  sourceWidth > 0, sourceHeight > 0,
                  Double(sourceWidth) * Double(sourceHeight) <= 80_000_000 else {
                throw ConversionError.code(.invalidImage, detail: "Cannot read this image.")
            }
            if input.pathExtension.lowercased() == "svg", options.width > 0, sourceWidth != options.width {
                throw ConversionError.code(.outputVerification, detail: "SVG renderer produced an unexpected width.")
            }
            let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
            let displayedWidth = (5...8).contains(orientation) ? sourceHeight : sourceWidth
            let displayedHeight = (5...8).contains(orientation) ? sourceWidth : sourceHeight
            guard displayedWidth > 0, displayedHeight > 0 else {
                throw ConversionError.code(.inputLimit, detail: "Source dimensions are invalid.")
            }
            let isSVG = input.pathExtension.lowercased() == "svg"
            let width = isSVG ? displayedWidth : (options.width > 0 ? options.width : Int(Double(displayedWidth) * options.scale))
            let height = Int((Double(displayedHeight) * Double(width) / Double(max(1, displayedWidth))).rounded())
            guard width > 0, height > 0, width <= 16_384, height <= 16_384,
                  Double(width) * Double(height) <= 40_000_000,
                  Double(sourceWidth) * Double(sourceHeight) <= 80_000_000 else {
                throw ConversionError.code(.outputLimit, detail: "Image exceeds the 40 megapixel output or 80 megapixel input limit.")
            }
            try Task.checkCancellation()
            let thumbnail: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(width, height)]
            guard let image = CGImageSourceCreateThumbnailAtIndex(sourceImage, 0, thumbnail as CFDictionary) else {
                throw ConversionError.code(.invalidImage, detail: "Cannot decode this image.")
            }
            try Task.checkCancellation()
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw ConversionError.code(.invalidImage, detail: "Cannot allocate output image.")
            }
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            if options.whiteBackground || options.format == .jpg {
                context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(rect)
            }
            context.interpolationQuality = .high
            context.draw(image, in: rect)
            try Task.checkCancellation()
            guard let rendered = context.makeImage(), let destination = CGImageDestinationCreateWithURL(result as CFURL,
                (options.format == .png ? UTType.png.identifier : UTType.jpeg.identifier) as CFString, 1, nil) else {
                throw ConversionError.code(.invalidImage, detail: "Cannot create image output.")
            }
            CGImageDestinationAddImage(destination, rendered, [kCGImageDestinationLossyCompressionQuality: options.jpegQuality] as CFDictionary)
            guard CGImageDestinationFinalize(destination), let check = CGImageSourceCreateWithURL(result as CFURL, nil),
                  let decoded = CGImageSourceCreateImageAtIndex(check, 0, nil), decoded.width == width, decoded.height == height else {
                throw ConversionError.code(.outputVerification, detail: "Output image verification failed.")
            }
            try Task.checkCancellation()
        }
        try Task.checkCancellation()
        let stem = input.deletingPathExtension().lastPathComponent
        for index in 0..<10000 {
            let suffix = index == 0 ? "" : "-\(index)"
            let target = directory.appendingPathComponent("\(stem)\(suffix).\(options.format.rawValue)")
            // link() publishes a complete file atomically and refuses to overwrite an existing path.
            if link(result.path, target.path) == 0 { return target }
            if errno == ENOSPC {
                throw ConversionError.code(.diskFull, detail: "Cannot save output: \(String(cString: strerror(errno)))")
            }
            if errno != EEXIST { throw ConversionError.code(.outputNotWritable, detail: "Cannot save output: \(String(cString: strerror(errno)))") }
        }
        throw ConversionError.code(.outputNotWritable, detail: "Too many files with the same output name.")
    }
}
