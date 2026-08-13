# Objects With Memories — Architecture

## System Overview

Camera Input
    ↓
Object Recognition
    ↓
Object Identity
    ↓
Memory Repository
    ↓
AR Content Presentation
    ↓
Spatially Anchored Experience

---

## Core Components

### Recognition

Answers:

> What physical object is currently visible?

The recognition implementation must be replaceable.

Potential implementations:

- ARKit object recognition
- Feature matching
- Computer vision
- Machine learning

### Object Identity

Answers:

> Which registered object does this correspond to?

All downstream systems should use stable object IDs.

### Memory Repository

Stores memories associated with object IDs.

### AR Content Presentation

Converts memories into RealityKit entities and places them relative to the recognized object anchor.

---

## Recommended Project Structure

```text
ObjectsWithMemories/
│
├── App/
│   ├── ObjectsWithMemoriesApp.swift
│   └── AppState.swift
│
├── AR/
│   ├── ARSessionManager.swift
│   ├── ARConfiguration.swift
│   ├── ARAnchorManager.swift
│   ├── ARContentPlacement.swift
│   └── ARSessionState.swift
│
├── Recognition/
│   ├── ObjectRecognitionService.swift
│   ├── RecognitionEvent.swift
│   ├── RecognitionResult.swift
│   │
│   ├── ARKit/
│   │   └── ARKitObjectRecognitionService.swift
│   │
│   ├── FeatureMatching/
│   │   └── FeatureMatchingRecognitionService.swift
│   │
│   └── ML/
│       └── MLObjectRecognitionService.swift
│
├── ARContent/
│   ├── MemoryEntityFactory.swift
│   ├── ImageMemoryEntity.swift
│   ├── VideoMemoryEntity.swift
│   ├── AudioMemoryEntity.swift
│   ├── TextMemoryEntity.swift
│   └── MemoryPlacement.swift
│
├── Models/
│   ├── RecognizedObject.swift
│   ├── Memory.swift
│   ├── MemoryType.swift
│   └── SpatialOffset.swift
│
├── Persistence/
│   ├── ObjectRepository.swift
│   ├── MemoryRepository.swift
│   ├── LocalStorage.swift
│   └── FileManagerStorage.swift
│
├── Features/
│   ├── Scanner/
│   ├── ObjectDetails/
│   ├── MemoryCreation/
│   ├── MemoryViewer/
│   └── ObjectLibrary/
│
├── Services/
│   ├── MediaImportService.swift
│   ├── VideoPlaybackService.swift
│   ├── AudioPlaybackService.swift
│   └── ObjectRegistrationService.swift
│
├── Resources/
│   └── SampleData/
│
└── Tests/
```

---

## Data Model

### RecognizedObject

```swift
struct RecognizedObject {
    let id: UUID
    var name: String
    var thumbnailPath: String?
    var recognitionDataPath: String?
    let createdAt: Date
}
```

The object should be identified by a stable internal ID. The display name is metadata only.

### Memory

```swift
struct Memory {
    let id: UUID
    let objectID: UUID
    let type: MemoryType
    let localFilePath: String
    var title: String?
    let createdAt: Date
    var spatialOffset: SpatialOffset?
}
```

### MemoryType

```swift
enum MemoryType {
    case image
    case video
    case audio
    case text
}
```

### SpatialOffset

Memory content should have a preferred transform relative to the recognized object's coordinate system.

```swift
struct SpatialOffset {
    var position: Vector3
    var rotation: Quaternion
    var scale: Vector3
}
```

---

## Recognition Abstraction

The rest of the application should not depend directly on a specific recognition technology.

Conceptually:

```swift
protocol ObjectRecognitionService {
    func start()
    func stop()
    var recognitionEvents: AsyncStream<RecognitionEvent> { get }
}
```

Possible implementations:

```text
ObjectRecognitionService
        │
        ├── ARKitObjectRecognitionService
        ├── FeatureMatchingRecognitionService
        └── MLObjectRecognitionService
```

---

## Recognition and Identity

These are separate concepts.

```text
Visual Input
      ↓
Recognition
      ↓
Recognition Result
      ↓
Object ID
      ↓
Memory Lookup
```

Recognition answers:

> What does the camera currently see?

Identity answers:

> Which registered object does this correspond to?

---

## Memory and AR Presentation

A `Memory` should not know how it is rendered in AR.

Conceptually:

```text
Memory Repository
      ↓
Memory
      ↓
Memory Presenter
      ↓
RealityKit Entity
```

Possible presenter implementations:

- Image memory presenter
- Video memory presenter
- Audio memory presenter
- Text memory presenter

---

## Object-Relative Coordinates

Memory content should be positioned relative to the physical object.

Avoid:

```text
World Position = (1.5, 0.3, -2.0)
```

Prefer:

```text
Object Anchor
      ↓
Memory Offset
      ↓
Content Position
```

This is essential to the feeling that the memory belongs to the object.

---

## Local Storage

The first version should use local storage.

Possible structure:

```text
Application Documents Directory
│
├── Objects/
│   │
│   ├── Object_001/
│   │   ├── metadata.json
│   │   ├── recognition_data
│   │   ├── thumbnail.jpg
│   │   └── Memories/
│   │       ├── memory_001.jpg
│   │       └── memory_002.mp4
│   │
│   └── Object_002/
│       ├── metadata.json
│       ├── recognition_data
│       └── Memories/
```

The recognition data format may change depending on the selected recognition technology.

That detail should be hidden behind the recognition and persistence layers.

---

## Dependency Direction

Prefer:

```text
Features
    ↓
Application Services
    ↓
Domain Models / Repositories
    ↓
Recognition / AR / Storage Implementations
```

Avoid allowing UI views to directly manage:

- AR sessions
- File storage
- Recognition implementation details

---

## Design Goal

The system should be able to replace the recognition technology without rewriting:

- Memory models
- Memory repositories
- Object-memory associations
- AR content presentation
- Most of the user interface

---

## Implemented: Experiment Mode vs. Product Mode

The app launches into a mode picker (`RootView` → `ModeSelectionView`), with a switch-mode button available from within either mode. This split keeps the recognition-testing tooling (Milestone 9/10) fully intact while giving Product mode its own, simpler pipeline built on the milestone findings.

**Experiment mode** (`ContentView`) is unchanged from the stress-testing work: `ARSessionManager` + `ARKitObjectRecognitionService` (Approach A) drives the main camera view, with `EmbeddingExperimentView` (Approach C, flask icon) as a separate manual-testing surface.

**Product mode** (`ProductModeView`) is a parallel, additive pipeline — it does not touch Experiment mode's classes:

- `EmbeddingObjectRecognitionService` (`Recognition/Embedding/`) — conforms to `ObjectRecognitionService` like `ARKitObjectRecognitionService` does, but is driven by polling (~0.5s) rather than ARKit's per-frame delegate, since running a Vision request on every frame would be too expensive. Matching logic (distance threshold, nearest-of-any-registered-photo) lives in `EmbeddingMatcher`, shared with `EmbeddingExperimentView` so the two surfaces can't drift apart on behavior.
- `ProductARSessionManager` (`AR/`) — a plain `ARSession` with plane detection on, no `detectionObjects`. Owns the recognition service and forwards recognized/lost events.
- `ProductARCameraView` (`AR/`) — on recognition, raycasts from screen center against the detected surface and drops a world-fixed `AnchorEntity` there, populated via the same `MemoryEntityFactory` Experiment mode uses. See Decision 006/007: Approach C has no pose, so this is a placement heuristic, not object tracking — content stays where it was placed even if the physical object moves.
- `ObjectRegistrationRepository` / `FileManagerObjectRegistrationRepository` (`Persistence/`) — stores an object's registration photos under `Documents/Objects/<stableID>/ReferencePhotos/`, alongside its `Memories/` folder (same `MemoryRepository` storage, same `StableObjectID`-derived directory). Renaming an object moves the whole `Documents/Objects/<id>` directory in one operation, so photos and memories migrate together.
- `Features/ProductMode/` — `RegisterObjectSheet` (register + attach memories in one flow), `ObjectLibraryView` / `EditObjectView` (rename, edit reference photos, edit memories).
