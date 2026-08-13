import SwiftUI
import PhotosUI

struct AddMemorySheet: View {
    let object: RecognizedObject
    let repository: MemoryRepository

    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var noteText = ""
    @State private var noteColor: Color = .white
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker("Choose Photo", selection: $photoItem, matching: .images)
                    if photoItem != nil {
                        Text("Photo selected").foregroundStyle(.secondary)
                    }
                }

                Section("Text Note") {
                    TextField("Write a memory...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                    ColorPicker("Text Color", selection: $noteColor)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Memory to \(object.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(photoItem == nil && noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        Task {
            do {
                if let photoItem, let data = try await photoItem.loadTransferable(type: Data.self) {
                    try repository.addMemory(type: .image, data: data, for: object)
                }

                let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    try repository.addMemory(type: .text, data: TextMemoryColorCoding.encode(text: trimmedNote, color: noteColor), for: object)
                }

                dismiss()
            } catch {
                errorMessage = "Could not save memory: \(error.localizedDescription)"
            }
        }
    }
}
