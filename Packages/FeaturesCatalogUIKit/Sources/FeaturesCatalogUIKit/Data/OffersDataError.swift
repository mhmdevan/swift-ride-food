import Foundation

public enum OffersDataError: Error, Equatable, Sendable {
    case network
    case timeout
    case decoding
    case server(statusCode: Int?)
    case cancelled
    case unknown

    public enum UXContext: Sendable {
        case initialLoad
        case refreshWithCache
        case pagination
    }

    public static func map(_ error: Error) -> OffersDataError {
        if let offersError = error as? OffersDataError {
            return offersError
        }

        if error is CancellationError {
            return .cancelled
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return .network
            default:
                return .unknown
            }
        }

        if error is DecodingError {
            return .decoding
        }

        if let graphQLError = error as? OffersGraphQLError {
            switch graphQLError {
            case .invalidPayload:
                return .decoding
            case .requestFailed:
                return .network
            case .apolloNotConfigured:
                return .server(statusCode: nil)
            }
        }

        return .unknown
    }

    public var isCancellation: Bool {
        if case .cancelled = self {
            return true
        }
        return false
    }

    public func message(for context: UXContext) -> String {
        switch context {
        case .initialLoad:
            return initialLoadMessage
        case .refreshWithCache:
            return refreshMessage
        case .pagination:
            return paginationMessage
        }
    }

    private var initialLoadMessage: String {
        switch self {
        case .network:
            return "No internet connection. Please try again."
        case .timeout:
            return "Request timed out. Please try again."
        case .decoding:
            return "Received invalid offers data. Please retry."
        case .server:
            return "Server is unavailable right now. Please try again."
        case .cancelled:
            return ""
        case .unknown:
            return "Unable to load catalog. Please try again."
        }
    }

    private var refreshMessage: String {
        switch self {
        case .network, .timeout:
            return "Connection issue. Showing latest cached data."
        case .decoding, .server, .unknown:
            return "Unable to refresh offers. Showing latest cached data."
        case .cancelled:
            return ""
        }
    }

    private var paginationMessage: String {
        switch self {
        case .network, .timeout:
            return "Connection issue while loading more offers."
        case .decoding, .server, .unknown:
            return "Unable to load more offers."
        case .cancelled:
            return ""
        }
    }
}
