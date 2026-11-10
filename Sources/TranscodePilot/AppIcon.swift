import AppKit

enum AppIcon {
    static var image: NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let resources = Bundle.main.resourceURL {
            let url = resources.appendingPathComponent("AppIcon.icns")
            if let image = NSImage(contentsOf: url) { return image }
        }
        if let moduleResources = Bundle.module.url(forResource: "Resources", withExtension: nil) {
            let url = moduleResources.appendingPathComponent("AppIcon.icns")
            if let image = NSImage(contentsOf: url) { return image }
        }
        return nil
    }
}
