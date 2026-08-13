import Vision
import CoreVideo
import CoreGraphics
import UIKit

/// Shared matching logic for Approach C (Vision embeddings) recognition, used by both
/// the Milestone 9/10 experiment tooling and the product recognition service, so the
/// two surfaces can't silently drift apart on threshold or matching behavior.
enum EmbeddingMatcher {
    /// Distance below which a candidate is considered a match to a reference.
    /// Chosen from Milestone 9 findings (Decision 006): same-object distances
    /// clustered ~0.3-0.5, different-object ~0.8-1.2.
    static let recognitionThreshold = 0.6

    struct Reference {
        let name: String
        let observation: FeaturePrintObservation
    }

    static func featurePrint(for cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> FeaturePrintObservation {
        try await GenerateImageFeaturePrintRequest().perform(on: cgImage, orientation: orientation)
    }

    static func featurePrint(for pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async throws -> FeaturePrintObservation {
        try await GenerateImageFeaturePrintRequest().perform(on: pixelBuffer, orientation: orientation)
    }

    /// Nearest-of-any-registered-photo distance per object name, sorted closest-first.
    static func nearestMatches(
        for candidate: FeaturePrintObservation,
        references: [Reference]
    ) throws -> (all: [(name: String, distance: Double)], best: (name: String, distance: Double)?) {
        var nearestDistanceByName: [String: Double] = [:]
        for reference in references {
            let distance = try candidate.distance(to: reference.observation)
            if let existing = nearestDistanceByName[reference.name] {
                nearestDistanceByName[reference.name] = min(existing, distance)
            } else {
                nearestDistanceByName[reference.name] = distance
            }
        }
        let sorted = nearestDistanceByName.map { (name: $0.key, distance: $0.value) }.sorted { $0.distance < $1.distance }
        return (sorted, sorted.first)
    }
}

extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
