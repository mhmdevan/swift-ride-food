import Foundation

public enum AppError: Error, Equatable, LocalizedError, Sendable {
    case network(message: String)
    case validation(message: String)
    case storage(message: String)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .network(let message), .validation(let message), .storage(let message):
            return message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
