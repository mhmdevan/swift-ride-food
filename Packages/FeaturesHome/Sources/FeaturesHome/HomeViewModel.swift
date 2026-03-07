import Analytics
import Combine
import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var query: String = ""
    @Published public private(set) var actions: [HomeDestination]

    private var allActions: [HomeDestination]
    private let tracker: any AnalyticsTracking
    private var cancellables: Set<AnyCancellable> = []

    public init(
        actions: [HomeDestination] = HomeDestination.allCases,
        tracker: any AnalyticsTracking = NoOpAnalyticsTracker()
    ) {
        self.actions = actions
        self.allActions = actions
        self.tracker = tracker

        bindQuery()
    }

    public func updateActions(_ newActions: [HomeDestination]) {
        allActions = newActions
        applyQueryFilter(query)
    }

    public func didSelectAction(_ action: HomeDestination) {
        Task {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.Action.homeActionSelected,
                    parameters: ["destination": action.rawValue]
                )
            )
        }
    }

    private func bindQuery() {
        $query
            .removeDuplicates()
            .sink { [weak self] query in
                self?.applyQueryFilter(query)
            }
            .store(in: &cancellables)
    }

    private func applyQueryFilter(_ value: String) {
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            actions = allActions
            return
        }

        actions = allActions.filter {
            $0.title.localizedCaseInsensitiveContains(value)
        }
    }
}
