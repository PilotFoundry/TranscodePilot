import Foundation
import TranscodePilotCore

/// Maps typed core failures to localized app-owned text. Engine stderr is the
/// only detail deliberately shown verbatim because it is diagnostic and may be
/// English by policy.
func localizedErrorText(_ error: Error) -> String {
    guard let conversion = error as? ConversionError else {
        return error.localizedDescription
    }
    switch conversion {
    case .message:
        return conversion.localizedDescription
    case .code(let code, let detail):
        let text: String
        switch code {
        case .invalidSettings: text = L("Conversion settings are invalid.")
        case .unsupportedFormat: text = L("This format is not supported.")
        case .unreadableSource: text = L("The source file cannot be read.")
        case .emptySource: text = L("The source file is empty.")
        case .inputTooLarge: text = L("The source file is too large.")
        case .missingEngine: text = L("A required conversion engine is not installed.")
        case .noAudioTrack: text = L("This video has no audio track.")
        case .invalidImage: text = L("The image cannot be read or written.")
        case .invalidSVG: text = L("The SVG cannot be converted.")
        case .externalSVGResource: text = L("The SVG uses external content, which is not supported.")
        case .unsupportedSVGContent: text = L("The SVG uses unsupported content.")
        case .outputLimit: text = L("The requested output exceeds the supported size limits.")
        case .inputLimit: text = L("The source image exceeds the supported size limits.")
        case .outputNotWritable: text = L("The output folder cannot be written to.")
        case .diskFull: text = L("The destination disk is full.")
        case .outputVolumeUnsupported: text = L("The output folder is on a volume without safe publication support.")
        case .outputVerification: text = L("The converted output could not be verified.")
        case .timeout: text = L("The conversion timed out.")
        case .engineFailure: text = L("The conversion engine failed.")
        case .sourceChanged: text = L("The source file changed during conversion.")
        case .unknown: text = L("The conversion failed.")
        }
        if code == .engineFailure, let detail, !detail.isEmpty {
            return text + "\n" + detail
        }
        return text
    }
}
