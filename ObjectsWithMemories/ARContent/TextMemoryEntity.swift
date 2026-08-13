import RealityKit
import SwiftUI

struct TextMemoryPresenter: MemoryPresenter {
    func present(_ memory: Memory, relativeTo anchor: AnchorEntity) {
        let (text, color) = Self.loadText(for: memory)
        let mesh = MeshResource.generateText(text, extrusionDepth: 0.002, font: .systemFont(ofSize: 0.02))
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: UIColor(color), isMetallic: false)])
        entity.position = SIMD3<Float>(-0.05, 0.12, 0) + (memory.spatialOffset?.position ?? .zero)
        anchor.addChild(entity)
    }

    private static func loadText(for memory: Memory) -> (text: String, color: Color) {
        guard memory.localFilePath != "placeholder",
              let content = try? String(contentsOfFile: memory.localFilePath, encoding: .utf8),
              !content.isEmpty else {
            return (memory.title ?? "A memory", .white)
        }
        let decoded = TextMemoryColorCoding.decode(content)
        let text = decoded.text.isEmpty ? (memory.title ?? "A memory") : decoded.text
        return (text, decoded.color)
    }
}
