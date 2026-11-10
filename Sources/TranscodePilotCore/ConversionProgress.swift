import Foundation

public enum ConversionPhase: String, Sendable {
    case preparing
    case reading
    case rendering
    case decoding
    case encoding
    case verifying
    case publishing
}

public struct ConversionProgress: Sendable {
    public let fraction: Double
    public let phase: ConversionPhase

    public init(fraction: Double, phase: ConversionPhase) {
        self.fraction = min(max(fraction, 0), 1)
        self.phase = phase
    }
}

public typealias ConversionProgressHandler = @Sendable (ConversionProgress) -> Void
