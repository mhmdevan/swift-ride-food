public actor DisabledWebSocketClient: WebSocketClient {
    public init() {}

    public func connect() async throws {}

    public func disconnect() async {}

    public func events() async -> AsyncThrowingStream<WebSocketEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}
