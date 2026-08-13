# Objects With Memories — Experiments

This document records technical experiments and findings.

Each experiment should include:

- Date
- Question
- Setup
- Conditions
- Result
- Interpretation
- Decision / next step

---

## Experiment Template

### Experiment: [Name]

**Date:**

**Question:**

**Setup:**

**Object(s):**

**Recognition method:**

**Test conditions:**

- Lighting:
- Viewpoint:
- Distance:
- Occlusion:
- Background:

**Results:**

| Condition | Detected? | Time to Detection | Tracking Stability | Notes |
|---|---|---|---|---|
| | | | | |

**Interpretation:**

**Decision / Next Step:**

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach C, partial)

**Date:** 2026-08-13

**Question:** Is embedding-based recognition (Approach C) reliable across viewpoint/lighting/distance conditions, per Decision 006's revisit criteria?

**Setup:** Manual testing via `EmbeddingExperimentView` (flask icon). Object roster changed since Milestone 9: red spoon swapped out for a laptop holder ("Holder"). Registered objects this round: Dog, Marker, Holder.

**Object(s):** Dog, Marker, Holder

**Recognition method:** Approach C — Vision `GenerateImageFeaturePrintRequest` embeddings, single-photo registration, nearest-neighbor match by embedding distance (lower = better).

**Test conditions:**

- Lighting: Daylight (indoor) only so far
- Viewpoint: Front, Side, Back tested (Dog); Front, Side tested (Holder); Front only (Marker)
- Distance: Front/normal, one Close trial (Dog)
- Occlusion: Not yet tested
- Background: Not yet tested

**Results:**

| Condition | Detected? | Time to Detection | Confidence (distance, lower=better) | Tracking Stability | Notes |
|---|---|---|---|---|---|
| Dog — Indoor/Front/Daylight | Yes | 0.1s | 0.387 | N/A (embeddings, no pose) | |
| Dog — Indoor/Close | Yes | 5.0s | 0.394 | N/A (embeddings, no pose) | |
| Marker — Indoor/Front/Daylight | Yes | 1.5s | 0.461 | N/A (embeddings, no pose) | |
| Holder — Indoor/Front/Daylight | Yes | 1.5s | 0.287 | N/A (embeddings, no pose) | |
| Dog — Indoor/Back/Daylight | No | 5.3s | 0.475 | N/A (embeddings, no pose) | Best match: Holder (misidentified) |
| Dog — Indoor/Side | No | 0.1s | 0.461 | N/A (embeddings, no pose) | Best match: Holder (misidentified) |
| Holder — Indoor/Side | Yes | 9.9s | 0.572 | N/A (embeddings, no pose) | |

**Interpretation:**

Front-view recognition is fast and accurate for all 3 objects (0.287–0.461 own-distance, correct match). Off-axis viewpoints (Dog back and side) both misidentified as Holder — the wrong object scored closer than Dog's own reference at those angles. This falls inside the ~0.6 threshold proposed in Milestone 9's initial (front-view-only, casual) testing, so a fixed distance threshold is not sufficient by itself to guarantee correctness — it only screens out clear non-matches, it doesn't guarantee the nearest neighbor is right when two objects' embeddings converge at an unfamiliar viewpoint. Holder's own side-view detection also took 9.9s, much slower than its 1.5s front-view case — latency is condition-sensitive too, not just accuracy.

Sample is still small (3 objects, indoor/daylight only, no occlusion/background/distance-matrix coverage yet) — not conclusive, but it's the first real data point against Decision 006's "larger, more systematic dataset across lighting/viewpoint/distance/occlusion/background" revisit criterion, and it surfaces a genuine viewpoint-robustness gap that the Milestone 9 sample (front-view only) didn't expose.

**Decision / Next Step:**

Continue Milestone 10 matrix (indoor low-light, outdoor daylight, distance sweep, occlusion, cluttered background) before revising Decision 006. Treat viewpoint-driven misidentification as an open risk for Approach C specifically — worth registering objects from multiple angles (multi-photo registration) rather than one, if this pattern holds up under a fuller test set.

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach A, scan roster update)

**Date:** 2026-08-13

**Question:** Which objects can be scanned and registered for Approach A (ARKit `ARReferenceObject`) well enough to stress-test?

**Setup:** Scanned new candidate objects via the ARKit scanning sample app, added as `.arobject` files to `Resources/ReferenceObjects/`.

**Object(s):** Marker (attempted, rejected), Dog (`Scan_dog.arobject`), Holder (`Scan_holder.arobject`), Pokemon sticker (`Scan_sticker.arobject`, added to replace Marker)

**Recognition method:** Approach A — ARKit reference-object scanning (`ARReferenceObject` / `ARObjectAnchor`)

**Results:**

Marker: scan repeatedly rejected — "too little unique landmarks detected." One scan attempt did complete, but the resulting reference object never triggered detection at runtime. Replaced with a flat Pokemon sticker (small, but high-contrast printed graphic) — scanned and detected successfully on first attempt.

**Interpretation:**

Same failure mode as Milestone 2's `Scan_controller` (AC remote): small/low-texture objects don't give ARKit's feature-point tracker enough to lock onto, so the scan itself gets rejected before detection is even in play. The flat sticker's success (despite also being small) suggests printed high-contrast graphic detail matters more than object size — texture/contrast, not scale, is the deciding factor for Approach A. Consistent with Milestone 2's conclusion, now confirmed on a second unrelated object.

**Decision / Next Step:**

Approach A roster for Milestone 10 stress testing: battery pack, stitch plush (from M2), Dog, Holder, sticker (new). Marker dropped from Approach A entirely — keep it as an Approach C-only object (Milestone 9 data already showed embeddings recognized it fine, distance 0.461). Reinforces Decision 006: low-texture/small objects are where Approach A structurally loses to Approach C, not a one-off fluke.

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach A, Indoor/Daylight)

**Date:** 2026-08-13

**Question:** How does Approach A (ARKit reference objects) perform indoors under daylight, for Dog, Holder, and Sticker?

**Setup:** In-app overlay export (`testDetection_StickerDogHolder.txt`, via the new share button) after a handheld session pointing at all 3 objects.

**Object(s):** Holder, Dog (~4cm), Sticker (~4cm)

**Recognition method:** Approach A — ARKit reference-object scanning (`ARReferenceObject` / `ARObjectAnchor`)

**Test conditions:**

- Lighting: Indoor, daylight
- Viewpoint: Sticker tested front and back (blank) face
- Distance, occlusion, background: not yet isolated this round

**Results:**

| Condition | Detected? | Time to Detection | Tracking Stability | Notes |
|---|---|---|---|---|
| Holder — Indoor/Daylight | No | — | — | Never fired a single recognition event all session — absent from export entirely |
| Dog — Indoor/Daylight | Yes | 2.6s | 10 losses | Recognized but flickered in/out of tracking 10 times |
| Sticker — Indoor/Daylight, front | Yes | 2.9s | 5 losses (combined) | |
| Sticker — Indoor/Daylight, back (blank face) | Yes | (same session) | (same session) | Recognized even with the blank, undecorated face toward camera |

**Interpretation:**

Recognition was unreliable across all 3 objects this round (user's own assessment: "recognition overall worked badly in daylight"). Holder's total failure to fire even once — despite a scan that reportedly succeeded — points at something environment- or distance-related rather than a bad scan per se; worth isolating (try Holder indoors without daylight glare, and at the same distance/angle used during scanning) before concluding it's unusable like Marker was.

Dog and Sticker did get recognized, but both flickered heavily (5–10 losses in one session) — even "successful" detections aren't stable enough yet to anchor content without visible jitter.

Sticker being recognized from its blank back face is the most notable finding: `ARObjectAnchor` matches against the full scanned 3D geometry, not the printed graphic. A flat object's blank side has near-identical geometry to its decorated side, so ARKit can't tell them apart — it isn't doing appearance matching at all. This is a real risk for the product's registration flow: any two objects sharing outline/silhouette (decorated or not) could cross-match under Approach A, independent of what a human would use to visually distinguish them.

**Decision / Next Step:**

Before drawing daylight-specific conclusions, re-test Holder in indoor non-daylight (isolate lighting from a possible scan/distance issue). Flag the face-agnostic Sticker match as a standing limitation of Approach A for Decision 006 — geometry-only matching is a structural gap that Approach C (which matches on appearance) does not share.

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach A, lighting/background/distance follow-up)

**Date:** 2026-08-13

**Question:** Isolate whether Holder's total detection failure is lighting-related, and check Sticker/Dog against background and distance variation.

**Setup:** Manual handheld testing indoors, same 3 objects (Holder, Dog ~4cm, Sticker ~4cm).

**Test conditions:**

- Lighting: dark surface, light surface, isolated, daylight, shadow (Holder — full sweep)
- Background: plain vs. high-contrast (Dog); background color matched to object color (Sticker)
- Distance: close-up (Dog)
- Viewpoint: all sides (Dog, when detected)

**Results:**

| Condition | Detected? | Notes |
|---|---|---|
| Holder — dark surface | No | |
| Holder — light surface | No | |
| Holder — isolated | No | |
| Holder — daylight | No | |
| Holder — shadow | No | |
| Sticker — background ≠ sticker color | Yes | |
| Sticker — background = sticker color (white-on-white) | No | Only failure case found for Sticker |
| Dog — high-contrast background | Yes | Tracked well from all sides |
| Dog — low-contrast/plain background | No (implied) | Only detected reliably against high-contrast background |
| Dog — close-up distance | No | Fails specifically at close range, despite otherwise tracking well |

**Interpretation:**

Holder fails in every condition tested — lighting is ruled out as the cause. This is not an environmental problem, it's the same failure class as Marker: the scan itself doesn't produce a reference object ARKit can actually match at runtime, regardless of scene. Should be treated as a bad/unusable scan, not a stress-test edge case — matches Marker's exact symptom (scan reports success, detection never fires).

Sticker's one failure (background same color as the object) is a classic figure-ground segmentation problem: ARKit's feature tracker needs contrast against the surrounding scene, not just internal texture on the object itself. This is a background-dependent constraint the product will need to account for (e.g. guidance to avoid same-color surfaces), not something fixable by rescanning.

Dog needing a high-contrast background to detect at all, but tracking well from every side once detected, suggests the scan geometry/features themselves are solid — the gating factor is initial lock-on against a low-contrast background, not the object's own geometry. Failing specifically at close-up is notable: likely the reference object's scanned feature points don't fill/match well when the object occupies too much of the frame (features go out of expected relative scale/position, or move outside the camera's minimum focus distance) — worth checking against the distance range used during the original scan.

Combined picture across both rounds: none of the 3 objects are reliable under all conditions. Holder is unusable outright. Dog and Sticker each have a specific, identifiable failure mode (background contrast, close distance) rather than being randomly flaky — which is actually a better outcome than pure noise, since each is addressable (rescan Holder from scratch or drop it; document background/distance constraints for Dog and Sticker).

**Decision / Next Step:**

Drop Holder from the Approach A roster — treat as a failed scan, same disposition as Marker. Re-attempt only if a fresh scan is done with more care around lighting/landmark density during the scan itself. Document background-contrast and minimum-distance constraints as known Approach A limitations going into Milestone 11 (product validation) — these are exactly the kind of failure an ordinary user would hit and not know how to fix, which is central to Milestone 10's stated purpose ("is recognition reliable enough for ordinary users"). Current answer: not yet, without user-facing guidance on background/distance, and not for objects that give ARKit as little to work with as Holder apparently does.

**Update (2026-08-13, rescan attempt):** Re-scanned Holder with more care — same outcome as Marker: "not enough unique landmarks detected," and the scan could only be built from a single front viewpoint (couldn't complete a walk-around scan). Confirms this is a scan-time landmark-density failure, not a runtime/environmental one. Holder is dropped from the Approach A roster for good, not just deprioritized.

---

### Finding: What Predicts Approach A Success, Across All Rounds (M2, M9, M10)

**Date:** 2026-08-13

Pooling every Approach A object tested so far — battery pack and stitch plush (M2, succeeded), AC remote `Scan_controller` (M2, failed), Marker (M10, failed), Holder (M10, failed), Dog and Sticker (M10, partial success):

- **Size does not predict success.** Dog and Sticker are both ~4cm and behave completely differently (Sticker far more reliable). Small is not inherently bad.
- **Surface detail is the strongest predictor.** Every failed object (AC remote, Marker, Holder) is described as low-texture/plain-surfaced. The one object with printed graphic detail (Sticker) scanned and detected far more reliably than the plain-surfaced Dog, and dramatically better than the blank Holder/Marker. ARKit's tracker needs visual landmarks on the object itself, not just its silhouette.
- **Surface material compounds the problem in sunlight.** Bright/glossy surfaces (Holder, Dog) wash out or glare under direct sun, on top of already having few landmarks — daylight makes a marginal object worse, it doesn't rescue a good one.
- **Background contrast matters independently of the object.** Even Sticker — the most reliable object tested — failed once the background matched its own color (white-on-white). Detection depends on contrast against the scene, not just the object's own surface.
- **Distance has a floor.** Dog tracked well from every angle at normal distance but failed close-up, suggesting scanned feature points stop resolving once the object fills too much of the frame (or falls under camera minimum focus distance).

Net: Approach A's practical reliability is gated by *object surface detail + material + background contrast + distance range*, not by object choice alone. A product built on Approach A would need either (a) upfront scan-quality gating that rejects objects like Holder/Marker before they're ever registered, plus user-facing guidance on background and distance, or (b) to lean further into Approach C for identity (per Decision 006) and solve pose separately, since Approach C has not shown any of these failure modes in testing so far (Milestone 9's embedding tests succeeded on `Scan_controller`, the exact object Approach A already failed on).

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach A, occlusion)

**Date:** 2026-08-13

**Question:** How do Dog, Sticker, and Holder hold up under partial occlusion?

**Object(s):** Dog, Sticker, Holder — battery pack and stitch plush scans removed from the project (no longer used for testing); controller not included this round.

**Recognition method:** Approach A — ARKit reference-object scanning

**Test conditions:**

- Occlusion: partially covered / partially hidden

**Results:**

| Condition | Detected? | Notes |
|---|---|---|
| Sticker — partial occlusion | Yes | Detects fine, consistent with every prior round |
| Dog — partial occlusion | Yes | Detects fine, consistent with every prior round |
| Holder — partial occlusion | No | Still undetectable — consistent with every condition tested so far |

**Interpretation:**

No new failure mode from occlusion specifically. Sticker and Dog's existing reliability (background/distance permitting) carries over unaffected by partial covering. Holder remains a dead scan regardless of any variable tested — occlusion is the last item in ROADMAP.md's matrix, and it doesn't change Holder's status.

This closes the full Milestone 10 condition matrix (lighting, viewpoint, distance, occlusion, background) for the current Approach A roster (Dog, Sticker, Holder).

**Decision / Next Step:**

Milestone 10 substantively complete for Approach A: reliability is not uniform across objects, but the failure modes are now well-characterized (surface detail/material, background contrast, distance floor) rather than unexplained flakiness, and Holder is confirmed unusable across every dimension tested. Per Decision 006, the open blocker going forward is spatial anchoring for Approach C (embeddings), not further Approach A stress testing.

---

### Finding: Two Distinct Stickers Are Correctly Told Apart By Image (Approach A)

**Date:** 2026-08-13

**Setup:** Registered a second sticker scan (`Scan_sticker0803.arobject`, different printed image, same rough flat shape as the original `Scan_sticker`). Pointed camera at each in the main app.

**Result:** Both stickers were correctly and distinctly recognized by their printed image — no cross-matching between the two.

**Interpretation:** This nuances the earlier finding (M10 lighting/background/distance round) that Sticker was detected even from its blank back face, which was read as "ARKit matches on 3D geometry, not the printed graphic." That conclusion was too strong. What's actually happening: a single object's scan captures feature points from *its own* front face; a blank back face is close enough in shape to still pass that object's own detection threshold (self-tolerant). But *across two different objects*, each scan's feature points are distinct enough (driven by their different printed graphics) that ARKit correctly discriminates between them. So printed detail does matter for telling objects apart — it just doesn't fully protect a single object from being detected in a pose/face it wasn't standing in reference photos for.

**Decision / Next Step:** Update the standing conclusion: Approach A's weak spot is specifically "same object, unexpected face/pose," not "ignores appearance entirely." Cross-object discrimination by printed detail is a real strength, consistent with the roadmap principle that recognition should work for arbitrary user objects, not just texture-matched pairs.

---

### Finding: Approach A Stops Re-detecting a Moved Object Until App Relaunch

**Date:** 2026-08-13

**Setup:** Sticker detected and tracked normally in place. Physically moved to a new location mid-session.

**Result:** Object was no longer recognized after being moved — required closing and reopening the app to detect it again at its new location.

**Interpretation:** This looks like `ARWorldTrackingConfiguration`/`ARObjectAnchor` only attempting to (re)detect each reference object once per world-tracking session by default, or the existing (now stale) anchor blocking a fresh detection attempt at the new position — `ARSession` doesn't appear to retry detection for an object it already anchored once, even after that anchor's tracked position clearly no longer matches reality. This is a significant usability gap distinct from the recognition-accuracy findings above: even a perfectly-scanned, perfectly-lit object breaks the moment its physical object is moved, which is a completely ordinary thing for a user to do with a personal object.

**Decision / Next Step:** Needs investigation before this can be considered solved by "just" fixing recognition and background/lighting — e.g. explicitly removing and re-adding anchors on request, running `session.run(configuration, options: [.resetTracking])` on demand, or moving toward Approach C (which re-evaluates every frame against the live camera image rather than anchoring once) sidesteps this specific problem entirely. Worth weighing alongside Decision 006's existing case for Approach C.

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach C, multi-image registration)

**Date:** 2026-08-13

**Question:** Does multi-image registration (2-5 photos per object instead of 1) improve Approach C reliability, and can it recognize the objects Approach A completely failed on (Holder)?

**Setup:** `EmbeddingExperimentView`, extended to register up to 5 photos per object (nearest-of-any-registered-photo matching). Objects: Dog, Sticker, Sticker0803 (second sticker with a different printed image), Holder.

**Object(s):** Dog, Sticker, Sticker0803, Holder

**Recognition method:** Approach C — Vision embeddings, multi-photo registration

**Results (interim, mid-session):**

| Condition | Detected? | Time to Detection | Confidence (distance, lower=better) | Notes |
|---|---|---|---|---|
| Dog — Indoor (other objects in frame) | No | 1.6s | 0.514 | Best match: Sticker (misidentified) |
| Dog — Indoor/solo | Yes | 0.0s | 0.381 | |
| Dog — Indoor/bottom viewpoint | Yes | 0.0s | 0.389 | |
| Sticker — Indoor/solo | Yes | 1.0s | 0.269 | |
| Sticker — Indoor/side | Yes | 2.0s | 0.366 | |
| Sticker0803 — Indoor/solo (1st attempt) | No | 4.5s | 0.590 | Best match: Holder (misidentified, distance right at the 0.6 threshold) |
| Sticker0803 — Indoor/solo (retry) | Yes | 0.7s | 0.512 | Flaky — failed then passed under nominally the same condition |
| Sticker0803 — Indoor/side | Yes | 5.0s | 0.532 | Slow and close to threshold compared to Sticker's equivalent (0.366, 2.0s) |
| Holder — Indoor/solo | Yes | 0.0s | 0.386 | |
| Holder — Indoor/back | Yes | 0.1s | 0.496 | |

**Interpretation:**

Headline result: **Holder is recognized reliably by Approach C**, including from the back — the exact object that failed in *every single condition* tested under Approach A (dark/light surface, isolated, daylight, shadow, occlusion). This is the strongest data point yet for Decision 006: embeddings succeed precisely where geometric feature-matching structurally can't.

Two secondary findings:

- The one Dog failure happened with other objects in frame (not "solo") — worth treating "solo vs. multiple objects in view" as its own test variable going forward, since it may explain confusion independent of lighting/background.
- Sticker0803 is measurably less reliable than the original Sticker despite both being printed/detailed flat objects — flakier (failed once, passed on retry under the same nominal condition), slower to detect, and its distances sit closer to the 0.6 threshold (0.51-0.59 vs Sticker's 0.27-0.37). Likely needs more/better-angled registration photos; the two stickers may also be similar enough in shape/color to push each other's distances up.

**Decision / Next Step:**

Multi-image registration is working as intended and materially strengthens the case for Approach C over Approach A, especially for objects like Holder that Approach A cannot handle under any condition. Sticker0803's borderline distances are worth another registration pass (more angles) before treating it as a stable reference. Continue treating "spatial anchoring for Approach C" (Decision 006) as the real remaining blocker — recognition reliability is no longer the limiting factor for at least these 4 objects.

---

### Experiment: Milestone 10 — Recognition Stress Testing (Approach C, viewpoint/clutter/occlusion round)

**Date:** 2026-08-13

**Setup:** Same 4 objects (Dog, Sticker, Sticker0803, Holder), tested via `EmbeddingExperimentView`'s stress-test flow — now with the added per-entry frame capture, confirmed working (screenshots: `test/test_multi_1_1.PNG`, `_2.PNG`, `_3.PNG`).

**Corrections applied per operator notes:**
- The "Sticker0803 — Indoor/Front/Closeup — No, 1.9s, 0.469, best match: Sticker" row was a data-entry mistake — the expected-object field should have been "Sticker," not "Sticker0803." Recorded below as a correct Sticker self-match, not a failure.
- One "Sticker0803 — Indoor/HalfOccluded" trial (0.1s, best match Holder) was captured while the camera wasn't actually pointed at the object. Discarded as invalid, not a real failure.
- The "Far" condition was not an isolated distance test — screenshots show all objects clustered together on the desk in the same frame. Relabeled below as "cluttered/multi-object" rather than pure distance.

**Results (corrected):**

| Condition | Detected? | Time to Detection | Confidence (distance) | Notes |
|---|---|---|---|---|
| Dog — Front/Closeup | Yes | 1.4s | 0.334 | |
| Dog — Front/Solo | Yes | 0.1s | 0.428 | |
| Dog — Front/cluttered (×2) | No | 0.0s / 0.1s | 0.503 / 0.594 | Best match both times: Holder |
| Dog — Occluded | Yes | 1.9s | 0.481 | |
| Dog — HalfOccluded | Yes | 1.2s | 0.591 | |
| Dog — LowerOccluded | Yes | 5.8s | 0.569 | Slow, but succeeded |
| Sticker — Front/Closeup (×2) | Yes | 1.2s / 1.9s | 0.576 / 0.469 | Second is the corrected relabel |
| Sticker — Front/cluttered | No | 0.1s | 0.549 | Best match: Holder |
| Sticker — Back | No | 2.5s | 0.535 | Best match: Holder |
| Sticker — HalfOccluded | Yes | 2.7s | 0.379 | |
| Sticker0803 — Front/Closeup | Yes | 5.1s | 0.375 | |
| Sticker0803 — Front/cluttered | No | 0.1s | 0.593 | Best match: Holder |
| Sticker0803 — Back | No | 0.4s | 0.591 | Best match: Holder |
| Sticker0803 — HalfOccluded2 | Yes | 0.1s | 0.516 | |
| Holder — Front/Closeup | Yes | 0.1s | 0.577 | |
| Holder — Front/cluttered | Yes | 0.1s | 0.447 | Only object unaffected by clutter |
| Holder — HalfOccluded | Yes | 1.9s | 0.561 | |

**Interpretation:**

Two new patterns, both fairly clear:

1. **Occlusion is a non-issue for Approach C.** Every occlusion/half-occlusion trial across all 4 objects succeeded (one was slow at 5.8s, none failed). This is a real point of contrast with Approach A, and consistent with embeddings working off overall image content rather than needing an intact silhouette.

2. **Holder is a systematic false-attractor.** Every single failure in this round — Dog, Sticker, and Sticker0803, in both "cluttered" and "Back" conditions — picked Holder as the best (wrong) match. Holder itself was the *only* object that stayed correctly detected in the cluttered frame. Combined with Holder's registration photos likely being visually plain (a blank light-colored object), this suggests its embedding sits in a generic/central region of embedding space that ambiguous or off-target frames tend to drift toward — it isn't that Holder resembles these objects specifically, it's that Holder-like "nothing distinctive" frames default to it. Worth registering Holder with more/varied-angle photos to sharpen its own boundary, since right now it may be acting as a magnet for uncertain frames rather than a well-defined reference.

3. **Back view fails cleanly on Approach C**, unlike Approach A. Recall the earlier finding that ARKit (`ARObjectAnchor`) recognized Sticker from its blank back face because it matches on scanned 3D geometry. Embeddings do the opposite — Sticker and Sticker0803 both failed from the back, because the back genuinely doesn't resemble any registered front-facing photo. This is more correct behavior for a product context (a blank back face shouldn't count as "recognizing" the front-printed object) but means multi-angle registration should include the object's actual usable viewing angles, not assume front-only coverage transfers.

**Decision / Next Step:**

Re-register Holder with a couple more/varied photos to reduce its false-attractor effect — this is likely fixable without new tooling, just better reference coverage. Occlusion can be considered a solved dimension for Approach C. Back-view failures are expected/correct behavior, not a bug — document as "register every angle a user might realistically view the object from," not a limitation to fix in code.

---

## Recognition Testing Guidelines

Test objects under:

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

---

## Important Findings

Add confirmed technical findings here as short entries.

Example:

> [Date] — ARKit reference-object detection was reliable for Object A under indoor lighting from front and side viewpoints, but detection degraded under low light.

> 2026-07-27 — Milestone 9 (Object Registration Research), Approach C — Learned Visual Embeddings: prototyped using Vision's `GenerateImageFeaturePrintRequest` (built into iOS 18, no custom CoreML model needed). Registration is a single photo per object (vs. ARKit's multi-angle walk-around scan for Approach A). Tested 3 new objects (marker, red spoon, dog figure) — each registered from one photo, then tested by pointing the camera at each in turn and comparing embedding distance against all three registered references:
>
> | Pointed at | vs marker ref | vs spoon ref | vs dog ref |
> |---|---|---|---|
> | marker | ~0.3–0.5 (own) | ~0.9–1.2 | ~0.8–1.1 |
> | red spoon | ~0.9–1.2 | ~0.3–0.5 (own) | ~0.8–1.1 |
> | dog figure | ~0.8–1.2 | ~0.95–1.2 | ~0.3–0.5 (own) |
>
> Clear separation: same-object distance consistently ~0.3–0.5, different-object consistently ~0.8–1.2. Correct match was always the closest for all 3 objects across the tests run. A threshold around ~0.6 would cleanly discriminate. Caveats: small sample (3 objects, casual angle/lighting variation, not the full Milestone 10 stress-test matrix), and this approach was not tested against the specific object Approach A failed on (`Scan_controller`, the low-texture AC remote) — worth a direct follow-up. Also: this approach gives object identity only, not 6DOF pose — would need a separate mechanism (e.g. screen-space bounding box + raycast) to drive spatial anchoring if adopted, unlike Approach A's `ARObjectAnchor` which provides both simultaneously. See DECISIONS.md for the comparative writeup.

> 2026-07-28 — Follow-up: registered `Scan_controller` (the Samsung AC remote — glossy, low-texture, scanned against a plain white table) via Approach C's single-photo flow and tested it under varying conditions. Scored ~0.4–0.6 on average, consistently recognized correctly. This is the exact object Approach A (ARKit `ARObjectAnchor` scanning) failed to detect at all in Milestone 2 due to insufficient feature points for its keypoint-based tracker. Approach C succeeds here because it works on whole-image semantic embeddings rather than local geometric feature matching — the low-texture/reflective surface that starves ARKit's tracker doesn't equally starve the embedding model. This directly resolves the gap flagged in Decision 006. Milestone 9 substantively complete: Approach C (Learned Visual Embeddings) recognized all 4 tested objects, including the one Approach A could not, with a simpler (single-photo) registration flow. Remaining open question is spatial anchoring (Approach C has no pose), not recognition reliability. Moving to Milestone 10 (Recognition Stress Testing).

> 2026-07-25 — Milestone 0 scaffold: project generated with xcodegen (project.yml), builds successfully for iOS Simulator (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build` → BUILD SUCCEEDED). ARKit/ARWorldTrackingConfiguration requires a physical device to actually run (no camera/world tracking in Simulator), so Milestone 0's success criteria (camera view + minimal AR scene) is still unconfirmed until tested on an iPhone.

> 2026-07-25 — Milestone 0 confirmed on physical iPhone: app builds, camera permission prompt shows, camera view displays, world tracking stays stable while moving device (no crash, no freeze). Milestone 0 complete. Moving to Milestone 1 (Basic AR Camera — session state, debug info).

> 2026-07-25 — Milestone 1 confirmed on physical iPhone: debug overlay shows Tracking: Normal, Anchors: 1, FPS: 60. The 1 anchor is RealityKit's automatic environment-probe anchor added by `ARView` (automatic environment texturing), not app-created — expected baseline, not a bug. Session stable. Milestone 1 complete. Moving to Milestone 2 (Recognition Technology Prototype).

> 2026-07-26 — AR Resource Groups (`.arresourcegroup` inside `.xcassets`) are NOT supported by this Xcode's `actool` (16.4) — it silently compiles an empty catalog with no error/warning, so `ARReferenceObject.referenceObjects(inGroupNamed:)` finds nothing at runtime. Switched to bundling `.arobject` files as a plain folder resource (`Resources/ReferenceObjects/`, added via xcodegen `type: folder`) and loading them directly with `ARReferenceObject(archiveURL:)`. Works reliably. Decision: avoid AR Resource Groups entirely going forward; use direct archive loading.

> 2026-07-26 — `ARObjectAnchor` persists once created and keeps reporting a transform even when the object leaves the camera view — ARKit never signals "object no longer visible." Added a per-frame frustum check (in-front-of-camera + `projectPoint` bounds test) in `ARSessionManager` so the published `recognizedObjects` list reflects current visibility, while the underlying ARKit anchors are left alone (needed for tracking continuity later).

> 2026-07-26 — Milestone 2 confirmed on physical iPhone with 3 scanned objects (battery pack, AC remote, stitch plush). 2 of 3 (battery pack, plush) detected reliably across multiple angles and lighting conditions, correctly distinguished from each other with stable identity. The AC remote (`Scan_controller`) failed to detect: preview image shows a low-texture, glossy, mostly-uniform light-gray object scanned against a plain white table — almost no distinguishable feature points for ARKit's tracker, worsened by LCD/plastic glare. Compared side-by-side with the successful battery-pack scan (high-contrast printed label, strong features) to confirm this is a scan-quality/object-choice issue, not a bug in the app's recognition code. Decision: accept as a known limitation of ARKit's feature-based object detection — low-texture reflective objects are poor candidates. Revisit if Milestone 9 (Object Registration Research) explores alternative approaches (e.g. learned embeddings) that handle this better. Milestone 2 complete. Moving to Milestone 3 (Recognition Abstraction).

> 2026-07-26 — Milestone 3 confirmed on physical iPhone: refactored object-detection logic out of `ARSessionManager` into `ARKitObjectRecognitionService` behind the `ObjectRecognitionService` protocol (`start()`/`stop()`/`recognitionEvents: AsyncStream<RecognitionEvent>`). `ARSessionManager` now only owns the AR session and tracking-state debug info, forwarding anchor/frame callbacks to the recognition service and consuming its event stream. Behavior unchanged from Milestone 2 (same 2/3 objects, visibility-aware list) — confirms the abstraction didn't regress anything. Milestone 3 complete. Moving to Milestone 4 (Spatial Anchoring).

> 2026-07-26 — `AnchorEntity(anchor: ARAnchor)` and the related `AnchoringComponent(_ anchor: ARAnchor)` bridging initializers are entirely absent from RealityKit's iOS Simulator SDK interface (not just marked unavailable — genuinely not declared there), while present in the device SDK. Any AR content code that anchors to a live `ARAnchor`/`ARObjectAnchor` will fail to compile for `-destination 'generic/platform=iOS Simulator'` with a confusing "no exact matches in call to initializer" error. Decision: from Milestone 4 onward, verify AR-content-touching builds against `-destination 'generic/platform=iOS'` (device, `CODE_SIGNING_ALLOWED=NO` for a signing-free compile check), not Simulator. Simulator remains fine for AR-independent code (Milestones 0–3 UI/session-state work).

> 2026-07-26 — Milestone 4 confirmed on physical iPhone: cube, sphere, and "Memory" text appear anchored to recognized objects (battery pack, stitch plush), stay locked to the correct object while moving the camera around. Content parented to `AnchorEntity(anchor: objectAnchor)` with object-relative offsets — no global world coordinates used. Milestone 4 complete. Moving to Milestone 5 (First Memory Experience — replace test geometry with a real hardcoded memory).

> 2026-07-26 — Milestone 5 confirmed on physical iPhone: generated placeholder memory (gradient card + title) appeared correctly anchored per object. Extended `HardcodedMemoryRepository` to look up a real bundled image by object name (`Resources/MemoryImages/<name>.jpg|png|jpeg|heic`, plain folder reference like `ReferenceObjects`) before falling back to the placeholder — `MemoryRepository.memories(for:)` takes the full `RecognizedObject` (not just its UUID) so the repository can key lookups off the name without widening the protocol into per-object special-casing. User dropped real photos in and confirmed each attaches to the correct corresponding object. Milestone 5 complete. Moving to Milestone 6 (Multiple Memory Types).

> 2026-07-26 — Milestone 6 confirmed on physical iPhone: added `MemoryPresenter` protocol (`present(_:relativeTo:)`) with one implementation per type — image (unchanged from M5), video (`VideoMaterial`/`AVPlayer`, looped, falls back to a "No video memory" text card if no file bundled), audio (spatial playback via `AudioFileResource`/`playAudio` off a small icon sphere), text (3D extruded `MeshResource.generateText`). `MemoryEntityFactory` is now a thin dispatcher. `HardcodedMemoryRepository` picks type by checking `MemoryVideos/` → `MemoryAudio/` → `MemoryImages/` → text fallback, so dropping a file of any of those types automatically exercises the right presenter. User confirmed video/audio work end-to-end.

> 2026-07-26 — Added `BillboardComponent` to the image and video plane entities so memory cards always face the camera (requested by user for readability while moving around an object). `BillboardComponent` requires iOS 18+, so bumped `IPHONEOS_DEPLOYMENT_TARGET` from 17.0 to 18.0 project-wide — acceptable since this is a personal prototype tested on the user's own device; would need revisiting (e.g. manual per-frame look-at rotation via a scene update subscriber) if broader device/OS support becomes a requirement later. Milestone 6 complete. Moving to Milestone 7 (Multiple Objects).

> 2026-07-26 — Milestone 7 confirmed on physical iPhone: `HardcodedMemoryRepository.memories(for:)` now returns every matching media file found for an object (image + video + audio combined) instead of picking one by priority, using each `Memory.spatialOffset` to stack multiple memories vertically (8cm apart) so they don't overlap. All four presenters apply that offset on top of their own default position. Distinct-object identification, correct per-object retrieval, and no cross-object mixing were already proven in Milestones 2/5/6; user confirmed both objects work correctly when in frame together and multiple memories per object stack correctly. Milestone 7 complete. Moving to Milestone 8 (Add a Memory — in-app capture flow + real local persistence, replacing the hardcoded/bundled-file repository).

> 2026-07-26 — Milestone 8 built: `StableObjectID` derives a deterministic UUID from the object's scanned name (SHA256-based) so object identity survives app relaunches — needed since the previous per-launch-random UUID would have made saved memories unretrievable after closing the app. `FileManagerMemoryRepository` replaced the hardcoded/bundle-based one, persisting to `Documents/Objects/<stableID>/Memories/`. `Features/MemoryCreation/AddMemorySheet` (PhotosPicker + text field) lets the user attach a photo and/or note to whichever object is currently recognized.

> 2026-07-26 — Two bugs found post-implementation, both from the same change: (1) saved photos appeared rotated 90° — `UIImage.cgImage` ignores EXIF orientation, so feeding it straight into `TextureResource.generate` bypassed the correction `UIImage` normally applies for display; (2) photo and text memories visually overlapped for portrait photos — the image plane's height scaled freely with aspect ratio and could exceed the fixed 8cm vertical stacking gap. Fixed by normalizing orientation via redraw, capping the image plane to a 0.15m×0.15m box regardless of aspect ratio, and widening the stacking gap to 0.2m.

> 2026-07-26 — Fixing the above introduced a real crash: app froze then crashed on the second object detected. Root cause was actually two compounding bugs: (a) `ARSession`'s `didAdd`/`didRemove` delegate callbacks fire on a background queue by default (same reason `didUpdate frame:` already had to dispatch its state update to main) — but unlike `didUpdate`, they were touching RealityKit/UIKit directly off-main; (b) the new orientation-normalize redraw ran at the photo's full original resolution (a Photos-library pick can be 12+ MP) — once forced onto the main thread by fixing (a), that synchronous full-res redraw + texture generation was slow enough to freeze the main thread and trigger a watchdog kill. Fixed by dispatching `didAdd`/`didRemove` to main (matching `didUpdate`'s existing pattern) AND capping the redraw to 1024px max dimension in the same pass as the orientation fix. User confirmed smooth operation after both fixes, including full close-app/reopen-app persistence test. Milestone 8 complete. Moving to Milestone 9 (Object Registration Research).

