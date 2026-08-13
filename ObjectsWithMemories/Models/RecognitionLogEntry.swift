import Foundation

/// Per-object recognition stats accumulated across a session, for manual
/// stress testing (Milestone 10). Not persisted — reset on relaunch.
struct RecognitionLogEntry: Identifiable {
    let id: UUID
    let name: String
    let confidence: Float
    let isCurrentlyTracked: Bool
    /// Seconds between losing sight of the object (or session start, if
    /// never seen before) and the most recent re-detection. Nil until the
    /// object has been detected at least once.
    let lastDetectionLatency: TimeInterval?
    /// Number of times the object went from tracked to lost. A rough
    /// stability signal — frequent flicker under a given test condition
    /// shows up as a fast-climbing count.
    let lossCount: Int

    var logLine: String {
        let status = isCurrentlyTracked ? "tracked" : "lost"
        let latency = lastDetectionLatency.map { String(format: "%.1fs", $0) } ?? "—"
        return "\(name): \(status), detect \(latency), losses \(lossCount)"
    }
}
