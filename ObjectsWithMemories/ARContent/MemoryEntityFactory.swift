import RealityKit

enum MemoryEntityFactory {
    static func present(_ memory: Memory, relativeTo anchor: AnchorEntity) {
        presenter(for: memory.type).present(memory, relativeTo: anchor)
    }

    private static func presenter(for type: MemoryType) -> MemoryPresenter {
        switch type {
        case .image:
            return ImageMemoryPresenter()
        case .video:
            return VideoMemoryPresenter()
        case .audio:
            return AudioMemoryPresenter()
        case .text:
            return TextMemoryPresenter()
        }
    }
}
