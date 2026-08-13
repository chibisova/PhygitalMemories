import RealityKit
import UIKit

struct ImageMemoryPresenter: MemoryPresenter {
    func present(_ memory: Memory, relativeTo anchor: AnchorEntity) {
        let image = Self.loadImage(for: memory)

        guard let cgImage = image.cgImage,
              let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else {
            return
        }

        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))

        let maxDimension: Float = 0.15
        let aspectRatio = Float(image.size.height / image.size.width)
        let (width, height) = aspectRatio > 1
            ? (maxDimension / aspectRatio, maxDimension)
            : (maxDimension, maxDimension * aspectRatio)

        let mesh = MeshResource.generatePlane(width: width, height: height)
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.position = SIMD3<Float>(0, 0.12, 0) + (memory.spatialOffset?.position ?? .zero)
        planeEntity.components.set(BillboardComponent())

        anchor.addChild(planeEntity)
    }

    private static func loadImage(for memory: Memory) -> UIImage {
        guard memory.localFilePath != "placeholder", let loaded = UIImage(contentsOfFile: memory.localFilePath) else {
            return PlaceholderCardRenderer.render(title: memory.title ?? "A memory")
        }
        return loaded.normalizedAndResized(maxDimension: 1024)
    }
}

private extension UIImage {
    func normalizedAndResized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1
        guard imageOrientation != .up || scale < 1 else { return self }

        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: targetSize)) }
    }
}
