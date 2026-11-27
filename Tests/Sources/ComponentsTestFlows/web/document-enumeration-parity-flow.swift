import DSL
import HTML
import References
import TestFlows
import WebComponents

/// The StructuredContent enumeration pass numbers citations and footnotes
/// exactly as the HTML `CitationResolver` does (D9 parity).
enum DocumentEnumerationParityFlowSuite: TestFlowRegistry {
    static let title = "Document enumeration parity"

    static let flows: [TestFlow] = [
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
