# Objects With Memories — Roadmap

## Current Status

Current milestone: **Milestone 11 — Product Validation**

Milestone 0 — Project Setup: complete (confirmed on physical iPhone, 2026-07-25).
Milestone 1 — Basic AR Camera: complete (confirmed on physical iPhone, 2026-07-25).
Milestone 2 — Recognition Technology Prototype: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 3 — Recognition Abstraction: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 4 — Spatial Anchoring: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 5 — First Memory Experience: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 6 — Multiple Memory Types: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 7 — Multiple Objects: complete (confirmed on physical iPhone, 2026-07-26).
Milestone 8 — Add a Memory: complete (confirmed on physical iPhone, 2026-07-27).
Milestone 9 — Object Registration Research: complete (Approach C — Learned Visual Embeddings — prototyped and compared against Approach A, 2026-07-28). See DECISIONS.md Decision 006.
Milestone 10 — Recognition Stress Testing: complete (Approach A tested across full lighting/viewpoint/distance/occlusion/background matrix, 2026-08-13). Reliability is not uniform — gated by object surface detail, material, background contrast, and distance range, not object choice alone. See EXPERIMENTS.md and DECISIONS.md Decision 006.

Update this section when a milestone is completed.

---

# Milestone 0 — Project Setup

## Goal

Create a clean, buildable iOS AR project.

## Stack

- Swift
- SwiftUI
- ARKit
- RealityKit
- Xcode

## Deliverables

- Application launches.
- Camera permission is configured.
- Basic AR session can start.
- Project builds on a physical iPhone.
- Initial repository structure exists.

## Success Criteria

The application opens a camera view and displays a minimal AR scene.

---

# Milestone 1 — Basic AR Camera

## Goal

Create a stable AR camera experience.

## Features

- Camera view
- World tracking
- AR session state
- Basic debug information

## Optional Debug Information

- Tracking state
- Camera state
- Number of anchors
- FPS

## Success Criteria

The application can maintain a stable AR world-tracking session on a physical device.

---

# Milestone 2 — Recognition Technology Prototype

## Goal

Test the first object-recognition approach.

The initial implementation may use developer-prepared reference objects.

The object itself is not important. Use several different physical objects to test whether the recognition approach works beyond one carefully tuned example.

## Possible Initial Technology

- ARKit object detection
- `ARReferenceObject`
- `ARObjectAnchor`

## Recognition Pipeline

Physical Object
    ↓
Reference Data
    ↓
AR Session
    ↓
Object Detection
    ↓
Recognized Object ID

## Success Criteria

The application can:

1. Detect multiple objects.
2. Distinguish between different objects.
3. Return a stable object identity.
4. Detect objects from different viewpoints.
5. Detect objects under different normal lighting conditions.

The recognition system should return a generic result such as:

```swift
RecognizedObject(
    id: objectID,
    confidence: confidence
)
```

The rest of the application should not care how recognition occurred.

---

# Milestone 3 — Recognition Abstraction

## Goal

Separate the product from the specific recognition technology.

Create an abstraction similar to:

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

The application should depend on the abstraction rather than directly coupling every feature to ARKit.

---

# Milestone 4 — Spatial Anchoring

## Goal

Place virtual content relative to the detected physical object.

## Pipeline

Recognition Event
    ↓
Object Identity
    ↓
Physical Object Anchor
    ↓
RealityKit AnchorEntity
    ↓
Virtual Content

## Test Content

Start with:

- Cube
- Sphere
- Text
- Image

## Success Criteria

Virtual content:

- Appears relative to the object.
- Moves with the object.
- Remains spatially stable.
- Can be positioned using object-relative coordinates.

Do not use hardcoded global world coordinates.

---

# Milestone 5 — First Memory Experience

## Goal

Replace test geometry with personal media.

## Example

Object detected
    ↓
Object ID
    ↓
Memory Repository
    ↓
Associated Memory
    ↓
AR Memory Presentation

The first version may use a hardcoded local memory.

The purpose is to test the emotional experience.

## Success Criteria

A user can:

1. Point the camera at an object.
2. Have the object recognized.
3. See a personal memory appear.
4. Understand the relationship between the object and the memory.
5. Move around and observe the memory remaining spatially connected to the object.

This is the first true product prototype.

---

# Milestone 6 — Multiple Memory Types

## Goal

Support different forms of personal memory.

### Image

A spatially anchored image.

### Video

A video surface attached to the object.

### Audio

A spatially anchored audio interaction.

### Text

A short memory or note attached to the object.

Create a common presentation interface so different memory types can have different implementations.

Example:

```swift
protocol MemoryPresenter {
    func present(_ memory: Memory, relativeTo anchor: AnchorEntity)
}
```

---

# Milestone 7 — Multiple Objects

## Goal

Prove the concept works with a collection of unrelated physical objects.

Example:

Object A
    ↓
Photo Memory

Object B
    ↓
Video Memory

Object C
    ↓
Audio Memory

## Success Criteria

The application:

- Identifies different objects.
- Retrieves the correct memories.
- Does not mix memories between objects.
- Supports multiple memories per object.

---

# Milestone 8 — Add a Memory

## Goal

Allow a user to attach new content to an object.

## User Flow

Scan Object
    ↓
Object Recognized
    ↓
Add Memory
    ↓
Choose:
    ├── Photo
    ├── Video
    ├── Audio
    └── Text
    ↓
Save
    ↓
Memory Associated With Object

## Initial Implementation

Use local storage.

No account or backend is required.

## Success Criteria

The user can:

1. Recognize an object.
2. Add a memory.
3. Close the application.
4. Reopen the application.
5. Recognize the same object.
6. Access the saved memory.

---

# Milestone 9 — Object Registration Research

## Goal

Investigate how users can register arbitrary physical objects.

This is a dedicated technical research milestone.

Possible approaches:

### Approach A — ARKit Object Scanning

Investigate whether an object can be scanned and converted into usable recognition data.

### Approach B — Feature-Based Recognition

Possible components:

- Keypoint detection
- Feature descriptors
- Feature matching
- RANSAC
- Homography estimation
- Pose estimation

### Approach C — Learned Visual Embeddings

Possible components:

- Image encoder
- Object embeddings
- Similarity search
- On-device inference

### Approach D — 3D Reconstruction

Possible components:

- Multi-view capture
- Depth data
- Point clouds
- Mesh reconstruction

Do not implement all approaches.

The goal is to experimentally determine which approach best satisfies:

- Recognition reliability
- User registration simplicity
- On-device performance
- Privacy
- Robustness to viewpoint and lighting

---

# Milestone 10 — Recognition Stress Testing

## Goal

Measure recognition reliability.

Test each object under:

### Lighting

- Bright daylight
- Indoor lighting
- Low light
- Shadows

### Viewpoint

- Front
- Side
- Back
- Top
- Partial view

### Distance

- Close
- Medium
- Far

### Occlusion

- Partially covered
- Partially hidden

### Background

- Plain
- Cluttered
- Similar colors

Record:

```text
Object ID
Condition
Detected?
Time to detection
Confidence
Tracking stability
Notes
```

The purpose is to determine whether recognition is reliable enough for ordinary users.

---

# Milestone 11 — Product Validation

## Goal

Test whether the experience has real emotional and product value.

Test with approximately 5–10 people.

Do not explain the entire concept before testing.

Observe:

1. Do users understand what to do?
2. Can they discover the memory?
3. Do they understand that the memory belongs to the physical object?
4. Does the experience feel different from opening the same media in Photos?
5. Do they want to scan another object?
6. Do they immediately think of objects from their own lives that they would use?

Strong validation may be spontaneous reactions such as:

> "I want this for my childhood toys."

or:

> "I have a box of things from my grandmother that I would use this with."

---

# Final MVP Definition

The MVP is complete when this experience works:

User has a physical object
    ↓
User opens the application
    ↓
User points the camera at the object
    ↓
The object is visually recognized
    ↓
The object receives an AR anchor
    ↓
Associated memory is retrieved
    ↓
Memory appears spatially attached to object
    ↓
User can add another memory

The MVP should support:

- Multiple arbitrary objects.
- Multiple memories per object.
- At least three media types.
- Local persistence.
- Basic memory creation.
- Spatially anchored presentation.
- A replaceable recognition layer.
