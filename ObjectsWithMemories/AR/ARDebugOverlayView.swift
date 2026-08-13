import SwiftUI

struct ARDebugOverlayView: View {
    let state: ARSessionState
    let recognitionLog: [RecognitionLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tracking: \(state.trackingStateDescription)")
            Text("Anchors: \(state.anchorCount)")
            Text("FPS: \(String(format: "%.0f", state.fps))")
            if recognitionLog.isEmpty {
                Text("Recognized: none")
            } else {
                ForEach(recognitionLog) { entry in
                    Text(entry.logLine)
                }
            }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .padding()
    }
}
