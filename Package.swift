// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TranscodePilot",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TranscodePilot", targets: ["TranscodePilot"]),
               .executable(name: "TranscodePilotChecks", targets: ["TranscodePilotChecks"])],
    targets: [
        .target(name: "TranscodePilotCore"),
        .executableTarget(name: "TranscodePilot", dependencies: ["TranscodePilotCore"], resources: [.copy("Resources")]),
        .executableTarget(name: "TranscodePilotChecks", dependencies: ["TranscodePilotCore"],
                          resources: [.copy("Fixtures")])
    ],
    swiftLanguageModes: [.v5]
)
