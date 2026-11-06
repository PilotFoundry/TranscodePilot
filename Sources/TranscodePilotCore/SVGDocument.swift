import Foundation

final class SVGDocument: NSObject, XMLParserDelegate {
    var failure: String?
    var root = false
    var size: CGSize?
    var styleText = ""
    var inStyle = false

    static func validate(_ data: Data) throws -> CGSize {
        guard data.count <= 20_000_000, let text = String(data: data, encoding: .utf8) else {
            throw ConversionError.message("SVG must be UTF-8 and smaller than 20 MB.")
        }
        // External resources and CSS escapes are rejected rather than silently omitted.
        let lower = text.lowercased()
        for token in ["<!doctype", "<!entity", "@import", "@font-face", "\\", "xml-stylesheet"] {
            if lower.contains(token) { throw ConversionError.message("SVG contains unsupported or external resources: \(token)") }
        }
        guard !hasExternalURL(text) else { throw ConversionError.message("SVG external CSS resources are not supported.") }
        let delegate = SVGDocument()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse(), delegate.root, delegate.failure == nil else {
            throw ConversionError.message(delegate.failure ?? "Invalid SVG document.")
        }
        guard let size = delegate.size, size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else {
            throw ConversionError.message("SVG needs positive pixel dimensions or a viewBox.")
        }
        return size
    }

    static func hasExternalURL(_ text: String) -> Bool {
        let expression = try! NSRegularExpression(pattern: #"url\s*\(\s*['\"]?\s*([^)'\"\s]+)"#, options: [.caseInsensitive])
        return expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).contains { match in
            guard let range = Range(match.range(at: 1), in: text) else { return true }
            return !text[range].hasPrefix("#")
        }
    }

    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        let name = element.lowercased().split(separator: ":").last.map(String.init) ?? element
        if name == "style" { inStyle = true; styleText = "" }
        if !root {
            guard name == "svg" else { failure = "Expected an SVG document."; parser.abortParsing(); return }
            root = true
            let viewBox = (attributes["viewBox"] ?? "").split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
            func dimension(_ key: String) -> Double? {
                guard let text = attributes[key] else { return nil }
                return Double(text.replacingOccurrences(of: "px", with: "").trimmingCharacters(in: .whitespaces))
            }
            if let width = dimension("width"), let height = dimension("height") {
                size = CGSize(width: width, height: height)
            } else if viewBox.count == 4 { size = CGSize(width: viewBox[2], height: viewBox[3]) }
            for key in ["width", "height"] {
                if let raw = attributes[key], let value = Double(raw.replacingOccurrences(of: "px", with: "")), value > 16384 {
                    failure = "SVG source dimensions exceed 16,384 pixels."; parser.abortParsing(); return
                }
            }
        }
        if ["script", "foreignobject", "animate", "animatetransform", "set"].contains(name) {
            failure = "SVG HTML, scripts and animations are not supported."; parser.abortParsing(); return
        }
        for (key, value) in attributes {
            if Self.hasExternalURL(value) || value.contains("\\") {
                failure = "SVG external paint resources are not supported."; parser.abortParsing(); return
            }
            if key.lowercased().hasPrefix("on") || key.lowercased() == "xml:base" {
                failure = "SVG scripting and external base paths are not supported."; parser.abortParsing(); return
            }
            if key.lowercased().hasSuffix("href"), !value.hasPrefix("#") {
                // shortcut: embedded/external images are excluded until resource decoding is isolated.
                failure = "SVG linked or embedded resources are not supported. Embed shapes as paths."; parser.abortParsing()
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inStyle { styleText += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName.lowercased().hasSuffix("style") {
            if Self.hasExternalURL(styleText) || styleText.contains("\\") || styleText.contains("@") {
                failure = "SVG external styles are not supported."; parser.abortParsing()
            }
            inStyle = false
        }
    }
}
