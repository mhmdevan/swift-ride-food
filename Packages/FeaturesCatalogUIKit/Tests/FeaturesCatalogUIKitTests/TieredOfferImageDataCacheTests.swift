import Foundation
import Testing
@testable import FeaturesCatalogUIKit

@Test
func tieredCacheReadsFromDiskAndWarmsMemory() async throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("tiered-offer-cache-\(UUID().uuidString)", isDirectory: true)
    let diskCache = DiskOfferImageDataCache(directoryURL: temporaryDirectory)
    let memoryCache = InMemoryOfferImageDataCache(maxEntries: 10)
    let cache = TieredOfferImageDataCache(memoryCache: memoryCache, diskCache: diskCache)
    let url = try #require(URL(string: "https://example.com/a.png"))
    let expected = Data("payload".utf8)

    await diskCache.insert(expected, for: url)
    let firstRead = await cache.data(for: url)
    let secondRead = await cache.data(for: url)

    #expect(firstRead == expected)
    #expect(secondRead == expected)
    #expect(await memoryCache.data(for: url) == expected)
}
