import DSL
import SiteMacros
import TestFlows

enum FixtureSites {}

extension FixtureSites {
    @Site("fixture.example")
    enum shop {
        @Index(title: "Shop")
        static var home: Site.Page

        @Section(title: "Offer", summary: "What we offer")
        enum offer {
            @Page(title: "Consult")
            static var consult: Site.Page

            @Page("private-lesson", title: "Private lesson")
            static var privateLesson: Site.Page

            @Section(title: "Courses")
            enum group_courses {
                @Page(title: "Puppy course")
                static var puppyCourse: Site.Page
            }
        }

        @Page(title: "Contact")
        static var contact: Site.Page
    }
}

enum SiteMacroFlowSuite: TestFlowRegistry {
    static let title = "Site macros"

    static let flows: [TestFlow] = [
        TestFlow(
            "site-macros",
            title: "@Site derives routes from member names and nesting",
            tags: [
                "site",
                "macros",
            ]
        ) {
            typealias Shop = FixtureSites.shop

            try Expect.equal(Shop.host, "fixture.example", "site-macros.host")
            try Expect.equal(
                Shop.pages.map(\.href),
                [
                    "/",
                    "/offer/",
                    "/offer/consult/",
                    "/offer/private-lesson/",
                    "/offer/group-courses/",
                    "/offer/group-courses/puppy-course/",
                    "/contact/",
                ],
                "site-macros.routes"
            )
            try Expect.equal(Shop.offer.index.summary, "What we offer", "site-macros.section-index")
            try Expect.equal(Shop.offer.group_courses.puppyCourse.title, "Puppy course", "site-macros.nested-page")
            try Expect.equal(
                try Shop.pageTree().children.map(\.identifier.rawValue),
                ["offer", "contact"],
                "site-macros.tree"
            )

            let link = StructuredContent.prose("Book a \(link: "consult", to: Shop.offer.consult).")
            guard case .paragraph(let inlines) = link,
                  case .link(.page(let key, _), _) = inlines[1]
            else {
                throw TestFlowAssertionFailure(label: "site-macros.link", message: "expected a page link")
            }
            try Expect.equal(key.rawValue, "fixture.example/offer/consult", "site-macros.link-key")

            return [
                .field("pages", "\(Shop.pages.count)"),
            ]
        },
    ]
}
