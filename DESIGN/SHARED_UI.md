---
doc_id: SHARED_UI
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
layering: D-001 v2 / L4a policy core
---

# SHARED_UI — shared UI policy core (L4a) and native target adapters (L4b)

**Layer statement (mandatory, D-001 v2).** This document is the canonical design
for **L4a — Shared UI contract / policy core**. L4a owns `UiDocument`, its
element/event/layout/accessibility contracts, capability negotiation, **and the
UI rendering port**. L4b target adapters implement that port; they do not define
or mirror it. The stack is L6 → L5 → L4b → L4a → L3 → L2 → L1 → L0, with L7 as
a developer/delivery plane (`docs/decisions/D-001-platform-layering.md:28-42,
46-56`). Source dependencies point downward toward stable policy; runtime call
and data flow may run the other way through subscriptions established by the
upper layer (`D-001:18-22, 85-94`). **L3 must not depend on L4a**: it renders
nothing UI-shaped and defines no UI port (`D-001:51, 63, 77-79`). L4a consumes
only L1 value semantics and L2 capabilities/diagnostics (`D-001:52, 64`); it
must know no DOM, GTK, AppKit, WinUI, UIKit or Android type. L4b consumes L4a's
port + L3 mechanisms + L2 (`D-001:53, 65`); sibling adapters never depend on
each other (`D-001:70`). L5 consumes L4a, not L4b directly (`D-001:54, 66`).

Input note: `ecosystem-readiness/ecosystem-readiness/docs/decisions/D-004-product-surface.md` referenced by
`DESIGN/README.md:30` and `work_logs/archive/phase-02-integration-status.md:74-83`
does not exist in the tree (checked). Names/gates below come from those sources
and D-001 v2; the missing decision is a PENDING source gap.

## 1. Current assets, status, and exact gaps

Statuses are `IMPLEMENTED_AND_VERIFIED` only where a local test is recorded;
otherwise `IMPLEMENTED_BUT_LIMITED` / `SPECIFIED_NOT_IMPLEMENTED`.

| Asset | v2 layer | Status | Evidence |
|---|---|---|---|
| `xylem-ui` document, validation, deterministic dumps | L4a | IMPLEMENTED_BUT_LIMITED | `crates/xylem-ui/src/lib.rs:24-68`; 12 lib + 13 invariant tests recorded in `ecosystem-worktrees/xylem-platform/docs/CRATE_STATUS.md:13` (not re-run here) |
| Fixtures + shared JSON | L4a (contract fixtures) | IMPLEMENTED_AND_VERIFIED in tree | `fixtures.rs:13-95`, `fixtures/shared-application.json:1-148`; tests `lib.rs:1135-1161` |
| `xylem-web` `render_ui_document` + `runtime.js` | L4b web adapter + L7 build tool | IMPLEMENTED_BUT_LIMITED | `xylem-web/src/ui.rs:28-54, 113-254`; compiler pins gate tests (`CRATE_STATUS.md:18`); placement per `D-001:122` |
| `xylem-desktop` `render_ui_document` | L4b adapter over L3 X11 host | IMPLEMENTED_BUT_LIMITED | `xylem-desktop/src/ui.rs:16-24, 111-169`; `CRATE_STATUS.md:16`; `D-001:123` |
| Graphics / wgpu | L3 substrate + L4b `Canvas` adapter | IMPLEMENTED_BUT_LIMITED | `WORKLOG.md:1353-1355`; `D-001:125, 139` |
| Capability/lifecycle | L4a | IMPLEMENTED_AND_VERIFIED in tree | `lib.rs:110-148, 280-354`; tests `lib.rs:1135-1210` |
| WL-57..WL-62 | — | complete per work log, not independently verified | `xylem-lang/docs/development/WORKLOG.md:1339-1356`; WL-63..67 blocked at `:1358` |

**Enumerated L4a contract** (`lib.rs`): elements `Column, Row, Button,
TextInput, Canvas` (`:751-759`); nodes `Text, Fragment, Conditional, Collection`
(`:356-364`); events `Click, Input, Submit, Change, KeyDown` (`:847-854`);
layout `direction/spacing/padding/align/width/height` (`:868-917`;
`Horizontal|Vertical`, `Start/Center/End/Stretch`, `Auto|Points(f32)`); roles
`Generic, Button, TextInput, Text, Group` (`:958-966`); accessibility
label/description/focusable/value (`:925-932`); diagnostics `UI-001..UI-011`
(`:449-575`, `:151-187`, `:490-511`).

**Gaps that cannot map to native widgets as-is:** five element kinds and five
roles only — no first-class list/label/checkbox/scroll/menu/dialog; `Text` emits
no role (`lib.rs:591`, `:577-607`); four of five events are demoted to opaque
`data-xylem-events` metadata by the web adapter (`xylem-web/src/ui.rs:188-196,
210-215`) while the native adapter merely copies them
(`xylem-desktop/src/ui.rs:155-168`); `Points(f32)` has no cross-platform unit and
style tokens are unresolved names; `accessibility_tree()` collects templates and
both branches rather than mounted nodes (`lib.rs:597-605`); `negotiate()` is
application-level only (`lib.rs:133-148`), so unmappable elements can be
lowered silently; no versioned rendering port identity exists yet.

## 2. Products studied, traps, and comparison

| Product / source | Architecture | Documented trap or limit |
|---|---|---|
| Ports/adapters — [AWS hexagonal](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html), [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), layered architecture (URL cited at `D-001:13-15`) | Ports are technology-agnostic entry points; adapters translate; source dependencies point inward, control flow may oppose them | Port must belong to the core, not be mirrored in the adapter; extra adapter layers have documented maintenance/latency costs — port count must stay minimal |
| Flutter — [overview](https://docs.flutter.dev/resources/architectural-overview), [inside](https://docs.flutter.dev/resources/inside-flutter), [constraints](https://docs.flutter.dev/ui/layout/constraints), [FAQ](https://docs.flutter.dev/resources/faq) | Immutable widgets → persistent element tree → render objects; one-pass box constraints; own renderer, not platform widgets | Platform views need texture copy, hit-test and accessibility bridging with "a certain amount of overhead" and documented broken accessibility/jank ([platform views](https://docs.flutter.dev/platform-integration/android/platform-views)) |
| React Native Fabric — [Fabric](https://reactnative.dev/architecture/fabric-renderer), [pipeline](https://reactnative.dev/architecture/render-pipeline), [New Architecture](https://reactnative.dev/architecture/landing-page) | JS tree → C++ shadow tree → Yoga → diff → atomic host-view mounts; JSI replaces JSON bridge | Legacy async layout caused visible "layout jump"; text sizing must call into host; enabling the new arch alone is not a win |
| Compose Multiplatform — [README](https://raw.githubusercontent.com/JetBrains/compose-multiplatform/master/README.md), [expect/actual](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-expect-actual.html), [resources](https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-resource-environment.html) | Shared declarative UI; per-target actuals; native iOS views; web Beta | Shared source ≠ shared semantics; locale/theme need `expect`/`actual`; Compose HTML is Kotlin/JS-only |
| AccessKit — [README](https://github.com/AccessKit/accesskit), [ARCHITECTURE](https://raw.githubusercontent.com/AccessKit/accesskit/main/ARCHITECTURE.md), [site](https://accesskit.dev/), [AT-SPI2](https://www.freedesktop.org/wiki/Accessibility/AT-SPI2/) | Schema tree + integer IDs + roles/actions; full tree then `TreeUpdate` deltas; platform adapters | Adapters are best-effort, web adapter only planned; shared schema does not guarantee parity |
| WebView stacks — [Cordova](https://cordova.apache.org/docs/en/latest/guide/overview), [Android WebView](https://developer.android.com/develop/ui/views/layout/webapps/webview), [WebView CG](https://webview-cg.github.io/usage-and-challenges) | HTML/CSS/JS in a native wrapper | "Behavioral inconsistencies across different WebViews"; higher baseline memory than standard views; leaks unless `destroy()` is called |
| CSS layout — [MDN Flexbox](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Flexbox), [box alignment](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Flexible_box_layout/Relationship_with_other_layout_methods) | 1D flex + 2D grid + box model | Auto-sizing/writing modes have no `UiLayout` equivalent; naive flex→native mapping over-promises |

No performance numbers are asserted; graphics figures in the work log belong
to the protected campaign and are not UI evidence.

## 3. Options and recommendation

- **A — Webview/CSS everywhere (rejected):** documented WebView inconsistency,
  memory/leak costs; violates native-component policy.
- **B — Own renderer everywhere (rejected):** documented platform-view bridge
  costs; violates native-widget policy.
- **C — L4a policy core + L4b adapters behind an L4a-owned port (RECOMMENDED).**
  The v1 design put adapters at L3 and made them render L4 — an upward source
  dependency (`D-001:7-11`). v2 fixes it by moving concrete rendering to L4b and
  keeping the port in L4a (`D-001:24-26, 72-83`). Tradeoff: per-target adapters
  and acceptance tests must be built; pixel identity is not a goal.

## 4. Component taxonomy and L4b native mapping table

Minimal shared L4a set: `container` (Column/Row), `text`, `button`, `input`,
`list`/`collection` (structural), `conditional` (structural), `canvas`
(embedded surface); `Fragment` is transparent. Every cell below is an **L4b**
implementation of the L4a port; L4a itself names none of these widget types.

| L4a component | L4b web DOM | L4b GTK4 | L4b AppKit | L4b WinUI | L4b iOS | L4b Android |
|---|---|---|---|---|---|---|
| container Column/Row | `div` + flex (`ui.rs:269-275, 322-341`) | `GtkBox` + orientation/spacing ([GTK](https://docs.gtk.org/gtk4/class.Box.html)) | `NSStackView` — **PENDING** | `StackPanel` ([MS](https://learn.microsoft.com/en-us/uwp/api/windows.ui.xaml.controls.stackpanel?view=winrt-26100)) | `UIStackView` — **PENDING** | `LinearLayout` ([Android](https://developer.android.com/reference/android/widget/LinearLayout)) |
| text (`UiNode::Text`) | text node / `<span>` (`ui.rs:59, 93-97`) | `GtkLabel` — PENDING | `NSTextField` — PENDING | `TextBlock` — PENDING | `UILabel` — PENDING | `TextView` — PENDING |
| button | `<button type="button">` (`ui.rs:140-144`) | `GtkButton` — PENDING | `NSButton` — PENDING | `Button` — PENDING | `UIButton` — PENDING | `Button` — PENDING |
| input | `<input>` + `data-xylem-bind` (`ui.rs:181-183`) | `GtkEntry` — PENDING | `NSTextField` — PENDING | `TextBox` — PENDING | `UITextField` — PENDING | `EditText` — PENDING |
| collection/list | `data-xylem-each/-item/-key` (`ui.rs:79-86`; `runtime.js:534-560, 686-738`) | `GtkListBox` keyed rows — PENDING | `NSTableView` — PENDING | `ListView` — PENDING | `UITableView` diffable — PENDING | `RecyclerView` — PENDING |
| conditional | `data-xylem-if` + placeholder (`ui.rs:65-78`; `runtime.js:516-533, 651-675`) | structural include/remove — PENDING | structural — PENDING | structural — PENDING | structural — PENDING | structural — PENDING |
| canvas | `<canvas>` + `data-xylem-scene` (`ui.rs:217-221`) | **UNSUPPORTED** in L4b; X11 software paint only (`WORKLOG.md:1353`) | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED |
| accessibility | `role`/`aria-*` (`ui.rs:125-139`) | AT-SPI via AccessKit | NSAccessibility via AccessKit | UIA via AccessKit | UIAccessibility via AccessKit | Android a11y via AccessKit |

PENDING = adapter and screen-reader acceptance test absent today
(`CRATE_STATUS.md:13-19`, `WORKLOG.md:1349-1358`). Canvas is an L4b adapter over
the L3 substrate, never a replacement for native widgets (`D-001:139`).

## 5. Data, binding, ownership, and lifetime

`UiBinding { path }` (`lib.rs:823-833`) names a checked state field, not a value:
the L4a document is a static policy contract. The web L4b adapter already
behaves like fine-grained reactivity: pre-indexed sites (`runtime.js:21-36,
491-560`), changed-field computation (`:237-247`), one coalesced microtask flush
(`:892-918`), updates only dirty sites (`:857-890`). Solid documents the same
model: no virtual DOM, components run once, "updates the exact parts of the page
that read the values you changed" ([Solid](https://docs.solidjs.com/),
[components](https://docs.solidjs.com/concepts/components-and-jsx/),
[about](https://www.solidjs.com/about/)).

**Ownership per D-001 v2 §7 (`D-001:95-105`):** L4a owns the document; L4b owns
widget handles and its site→handle map; L3 owns event-loop/surface state; L5 owns
application/session state; L6 owns business data. No global mutable registry.
L4a provides document-level binding-site descriptors; L4b materializes them into
handles. A dirty-field set is passed down through the port; callbacks cross
upward only as explicit subscriptions with numeric ids/borrowed snapshots, never
as closures capturing upper-layer owned data (`D-001:85-94`). No document clone
on update.

## 6. Capability negotiation and graceful degradation

L4a owns `UiApplication::negotiate` (`lib.rs:133-148`), the capability enum
(`:216-227`) and `UiDiagnostic` (`:995-1000`); L2 supplies typed capability and
diagnostic contracts; L3 advertises readiness/surface/input through its own
port; L4b consumes the negotiation result before touching widgets. If
`is_supported()` is false (`lib.rs:274-278`), do not mount. SPECIFIED_NOT_IMPLEMENTED
element-level checks: add new codes `UI-012` unsupported kind, `UI-013`
unsupported event, `UI-014` unsupported role, `UI-015` unsupported dimension/
token, `UI-016` no accessibility backend, `UI-017` canvas surface unavailable.
Degradation is a labelled fallback plus a diagnostic in the same deterministic
channel — never fabricated support or a silent drop (`D-001:107-115`).

## 7. API sketch — the L4a-owned port (signatures only)

```rust
// Identity/version lives with the port owner (L4a), not in adapter crates.
const UI_RENDERING_PORT: &str = "xylem-ui/rendering/1";

trait UiRenderingPort {                         // defined in L4a
    fn negotiate(app: &UiApplication, caps: &UiPlatformCapabilities) -> UiNegotiation;
    fn validate(app: &UiApplication, caps: &UiPlatformCapabilities) -> Vec<UiDiagnostic>;
    fn lower(document: &UiDocument) -> Result<RenderPlan, UiDiagnostic>;
    fn apply_dirty(plan: &mut RenderPlan, dirty: &BTreeSet<String>, fields: &dyn StateFieldReader);
    fn accessibility_delta(previous: &UiAccessibility, next: &UiAccessibility) -> AccessibilityUpdate;
}
// L4b: `impl UiRenderingPort for WebAdapter / GtkAdapter / ...` — no mirrored trait.
// L3: its own readiness/input/surface port (owned by L3, out of this document).
fn subscribe_input(source: &L3InputPort, adapter: SiteHandle) -> SubscriptionId;
```
`RenderPlan` is a borrowed/arena-backed view; `StateFieldReader` is an L2
boundary trait. No DOM/WASM/widget type appears in an L4a signature.

## 8. Performance budget, anti-patterns, v2 matrix and rule check

**Budget:** one validation + one lowering pass per change; one site prepass at
mount; one dirty flush per batch; zero document clones on update. Timings are
**PENDING_VERIFICATION** — no numbers asserted.

**Anti-pattern checklist** (D-001 v2 §7 and the compiler campaign's documented
representation problems in `xylem-lang/AGENTS.md`):
- [ ] No per-node boxing in hot paths: `UiNode::Element(Box<UiElement>)`,
  conditional/collection `Box<UiNode>` (`lib.rs:358-364, 785-800`) → arena handles.
- [ ] No repeated whole-tree scans: `validate()` (`:43-49`), `node_count()`
  (`:420-447`), `collect_accessibility()` (`:577-607`), `write_debug()`
  (`:609-677`), both adapters (`xylem-web/src/ui.rs:51`,
  `xylem-desktop/src/ui.rs:121`) → fuse validate/lower/layout.
- [ ] No diagnostic path allocation per node (`format!` at `lib.rs:531-532,
  536-537, 550-552`) — build lazily.
- [ ] No clone churn: native adapter clones every field (`xylem-desktop/src/ui.rs:155-168`).
- [ ] No opaque helper calls/hidden globals; the site→handle map is the only
  adapter-owned mutable state.
- [ ] No canvas as a native-widget replacement; no sibling-adapter imports.

**Source-dependency matrix (target, per `D-001:58-70`)**: L3→L4a **no**;
L4a→L3 **no**; L4b→L4a yes / L3 yes / L2 yes / sibling L4b no; L5→L4a yes /
L4b no; L6→L4a yes / L3 no; L7 consumes all published interfaces but is not a
runtime dependency.

| v2 rule (source) | Today | Target |
|---|---|---|
| Source deps downward; L3 no L4a (`D-001:18-22, 63, 77`) | FAIL — v1 placed adapters at L3; no port | PASS with L4b placement + port |
| Port owned by L4a, not mirrored (`D-001:20-22, 74-83`) | FAIL — two `render_ui_document` fns, no port identity | PASS (`UI_RENDERING_PORT`) |
| Runtime control may oppose source deps (`D-001:85-94`) | PARTIAL — web subscriptions exist, L4a not involved | PASS via explicit numeric subscription |
| Ownership/lifetime, no global registry (`D-001:95-103`) | FAIL — boxing/clones | PASS per §5 |
| Single-pass validate/index/layout (`D-001:104-105`) | FAIL — multiple scans | PASS per §8 budget |
| Typed failure, honest diagnostics (`D-001:107-115`) | PARTIAL — app-level only | PASS with `UI-012..017` |
| Native widgets, canvas bounded (`D-001:53, 139`) | PARTIAL — web + X11 only | PASS per target fixture |
| Per-layer gates (`D-001:46-56`); enforcement not shipped (`:130-133`) | PARTIAL — L4a unit tests; L4b gated | PASS with §9 gates |
| L7 plane (`D-001:40-41, 56`) | PASS by design | PASS |

## 9. Interface requests, out of scope, phases, self-critique

**Protected-team requests (none blocking L4a):** a stable, versioned Phase C
state-layout descriptor (field names/kinds) and per-field change notification —
the web build currently validates binding paths against that layout
(`WORKLOG.md:1344`); confirmation that typed string/array reads are stable
across backends. File as interface requests; do not edit L0/L1. Port version
identity format remains an open question in D-001 v2 (`D-001:142-145`). All
adapters, site maps and diagnostics stay in L4a/L4b.

**Out of scope:** HTML parser/DOM in L4a, CSS cascade, general expressions,
rich text, animation, menus/dialogs, pixel identity, hydration, mobile/macOS/
Windows releases (WL-63..67), and performance certification.

**Phases / verification gates** (all SPECIFIED_NOT_IMPLEMENTED; no CI/deploy):
1. Define/version the L4a port + element-level diagnostics; gate: invariant and
   `UI-012..017` tests run without any L4b/L3 code (`D-001:52` gate).
2. Arena-backed storage + fused validate/lower/layout; gate: unchanged
   `debug_tree()`/`accessibility_tree()` snapshots for both fixtures.
3. L4b adapters implementing the port (web, GTK, AppKit, WinUI, iOS, Android);
   gate: shared fixture on each target with native-widget identity and AT-SPI /
   UIA / VoiceOver / TalkBack checks; SDK-less targets stay PENDING
   (`D-001:53` gate).
4. Dirty-field site map parity; gate: identical binding results from web `runtime.js`
   and a native adapter for the same dirty set; no document rebuild.
5. Accessibility deltas via AccessKit; gate: mounted-tree (not template) nodes
   in the adapter tree.

**Self-critique (one pass).** The previous revision treated adapters as L3
consumers of an L4 document — exactly the inversion D-001 v2 identifies
(`D-001:7-11`). Weakest assumption then: that an L3 adapter could consume L4
without defining a port. Contrary primary evidence: AWS states ports belong to
the application core and adapters translate to them; Clean Architecture states
source deps point inward while control flow may oppose them. **Revision made:**
this document is now the canonical L4a policy core; it owns and versions the
rendering port (§7); every concrete widget mapping moved to L4b (§4); L3 is
explicitly forbidden to depend on L4a; the matrix and rule-check use v2 §§3–8.
The absent `ecosystem-readiness/docs/decisions/D-004-product-surface.md` remains recorded, not invented.

## 10. Open questions and sources

Open: who resolves theme tokens (L4b theme or L4a policy)? Is `UiValue::Float`
safe across protected backends? Which native container expresses
`UiAlign::Stretch` on iOS/Android? Should `UiNode::Text` carry a `Text` role?
Exact port identity format and SSR serialization port remain owner questions.

**Local sources:** `docs/decisions/D-001-platform-layering.md` (v2) :15-22,
:28-42, :46-70, :72-115, :116-145; `DESIGN/README.md`;
`work_logs/archive/phase-02-integration-status.md:74-83`;
`xylem-platform/crates/xylem-ui/src/lib.rs`, `src/fixtures.rs`,
`fixtures/shared-application.json`; `xylem-platform/crates/xylem-web/src/ui.rs`,
`src/runtime.js`; `xylem-platform/crates/xylem-desktop/src/ui.rs`;
`ecosystem-worktrees/xylem-platform/docs/CRATE_STATUS.md`;
`xylem-lang/docs/development/WORKLOG.md:1339-1359`; `xylem-lang/AGENTS.md`.

**Web sources (live search/fetch):** https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html ; https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html ; https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff650258(v=pandp.10) ; https://docs.flutter.dev/resources/architectural-overview ; https://docs.flutter.dev/resources/inside-flutter ; https://docs.flutter.dev/ui/layout/constraints ; https://docs.flutter.dev/resources/faq ; https://docs.flutter.dev/platform-integration/android/platform-views ; https://reactnative.dev/architecture/fabric-renderer ; https://reactnative.dev/architecture/render-pipeline ; https://reactnative.dev/architecture/landing-page ; https://raw.githubusercontent.com/JetBrains/compose-multiplatform/master/README.md ; https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-expect-actual.html ; https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-resource-environment.html ; https://github.com/AccessKit/accesskit ; https://raw.githubusercontent.com/AccessKit/accesskit/main/ARCHITECTURE.md ; https://accesskit.dev/ ; https://www.freedesktop.org/wiki/Accessibility/AT-SPI2/ ; https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Flexbox ; https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Flexible_box_layout/Relationship_with_other_layout_methods ; https://docs.solidjs.com/ ; https://docs.solidjs.com/concepts/components-and-jsx/ ; https://www.solidjs.com/about/ ; https://cordova.apache.org/docs/en/latest/guide/overview ; https://developer.android.com/develop/ui/views/layout/webapps/webview ; https://webview-cg.github.io/usage-and-challenges ; https://docs.gtk.org/gtk4/class.Box.html ; https://learn.microsoft.com/en-us/uwp/api/windows.ui.xaml.controls.stackpanel?view=winrt-26100 ; https://developer.android.com/reference/android/widget/LinearLayout .
