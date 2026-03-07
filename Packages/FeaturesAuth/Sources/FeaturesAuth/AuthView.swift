import Core
import DesignSystem
import SwiftUI

public struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    private let onAuthenticated: () -> Void

    public init(viewModel: AuthViewModel, onAuthenticated: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onAuthenticated = onAuthenticated
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Sign In")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("auth_title")
                .accessibilityAddTraits(.isHeader)

            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .accessibilityLabel("email_input")
                .accessibilityHint("Enter your account email")
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("password_input")
                .accessibilityHint("Enter your password")

            PrimaryActionButton(title: "Continue") {
                Task { await viewModel.signIn() }
            }
            .accessibilityLabel("sign_in_button")
            .accessibilityHint("Sign in with email and password")

            if viewModel.canUseBiometrics {
                PrimaryActionButton(title: "Unlock with Face ID / Touch ID") {
                    Task { await viewModel.unlockWithBiometrics() }
                }
                .accessibilityLabel("biometric_unlock_button")
                .accessibilityHint("Authenticate using biometrics")
            }

            feedbackView

            Spacer()
        }
        .padding(AppSpacing.large)
        .background(AppColors.background)
        .task {
            await viewModel.restoreSessionIfAvailable()
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            onAuthenticated()
        }
    }

    @ViewBuilder
    private var feedbackView: some View {
        switch viewModel.state {
        case .idle, .loaded:
            EmptyView()
        case .loading:
            StateFeedbackView(kind: .loading)
                .accessibilityLabel("auth_loading_state")
        case .empty:
            StateFeedbackView(kind: .empty(message: "No active session"))
                .accessibilityLabel("auth_empty_state")
        case .failed(let error):
            StateFeedbackView(kind: .error(message: error.errorDescription ?? "Unknown error"))
                .accessibilityLabel("auth_error_message")
        }
    }
}
