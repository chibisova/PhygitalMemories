import SwiftUI
import RealityKit
import ARKit

struct ARCameraView: UIViewRepresentable {
    let sessionManager: ARSessionManager
    let memoryRepository: MemoryRepository

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = sessionManager.session

        sessionManager.onObjectAnchorAdded = { [weak arView, memoryRepository] objectAnchor, recognizedObject in
            guard let arView else { return }
            let anchorEntity = AnchorEntity(anchor: objectAnchor)
            anchorEntity.name = objectAnchor.identifier.uuidString

            if let recognizedObject {
                let memories = memoryRepository.memories(for: recognizedObject)
                for memory in memories {
                    MemoryEntityFactory.present(memory, relativeTo: anchorEntity)
                }
            }

            arView.scene.addAnchor(anchorEntity)
        }

        sessionManager.onObjectAnchorRemoved = { [weak arView] objectAnchor in
            guard let arView else { return }
            let name = objectAnchor.identifier.uuidString
            if let anchorEntity = arView.scene.anchors.first(where: { $0.name == name }) {
                arView.scene.removeAnchor(anchorEntity)
            }
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
