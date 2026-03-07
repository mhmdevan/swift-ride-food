import Combine
import Core
import Foundation

@MainActor
final class GlobalErrorCenter: ObservableObject, GlobalErrorHandling {
    struct PresentedError: Equatable, Identifiable {
        let id: UUID
        let source: String
        let message: String

        init(source: String, message: String) {
            id = UUID()
            self.source = source
            self.message = message
        }
    }

    @Published private(set) var presentedError: PresentedError?

    func present(_ error: AppError, source: String) {
        presentedError = PresentedError(
            source: source,
            message: error.errorDescription ?? "Something went wrong. Please try again."
        )
    }

    func dismiss() {
        presentedError = nil
    }
}
