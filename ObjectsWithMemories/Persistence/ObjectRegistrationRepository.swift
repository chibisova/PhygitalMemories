import Foundation

protocol ObjectRegistrationRepository {
    func allObjects() -> [RegisteredObject]
    func register(name: String, photos: [Data]) throws -> RegisteredObject
    func addPhotos(_ photos: [Data], to object: RegisteredObject) throws -> RegisteredObject
    func removePhoto(_ url: URL, from object: RegisteredObject) throws -> RegisteredObject
    func rename(_ object: RegisteredObject, to newName: String) throws -> RegisteredObject
}
