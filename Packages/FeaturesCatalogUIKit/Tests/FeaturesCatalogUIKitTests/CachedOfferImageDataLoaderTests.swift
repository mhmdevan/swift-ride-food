import Foundation
import Testing
@testable import FeaturesCatalogUIKit

private enum StubLoaderError: Error {
    case failed
}

private actor CountingImageDataLoader: OfferImageDataLoading {
    private(set) var callCount: Int = 0
    private let delayNanoseconds: UInt64
    private let result: Result<Data, Error>

    init(result: Result<Data, Error>, delayNanoseconds: UInt64 = 0) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func loadData(from url: URL) async throws -> Data {
        callCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return try result.get()
    }

    func snapshotCallCount() -> Int {
        callCount
    }
}

private actor FlakyImageDataLoader: OfferImageDataLoading {
    private var callCount: Int = 0
    private var remainingFailures: Int
    private let payload: Data

    init(remainingFailures: Int, payload: Data) {
        self.remainingFailures = remainingFailures
        self.payload = payload
    }

    func loadData(from url: URL) async throws -> Data {
        callCount += 1
        if remainingFailures > 0 {
            remainingFailures -= 1
            throw StubLoaderError.failed
        }
        return payload
    }

    func snapshotCallCount() -> Int {
        callCount
    }
}

@Test
func cachedLoaderUsesCacheAfterFirstFetch() async throws {
    let url = try #require(URL(string: "https://example.com/a.png"))
    let expected = Data("image-a".utf8)
    let upstream = CountingImageDataLoader(result: .success(expected))
    let cache = InMemoryOfferImageDataCache()
    let loader = CachedOfferImageDataLoader(upstream: upstream, cache: cache)

    let first = try await loader.loadData(from: url)
    let second = try await loader.loadData(from: url)

    #expect(first == expected)
    #expect(second == expected)
    #expect(await upstream.snapshotCallCount() == 1)
}

@Test
func cachedLoaderDeduplicatesConcurrentRequestsForSameURL() async throws {
    let url = try #require(URL(string: "https://example.com/b.png"))
    let expected = Data("image-b".utf8)
    let upstream = CountingImageDataLoader(
        result: .success(expected),
        delayNanoseconds: 40_000_000
    )
    let cache = InMemoryOfferImageDataCache()
    let loader = CachedOfferImageDataLoader(upstream: upstream, cache: cache)

    async let first = loader.loadData(from: url)
    async let second = loader.loadData(from: url)
    let (firstData, secondData) = try await (first, second)

    #expect(firstData == expected)
    #expect(secondData == expected)
    #expect(await upstream.snapshotCallCount() == 1)
}

@Test
func cachedLoaderDoesNotCacheFailures() async throws {
    let url = try #require(URL(string: "https://example.com/c.png"))
    let expected = Data("image-c".utf8)
    let upstream = FlakyImageDataLoader(remainingFailures: 1, payload: expected)
    let cache = InMemoryOfferImageDataCache()
    let loader = CachedOfferImageDataLoader(upstream: upstream, cache: cache)

    do {
        _ = try await loader.loadData(from: url)
        Issue.record("Expected first request to throw.")
    } catch {
        // expected
    }

    let second = try await loader.loadData(from: url)

    #expect(second == expected)
    #expect(await upstream.snapshotCallCount() == 2)
}

@Test
func inMemoryCacheEvictsOldestEntryWhenCapacityExceeded() async throws {
    let firstURL = try #require(URL(string: "https://example.com/first.png"))
    let secondURL = try #require(URL(string: "https://example.com/second.png"))
    let cache = InMemoryOfferImageDataCache(maxEntries: 1)

    await cache.insert(Data("first".utf8), for: firstURL)
    await cache.insert(Data("second".utf8), for: secondURL)

    #expect(await cache.data(for: firstURL) == nil)
    #expect(await cache.data(for: secondURL) == Data("second".utf8))
}
