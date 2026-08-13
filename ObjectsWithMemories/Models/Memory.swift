import Foundation

struct Memory: Identifiable {
    let id: UUID
    let objectID: UUID
    let type: MemoryType
    let localFilePath: String
    var title: String?
    let createdAt: Date
    var spatialOffset: SpatialOffset?
}
