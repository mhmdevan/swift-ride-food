import SwiftUI

public enum StateFeedbackKind: Equatable, Sendable {
    case loading
    case empty(message: String)
    case error(message: String)
    case success(message: String)
}

public struct StateFeedbackView: View {
    private let kind: StateFeedbackKind

    public init(kind: StateFeedbackKind) {
        self.kind = kind
    }

    public var body: some View {
        switch kind {
        case .loading:
            ProgressView("Loading…")
                .progressViewStyle(.circular)
        case .empty(let message):
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
        case .error(let message):
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.stateError)
        case .success(let message):
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.stateSuccess)
        }
    }
}
