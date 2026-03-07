import Core
import Data
import DesignSystem
import SwiftUI

public struct OrdersView: View {
    @ObservedObject private var viewModel: OrdersViewModel
    @State private var newOrderTitle: String = "Lunch Combo"

    public init(viewModel: OrdersViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Order History")
                .font(AppTypography.heading)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("orders_title")
                .accessibilityAddTraits(.isHeader)

            content

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                TextField("Order title", text: $newOrderTitle)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("create_order_title_input")
                    .accessibilityHint("Enter title for new order")

                PrimaryActionButton(title: "Create Order") {
                    let currentTitle = newOrderTitle
                    Task {
                        await viewModel.createOrder(title: currentTitle)
                    }
                }
                .accessibilityLabel("create_order_button")
                .accessibilityHint("Creates a new order")
            }

            PrimaryActionButton(title: "Refresh") {
                Task { await viewModel.loadOrders() }
            }
            .accessibilityLabel("orders_refresh_button")
            .accessibilityHint("Reload order history")

            Spacer()
        }
        .padding(AppSpacing.large)
        .background(AppColors.background)
        .task {
            await viewModel.loadOrders()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            StateFeedbackView(kind: .loading)
        case .empty:
            StateFeedbackView(kind: .empty(message: "No orders yet"))
        case .failed(let error):
            StateFeedbackView(kind: .error(message: error.errorDescription ?? "Unknown error"))
        case .loaded(let orders):
            List(orders) { order in
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(order.title)
                        .font(AppTypography.body)
                    Text(order.status.rawValue.capitalized)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("order_row_\(order.id.uuidString)")
                .accessibilityValue("\(order.title), \(order.status.rawValue)")
            }
            .listStyle(.plain)
            .accessibilityLabel("orders_list")
        }
    }
}
