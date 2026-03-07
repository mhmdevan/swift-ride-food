import Core
import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    case invalidBaseURL
    case invalidURL
    case invalidResponse
    case decoding(message: String)
    case transport(message: String)
    case statusCode(code: Int, message: String?)

    public var asAppError: AppError {
        switch self {
        case .invalidBaseURL, .invalidURL:
            return .network(message: "Invalid request URL")
        case .invalidResponse:
            return .network(message: "Server returned invalid response")
        case .decoding(let message):
            return .network(message: message)
        case .transport(let message):
            return .network(message: message)
        case .statusCode(let code, let message):
            if let message, message.isEmpty == false {
                return .network(message: message)
            }
            return .network(message: "Request failed with status code \(code)")
        }
    }
}
