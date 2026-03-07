import Foundation
import Testing
@testable import PushNotifications

@Test
func presentationBuilderAppliesPayloadOverrides() {
    let payload = PushNotificationPayload(
        userInfo: [
            "rich_title": "Updated title",
            "rich_body": "Updated body",
            "rich_subtitle": "Updated subtitle",
            "rich_image_url": "https://example.com/image.png"
        ]
    )

    let builder = PushNotificationPresentationBuilder()
    let presentation = builder.build(
        baseTitle: "Base title",
        baseBody: "Base body",
        baseSubtitle: "Base subtitle",
        payload: payload
    )

    #expect(presentation.title == "Updated title")
    #expect(presentation.body == "Updated body")
    #expect(presentation.subtitle == "Updated subtitle")
    #expect(presentation.richImageURL?.absoluteString == "https://example.com/image.png")
}
