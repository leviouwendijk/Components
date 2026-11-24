import TestFlows

@main
enum ComponentsFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite:
                ComponentsFlowSuite.self
        )
    }
}

enum ComponentsFlowSuite:
    TestFlowRegistry
{
    static let title =
        "Components flows"

    static let flows: [TestFlow] =
        MarkupComponentsFlowSuite.flows
        + WebComponentsFlowSuite.flows
}
