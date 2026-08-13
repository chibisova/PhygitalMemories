import Foundation

enum ObjectRegistrationError: Error {
    case nameAlreadyRegistered
}

final class FileManagerObjectRegistrationRepository: ObjectRegistrationRepository {
    private let fileManager = FileManager.default

    func allObjects() -> [RegisteredObject] {
        guard let objectDirs = try? fileManager.contentsOfDirectory(
            at: objectsRootDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return objectDirs.compactMap { dir -> RegisteredObject? in
            guard let id = UUID(uuidString: dir.lastPathComponent) else { return nil }
            let nameFile = dir.appendingPathComponent("name.txt")
            guard let name = try? String(contentsOf: nameFile, encoding: .utf8) else { return nil }
            return RegisteredObject(id: id, name: name, photoFileURLs: photoURLs(in: dir))
        }
        .sorted { $0.name < $1.name }
    }

    func register(name: String, photos: [Data]) throws -> RegisteredObject {
        let id = StableObjectID.make(from: name)
        let dir = objectDirectory(for: id)
        try fileManager.createDirectory(at: referencePhotosDirectory(for: dir), withIntermediateDirectories: true)
        try name.write(to: dir.appendingPathComponent("name.txt"), atomically: true, encoding: .utf8)

        for photo in photos {
            try writePhoto(photo, into: dir)
        }

        return RegisteredObject(id: id, name: name, photoFileURLs: photoURLs(in: dir))
    }

    func addPhotos(_ photos: [Data], to object: RegisteredObject) throws -> RegisteredObject {
        let dir = objectDirectory(for: object.id)
        for photo in photos {
            try writePhoto(photo, into: dir)
        }
        return RegisteredObject(id: object.id, name: object.name, photoFileURLs: photoURLs(in: dir))
    }

    func removePhoto(_ url: URL, from object: RegisteredObject) throws -> RegisteredObject {
        try fileManager.removeItem(at: url)
        let dir = objectDirectory(for: object.id)
        return RegisteredObject(id: object.id, name: object.name, photoFileURLs: photoURLs(in: dir))
    }

    func rename(_ object: RegisteredObject, to newName: String) throws -> RegisteredObject {
        let newID = StableObjectID.make(from: newName)
        let oldDir = objectDirectory(for: object.id)

        guard newID != object.id else {
            try newName.write(to: oldDir.appendingPathComponent("name.txt"), atomically: true, encoding: .utf8)
            return RegisteredObject(id: object.id, name: newName, photoFileURLs: object.photoFileURLs)
        }

        let newDir = objectDirectory(for: newID)
        guard !fileManager.fileExists(atPath: newDir.path) else {
            throw ObjectRegistrationError.nameAlreadyRegistered
        }

        try fileManager.moveItem(at: oldDir, to: newDir)
        try newName.write(to: newDir.appendingPathComponent("name.txt"), atomically: true, encoding: .utf8)

        return RegisteredObject(id: newID, name: newName, photoFileURLs: photoURLs(in: newDir))
    }

    private var objectsRootDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = documentsDirectory.appendingPathComponent("Objects")
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func objectDirectory(for id: UUID) -> URL {
        objectsRootDirectory.appendingPathComponent(id.uuidString)
    }

    private func referencePhotosDirectory(for objectDirectory: URL) -> URL {
        objectDirectory.appendingPathComponent("ReferencePhotos")
    }

    private func writePhoto(_ data: Data, into objectDirectory: URL) throws {
        let dir = referencePhotosDirectory(for: objectDirectory)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        try data.write(to: fileURL, options: .atomic)
    }

    private func photoURLs(in objectDirectory: URL) -> [URL] {
        let dir = referencePhotosDirectory(for: objectDirectory)
        guard let urls = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
