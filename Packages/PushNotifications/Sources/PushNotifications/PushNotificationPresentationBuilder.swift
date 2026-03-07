public struct PushNotificationPresentationBuilder: Sendable {
    public init() {}

    public func build(
        baseTitle: String,
        baseBody: String,
        baseSubtitle: String,
        payload: PushNotificationPayload
    ) -> PushNotificationPresentation {
        PushNotificationPresentation(
            title: payload.titleOverride ?? baseTitle,
            body: payload.bodyOverride ?? baseBody,
            subtitle: payload.subtitleOverride ?? baseSubtitle,
            richImageURL: payload.richImageURL
        )
    }
}
