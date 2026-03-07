import Foundation
import Testing
@testable import FeaturesCatalogUIKit

private enum RepositoryError: Error {
    case failed
}

private actor StubPaginatedOffersRepository: OffersRepository {
    var cachedFirstPageValue: OffersPage?
    var firstPageResult: Result<OffersPage, Error>
    var nextPageResults: [String: Result<OffersPage, Error>]
    var firstPageLatencyNanoseconds: UInt64 = 0
    var nextPageLatencyNanoseconds: [String: UInt64] = [:]

    private(set) var fetchFirstPageCallCount: Int = 0
    private(set) var fetchNextPageCursors: [String] = []

    init(
        cachedFirstPageValue: OffersPage? = nil,
        firstPageResult: Result<OffersPage, Error>,
        nextPageResults: [String: Result<OffersPage, Error>] = [:]
    ) {
        self.cachedFirstPageValue = cachedFirstPageValue
        self.firstPageResult = firstPageResult
        self.nextPageResults = nextPageResults
    }

    func cachedFirstPage(limit: Int) async -> OffersPage? {
        _ = limit
        return cachedFirstPageValue
    }

    func fetchFirstPage(limit: Int) async throws -> OffersPage {
        _ = limit
        fetchFirstPageCallCount += 1
        if firstPageLatencyNanoseconds > 0 {
            try await Task.sleep(nanoseconds: firstPageLatencyNanoseconds)
        }
        return try firstPageResult.get()
    }

    func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        _ = limit
        fetchNextPageCursors.append(cursor)
        if let latency = nextPageLatencyNanoseconds[cursor], latency > 0 {
            try await Task.sleep(nanoseconds: latency)
        }
        guard let result = nextPageResults[cursor] else {
            throw RepositoryError.failed
        }
        return try result.get()
    }

    func setFirstPageResult(_ result: Result<OffersPage, Error>) {
        firstPageResult = result
    }

    func setNextPageLatency(_ latencyNanoseconds: UInt64, cursor: String) {
        nextPageLatencyNanoseconds[cursor] = latencyNanoseconds
    }
}

private func makeOffer(id: String, title: String) -> OfferItem {
    OfferItem(
        id: UUID(uuidString: id)!,
        title: title,
        subtitle: "Subtitle \(title)",
        priceText: "$10.00"
    )
}

private func loadedItems(from state: OffersViewState) -> [OfferItem] {
    guard case let .loaded(sections) = state else { return [] }
    return sections.flatMap(\.items)
}

@MainActor
@Test
func loadOffersProducesLoadedStateFromNetwork() async {
    let networkPage = OffersPage(
        items: [
            makeOffer(id: "20000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "20000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "20000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "20000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "4",
        source: .network
    )
    let repository = StubPaginatedOffersRepository(firstPageResult: .success(networkPage))
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)

    await viewModel.loadOffers()

    let items = loadedItems(from: viewModel.state)
    #expect(items.map(\.title) == ["A", "B", "C", "D"])
    #expect(viewModel.paginationState == .idle)
    #expect(await repository.fetchFirstPageCallCount == 1)
}

@MainActor
@Test
func loadOffersEmitsCachedContentThenRefreshedContent() async {
    let cachedPage = OffersPage(
        items: [
            makeOffer(id: "21000000-0000-0000-0000-000000000001", title: "Cached A"),
            makeOffer(id: "21000000-0000-0000-0000-000000000002", title: "Cached B"),
            makeOffer(id: "21000000-0000-0000-0000-000000000003", title: "Cached C")
        ],
        nextCursor: "3",
        source: .cacheStale
    )
    let refreshedPage = OffersPage(
        items: [
            makeOffer(id: "21000000-0000-0000-0000-000000000001", title: "Refreshed A"),
            makeOffer(id: "21000000-0000-0000-0000-000000000002", title: "Refreshed B"),
            makeOffer(id: "21000000-0000-0000-0000-000000000003", title: "Refreshed C")
        ],
        nextCursor: "3",
        source: .network
    )

    let repository = StubPaginatedOffersRepository(
        cachedFirstPageValue: cachedPage,
        firstPageResult: .success(refreshedPage)
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 3)
    var observedStates: [OffersViewState] = []
    viewModel.onStateChange = { observedStates.append($0) }

    await viewModel.loadOffers()

    #expect(observedStates.count >= 2)
    #expect(loadedItems(from: observedStates[0]).map(\.title).contains("Cached A"))
    #expect(loadedItems(from: viewModel.state).map(\.title).contains("Refreshed A"))
}

@MainActor
@Test
func loadOffersKeepsCachedContentWhenRefreshFails() async {
    let cachedPage = OffersPage(
        items: [
            makeOffer(id: "22000000-0000-0000-0000-000000000001", title: "Cached A"),
            makeOffer(id: "22000000-0000-0000-0000-000000000002", title: "Cached B"),
            makeOffer(id: "22000000-0000-0000-0000-000000000003", title: "Cached C")
        ],
        nextCursor: "3",
        source: .cacheStale
    )
    let repository = StubPaginatedOffersRepository(
        cachedFirstPageValue: cachedPage,
        firstPageResult: .failure(RepositoryError.failed)
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 3)

    await viewModel.loadOffers()

    #expect(loadedItems(from: viewModel.state).map(\.title) == ["Cached A", "Cached B", "Cached C"])
    #expect(viewModel.paginationState == .failed(message: "Unable to refresh offers. Showing latest cached data."))
}

@MainActor
@Test
func loadNextPageAppendsUniqueItems() async {
    let firstPage = OffersPage(
        items: [
            makeOffer(id: "23000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "23000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "23000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "23000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "4",
        source: .network
    )
    let nextPage = OffersPage(
        items: [
            makeOffer(id: "23000000-0000-0000-0000-000000000004", title: "D"),
            makeOffer(id: "23000000-0000-0000-0000-000000000005", title: "E")
        ],
        nextCursor: nil,
        source: .network
    )
    let repository = StubPaginatedOffersRepository(
        firstPageResult: .success(firstPage),
        nextPageResults: ["4": .success(nextPage)]
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)

    await viewModel.loadOffers()
    await viewModel.loadNextPageIfNeeded(currentVisibleItemID: UUID(uuidString: "23000000-0000-0000-0000-000000000004"))

    let items = loadedItems(from: viewModel.state)
    #expect(items.map(\.title) == ["A", "B", "C", "D", "E"])
    #expect(viewModel.paginationState == .exhausted)
    #expect(await repository.fetchNextPageCursors == ["4"])
}

@MainActor
@Test
func loadNextPageSetsFailureStateWhenRequestFails() async {
    let firstPage = OffersPage(
        items: [
            makeOffer(id: "24000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "24000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "24000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "24000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "4",
        source: .network
    )
    let repository = StubPaginatedOffersRepository(
        firstPageResult: .success(firstPage),
        nextPageResults: ["4": .failure(RepositoryError.failed)]
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)

    await viewModel.loadOffers()
    await viewModel.loadNextPageIfNeeded(currentVisibleItemID: UUID(uuidString: "24000000-0000-0000-0000-000000000004"))

    #expect(viewModel.paginationState == .failed(message: "Unable to load more offers."))
}

@MainActor
@Test
func loadOffersEmitsPerformanceMeasurement() async {
    let firstPage = OffersPage(
        items: [
            makeOffer(id: "25000000-0000-0000-0000-000000000001", title: "A")
        ],
        nextCursor: nil,
        source: .network
    )
    let repository = StubPaginatedOffersRepository(firstPageResult: .success(firstPage))
    let viewModel = OffersViewModel(repository: repository, pageSize: 1)
    var measurement: OffersFeedLoadMeasurement?
    viewModel.onFeedLoadMeasurement = { measurement = $0 }

    await viewModel.loadOffers()

    #expect(measurement?.outcome == .success)
    #expect(measurement?.isWarmStart == false)
    #expect(measurement?.cacheProbe == .miss)
    #expect((measurement?.durationMilliseconds ?? 0) >= 0)
}

@MainActor
@Test
func loadNextPageEmitsPaginationMeasurement() async {
    let firstPage = OffersPage(
        items: [
            makeOffer(id: "26000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "26000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "26000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "26000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "4",
        source: .network
    )
    let nextPage = OffersPage(
        items: [
            makeOffer(id: "26000000-0000-0000-0000-000000000005", title: "E")
        ],
        nextCursor: nil,
        source: .network
    )
    let repository = StubPaginatedOffersRepository(
        firstPageResult: .success(firstPage),
        nextPageResults: ["4": .success(nextPage)]
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)
    var measurement: OffersPaginationMeasurement?

    viewModel.onPaginationMeasurement = { measurement = $0 }

    await viewModel.loadOffers()
    await viewModel.loadNextPageIfNeeded(currentVisibleItemID: UUID(uuidString: "26000000-0000-0000-0000-000000000004"))

    #expect(measurement?.outcome == .success)
    #expect(measurement?.appendedItemCount == 1)
    #expect((measurement?.durationMilliseconds ?? 0) >= 0)
}

@MainActor
@Test
func stalePaginationResponseIsIgnoredWhenFeedReloads() async {
    let firstPageA = OffersPage(
        items: [
            makeOffer(id: "27000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "27000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "27000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "27000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "cursor-a",
        source: .network
    )
    let firstPageB = OffersPage(
        items: [
            makeOffer(id: "27100000-0000-0000-0000-000000000001", title: "Reloaded")
        ],
        nextCursor: nil,
        source: .network
    )
    let nextPageA = OffersPage(
        items: [
            makeOffer(id: "27200000-0000-0000-0000-000000000001", title: "ShouldNotAppend")
        ],
        nextCursor: nil,
        source: .network
    )

    let repository = StubPaginatedOffersRepository(
        firstPageResult: .success(firstPageA),
        nextPageResults: ["cursor-a": .success(nextPageA)]
    )
    await repository.setNextPageLatency(80_000_000, cursor: "cursor-a")
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)

    await viewModel.loadOffers()

    async let oldPagination: Void = viewModel.loadNextPageIfNeeded(
        currentVisibleItemID: UUID(uuidString: "27000000-0000-0000-0000-000000000004")
    )

    await repository.setFirstPageResult(.success(firstPageB))
    await viewModel.loadOffers()
    _ = await oldPagination

    let items = loadedItems(from: viewModel.state)
    #expect(items.map(\.title) == ["Reloaded"])
    #expect(items.contains(where: { $0.title == "ShouldNotAppend" }) == false)
}

@MainActor
@Test
func paginationMarksExhaustedWhenCursorDoesNotAdvanceAndNoItemsAppended() async {
    let firstPage = OffersPage(
        items: [
            makeOffer(id: "28000000-0000-0000-0000-000000000001", title: "A"),
            makeOffer(id: "28000000-0000-0000-0000-000000000002", title: "B"),
            makeOffer(id: "28000000-0000-0000-0000-000000000003", title: "C"),
            makeOffer(id: "28000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "cursor-loop",
        source: .network
    )
    let loopPage = OffersPage(
        items: [
            makeOffer(id: "28000000-0000-0000-0000-000000000004", title: "D")
        ],
        nextCursor: "cursor-loop",
        source: .network
    )
    let repository = StubPaginatedOffersRepository(
        firstPageResult: .success(firstPage),
        nextPageResults: ["cursor-loop": .success(loopPage)]
    )
    let viewModel = OffersViewModel(repository: repository, pageSize: 4)

    await viewModel.loadOffers()
    await viewModel.loadNextPageIfNeeded(currentVisibleItemID: UUID(uuidString: "28000000-0000-0000-0000-000000000004"))

    #expect(viewModel.paginationState == .exhausted)
}
