import SwiftUI
import PhotosUI
import Vision
import ImageIO
import UIKit

private let recognitionThreshold = EmbeddingMatcher.recognitionThreshold
private let stressTestTimeout: TimeInterval = 20

private struct StressTestLogEntry: Identifiable {
    let id = UUID()
    let expectedObject: String
    let condition: String
    let detected: Bool
    let elapsedSeconds: TimeInterval
    let bestMatchName: String
    let bestDistance: Double
    /// What the camera saw at the moment the test finished (success or timeout) — lets you
    /// visually review why a condition passed or failed after the fact.
    let capturedImage: UIImage?
}

struct EmbeddingExperimentView: View {
    let sessionManager: ARSessionManager

    @State private var references: [EmbeddingMatcher.Reference] = []
    @State private var results: [(name: String, distance: Double)] = []
    @State private var newObjectName = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var statusMessage = ""

    @State private var expectedObjectName = ""
    @State private var conditionLabel = ""
    @State private var log: [StressTestLogEntry] = []
    @State private var isTesting = false
    @State private var liveElapsed: TimeInterval = 0
    @State private var testTask: Task<Void, Never>?
    @State private var copiedConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Register Reference (1–5 photos, different angles)") {
                    TextField("Object name", text: $newObjectName)
                    PhotosPicker("Choose Photos", selection: $photoItems, maxSelectionCount: 5, matching: .images)
                }

                Section("Registered (\(registeredNames.count) objects, \(references.count) photos)") {
                    ForEach(registeredNames, id: \.self) { name in
                        Text("\(name) (\(references.filter { $0.name == name }.count) photo(s))")
                    }
                }

                Section("Quick Test") {
                    Button("Test Current Frame") { testCurrentFrame() }
                        .disabled(references.isEmpty)

                    ForEach(results, id: \.name) { result in
                        HStack {
                            Text(result.name)
                            Spacer()
                            Text(String(format: "%.3f", result.distance))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Milestone 10 — Stress Test") {
                    Picker("Expected object", selection: $expectedObjectName) {
                        Text("Select…").tag("")
                        ForEach(registeredNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    TextField("Condition (e.g. Indoor / Front / Close / Plain)", text: $conditionLabel)

                    if isTesting {
                        HStack {
                            ProgressView()
                            Text(String(format: "Testing… %.1fs", liveElapsed))
                            Spacer()
                            Button("Stop") { stopTest(manually: true) }
                        }
                    } else {
                        Button("Start Test") { startTest() }
                            .disabled(expectedObjectName.isEmpty || conditionLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Log (\(log.count))") {
                    ForEach(log.reversed()) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            if let capturedImage = entry.capturedImage {
                                Image(uiImage: capturedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipped()
                                    .cornerRadius(6)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(entry.expectedObject).bold()
                                    Spacer()
                                    Text(entry.detected ? "Detected" : "Not detected")
                                        .foregroundStyle(entry.detected ? .green : .red)
                                }
                                Text(entry.condition).font(.caption).foregroundStyle(.secondary)
                                Text(String(format: "%.1fs · best match: %@ (%.3f)", entry.elapsedSeconds, entry.bestMatchName, entry.bestDistance))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !log.isEmpty {
                        Button(copiedConfirmation ? "Copied!" : "Copy Log as Table") { copyLogToClipboard() }
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Embedding Recognition Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoItems) { _, newValue in
                guard !newValue.isEmpty else { return }
                registerReference(from: newValue)
            }
        }
    }

    private var registeredNames: [String] {
        var seen = Set<String>()
        return references.map(\.name).filter { seen.insert($0).inserted }
    }

    private func registerReference(from items: [PhotosPickerItem]) {
        let name = newObjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            statusMessage = "Enter an object name before picking photos."
            return
        }

        Task {
            var registeredCount = 0
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data),
                          let cgImage = uiImage.cgImage else {
                        continue
                    }

                    let observation = try await EmbeddingMatcher.featurePrint(
                        for: cgImage,
                        orientation: uiImage.imageOrientation.cgImagePropertyOrientation
                    )

                    references.append(EmbeddingMatcher.Reference(name: name, observation: observation))
                    registeredCount += 1
                } catch {
                    statusMessage = "Registration failed on one photo: \(error.localizedDescription)"
                }
            }
            newObjectName = ""
            photoItems = []
            statusMessage = "Registered \(registeredCount) photo(s) for \(name)."
        }
    }

    private func testCurrentFrame() {
        guard let pixelBuffer = sessionManager.session.currentFrame?.capturedImage else {
            statusMessage = "No camera frame available."
            return
        }

        Task {
            do {
                let candidate = try await bestMatch(for: pixelBuffer)
                results = candidate.all.sorted { $0.distance < $1.distance }
                statusMessage = "Tested against \(references.count) reference(s)."
            } catch {
                statusMessage = "Test failed: \(error.localizedDescription)"
            }
        }
    }

    private func startTest() {
        isTesting = true
        liveElapsed = 0
        let expected = expectedObjectName
        let condition = conditionLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = Date()

        testTask = Task {
            while !Task.isCancelled {
                liveElapsed = Date().timeIntervalSince(start)
                let pixelBuffer = sessionManager.session.currentFrame?.capturedImage

                if liveElapsed >= stressTestTimeout {
                    finishTest(expected: expected, condition: condition, start: start, best: nil, pixelBuffer: pixelBuffer)
                    return
                }

                if let pixelBuffer,
                   let candidate = try? await bestMatch(for: pixelBuffer),
                   let best = candidate.best,
                   best.distance < recognitionThreshold {
                    finishTest(expected: expected, condition: condition, start: start, best: best, pixelBuffer: pixelBuffer)
                    return
                }

                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    private func stopTest(manually: Bool) {
        testTask?.cancel()
        testTask = nil
        isTesting = false
    }

    private func finishTest(
        expected: String,
        condition: String,
        start: Date,
        best: (name: String, distance: Double)?,
        pixelBuffer: CVPixelBuffer?
    ) {
        let elapsed = Date().timeIntervalSince(start)
        log.append(StressTestLogEntry(
            expectedObject: expected,
            condition: condition,
            detected: best != nil && best?.name == expected,
            elapsedSeconds: elapsed,
            bestMatchName: best?.name ?? "none",
            bestDistance: best?.distance ?? .infinity,
            capturedImage: pixelBuffer.flatMap { Self.downscaledImage(from: $0) }
        ))
        isTesting = false
        testTask = nil
        conditionLabel = ""
    }

    private static func downscaledImage(from pixelBuffer: CVPixelBuffer, maxDimension: CGFloat = 300) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        let scale = maxDimension / max(ciImage.extent.width, ciImage.extent.height)
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func bestMatch(for pixelBuffer: CVPixelBuffer) async throws -> (all: [(name: String, distance: Double)], best: (name: String, distance: Double)?) {
        let candidate = try await EmbeddingMatcher.featurePrint(for: pixelBuffer)
        return try EmbeddingMatcher.nearestMatches(for: candidate, references: references)
    }

    private func copyLogToClipboard() {
        let header = "Object ID\tCondition\tDetected?\tTime to detection\tConfidence\tTracking stability\tNotes"
        let rows = log.map { entry -> String in
            let detected = entry.detected ? "Yes" : "No"
            let time = String(format: "%.1fs", entry.elapsedSeconds)
            let confidence = entry.bestDistance.isFinite ? String(format: "%.3f (distance, lower=better)", entry.bestDistance) : "n/a"
            let notes = entry.detected ? "" : "best match: \(entry.bestMatchName)"
            return "\(entry.expectedObject)\t\(entry.condition)\t\(detected)\t\(time)\t\(confidence)\tN/A (embeddings, no pose)\t\(notes)"
        }
        UIPasteboard.general.string = ([header] + rows).joined(separator: "\n")
        copiedConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedConfirmation = false }
    }
}
