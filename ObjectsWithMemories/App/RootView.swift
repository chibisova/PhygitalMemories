import SwiftUI

struct RootView: View {
    @State private var mode: AppMode?

    var body: some View {
        switch mode {
        case .none:
            ModeSelectionView { selected in mode = selected }
        case .experiment:
            ContentView(onSwitchMode: { mode = nil })
        case .product:
            ProductModeView(onSwitchMode: { mode = nil })
        }
    }
}
