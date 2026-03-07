import Foundation
import Testing
@testable import Networking

@Test
func mockWebSocketClientEmitsStatusAndLocationEvents() async throws {
    let orderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let client = MockWebSocketClient(
        trackedOrderID: orderID,
        intervalNanoseconds: 5_000_000,
        maxEvents: 4
    )

    try await client.connect()

    var collectedEvents: [WebSocketEvent] = []

    for try await event in await client.events() {
        collectedEvents.append(event)
    }

    #expect(collectedEvents.count == 4)

    if case .orderStatusChanged(let firstOrderID, _) = collectedEvents[0] {
        #expect(firstOrderID == orderID)
    } else {
        Issue.record("First event should be order_status_changed")
    }

    if case .driverLocationChanged(let secondOrderID, _, _) = collectedEvents[1] {
        #expect(secondOrderID == orderID)
    } else {
        Issue.record("Second event should be driver_location_changed")
    }
}
