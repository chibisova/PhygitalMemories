import Foundation

struct RegisteredObject: Identifiable, Equatable {
    let id: UUID
    var name: String
    var photoFileURLs: [URL]

    var recognizedObject: RecognizedObject {
        RecognizedObject(id: id, name: name, confidence: 1.0)
    }
}
