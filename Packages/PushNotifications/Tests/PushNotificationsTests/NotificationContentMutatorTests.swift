import Foundation
import Testing
@testable import PushNotifications

@Test
func contentMutatorAppliesPayloadOverrides() {
    let mutator = DefaultNotificationContentMutator()

    let presentation = mutator.mutate(
        baseTitle: "Base title",
        baseBody: "Base body",
        baseSubtitle: "Base subtitle",
        userInfo: [
            "rich_title": "Updated title",
            "rich_body": "Updated body",
            "rich_subtitle": "Updated subtitle",
            "rich_image_url": "https://example.com/image.png"
        ]
    )

    #expect(presentation.title == "Updated title")
    #expect(presentation.body == "Updated body")
    #expect(presentation.subtitle == "Updated subtitle")
    #expect(presentation.richImageURL?.absoluteString == "https://example.com/image.png")
}

@Test
func contentMutatorFallsBackToBaseContentWhenOverridesAreMissing() {
    let mutator = DefaultNotificationContentMutator()

    let presentation = mutator.mutate(
        baseTitle: "Base title",
        baseBody: "Base body",
        baseSubtitle: "Base subtitle",
        userInfo: [:]
    )

    #expect(presentation.title == "Base title")
    #expect(presentation.body == "Base body")
    #expect(presentation.subtitle == "Base subtitle")
    #expect(presentation.richImageURL == nil)
}

@Test
func contentMutatorIgnoresMalformedRichImageURL() {
    let mutator = DefaultNotificationContentMutator()

    let presentation = mutator.mutate(
        baseTitle: "Base title",
        baseBody: "Base body",
        baseSubtitle: "Base subtitle",
        userInfo: [
            "rich_title": "Updated title",
            "rich_image_url": "not-a-valid-url"
        ]
    )

    #expect(presentation.title == "Updated title")
    #expect(presentation.body == "Base body")
    #expect(presentation.subtitle == "Base subtitle")
    #expect(presentation.richImageURL == nil)
}
