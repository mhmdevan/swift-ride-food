import Testing
@testable import Core

@MainActor
@Test
func noOpGlobalErrorHandlerAcceptsPresentationCalls() {
    let handler = NoOpGlobalErrorHandler()

    handler.present(.validation(message: "Invalid value"), source: "test")

    #expect(Bool(true))
}
