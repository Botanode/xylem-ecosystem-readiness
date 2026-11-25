---
doc_id: WEB-FRAMEWORK-001
product: xylem-web-framework
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
owner: D-WEB
revised_by: D-AURELIA
primary_layer: L5
layer_contract: docs/decisions/D-001-platform-layering.md (ACCEPTED v2, 2026-11-25)
---

# `xylem-web-framework` — design research (design only)

No code, build, benchmark, push or CI action originates here. External claims were fetched 2026-11-25 from official/GitHub primary sources; local claims are `file:line`; Xylem performance figures are `PENDING_VERIFICATION`. This revision follows D-001 **v2**, which split L4 into policy core **L4a** and adapters **L4b** and fixed the v1 L3→L4 inversion (`D-001:1-5,18-26`; `D-001` = `docs/decisions/D-001-platform-layering.md`).

## 1. Scope, status and layer placement (D-001 v2; L5)

`xylem-web-framework` is **L5**. It consumes L4a's UI/rendering port, L3 substrate events and L2 web effects; it does **not** consume L4b adapters directly (`D-001:46-56,58-70,116-127`).

| Direction | Layer / interface | Evidence |
|---|---|---|
| downward | **L4a** policy core: `UiDocument`, `UiBinding`, `UiHandler`, `UiEventKind`, `validate()`, `accessibility_tree()`, rendering port, capability negotiation | `D-001:52,72-83`; `xylem-ui/src/lib.rs:21-28,43-67,123-145` |
| downward | **L3** substrate: event loop, surface, input, timers; input flows *up* only via L4b/L5 subscriptions; L3 must not depend on L4a | `D-001:51,63,85-94` |
| downward | **L2** capability imports + typed diagnostics | `D-001:50`; `cross-target-capabilities.md:50,58` |
| downward | **L1** value model via `StateLayout`/`MemKind` (read-only, protected) | `xylem-wasm/src/lib.rs:1361-1402`; `D-001:48-49` |
| L4b (not a dependency) | `xylem-web` builder + `runtime.js` implement the L4a web port and are L7 build tooling; L5 authors to the port, not DOM code | `D-001:53,65-66,122` |

No upward **source** or sideways dependency is proposed. Runtime data may flow upward (L3 input → L4b → L4a document → L5 state) via subscriptions the upper layer establishes; lower layers store no upper-layer state (`D-001:85-94`). **Status: `IMPLEMENTED_BUT_LIMITED`** for primitives/builder; proposals are `SPECIFIED_NOT_IMPLEMENTED`.

### 1.1 D-002 plugin-boundary map

| Core / port (not a plugin) | Plugin(s) | Evidence |
|---|---|---|
| L4a document, rendering port, capability registry | L4b web adapter (`xylem-web`/`runtime.js`), GTK/AppKit/WinUI/mobile, Canvas | `D-002:15-23`; `D-001:52-54,72-83` |
| L3 readiness/input/surface port | L3 host plugins | `D-002:25-29`; `D-001:51` |
| L2 capability interface | web storage/network imports | `D-002:25-33`; `D-001:50` |
| L5 authoring interfaces | routing, form/state helpers, loaders, component library | `D-002:29-30` |
| L7 commands/diagnostics | CLI, LSP, lint/conformance packs | `D-002:31-32` |

Plugins use compile-time registration, versioned identity, typed interfaces, explicit lifecycle and `UiDiagnostic`; no reflection, global state or sideways calls (`D-002:46-65`).

### 1.2 D-003 conformance mapping

| D-003 contract | Where satisfied |
|---|---|
| Design record: layer, downward deps, plugin map, ownership, out-of-scope | §1, §1.1, §5.3, §5.4 |
| Architecture: no upward/sideways source dep, one UI model, versioned ports | §1; §5.1; §8 |
| Coding practice: explicit ownership/effects, single-pass, deterministic | §5.3, §6, §7 |
| Verification gates: focused fixtures, pinned identity, no perf claims | §9; all budgets `PENDING_VERIFICATION` |
| Documentation: one design record, no status docs | `D-003:14-29,44-56` |

`xylem lint` enforces only style codes `W7001`–`W7004`; architecture enforcement is an unshipped L7 item (`D-003:31-42`; `D-001:130-134`).

## 2. Current Xylem assets and exact gaps

**Assets.** Xylem source: `stdlib/src/std/web/{dom,forms,http,navigation,storage}.xy`; `html.xy`/`url.xy` are pure text helpers now merged into the
`integration/ecosystem-readiness` branch and pushed to GitHub, **not** a
DOM/HTML parser (`ecosystem-worktrees/xylem-lang/stdlib/src/std/web/html.xy:1-10`;
`.../url.xy:1-13`). Note: the pinned compiler's compiled-in stdlib inventory
does not yet list them, so canonical `std/web/url` imports fail (handover
`XY-002`); the example imports them by relative path. `url.xy` handles percent-encoding (`:97-121,138-213,215-252`); `navigation.xy` has pure `path_of`/`query_value`/`route_matches` (`:48-87,110-138`); `forms.xy` holds validators (`xylem-lang/stdlib/src/std/web/forms.xy:2-14`). `xylem-platform/crates/xylem-web` emits `data-xylem-*` (`ui.rs:28,176-192`). Browser evidence WL-40/WL-57–WL-62 (`WORKLOG.md:1200,1339-1350`); web capability `IMPLEMENTED_BUT_LIMITED` (`cross-target-capabilities.md:58`). ABI v2: `xylem_web_init`, typed handler/hook exports, version export (`xylem-wasm/src/lib.rs:23,1257-1259,209-221`); `StateLayout`/`MemKind` exist (`:1361-1402`).

**Gaps.** `runtime.js` re-snapshots state each render (`:208-247,857-890`), publishes all state to `data-xylem-state` (`:841-855`), and whole-field diffs on unknown write sets (`xylem-wasm/src/lib.rs:1411-1425`; `runtime.js:244,1194`). No Xylem-source declarative API emitting `UiDocument`; no versioned identity for L4a/L4b/L2; SSR/hydration, guards, lazy loading, animation and component-private state out of scope (`cross-target-capabilities.md:58`). Naming authority: `ecosystem-readiness/docs/decisions/README.md:17-20,36-47,92-98`.

## 3. Products studied — rendering models and documented costs

| Product (primary source) | Model | Documented cost | Xylem takeaway |
|---|---|---|---|
| React `hydrateRoot` — https://react.dev/reference/react-dom/client/hydrateRoot | VDOM + hydration | Mismatches are bugs; validating all markup "prohibitively expensive"; early `root.render` clears server HTML | No hydration v1; deterministic L4a structure if SSR added |
| Next.js App Router — https://nextjs.org/docs/app/getting-started/server-and-client-components | RSC + hydration | HTML non-interactive; `"use client"` pulls all imports into client bundle; props serialisable | Small payload, serialisable state, no module-graph explosion |
| Svelte — https://svelte.dev/blog/virtual-dom-is-pure-overhead ; https://svelte.dev/blog/svelte-3-rethinking-reactivity | Compile-time DOM writes | "Diffing isn't free"; VDOM work is *in addition to* DOM work | Direct DOM writes; no per-render node allocation |
| Solid — https://docs.solidjs.com/concepts/reactivity | Signals, run-once components | Untracked reads never update; module-scope state leaks across requests | Static deps, explicit ownership/disposal |
| Leptos — https://book.leptos.dev/ssr/24_hydration_bugs.html | Rust fine-grained + SSR | Runs twice at startup; invalid HTML/`<tbody>` breaks hydration | One render authority; no HTML reparser |
| Dioxus — https://dioxuslabs.com/learn/0.6/getting_started | RSX, per-target adapters | `dx` tool + WebView/WebKitGTK deps | Shared authoring, per-target adapters (L4a/L4b); SSR out of scope |
| Yew — https://yew.rs/docs/concepts/html | `html!` + VDOM | `ref`/`key` are VDOM instructions | No VDOM nodes in WASM memory |
| htmx — https://htmx.org/docs/ | HTML fragment swaps | No build system; morph keeps focus/video "at the cost of more CPU" | Future L5 option, not a v1 claim |
| WASM facts — https://rustwasm.github.io/book/reference/js-ffi.html ; https://webassembly.org/docs/faq/ | Numeric-only boundary | No JS object access; FAQ: binary decode >20× faster than JS parse | Size/startup as fields, not claims; allocation-free hot paths |

**Traps avoided:** VDOM alloc/diff, hydration mismatch/double work, module-graph bloat, opaque handles, boxed-`AValue`/O(n²) failures (`PERFORMANCE_GUARDRAILS.md:50-63`; wasm-bindgen docs, §5.2).

### 3.1 Aurelia 2 study (primary sources)

| Aurelia feature | How it works | Source URL | Xylem analogue | Gap |
|---|---|---|---|---|
| Philosophy: standards-based, minimal intrusion | Enhance HTML/CSS/JS; "just write your code"; cohesive router+DI+binding+testing | https://docs.aurelia.io/introduction/the-aurelia-philosophy ; https://github.com/aurelia/aurelia | L5 authors in Xylem; output is L4a `UiDocument`, not JS/DOM | Typed compiled language + numeric ABI; "familiar" = semantics, not browser APIs |
| Convention over configuration | `user-profile.ts`+`.html` → `<user-profile>`; `propertyChanged`; `@customElement` escape hatch | https://docs.aurelia.io/introduction/the-aurelia-philosophy | `view`/`state`/handler names resolved at L5→L4a compile step (§4.1) | No file pairs/HTML templates; compile-time checks replace runtime config |
| Templates / interpolation | `${user.name}`, `if.bind`, `show.bind`, `repeat.for`; HTML + binding attributes | https://docs.aurelia.io/templates/overview ; https://docs.aurelia.io/templates/cheat_sheet | `UiConditional`/`UiCollection`/`UiBinding` → `data-xylem-if`/`each`/`text` (`xylem-ui/src/lib.rs:788-824`; `runtime.js:516-560`) | Backend-neutral L4a, not HTML; no attribute patterns/converters |
| Two-way binding | `.bind` two-way for inputs, to-view otherwise; `.two-way`/`.to-view`/`.from-view`/`.one-time` | https://docs.aurelia.io/templates/overview/attribute-binding | `data-xylem-bind` + `Input`/`Submit` handlers over contiguous state (`runtime.js:155-168,1144-1198`) | Direction is a closed write set, not a runtime mode; no property/attribute split |
| Components / custom elements | Class + optional HTML template; `@customElement`, `@bindable`, slots, `<import>` vs global | https://docs.aurelia.io/introduction/essentials/components | L4a `UiNode`/`UiElement` tree; L5 component = fn returning L4a nodes (§6) | No private state, Shadow DOM or slots today; fragments, not DOM hosts |
| DI / service registry | `resolve()` over decorators; `DI.createContainer`; singleton/transient/alias; `lazy`/`all`/`optional` | https://docs.aurelia.io/introduction/essentials/dependency-injection ; https://docs.aurelia.io/getting-to-know-aurelia/services-and-runtime-hooks/dependency-injection/resolvers | D-002 versioned compile-time registries + L5 service interfaces | No runtime container/`resolve()`; wiring checked at compile time |
| Observability / reactivity | Plain properties auto-observed; `@observable` + `propertyChanged`; `@computed`; `effect`; `batch()` | https://docs.aurelia.io/introduction/essentials/reactivity ; https://docs.aurelia.io/getting-to-know-aurelia/state-and-observation/synchronous-binding-system | Closed write sets + one microtask flush (`xylem-wasm/src/lib.rs:1411-1425`; `runtime.js:892-918`) | No Proxy/track-on-read; deps explicit; declared writes avoid tearing |
| Lifecycle hooks | `created`, `binding`, `bound`, `attaching`, `attached`, `detaching`, `unbinding`, `dispose`; async awaited | https://docs.aurelia.io/components/component-lifecycles | `xylem_web_hook_<name>` via `callHook`, `writes` metadata (`lib.rs:1259,1416-1426`; `runtime.js:1016-1039`) | Numeric exports, not Promise-returning methods; no DOM-attached phase |
| Router | `@route`/`static routes`; `:id`/`:id?`/`*`; regex; `canLoad`/`loading`/`loaded`/`canUnload`/`unloading` | https://docs.aurelia.io/getting-to-know-aurelia/aurelia-router/fundamentals/configuring-routes ; https://docs.aurelia.io/getting-to-know-aurelia/aurelia-router/lifecycle-and-events/routing-lifecycle | L5 routing over pure-text `path_of`/`query_value`/`route_matches` (`navigation.xy:48-87,110-138`) | No History API or async guards; route table is compile-time data |
| Validation / forms | `@aurelia/validation` + `validation-html`; forms docs cover validation integration | https://docs.aurelia.io/templates/forms ; https://docs.aurelia.io/developer-guides/error-messages/4100-to-4106.md | `stdlib/src/std/web/forms.xy:2-14` validators; L5 form plugin (`D-002:29`) | No rule DSL, renderer or async rules; validators are functions with effects |
| Testing | DI makes mocking trivial; component and stub/mock/spy guides | https://docs.aurelia.io/developer-guides/overview/testing-components ; https://docs.aurelia.io/developer-guides/overview/mocks-spies | D-003 focused fixtures, pinned compiler; no runtime container to mock | No JS runner; substitution is compile-time, not a runtime spy |
| Build tooling / no-build | Vite/Webpack/Parcel guides; browser-no-build via module script + CDN | https://docs.aurelia.io/developer-guides/bundlers ; https://docs.aurelia.io/getting-started/browser-no-build | L7 emits WASM + `runtime.js`; no npm for authors (`D-001:40-41,56`) | No CDN no-build path |

Familiar JS semantics (first-party standards): modules/dependency graph — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules; classes — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_classes; Proxy caveat (identity and private-field/internal-slot forwarding can fail) — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy; decorators are a TC39 proposal, and Aurelia has non-decorator `resolve()`/`static inject` — https://tc39.es/proposal-decorators/ ; https://docs.aurelia.io/getting-to-know-aurelia/services-and-runtime-hooks/dependency-injection/dependency-injection-di.

## 4. Design options and recommendation

| Option | Fit with L4a | Cost profile (no Xylem numbers) | Verdict |
|---|---|---|---|
| A. VDOM in WASM + diff | Poor: VDOM nodes are not `UiNode`/`UiNodeId`; duplicates L4a | Per-node alloc + O(n) diff/GC (Svelte/Yew) | Reject |
| B. SSR + hydration | Needs server renderer + exact tree identity | Double execution + mismatch failures (React, Leptos) | Reject v1; future L5 SSR |
| C. Static L4a document + field-scoped DOM writes in **L4b**; WASM holds state/handlers | Excellent: L4a is the document; web is one adapter | Numeric-only; no per-node WASM objects; diff bounded by writes | **Recommended** |
| D. HTML-fragment swaps (htmx-style) | Neutral: fragments generated from L4a | No server HTML today; morph CPU cost acknowledged | Defer |

**Recommendation: Option C.** It alone preserves one L4a document across web/native, uses the existing numeric ABI (`xylem_web_init`, typed exports, `StateLayout`), and follows Svelte/Solid evidence that updates target changed fields. It is an **L4a-port adapter**, not a new component model or an L3 responsibility (`D-001:53,72-83`).

### 4.1 The "plain-JS feel" contract

| Must feel familiar | Xylem decision | Evidence |
|---|---|---|
| Modules / imports | Xylem `import { ... } from "std/..."`; no global script scope | `url.xy:14`; MDN Modules (§3.1) |
| Functions / classes | `fn`/`pub fn` + ordinary structs; no framework base class | `url.xy:20-97`; MDN classes (§3.1) |
| Declarative templates | `view` returns an L4a `UiDocument`; no imperative DOM calls | §6; `xylem-ui/src/lib.rs:25-28` |
| Two-way binding | Declared field path binds an input to contiguous state; direction is a closed write set | `runtime.js:155-168,1144-1198` |
| Convention over configuration | `view`/`state`/handler names resolved at L5→L4a compile time; deviation is explicit, not a config file | Aurelia philosophy (§3.1); `D-002:46-49` |
| DI / service registry | Named, versioned interfaces registered at compile time; no reflection/`resolve()` | `D-002:34-45,46-65` |
| Routing | Declarative route table + named hooks; pure-text primitives exist | `navigation.xy:48-87,110-138` |
| Lifecycle hooks | Named handlers/hooks with explicit effects, not base-class overrides | `lib.rs:1257-1259,1411-1425` |

**Must differ (non-negotiable).** (1) **Static types/effects** are visible (`effects [allocation]`, `url.xy:97,138,215`); no untyped JS objects. (2) **Ownership**: one contiguous struct behind an `i32` pointer; no hidden global state (`lib.rs:1391-1402`; `D-001:95-105`). (3) **L4a shared document, not DOM-only**: DOM is L4b (`D-001:52-54`). (4) **No VDOM**: L4b writes changed fields (§3). (5) **Numeric WASM ABI** (§5.2). (6) **No npm/JS runtime or CDN no-build path**: L7 emits WASM + `runtime.js` (`D-001:40-41,56`).

### 4.2 What makes it unique (not an Aurelia port)

1. **Shared-document-first authoring** — L5 emits an L4a `UiDocument`; no HTML template or DOM-host class (`lib.rs:25-28,43-67`).
2. **Effect-typed handlers** — closed write sets; unknown writes force a diagnostic, never a full scan (`lib.rs:1411-1425`; `D-003:21-23`).
3. **Capability-negotiated components** — `UiApplication::negotiate` returns granted/missing sets + `UiDiagnostic`, not feature sniffing (`lib.rs:123-145,217-280`; `D-002:62-63`).
4. **Deterministic state layout** — `StateLayout`/`MemKind::{Scalar,Text,Array}` with contiguous aligned offsets replaces Proxy observation (`lib.rs:1361-1402,1477-1552`).
5. **Compile-time plugin registration** — wiring is static and versioned, never discovered at runtime (`D-002:46-65`).

No Aurelia internals (binding engine, DI container, template compiler, observer locator) are copied — only authoring ergonomics.

## 5. Data/model/lifetime design

### 5.1 L4a shared UI contract and the L4b web-adapter mapping

L5-authored UI produces an **`UiDocument` and nothing else**: `root`, `theme`, stable `UiNodeId`, `UiElement`/`UiText`/`UiFragment`/`UiConditional`/`UiCollection`, typed `UiValue`/`UiBinding`/`UiHandler`, layout/style/accessibility (`xylem-ui/src/lib.rs:21-28,682-696,751-759,773-845`). `validate()`/`accessibility_tree()` are the inspection gates (`:43-67`); no HTML parser, DOM object, CSS selector or JS value (`:1-5`).

| L4a construct | L4b `runtime.js` / DOM mechanism | Evidence |
|---|---|---|
| `UiBinding { path }` | `data-xylem-text`/`show`/`bind`/`attr`/`class`/`style`, via `fieldValue` against the state pointer | `ui.rs:176-189`; `runtime.js:155-168,319-371` |
| `UiHandler` + `UiEventKind` | `data-xylem-click` → `HANDLERS[name]` → `exports[handler.export](statePointer, ...)`; `Input`/`Submit` via `handleBinding`/`handleSubmit` | `runtime.js:1144-1198,1223-1233` |
| `UiConditional` | `data-xylem-if` + comment placeholder + cloned template | `runtime.js:516-533,651-675` |
| `UiCollection` | `data-xylem-each`/`key`; keyed `Map`, reverse-walk reorder | `runtime.js:534-560,640-738` |
| Hooks | `xylem_web_hook_<name>` via `callHook`, with `writes` metadata | `lib.rs:1259,1416-1426`; `runtime.js:1016-1039` |
| `UiElementKind::Canvas` | SVG scene inside the shared document, not a competing UI system | `xylem-ui/src/lib.rs:692-694` |
| Unmappable element/capability | `UiDiagnostic` + graceful degradation | `D-001:107-113`; `xylem-ui/src/lib.rs:43-49` |

The web adapter **implements the L4a port** and defines no second UI model (`D-001:72-83,138`). L3 provides event loop/input/timers and emits input events L4b/L5 **subscribe to**; L3 never depends on L4a (`D-001:51,63,85-94`). Web-only escape hatches live in **L4b** (`data-xylem-*`, `localStorage`/`fetch`/`history`, `data-xylem-state`; `runtime.js:13,841-855,1399-1450`); `env.xylem_web_storage` is an **L2** import. No web-only state model, widget unmappable to L4a, HTML parser or VDOM.

### 5.2 Numeric ABI (existing; consume, do not modify)

WASM/JS calls carry primitive numerics only — "these functions must operate only on primitive numeric types" (https://rustwasm.github.io/book/reference/js-ffi.html); JS reads linear memory via `DataView`, WASM has no direct JS-object access. `wasm-bindgen` generates heap indices (`JsValue` as `u32`) with `Drop` traffic (https://github.com/wasm-bindgen/wasm-bindgen/blob/main/guide/src/contributing/design/js-objects-in-rust.md). **Xylem needs none of this**: `i32` state pointer, numeric args (`runtime.js:66-87,1357-1359`). Exports `xylem_web_abi_version`, `xylem_web_init`, `xylem_web_handler_*`, `xylem_web_hook_*`, `memory` (`lib.rs:23,1257-1259,209-221`; `runtime.js:2-7,1350-1358`) are a boundary to **version**, not reimplement in L5.

### 5.3 State in linear memory

`StateLayout { type_name, size, align, fields }` with `MemField { offset, kind }` and `MemKind::{Scalar,Text{capacity},Array{length,stride,element}}` is authoritative (`lib.rs:1361-1402`); `field_layout` yields contiguous aligned offsets (`:1477-1552`). Keep one struct behind the `xylem_web_init` pointer; text is fixed-capacity length-prefixed (`runtime.js:148-153`), arrays stride-based (`:189-206`). No boxed nodes, JS-object handles or per-node refcount; dirty data is field names/offsets. Allocation/RC/helper counters are `PENDING_VERIFICATION` (`D-001:95-105`).

### 5.4 Explicitly out of scope

No VDOM, v1 hydration/SSR, HTML parser, JS-authored components, wasm-bindgen, component-private state, cross-origin requests/streaming/retry/IndexedDB, animation/graphics, native widget rendering here, benchmark/CI/deploy, or performance claim.

## 6. API sketch — signatures and behaviour only

```text
# L5 Xylem source: emits L4a, never DOM
fn view(state: &AppState) -> UiDocument
fn bind(path: &String) -> UiBinding
fn handler(name: &String) -> UiHandler
fn conditional(cond: UiBinding, then_node: UiNode, else_node: UiNode) -> UiConditional
fn collection(items: UiBinding, key: &String, row: UiNode) -> UiCollection
fn schedule_render(dirty: FieldSet) -> Unit

# L5 state: contiguous struct; layout from protected interface
struct AppState { /* scalar | text(capacity) | array(stride, element) */ }
fn state_layout(program: &IRProgram, state_type: &String) -> StateLayout   # existing, L0/L1

# L4a reference (not redefined)
UiDocument::validate(&self) -> Vec<UiDiagnostic>
UiDocument::accessibility_tree(&self) -> Vec<UiAccessibility>

# L4b web adapter (consume port)
render_ui_document(&UiDocument) -> Result<String, WebError>

# L2/L4b numeric boundary (consume)
xylem_web_abi_version: i32
xylem_web_init() -> i32                          # returns state pointer
xylem_web_handler_<name>(state: i32, arg: i32) -> Unit
xylem_web_hook_<name>(state: i32, args: i32...) -> Unit
env.xylem_web_storage(slot: i32, op: i32, value: i32) -> i32
```

Names are **proposed conventions**, not implemented Xylem syntax. `view` is pure/deterministic; bindings are field paths, not callbacks; handlers declare closed write sets; the adapter schedules at most one flush per change (`runtime.js:892-918`).

## 7. Performance budget and anti-pattern checklist

Budgets are `PENDING_VERIFICATION` (`PERFORMANCE_GUARDRAILS.md:115-137`): startup, update latency, payload size, allocations/update, RC/COW increments, helper calls/update. **No numbers asserted.**

| # | Anti-pattern | Guard | Evidence |
|---|---|---|---|
| 1 | Boxed per-node/per-value UI objects | Contiguous state; one `StateLayout` | `PERFORMANCE_GUARDRAILS.md:54`; `lib.rs:1361-1402` |
| 2 | Opaque per-node helper calls | Numeric ABI only; no JS-object heap/slab | `:55`; wasm-bindgen doc (§5.2) |
| 3 | Repeated whole-tree scans / re-parse | One `validate()` + one index pass; closed write sets | `:56,58`; `xylem-ui/src/lib.rs:43-49` |
| 4 | O(n²) diff / per-render allocation | Keyed rows + field scoping; `publishState` snapshots are canaries | `:59`; `runtime.js:677-679,841-855` |
| 5 | Refcount churn / hidden global state | No `JsValue`/`Drop` handles; one state pointer | `:57`; Solid (§3); wasm-bindgen doc |
| 6 | Hydration mismatch / double execution | No hydration in v1; deterministic L4a document | React; Leptos |
| 7 | Client payload bloat | Narrow interactive boundary; no VDOM runtime | Next.js; Rust/WASM code-size page |
| 8 | Proxy-as-result / invented numbers | Structural counters only; timing by protected campaign | `:61-62` |

**D-001 v2 rule check.**

| Requirement | Status | Evidence |
|---|---|---|
| Source deps downward; L3 never depends on L4a | PASS | §1; `D-001:58-70,85-94` |
| Port owned by L4a; L4b adapter implements it | PASS | §5.1; `D-001:72-83` |
| Explicit ownership, no boxed hot-path nodes, bounded RC/COW | PASS | §5.3; `D-001:95-105` |
| Single-pass validation/index/layout; typed diagnostics | PASS | `lib.rs:43-49`; `D-001:104-113` |
| L7 is a plane, not a runtime tier | PASS | §1; `D-001:40-41,56` |
| Per-layer gates, no perf claims | PASS | §9; `D-001:128-134` |
| Escalate, not modify protected L0/L1 | PASS | §8 only |

## 8. Interface requests to the protected compiler team

1. Publish a **versioned identity** for ABI v2, `StateLayout` and the **L4a rendering port** used by L4b/L7 (`D-001:113`; `lib.rs:23,1642-1653`).
2. Guarantee **closed write sets** for every handler/hook so the runtime never scans all fields (`lib.rs:1411-1425`; `runtime.js:244,1194`); else emit a diagnostic, not `None`.
3. Keep the boundary **numeric-only**: no JS-object handles or wasm-bindgen heap/slab (§5.2).
4. Provide exact **allocation/RC-COW/helper-call canaries** (no timing) to bound `publishState` snapshots (`runtime.js:677-679,841-855`).
5. Verify deterministic **trap/diagnostic equivalence** for handler/hook calls, interpreter vs WASM (`xylem-lang/AGENTS.md:37-54`).
6. Document the bounded text-record capacity/length contract as a stable L2 interface (`lib.rs:1521-1528`; `runtime.js:148-153`).

## 9. Phased milestones and verification gates (no CI/deploy triggers)

- **M0 — Evidence lock.** Re-read WL-40/WL-57–WL-62 and ABI identity; statuses `PENDING_INDEPENDENT_VERIFICATION`.
- **M1 — Authoring contract.** Xylem source → L4a `UiDocument` only; review `counter_fixture`/`form_fixture` (`WORKLOG.md:1342-1345`); no new UI model.
- **M2 — L4b mapping.** Complete §5.1 for every `UiElementKind`/`UiEventKind`; unmappable entries emit `UiDiagnostic`. No browser build.
- **M3 — Dirty sets.** Closed writes + one-flush scheduler; structural field-read canary, *no wall-time gain claimed*.
- **M4 — Layout stability.** Versioned `StateLayout`/`MemKind`; golden fixture, no allocation claims.
- **M5 — Deferred verification.** Protected campaign fills §7 and runs paired A/B; this campaign files §8 requests.

### 9.1 Self-critique pass (recorded changes)

**Weakest assumption:** "field-scoped direct DOM writes avoid all diff cost." htmx: morph swaps keep focus/video "at the cost of more CPU" (https://htmx.org/docs/); Solid: untracked reads leave stale state (https://docs.solidjs.com/concepts/reactivity); Leptos: hydration fails when source and parsed DOM diverge (https://book.leptos.dev/ssr/24_hydration_bugs.html). Locally `runtime.js:677-679` allocates a `JSON.stringify` snapshot per row and `:841-855` re-reads all state. **Revision:** no "no diffing" claim — only *bounded, keyed, field-scoped* diffing; `publishState`/row snapshots are canaries (§7, §8.4).

**Second revision:** an early instinct was WASM mutating the DOM via object handles. The Rust/WASM book states WASM has no direct JS-object access and only numerics cross the boundary; wasm-bindgen uses `u32` heap indices with `Drop` traffic. DOM mutation stays in L4b `runtime.js`; WASM holds state + numeric handlers.

**Third revision (Aurelia-clone critique).** It would be a mere clone if it copied the DI container, template compiler, `@observable`/`@computed` observation, binding grammar and router/lifecycle hooks onto WASM. It avoids that by (a) the **L4a document** as sole UI model — no DOM, templates or proxies (§4.2); (b) **effect-typed handlers** + deterministic `StateLayout` instead of runtime observation (§4.2); (c) **compile-time registration** instead of container `resolve()` (`D-002:46-65`); (d) conventions as compile-time name resolution, not runtime config (§4.1); (e) pure-text routing, not browser History (§3.1). Only authoring familiarity is borrowed.

## 10. Open questions and full source list

### 10.1 Open questions

- Will the protected side expose closed write sets for **all** handlers, or is a diagnostic fallback needed?
- Can `std/web/{html,url}.xy` be promoted from a worktree to pinned stdlib, and who owns it (L7/L2)?
- If SSR is introduced, which L5 service owns L4a→HTML and how is tree identity checked without hydration?
- Are WL-40/WL-57–WL-62 runs independently reproducible? Still `PENDING_INDEPENDENT_VERIFICATION`.
- What is the version identity format for the L4a port / L4b contract (`D-001:142-145`)?

### 10.2 Source list

**External (official/GitHub; fetched 2026-11-25):** https://docs.aurelia.io/introduction/the-aurelia-philosophy ; https://docs.aurelia.io/introduction/essentials/components ; https://docs.aurelia.io/introduction/essentials/dependency-injection ; https://docs.aurelia.io/introduction/essentials/reactivity ; https://docs.aurelia.io/templates/overview ; https://docs.aurelia.io/templates/cheat_sheet ; https://docs.aurelia.io/templates/overview/attribute-binding ; https://docs.aurelia.io/templates/forms ; https://docs.aurelia.io/components/component-lifecycles ; https://docs.aurelia.io/getting-to-know-aurelia/services-and-runtime-hooks/dependency-injection/resolvers ; https://docs.aurelia.io/getting-to-know-aurelia/services-and-runtime-hooks/dependency-injection/dependency-injection-di ; https://docs.aurelia.io/getting-to-know-aurelia/state-and-observation/synchronous-binding-system ; https://docs.aurelia.io/getting-to-know-aurelia/aurelia-router/fundamentals/configuring-routes ; https://docs.aurelia.io/getting-to-know-aurelia/aurelia-router/lifecycle-and-events/routing-lifecycle ; https://docs.aurelia.io/developer-guides/overview/testing-components ; https://docs.aurelia.io/developer-guides/overview/mocks-spies ; https://docs.aurelia.io/developer-guides/error-messages/4100-to-4106.md ; https://docs.aurelia.io/developer-guides/bundlers ; https://docs.aurelia.io/getting-started/browser-no-build ; https://docs.aurelia.io/llms.txt ; https://github.com/aurelia/aurelia ; https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules ; https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_classes ; https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy ; https://tc39.es/proposal-decorators/ ; https://react.dev/reference/react-dom/client/hydrateRoot ; https://nextjs.org/docs/app/getting-started/server-and-client-components ; https://svelte.dev/blog/virtual-dom-is-pure-overhead ; https://svelte.dev/blog/svelte-3-rethinking-reactivity ; https://docs.solidjs.com/concepts/reactivity ; https://book.leptos.dev/ssr/24_hydration_bugs.html ; https://dioxuslabs.com/learn/0.6/getting_started ; https://yew.rs/docs/concepts/html ; https://htmx.org/docs/ ; https://rustwasm.github.io/book/reference/js-ffi.html ; https://rustwasm.github.io/book/reference/code-size.html ; https://webassembly.org/docs/faq/ ; https://github.com/wasm-bindgen/wasm-bindgen/blob/main/guide/src/contributing/design/js-objects-in-rust.md ; https://github.com/wasm-bindgen/wasm-bindgen/blob/main/guide/src/contributing/design/rust-type-conversions.md .

**Local:** `docs/decisions/D-001-platform-layering.md:1-5,18-26,40-70,72-147` ; `docs/decisions/D-002-plugin-centric-platform.md:9-65` ; `docs/decisions/D-003-platform-app-conformance.md:14-56` ; `ecosystem-readiness/docs/decisions/README.md:17-20,36-47,92-98` ; `ecosystem-worktrees/xylem-lang/docs/tooling/cross-target-capabilities.md:50,58` ; `ecosystem-worktrees/xylem-lang/docs/development/WORKLOG.md:1200,1339-1350` ; `xylem-rust/crates/xylem-wasm/src/lib.rs:23,192-197,209-221,1257-1259,1361-1436,1477-1552,1642-1653,2086-2090` ; `xylem-platform/crates/xylem-web/src/runtime.js:2-7,66-87,148-168,189-247,516-560,640-738,841-918,1016-1039,1144-1198,1223-1328,1330-1450` ; `xylem-platform/crates/xylem-web/src/ui.rs:28,176-192` ; `xylem-platform/crates/xylem-ui/src/lib.rs:1-5,21-28,43-67,123-145,217-280,682-696,751-845` ; `ecosystem-worktrees/task-web-primitives/stdlib/src/std/web/html.xy:1-10` ; `.../url.xy:1-13,97-121,138-213,215-252` ; `.../navigation.xy:48-87,110-138` ; `ecosystem-worktrees/xylem-lang/stdlib/src/std/web/forms.xy:2-14` ; `ecosystem-readiness/DESIGN/PERFORMANCE_GUARDRAILS.md:12-35,50-63,115-137` ; `xylem-lang/AGENTS.md:37-54`.

## 11. Implementation status (2026-11-25)

The Aurelia-like authoring layer is implemented in Xylem source and verified with
the pinned compiler:

- `framework/web/{component,services,router,app}.xy` — binding modes, eight-phase
  lifecycle, static service registry, declarative router, app composition.
- `examples/web-framework-aurelia/` — `.xylem`/`.view` pairs (`counter`, `profile`),
  six lifecycle hooks, four binding attributes, static formatter plugin, two
  routes, L7 component checker and byte-exact fixtures.
- `framework/web/tools/emit_l4a.py` — `.view` → bare `UiDocument { root, theme }`
  for the existing `xylem web build --ui` path; 11 Python tests pass.
- `framework/web/tools/build_web.py` — validates pairs, emits the UiDocument and
  writes a build plan; it deliberately does NOT execute a browser build.

Verification actually run: framework `xylem test` 1 passed; web example
`xylem test` 1 passed; component checker PASS plus five typed negative fixtures;
L4a adapter tests 11 passed; ecosystem sweep 28 PASS / 0 FAIL.

DEFERRED (capability or design boundary, not hidden): browser HTML/CSS/DOM,
hydration/SSR, general HTML parser, dynamic component-private state, raw CSS and
media queries, Canvas scene authoring, non-Click runtime behavior, and all
performance measurement (protected compiler campaign). Styling is token-first;
Tailwind remains an L4b web styling tool behind `xylem-web/styles.rs`.
