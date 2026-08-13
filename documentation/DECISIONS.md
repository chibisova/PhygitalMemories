# Objects With Memories — Architectural Decisions

## Decision 001 — Local Storage First

**Status:** Accepted

### Decision

Use local storage during the prototype and MVP validation stages.

### Reason

The current goal is to validate:

- Object recognition
- Object-memory association
- Spatial AR presentation
- Product/emotional value

Cloud infrastructure is not required to test these hypotheses.

### Revisit When

Consider backend infrastructure when users need:

- Cross-device synchronization
- Cloud backup
- Sharing
- Multi-user access
- Remote media storage

---

## Decision 002 — Recognition Must Be Replaceable

**Status:** Accepted

### Decision

The application should not be architecturally coupled to one object-recognition technology.

### Reason

The final recognition approach is still an open technical question.

Possible approaches include:

- ARKit object recognition
- Feature matching
- Learned visual embeddings
- Custom computer vision
- 3D reconstruction

The first prototype may use one approach, while the final product may require another.

### Consequence

Recognition should be accessed through an abstraction that produces object identities or recognition events.

---

## Decision 003 — Objects Are Generic

**Status:** Accepted

### Decision

Do not hardcode behavior for specific physical objects.

### Reason

The product is intended for arbitrary personal objects.

The architecture should scale from a few prototype objects to a larger user-owned object collection.

---

## Decision 004 — Object-Relative Memory Placement

**Status:** Accepted

### Decision

Memory content should be positioned relative to the recognized object's coordinate system.

### Reason

The product experience depends on the perception that the memory belongs to the physical object.

Global world coordinates are not appropriate for this interaction.

---

## Decision 005 — Build the Smallest Testable Version

**Status:** Accepted

### Decision

Each implementation should answer a concrete technical or product question.

### Reason

The project is an experiment as much as it is a product.

Avoid building:

- Authentication
- Social systems
- Backend infrastructure
- Complex abstractions
- Advanced ML

before the core interaction has been validated.

---

## Decision 006 — Recognition Technology: Embeddings Favored for Identity, ARKit Scanning Still Needed for Pose

**Status:** Accepted — Milestone 10 confirms Approach A fails on low-texture/glossy/plain objects regardless of lighting or background. Approach C remains the stronger identity path; pose-for-embeddings is now the actual blocker, not recognition reliability.

### Decision

Learned visual embeddings (Vision's `GenerateImageFeaturePrintRequest`, Approach C) is the preferred approach for *object identity/registration* going forward — it registers from a single photo and, in testing, recognized objects ARKit scanning could not. ARKit object scanning (`ARReferenceObject` / `ARObjectAnchor`, Approach A) is still needed wherever continuous 6DOF pose is required to spatially anchor content, since embeddings provide identity only.

### Reason

Milestone 9 prototyped Approach C against the existing Approach A baseline from Milestone 2, across 4 objects total:

- **Registration simplicity:** Approach C wins clearly — one photo vs. ARKit's multi-step scan/bounding-box/walk-around flow.
- **Recognition reliability:** Approach C showed a clean separation between same-object (~0.3–0.5) and different-object (~0.8–1.2) embedding distances across 3 initial test objects, correct match always ranked closest.
- **Robustness to low-texture objects — the deciding factor:** Approach A failed outright on `Scan_controller` (a glossy, low-texture AC remote — Milestone 2 finding). Approach C recognized the same object reliably (~0.4–0.6 across varying conditions), because it works on whole-image semantic embeddings rather than local geometric feature matching, so it isn't equally starved by a texture-poor surface.
- **Spatial anchoring:** Approach A still wins here — `ARObjectAnchor` provides pose tracking that Approach C cannot. No spatial-anchoring mechanism for embedding-only identity has been designed or prototyped.

Net: embeddings are the stronger *recognition* technology so far, but the product's spatial-anchoring pipeline (Milestone 4 onward) currently depends on Approach A's pose data specifically. Swapping recognition technology alone (already possible via the `ObjectRecognitionService` abstraction, Milestone 3) does not by itself solve spatial anchoring for embedding-recognized objects.

**Milestone 10 update (2026-08-13):** Stress-tested 3 new Approach A objects (Marker, Holder, Dog) plus Sticker, across lighting, background, and distance. Results reinforce the M2 finding rather than complicating it:

- Marker and Holder both failed scanning outright ("not enough unique landmarks detected"), and Holder failed detection in *every* condition tested (dark/light surface, isolated, daylight, shadow) — ruling out lighting as the cause. Same failure class as `Scan_controller`.
- Sticker (small, but printed graphic detail) was the most reliable object tested — failing only when its background matched its own color. Object size does not predict success; surface detail does.
- Dog (plain, bright/glossy surface) only detected against a high-contrast background, and failed close-up even when otherwise tracking well from every angle.
- Bright/glossy surfaces compound in direct sunlight (glare on top of already-few landmarks).

This is a larger, more systematic sample than Milestone 9's (covers lighting, background, distance, viewpoint — not yet occlusion), and it confirms rather than overturns the original call: Approach A's reliability is gated by object surface detail, material, background contrast, and distance range, not something a bigger sample was likely to fix. See EXPERIMENTS.md, Milestone 10 entries, for full data and the cross-round synthesis.

### Revisit When

- A spatial anchoring strategy for embedding-only recognition is designed (e.g. screen-space bounding box + raycast against detected planes/mesh, or hybrid: embeddings for identity + a lightweight pose estimate). **This is now the primary open blocker**, not recognition reliability.
- Occlusion testing (not yet covered) reveals something that changes the picture for either approach.
- If a hybrid is pursued: embeddings for low-friction registration and identity, ARKit scanning (or another pose-capable method) layered on only for objects where spatial tracking is needed.

---

## Decision 007 — Product Mode Placement: Screen-Center Raycast, World-Fixed

**Status:** Accepted

### Decision

Product mode (Approach C only, per Decision 006) places memory content via a raycast from screen center against the detected surface at the moment of recognition, dropping a world-fixed `AnchorEntity` there. This is a real 3D placement, but it does not track the object if it's physically moved afterward — the content stays at the point it was placed, not glued to the object.

### Reason

Embeddings give identity with no pose. Two options were considered: (a) raycast placement — a true RealityKit anchor, closer to the project's "spatially anchored content" premise, but dependent on ARKit's plane/surface detection succeeding and non-tracking if the object moves; (b) a 2D screen-space overlay — simpler and always available, but not a real AR anchor, a step back from the stated architecture. The user chose (a) for a real product build. This is consistent with an existing finding: Approach A's `ARObjectAnchor` also stops re-detecting a moved object until app relaunch (see EXPERIMENTS.md), so "content doesn't follow a moved object" is not a new limitation introduced by this choice — both approaches share it in different forms.

### Revisit When

- Users report the placement drifting from the object often enough to hurt the core "this object remembers" feeling — e.g. if raycast misses are common (surface not yet detected) or objects get moved between sessions regularly.
- A pose-capable hybrid is built (see Decision 006's revisit criteria) — at that point Product mode could switch from raycast-once to true per-object tracking without changing the recognition or memory layers, since `ProductARCameraView`'s placement step is isolated behind `onObjectRecognized`.
