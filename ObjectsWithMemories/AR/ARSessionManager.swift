import ARKit

final class ARSessionManager: NSObject, ObservableObject {
    let session = ARSession()

    @Published private(set) var state = ARSessionState()
    @Published private(set) var recognizedObjects: [RecognizedObject] = []
    @Published private(set) var recognitionLog: [RecognitionLogEntry] = []

    var objectRecognitionService: ObjectRecognitionService { recognitionService }

    var onObjectAnchorAdded: ((ARObjectAnchor, RecognizedObject?) -> Void)?
    var onObjectAnchorRemoved: ((ARObjectAnchor) -> Void)?

    private let recognitionService = ARKitObjectRecognitionService()
    private var recognitionTask: Task<Void, Never>?
    private var lastFrameTimestamp: TimeInterval?

    private var sessionStartTime: Date?
    private var lastLostAt: [UUID: Date] = [:]
    private var lastDetectionLatency: [UUID: TimeInterval] = [:]
    private var lossCounts: [UUID: Int] = [:]

    override init() {
        super.init()
        session.delegate = self
        recognitionTask = Task { [weak self] in
            guard let self else { return }
            for await event in self.recognitionService.recognitionEvents {
                await MainActor.run { self.apply(event) }
            }
        }
    }

    deinit {
        recognitionTask?.cancel()
    }

    func start() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionObjects = recognitionService.referenceObjects
        session.run(configuration)
        recognitionService.start()
        sessionStartTime = Date()
        lastLostAt = [:]
        lastDetectionLatency = [:]
        lossCounts = [:]
        recognitionLog = []
    }

    func stop() {
        session.pause()
        recognitionService.stop()
    }

    func exportLogText() -> String {
        let header = "Recognition log export — \(Date())"
        return ([header] + recognitionLog.map(\.logLine)).joined(separator: "\n")
    }

    private func apply(_ event: RecognitionEvent) {
        let object: RecognizedObject
        switch event {
        case .objectRecognized(let recognized):
            object = recognized
            if !recognizedObjects.contains(where: { $0.id == object.id }) {
                recognizedObjects.append(object)
            }
            let referenceTime = lastLostAt[object.id] ?? sessionStartTime
            if let referenceTime {
                lastDetectionLatency[object.id] = Date().timeIntervalSince(referenceTime)
            }
        case .objectLost(let lost):
            object = lost
            recognizedObjects.removeAll { $0.id == object.id }
            lastLostAt[object.id] = Date()
            lossCounts[object.id, default: 0] += 1
        }
        updateRecognitionLog(with: object)
    }

    private func updateRecognitionLog(with object: RecognizedObject) {
        let isTracked = recognizedObjects.contains { $0.id == object.id }
        let entry = RecognitionLogEntry(
            id: object.id,
            name: object.name,
            confidence: object.confidence,
            isCurrentlyTracked: isTracked,
            lastDetectionLatency: lastDetectionLatency[object.id],
            lossCount: lossCounts[object.id, default: 0]
        )
        if let index = recognitionLog.firstIndex(where: { $0.id == object.id }) {
            recognitionLog[index] = entry
        } else {
            recognitionLog.append(entry)
        }
    }

    private static func description(for trackingState: ARCamera.TrackingState) -> String {
        switch trackingState {
        case .normal:
            return "Normal"
        case .notAvailable:
            return "Not Available"
        case .limited(.initializing):
            return "Limited (Initializing)"
        case .limited(.excessiveMotion):
            return "Limited (Excessive Motion)"
        case .limited(.insufficientFeatures):
            return "Limited (Insufficient Features)"
        case .limited(.relocalizing):
            return "Limited (Relocalizing)"
        case .limited:
            return "Limited"
        }
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        recognitionService.handle(didAdd: anchors)
        let objectAnchors = anchors.compactMap { $0 as? ARObjectAnchor }
        guard !objectAnchors.isEmpty else { return }

        DispatchQueue.main.async {
            for objectAnchor in objectAnchors {
                self.onObjectAnchorAdded?(objectAnchor, self.recognitionService.recognizedObject(for: objectAnchor))
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        recognitionService.handle(didRemove: anchors)
        let objectAnchors = anchors.compactMap { $0 as? ARObjectAnchor }
        guard !objectAnchors.isEmpty else { return }

        DispatchQueue.main.async {
            for objectAnchor in objectAnchors {
                self.onObjectAnchorRemoved?(objectAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        var fps = state.fps
        if let last = lastFrameTimestamp {
            let delta = frame.timestamp - last
            if delta > 0 {
                fps = 1.0 / delta
            }
        }
        lastFrameTimestamp = frame.timestamp

        let newState = ARSessionState(
            trackingState: frame.camera.trackingState,
            trackingStateDescription: Self.description(for: frame.camera.trackingState),
            anchorCount: frame.anchors.count,
            fps: fps
        )

        recognitionService.handle(didUpdate: frame)

        DispatchQueue.main.async {
            self.state = newState
        }
    }
}
