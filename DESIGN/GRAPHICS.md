---
doc_id: GRAPHICS
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
product: graphics/renderer surface (xylem-graphics + wgpu adapter)
layer: L3 platform substrate + L4b Canvas adapter (D-001 v2)
---

# Graphics / renderer surface — design research (design-only)

**Scope discipline.** No implementation, builds, pushes or CI. No performance
numbers: every cost claim is either cited to a primary source or marked
`PENDING_VERIFICATION`. Headless GPU was verified on one adapter only; **no
cross-adapter claim** is made.

## 2. Current Xylem assets and exact gaps

| Asset (local path) | What exists | Exact gap |
|---|---|---|
| `xylem-platform/crates/xylem-graphics/src/lib.rs:1-43` | Deterministic software renderer; `Scene`, `Surface`, `Canvas`, PNG codec, text/font stack, backend seam, `forbid(unsafe_code)` | No scene-embedded asset handle; every `DrawCommand::Image` owns full `Image` pixels (`scene.rs:39-43`) |
| `xylem-platform/crates/xylem-graphics/src/backend.rs:109-115` | `GpuDevice` seam (`begin_frame`/`submit`/`finish_frame`); `GpuBackend::lower` batches geometry (`backend.rs:142-216`, `flush` at 240-244) | No device-loss, resize hook, explicit release, or frame-graph/pass interface; `resize` is a `RenderBackend` size field only (`backend.rs:226-229`) |
| `xylem-platform/crates/xylem-graphics/src/scheduler.rs:31-92` | Deterministic `FrameScheduler` with caller-supplied time and `FrameStats` | Measures only CPU render durations, not GPU submission structure; no resource counters |
| `ecosystem-worktrees/task-platform-gpu/crates/xylem-graphics-wgpu/src/lib.rs` (I091) | `WgpuDiagnostics` snapshot (497-512), bounded LRU `ImageCache` (190-354), `FrameLifecycle`, explicit `evict_images`/`clear_images` (523-531), recorded resize invalidation (533-553), `image_key` (1036-1042) | No device-loss path, no explicit `destroy()`, whole-cache invalidation on resize, content rehash per draw, one buffer + one command encoder + one submit per command (624-673), blocking `poll(Maintain::Wait)` readback (904) |
| `.../task-platform-gpu/.../GPU_LIFECYCLE.md:41-102` | Documents admission, eviction, invalidation and field-order drop | §4 explicitly relies on declaration-order drop and refcount handles, not explicit teardown |
| `xylem-platform/crates/xylem-ui/src/lib.rs:15,25-28,680-696,751-759` | Shared `UiDocument`; `UiElementKind::Canvas` embeds `Scene`; validation `UI-009/010/011` (490-511); `accessibility_tree` (62-67) | No documented ownership boundary for GPU resources behind an embedded scene |
| `xylem-platform/crates/xylem-web/src/ui.rs:217-219,274` and `xylem-desktop/src/components.rs:86-96` | Same document consumed one-way: web emits `<canvas>` + `data-xylem-scene`; desktop constructs native Button/TextInput | No shared definition of which side owns GPU texture lifetime for a Canvas |

**Integration contradiction (PENDING).** The verified I091 diagnostics/cache code is
present in `ecosystem-worktrees/task-platform-gpu/...`; the main-tree
`xylem-platform/crates/xylem-graphics-wgpu/src/lib.rs:93-105` still has a plain
`HashMap`, no `WgpuDiagnostics`, and no bounded cache. All I091 citations below
are to the worktree path. Integration into the main tree is not claimed.

## Shared UI and the graphics surface

**Layer placement (D-001 v2).** Graphics is split across two layers:
`xylem-graphics` + wgpu adapter are the **L3 platform substrate** (GPU device,
surface, timers), and the embedded `Canvas`/scene rendering is an **L4b target
adapter** (D-001 v2:33-41,125-126). The v1 "L3 serves L4" ambiguity is resolved
structurally: **L4a owns the UI rendering port**; L4b implements it and consumes
L3 + L2 (D-001 v2:52-53,74-83). Graphics is a substrate for Canvas, never a
replacement for native widgets (D-001 v2:139). L7 is a delivery plane, not a
runtime tier (D-001 v2:40-41).

**Dependency matrix (source dependencies; D-001 v2:58-70).**

| From ↓ / To → | L2 | L3 | L4a (port) | L4b | L5/L6/L7 |
|---|---|---|---|---|---|
| L3 graphics substrate (`xylem-graphics`, wgpu adapter) | yes | — | **no** | no | no |
| L4b Canvas adapter (`xylem-web`/`xylem-desktop` canvas path) | via L3 | yes | yes (implements) | —¹ | no |

¹ Adapters never depend on sibling adapters; they meet through L4a/L3 ports.

Runtime data/control flow may reverse via subscriptions established by the
upper layer (L3 device events → L4b adapter → L4a document update); lower
layers must not store references to upper-layer-owned state, and callbacks
crossing upward should use numeric ids or borrowed snapshots (D-001 v2:85-93).

**Ownership boundary.**

- **(a) L4a shared policy core:** `UiDocument` is the single validated,
  serializable tree; layout, bindings, events, accessibility and the rendering
  port belong here (`xylem-ui/src/lib.rs:1-5,42-67`; D-001 v2:52). It contains
  no OS widget, DOM type or GPU handle. Canvas validity is structural: a scene
  must exist and Canvas must have no children (`xylem-ui/src/lib.rs:490-511`).
- **(b) L4b target adapters:** desktop/mobile map Button and TextInput to native
  components (`xylem-desktop/src/components.rs:86-96`), web maps them to
  semantic HTML (`xylem-web/src/ui.rs:269-276`); `xylem-web` is L4b + L7 build
  tooling and `xylem-desktop` is L4b + L3 host (D-001 v2:122-124). These are
  not rendered by our renderer. The Canvas port is **not** mirrored in L4b or
  L3 packages (D-001 v2:22,83).
- **(c) L3 substrate + L4b Canvas:** `Scene` is embedded as L4a value data in the
  document (`xylem-ui/src/lib.rs:692-694,740-743`). An L4b adapter renders it
  through `GpuBackend`/`SoftwareBackend`; on web the browser owns the
  `<canvas>` and the scene is serialized as `data-xylem-scene`
  (`xylem-web/src/ui.rs:217-219`). Our readback `Surface` is a native-side
  result, not a web DOM contract.

**Resource lifecycle for embedded scenes.** Cache keys, budgets and frame state
are owned by the L3 device/target, never by `UiElement` (D-001 v2:95-101).
When a Canvas scene changes, the L4a document changes; the L4b adapter submits
the new scene at its next `begin_frame`/lowering and L3 applies LRU
admission/invalidation. `GpuBackend::lower(&Scene)` returns owned `Vec<GpuCommand>`
(`backend.rs:142-216`), so no L3 object retains an upward reference to the
document; the only remaining copy hazard is the owned `Image` clone at
`backend.rs:182-186`. Unmounting a Canvas must not silently drop a device: the
device is owned by `GpuBackend` (`backend.rs:118-138`) and the document holds
only value scene data. A second rendering tree inside Canvas would duplicate
layout, accessibility and focus state — forbidden by D-001 v2:138-139.

## 3. Existing products studied and the traps they fell into

| Primary source | Practice | Trap it avoids / our gap |
|---|---|---|
| wgpu architecture — https://wgpu.rs/doc/wgpu/documentation/internals/architecture/index.html | `wgpu_core` tracks lifetimes with `Arc`, generates barriers via `Tracker`; `Device` creation methods take `&self`; handles are refcounted (https://docs.rs/wgpu/latest/wgpu/) | Native backends demand explicit barriers; wgpu hides them but refcount traffic is not free. Our per-draw handle creation (`lib.rs:624-673`) ignores this |
| wgpu bind groups — https://docs.rs/wgpu/latest/src/wgpu/api/bind_group.rs.html; https://docs.rs/wgpu/latest/wgpu/enum.BindingType.html | `BindGroup` maps 1:1 to WebGPU `GPUBindGroup`; dynamic offsets exist for reused layouts | Rebuilding bind groups per object instead of reusing one per cached texture |
| Bevy `RenderSystems` — https://docs.rs/bevy/latest/bevy/render/enum.RenderSystems.html; https://bevy.org/news/bevy-0-6/ | Extract → Prepare → Queue → Render → Cleanup/PostCleanup, `PrepareBindGroups` after resource flush; extract only minimum data; separate render world | Doing computation in extract; per-object heap allocation; our lowering is a single `Vec` pass with no prepared-resource phase |
| Skia `GrResourceCache` — https://android.googlesource.com/platform/external/skia/+/cfe11bf71c50320fe5887e1b5f98c99e44d20bea/src/gpu/GrResourceCache.cpp; `GrResourceProvider` — https://skia.googlesource.com/skia/+/db9f95c8880ab13cf19d3ff152f6a2cb756533da/src/gpu/GrResourceProvider.cpp | Byte-budgeted LRU, budgeted/unbudgeted classes, scratch-key reuse, `abandon`/`release` on context loss | Silent cache drops: our I091 *records* invalidation but discards all textures on any resize |
| Vulkan Guide — https://docs.vulkan.org/guide/latest/memory_allocation.html; https://docs.vulkan.org/guide/latest/common_pitfalls.html | Sub-allocate large blocks (`maxMemoryAllocationCount`); staging buffers for discrete GPUs; re-record command buffers per frame; group descriptor sets by update frequency; batch barriers | Blind per-swapchain duplication and caching command buffers that must change every frame |
| Metal Best Practices — https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/PersistentObjects.html; .../BufferBindings.html | One device/queue, build pipelines once, allocate resources up front, avoid creating resources in the render loop; bind a buffer once and change offsets | Creating a buffer and encoder per draw (our `lib.rs:638,647`) |
| DX12 — https://learn.microsoft.com/en-us/windows/win32/direct3d12/using-resource-barriers-to-synchronize-resource-states-in-direct3d-12; .../descriptor-heaps | App-managed state, batch transitions, common-state promotion/decay, split barriers, contiguous descriptor heaps | Excessive explicit transitions; treating descriptors as per-object allocations |
| WebGPU spec — https://gpuweb.github.io/gpuweb/ (§3.1.2, §3.4.1, §4.4, §21, §22) | `destroy()` over GC reliance; device can be lost at any time; `lost` promise; content/device/queue timelines | Assuming a device never dies or that blocking queue waits exist on the web |

## 4. Design options and recommendation

1. **Keep the synchronous headless adapter, add pass-level batching.** One
   encoder per frame, one reusable staged vertex buffer with offsets, cached
   bind groups, explicit lifecycle hooks. *Lowest risk; preserves the verified
   I091 seam and one-adapter scope.*
2. **Full frame graph with render worlds and async device loss.** Bevy-style
   Extract/Prepare/Queue; highest complexity, would duplicate L4a policy state
   inside a lower layer and exceed current evidence. *Reject now.*
3. **Delegate entirely to the browser/native compositor.** No custom renderer.
   *Reject: loses the Canvas surface the product already implements.*

**Recommended: option 1**, staged through the gates in §9. It is additive to
`GpuDevice`, keeps `Scene` value-owned, and makes resource lifetime explicit
without inventing a second UI tree.

## 5. Data/model/lifetime design

- **Ownership:** `GpuBackend` owns the device; device owns target, pipelines,
  sampler and `ImageCache`. Cached entries own texture + bind group. L4a owns
  only scene values; L4b owns widget/surface handles (D-001 v2:95-101). No
  `Rc`/`Arc` per drawable; no hidden global state.
- **Layout:** `Scene` is a contiguous `Vec<DrawCommand>` (`scene.rs:52-53`);
  lowering already moves batches with `mem::take` (`backend.rs:240-244`).
  Prefer an image *key/id* in `GpuCommand::Image` over the owned `Image` clone
  at `backend.rs:182-186`; index pixels into one upload arena.
- **Hot paths:** lower once per frame; hash image content once per *changed*
  image, not per draw (`lib.rs:1036-1042`); reuse one encoder and one staged
  vertex buffer with offsets (Metal/DX12 patterns above); one bind group per
  cached texture; explicit clear → geometry → images → readback pass order.
  Refcount/COW traffic hurts at per-triangle handles, per-command `Image`
  clones, and transient wgpu buffer/encoder churn.
- **Lifecycle:** add explicit `on_device_lost`/`destroy` hooks at the seam;
  make resize invalidation selective (same-format scratch reuse) rather than
  whole-cache; treat readback as an async boundary for web parity.
- **Web parity:** logic (cache policy, frame state, lowering, diagnostics)
  transfers because it is plain Rust; wgpu→WASM drives browser WebGPU without
  `wgpu_core`/`wgpu_hal` (architecture doc). The web target is an L4b adapter
  consuming the L4a port (D-001 v2:122); browser `<canvas>` presentation, not
  our device-owned readback `Surface`, is its output. Not transferred: backend/adapter
  selection (`Backends::all()`, `force_fallback_adapter`), `get_info()` detail
  (WebGPU §2.2.6 may bin/withhold), blocking `device.poll(Maintain::Wait)`
  (`lib.rs:904`) versus WebGPU promises (§3.2, §4.4), optional features/limits
  (§3.6), native custom backends, and application-threaded command encoding.
- **Explicitly out of scope:** paths/curves/gradients/masks/shadows/font
  discovery (`lib.rs:11-12`), native widget rendering, windowing, layout,
  accessibility computation, L0/L1 value/RC model, benchmark harness,
  cross-adapter certification, wall-time performance claims.

## 6. API sketch (signatures and behavior only)

```rust
// Additive, defaulted; no breaking change to GpuDevice.
trait GpuDeviceLifecycle {
    type Error;
    fn on_resize(&mut self, size: Size) -> Result<(), Self::Error>; // default no-op
    fn on_device_lost(&mut self, reason: &str) -> Result<(), Self::Error>;
    fn release_resources(&mut self) -> Result<(), Self::Error>;
    fn diagnostics(&self) -> DeviceDiagnostics; // counters only, no handles
}

// Frame graph as an ordered pass list; no new UI tree.
struct FramePass<'a> { kind: PassKind, commands: &'a [GpuCommand] }
fn record_frame(device: &mut impl GpuDevice, passes: &[FramePass]) -> Result<Surface, DeviceError>;

// Asset-handle form (replaces owned pixel clone in the command).
struct ImageId(u64);
enum GpuCommand { /* ... */ Image { id: ImageId, position: Point, opacity: u8 } }
fn upload_image(device: &mut impl GpuDevice, key: u64, pixels: &[u8]) -> Result<ImageId, DeviceError>;
```

Behavior: `begin_frame` still gates submission; `finish_frame` remains the only
close; every new hook is defaulted so existing callers compile. `GpuDeviceLifecycle`
is an **L3-owned** seam; the Canvas rendering port that L4b implements is
**L4a-owned** and is only requested here, not declared in an adapter package
(D-001 v2:74-83). `record_frame` is an L4b caller of the L3 seam. No
implementation is authorized here.

## 7. Performance budget, rule-check, anti-pattern checklist

**Budget (non-numeric):** at most one command encoder and one vertex upload per
frame; one bind group per resident cached image; one content hash per changed
image; no heap allocation in the per-triangle loop; counters, not wall time,
are the only campaign-owned measurements. Any cost figure is
`PENDING_VERIFICATION`.

**D-001 v2 rule-check** (v1's eight rules are redistributed across v2
§§1/4, 5/8, 7, 7, 3+11, 8, 3, 3): (1) downward-only — L3 consumes L2/L1 and
never L4a; L4b consumes L4a port + L3 + L2 (v2:18-22,58-70); (2) stable
boundaries — `GpuDevice` is an L3-owned seam; the Canvas rendering port belongs
to L4a and is not mirrored in L4b/L3 (v2:74-83); (3) single-pass — lower once
per frame, no repeated tree scans (v2:104-105); (4) explicit ownership —
contiguous `Vec`, no boxed per-node hot values, bounded cache, no upward refs
from L3 (v2:90-103); (5) native widgets at L4b→L3 — Canvas is an embedded
surface, never a replacement UI (v2:53,139); (6) honest diagnostics — typed
errors, `UiDiagnostic`s and counters, no fabricated support (v2:107-113); (7)
per-layer gates — headless correctness fixtures below, no benchmark campaign
(v2:51-56); (8) escalation — L0/L1 protected, requests only; `xylem lint`
architecture enforcement is not shipped (v2:48-50,130-134).
**v2-specific:** source dependency ≠ runtime call direction — device events
cross upward only via subscriptions established above, with numeric ids/borrowed
snapshots (v2:85-93).

**Anti-patterns:** per-draw `create_buffer`/`create_command_encoder`/`submit`
(`lib.rs:638,647,673`); cloning full `Image` into `GpuCommand`
(`backend.rs:182-186`); rehashing pixels per draw; whole-cache invalidation as
the only resize policy; blocking readback on the web path; relying on field
drop order instead of `release_resources`; duplicating layout/accessibility
inside a Canvas; cross-adapter or wall-time claims from one adapter.

## 8. Interface requests to protected teams

- **L4a UI contract owner:** request a versioned Canvas rendering port
  (scene-in, surface-out, `UiDiagnostic` on unmappable content) owned by L4a,
  so L4b adapters implement rather than define it (D-001 v2:52,74-83,114).
- **L1 ownership/value model:** request a stable borrowed-image/asset-ID view
  so render commands need not clone pixel buffers. Do not modify RC/COW code.
- **L0/L2 host:** request a device-loss and capability-change notification
  channel into the L3 event loop (WebGPU §4.4 requires handling loss at any
  time); delivery upward by subscription (v2:85-93).
- **L7 tooling:** request a non-wall-time resource-counter fixture target and
  architecture-rule enforcement; style lint `W7001`–`W7004` is not architecture
  enforcement (v2:130-134). Do not touch the protected benchmark harness.

## 9. Phased milestones and verification gates (no CI/deploy triggers)

1. **P0 — Document the boundary.** Gate: this doc reviewed against D-001 v2
   (L3 substrate / L4b Canvas adapter, L4a-owned port); the
   main-tree/worktree I091 divergence recorded as PENDING.
2. **P1 — Lifecycle fixtures.** Gate: adapter-free tests assert frame-order
   errors, LRU victim determinism, eviction/invalidation/clear counters, and
   zero-size/overflow rejection; no adapter required.
3. **P2 — Submission batching (design gate only).** Gate: review that the
   planned pass list has one encoder and one staged upload; cost claims remain
   PENDING_VERIFICATION.
4. **P3 — Web-parity review.** Gate: audit that only transferable logic is in
   the shared path, that the web L4b adapter consumes the L4a port rather than
   defining one, and that async readback + device-loss handling are specified
   before any web adapter work.
5. **P4 — Cross-adapter evidence (deferred).** Gate: only after explicit
   owner authorization and outside the protected harness; no claim until then.

Each gate is a human review/correctness fixture; none triggers CI or deploy.

## 10. Open questions and full sources

- Resolved by v2: the v1 "L3 serves L4" inversion is now L4a-owned port +
  L4b-implemented adapter (D-001 v2:1-3,72-83). Open: exact version identity
  format for the L2–L7 ports, including the Canvas port (v2:142-145).
- Does the pinned wgpu expose `Device::destroy()`; if not, is a handover
  interface needed? (GPU_LIFECYCLE.md §4 currently relies on drop.)
- Should resize invalidation reuse same-format scratch textures (Skia) or stay
  whole-cache destructive (current I091 behavior)?
- Can a scene-content version be supplied so image hashes are computed once
  per change without touching L1 value semantics?
- How does capability negotiation report an unmappable Canvas on mobile without
  device hardware, and who owns architecture lint enforcement (v2:144,130-134)?

**Self-critique (one pass).** Weakest assumption: that one-adapter headless
verification generalizes enough to recommend a single-encoder pass design.
Contrary evidence: WebGPU §2.2.6/§3.6 allow withheld adapter identity and
optional features, and Vulkan Guide warns that "best" resource strategies are
hardware-dependent; therefore the recommendation is staged behind P2/P4 and
makes no portability guarantee. Re-reviewing against D-001 v2 changed the
recommendation's structure: my earlier "L3 serves L4" wording was ambiguous, so
layer placement, the product dependency matrix, the rule-check and the
ports/adapters boundary were rewritten around L4a port ownership and L4b
implementation. The I091 main-tree/worktree divergence is still demoted to the
worktree path. No performance numbers were added.

**Sources.** Local: paths and `file:line` above; `docs/decisions/D-001-platform-layering.md:1-3,18-26,30-42,44-70,72-93,95-101,107-114,116-126,130-147`;
`ecosystem-worktrees/task-platform-gpu/crates/xylem-graphics-wgpu/GPU_LIFECYCLE.md:41-102`.
External (all accessed 2026-11-25): https://wgpu.rs/doc/wgpu/documentation/internals/architecture/index.html ;
https://docs.rs/wgpu/latest/wgpu/ ; https://docs.rs/wgpu/latest/wgpu/enum.BindingType.html ;
https://docs.rs/wgpu/latest/src/wgpu/api/bind_group.rs.html ;
https://docs.rs/bevy/latest/bevy/render/enum.RenderSystems.html ; https://bevy.org/news/bevy-0-6/ ;
https://android.googlesource.com/platform/external/skia/+/cfe11bf71c50320fe5887e1b5f98c99e44d20bea/src/gpu/GrResourceCache.cpp ;
https://skia.googlesource.com/skia/+/db9f95c8880ab13cf19d3ff152f6a2cb756533da/src/gpu/GrResourceProvider.cpp ;
https://docs.vulkan.org/guide/latest/memory_allocation.html ; https://docs.vulkan.org/guide/latest/common_pitfalls.html ;
https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/PersistentObjects.html ;
https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/BufferBindings.html ;
https://learn.microsoft.com/en-us/windows/win32/direct3d12/using-resource-barriers-to-synchronize-resource-states-in-direct3d-12 ;
https://learn.microsoft.com/en-us/windows/win32/direct3d12/descriptor-heaps ;
https://gpuweb.github.io/gpuweb/ ; https://www.w3.org/TR/webgpu/ .
