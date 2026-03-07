import Foundation

public protocol NotificationContentMutating: Sendable {
    func mutate(
        baseTitle: String,
        baseBody: String,
        baseSubtitle: String,
        userInfo: [AnyHashable: Any]
    ) -> PushNotificationPresentation
}

public struct DefaultNotificationContentMutator: NotificationContentMutating {
    private let presentationBuilder: PushNotificationPresentationBuilder

    public init(presentationBuilder: PushNotificationPresentationBuilder = PushNotificationPresentationBuilder()) {
        self.presentationBuilder = presentationBuilder
    }

    public func mutate(
        baseTitle: String,
        baseBody: String,
        baseSubtitle: String,
        userInfo: [AnyHashable: Any]
    ) -> PushNotificationPresentation {
        let payload = PushNotificationPayload(userInfo: userInfo)
        return presentationBuilder.build(
            baseTitle: baseTitle,
            baseBody: baseBody,
            baseSubtitle: baseSubtitle,
            payload: payload
        )
    }
}
