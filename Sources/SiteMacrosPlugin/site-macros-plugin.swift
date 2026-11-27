import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SiteMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SiteMacro.self,
        PageMacro.self,
        SectionMacro.self,
    ]
}

enum SiteMacroError: Error, CustomStringConvertible {
    case hostRequired
    case memberNeedsType(String)
    case indexOutsideRoot(String)
    case duplicateRoute(String, [String])
    case markerMissing(String)
    case outsideSite(String)

    var description: String {
        switch self {
        case .hostRequired:
            "@Site needs the site's host as a string literal: @Site(\"example.com\")."
        case .memberNeedsType(let name):
            "Page member '\(name)' must be declared 'static var \(name): SitePage'."
        case .indexOutsideRoot(let name):
            "@Index '\(name)' is the site's root page; declare it directly in the @Site type, not in a section."
        case .duplicateRoute(let route, let members):
            "Route '\(route)' is declared more than once: \(members.joined(separator: ", "))."
        case .markerMissing(let name):
            "'\(name)' has no @Page, @Index or @Section attribute."
        case .outsideSite(let name):
            "'\(name)' must be declared inside an @Site type."
        }
    }
}

// MARK: - @Site

public struct SiteMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let host = try SiteSyntax.host(node)
        let access = SiteSyntax.access(declaration.modifiers)
        let pages = try SiteSyntax.pages(in: declaration.memberBlock, prefix: [], parent: [], root: true)

        var routes: [String: [String]] = [:]
        for page in pages {
            routes[SiteSyntax.route(page.path), default: []].append(page.expression)
        }
        if let (route, members) = routes.first(where: { $0.value.count > 1 }) {
            throw SiteMacroError.duplicateRoute(route, members)
        }

        let list = pages.map { "Self." + $0.expression }.joined(separator: ", ")

        return [
            "\(raw: access)static let host = \(literal: host)",
            "\(raw: access)static var pages: [SitePage] { [\(raw: list)] }",
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [try ExtensionDeclSyntax("extension \(type.trimmed): Site {}")]
    }
}

// MARK: - Pages and sections

/// `@Page` / `@Index`: the member's getter. Host and parent path come from
/// the enclosing `@Section` types and the `@Site` type.
public struct PageMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let name = SiteSyntax.name(variable)
        else {
            return []
        }

        guard variable.bindings.first?.typeAnnotation != nil else {
            throw SiteMacroError.memberNeedsType(name)
        }

        guard let marker = SiteSyntax.marker(variable.attributes) else {
            throw SiteMacroError.markerMissing(name)
        }

        let (host, parent) = try SiteSyntax.enclosing(context, name: name)

        if marker.isIndex, !parent.isEmpty {
            throw SiteMacroError.indexOutsideRoot(name)
        }

        let path = marker.isIndex ? [] : parent + [marker.segment ?? SiteSyntax.kebab(name)]

        return [
            """
            get {
                SitePage(host: \(literal: host), path: \(raw: SiteSyntax.array(path)), title: \(raw: marker.title), summary: \(raw: marker.summary))
            }
            """,
        ]
    }
}

/// `@Section`: the section's own page, `index`.
public struct SectionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let marker = SiteSyntax.marker(declaration.attributes),
              let (name, _) = SiteSyntax.typeDeclaration(declaration)
        else {
            return []
        }

        let (host, parent) = try SiteSyntax.enclosing(context, name: name)
        let path = parent + [marker.segment ?? SiteSyntax.kebab(name)]
        let access = SiteSyntax.access(declaration.modifiers)

        return [
            """
            \(raw: access)static var index: SitePage {
                SitePage(host: \(literal: host), path: \(raw: SiteSyntax.array(path)), title: \(raw: marker.title), summary: \(raw: marker.summary))
            }
            """,
        ]
    }
}

// MARK: - Syntax

enum SiteSyntax {
    struct Marker {
        var isIndex = false
        var isSection = false
        var segment: String?
        var title = "\"\""
        var summary = "nil"
    }

    struct Page {
        let expression: String
        let path: [String]
    }

    static func host(_ node: AttributeSyntax) throws -> String {
        guard let first = node.arguments?.as(LabeledExprListSyntax.self)?.first,
              let value = stringValue(first.expression)
        else {
            throw SiteMacroError.hostRequired
        }
        return value
    }

    /// The host of the enclosing `@Site` type and the segments of the
    /// `@Section` types between it and the declaration, outermost first.
    static func enclosing(
        _ context: some MacroExpansionContext,
        name: String
    ) throws -> (String, [String]) {
        var sections: [String] = []

        for element in context.lexicalContext {
            guard let (typeName, attributes) = typeDeclaration(element) else {
                continue
            }

            if let site = siteAttribute(attributes) {
                return (try host(site), sections.reversed())
            }

            if let marker = marker(attributes), marker.isSection {
                sections.append(marker.segment ?? kebab(typeName))
            }
        }

        throw SiteMacroError.outsideSite(name)
    }

    static func siteAttribute(_ attributes: AttributeListSyntax) -> AttributeSyntax? {
        for element in attributes {
            if let attribute = element.as(AttributeSyntax.self),
               attribute.attributeName.trimmedDescription == "Site"
            {
                return attribute
            }
        }
        return nil
    }

    /// The marker attribute (`@Page`, `@Index`, `@Section`) and its arguments.
    static func marker(_ attributes: AttributeListSyntax) -> Marker? {
        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else { continue }
            let name = attribute.attributeName.trimmedDescription

            guard name == "Page" || name == "Index" || name == "Section" else { continue }

            var marker = Marker()
            marker.isIndex = name == "Index"
            marker.isSection = name == "Section"

            for argument in attribute.arguments?.as(LabeledExprListSyntax.self) ?? [] {
                switch argument.label?.text {
                case nil:
                    marker.segment = stringValue(argument.expression)
                case "title":
                    marker.title = argument.expression.trimmedDescription
                case "summary":
                    marker.summary = argument.expression.trimmedDescription
                default:
                    break
                }
            }

            return marker
        }

        return nil
    }

    /// Every page under `members`, depth first, with the expression that
    /// names it from the site type.
    static func pages(
        in members: MemberBlockSyntax,
        prefix: [String],
        parent: [String],
        root: Bool
    ) throws -> [Page] {
        var result: [Page] = []

        for item in members.members {
            let decl = item.decl

            if let variable = decl.as(VariableDeclSyntax.self),
               let marker = marker(variable.attributes),
               let name = name(variable)
            {
                if marker.isIndex, !root {
                    throw SiteMacroError.indexOutsideRoot(name)
                }
                let path = marker.isIndex ? [] : parent + [marker.segment ?? kebab(name)]
                result.append(.init(expression: (prefix + [name]).joined(separator: "."), path: path))
                continue
            }

            if let (name, attributes) = typeDeclaration(decl),
               let marker = marker(attributes),
               marker.isSection,
               let block = memberBlock(decl)
            {
                let path = parent + [marker.segment ?? kebab(name)]
                result.append(.init(expression: (prefix + [name, "index"]).joined(separator: "."), path: path))
                result += try pages(in: block, prefix: prefix + [name], parent: path, root: false)
            }
        }

        return result
    }

    static func typeDeclaration(_ decl: some SyntaxProtocol) -> (String, AttributeListSyntax)? {
        if let type = decl.as(EnumDeclSyntax.self) { return (type.name.text, type.attributes) }
        if let type = decl.as(StructDeclSyntax.self) { return (type.name.text, type.attributes) }
        return nil
    }

    static func memberBlock(_ decl: some DeclSyntaxProtocol) -> MemberBlockSyntax? {
        decl.as(EnumDeclSyntax.self)?.memberBlock ?? decl.as(StructDeclSyntax.self)?.memberBlock
    }

    static func name(_ variable: VariableDeclSyntax) -> String? {
        variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    static func access(_ modifiers: DeclModifierListSyntax) -> String {
        modifiers.contains { $0.name.text == "public" } ? "public " : ""
    }

    static func stringValue(_ expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self) else { return nil }
        return literal.segments.compactMap {
            $0.as(StringSegmentSyntax.self)?.content.text
        }.joined()
    }

    static func array(_ path: [String]) -> String {
        "[" + path.map { "\"" + $0 + "\"" }.joined(separator: ", ") + "]"
    }

    static func route(_ path: [String]) -> String {
        path.isEmpty ? "/" : "/" + path.joined(separator: "/") + "/"
    }

    /// `priveLes` → `prive-les`, `Aanbod` → `aanbod`.
    static func kebab(_ name: String) -> String {
        var result = ""
        for (index, character) in name.enumerated() {
            if character.isUppercase {
                if index > 0 { result.append("-") }
                result.append(Character(character.lowercased()))
            } else {
                result.append(character)
            }
        }
        return result
    }
}
