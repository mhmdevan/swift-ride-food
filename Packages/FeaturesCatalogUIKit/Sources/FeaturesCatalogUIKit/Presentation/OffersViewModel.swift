import Foundation

public enum OffersViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded([OfferSection])
    case empty(message: String)
    case failed(message: String)
}

public enum OffersPaginationState: Equatable, Sendable {
    case idle
    case loading
    case failed(message: String)
    case exhausted
}

public enum OffersCacheProbe: Equatable, Sendable {
    case hit(source: OffersPageSource)
    case miss
}

public struct OffersFeedLoadMeasurement: Equatable, Sendable {
    public enum Outcome: String, Equatable, Sendable {
        case success
        case failure
    }

    public let durationMilliseconds: Double
    public let outcome: Outcome
    public let itemCount: Int
    public let isWarmStart: Bool
    public let cacheProbe: OffersCacheProbe

    public init(
        durationMilliseconds: Double,
        outcome: Outcome,
        itemCount: Int,
        isWarmStart: Bool,
        cacheProbe: OffersCacheProbe
    ) {
        self.durationMilliseconds = durationMilliseconds
        self.outcome = outcome
        self.itemCount = itemCount
        self.isWarmStart = isWarmStart
        self.cacheProbe = cacheProbe
    }
}

public struct OffersPaginationMeasurement: Equatable, Sendable {
    public enum Outcome: String, Equatable, Sendable {
        case success
        case failure
    }

    public let durationMilliseconds: Double
    public let outcome: Outcome
    public let appendedItemCount: Int

    public init(durationMilliseconds: Double, outcome: Outcome, appendedItemCount: Int) {
        self.durationMilliseconds = durationMilliseconds
        self.outcome = outcome
        self.appendedItemCount = appendedItemCount
    }
}

@MainActor
public final class OffersViewModel {
    public var onStateChange: ((OffersViewState) -> Void)?
    public var onPaginationStateChange: ((OffersPaginationState) -> Void)?
    public var onFeedLoadMeasurement: ((OffersFeedLoadMeasurement) -> Void)?
    public var onPaginationMeasurement: ((OffersPaginationMeasurement) -> Void)?

    public private(set) var state: OffersViewState = .idle {
        didSet {
            onStateChange?(state)
        }
    }
    public private(set) var paginationState: OffersPaginationState = .idle {
        didSet {
            onPaginationStateChange?(paginationState)
        }
    }

    private let repository: any OffersRepository
    private let pageSize: Int
    private let prefetchThreshold: Int
    private var allItems: [OfferItem] = []
    private var nextCursor: String?
    private var isLoadingFirstPage = false
    private var isLoadingNextPage = false
    private var feedGeneration = UUID()
    private var consumedPaginationCursors: Set<String> = []

    public init(
        repository: any OffersRepository = MockOffersRepository(),
        pageSize: Int = 8,
        prefetchThreshold: Int = 3
    ) {
        self.repository = repository
        self.pageSize = max(1, pageSize)
        self.prefetchThreshold = max(1, prefetchThreshold)
    }

    public func loadOffers() async {
        let loadStart = Date()
        guard isLoadingFirstPage == false else { return }
        isLoadingFirstPage = true
        defer { isLoadingFirstPage = false }
        let generation = UUID()
        feedGeneration = generation

        paginationState = .idle

        let cacheProbe: OffersCacheProbe
        if let cachedPage = await repository.cachedFirstPage(limit: pageSize) {
            applyFirstPage(cachedPage, generation: generation)
            cacheProbe = .hit(source: cachedPage.source)
        } else {
            state = .loading
            cacheProbe = .miss
        }

        let hadCachedContent = !allItems.isEmpty

        do {
            let firstPage = try await repository.fetchFirstPage(limit: pageSize)
            guard generation == feedGeneration else { return }
            applyFirstPage(firstPage, generation: generation)
            paginationState = firstPage.nextCursor == nil ? .exhausted : .idle
            onFeedLoadMeasurement?(
                OffersFeedLoadMeasurement(
                    durationMilliseconds: Date().timeIntervalSince(loadStart) * 1000,
                    outcome: .success,
                    itemCount: firstPage.items.count,
                    isWarmStart: hadCachedContent,
                    cacheProbe: cacheProbe
                )
            )
        } catch {
            let offersError = OffersDataError.map(error)
            guard offersError.isCancellation == false else { return }

            if hadCachedContent {
                paginationState = .failed(
                    message: offersError.message(for: .refreshWithCache)
                )
            } else {
                state = .failed(message: offersError.message(for: .initialLoad))
            }
            onFeedLoadMeasurement?(
                OffersFeedLoadMeasurement(
                    durationMilliseconds: Date().timeIntervalSince(loadStart) * 1000,
                    outcome: .failure,
                    itemCount: allItems.count,
                    isWarmStart: hadCachedContent,
                    cacheProbe: cacheProbe
                )
            )
        }
    }

    public func loadNextPageIfNeeded(currentVisibleItemID: UUID?) async {
        // Prevent mixing stale pagination responses into an in-flight first-page refresh.
        guard isLoadingFirstPage == false else { return }
        guard isLoadingNextPage == false else { return }
        guard let cursor = nextCursor else {
            paginationState = .exhausted
            return
        }
        guard consumedPaginationCursors.contains(cursor) == false else {
            paginationState = .exhausted
            return
        }

        guard shouldLoadNextPage(for: currentVisibleItemID) else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        paginationState = .loading
        let paginationStart = Date()
        let generation = feedGeneration

        do {
            let previousCount = allItems.count
            let nextPage = try await repository.fetchNextPage(after: cursor, limit: pageSize)
            guard generation == feedGeneration else {
                paginationState = .idle
                return
            }
            appendPage(nextPage)
            let appendedCount = max(0, allItems.count - previousCount)
            consumedPaginationCursors.insert(cursor)
            let cursorDidNotAdvance = nextPage.nextCursor == cursor
            if nextPage.nextCursor == nil || (cursorDidNotAdvance && appendedCount == 0) {
                nextCursor = nil
                paginationState = .exhausted
            } else {
                paginationState = .idle
            }
            onPaginationMeasurement?(
                OffersPaginationMeasurement(
                    durationMilliseconds: Date().timeIntervalSince(paginationStart) * 1000,
                    outcome: .success,
                    appendedItemCount: appendedCount
                )
            )
        } catch {
            let offersError = OffersDataError.map(error)
            guard offersError.isCancellation == false else {
                paginationState = .idle
                return
            }

            paginationState = .failed(message: offersError.message(for: .pagination))
            onPaginationMeasurement?(
                OffersPaginationMeasurement(
                    durationMilliseconds: Date().timeIntervalSince(paginationStart) * 1000,
                    outcome: .failure,
                    appendedItemCount: 0
                )
            )
        }
    }

    public func retryLoadNextPage() async {
        await loadNextPageIfNeeded(currentVisibleItemID: allItems.last?.id)
    }

    public func shouldPrefetchNextPage(for itemID: UUID?) -> Bool {
        shouldLoadNextPage(for: itemID)
    }

    private func shouldLoadNextPage(for itemID: UUID?) -> Bool {
        guard let itemID,
              let index = allItems.firstIndex(where: { $0.id == itemID }),
              nextCursor != nil else {
            return false
        }

        return index >= max(0, allItems.count - prefetchThreshold)
    }

    private func applyFirstPage(_ page: OffersPage, generation: UUID) {
        guard generation == feedGeneration else { return }
        allItems = page.items
        nextCursor = page.nextCursor
        consumedPaginationCursors.removeAll()
        state = composeState(from: allItems)
    }

    private func appendPage(_ page: OffersPage) {
        var existing = Set(allItems.map(\.id))
        for item in page.items where existing.contains(item.id) == false {
            allItems.append(item)
            existing.insert(item.id)
        }
        nextCursor = page.nextCursor
        state = composeState(from: allItems)
    }

    private func composeState(from items: [OfferItem]) -> OffersViewState {
        guard items.isEmpty == false else {
            return .empty(message: "No offers available right now.")
        }

        let featured = Array(items.prefix(3))
        let compact = Array(items.dropFirst(3))

        var sections: [OfferSection] = [
            OfferSection(
                id: UUID(uuidString: "B0000000-0000-0000-0000-000000000001")!,
                title: "Featured Offers",
                style: .featuredCarousel,
                items: featured
            )
        ]

        if compact.isEmpty == false {
            sections.append(
                OfferSection(
                    id: UUID(uuidString: "B0000000-0000-0000-0000-000000000002")!,
                    title: "Quick Picks",
                    style: .compactGrid,
                    items: compact
                )
            )
        }

        return .loaded(sections)
    }
}
