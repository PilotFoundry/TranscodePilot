import Foundation

final class SVGDocument: NSObject, XMLParserDelegate {
    var failure: String?
    var root = false
    var size: CGSize?
    var styleText = ""
    var inStyle = false

    private enum Length {
        case pixels(Double)
        case percent(Double)
    }

    private static let lengthExpression = try! NSRegularExpression(
        pattern: #"^\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*([a-zA-Z%]*)\s*$"#
    )

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
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        guard parser.parse(), delegate.root, delegate.failure == nil else {
            throw ConversionError.message(delegate.failure ?? "Invalid SVG document.")
        }
        guard let size = delegate.size, size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else {
            throw ConversionError.message(delegate.failure ?? "SVG needs positive pixel dimensions or a viewBox.")
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

    private static func parseLength(_ raw: String) -> Length? {
        let nsRange = NSRange(raw.startIndex..., in: raw)
        guard let match = lengthExpression.firstMatch(in: raw, range: nsRange),
              let numberRange = Range(match.range(at: 1), in: raw),
              let unitRange = Range(match.range(at: 2), in: raw),
              let number = Double(raw[numberRange]), number.isFinite else {
            return nil
        }
        let unit = raw[unitRange].lowercased()
        // CSS absolute units use the CSS 96 dpi reference pixel. Unitless values
        // and px are already CSS pixels.
        switch unit {
        case "", "px":
            return .pixels(number)
        case "in":
            return .pixels(number * 96)
        case "cm":
            return .pixels(number * 96 / 2.54)
        case "mm":
            return .pixels(number * 96 / 25.4)
        case "pt":
            return .pixels(number * 96 / 72)
        case "pc":
            return .pixels(number * 16)
        case "q":
            return .pixels(number * 96 / 101.6)
        case "%":
            return .percent(number)
        default:
            return nil
        }
    }

    private static func resolved(_ length: Length?, reference: Double?) -> Double? {
        switch length {
        case .pixels(let value):
            return value
        case .percent(let value):
            return reference.map { value / 100 * $0 }
        case nil:
            return nil
        }
    }

    private static func intrinsicSize(width rawWidth: String?, height rawHeight: String?,
                                      viewBox rawViewBox: String?) -> CGSize? {
        let widthLength = rawWidth.flatMap(parseLength)
        let heightLength = rawHeight.flatMap(parseLength)
        if rawWidth != nil && widthLength == nil { return nil }
        if rawHeight != nil && heightLength == nil { return nil }
        let values = (rawViewBox ?? "").split(whereSeparator: { $0.isWhitespace || $0 == "," }).compactMap { Double($0) }
        let viewBox = values.count == 4 ? values : nil
        let viewWidth = viewBox.map { $0[2] }
        let viewHeight = viewBox.map { $0[3] }

        var width = resolved(widthLength, reference: viewWidth)
        var height = resolved(heightLength, reference: viewHeight)

        if values.count == 4, values[2] > 0, values[3] > 0 {
            let vbWidth = values[2]
            let vbHeight = values[3]
            if width == nil && height == nil {
                width = vbWidth
                height = vbHeight
            } else if width == nil, let height {
                width = height * vbWidth / vbHeight
            } else if height == nil, let width {
                height = width * vbHeight / vbWidth
            }
        }

        guard let width, let height, width.isFinite, height.isFinite, width > 0, height > 0 else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        let name = element.lowercased().split(separator: ":").last.map(String.init) ?? element
        if name == "style" { inStyle = true; styleText = "" }
        if !root {
            guard name == "svg" else { failure = "Expected an SVG document."; parser.abortParsing(); return }
            if let namespaceURI, !namespaceURI.isEmpty, namespaceURI != "http://www.w3.org/2000/svg" {
                failure = "SVG root must use the SVG namespace."
                parser.abortParsing()
                return
            }
            root = true
            if let size = Self.intrinsicSize(width: attributes["width"], height: attributes["height"],
                                             viewBox: attributes["viewBox"]) {
                self.size = size
            } else if attributes["width"]?.contains("%") == true || attributes["height"]?.contains("%") == true {
                failure = "SVG percentage dimensions require a viewBox."
                parser.abortParsing()
                return
            } else {
                failure = "SVG needs positive pixel dimensions or a viewBox."
                parser.abortParsing()
                return
            }
        }
        if ["script", "foreignobject", "animate", "animatetransform", "animatecolor",
            "animatemotion", "set", "discard", "handler", "listener"].contains(name) {
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

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if inStyle, let text = String(data: CDATABlock, encoding: .utf8) {
            styleText += text
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName.lowercased().hasSuffix("style") {
            // @import/@font-face are rejected by the document-wide lexical scan;
            // self-contained at-rules such as @media must remain usable.
            if Self.hasExternalURL(styleText) || styleText.contains("\\") {
                failure = "SVG external styles are not supported."; parser.abortParsing()
            }
            inStyle = false
        }
    }
}
