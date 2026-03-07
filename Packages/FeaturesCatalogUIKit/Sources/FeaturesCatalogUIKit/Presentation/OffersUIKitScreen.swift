import SwiftUI

public struct OffersUIKitScreen: View {
    private let viewModel: OffersViewModel

    public init(viewModel: OffersViewModel = OffersViewModel()) {
        self.viewModel = viewModel
    }

    public var body: some View {
#if canImport(UIKit)
        OffersViewControllerRepresentable(viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
#else
        Text("UIKit catalog is available on iOS builds.")
            .padding()
#endif
    }
}

#if canImport(UIKit)
import UIKit

private struct OffersViewControllerRepresentable: UIViewControllerRepresentable {
    let viewModel: OffersViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        OffersViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif
