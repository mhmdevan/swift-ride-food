import SwiftUI

public struct PrimaryActionButton: View {
    private let title: String
    private let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
        }
        .background(AppColors.brand)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
