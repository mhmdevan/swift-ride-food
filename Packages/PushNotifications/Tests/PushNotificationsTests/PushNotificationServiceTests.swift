import Foundation
import Testing
@testable import PushNotifications

@Test
func registeringAPNSTokenProducesFCMToken() async {
    let messagingClient = MockPushMessagingClient()
    let service = PushNotificationService(messagingClient: messagingClient)

    await service.configure()
    await service.didRegisterAPNSToken(Data([0xAA, 0xBB, 0xCC, 0xDD]))

    let token = await service.currentFCMToken()

    #expect(token?.hasPrefix("fcm_") == true)
}

@Test
func handleRemoteNotificationReturnsNewDataForOrderStatusPayload() async {
    let service = PushNotificationService(messagingClient: MockPushMessagingClient())

    let result = await service.handleRemoteNotification(
        userInfo: [
            "order_id": "11111111-1111-1111-1111-111111111111",
            "status": "completed"
        ]
    )

    #expect(result == .newData)
}

@Test
func handleRemoteNotificationReturnsNoDataForUnknownPayload() async {
    let service = PushNotificationService(messagingClient: MockPushMessagingClient())

    let result = await service.handleRemoteNotification(userInfo: ["foo": "bar"])

    #expect(result == .noData)
}
