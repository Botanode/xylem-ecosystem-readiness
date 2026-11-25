---
doc_id: ECO-DESKTOP-001
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
---

# DESKTOP — `xylem-linux-desktop` / desktop family (D-001 v2)

Design-only. No code, builds, commits, CI, pushes, or protected-source edits.
All status tags are evidence classifications, not independently reproduced
results. `ecosystem-readiness/docs/decisions/D-004-product-surface.md` is referenced by `DESIGN/README.md:44`
and `work_logs/archive/phase-02-integration-status.md:76` but is **absent from
this workspace**; the owner decision is reconstructed from that status file
(lines 74–83) and is **PENDING**. Live `websearch` returned no results here;
external claims were verified by `webfetch` of the exact primary URLs in §10.
This revision follows **D-001 v2** (`docs/decisions/D-001-platform-layering.md`,
amended 2026-11-25), which explicitly fixes the v1 L3→L4 dependency inversion.

## 1. Layer placement, dependency matrix, and rule-check

**Placement.** Under D-001 v2 §2–§5, desktop products are **L4b target UI
adapters** implementing the **L4a rendering port** owned by `xylem-ui`, over
**L3 platform substrate** (event loop, surface, input, timers, device). The
port lives in L4a; the GTK/libadwaita adapter implements it and must not mirror
or redefine it. **L3 must not depend on L4a** and must not render `UiDocument`.

Source dependencies (D-001 v2 §4 matrix; only relevant rows):

| From ↓ / To → | L2 | L3 | L4a | L4b | L5 | L6 | L7 |
|---|---|---|---|---|---|---|---|
| L3 substrate | yes | — | **no** | no | no | no | no |
| L4a `xylem-ui` | yes | **no** | — | no | no | no | no |
| L4b GTK adapter | yes (via L3) | yes | **yes (port)** | no¹ | no | no | no |
| L5 framework | yes | yes | yes | **no** | — | no | no |
| L6 application | yes | no | yes | no | yes | — | no |
| L7 delivery plane | yes | yes | yes | yes | yes | yes | — |

¹ Sibling adapters never depend on each other; they meet through L4a/L3 ports.
No runtime layer depends on L7 — packaging/CLI are a delivery plane, not a tier.

**Runtime vs source direction** (D-001 v2 §6): source deps point downward, but
events flow upward: **L3 input event → L4b adapter → L4a document update → L5
state change**. The subscription is established by the upper layer; L3 never
stores upper-layer state. Cross-boundary callbacks use numeric `UiNodeId`s and
borrowed snapshots, not closures capturing owned upper-layer data.

**Existing inversion to record, not fix here.** The current single
`xylem-desktop` crate mixes L3 host code with L4a consumption:
`src/lib.rs:19` imports `xylem_ui`, `src/ui.rs:11-14` lowers `UiDocument`, and
`src/platform.rs:21,248-251` validates/negotiates it inside the host. Under v2
this is an L3→L4a source inversion. It is recorded as a gap and an interface
request (§8); no boundary change is implemented by this design.

Rule-check against D-001 v2 §3–§8:

| Rule | Conformance |
|---|---|
| Port owned by its layer; no mirrored port in adapter | L4a owns the rendering port; `WidgetMapV1` is an adapter-internal instantiation, not a second contract. PASS by design; version identity **PENDING**. |
| L3 must not render `UiDocument` or define UI ports | L3 owns only loop/surface/input/dialogs/clipboard; the `ui.rs` lowering is L4b responsibility after boundary split. **GAP** recorded, no code change. |
| L4b must not define a second UI model or depend on sibling adapters | One `UiDocument` from L4a; GTK adapter has no web/Qt dependency. PASS by design. |
| Downward-only source deps; runtime events may flow up | Matrix above; numeric-id event path in §5. PASS by design. |
| Versioned boundary identities; typed diagnostics; no silent fallback | `UiDiagnostic` from L4a, versioned port/plugin ids — identity format **PENDING** (D-001 v2 §11). |
| Single-pass validation/layout; owned state; no global registry | §7 structural budget; one document owned by L4a/L6 state, widget handles by L4b. PASS by design, unverified. |
| L7 is a plane, never a runtime dependency | Packaging/update manifests live at L7; no L3/L4b import of CLI/tooling. PASS. |
| L0/L1 protected | No compiler/value-model edits or interface requests. PASS. |

## 2. Current Xylem assets and exact gaps

**L4a policy core.** `xylem-ui/src/lib.rs:24-68`: `UiDocument`, `validate()`,
`debug_tree()`, `accessibility_tree()`; `UiNode` at `:356-364`; five
`UiElementKind`s at `:751-759`; `UiBinding`/`UiHandler` at `:824-845`;
`UiLayout` at `:868-876`; `UiAccessibility`/`UiRole` at `:925-978`;
capabilities/negotiation/lifecycle at `:133-148,217-227,280-335`. Status:
**IMPLEMENTED_BUT_LIMITED** (`ecosystem-worktrees/xylem-platform/docs/CRATE_STATUS.md:13`,
12 + 13 tests recorded). D-001 v2 §9 names `xylem-ui` the single source of
truth; no product may duplicate it.

**L3 substrate (today, colocated).** `xylem-desktop/src/platform.rs:239-470`
opens an X11 window and runs `wait_for_event()` (`:365`); `:197-203` advertises
window/input/clipboard/native-controls; `xylem-graphics` software surface and
scene painting are used at `:482-598`; AT-SPI via `accesskit_unix` is at
`src/accessibility.rs:18-43,68-141`. Status: Rust adapter
**IMPLEMENTED_BUT_LIMITED** (`CRATE_STATUS.md:16`: 16 layout tests passed, 3
ignored; `ui_document.rs`, native-window and packaging tests not run).
D-001 v2 §9 classifies `xylem-graphics`/wgpu as L3 substrate **and** L4b
`Canvas` adapter.

**L4b gap.** `src/ui.rs:111-124` (`render_ui_document`) and `:16-78,126-169`
(the `NativeNode`/`NativeControl` tree) are adapter work living inside the L3
host crate; no target-specific GTK/Qt widget backend exists. The Xylem-side
product is **SPECIFIED_NOT_IMPLEMENTED** — `xylem-platform/AGENTS.md:8-9`
preserves Rust adapters; there is no `.xy` desktop product.

**Other gaps:** no versioned L4a rendering port identity; no general
native-widget→`UiEventKind` router beyond `run_with_input` (`platform.rs:212-245`);
no a11y ownership rule between native widgets and the parallel AccessKit tree;
no Wayland application host (the compositor is a separate crate); no production
signer/update host (WL-56/WL-67); macOS/Windows/mobile blocked by WL-63–WL-67
(`ecosystem-worktrees/xylem-lang/docs/tooling/cross-target-capabilities.md:57-66`).

**Collision resolution (retained).** Do not create, rename, or publish a crate
named `xylem-desktop`. D-001 v2 §9 lists `xylem-linux-desktop` (label) and the
existing `xylem-desktop` crate together as "L4b adapter + L3 host" consuming
L4a and L3; §11 leaves the crate-name ruling open (D-002). Proposal: keep the
Cargo crate `xylem-desktop` as the single adapter/host implementation and use
`xylem-linux-desktop` only as the **product label** for the L6 acceptance app
and L7 packaging/update manifests, depending downward on L4a/L3. No second
adapter, no sideways dependency. If a distinct distributable crate is
required, name it `xylem-linux-desktop-app` — **PENDING owner ruling (D-002)**.

## 3. Existing products studied (primary sources) and traps

| Approach | Primary source evidence | Event loop / rendering | Accessibility | Distribution / update | Documented tradeoff; D-001 v2 fit |
|---|---|---|---|---|---|
| GTK4 + libadwaita (native widgets) | `https://docs.gtk.org/gtk4/`; `/drawing-model.html`; `/input-handling.html`; `/section-accessibility.html`; `/section-threading.html`; `https://docs.gtk.org/glib/main-loop.html`; `https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/index.html` | Mainloop-driven frame clock Events→Update→Layout→Paint; cached GSK render nodes; GL/Vulkan/cairo renderers; capture/target/bubble event phases; GUI-thread affinity | Standard controls implement `GtkAccessible`; `GtkATContext` proxies AT-SPI (Linux), NSAccessibility (macOS), MSAA (Windows); "a role is a promise" | Out of scope for GTK docs; L7 handles delivery | Best L4b fit: real widgets, native a11y, no bundled runtime. Worker results must return via idle/`g_main_context_invoke()`. No numeric claim. |
| Qt Widgets / Qt Quick | `https://doc.qt.io/qt-6/eventsandfilters.html`; `https://doc.qt.io/qt-6/accessible.html` | `QEvent` objects, virtual handlers, event filters; `postEvent()` compresses resize/paint events | Platform APIs expose semantic structure; ready-made widgets carry metadata; custom widgets extend it | Not claimed from fetched docs | Event-routing pattern for a future sibling L4b adapter; no cross-adapter dependency. |
| winit | `https://docs.rs/winit/latest/winit/` | Window creation + `EventLoop::run_app`, `RedrawRequested`; `ControlFlow::Wait` for event-driven apps; X11/Wayland backends; **no drawing methods** | No built-in a11y | Not claimed | L3 mechanism only. Pairing it with a custom renderer as *widgets* would breach D-001 v2 §3 (L3 must not render) and §11. |
| Tauri | `https://github.com/tauri-apps/tauri`; `.../blob/dev/ARCHITECTURE.md`; `https://v2.tauri.app/develop/calling-rust/`; `https://v2.tauri.app/plugin/updater/`; `https://v2.tauri.app/distribute/` | TAO (winit fork) + WRY → WKWebView/WebView2/WebKitGTK; typed commands, async commands, channels, events | Web-content tree, not native widgets | Bundles `.deb`/AppImage; updater signature cannot be disabled; TLS enforced in production; AppImage + `.sig` | First-party claim: small binaries "because they use the OS's webview" and ship no runtime. As UI, out of scope under D-001 v2 (no embedded-browser fallback); only L7 delivery/IPC patterns are informative. |
| Electron | `https://www.electronjs.org/docs/latest/tutorial/process-model`; `/performance`; `/accessibility`; `/updates` | Main + renderer processes; preload/`contextBridge`; checklist warns against blocking main/renderer and eager module loading | HTML-based; auto-enabled with assistive tech | Squirrel/`autoUpdater`; free official update service macOS/Windows only | Multi-process isolation vs IPC boundary and eager-work traps; webview UI not an L4b native adapter. |
| iced / druid / Xilem | `https://github.com/iced-rs/iced`; `https://github.com/linebender/druid`; `https://github.com/linebender/xilem` | iced: renderer-agnostic runtime, wgpu/tiny-skia, winit shell, **experimental**; druid: native runloop, piet, **UNMAINTAINED**; Xilem: winit + Vello/wgpu + AccessKit, **experimental** | AccessKit-based, not native widgets | Not claimed | Borrow single-pass layout ideas; do not import their renderers or define a parallel UI model (L4b prohibition). |
| Flutter desktop | `https://docs.flutter.dev/resources/inside-flutter`; `https://docs.flutter.dev/ui/widgets/accessibility` | One layout per frame, single-pass constraints-down/geometry-up, dirty-element build, linear reconciliation, separate Element/RenderObject trees | `Semantics`, `MergeSemantics`, `ExcludeSemantics` | Not claimed | Strong evidence for single-pass anti-pattern rules; still a custom renderer + semantics tree, not an L4b native-widget adapter. |

Traps: duplicated event loops, whole-tree rebuild per event, per-widget heap
objects, parallel a11y exports, and treating a webview or canvas as the widget
system.

## 4. Options and recommendation

- **A — Native-widget L4b adapter implementing the L4a port (RECOMMENDED).**
  GTK4/libadwaita widgets realize the shared document; L3 provides loop/surface;
  native properties carry accessibility. Pros: correct source direction, native
  focus/keyboard/AT behaviour, no browser runtime. Cons: one adapter per target;
  finite widget map; native dev packages needed for gates.
- **B — Custom renderer on winit as the UI.** REJECTED: would make L3 render a
  document (D-001 v2 §3), duplicate `xylem-graphics`, and duplicate a11y.
  Permitted only for `UiElementKind::Canvas` (L3 substrate + L4b Canvas adapter).
- **C — Embedded webview fallback.** PROHIBITED (no browser fallback); only its
  L7 signing/update and IPC patterns may be studied.
- **D — Current core-X11 draw host as product UI.** Limited to deterministic
  fixtures and canvas painting, never a native-widget replacement.

Recommended **A**, with D retained only as a headless/test host and Canvas
surface. No existing code is modified by this design.

## 5. Shared UI to native component mapping (L4a port → L4b adapter)

The port and `UiDocument` stay in L4a; the table below is adapter-internal
realization keyed by `UiNodeId`, never a second UI model in the adapter package.

| Shared L4a item | GTK4/libadwaita (L4b) | Future Qt (L4b) | Notes |
|---|---|---|---|
| `Column` / `Row` (`UiLayout.direction`) | `GtkBox` vertical / horizontal | `QVBoxLayout` / `QHBoxLayout` | Native layout; no per-frame recompute. |
| `Button` + `Click` | `GtkButton::clicked` | `QPushButton::clicked` | `UiHandler` is a name, not code. |
| `TextInput` + `Input`/`Change` | `GtkEntry`/`GtkText` `changed` | `QLineEdit::textChanged` | `UiBinding.path` updates document state; `UI-003` forbids children. |
| `Text` | `GtkLabel` | `QLabel` | No separate a11y node unless `UiRole::Text`. |
| `Canvas` (`Scene`) | `GtkDrawingArea`/`GLArea` | `QWidget::paintEvent` | L3 rendering substrate under L4b Canvas adapter only. |
| `Fragment` | Transparent container/inline flatten | same | No accessible role emitted. |
| `Conditional` | Rebuild/show-hide dirty subtree by id | same | One patch per state change. |
| `Collection` | `GtkListBox`/`ListView` + `GListModel` keyed by `UiCollection.key` | `QListView` + model | Stable keys avoid id churn (`UI-006`). |
| `UiAccessibility`/`UiRole` | `GtkAccessible` role/label/description | `QAccessible` | Preserve `accessibility_tree()` order/values; one export per node. |

**Unmappable, with reasons:** arbitrary `UiStyle` token names (no native
equivalent → theme fallback + `UiDiagnostic`); `UiBinding`/`UiHandler` names
(state references, not callables); `Points(f32)` across DPI/unit systems (host
scaling); ungranted `Filesystem`/`Network`/`Notifications` capabilities
(negotiation failure, no fabricated widget); rich scenes beyond 2D primitives
(Canvas only); and macOS/Windows/mobile targets (WL-63–WL-67).

**A11y semantics.** L4a `accessibility_tree()` is the conformance oracle;
native widget properties are the export path. The existing `AtspiBridge` builds
a parallel tree from the document (`accessibility.rs:68-141`) and would duplicate
nodes once GTK widgets export themselves. Resolution: native widgets own a11y
for mapped elements; AccessKit is limited to Canvas/unmapped cases with
incremental updates — interface request in §8.

**Event/binding routing (D-001 v2 §6).** L3 delivers a raw input event; the
L4b adapter translates it to `(UiNodeId, UiEventKind, borrowed snapshot)` and
subscribes upward; the L4a document is updated once and emits patches; L5 may
react to the resulting state change. Subscription is established by the upper
layer; L3 stores no upper-layer state. `run_with_input` (`platform.rs:239-245`)
is only the current bounded example of this path.

## 6. API sketch (signatures and behaviour only)

```text
// L4a — owned by the policy core; not mirrored in any L4b package
port RenderPortV1 {                 // identity + version required by D-001 v2 §8
    mount(&UiDocument) -> Result<RenderState, UiDiagnostic>
    dispatch(UiNodeId, UiEventKind, BorrowedSnapshot) -> Vec<UiPatch>
    accessibility_snapshot(&[UiNodeId]) -> Vec<UiAccessibility>
    report_unmappable(&UiDocument) -> Vec<UiDiagnostic>
}

// L4b GTK adapter implements RenderPortV1 using L3 surface/input mechanisms;
// L4b owns widget handles; L3 owns loop/surface state.
map_document(&UiDocument, &RenderPortV1) -> Result<WidgetTree, UiDiagnostic>
apply_patches(&mut WidgetTree, &[UiPatch]) -> Result<(), DesktopError>
negotiate_native(target: &str) -> UiPlatformCapabilities
```

No implementation is authorized here.

## 7. Performance budget and anti-pattern checklist

Budget (structural; no performance or timing claims — certification belongs to
the protected L0/L1 campaign):

| Item | Rule | Status |
|---|---|---|
| `validate()` | Once per document state change, never per frame | PENDING_VERIFICATION |
| Layout | One pass per dirty subtree; native layout reused | PENDING_VERIFICATION |
| A11y | Incremental for changed ids only; single export owner | PENDING_VERIFICATION |
| Document clones | None on event hot path | PENDING_VERIFICATION |
| Event source | L3 toolkit loop / `wait_for_event`, never a poll loop | PENDING_VERIFICATION |
| Boundaries | Versioned port identity; typed errors; no mirrored ports | PENDING |
| Measurements | No benchmark/CI/deploy from this design | PASS by scope |

Anti-pattern checklist (D-001 v2 §3, §7; `DESIGN/README.md:17-19`):

- [ ] L3 renders `UiDocument`, imports L4a, or defines a UI port — **forbidden**; current colocation is a recorded gap.
- [ ] L4b defines a second UI model, mirrors the port, or depends on a sibling adapter — **forbidden**.
- [ ] Per-widget heap `Rc`/boxed per-node values in hot paths — **forbidden**; use arenas/borrowed ids (Flutter's child-model-agnostic leaves are the contrary pattern).
- [ ] Recompute layout every frame — **forbidden**; GTK queues Layout/Paint only on change and caches render nodes.
- [ ] Refcount/COW churn across the tree per event — **forbidden**; use dirty id sets.
- [ ] Polling instead of events — **forbidden**; winit `ControlFlow::Wait`, GLib `GMainLoop`, Qt `postEvent`, `platform.rs:365`.
- [ ] Hidden global mutable registry or duplicated main loops — **forbidden**; only explicit versioned L3/L4a/L7 registries.
- [ ] Upper-layer state stored in L3, or upward callbacks capturing owned data — **forbidden**; numeric ids/borrowed snapshots only.
- [ ] Webview fallback or custom renderer presented as widgets — **forbidden** (D-001 v2 §11).
- [ ] Silent capability fabrication — **forbidden**; emit `UiDiagnostic`.
- [ ] L7 as a runtime dependency of L3/L4b — **forbidden** (delivery plane only).

## 8. Interface requests (no protected code touched)

1. **L4a owner:** version identity for `RenderPortV1` and an explicit
   "unmappable element → `UiDiagnostic`" rule; the port must remain in L4a.
2. **L4b/L3 owner:** separate the colocated host/lowering boundary so L3 no
   longer has a source dependency on `xylem_ui` (no code change here; D-001 v2
   §3/§5).
3. **L3 owner:** readiness/input/surface port review so the GTK loop is owned
   once and subscriptions are established upward with explicit lifetimes.
4. **L3/L4a joint:** a11y ownership contract to prevent duplicate AT-SPI nodes.
5. **L7 owner:** production Debian signing identity + public update host
   (WL-56/WL-67 remain follow-ups, not shipped claims).
6. **L0/L1:** none. Missing compiler/host intrinsics go to a defect handover.

## 9. Phased milestones and gates (no CI/deploy triggers)

| Phase | Scope | Gate |
|---|---|---|
| P0 Evidence | Sources, D-001 v2 rule-check, collision decision | Reviewed here; collision ruling **PENDING (D-002)**. |
| P1 Port spec | Versioned `RenderPortV1` in L4a + unmappable diagnostics; no new crates | Port reviewed against all node/element kinds and L4a ownership confirmed. |
| P2 L4b GTK adapter | Real widgets in an isolated worktree with native dev packages | Every mapped kind produces a native widget; a11y tree matches `accessibility_tree()`; Xvfb/AT-SPI fixture recorded. |
| P3 Boundary + routing | L3→L4a source dependency removed at boundary level; event→document→patch path | No L3 import of L4a in adapter architecture; one `validate()`/layout per change; no full-tree clone. |
| P4 L7 delivery | Signed package/update manifests | Loopback signed apt evidence recorded; production signer/update host PENDING; no release. |
| P5 Other targets | Qt/macOS/Windows/mobile | Blocked by WL-63–WL-67; sibling adapters never imported by GTK adapter. |

No build, benchmark, push, CI, or deploy is triggered by this design.

## 10. Open questions, self-critique, and sources

**Open / PENDING:** owner ruling on `ecosystem-readiness/docs/decisions/D-004-product-surface.md` (absent) and
the `xylem-desktop` name collision (D-001 v2 §11 / D-002); port version identity
format; a11y ownership; Qt backend timing; production signing/update host;
independent verification of all status tags; real screen-reader acceptance;
macOS/Windows/mobile gated by WL-63–WL-67.

**Self-critique (one pass).** The previous revision placed the adapter at
"L3 + L4" and let the L3 host validate/lower `UiDocument`. D-001 v2 §1 calls
exactly that a dependency inversion; contrary evidence is in this tree at
`xylem-desktop/src/lib.rs:19`, `ui.rs:11-14`, `platform.rs:21,248-251`. **Revised:**
the document now places GTK at L4b, leaves the rendering port in L4a, reduces L3
to substrate with **no L4a dependency**, and records the existing colocation as
a gap/interface request rather than treating it as the design. Second
assumption revised: the old AccessKit bridge could not be reused unchanged
because GTK standard controls already export accessibility; a11y ownership is
now a request. Third: the collision resolution remains a proposal, explicitly
PENDING.

**Local sources (exact paths/lines).**
`ecosystem-readiness/DESIGN/README.md:1-73`;
`ecosystem-readiness/work_logs/archive/phase-02-integration-status.md:74-83`;
`docs/decisions/D-001-platform-layering.md:v2 §§1-11 (lines 1-147)`;
`xylem-platform/README.md:44-54`; `xylem-platform/AGENTS.md:1-11`;
`ecosystem-worktrees/xylem-platform/docs/CRATE_STATUS.md:13-19`;
`ecosystem-worktrees/xylem-lang/docs/tooling/cross-target-capabilities.md:57-66,95-105`;
`xylem-platform/crates/xylem-ui/src/lib.rs:24-68,133-148,217-227,280-335,356-364,751-759,824-845,868-876,925-978`;
`xylem-platform/crates/xylem-desktop/src/{lib.rs:19,39-42,ui.rs:11-14,16-78,111-169,platform.rs:21,197-245,248-251,364-365,482-598,accessibility.rs:18-43,68-141}`;
`xylem-platform/crates/xylem-desktop/Cargo.toml:1-14`.

**External primary sources (fetched).**
GTK4: https://docs.gtk.org/gtk4/ ; https://docs.gtk.org/gtk4/drawing-model.html ; https://docs.gtk.org/gtk4/input-handling.html ; https://docs.gtk.org/gtk4/section-accessibility.html ; https://docs.gtk.org/gtk4/section-threading.html ; https://docs.gtk.org/glib/main-loop.html ; https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/index.html
Qt: https://doc.qt.io/qt-6/eventsandfilters.html ; https://doc.qt.io/qt-6/accessible.html
winit: https://docs.rs/winit/latest/winit/
Tauri: https://github.com/tauri-apps/tauri ; https://github.com/tauri-apps/tauri/blob/dev/ARCHITECTURE.md ; https://v2.tauri.app/develop/calling-rust/ ; https://v2.tauri.app/plugin/updater/ ; https://v2.tauri.app/distribute/
Electron: https://www.electronjs.org/docs/latest/tutorial/process-model ; https://www.electronjs.org/docs/latest/tutorial/performance ; https://www.electronjs.org/docs/latest/tutorial/accessibility ; https://www.electronjs.org/docs/latest/tutorial/updates
iced/druid/Xilem: https://github.com/iced-rs/iced ; https://github.com/linebender/druid ; https://github.com/linebender/xilem
AccessKit: https://github.com/AccessKit/accesskit
Flutter: https://docs.flutter.dev/resources/inside-flutter ; https://docs.flutter.dev/ui/widgets/accessibility
Ports/adapters references cited by D-001 v2 §1 (not independently fetched here): https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html ; https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html ; https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff650258(v=pandp.10)
