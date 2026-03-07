import Foundation

public protocol WebSocketClient: Sendable {
    func connect() async throws
    func disconnect() async
    func events() async -> AsyncThrowingStream<WebSocketEvent, Error>
}

public actor MockWebSocketClient: WebSocketClient {
    private let trackedOrderID: UUID
    private let intervalNanoseconds: UInt64
    private let maxEvents: Int?

    private var isConnected = false

    public init(
        trackedOrderID: UUID,
        intervalNanoseconds: UInt64 = 2_500_000_000,
        maxEvents: Int? = nil
    ) {
        self.trackedOrderID = trackedOrderID
        self.intervalNanoseconds = intervalNanoseconds
        self.maxEvents = maxEvents
    }

    public func connect() async throws {
        isConnected = true
    }

    public func disconnect() async {
        isConnected = false
    }

    public func events() async -> AsyncThrowingStream<WebSocketEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var index = 0

                while connectionState() {
                    if let maxEvents, index >= maxEvents {
                        continuation.finish()
                        return
                    }

                    try await Task.sleep(nanoseconds: intervalNanoseconds)

                    let event = Self.makeEvent(at: index, trackedOrderID: trackedOrderID)
                    continuation.yield(event)
                    index += 1
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func connectionState() -> Bool {
        isConnected
    }

    private static func makeEvent(at index: Int, trackedOrderID: UUID) -> WebSocketEvent {
        if index % 2 == 0 {
            let statuses = ["pending", "in_progress", "completed"]
            let status = statuses[(index / 2) % statuses.count]
            return .orderStatusChanged(orderID: trackedOrderID, status: status)
        }

        let coordinates = [
            (55.7501, 37.6164),
            (55.7512, 37.6171),
            (55.7524, 37.6180),
            (55.7531, 37.6190)
        ]

        let pair = coordinates[(index / 2) % coordinates.count]
        return .driverLocationChanged(orderID: trackedOrderID, latitude: pair.0, longitude: pair.1)
    }
}
