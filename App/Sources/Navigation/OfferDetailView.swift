import DesignSystem
import SwiftUI

struct OfferDetailView: View {
    let offerID: UUID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Offer Details")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityLabel("offer_detail_title")
                    .accessibilityAddTraits(.isHeader)

                Text("Offer ID")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textPrimary.opacity(0.7))

                Text(offerID.uuidString.lowercased())
                    .font(AppTypography.body.monospaced())
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityLabel("offer_detail_id")
                    .accessibilityHint("Unique identifier for selected offer")
                    .textSelection(.enabled)

                StateFeedbackView(
                    kind: .success(message: "Deep link route resolved successfully.")
                )
                .accessibilityLabel("offer_detail_state")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.large)
        }
        .background(AppColors.background)
        .navigationTitle("Offer")
    }
}
