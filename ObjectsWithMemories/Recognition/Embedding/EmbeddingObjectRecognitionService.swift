import Foundation
import CoreVideo
import UIKit

/// Approach C (Vision embeddings) recognition for Product mode. Unlike
/// `ARKitObjectRecognitionService`, this isn't driven by ARKit's per-frame delegate
/// callbacks — running a Vision request on every ARKit frame would be far too expensive.
/// Instead it polls the latest frame on a timer, mirroring the cadence already proven
/// workable in `EmbeddingExperimentView`'s stress-test loop.
final class EmbeddingObjectRecognitionService: ObjectRecognitionService {
    private let registrationRepository: ObjectRegistrationRepository
    private let pollInterval: TimeInterval
    private let frameProvider: () -> CVPixelBuffer?

    private var references: [EmbeddingMatcher.Reference] = []
    private var registeredObjectsByName: [String: RegisteredObject] = [:]
    private var continuation: AsyncStream<RecognitionEvent>.Continuation?
    private var pollTask: Task<Void, Never>?
    private var currentlyRecognized: RecognizedObject?

    lazy var recognitionEvents: AsyncStream<RecognitionEvent> = AsyncStream { [weak self] continuation in
        self?.continuation = continuation
    }

    init(
        registrationRepository: ObjectRegistrationRepository,
        pollInterval: TimeInterval = 0.5,
        frameProvider: @escaping () -> CVPixelBuffer?
    ) {
        self.registrationRepository = registrationRepository
        self.pollInterval = pollInterval
        self.frameProvider = frameProvider
    }

    func start() {
        reload()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.pollOnce()
                try? await Task.sleep(nanoseconds: UInt64(self.pollInterval * 1_000_000_000))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        continuation?.finish()
    }

    /// Recomputes reference embeddings from disk — call after registering or editing an
    /// object so it's recognizable immediately, without restarting the session.
    func reload() {
        let objects = registrationRepository.allObjects()
        registeredObjectsByName = Dictionary(uniqueKeysWithValues: objects.map { ($0.name, $0) })

        Task {
            var newReferences: [EmbeddingMatcher.Reference] = []
            for object in objects {
                for url in object.photoFileURLs {
                    guard let data = try? Data(contentsOf: url),
                          let uiImage = UIImage(data: data),
                          let cgImage = uiImage.cgImage,
                          let observation = try? await EmbeddingMatcher.featurePrint(
                            for: cgImage,
                            orientation: uiImage.imageOrientation.cgImagePropertyOrientation
                          ) else { continue }
                    newReferences.append(EmbeddingMatcher.Reference(name: object.name, observation: observation))
                }
            }
            self.references = newReferences
        }
    }

    private func pollOnce() async {
        guard !references.isEmpty, let pixelBuffer = frameProvider() else { return }
        guard let candidate = try? await EmbeddingMatcher.featurePrint(for: pixelBuffer),
              let matches = try? EmbeddingMatcher.nearestMatches(for: candidate, references: references) else {
            return
        }

        guard let best = matches.best,
              best.distance < EmbeddingMatcher.recognitionThreshold,
              let registeredObject = registeredObjectsByName[best.name] else {
            if let lost = currentlyRecognized {
                currentlyRecognized = nil
                continuation?.yield(.objectLost(lost))
            }
            return
        }

        let recognized = registeredObject.recognizedObject
        guard currentlyRecognized?.id != recognized.id else { return }

        if let previous = currentlyRecognized {
            continuation?.yield(.objectLost(previous))
        }
        currentlyRecognized = recognized
        continuation?.yield(.objectRecognized(recognized))
    }
}
