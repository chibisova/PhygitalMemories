import Foundation
import simd

final class FileManagerMemoryRepository: MemoryRepository {
    private let fileManager = FileManager.default

    func memories(for object: RecognizedObject) -> [Memory] {
        let directory = memoriesDirectory(for: object)
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else {
            return []
        }

        let memories = files.compactMap { url -> Memory? in
            guard let type = Self.memoryType(for: url.pathExtension) else { return nil }
            let createdAt = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            return Memory(
                id: UUID(),
                objectID: object.id,
                type: type,
                localFilePath: url.path,
                title: object.name,
                createdAt: createdAt,
                spatialOffset: nil
            )
        }
        .sorted { $0.createdAt < $1.createdAt }

        return memories.enumerated().map { index, memory in
            var memory = memory
            memory.spatialOffset = SpatialOffset(
                position: SIMD3<Float>(0, Float(index) * 0.2, 0),
                rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
                scale: SIMD3<Float>(repeating: 1)
            )
            return memory
        }
    }

    func addMemory(type: MemoryType, data: Data, for object: RecognizedObject) throws {
        let directory = memoriesDirectory(for: object)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(Self.fileExtension(for: type))
        try data.write(to: fileURL, options: .atomic)
    }

    func deleteMemory(_ memory: Memory) throws {
        try fileManager.removeItem(at: URL(fileURLWithPath: memory.localFilePath))
    }

    private func memoriesDirectory(for object: RecognizedObject) -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory
            .appendingPathComponent("Objects")
            .appendingPathComponent(object.id.uuidString)
            .appendingPathComponent("Memories")
    }

    private static func fileExtension(for type: MemoryType) -> String {
        switch type {
        case .image: return "jpg"
        case .video: return "mp4"
        case .audio: return "m4a"
        case .text: return "txt"
        }
    }

    private static func memoryType(for pathExtension: String) -> MemoryType? {
        switch pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic": return .image
        case "mp4", "mov": return .video
        case "mp3", "m4a", "wav": return .audio
        case "txt": return .text
        default: return nil
        }
    }
}
