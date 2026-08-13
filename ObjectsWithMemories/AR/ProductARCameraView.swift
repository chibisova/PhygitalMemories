import SwiftUI
import RealityKit
import ARKit

/// Product mode's camera view. Places memory content via a screen-center raycast at the
/// moment an object is recognized, rather than an `ARObjectAnchor` — Approach C has no
/// pose of its own (Decision 006). The resulting anchor is world-fixed: it does not
/// follow the physical object if it's moved after placement, an explicit tradeoff.
struct ProductARCameraView: UIViewRepresentable {
    let sessionManager: ProductARSessionManager
    let memoryRepository: MemoryRepository

    func makeCoordinator() -> Coordinator {
        Coordinator(memoryRepository: memoryRepository)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = sessionManager.session
        context.coordinator.arView = arView

        sessionManager.onObjectRecognized = { [weak coordinator = context.coordinator] object in
            coordinator?.place(object)
        }
        sessionManager.onMemoriesChanged = { [weak coordinator = context.coordinator] objectID in
            coordinator?.refreshMemories(for: objectID)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator {
        weak var arView: ARView?
        private let memoryRepository: MemoryRepository
        private var placedObjects: [UUID: RecognizedObject] = [:]

        init(memoryRepository: MemoryRepository) {
            self.memoryRepository = memoryRepository
        }

        func place(_ object: RecognizedObject) {
            guard placedObjects[object.id] == nil, let arView else { return }

            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
            guard let result = results.first else { return }

            placedObjects[object.id] = object

            let anchorEntity = AnchorEntity(world: result.worldTransform)
            anchorEntity.name = object.id.uuidString
            populate(anchorEntity, for: object)
            arView.scene.addAnchor(anchorEntity)
        }

        func refreshMemories(for objectID: UUID) {
            guard let object = placedObjects[objectID],
                  let arView,
                  let anchorEntity = arView.scene.anchors.first(where: { $0.name == objectID.uuidString }) as? AnchorEntity else { return }

            for child in Array(anchorEntity.children) {
                child.removeFromParent()
            }
            populate(anchorEntity, for: object)
        }

        private func populate(_ anchorEntity: AnchorEntity, for object: RecognizedObject) {
            for memory in memoryRepository.memories(for: object) {
                MemoryEntityFactory.present(memory, relativeTo: anchorEntity)
            }
        }
    }
}
