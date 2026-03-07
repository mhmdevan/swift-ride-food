import Analytics
import Core
import Data
import Foundation

@MainActor
public final class OrdersViewModel: ObservableObject {
    @Published public private(set) var state: LoadableState<[Order]> = .idle

    private let repository: any OrderRepository
    private let tracker: any AnalyticsTracking
    private let crashReporter: any CrashReporting
    private let globalErrorHandler: any GlobalErrorHandling

    public init(
        repository: any OrderRepository,
        tracker: any AnalyticsTracking = NoOpAnalyticsTracker(),
        crashReporter: any CrashReporting = NoOpCrashReporter(),
        globalErrorHandler: any GlobalErrorHandling = NoOpGlobalErrorHandler()
    ) {
        self.repository = repository
        self.tracker = tracker
        self.crashReporter = crashReporter
        self.globalErrorHandler = globalErrorHandler
    }

    public func loadOrders() async {
        state = .loading

        do {
            let orders = try await repository.fetchOrders(forceRefresh: false)
            await tracker.track(AnalyticsEvent(name: "orders_loaded", parameters: ["count": "\(orders.count)"]))
            state = orders.isEmpty ? .empty : .loaded(orders)
        } catch {
            let appError = AppError.storage(message: "Unable to load order history")
            state = .failed(appError)
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "orders", "action": "load_orders"]
            )
            globalErrorHandler.present(appError, source: "orders_load")
        }
    }

    public func createOrder(title: String) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else {
            let appError = AppError.validation(message: "Order title cannot be empty.")
            state = .failed(appError)
            globalErrorHandler.present(appError, source: "orders_create_validation")
            return
        }

        do {
            let createdOrder = try await repository.createOrder(title: trimmedTitle)
            await tracker.track(
                AnalyticsEvent(
                    name: "order_created",
                    parameters: ["order_id": createdOrder.id.uuidString]
                )
            )
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Order created",
                    category: "orders",
                    metadata: ["order_id": createdOrder.id.uuidString]
                )
            )
            await loadOrders()
        } catch {
            let appError = AppError.storage(message: "Unable to create order")
            state = .failed(appError)
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "orders", "action": "create_order"]
            )
            globalErrorHandler.present(appError, source: "orders_create")
        }
    }
}
