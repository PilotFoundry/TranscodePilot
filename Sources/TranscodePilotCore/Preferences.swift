import Foundation

/// Restores stored preferences without ever handing an unbounded value to the
/// UI or to the conversion guards.
public enum PreferenceDefaults {
    public static let scale: Double = 2
    public static let jpegQuality: Double = 0.9
    public static let audioBitrate: Int = 192
    public static let allowedScales: [Double] = [1, 2, 4]
    public static let allowedAudioBitrates = [128, 192, 320]

    public static func sanitizedScale(_ stored: Double?) -> Double {
        guard let value = stored, value.isFinite, allowedScales.contains(value) else {
            return scale
        }
        return value
    }

    public static func sanitizedJPEGQuality(_ stored: Double?) -> Double {
        guard let value = stored, value.isFinite else {
            return jpegQuality
        }
        return min(max(value, 0.1), 1)
    }

    public static func sanitizedAudioBitrate(_ stored: Int?) -> Int {
        guard let value = stored, allowedAudioBitrates.contains(value) else {
            return audioBitrate
        }
        return value
    }
}
