import Foundation
import CoreGraphics
import ImageIO

/// Filesystem preflight shared by inspection and conversion.
public enum InputFile {
    /// The source review selected 20 MB as the upper bound for SVG text.
    public static let svgSizeLimit = 20_000_000

    /// Resolves symbolic links and proves that the URL is a readable, non-empty
    /// regular file. Directories, FIFOs, devices and dangling links are rejected
    /// before an engine or decoder is started.
    public static func regularFileURL(_ url: URL) throws -> URL {
        let resolved = url.resolvingSymlinksInPath()
        guard FileManager.default.fileExists(atPath: resolved.path),
              let values = try? resolved.resourceValues(forKeys: [.isRegularFileKey, .isReadableKey, .fileSizeKey]),
              values.isRegularFile == true,
              values.isReadable == true else {
            throw ConversionError.code(.unreadableSource, detail: "This item is not a readable regular file.")
        }
        guard let size = values.fileSize, size > 0 else {
            throw ConversionError.code(.emptySource, detail: "The source file is empty.")
        }
        return resolved
    }

    /// Checks the on-disk size before loading a file into memory.
    public static func readData(_ url: URL, limit: Int, limitMessage: String) throws -> Data {
        let resolved = try regularFileURL(url)
        guard let values = try? resolved.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize, size <= limit else {
            throw ConversionError.code(.inputTooLarge, detail: limitMessage)
        }
        return try Data(contentsOf: resolved)
    }
}

public enum SourceKind: String, Sendable {
    case image
    case svg
    case video
}

public struct SourceMetadata: Sendable, Equatable {
    public enum Dimensions: Sendable, Equatable {
        /// Displayed bitmap pixels after EXIF orientation is applied.
        case pixels(Int, Int)
        /// Intrinsic SVG size in the units the current validator reports.
        case svg(Double, Double)
        /// Video dimensions are only needed once the source has been probed.
        case unknown
    }

    public let kind: SourceKind
    public let dimensions: Dimensions

    public init(kind: SourceKind, dimensions: Dimensions) {
        self.kind = kind
        self.dimensions = dimensions
    }
}

public enum SourceInspector {
    public static func inspect(_ input: URL) throws -> SourceMetadata {
        let formats = Converter.formats(for: input)
        guard !formats.isEmpty else {
            throw ConversionError.code(.unsupportedFormat, detail: "Unsupported input format.")
        }
        let resolved = try InputFile.regularFileURL(input)
        if formats == [.mp3] {
            return SourceMetadata(kind: .video, dimensions: .unknown)
        }
        if input.pathExtension.lowercased() == "svg" {
            let data = try InputFile.readData(
                input,
                limit: InputFile.svgSizeLimit,
                limitMessage: "SVG must be UTF-8 and smaller than 20 MB."
            )
            let size = try SVGDocument.validate(data)
            return SourceMetadata(kind: .svg, dimensions: .svg(Double(size.width), Double(size.height)))
        }
        guard let source = CGImageSourceCreateWithURL(resolved as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let sourceWidth = properties[kCGImagePropertyPixelWidth] as? Int,
              let sourceHeight = properties[kCGImagePropertyPixelHeight] as? Int,
              sourceWidth > 0, sourceHeight > 0,
              Double(sourceWidth) * Double(sourceHeight) <= 80_000_000 else {
            throw ConversionError.code(.invalidImage, detail: "Cannot read this image.")
        }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let displayedWidth = (5...8).contains(orientation) ? sourceHeight : sourceWidth
        let displayedHeight = (5...8).contains(orientation) ? sourceWidth : sourceHeight
        return SourceMetadata(kind: .image, dimensions: .pixels(displayedWidth, displayedHeight))
    }
}

public struct ConversionEstimate: Sendable, Equatable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

/// Pure planning/validation shared by the UI and conversion path. Keeping the
/// dimension arithmetic here makes it testable without starting an engine.
public enum ConversionPlanner {
    public static func estimate(_ input: URL, options: ConversionOptions) throws -> ConversionEstimate? {
        try options.validate()
        return try estimate(try SourceInspector.inspect(input), options: options)
    }

    public static func estimate(_ metadata: SourceMetadata, options: ConversionOptions) throws -> ConversionEstimate? {
        try options.validate()
        switch metadata.dimensions {
        case .unknown:
            return nil
        case .pixels(let sourceWidth, let sourceHeight):
            guard sourceWidth > 0, sourceHeight > 0 else {
                throw ConversionError.code(.inputLimit, detail: "Source dimensions are invalid.")
            }
            let width = options.width > 0 ? options.width : Int(Double(sourceWidth) * options.scale)
            let height = Int((Double(sourceHeight) * Double(width) / Double(max(1, sourceWidth))).rounded())
            guard width > 0, height > 0, width <= 16_384, height <= 16_384,
                  Double(width) * Double(height) <= 40_000_000,
                  Double(sourceWidth) * Double(sourceHeight) <= 80_000_000 else {
                throw ConversionError.code(.outputLimit, detail: "Image exceeds the 40 megapixel output or 80 megapixel input limit.")
            }
            return ConversionEstimate(width: width, height: height)
        case .svg(let sourceWidth, let sourceHeight):
            guard sourceWidth.isFinite, sourceHeight.isFinite, sourceWidth > 0, sourceHeight > 0 else {
                throw ConversionError.code(.invalidSVG, detail: "SVG needs positive pixel dimensions or a viewBox.")
            }
            let width = options.width > 0 ? Double(options.width) : sourceWidth * options.scale
            let height = sourceHeight * width / sourceWidth
            guard width >= 1, height >= 1, width <= 16_384, height <= 16_384,
                  width * height <= 40_000_000 else {
                throw ConversionError.code(.outputLimit, detail: "SVG output exceeds the 40 megapixel or 16,384 pixel limit.")
            }
            return ConversionEstimate(width: Int(width.rounded()), height: Int(height.rounded()))
        }
    }
}
