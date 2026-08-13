import SwiftUI

struct ProductModeView: View {
    var onSwitchMode: (() -> Void)? = nil

    @StateObject private var sessionManager = ProductARSessionManager(
        registrationRepository: FileManagerObjectRegistrationRepository()
    )
    private let objectRegistrationRepository: ObjectRegistrationRepository = FileManagerObjectRegistrationRepository()
    private let memoryRepository: MemoryRepository = FileManagerMemoryRepository()

    @State private var isShowingRegisterSheet = false
    @State private var isShowingLibrary = false

    var body: some View {
        ProductARCameraView(sessionManager: sessionManager, memoryRepository: memoryRepository)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Button {
                    isShowingRegisterSheet = true
                } label: {
                    Label("Add Memory", systemImage: "plus.circle.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.bottom, 32)
            }
            .overlay(alignment: .topTrailing) {
                HStack {
                    Button {
                        isShowingLibrary = true
                    } label: {
                        Image(systemName: "books.vertical")
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
            .sheet(isPresented: $isShowingRegisterSheet) {
                RegisterObjectSheet(
                    objectRegistrationRepository: objectRegistrationRepository,
                    memoryRepository: memoryRepository,
                    onSaved: { sessionManager.reloadRegisteredObjects() },
                    onMemoriesChanged: { sessionManager.notifyMemoriesChanged(for: $0) }
                )
            }
            .sheet(isPresented: $isShowingLibrary) {
                ObjectLibraryView(
                    objectRegistrationRepository: objectRegistrationRepository,
                    memoryRepository: memoryRepository,
                    onChanged: { sessionManager.reloadRegisteredObjects() },
                    onMemoriesChanged: { sessionManager.notifyMemoriesChanged(for: $0) }
                )
            }
    }
}
