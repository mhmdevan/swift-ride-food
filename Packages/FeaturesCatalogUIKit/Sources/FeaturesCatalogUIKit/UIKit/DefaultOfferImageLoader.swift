#if canImport(UIKit)
import UIKit

public protocol OfferImageLoading {
    func loadImage(from url: URL) async -> UIImage?
    func prefetchImage(from url: URL)
    func cancelPrefetch(for url: URL)
}

public extension OfferImageLoading {
    func prefetchImage(from url: URL) {
        _ = url
    }

    func cancelPrefetch(for url: URL) {
        _ = url
    }
}

public final class DefaultOfferImageLoader: OfferImageLoading {
    private let dataLoader: any OfferImageDataLoading
    private let lock = NSLock()
    private var inFlightByURL: [URL: (identifier: UUID, task: Task<UIImage?, Never>)] = [:]

    public init(dataLoader: any OfferImageDataLoading = CachedOfferImageDataLoader()) {
        self.dataLoader = dataLoader
    }

    public func loadImage(from url: URL) async -> UIImage? {
        let work = task(for: url)
        return await work.value
    }

    public func prefetchImage(from url: URL) {
        let work = task(for: url)
        Task {
            _ = await work.value
        }
    }

    public func cancelPrefetch(for url: URL) {
        lock.lock()
        let task = inFlightByURL[url]?.task
        inFlightByURL[url] = nil
        lock.unlock()
        task?.cancel()
    }

    private func task(for url: URL) -> Task<UIImage?, Never> {
        lock.lock()
        if let existing = inFlightByURL[url]?.task {
            lock.unlock()
            return existing
        }

        let identifier = UUID()
        let task = Task<UIImage?, Never> { [dataLoader] in
            do {
                let imageData = try await dataLoader.loadData(from: url)
                if Task.isCancelled {
                    return nil
                }
                return UIImage(data: imageData)
            } catch {
                return nil
            }
        }
        inFlightByURL[url] = (identifier, task)
        lock.unlock()

        Task { [weak self] in
            _ = await task.value
            self?.removeCompletedTask(for: url, identifier: identifier)
        }

        return task
    }

    private func removeCompletedTask(for url: URL, identifier: UUID) {
        lock.lock()
        defer { lock.unlock() }

        guard inFlightByURL[url]?.identifier == identifier else {
            return
        }
        inFlightByURL[url] = nil
    }
}
#endif
