import DesignSystem
import SwiftUI

public struct HomeView: View {
    @ObservedObject private var viewModel: HomeViewModel
    private let onSelect: (HomeDestination) -> Void

    public init(viewModel: HomeViewModel, onSelect: @escaping (HomeDestination) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("SwiftRide & Food")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("home_title")
                .accessibilityAddTraits(.isHeader)

            Text("Choose a destination to continue your trip or delivery flow.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textPrimary.opacity(0.7))
                .accessibilityLabel("home_subtitle")

            TextField("Search destination", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("home_search_input")
                .accessibilityHint("Filter available app destinations")

            if viewModel.actions.isEmpty {
                StateFeedbackView(kind: .empty(message: "No matching destinations"))
                    .accessibilityLabel("home_empty_state")
            } else {
                ForEach(viewModel.actions) { action in
                    PrimaryActionButton(title: action.title) {
                        viewModel.didSelectAction(action)
                        onSelect(action)
                    }
                    .accessibilityLabel("home_action_\(action.rawValue)")
                    .accessibilityHint("Opens \(action.title)")
                }
            }

            Spacer()
        }
        .padding(AppSpacing.large)
        .background(AppColors.background)
    }
}
