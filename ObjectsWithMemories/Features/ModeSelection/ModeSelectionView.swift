import SwiftUI

struct ModeSelectionView: View {
    let onSelect: (AppMode) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Objects With Memories")
                .font(.title2).bold()

            VStack(spacing: 16) {
                Button {
                    onSelect(.product)
                } label: {
                    modeCard(
                        title: "Product",
                        subtitle: "Register objects and attach memories to them."
                    )
                }

                Button {
                    onSelect(.experiment)
                } label: {
                    modeCard(
                        title: "Experiment",
                        subtitle: "Recognition testing tools (ARKit + embeddings)."
                    )
                }
            }
        }
        .padding()
    }

    private func modeCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.primary)
    }
}
