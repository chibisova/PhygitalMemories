import RealityKit
import UIKit

struct AudioMemoryPresenter: MemoryPresenter {
    func present(_ memory: Memory, relativeTo anchor: AnchorEntity) {
        let icon = ModelEntity(
            mesh: .generateSphere(radius: 0.015),
            materials: [SimpleMaterial(color: .systemTeal, isMetallic: false)]
        )
        icon.position = SIMD3<Float>(0, 0.12, 0) + (memory.spatialOffset?.position ?? .zero)
        anchor.addChild(icon)

        guard memory.localFilePath != "placeholder",
              let audioResource = try? AudioFileResource.load(contentsOf: URL(fileURLWithPath: memory.localFilePath)) else {
            return
        }

        icon.playAudio(audioResource)
    }
}
