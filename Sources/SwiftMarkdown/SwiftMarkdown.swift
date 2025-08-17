import cmark_gfm
#if os(Android) || os(Linux)
import Glibc
#endif

public enum MarkdownError: Error {
    case conversionFailed
}

public struct MarkdownOptions: OptionSet {
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    static public let sourcePosition = MarkdownOptions(rawValue: 1 << 1)
    static public let hardBreaks = MarkdownOptions(rawValue: 1 << 2)
    static public let safe = MarkdownOptions(rawValue: 1 << 3)
    static public let noBreaks = MarkdownOptions(rawValue: 1 << 4)
    static public let normalize = MarkdownOptions(rawValue: 1 << 8)
    static public let validateUTF8 = MarkdownOptions(rawValue: 1 << 9)
    static public let smartQuotes = MarkdownOptions(rawValue: 1 << 10)
    static public let unsafe = MarkdownOptions(rawValue: 1 << 17)
}

public func markdownToHTML_GFM(
    _ markdown: String,
    options: MarkdownOptions = [.safe],
    enable: [String] = ["table", "strikethrough", "autolink", "tasklist"]
) throws -> String {

    // 2) Create a parser with your options
    guard let parser = cmark_parser_new(options.rawValue) else {
        throw MarkdownError.conversionFailed
    }
    defer { cmark_parser_free(parser) }

    // 3) Attach requested extensions (ignore unknown names safely)
    for name in enable {
        if let ext = cmark_find_syntax_extension(name) {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
    }

    // 4) Feed source and finish
    markdown.withCString { cstr in
        cmark_parser_feed(parser, cstr, strlen(cstr))
    }
    guard let doc = cmark_parser_finish(parser) else {
        throw MarkdownError.conversionFailed
    }
    defer { cmark_node_free(doc) }

    // 5) Render to HTML
    guard let htmlC = cmark_render_html(doc, options.rawValue, nil) else {
        throw MarkdownError.conversionFailed
    }
    defer { free(htmlC) }

    return String(cString: htmlC)
}
