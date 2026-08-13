import SwiftUI

struct ObjectLibraryView: View {
    let objectRegistrationRepository: ObjectRegistrationRepository
    let memoryRepository: MemoryRepository
    let onChanged: () -> Void
    let onMemoriesChanged: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var objects: [RegisteredObject] = []

    var body: some View {
        NavigationStack {
            List {
                if objects.isEmpty {
                    Text("No objects registered yet.").foregroundStyle(.secondary)
                }
                ForEach(objects) { object in
                    NavigationLink {
                        EditObjectView(
                            object: object,
                            objectRegistrationRepository: objectRegistrationRepository,
                            memoryRepository: memoryRepository,
                            onChanged: {
                                reload()
                                onChanged()
                            },
                            onMemoriesChanged: onMemoriesChanged
                        )
                    } label: {
                        VStack(alignment: .leading) {
                            Text(object.name).font(.headline)
                            Text("\(object.photoFileURLs.count) reference photo(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { reload() }
        }
    }

    private func reload() {
        objects = objectRegistrationRepository.allObjects()
    }
}
