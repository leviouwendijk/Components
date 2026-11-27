import DSL
import HTML
import Provenance
import References
import TestFlows
import WebComponents

/// The StructuredContent enumeration pass numbers citations and footnotes
/// exactly as the HTML `CitationResolver` does (D9 parity).
enum DocumentEnumerationParityFlowSuite: TestFlowRegistry {
    static let title = "Document enumeration parity"

    static let flows: [TestFlow] = [
        TestFlow(
            "docs-provenance-card",
            title: "The AI notice renders typed provenance",
            tags: [
                "provenance",
                "docs",
            ]
        ) {
            let provenance = try Provenance(
                .init(
                    involvement: .drafted,
                    control: .instructed(by: .init(rawValue: "Levi")),
                    sources: [.sessions(count: 14, years: 2025...2026), .literature],
                    redaction: .init(.aggregated, by: .automaticChecked(by: .init(rawValue: "Casper"))),
                    review: .reviewed(by: .init(rawValue: "Casper"), on: "2026-11-12"),
                    audience: .public
                )
            )

            let card = DocsAIContentNotice(
                provenance: provenance,
                language: .dutch,
                lexicon: .dutch,
                includeStyles: false
            ).node().render(options: .init(), indent: 0)

            try Expect.true(
                card.contains("Opgesteld met AI in opdracht van Levi, op basis van 14 sessietranscripten (2025–2026) en literatuur; geaggregeerd, nagelezen door Casper op 12-11-2026."),
                "provenance.card.sentence"
            )
            try Expect.true(
                card.contains("<details") && card.contains("<summary") && card.contains("Details"),
                "provenance.card.details"
            )
            try Expect.true(
                card.contains("Automatisch, gecontroleerd door Casper"),
                "provenance.card.redaction-method"
            )

            let generic = DocsAIContentNotice(
                lexicon: .dutch,
                includeStyles: false
            ).node().render(options: .init(), indent: 0)

            try Expect.true(
                !generic.contains("<details"),
                "provenance.card.generic-unchanged"
            )

            return []
        },
        TestFlow(
            "document-enumeration-citation-resolver-parity",
            title: "Enumeration matches CitationResolver numbering",
            tags: [
                "enumeration",
                "citation",
                "parity",
            ]
        ) {
            let page = ReferenceLocator(.page, "12")

            let html: HTMLFragment = [
                HTMLElement(
                    "p",
                    children: [
                        HTMLText("Cortisol "),
                        Citation(_TestRefs.beyond_cortisol, at: page),
                        HTMLText(" and an example "),
                        Citation(_TestRefs.some_ref_example),
                        Footnote("A footnote."),
                    ]
                ),
                HTMLElement(
                    "p",
                    children: [
                        HTMLText("Again "),
                        Citation(_TestRefs.beyond_cortisol, at: page),
                        Citation(_TestRefs.beyond_cortisol),
                        Footnote("Another."),
                        Citation(_TestRefs.some_ref_example),
                    ]
                ),
            ]

            let content = StructuredContent.collection([
                .prose("Cortisol \(cite: _TestRefs.beyond_cortisol, at: page) and an example \(cite: _TestRefs.some_ref_example)\(note: "A footnote.")"),
                .prose("Again \(cite: _TestRefs.beyond_cortisol, at: page)\(cite: _TestRefs.beyond_cortisol)\(note: "Another.")\(cite: _TestRefs.some_ref_example)"),
            ])

            let legacy = CitationResolver.resolve(from: html)
            let resolved = StructuredContentEnumerations.resolve(
                content,
                bibliography: ReferenceBibliography().adding(_TestRefs.self)
            )
            let tables = resolved.enumerations

            try Expect.equal(
                tables.citations.entries.map(\.key.rawValue),
                legacy.references.map(\.reference.public_name_or_id),
                "parity.reference-order"
            )
            try Expect.equal(
                tables.citations.entries.map(\.occurrences),
                legacy.references.map(\.pointers),
                "parity.pointers"
            )
            try Expect.equal(
                tables.footnotes.map(\.number),
                legacy.footnotes.map(\.number),
                "parity.footnotes"
            )
            try Expect.equal(
                legacy.references.map { reference in
                    reference.comments.map(\.pointers)
                },
                tables.citations.entries.map { entry in
                    (tables.citationUses[entry.key] ?? []).map(\.pointers)
                },
                "parity.locator-uses"
            )

            guard case .collection(let blocks) = resolved.content,
                  case .notes(let bibliography) = blocks.last,
                  case .paragraph(let entry) = bibliography.first?.content,
                  case .link(.external(let url), _) = entry.first
            else {
                throw TestFlowAssertionFailure(
                    label: "parity.bibliography",
                    message: "expected an appended bibliography with linked entries"
                )
            }

            try Expect.equal(
                url,
                _TestRefs.beyond_cortisol.url,
                "parity.bibliography.entry"
            )

            return [
                .field(
                    "pointers",
                    "\(legacy.references.map(\.pointers))"
                ),
                .field(
                    "footnotes",
                    "\(legacy.footnotes.map(\.number))"
                ),
            ]
        },
    ]
}
