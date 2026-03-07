import Core
import Foundation

public protocol HTTPClient: Sendable {
    func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
}

public extension HTTPClient {
    func send<Response: Decodable>(
        _ endpoint: Endpoint,
        decoder: JSONDecoder = .networkDefault
    ) async throws -> Response {
        let (data, _) = try await send(endpoint)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decoding(message: "Failed to decode response")
        }
    }
}

public actor URLSessionHTTPClient: HTTPClient {
    private let requestBuilder: HTTPRequestBuilder
    private let transport: any NetworkTransport
    private let retryPolicy: RetryPolicy
    private let interceptors: [any HTTPInterceptor]
    private let logger: any NetworkLogger

    public init(
        baseURL: URL,
        transport: any NetworkTransport = URLSessionNetworkTransport(),
        retryPolicy: RetryPolicy = RetryPolicy(),
        interceptors: [any HTTPInterceptor] = [],
        logger: any NetworkLogger = NoOpNetworkLogger()
    ) {
        self.requestBuilder = HTTPRequestBuilder(baseURL: baseURL)
        self.transport = transport
        self.retryPolicy = retryPolicy
        self.interceptors = interceptors
        self.logger = logger
    }

    public func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0

        while true {
            var request = try requestBuilder.buildRequest(from: endpoint)

            for interceptor in interceptors {
                request = try await interceptor.adapt(request)
            }

            logger.logRequest(request, attempt: attempt + 1)

            do {
                let (data, response) = try await transport.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                logger.logResponse(request: request, response: httpResponse, data: data)

                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    let message = parseErrorMessage(from: data)

                    if endpoint.method.isIdempotent,
                       retryPolicy.shouldRetry(statusCode: httpResponse.statusCode, attempt: attempt) {
                        attempt += 1
                        continue
                    }

                    throw NetworkError.statusCode(code: httpResponse.statusCode, message: message)
                }

                return (data, httpResponse)
            } catch {
                logger.logError(request: request, error: error)

                if endpoint.method.isIdempotent,
                   shouldRetryTransportError(error, attempt: attempt) {
                    attempt += 1
                    continue
                }

                if let networkError = error as? NetworkError {
                    throw networkError
                }

                throw NetworkError.transport(message: error.localizedDescription)
            }
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard data.isEmpty == false else {
            return nil
        }

        guard let payload = try? JSONDecoder.networkDefault.decode(HTTPErrorPayload.self, from: data) else {
            return nil
        }

        return payload.resolvedMessage
    }

    private func shouldRetryTransportError(_ error: Error, attempt: Int) -> Bool {
        guard attempt < retryPolicy.maxAttempts else {
            return false
        }

        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
