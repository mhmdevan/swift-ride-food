import Foundation
import Testing
@testable import PushNotifications

@Test
func payloadParsesOrderAndRichContentFields() {
    let orderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let userInfo: [AnyHashable: Any] = [
        "order_id": orderID.uuidString,
        "status": "in_progress",
        "rich_title": "Driver nearby",
        "rich_body": "Your order is 2 minutes away",
        "rich_subtitle": "SwiftRide & Food",
        "rich_image_url": "https://example.com/image.png"
    ]

    let payload = PushNotificationPayload(userInfo: userInfo)

    #expect(payload.orderID == orderID)
    #expect(payload.status == "in_progress")
    #expect(payload.titleOverride == "Driver nearby")
    #expect(payload.bodyOverride == "Your order is 2 minutes away")
    #expect(payload.subtitleOverride == "SwiftRide & Food")
    #expect(payload.richImageURL?.absoluteString == "https://example.com/image.png")
    #expect(payload.hasOrderStatusUpdate == true)
    #expect(payload.hasRichContentOverrides == true)
}

@Test
func payloadFallsBackToAPSAlertValues() {
    let userInfo: [AnyHashable: Any] = [
        "aps": [
            "alert": [
                "title": "Order Update",
                "body": "Your courier is on the way",
                "subtitle": "ETA 5 min"
            ]
        ]
    ]

    let payload = PushNotificationPayload(userInfo: userInfo)

    #expect(payload.titleOverride == "Order Update")
    #expect(payload.bodyOverride == "Your courier is on the way")
    #expect(payload.subtitleOverride == "ETA 5 min")
}
