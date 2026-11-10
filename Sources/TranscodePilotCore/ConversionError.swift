import Foundation

public enum ConversionErrorCode: String, Sendable {
    case invalidSettings
    case unsupportedFormat
    case unreadableSource
    case emptySource
    case inputTooLarge
    case missingEngine
    case noAudioTrack
    case invalidImage
    case invalidSVG
    case externalSVGResource
    case unsupportedSVGContent
    case outputLimit
    case inputLimit
    case outputNotWritable
    case diskFull
    case outputVolumeUnsupported
    case outputVerification
    case timeout
    case engineFailure
    case sourceChanged
    case unknown

    var defaultEnglish: String {
        switch self {
        case .invalidSettings: return "Unsupported format or invalid conversion settings."
        case .unsupportedFormat: return "Unsupported input format."
        case .unreadableSource: return "The source file is not a readable regular file."
        case .emptySource: return "The source file is empty."
        case .inputTooLarge: return "The source file is too large."
        case .missingEngine: return "A required conversion engine is not installed."
        case .noAudioTrack: return "This video has no audio track."
        case .invalidImage: return "The image cannot be read or written."
        case .invalidSVG: return "The SVG cannot be converted."
        case .externalSVGResource: return "The SVG uses external content, which is not supported."
        case .unsupportedSVGContent: return "The SVG uses unsupported content."
        case .outputLimit: return "The requested output exceeds the supported size limits."
        case .inputLimit: return "The source image exceeds the supported size limits."
        case .outputNotWritable: return "The output folder cannot be written to."
        case .diskFull: return "The destination disk is full."
        case .outputVolumeUnsupported: return "The output folder is on a volume without safe publication support."
        case .outputVerification: return "The converted output could not be verified."
        case .timeout: return "The conversion timed out."
        case .engineFailure: return "The conversion engine failed."
        case .sourceChanged: return "The source file changed during conversion."
        case .unknown: return "The conversion failed."
        }
    }
}

public enum ConversionError: Error, LocalizedError {
    case message(String)
    case code(ConversionErrorCode, detail: String? = nil)

    public var errorCode: ConversionErrorCode? {
        if case .code(let code, _) = self { return code }
        return nil
    }

    public var detail: String? {
        if case .code(_, let detail) = self { return detail }
        return nil
    }

    public var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        case .code(let code, let detail):
            // The detail is retained for tests and engine diagnostics; the app
            // maps the code to localized app-owned text instead of showing it
            // verbatim (except for engine stderr).
            return detail ?? code.defaultEnglish
        }
    }
}
