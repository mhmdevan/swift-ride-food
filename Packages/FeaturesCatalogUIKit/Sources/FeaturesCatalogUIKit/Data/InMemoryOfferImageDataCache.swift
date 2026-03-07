import Foundation

public protocol OfferImageDataCaching: Sendable {
    func data(for url: URL) async -> Data?
    func insert(_ data: Data, for url: URL) async
}

public actor InMemoryOfferImageDataCache: OfferImageDataCaching {
    private let maxEntries: Int
    private var storage: [URL: Data] = [:]
    private var insertionOrder: [URL] = []

    public init(maxEntries: Int = 120) {
        self.maxEntries = max(1, maxEntries)
    }

    public func data(for url: URL) -> Data? {
        storage[url]
    }

    public func insert(_ data: Data, for url: URL) {
        storage[url] = data

        if let existingIndex = insertionOrder.firstIndex(of: url) {
            insertionOrder.remove(at: existingIndex)
        }
        insertionOrder.append(url)

        while insertionOrder.count > maxEntries,
              let oldestURL = insertionOrder.first {
            insertionOrder.removeFirst()
            storage.removeValue(forKey: oldestURL)
        }
    }
}
