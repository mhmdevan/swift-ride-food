import Foundation

public actor CachedOfferImageDataLoader: OfferImageDataLoading {
    private let upstream: any OfferImageDataLoading
    private let cache: any OfferImageDataCaching
    private var inFlightRequests: [URL: Task<Data, Error>] = [:]

    public init(
        upstream: any OfferImageDataLoading = URLSessionOfferImageDataLoader(),
        cache: any OfferImageDataCaching = TieredOfferImageDataCache()
    ) {
        self.upstream = upstream
        self.cache = cache
    }

    public func loadData(from url: URL) async throws -> Data {
        if Task.isCancelled {
            throw CancellationError()
        }

        if let cachedData = await cache.data(for: url) {
            return cachedData
        }

        if let inFlightTask = inFlightRequests[url] {
            return try await inFlightTask.value
        }

        let requestTask = Task<Data, Error> {
            if Task.isCancelled {
                throw CancellationError()
            }
            let data = try await upstream.loadData(from: url)
            if Task.isCancelled {
                throw CancellationError()
            }
            await cache.insert(data, for: url)
            return data
        }

        inFlightRequests[url] = requestTask
        defer {
            inFlightRequests[url] = nil
        }

        return try await requestTask.value
    }
}
