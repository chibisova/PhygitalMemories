# Objects With Memories

## Project Overview

Objects With Memories is a camera-based AR application that connects physical objects with personal digital memories.

The user points a phone camera at a physical object. The application visually recognizes the object without requiring QR codes, NFC tags, or other physical markers. Once recognized, the application retrieves memories associated with that specific object and presents them spatially anchored to the physical object.

Core interaction:

Physical object
    ↓
Visual recognition
    ↓
Object identity
    ↓
Associated memory
    ↓
Spatially anchored AR content

The product hypothesis is:

> People may find it meaningful to access personal memories by looking at the physical objects associated with those memories.

The product should make the user feel:

> "This object remembers."

The physical object is the interface.

---

## Current Goal

This project is currently in the prototype stage.

The immediate goal is to validate the core technical loop:

1. Recognize a physical object.
2. Assign it a stable identity.
3. Associate a digital memory with that identity.
4. Display the memory spatially anchored to the object.

The current milestone and detailed implementation plan are defined in:

> `documentation/ROADMAP.md`

Before implementing a new feature, check the relevant milestone in `documentation/ROADMAP.md`.

---

## Technical Stack

### Platform

- iOS
- Swift
- Xcode

### AR

- ARKit
- RealityKit

### UI

- SwiftUI

### Media

- Photos
- Videos
- Audio

Relevant frameworks:

- PhotosUI
- AVFoundation
- AVKit

### Persistence

Start with local storage.

Do not introduce a backend, authentication, or cloud infrastructure until the core product experience has been validated.

---

## Architecture

The application is organized around the following pipeline:

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

The main conceptual layers are:

### Recognition

Answers:

> What physical object is currently visible?

Possible implementations may include:

- ARKit object recognition
- Feature matching
- Computer vision
- Machine learning

The recognition technology must remain replaceable.

### Object Identity

Answers:

> Which registered object does this correspond to?

The rest of the application should work with stable object IDs rather than depending on a specific recognition technology.

### Memory

Stores content associated with an object:

- Images
- Videos
- Audio
- Text

### AR Presentation

Converts memories into spatially anchored RealityKit content.

---

## Architecture Principles

### 1. Recognition Is Replaceable

Do not tightly couple the application to one recognition technology.

The application should depend on a recognition abstraction that produces a generic recognition result and object ID.

### 2. Objects Are Generic

Never hardcode logic for a specific physical object.

Avoid:

```swift
if object.name == "SpecificObject" {
    showVideo(...)
}
```

Prefer:

```swift
let memories = memoryRepository.memories(for: object.id)
```

The architecture should work for arbitrary user-owned objects.

### 3. Separate Recognition From Memory

Recognition determines:

> Which object is present?

The memory system determines:

> What content belongs to that object?

These must remain separate.

### 4. Separate Memory From AR Presentation

A `Memory` should not know how it is rendered.

The same memory may eventually be presented through:

- AR
- An object library
- A timeline
- Other interfaces

### 5. Use Object-Relative Coordinates

Memory content must be positioned relative to the physical object's anchor.

Do not rely on hardcoded global world coordinates.

### 6. Local First

Prefer local storage during the prototype phase.

Do not build:

- Authentication
- Backend services
- Cloud synchronization
- Social features

until product validation justifies them.

### 7. Build the Smallest Testable Version

Every implementation should answer a concrete technical or product question.

Avoid building infrastructure for hypothetical future requirements.

---

## Project Structure

Organize code by responsibility:

```text
ObjectsWithMemories/
│
├── App/
├── AR/
├── Recognition/
├── ARContent/
├── Models/
├── Persistence/
├── Features/
├── Services/
├── Resources/
└── Tests/
```

Keep detailed file responsibilities and architecture decisions in:

> `documentation/ARCHITECTURE.md`

---

## Development Workflow

Before implementing a feature:

1. Inspect the existing repository.
2. Read the relevant section of `documentation/ROADMAP.md`.
3. Identify the smallest implementation needed.
4. Check whether the architecture already has an appropriate abstraction.
5. Implement only the requested scope.
6. Build the project.
7. Fix compilation errors.
8. Run relevant tests.
9. Test on a physical iPhone when the feature depends on AR or camera behavior.
10. Report what changed and what remains untested.

---

## Code Rules

- Do not rewrite unrelated code.
- Do not introduce dependencies without a clear reason.
- Do not implement future milestones prematurely.
- Do not create abstractions solely for hypothetical future use.
- Prefer simple, readable implementations.
- Keep AR session management separate from content presentation.
- Keep persistence separate from UI.
- Keep object recognition replaceable.
- Use stable object IDs for object-memory relationships.

---

## Current Milestone

The current implementation priority is:

> **Milestone 11: Product Validation**

After completing a milestone:

1. Verify the success criteria in `documentation/ROADMAP.md`.
2. Update the current milestone in this file if appropriate.
3. Record important technical findings in `documentation/EXPERIMENTS.md`.
4. Do not advance to the next milestone without confirming the current milestone works.

---

## Documentation

### `documentation/ROADMAP.md`

Contains:

- Milestones
- Goals
- Technical experiments
- Success criteria
- Future implementation stages

Read only the relevant milestone section when working on a task.

### `documentation/ARCHITECTURE.md`

Contains:

- Detailed architecture
- Data models
- Service interfaces
- Recognition abstraction
- Persistence design
- AR content pipeline

### `documentation/DECISIONS.md`

Contains:

- Important architectural decisions
- The reasoning behind those decisions
- Conditions under which decisions should be revisited

### `documentation/EXPERIMENTS.md`

Contains:

- Recognition experiments
- Test conditions
- Results
- Performance measurements
- Technical failures
- Decisions based on experiments

Keep documentation synchronized with actual implementation.

---

## Definition of Done

A feature is complete when:

- The implementation is present.
- The project builds successfully.
- Existing functionality still works.
- Relevant tests pass.
- AR features are tested on a physical device when applicable.
- The implementation is no more complex than necessary.
- Relevant documentation is updated.
