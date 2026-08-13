import ARKit

/// Product mode's AR session driver. Unlike `ARSessionManager` (Experiment mode,
/// ARKit reference-object scanning), this doesn't use `detectionObjects` at all —
/// identity comes entirely from `EmbeddingObjectRecognitionService` (Approach C).
/// Plane detection is enabled so `ProductARCameraView` can raycast a placement point
/// once an object is recognized (Decision 006: embeddings have no pose of their own).
final class ProductARSessionManager: ObservableObject {
    let session = ARSession()

    var onObjectRecognized: ((RecognizedObject) -> Void)?
    var onObjectLost: ((RecognizedObject) -> Void)?
    /// Set by `ProductARCameraView` so already-placed content can be refreshed on demand —
    /// see `notifyMemoriesChanged(for:)`.
    var onMemoriesChanged: ((UUID) -> Void)?
    /// Set by `ProductARCameraView` so an already-placed anchor can be torn down —
    /// see `notifyObjectDeleted(for:)`.
    var onObjectDeleted: ((UUID) -> Void)?

    private let registrationRepository: ObjectRegistrationRepository
    private var recognitionService: EmbeddingObjectRecognitionService?
    private var recognitionTask: Task<Void, Never>?

    init(registrationRepository: ObjectRegistrationRepository) {
        self.registrationRepository = registrationRepository
    }

    func start() {
        let service = EmbeddingObjectRecognitionService(
            registrationRepository: registrationRepository,
            frameProvider: { [weak self] in self?.session.currentFrame?.capturedImage }
        )
        recognitionService = service
        recognitionTask = Task { [weak self] in
            for await event in service.recognitionEvents {
                await MainActor.run {
                    switch event {
                    case .objectRecognized(let object):
                        self?.onObjectRecognized?(object)
                    case .objectLost(let object):
                        self?.onObjectLost?(object)
                    }
                }
            }
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        session.run(configuration)
        service.start()
    }

    func stop() {
        session.pause()
        recognitionService?.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionService = nil
    }

    /// Call after registering or editing an object so it's recognizable immediately.
    func reloadRegisteredObjects() {
        recognitionService?.reload()
    }

    /// Call after adding/deleting a memory so already-placed AR content picks up the
    /// change without waiting for the object to be re-recognized (or the app relaunched).
    func notifyMemoriesChanged(for objectID: UUID) {
        onMemoriesChanged?(objectID)
    }

    /// Call after deleting a registered object so any already-placed AR content for it
    /// is removed immediately, and it stops being recognizable going forward.
    func notifyObjectDeleted(for objectID: UUID) {
        recognitionService?.reload()
        onObjectDeleted?(objectID)
    }
}
