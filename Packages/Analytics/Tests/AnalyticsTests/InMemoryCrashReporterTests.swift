import Foundation
import Testing
@testable import Analytics

private struct StubError: Error {}

@Test
func addBreadcrumbStoresBreadcrumb() async {
    let reporter = InMemoryCrashReporter()

    await reporter.addBreadcrumb(
        CrashBreadcrumb(
            message: "Order screen opened",
            category: "navigation",
            metadata: ["screen": "orders"]
        )
    )

    let breadcrumbs = await reporter.trackedBreadcrumbs()

    #expect(breadcrumbs.count == 1)
    #expect(breadcrumbs.first?.message == "Order screen opened")
    #expect(breadcrumbs.first?.category == "navigation")
    #expect(breadcrumbs.first?.metadata["screen"] == "orders")
}

@Test
func recordNonFatalStoresErrorContext() async {
    let reporter = InMemoryCrashReporter()

    await reporter.recordNonFatal(
        StubError(),
        context: ["feature": "orders", "action": "load"]
    )

    let errors = await reporter.trackedErrors()

    #expect(errors.count == 1)
    #expect(errors.first?.context["feature"] == "orders")
    #expect(errors.first?.context["action"] == "load")
}
