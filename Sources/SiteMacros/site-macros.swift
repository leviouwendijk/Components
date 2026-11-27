@_exported import Constructors

/// A site: its pages are the `@Index`, `@Page` and `@Section` members of
/// the type, nested as the types nest.
///
///     @Site("hondenmeesters.nl")
///     public enum Hondenmeesters {
///         @Index(title: "Hondenmeesters") static var home: SitePage
///
///         @Section(title: "Aanbod")                 // /aanbod/ (its `index`)
///         public enum Aanbod {
///             @Page(title: "Consult") static var consult: SitePage   // /aanbod/consult/
///             @Page("prive-les", title: "Privéles") static var priveLes: SitePage
///         }
///     }
///
/// A member's name is its route segment (camelCase becomes kebab-case);
/// a string argument overrides it. Generates the `Site` conformance, `host`
/// and `declaredPages` (and `pages`, unless the type declares its own to
/// add pages from data); two pages on one route are a compile error.
@attached(member, names: named(host), named(declaredPages), named(pages))
@attached(extension, conformances: Site)
public macro Site(
    _ host: String
) = #externalMacro(
    module: "SiteMacrosPlugin",
    type: "SiteMacro"
)

/// The site's root page (`/`), declared directly in the `@Site` type.
@attached(accessor)
public macro Index(
    title: String,
    summary: String? = nil
) = #externalMacro(
    module: "SiteMacrosPlugin",
    type: "PageMacro"
)

/// A page; its segment is the member's name unless given.
@attached(accessor)
public macro Page(
    _ segment: String? = nil,
    title: String,
    summary: String? = nil
) = #externalMacro(
    module: "SiteMacrosPlugin",
    type: "PageMacro"
)

/// A section: a type whose members are its pages, and which is a page
/// itself (its generated `index`).
@attached(member, names: named(index))
public macro Section(
    _ segment: String? = nil,
    title: String,
    summary: String? = nil
) = #externalMacro(
    module: "SiteMacrosPlugin",
    type: "SectionMacro"
)
