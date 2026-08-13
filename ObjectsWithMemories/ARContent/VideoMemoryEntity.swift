import RealityKit
import AVFoundation

struct VideoMemoryPresenter: MemoryPresenter {
    func present(_ memory: Memory, relativeTo anchor: AnchorEntity) {
        guard memory.localFilePath != "placeholder" else {
            TextMemoryPresenter().present(Self.fallbackMemory(from: memory), relativeTo: anchor)
            return
        }

        let url = URL(fileURLWithPath: memory.localFilePath)
        let player = AVPlayer(url: url)
        let material = VideoMaterial(avPlayer: player)

        // VideoMaterial samples the raw (untransformed) pixel buffer — it does not apply
        // the track's preferredTransform the way AVPlayerLayer does, so portrait-recorded
        // video plays back sideways unless corrected here. This is a one-time read of the
        // asset's metadata at placement time, not a per-frame cost.
        let track = AVURLAsset(url: url).tracks(withMediaType: .video).first
        let transform = track?.preferredTransform ?? .identity
        let naturalSize = track?.naturalSize ?? CGSize(width: 16, height: 9)
        let rotation = -Float(atan2(Double(transform.b), Double(transform.a)))

        let maxDimension: Float = 0.16
        let aspectRatio = Float(naturalSize.height / naturalSize.width)
        let (width, height) = aspectRatio > 1
            ? (maxDimension / aspectRatio, maxDimension)
            : (maxDimension, maxDimension * aspectRatio)

        let mesh = MeshResource.generatePlane(width: width, height: height)
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.orientation = simd_quatf(angle: rotation, axis: SIMD3<Float>(0, 0, 1))

        // BillboardComponent recomputes the entity's full orientation every frame to face
        // the camera, which would stomp the rotation fix above if applied directly to the
        // same entity — so the correction lives on this child, billboard on a wrapping parent.
        let container = Entity()
        container.components.set(BillboardComponent())
        container.position = SIMD3<Float>(0, 0.12, 0) + (memory.spatialOffset?.position ?? .zero)
        container.addChild(planeEntity)
        anchor.addChild(container)

        player.play()
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private static func fallbackMemory(from memory: Memory) -> Memory {
        Memory(
            id: memory.id,
            objectID: memory.objectID,
            type: .text,
            localFilePath: "placeholder",
            title: "No video memory",
            createdAt: memory.createdAt,
            spatialOffset: memory.spatialOffset
        )
    }
}
