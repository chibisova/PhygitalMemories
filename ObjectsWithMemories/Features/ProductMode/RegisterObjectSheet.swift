import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct RegisterObjectSheet: View {
    let objectRegistrationRepository: ObjectRegistrationRepository
    let memoryRepository: MemoryRepository
    let onSaved: () -> Void
    let onMemoriesChanged: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var registrationPhotoItems: [PhotosPickerItem] = []

    @State private var memoryPhotoItem: PhotosPickerItem?
    @State private var memoryVideoItem: PhotosPickerItem?
    @State private var isShowingAudioImporter = false
    @State private var audioFileName: String?
    @State private var audioData: Data?
    @State private var noteText = ""
    @State private var noteColor: Color = .white

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Object") {
                    TextField("Name", text: $name)
                    PhotosPicker(
                        "Choose Photos (1–5, different angles)",
                        selection: $registrationPhotoItems,
                        maxSelectionCount: 5,
                        matching: .images
                    )
                    if !registrationPhotoItems.isEmpty {
                        Text("\(registrationPhotoItems.count) photo(s) selected").foregroundStyle(.secondary)
                    }
                }

                Section("Attach Memories (optional)") {
                    PhotosPicker("Choose Photo", selection: $memoryPhotoItem, matching: .images)
                    if memoryPhotoItem != nil {
                        Text("Photo selected").foregroundStyle(.secondary)
                    }

                    PhotosPicker("Choose Video", selection: $memoryVideoItem, matching: .videos)
                    if memoryVideoItem != nil {
                        Text("Video selected").foregroundStyle(.secondary)
                    }

                    Button(audioFileName ?? "Choose Audio") { isShowingAudioImporter = true }

                    TextField("Write a memory...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                    ColorPicker("Text Color", selection: $noteColor)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Register Object")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || registrationPhotoItems.isEmpty)
                }
            }
            .fileImporter(isPresented: $isShowingAudioImporter, allowedContentTypes: [.audio]) { result in
                guard case .success(let url) = result else { return }
                loadAudio(from: url)
            }
        }
    }

    private func loadAudio(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        audioData = try? Data(contentsOf: url)
        audioFileName = url.lastPathComponent
    }

    private func save() {
        isSaving = true
        Task {
            do {
                var photoDatas: [Data] = []
                for item in registrationPhotoItems {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        photoDatas.append(data)
                    }
                }
                guard !photoDatas.isEmpty else {
                    errorMessage = "Could not load any of the selected photos."
                    isSaving = false
                    return
                }

                let registered = try objectRegistrationRepository.register(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    photos: photoDatas
                )
                let recognizedObject = registered.recognizedObject

                if let memoryPhotoItem, let data = try await memoryPhotoItem.loadTransferable(type: Data.self) {
                    try memoryRepository.addMemory(type: .image, data: data, for: recognizedObject)
                }

                if let memoryVideoItem, let data = try await memoryVideoItem.loadTransferable(type: Data.self) {
                    try memoryRepository.addMemory(type: .video, data: data, for: recognizedObject)
                }

                if let audioData {
                    try memoryRepository.addMemory(type: .audio, data: audioData, for: recognizedObject)
                }

                let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    try memoryRepository.addMemory(type: .text, data: TextMemoryColorCoding.encode(text: trimmedNote, color: noteColor), for: recognizedObject)
                }

                onSaved()
                onMemoriesChanged(registered.id)
                dismiss()
            } catch {
                errorMessage = "Could not save: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
