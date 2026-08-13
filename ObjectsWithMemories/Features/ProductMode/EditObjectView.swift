import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EditObjectView: View {
    let object: RegisteredObject
    let objectRegistrationRepository: ObjectRegistrationRepository
    let memoryRepository: MemoryRepository
    let onChanged: () -> Void
    let onMemoriesChanged: (UUID) -> Void
    let onDeleted: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentObject: RegisteredObject
    @State private var name: String
    @State private var memories: [Memory] = []
    @State private var errorMessage: String?

    @State private var newPhotoItems: [PhotosPickerItem] = []
    @State private var newMemoryPhotoItem: PhotosPickerItem?
    @State private var newMemoryVideoItem: PhotosPickerItem?
    @State private var isShowingAudioImporter = false
    @State private var newAudioData: Data?
    @State private var newAudioFileName: String?
    @State private var newNoteText = ""
    @State private var newNoteColor: Color = .white
    @State private var isShowingDeleteConfirmation = false

    init(
        object: RegisteredObject,
        objectRegistrationRepository: ObjectRegistrationRepository,
        memoryRepository: MemoryRepository,
        onChanged: @escaping () -> Void,
        onMemoriesChanged: @escaping (UUID) -> Void,
        onDeleted: @escaping (UUID) -> Void
    ) {
        self.object = object
        self.objectRegistrationRepository = objectRegistrationRepository
        self.memoryRepository = memoryRepository
        self.onChanged = onChanged
        self.onMemoriesChanged = onMemoriesChanged
        self.onDeleted = onDeleted
        _currentObject = State(initialValue: object)
        _name = State(initialValue: object.name)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                Button("Save Name") { rename() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name == currentObject.name)
            }

            Section("Reference Photos (\(currentObject.photoFileURLs.count))") {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(currentObject.photoFileURLs, id: \.self) { url in
                            thumbnail(for: url)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        removePhoto(url)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                    }
                                    .padding(2)
                                }
                        }
                    }
                }
                PhotosPicker("Add Photos", selection: $newPhotoItems, maxSelectionCount: 5, matching: .images)
                    .onChange(of: newPhotoItems) { _, newValue in
                        guard !newValue.isEmpty else { return }
                        addPhotos(newValue)
                    }
            }

            Section("Attached Memories (\(memories.count))") {
                ForEach(memories) { memory in
                    HStack {
                        Text(memory.type.label)
                        Spacer()
                        Text(memory.createdAt, style: .date).foregroundStyle(.secondary)
                        Button(role: .destructive) {
                            deleteMemory(memory)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }

            Section("Add Memory") {
                PhotosPicker("Choose Photo", selection: $newMemoryPhotoItem, matching: .images)
                PhotosPicker("Choose Video", selection: $newMemoryVideoItem, matching: .videos)
                Button(newAudioFileName ?? "Choose Audio") { isShowingAudioImporter = true }
                TextField("Write a memory...", text: $newNoteText, axis: .vertical).lineLimit(3...6)
                ColorPicker("Text Color", selection: $newNoteColor)
                Button("Add") { addMemory() }
                    .disabled(newMemoryPhotoItem == nil && newMemoryVideoItem == nil && newAudioData == nil
                        && newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }

            Section {
                Button("Delete Object", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(currentObject.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reloadMemories() }
        .fileImporter(isPresented: $isShowingAudioImporter, allowedContentTypes: [.audio]) { result in
            guard case .success(let url) = result else { return }
            loadAudio(from: url)
        }
        .confirmationDialog(
            "Delete \(currentObject.name)? This removes it and all its memories permanently.",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteObject() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func thumbnail(for url: URL) -> some View {
        Group {
            if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 64, height: 64)
        .clipped()
        .cornerRadius(6)
    }

    private func loadAudio(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        newAudioData = try? Data(contentsOf: url)
        newAudioFileName = url.lastPathComponent
    }

    private func rename() {
        do {
            currentObject = try objectRegistrationRepository.rename(currentObject, to: name.trimmingCharacters(in: .whitespacesAndNewlines))
            onChanged()
        } catch {
            errorMessage = "Could not rename: \(error.localizedDescription)"
        }
    }

    private func addPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var datas: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    datas.append(data)
                }
            }
            do {
                currentObject = try objectRegistrationRepository.addPhotos(datas, to: currentObject)
                newPhotoItems = []
                onChanged()
            } catch {
                errorMessage = "Could not add photos: \(error.localizedDescription)"
            }
        }
    }

    private func removePhoto(_ url: URL) {
        do {
            currentObject = try objectRegistrationRepository.removePhoto(url, from: currentObject)
            onChanged()
        } catch {
            errorMessage = "Could not remove photo: \(error.localizedDescription)"
        }
    }

    private func deleteObject() {
        do {
            try objectRegistrationRepository.deleteObject(currentObject)
            onDeleted(currentObject.id)
            dismiss()
        } catch {
            errorMessage = "Could not delete object: \(error.localizedDescription)"
        }
    }

    private func reloadMemories() {
        memories = memoryRepository.memories(for: currentObject.recognizedObject)
    }

    private func deleteMemory(_ memory: Memory) {
        do {
            try memoryRepository.deleteMemory(memory)
            reloadMemories()
            onMemoriesChanged(currentObject.id)
        } catch {
            errorMessage = "Could not delete memory: \(error.localizedDescription)"
        }
    }

    private func addMemory() {
        Task {
            do {
                let object = currentObject.recognizedObject
                if let newMemoryPhotoItem, let data = try await newMemoryPhotoItem.loadTransferable(type: Data.self) {
                    try memoryRepository.addMemory(type: .image, data: data, for: object)
                }
                if let newMemoryVideoItem, let data = try await newMemoryVideoItem.loadTransferable(type: Data.self) {
                    try memoryRepository.addMemory(type: .video, data: data, for: object)
                }
                if let newAudioData {
                    try memoryRepository.addMemory(type: .audio, data: newAudioData, for: object)
                }
                let trimmedNote = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    try memoryRepository.addMemory(type: .text, data: TextMemoryColorCoding.encode(text: trimmedNote, color: newNoteColor), for: object)
                }

                newMemoryPhotoItem = nil
                newMemoryVideoItem = nil
                newAudioData = nil
                newAudioFileName = nil
                newNoteText = ""
                newNoteColor = .white
                reloadMemories()
                onMemoriesChanged(currentObject.id)
            } catch {
                errorMessage = "Could not add memory: \(error.localizedDescription)"
            }
        }
    }
}

private extension MemoryType {
    var label: String {
        switch self {
        case .image: return "Photo"
        case .video: return "Video"
        case .audio: return "Audio"
        case .text: return "Text"
        }
    }
}
