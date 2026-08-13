import ARKit

struct ARSessionState {
    var trackingState: ARCamera.TrackingState = .notAvailable
    var trackingStateDescription: String = "Not Available"
    var anchorCount: Int = 0
    var fps: Double = 0
}
