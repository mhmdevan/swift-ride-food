import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum OfferImageLoaderError: Error, Equatable, Sendable {
    case invalidResponse
}

public protocol OfferImageDataLoading: Sendable {
    func loadData(from url: URL) async throws -> Data
}

public struct URLSessionOfferImageDataLoader: OfferImageDataLoading {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func loadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw OfferImageLoaderError.invalidResponse
        }

        return data
    }
}
