import Foundation

public protocol OffersFirstPageCaching: Sendable {
    func cachedPage(limit: Int) async -> (page: OffersRemotePage, savedAt: Date)?
    func save(page: OffersRemotePage, limit: Int, savedAt: Date) async
    func invalidate(limit: Int) async
    func invalidateAll() async
}

public actor InMemoryOffersFirstPageCache: OffersFirstPageCaching {
    private struct Entry: Sendable {
        let page: OffersRemotePage
        let savedAt: Date
    }

    private var storage: [Int: Entry] = [:]

    public init() {}

    public func cachedPage(limit: Int) -> (page: OffersRemotePage, savedAt: Date)? {
        guard let entry = storage[limit] else {
            return nil
        }
        return (entry.page, entry.savedAt)
    }

    public func save(page: OffersRemotePage, limit: Int, savedAt: Date) {
        storage[limit] = Entry(page: page, savedAt: savedAt)
    }

    public func invalidate(limit: Int) {
        storage.removeValue(forKey: limit)
    }

    public func invalidateAll() {
        storage.removeAll()
    }
}
