---
doc_id: DESIGN-MOBILE
product: xylem-native-mobile
d001_version: v2 (amended 2026-11-25; v1 L3→L4 inversion removed)
status: SPECIFIED_NOT_IMPLEMENTED
product_status: PLANNED / SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
author: D-MOBILE (design-only; no implementation, builds, pushes or CI)
---

# `xylem-native-mobile` — design specification (paper only)

**Honest status.** This document specifies a *planned* product. It does **not**
claim implementability in this environment. There is no iOS/Android SDK,
simulator, device, signing identity, or mobile lifecycle/touch host here
(`WL-64`, `WL-65`). No package under this name may be created in this campaign
(`ecosystem-readiness/docs/decisions/README.md:65,69`). All design claims below
are `SPECIFIED_NOT_IMPLEMENTED` unless explicitly marked as existing local code.

## 1. Current Xylem assets and exact gaps

Product placement under D-001 v2: `xylem-native-mobile` is an **L4b target
adapter + L3 host**, consuming L4a's port and L3 mechanisms (`D-001:116-124`).
No package exists; all product-level work is `SPECIFIED_NOT_IMPLEMENTED`.

| Asset (local primary source) | What exists | Gap for mobile |
|---|---|---|
| `xylem-platform/crates/xylem-ui/src/lib.rs:25-28,75-83,356-364,682-696,752-759,847-866,868-876,925-966` | `UiDocument`, `UiApplication`, `UiNode`, `UiElement`, five `UiElementKind`s, five `UiEventKind`s, `UiBinding`, `UiHandler`, `UiLayout`, `UiAccessibility`, `validate()` | No mobile lifecycle events, gestures, dynamic insets/safe areas, runtime permission state, navigation/back semantics; no per-target widget mapping |
| `xylem-platform/crates/xylem-desktop/src/lib.rs:1-59` | Working X11 adapter: validation, layout, pointer/keyboard, focus, capabilities, mount/update/unmount | Proof of the adapter pattern only; X11 lifecycle ≠ mobile Activity/Scene lifecycle |
| `xylem-platform/crates/xylem-web/src/ui.rs:1-28,113-120` | One-way checked document → semantic HTML adapter; metadata retained, nothing silently dropped | Browser target, not native widgets; must not be reused as a mobile UI path |
| `xylem-rust/crates/xylem-wasm/src/lib.rs:1-27,106-133` | Documented subset IR→WASM; `env` trap/storage/DOM imports | No native mobile backend or native ABI artifact |
| `docs/development/WORKLOG.md:1361,1364-1366` (in `ecosystem-worktrees/*`) | `WL-64` mobile foundation, `WL-65` platform expansion | Both `[!]`, blocked; unblock conditions require device runners and signing evidence |
| `docs/tooling/cross-target-capabilities.md:63-64` (in `ecosystem-worktrees/*`) | iOS/Android tagged `SPECIFIED_NOT_IMPLEMENTED` | Explicit "no SDK, simulator, device, or signing identity"; "no mobile lifecycle or touch host" |

**Required-but-absent:** native entry points (`Activity`/`UIViewController`),
touch/pointer host, safe-area and inset source, permission request/denial flow,
background lifecycle observation, back-navigation host, native widget bridge,
packaging/signing/distribution evidence.

## 2. Layer placement, dependency table, and rule check

D-001 v2 (`docs/decisions/D-001-platform-layering.md:1-147`) fixes the v1
inversion: adapters sit **above** the policy core. `xylem-native-mobile` is an
**L4b target UI adapter** (iOS/Android widgets + embedded Canvas) running on an
**L3 platform host** (event loop, surface, input, lifecycle). L4a owns the
shared UI contract and the rendering port; L3 owns the readiness/input/surface
port; L2 owns capabilities (`D-001:44-56,72-84,116-124`).

**Source dependency table (mobile slice; `D-001:58-70`):**

| From ↓ / To → | L2 | L3 | L4a | L4b sibling | L5/L6/L7 |
|---|---|---|---|---|---|
| L3 host | yes (via L2) | — | **no** | no | no |
| L4a `xylem-ui` | yes | **no** | — | no | no |
| L4b mobile adapter | yes | yes (L3 port) | yes (rendering port, owned by L4a) | no¹ | no |
| L5/L6 | yes | L3 events only | yes | no | — |

¹ Adapters never depend on sibling adapters; they meet only through L4a/L3 ports.
**No L3 source may import L4a or L4b.** Runtime call/data flow may go upward via
subscriptions established by the upper layer (L3 input → L4b adapter → L4a
document update → L5 state); lower layers never store references to upper-layer
state (`D-001:85-93`).

**Rule check against D-001 v2:**

| Rule (`D-001` section) | Compliance |
|---|---|
| §4 downward-only source deps; §5 ports owned by owning layer | Yes: mobile L4b implements the L4a rendering port; consumes L3 + L2 ports; never defines/mirrors a UI port in its own package; never makes L3 depend on L4a |
| §5 no sibling-adapter coupling | Yes: no dependency on `xylem-web`/`xylem-desktop` internals; only L4a/L3 ports |
| §6 control flow via upper-layer subscription | Yes: L4b subscribes to L3 events; callbacks use numeric `UiNodeId`/borrowed snapshots, no captured owned upper-layer data |
| §7 per-layer state ownership | Yes: L4a owns `UiDocument`; L4b owns widget handles; L3 owns event-loop/surface state; no global mutable registry |
| §7 single-pass validation/index/layout; no boxed hot values | Yes: one `validate()`/layout per state change; id maps, arenas/borrowed views (§5, §7) |
| §3 native widgets, Canvas embedded only | Yes: native iOS/Android widgets; **no embedded-browser fallback**, no custom renderer replacing native widgets |
| §8 typed diagnostics + graceful degradation | Yes: `UiApplication::negotiate()` (`xylem-ui/src/lib.rs:133-148`) reports `missing`; unmapped elements → `UiDiagnostic` |
| §3/§9 verification gates | Yes: per-layer fixtures only on paper; no heavy builds/benchmarks, no performance claims; WL-64/WL-65 gates retained |
| §10 protected layers | Yes: §8 files interface requests; no L0/L1 edits |

## 3. Existing products studied (primary sources) and traps

| Framework | Sharing model / native UI | Lifecycle, input, insets | Documented trap | Source |
|---|---|---|---|---|
| Flutter | One layered stack: framework (widgets), engine (C++), platform embedder; own widgets/material/cupertino, AOT machine code in release | Embedder owns entrypoint, rendering surface, accessibility, input, event loop, app lifecycle; platform channels for host services | Own controls avoid platform transitions; **platform views** (native controls) need texture copy, hit-test/input translation and accessibility-tree mirroring — "a certain amount of overhead"; channels serialize maps to Kotlin/Swift equivalents; FFI avoids serialization | [arch](https://docs.flutter.dev/resources/architectural-overview), [channels](https://docs.flutter.dev/platform-integration/platform-channels), [modes](https://docs.flutter.dev/testing/build-modes) |
| React Native (New Architecture) | Shared JS/React with C++ renderer; JSI replaces async bridge; Fabric immutable view tree, TurboModules lazy | Synchronous layout/`useLayoutEffect`, concurrent rendering, event loop aligned to web | Old async bridge serialized calls, caused empty frames/UI jumps and made 60+ FPS hard; automatic batching needed to stop intermediate re-renders; "enabling the New Architecture … may not immediately improve performance" | [new arch](https://reactnative.dev/architecture/landing-page), [0.76 post](https://reactnative.dev/blog/2024/10/23/the-new-architecture-is-here) |
| SwiftUI | Declarative views on native AppKit/UIKit stack | `@main App`/scene lifecycle; `ScenePhase` active/inactive/background; background ⇒ "expect termination soon"; `safeAreaInset` grows safe area | Shared model must map into scene phases; cannot treat `Mounted` as equivalent to "interactive" | [scene phase](https://developer.apple.com/documentation/swiftui/scenephase.md), [life cycle](https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle.md), [insets](https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:).md) |
| Jetpack Compose | Declarative Kotlin UI on native Android | `Activity` callbacks `onCreate..onDestroy`; insets `safeDrawing`/`safeGestures`/`safeContent`, `ime`, displayCutout; gestures layered component → modifier → `pointerInput`; event **consumption** | Need highest gesture abstraction for semantics; custom gestures must consume events or parents double-handle; process death requires state restoration | [activity lifecycle](https://developer.android.com/guide/components/activities/activity-lifecycle), [insets](https://developer.android.com/jetpack/compose/system/insets), [gestures](https://developer.android.com/develop/ui/compose/touch-input/pointer-input/understand-gestures) |
| Compose Multiplatform / KMP | Shared `App()` UI in common code; `expect`/`actual` for platform APIs | Native entry points remain: Android `ComponentActivity`/`setContent`, iOS `ComposeUIViewController`, desktop window, web container | Shared UI does not remove platform entry points; unsupported APIs need platform source sets | [entry points](https://kotlinlang.org/docs/multiplatform/compose-multiplatform-entry-points.html), [expect/actual](https://kotlinlang.org/docs/multiplatform/multiplatform-expect-actual.html) |
| Capacitor / Ionic | Web app in a native WebView container + plugin bridge | Native shell wraps web UI; native plugins for device APIs | WebView-based "hybrid" container: explicitly a *web-first* runtime, native widgets are plugins, not the shared UI — incompatible with D-001 v2 §3/§5 | [Capacitor](https://capacitorjs.com/docs/) |

**Cross-cutting lesson:** successful frameworks share *description/state*, keep
*lifecycle, input and accessibility* in the native host, and minimise boundary
serialisation. Failed/expensive patterns are async bridge round trips, frequent
large-object copies across native↔managed boundaries, and in-place mutation of
one native view hierarchy that cannot be read synchronously.

## 4. Options and recommendation

- **A — WebView/Capacitor-style embedded browser UI.** Rejected. Violates D-001
  v2 §3/§5 (no embedded-browser fallback), gives up native widget
  accessibility/lifecycle and adds a serialising plugin bridge.
- **B — L4a `UiDocument` → L4b native widget adapter over L3 host (recommended).**
  One validated policy-core document; the mobile L4b adapter implements the
  L4a-owned rendering port, consumes the L3-owned input/surface port and L2
  capabilities, and maps to native iOS/Android widgets. Native entry points,
  lifecycle, gesture recognisers, insets and permissions stay in L3/host code.
  Matches the `xylem-desktop` L4b precedent and Flutter/KMP layering. Cost: IR
  extensions (§5) and two adapters; unverifiable here until WL-64/WL-65 pass.
- **C — Custom cross-platform renderer with own widgets.** Rejected by D-001 v2
  §3/§5; duplicates Flutter's engine work and hides accessibility behind a new
  tree-mirroring layer.
- **D — Shared Rust logic with no native host.** Rejected: nothing can own
  Activity/Scene lifecycle, touch, safe areas, signing or distribution.

**Recommendation: Option B, paper-only.** Treat it as a *specification* until
provisioning and compiler-backend gates in §9 pass.

## 5. Data/model/lifetime design, and Shared UI to mobile native component mapping

Per D-001 v2 §7, **L4a owns the `UiDocument`; L4b owns widget handles; L3 owns
event-loop/surface state**. The immutable document is the single source of truth;
the mobile L4b adapter keeps only a `UiNodeId → native widget handle` map, with
no second component/state model and no global mutable registry. L3 emits input;
L4b establishes the subscription and updates L4a (D-001 §6); callbacks cross
upward only as numeric ids/borrowed snapshots. `validate()` runs once per state
change (`xylem-ui/src/lib.rs:42-53`); layout/binding state is computed once into
indexed structures and reused. Event payloads are scalars or bounded owned
buffers, never boxed per-node values; cross-boundary ownership is explicit.
Lifecycle stays transient and unserialised (`lib.rs:70-83`).

### Shared UI to mobile native component mapping (all SPECIFIED_NOT_IMPLEMENTED; L4b implements the L4a-owned rendering port)

| L4a contract | iOS native counterpart (L4b) | Android native counterpart (L4b) | Gap / required extension |
|---|---|---|---|
| `Column` / `Row` (`lib.rs:752-759`) | `UIStackView` axis | `LinearLayout`/`Column` arrangement | Layout currently static `UiLayout` (`lib.rs:868-876`); needs dynamic environment (size classes, orientation) |
| `Text` (`lib.rs:773-777`) | `UILabel` | `Text` | Theme tokens only; no typography scale/Dynamic Type semantics |
| `Button` + `Click` | `UIButton` + tap recogniser | `Button` + `clickable` | Needs press states, accessibility traits, and gesture consumption |
| `TextInput` + `Input`/`Submit` | `UITextField`/`UITextView` | `TextField` | No keyboard type, secure entry, return-key or IME visibility field |
| `Canvas` + `Scene` (`lib.rs:490-511,1093-1121`) | embedded scene surface | embedded scene surface | Embedded surface only (D-001 v2 §3/§7); no standalone renderer |
| `Conditional`/`Collection` (`lib.rs:785-800`) | diffed subtree / table rows | diffed subtree / `LazyColumn` | Need stable keyed diff (already required by `UI-006`) to avoid re-render storms |
| `UiAccessibility` (`lib.rs:925-966`) | accessibility traits | semantics | Five roles insufficient for switch/header/adjustable; extend behind diagnostics |
| `UiCapability` (`lib.rs:217-227`) | native permission prompts | runtime permission flow | Declaration/negotiation only; no request, grant, denial or revocation state |
| `UiLifecycle` (`lib.rs:280-335`) | `ScenePhase` active/inactive/background | `onCreate…onDestroy` | Three phases cannot express pause/stop/background/process death |
| `UiEventKind` (`lib.rs:847-866`) | tap/long press/pan/pinch/swipe-back | pointer/gesture modifiers | No long-press, pan, pinch, swipe, appear/disappear or keyboard events |
| `UiEdges` (`lib.rs:897-903`) | safe-area insets | `WindowInsets` safeDrawing/safeGestures/ime/displayCutout | Static `f32` padding cannot represent dynamic, named inset sources |

**Concrete L4a policy-core extensions (gated by WL-64/WL-65, not implemented here):**
`UiLifecyclePhase` gains `Active/Inactive/Background/Destroyed` plus host event
mapping; `UiEventKind` gains `LongPress/Pan/Pinch/Swipe/Back/Appear/Disappear/
KeyboardChange`; a `UiInsets` with named sources (safe-area, system-gestures,
IME, display-cutout) and dynamic environment reads; `UiPermissionRequest` /
`UiPermissionState` plus extended `UiCapability` (Camera, Location,
Notifications, SecureStorage, BackgroundExecution) with denial → `UiDiagnostic`
and graceful degradation; `UiNavigation` (route id, stack, pop, deep-link) and a
`UiBackHandler` for Android system Back and iOS interactive-pop gestures;
extended text-input props and accessibility roles. Unmapped elements must emit
diagnostics, never silently render or fabricate support (D-001 v2 §8).

**Explicitly out of scope:** webview UI, custom renderer replacement, L0/L1
changes, compiler/LLVM/runtime work, cross-product packages, CI/deploy/release,
performance certification, and any claim of a shipped app.

## 6. API sketch — signatures and behaviour only

```text
// All items: SPECIFIED_NOT_IMPLEMENTED. Rust-like notation describes contracts only.
// Ports are owned by their layers (D-001 v2 §5); L4b implements, never mirrors, them.
trait UiRenderPort {                 // owned by L4a, implemented by mobile L4b
    fn set_document(&mut self, doc: &UiDocument) -> Result<(), UiDiagnostic>;
    fn dispatch(&mut self, id: UiNodeId, event: UiEventKind) -> Result<UiHandler, UiDiagnostic>;
    fn set_lifecycle(&mut self, phase: MobilePhase) -> Result<(), UiLifecycleError>;
}
trait PlatformPort {                 // owned by L3, consumed by mobile L4b
    fn capabilities(&self) -> UiPlatformCapabilities;      // L2-sourced
    fn subscribe(&self, sink: EventSinkId);                // upper layer subscribes
    fn insets(&self) -> UiInsets;                          // dynamic, named
    fn request_permission(&self, p: UiCapability) -> UiPermissionState;
}
fn mount(doc: &UiDocument, platform: &impl PlatformPort)
    -> Result<MobileAdapterSession, UiDiagnostic>;
fn unmount(session: &mut MobileAdapterSession) -> Result<(), UiLifecycleError>;
```

Behaviour: validate before any native mutation; one render pass per state
change; L4b subscribes to L3 input and reports ids/borrowed snapshots upward,
never stores upper-layer state; handlers referenced by name only;
denial/unsupported → diagnostic and graceful degradation; no serialised
whole-document round trips per frame.

## 7. Performance budget and anti-pattern checklist

Budget fields follow `PERFORMANCE_GUARDRAILS.md:115-132`; every value
`PENDING_VERIFICATION` — no numbers asserted here: cold/warm startup, steady
frame time p95, peak RSS, installed binary size, compressed bundle size,
allocations per node/operation, RC/COW increments and helper calls per op,
adapter/GPU facts. No performance claims from this campaign (D-001 v2 §3/§9).

Anti-pattern checklist (from `PERFORMANCE_GUARDRAILS.md:52-63`, F1–F10; R-numbers
there follow that document's taxonomy):

- [ ] No L3 source import of L4a/L4b; no UI port mirrored in L4b; no sibling-adapter dependency (D-001 v2 §5).
- [ ] No global mutable registry; no L3 callback capturing owned upper-layer state (D-001 v2 §6/§7).
- [ ] No heap allocation per UI/document node in hot paths; contiguous storage and borrow views (R4/F1).
- [ ] No opaque per-node helper/bridge calls inside a frame; typed, versioned boundary only (R2/F2).
- [ ] Validate/layout/bindings computed once per state change; no repeated whole-tree scans or re-parsing (R3/F3, F5).
- [ ] No per-event frame walk, no per-temp cell/frame allocation (F3).
- [ ] Bounded RC/COW traffic, single ownership authority, no global mutable lock (R4/F4).
- [ ] No bridge round trips per pointer move; batch/coalesce input to native gesture recognisers (Flutter channels/RN bridge evidence §3).
- [ ] No re-render storms: keyed diff, event consumption, no spurious whole-document rebuild (RN automatic batching, Compose consumption).
- [ ] No native-view/accessibility-tree mirroring on every frame (Flutter platform-view overhead).
- [ ] No large unversioned bundle or lazy-init stall at first screen (Flutter engine init guidance; app-size guidance).
- [ ] No fabricated capability support; denial is a diagnostic, not silent success (D-001 v2 §8/F8).
- [ ] No proxy-as-result, stale artifacts, debug timings or unpaired claims (R7/F8–F10).

## 8. Interface requests to the protected compiler team

No L0/L1 modifications are made or requested as edits here; these are
interface requests/defect handovers only:

1. A **pinned, versioned native AOT artifact** for iOS/Android (device ABI,
   static/shared library form, symbol identity) — current WASM subset
   (`xylem-wasm/src/lib.rs:1-27,106-133`) is not a mobile backend; release
   builds must not depend on JIT (Flutter build-mode evidence §3).
2. A documented **ownership/FFI contract** for linear-memory/ownership-based
   values crossing native↔managed boundaries: buffer lifetime, who frees,
   zero-copy borrow windows; must avoid per-value boxing and helper calls
   (F1/F2).
3. **L2 host intrinsics** for touch input, lifecycle, permissions, insets and
   background execution with stable IDs and diagnostics; this campaign will
   not implement or patch host intrinsics (D-001 v2 §10, protected layers).
4. **IR/ABI version identity and migration record** for every consumed
   interface; unsupported constructs rejected with stable diagnostics.
5. Confirmation of translated-device build support before any release
   artifact is claimed; no simulator-only evidence as release evidence.

## 9. Phased milestones with explicit provisioning gates

| Phase | Deliverable (paper) | Verification gate — blocks all later phases |
|---|---|---|
| M0 | This document; layer/rule check; source table | Design-only; no implementation authorized |
| M1 | Provisioning plan | **GATE WL-64/WL-65:** iOS/Android SDK, simulator/device runners, signing identities and documented capability matrix. Absent ⇒ stop |
| M2 | Native entry-point skeleton spec per platform | One target demonstrates native lifecycle mapping from host event → `UiLifecycle` without a WebView; architecture gate: L3 source imports no L4a/L4b; requires M1 |
| M3 | L4a IR extension spec + conformance fixtures | Diagnostics for every unmapped element/event; keyed diff; single-pass validation; L4b port not mirrored and no sibling-adapter import; requires M2 |
| M4 | Touch/inset/permission/back matrix spec | Gesture consumption, dynamic named insets, permission denial/degradation, Android Back and iOS interactive-pop; requires M3 and device runners |
| M5 | Packaging/signing/distribution evidence plan | Signed installable artifact + size/startup fields measured per guardrails; requires M1 + release artifact gate |
| M6 | Protected-compiler dependency confirmation | AOT artifact, FFI ownership contract, IR version record accepted by protected team; requires handover, not local edits |

No CI, deploy, push, release trigger or heavy measurement is authorized in any
phase. The §2 source-dependency table is a gate at M2/M3, not a future cleanup.
Every phase remains `SPECIFIED_NOT_IMPLEMENTED` until independently verified.

## 10. Open questions, sources, and self-critique

**Open/PENDING:** exact native widget set per element kind; whether `Canvas`
needs a dedicated surface adapter; how iOS interactive-pop maps to `UiBackHandler`;
which permissions map to which `UiCapability`; whether ownership values can be
borrowed zero-copy across the FFI boundary; all budget numbers; release artifact
identity; independent verification of every external citation.

**Self-critique (one pass).** Weakest assumption: that `UiDocument` can serve
mobile largely unchanged. Contrary primary evidence: mobile adds scene/activity
phases, multi-pass gesture consumption, dynamic named insets, runtime permission
denial and system Back — none representable in the current five event kinds,
three lifecycle phases and static `UiEdges` (`xylem-ui/src/lib.rs` as cited).
Revision: added the concrete extension list in §5, marked all of it
`SPECIFIED_NOT_IMPLEMENTED`, and required diagnostics for unmapped constructs.
Second challenge: could a WebView path satisfy "shared UI"? It is rejected
because Capacitor is explicitly a web-first container and D-001 v2 §3/§5 forbids
an embedded-browser fallback. Third: does shared UI remove native hosts?
KMP/Flutter evidence says no — native entry points/embedders remain. Fourth:
D-001 v2 supersedes the v1 placement used in the first draft; the v1 L3→L4
dependency was an inversion. Revision: §2 now places mobile at **L4b over an L3
host**, adds the downward-dependency table and v2 rule-check, §5/§6 move port
ownership to L4a/L3, and §9 gates the architecture at M2/M3. No implementation
is claimed.

**Local sources:** `ecosystem-readiness/docs/decisions/README.md:5-90`;
`docs/decisions/D-001-platform-layering.md:1-147` (v2, incl. §3–§10);
`xylem-platform/crates/xylem-ui/src/lib.rs:25-28,42-53,70-83,133-148,217-227,280-335,356-364,490-511,682-696,752-759,773-800,847-876,897-966,1093-1121`;
`xylem-platform/crates/xylem-desktop/src/lib.rs:1-59`;
`xylem-platform/crates/xylem-web/src/ui.rs:1-28`;
`xylem-rust/crates/xylem-wasm/src/lib.rs:1-27,106-133`;
`xylem-lang/docs/development/WORKLOG.md:1361,1364-1366` (worktree copies);
`docs/tooling/cross-target-capabilities.md:63-64` (worktree copies);
`ecosystem-readiness/DESIGN/PERFORMANCE_GUARDRAILS.md:50-63,115-132`.

**External primary sources (fetched 2026-11-25):**
https://docs.flutter.dev/resources/architectural-overview ;
https://docs.flutter.dev/resources/architectural-overview.md ;
https://docs.flutter.dev/platform-integration/platform-channels ;
https://docs.flutter.dev/perf/best-practices.md ;
https://docs.flutter.dev/perf/app-size.md ;
https://docs.flutter.dev/testing/build-modes.md ;
https://reactnative.dev/architecture/landing-page ;
https://reactnative.dev/blog/2024/10/23/the-new-architecture-is-here ;
https://developer.apple.com/documentation/swiftui/scenephase.md ;
https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle.md ;
https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:).md ;
https://developer.android.com/guide/components/activities/activity-lifecycle ;
https://developer.android.com/jetpack/compose/system/insets ;
https://developer.android.com/develop/ui/compose/touch-input/pointer-input/understand-gestures ;
https://developer.android.com/training/permissions/requesting ;
https://developer.android.com/studio/publish/app-signing ;
https://kotlinlang.org/docs/multiplatform/compose-multiplatform-entry-points.html ;
https://kotlinlang.org/docs/multiplatform/multiplatform-expect-actual.html ;
https://capacitorjs.com/docs/
