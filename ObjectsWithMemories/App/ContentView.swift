import SwiftUI

struct ContentView: View {
    var onSwitchMode: (() -> Void)? = nil

    @StateObject private var sessionManager = ARSessionManager()
    private let memoryRepository: MemoryRepository = FileManagerMemoryRepository()

    @State private var objectForAddMemory: RecognizedObject?
    @State private var isShowingEmbeddingExperiment = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ARCameraView(sessionManager: sessionManager, memoryRepository: memoryRepository)
                .ignoresSafeArea()
            ARDebugOverlayView(state: sessionManager.state, recognitionLog: sessionManager.recognitionLog)
        }
        .overlay(alignment: .bottom) {
            addMemoryButton
        }
        .overlay(alignment: .topTrailing) {
            HStack {
                if !sessionManager.recognitionLog.isEmpty {
                    ShareLink(item: sessionManager.exportLogText()) {
                        Image(systemName: "square.and.arrow.up")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                Button {
                    isShowingEmbeddingExperiment = true
                } label: {
                    Image(systemName: "flask")
                        .padding(10)
                        .background(.thinMaterial, in: Circle())
                }
                if let onSwitchMode {
                    Button(action: onSwitchMode) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                }
            }
            .padding()
        }
        .onAppear { sessionManager.start() }
        .onDisappear { sessionManager.stop() }
        .sheet(item: $objectForAddMemory) { object in
            AddMemorySheet(object: object, repository: memoryRepository)
        }
        .sheet(isPresented: $isShowingEmbeddingExperiment) {
            EmbeddingExperimentView(sessionManager: sessionManager)
        }
    }

    @ViewBuilder
    private var addMemoryButton: some View {
        if !sessionManager.recognizedObjects.isEmpty {
            Menu {
                ForEach(sessionManager.recognizedObjects) { object in
                    Button(object.name) {
                        objectForAddMemory = object
                    }
                }
            } label: {
                Label("Add Memory", systemImage: "plus.circle.fill")
                    .font(.title2)
                    .padding()
                    .background(.thinMaterial, in: Capsule())
            }
            .padding(.bottom, 32)
        }
    }
}
