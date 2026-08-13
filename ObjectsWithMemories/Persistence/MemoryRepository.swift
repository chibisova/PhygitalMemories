import Foundation

protocol MemoryRepository {
    func memories(for object: RecognizedObject) -> [Memory]
    func addMemory(type: MemoryType, data: Data, for object: RecognizedObject) throws
    func deleteMemory(_ memory: Memory) throws
}
