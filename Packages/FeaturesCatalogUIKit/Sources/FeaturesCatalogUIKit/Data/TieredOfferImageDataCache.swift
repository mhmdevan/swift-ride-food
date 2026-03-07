import Foundation

public actor TieredOfferImageDataCache: OfferImageDataCaching {
    private let memoryCache: any OfferImageDataCaching
    private let diskCache: any OfferImageDataCaching

    public init(
        memoryCache: any OfferImageDataCaching = InMemoryOfferImageDataCache(),
        diskCache: any OfferImageDataCaching = DiskOfferImageDataCache()
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    public func data(for url: URL) async -> Data? {
        if let memoryData = await memoryCache.data(for: url) {
            return memoryData
        }

        guard let diskData = await diskCache.data(for: url) else {
            return nil
        }

        await memoryCache.insert(diskData, for: url)
        return diskData
    }

    public func insert(_ data: Data, for url: URL) async {
        await memoryCache.insert(data, for: url)
        await diskCache.insert(data, for: url)
    }
}
