import Foundation

enum ProjectLinks {
    static let repository: URL = {
        let configured = Bundle.main.object(forInfoDictionaryKey: "TPProjectURL") as? String
        let fallback = "https://github.com/PilotFoundry/TranscodePilot"
        return URL(string: configured ?? fallback) ?? URL(string: fallback)!
    }()

    static var issues: URL { repository.appendingPathComponent("issues") }
    static var repositoryDisplay: String {
        repository.absoluteString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
