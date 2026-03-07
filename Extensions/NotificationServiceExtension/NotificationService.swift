import Foundation
import PushNotifications
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private let contentMutator: any NotificationContentMutating = DefaultNotificationContentMutator()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        bestAttemptContent = mutableContent

        let presentation = contentMutator.mutate(
            baseTitle: mutableContent.title,
            baseBody: mutableContent.body,
            baseSubtitle: mutableContent.subtitle,
            userInfo: mutableContent.userInfo
        )

        mutableContent.title = presentation.title
        mutableContent.body = presentation.body
        mutableContent.subtitle = presentation.subtitle

        guard let richImageURL = presentation.richImageURL else {
            contentHandler(mutableContent)
            return
        }

        Task {
            if let attachment = try? await downloadAttachment(from: richImageURL) {
                mutableContent.attachments = [attachment]
            }

            contentHandler(mutableContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let bestAttemptContent {
            contentHandler?(bestAttemptContent)
        }
    }

    private func downloadAttachment(from remoteURL: URL) async throws -> UNNotificationAttachment {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)

        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileExtension = remoteURL.pathExtension.isEmpty ? "jpg" : remoteURL.pathExtension
        let destinationURL = temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        try data.write(to: destinationURL)

        return try UNNotificationAttachment(
            identifier: "rich_image",
            url: destinationURL
        )
    }
}
