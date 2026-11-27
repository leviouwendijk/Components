import DSL
import HTML

/// StructuredContent lowered to HTML nodes, for pages. Links and images go
/// through the shared capability rules and a resolver (route table, asset
/// catalog); citations and footnotes are expected to be enumerated first
/// (`StructuredContentEnumerations.resolve`), and fall back to their plain
/// forms otherwise. Group roles become `data-role`, so a theme styles them.
public struct StructuredContentHTML:
    Sendable
{
    public let resolver: any StructuredContentURLResolving
    public let capabilities: RenderCapabilities

    public init(
        resolver: any StructuredContentURLResolving = StructuredContentURLTable(),
        capabilities: RenderCapabilities = .staticHTML
    ) {
        self.resolver = resolver
        self.capabilities = capabilities
    }

    public func nodes(
        _ content: StructuredContent
    ) -> HTMLFragment {
        switch content {
        case .collection(let children):
            return children.flatMap(nodes)

        case .paragraph(let inlines):
            return [element("p", inline(inlines))]

        case .code(let language, let source):
            let attrs: HTMLAttribute = language.map { ["class": "language-" + $0] } ?? [:]
            return [element("pre", [element("code", attrs: attrs, [HTMLText(source)])])]

        case .quote(let inner, let attribution):
            let quote = element("blockquote", nodes(inner))
            guard let attribution else { return [quote] }
            return [
                element(
                    "figure",
                    attrs: ["class": "quote"],
                    [quote, element("figcaption", [HTMLText("— ")] + inline(attribution))]
                ),
            ]

        case .list(let style, let items):
            return [element(style == .ordered ? "ol" : "ul", items.map { element("li", nodes($0)) })]

        case .group(let role, let title, let inner):
            var children: HTMLFragment = []
            if let title {
                children.append(element("p", attrs: ["class": "group-title"], inline(title)))
            }
            children += nodes(inner)
            let tag = role.map(Self.isAside) == true ? "aside" : "div"
            let attrs: HTMLAttribute = role.map { ["data-role": $0.rawValue] } ?? [:]
            return [element(tag, attrs: attrs, children)]

        case .table(let header, let rows):
            return [
                element("table", [
                    element("thead", [element("tr", header.map { element("th", nodes($0)) })]),
                    element("tbody", rows.map { row in element("tr", row.map { element("td", nodes($0)) }) }),
                ]),
            ]

        case .heading(let level, let anchor, let content):
            let attrs: HTMLAttribute = anchor.map { ["id": $0.rawValue] } ?? [:]
            return [element("h\(StructuredContentFallback.headingLevel(level))", attrs: attrs, inline(content))]

        case .image(let source, let alt):
            return [image(source, alt: alt)]

        case .figure(let anchor, let content, let caption):
            var children = nodes(content)
            if let caption {
                children.append(element("figcaption", inline(caption)))
            }
            let attrs: HTMLAttribute = anchor.map { ["id": $0.rawValue] } ?? [:]
            return [element("figure", attrs: attrs, children)]

        case .verse(let lines):
            var children: HTMLFragment = []
            for (index, line) in lines.enumerated() {
                if index > 0 { children.append(HTMLElement("br")) }
                children += verseLine(line)
            }
            return [element("p", attrs: ["class": "verse"], children)]

        case .rule:
            return [HTMLElement("hr")]

        case .definitions(let definitions):
            return [
                element("dl", definitions.flatMap {
                    [element("dt", inline($0.term)), element("dd", nodes($0.description))]
                }),
            ]

        case .listing:
            return []

        case .notes(let notes):
            return [
                element("ul", attrs: ["class": "notes"], notes.map { note in
                    var children: HTMLFragment = [element("span", attrs: ["class": "note-label"], [HTMLText(note.label)])]
                    if case .paragraph(let inlines) = note.content {
                        children += [HTMLText(" ")] + inline(inlines)
                    } else {
                        children += nodes(note.content)
                    }
                    if !note.uses.isEmpty {
                        children.append(
                            element("span", attrs: ["class": "note-uses"], [
                                HTMLText(" " + note.uses.map(\.rendered).joined(separator: "; ")),
                            ])
                        )
                    }
                    return element("li", attrs: ["id": note.anchor.rawValue], children)
                }),
            ]

        case .native(_, _, let fallback):
            return nodes(fallback)
        }
    }

    public func inline(
        _ inlines: [StructuredContent.Inline]
    ) -> HTMLFragment {
        inlines.flatMap(inline)
    }

    public func inline(
        _ value: StructuredContent.Inline
    ) -> HTMLFragment {
        switch value {
        case .text(let text):
            return [HTMLText(text)]
        case .code(let code):
            return [element("code", [HTMLText(code)])]
        case .emphasis(let inner):
            return [element("em", inline(inner))]
        case .strong(let inner):
            return [element("strong", inline(inner))]
        case .link(let target, let inner):
            switch capabilities.link(target, content: inner, resolver: resolver) {
            case .hyperlink(let url):
                return [element("a", attrs: ["href": url], inline(inner))]
            case .textWithURL(let url):
                return inline(inner) + [HTMLText(" (\(url))")]
            case .text:
                return inline(inner)
            }
        case .citation(let key, let locators):
            return [HTMLText(StructuredContentFallback.citation(key: key, locators: locators))]
        case .footnote(let content):
            return [HTMLText(" (" + content.plainText + ")")]
        case .noteReference(let number, let anchor):
            return [
                element("sup", attrs: ["class": "note-ref"], [
                    element("a", attrs: ["href": "#" + anchor.rawValue], [HTMLText("\(number)")]),
                ]),
            ]
        }
    }

    private func image(
        _ source: StructuredContent.ImageSource,
        alt: String
    ) -> any HTMLNode {
        switch capabilities.image(source, resolver: resolver) {
        case .image(let url):
            return HTMLElement("img", attrs: ["src": url, "alt": alt])
        case .link(let url):
            return element("a", attrs: ["href": url], [HTMLText(alt)])
        case .alt:
            return element("em", [HTMLText(alt)])
        }
    }

    /// Leading spaces kept as no-break spaces.
    private func verseLine(
        _ line: [StructuredContent.Inline]
    ) -> HTMLFragment {
        guard case .text(let first) = line.first else {
            return inline(line)
        }

        let lead = first.prefix { $0 == " " }.count
        guard lead > 0 else { return inline(line) }

        return [HTMLText(String(repeating: "\u{00A0}", count: lead) + first.dropFirst(lead))]
            + inline(Array(line.dropFirst()))
    }

    private func element(
        _ tag: String,
        attrs: HTMLAttribute = [:],
        _ children: HTMLFragment
    ) -> HTMLElement {
        HTMLElement(tag, attrs: attrs, children: children)
    }

    private static func isAside(
        _ role: StructuredContent.Role
    ) -> Bool {
        [.note, .tip, .warning, .caution, .epigraph].contains(role)
    }
}
