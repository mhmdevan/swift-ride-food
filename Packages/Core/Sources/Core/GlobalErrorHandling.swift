import Foundation

@MainActor
public protocol GlobalErrorHandling: AnyObject {
    func present(_ error: AppError, source: String)
}

@MainActor
public final class NoOpGlobalErrorHandler: GlobalErrorHandling {
    public init() {}

    public func present(_ error: AppError, source: String) {
        _ = error
        _ = source
    }
}
