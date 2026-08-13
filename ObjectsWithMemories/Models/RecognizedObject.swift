import Foundation

struct RecognizedObject: Identifiable, Equatable {
    let id: UUID
    let name: String
    let confidence: Float
}
