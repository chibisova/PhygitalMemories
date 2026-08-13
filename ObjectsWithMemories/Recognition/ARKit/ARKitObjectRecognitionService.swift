import ARKit

final class ARKitObjectRecognitionService: ObjectRecognitionService {
    let referenceObjects: Set<ARReferenceObject>

    private var continuation: AsyncStream<RecognitionEvent>.Continuation?
    private var visibleObjectIDs: Set<UUID> = []
    private var trackedAnchors: [UUID: (anchor: ARObjectAnchor, object: RecognizedObject)] = [:]
    private var objectIDsByName: [String: UUID] = [:]

    lazy var recognitionEvents: AsyncStream<RecognitionEvent> = AsyncStream { [weak self] continuation in
        self?.continuation = continuation
    }

    init() {
        referenceObjects = Set(Self.loadReferenceObjects())
        for referenceObject in referenceObjects {
            let name = referenceObject.name ?? "Unknown Object"
            objectIDsByName[name] = StableObjectID.make(from: name)
        }
    }

    func start() {}

    func stop() {
        continuation?.finish()
    }

    private static func loadReferenceObjects() -> [ARReferenceObject] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "arobject", subdirectory: "ReferenceObjects") else {
            return []
        }
        return urls.compactMap { url in
            guard let referenceObject = try? ARReferenceObject(archiveURL: url) else { return nil }
            if referenceObject.name == nil {
                referenceObject.name = url.deletingPathExtension().lastPathComponent
            }
            return referenceObject
        }
    }

    func recognizedObject(for anchor: ARObjectAnchor) -> RecognizedObject? {
        trackedAnchors[anchor.identifier]?.object
    }

    func handle(didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let objectAnchor = anchor as? ARObjectAnchor else { continue }
            let name = objectAnchor.referenceObject.name ?? "Unknown Object"
            let id = objectIDsByName[name] ?? StableObjectID.make(from: name)
            trackedAnchors[objectAnchor.identifier] = (objectAnchor, RecognizedObject(id: id, name: name, confidence: 1.0))
        }
    }

    func handle(didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let objectAnchor = anchor as? ARObjectAnchor else { continue }
            guard let entry = trackedAnchors.removeValue(forKey: objectAnchor.identifier) else { continue }
            if visibleObjectIDs.remove(entry.object.id) != nil {
                continuation?.yield(.objectLost(entry.object))
            }
        }
    }

    func handle(didUpdate frame: ARFrame) {
        let currentlyVisible = trackedAnchors.values.filter { Self.isAnchorVisible($0.anchor, in: frame) }
        let currentIDs = Set(currentlyVisible.map(\.object.id))

        for entry in currentlyVisible where !visibleObjectIDs.contains(entry.object.id) {
            continuation?.yield(.objectRecognized(entry.object))
        }

        for lostID in visibleObjectIDs.subtracting(currentIDs) {
            if let entry = trackedAnchors.values.first(where: { $0.object.id == lostID }) {
                continuation?.yield(.objectLost(entry.object))
            }
        }

        visibleObjectIDs = currentIDs
    }

    private static func isAnchorVisible(_ anchor: ARAnchor, in frame: ARFrame) -> Bool {
        let camera = frame.camera
        let worldPosition = anchor.transform.columns.3
        let cameraSpacePosition = simd_mul(simd_inverse(camera.transform), worldPosition)
        guard cameraSpacePosition.z < 0 else { return false }

        let viewportSize = camera.imageResolution
        let projected = camera.projectPoint(
            simd_make_float3(worldPosition),
            orientation: .portrait,
            viewportSize: viewportSize
        )

        return projected.x >= 0 && projected.x <= viewportSize.width
            && projected.y >= 0 && projected.y <= viewportSize.height
    }
}
