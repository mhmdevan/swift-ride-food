import Testing
@testable import Analytics

@Test
func trackStoresEvent() async {
    let tracker = InMemoryAnalyticsTracker()

    await tracker.track(AnalyticsEvent(name: "login_success"))
    let trackedEvents = await tracker.trackedEvents()

    #expect(trackedEvents.count == 1)
    #expect(trackedEvents.first?.name == "login_success")
}
