---
doc_id: SERVER-RUNTIME-001
title: "xylem-<server-runtime> (name TBD) — Deno/Node analogue, design only"
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
layer: L5 (primary); consumes L3 readiness/timers, L2 networking, L4a UI port for SSR; L7 is a delivery plane, not a runtime dependency
---

## 1. Current Xylem assets and exact gaps (with layer placement)

**Owner directive honored:** design only — no implementation, no build, no CI/push.

Per `docs/decisions/D-001-platform-layering.md` **v2:28-56,116-125**, `xylem-<server-runtime>` is **primarily L5** (frameworks/application services). v2 amended v1's L3→L4 dependency inversion: L4 is split into **L4a** (shared UI policy core, owns the rendering port) and **L4b** (target adapters that implement that port). Its source dependencies are downward only:

| Direction | Layer | Interface consumed | Evidence |
|---|---|---|---|
| down | L3 | platform readiness/timers, surface, input; event-loop state owned by L3 | `D-001 v2:51`, product row `:121` |
| down | L2 | networking/fs/process/streams capabilities + typed diagnostics | `xylem-lang/stdlib/src/std/{networking,process,filesystem,streams}.xy` |
| down | **L4a** | UI contract + **rendering port** for SSR — never L4b directly, never a private UI model | `D-001 v2:52,54,79`; `xylem-platform/crates/xylem-ui/src/lib.rs:1-68` |
| delivery only (not runtime) | **L7** | published stable artifacts from manifest/lockfile/registry/resolver; L7 consumes L0–L6 interfaces, no runtime layer depends on L7 | `D-001 v2:40,56,68,140-141`; `xylem-rust/crates/xylem-toolchain/src/{manifest,lockfile,registry,resolver}.rs` |
| down | L0/L1 | protected host execution/value model — **interface requests only** | `D-001 v2:48-49`; `xylem-lang/AGENTS.md:14-20` |

**Dependency rules:** source dependencies point downward toward stable policy; runtime call/data flow may go upward via events/subscriptions established by the upper layer (`D-001 v2:18-19,85-93`). The port lives in its owning layer — UI rendering in L4a, readiness/input/surface in L3, capabilities in L2; an adapter that merely mirrors its implementation is not a port (`D-001 v2:72-83`). L5 never calls L6 as a library, never reimplements L2 capabilities, never depends on a sibling L4b adapter or defines a competing UI contract; Canvas remains an L4b embedded surface, never a widget replacement (`D-001 v2:54,119,138-139`).

**What exists (evidence, not aspiration):** `xylem-cli` `run`/`eval`/`repl` (`xylem-rust/crates/xylem-cli/src/{main,lib}.rs`); `std/networking.xy:12-118` (`listen`, `local_port`, `accept`, `connect`, `send`, `receive`, `shutdown_write`, `close_*`, `loopback`, all with `network` effects); `std/process.xy`, `std/filesystem.xy`, `std/streams.xy`, `std/json.xy`, `std/toml.xy`; `std/runtime.xy:2-44` (execution contexts, leases, event count, logging); `xylem-toolchain` manifest/lockfile/registry/resolver; `xylem-wasm` ABI v1/v2 (`xylem-rust/crates/xylem-wasm/src/lib.rs:21-27,1255-1436`); L4 shared document + web/desktop adapters + JSON fixture.

**Exact gaps:** no event loop/timer/reactor, no nonblocking I/O scheduler, no runtime module resolution, no server lifecycle, no declared-effect→permission mapping, no stable server API, no SSR router. `xylem-runtime` is **not available** as a product name (protected compiler crate) — `docs/decisions/README.md:22-24`. `ecosystem-readiness/docs/decisions/D-004-product-surface.md` is named in the campaign `DESIGN/README.md` input list (and in v1 D-001's "Supersedes" section) but does not exist at either path; v2's related decisions are D-002/D-003 (`D-001 v2:5`). The accepted product-surface decision text is `ecosystem-readiness/docs/decisions/README.md` (recorded in §10).

**Status contradiction:** the owner brief calls general TCP "unverified"; the live matrix (`ecosystem-worktrees/xylem-lang/docs/tooling/cross-target-capabilities.md:59-60`) calls loopback `IMPLEMENTED_BUT_LIMITED` and general TCP `IMPLEMENTED_BUT_LIMITED` (Linux x86-64 interpreter/native, WL-28, 64-handle table). Both are **PENDING_INDEPENDENT_VERIFICATION**; no status promoted.

## 2. Existing products studied (primary sources) and the traps they fell into

| Runtime | Event-loop / concurrency model | Module & capability story | Documented trap | Primary source |
|---|---|---|---|---|
| Node.js / libuv | 6-phase loop (timers, pending, idle/prepare, poll, check, close); timers moved after poll in libuv 1.45; one loop per thread, loop not thread-safe; fs/DNS on fixed thread pool | `node_modules` resolution; native addons need ABI stability (N-API since v8.6.0, forward-compatible across majors) | blocking callbacks, REDOS, JSON DOS, recursive `nextTick` starving poll; worker offload requires serialize/deserialize | https://nodejs.org/learn/asynchronous-work/event-loop-timers-and-nexttick ; https://docs.libuv.org/en/v1.x/design.html ; https://github.com/libuv/libuv/blob/v1.x/src/unix/core.c ; https://nodejs.org/learn/asynchronous-work/dont-block-the-event-loop ; https://nodejs.org/learn/modules/abi-stability |
| Deno | Tokio scheduler under V8; ops are an RPC boundary; `rid`≈fd, workers≈processes | URL/`jsr:`/`npm:` specifiers, import map in `deno.json`, `deno.lock` with frozen mode; deny-by-default `--allow-*` flags; `--deny-*` overrides | permissions enforced in JS layer; `--allow-ffi`/`--allow-run` are effectively `--allow-all` (native code issues syscalls directly); permission stack traces off by default for performance | https://docs.deno.com/runtime/contributing/architecture/ ; https://docs.deno.com/runtime/reference/permissions/ ; https://docs.deno.com/runtime/fundamentals/security/ ; https://docs.deno.com/runtime/reference/deno_json/ ; https://docs.deno.com/runtime/packages/ |
| Bun | `Bun.serve` with route/pattern dispatch over `Request`/`Response`; Web-API-first server | `bunfig.toml`, Node compat | `--watch` hard-restarts; `--hot` re-evaluates all modules, runs GC synchronously, re-transpiles unchanged files; `globalThis` state persists | https://bun.sh/docs/runtime/http/server.md ; https://bun.com/docs/runtime/watch-mode ; https://bun.sh/guides/http/hot.md |
| Tokio | M:N work-stealing, per-processor fixed queue + global overflow, throttled stealing; task ≈ one allocation + 64 bytes | n/a | mutex contention blocks all tasks on a thread; naive notification causes thundering herd | https://tokio.rs/tokio/tutorial/spawning ; https://tokio.rs/tokio/tutorial/shared-state ; https://tokio.rs/blog/2019-10-scheduler |
| Go | G/M/P scheduler, per-P run queues, work stealing, async preemption, GOMAXPROCS | n/a | more CPUs can slow a program via context switching; unbounded goroutine-per-request consumes unlimited resources | https://go.dev/doc/faq ; https://go.dev/doc/effective_go ; https://github.com/golang/go/blob/master/src/runtime/proc.go |
| nginx | event loop = nearest timer → I/O wait → expire timers → posted events; edge-triggered; connections preallocated; `timer_resolution` reduces `gettimeofday` calls | n/a | accept thundering herd without `EPOLLEXCLUSIVE`/reuseport; unbounded connections | https://nginx.org/en/docs/dev/development_guide.html ; http://nginx.org/en/docs/ngx_core_module.html ; https://nginx.org/en/docs/events.html |
| Uvicorn / ASGI | pluggable loop (`asyncio`, uvloop/libuvCython, experimental rloop); `scope`/`receive`/`send` coroutine channels | n/a | context leakage in asyncio (`--reset-contextvars`); uvloop unavailable on Windows/PyPy | https://uvicorn.dev/concepts/event-loop/ ; https://uvicorn.dev/concepts/asgi/ ; https://github.com/MagicStack/uvloop |
| WASI / Wasmtime | capability-based: link-time imports + unforgeable handles; no ambient authorities; fs paths relative to a preopen handle; Wasmtime `WasiCtx` per Store | component model `world`/`bindgen!` | FFI/native code escapes sandbox; `wasmtime serve` explicitly not production-hardened | https://github.com/WebAssembly/WASI/blob/main/docs/DesignPrinciples.md ; https://github.com/WebAssembly/WASI/blob/v0.2.11/docs/Capabilities.md ; https://docs.wasmtime.dev/security.html ; https://docs.wasmtime.dev/cli-options.html |

**Synthesis:** every mature runtime pays for either (a) per-event allocation, (b) cross-thread synchronization, or (c) boundary serialization. The design below avoids owning any of those at L5: it consumes them from L3/L0-L1 as pinned interfaces and keeps the hot path a single-threaded, preallocated dispatch loop.

## 3. Design options with tradeoffs; recommended option

- **A — Node/libuv clone inside the product.** Familiar phases. Reject: duplicates L3 event loop and L0/L1 host execution (violates `D-001 v2:54,60-68,130-134`), inherits callback churn and thread-pool contention.
- **B — Tokio-style work-stealing task scheduler at L5.** Good utilization. Reject: task allocation, mutex/steal contention and scheduler tuning belong to L3/L0-L1; Tokio's own docs show the cost is in the scheduler, not the framework.
- **C — Deno-style "runtime product" spanning L0–L5.** Reject: `xylem-runtime` is protected; forbidden by campaign ground rules.
- **D (recommended) — thin L5 reactor + resolution/capability/SSR services.** A per-shard, single-threaded reactor consumes an L3 readiness source; a fixed-capacity completion ring and timer min-heap are reused across iterations; declared effect rows become a startup capability table; SSR consumes the L4a rendering port (never an L4b adapter). Downward-only, single source of UI truth, no new scheduler internals. Tradeoff: no in-product I/O tuning, and throughput ceiling is the L3 host's — accepted because performance certification is owned by the protected campaign.

## 4. Data/model/lifetime design

- **Ownership:** L4a owns the UI document, L4b owns widget handles, L3 owns event-loop/surface state, L5 owns session/request state, L6 owns business data (`D-001 v2:97-101`). Lower layers never store references to upper-layer-owned state; L5 holds borrowed views/numeric ids into lower layers, and callbacks crossing upward use explicit lifetimes, ids or borrowed snapshots rather than closures capturing owned upper-layer data (`D-001 v2:90-93`). Listener/connection handles remain the opaque `i64` values of `std/networking.xy:12-20`; L5 never interprets them. Connection state lives in a fixed-slot table with stable slot indices, not boxes per callback. No global mutable registry; only explicit versioned capability registries owned by L3/L4a/L7 (`D-001 v2:101`). No boxed per-node values in hot paths; contiguous storage/arenas and borrowed views; refcount/COW traffic visible and bounded (`D-001 v2:102-103`).
- **Memory layout / allocation:** one reusable completion ring (readiness + handler id + slot), one timer min-heap keyed by deadline, one arena per request that is reset (not freed/reallocated) after the handler returns. Preallocated per nginx's connection pool pattern and libuv's handle-vs-request lifetime rules. Steady-state allocation count per poll cycle is **PENDING_VERIFICATION** (no number asserted).
- **Hot paths:** poll → dequeue readiness → resolve handler id → invoke handler → write completion; SSR path = validate once → render → serialize snapshot. Validation, indexing and layout computed **once per state change** and reused (`D-001 v2:104-105`).
- **Work queues:** timers, I/O completions, posted work (nginx-style late processing), and a bounded offload queue for blocking work. No unbounded per-request spawning (Go `effective_go` documents the resource-exhaustion failure); offload serialization is a known cost (Node guide) and is kept out of the steady-state path.
- **Explicitly out of scope:** TLS termination, HTTP/2, WebSocket framing, cluster/worker supervision, hot module replacement, native addons, mobile/desktop windowing, compiler lowering, IR/ABI changes, any performance number.

## 5. Server rendering and the shared UI contract

**Owner constraint:** UI is shared across all platforms with native components per platform. The server must render the *same* `UiDocument` for SSR and serve serialized state/binding data to web/native clients. In D-001 v2 terms, SSR **consumes L4a's port**; it does not call an L4b adapter and does not own a second UI contract (`D-001 v2:54,72-79`).

- **SSR from `UiDocument` via the L4a port.** L4a owns `UiDocument`, layout/a11y descriptors and the rendering port; L4b adapters (web DOM, GTK, AppKit, WinUI, mobile widgets, Canvas) implement that port and consume L3/L2 (`D-001 v2:52-53,74-78`). L5 obtains an implementation via explicit wiring (L6/L7 composition, `:80-82`), validates once and renders deterministically. Behavioral evidence: `xylem-web/src/ui.rs:1-13,28-54` (validate first, escaped `data-xylem-*` markup — an L4b implementation, **not** the port) and `xylem-ui/src/lib.rs:1-6` (no HTML/DOM/selector/JS value/platform handle in L4a). No second renderer, component tree or state model at L5. Parity fixture: `xylem-ui/fixtures/shared-application.json`. SSR is out of scope for today's web builder (matrix line 58, WL-42/43/45); not implemented.
- **Serialized state/binding contract.** Wire identifiers are exactly `UiBinding.path` (`xylem-ui/src/lib.rs:823-833`), `UiHandler.name` (`:835-845`), `UiNodeId` (`:21`) and `UiValue` (`:802-809`). A snapshot is a deterministic, key-ordered map of binding paths to `UiValue` plus theme tokens via existing `std/json`; `debug_tree()` already specifies key-ordered emission (`:55-60`). Envelope shape and a possible separate serialization port are **PENDING_VERIFICATION** (`D-001 v2:142-144`) and belong to L4a, not L5.
- **Handler id → endpoint or client handler.** Today `UiHandler.name` is emitted as `data-xylem-click` by the L4b web adapter (`xylem-web/src/ui.rs:188-196`) and resolved as `HANDLERS[name]` to a WASM export by `runtime.js:1178-1193,1280-1319`. The server must use the **same name**, never a second id namespace. Dispatch class (server endpoint vs client handler) must come from L4a handler metadata/effect requirements — not a server-only route table and not an L4b-private convention. Until L4a exposes that metadata through its port, the mapping is **PENDING_VERIFICATION** and no routing behavior is claimed.
- **Must NOT be server-specific:** no duplicate `UiDocument`/`UiElementKind`/`UiBinding`/`UiHandler`, no server-only props/events/state container, no port mirrored in L5, no dependency on a sibling L4b adapter, no embedded-browser fallback, no custom renderer replacing native widgets, no Canvas treated as a competing UI system (`D-001 v2:53,79,83,119,138-139`). Unsupported capabilities or unmappable elements produce `UiDiagnostic`s and graceful degradation, never fabricated support (`D-001 v2:111-112`; `xylem-ui/src/lib.rs:133-148`).

## 6. API sketch (signatures and behavior only — no implementation)

```text
serve(config: ServerConfig) -> Result<Server, ServerError>
    effects [network, capability]          # bind reactor; no module resolution here

ServerConfig { listener: Listener, capabilities: CapabilitySet,
               resolved: ResolvedGraph, render: RenderFn }

register_handler(name: &str, target: HandlerTarget) -> Result<Unit, ServerError>
HandlerTarget = ClientOnly | ServerRoute(RouteId) | Conditional(EffectRow)

poll(server: &mut Server, budget: Budget) -> Result<PollOutcome, ServerError>
    effects [network, timer]               # reuse ring + heap; no allocation specified here

render_ssr(doc: &UiDocument, state: &UiStateSnapshot)
    -> Result<String, ServerError> effects [allocation]

serialize_state(state: &UiStateSnapshot) -> String effects [allocation]

RequestContext { node: UiNodeId, binding_paths: View<&str>, handler: &UiHandler }
```

All named types are placeholders pending stable L3/L4 interfaces; signatures assert behavior, not representation.

## 7. Performance budget + anti-pattern checklist + D-001 rule check

**Budget (invariants, not numbers):** ≤1 document validation per state change; O(1) dispatch per readiness event; zero per-request re-resolution; bounded ring/heap/worker pools; no lock on the reactor thread; no unbounded log volume; absolute latencies/throughput **PENDING_VERIFICATION** and must come from the protected campaign under paired A/B with exact artifact identities (`xylem-lang/AGENTS.md:46-54`).

**Anti-pattern checklist** (derived from primary sources above):
- [ ] No blocking/CPU-heavy callback, sync fs or unbounded JSON on the reactor (Node "Don't block"; JSON DOS).
- [ ] No recursive tick queue that starves I/O (Node `nextTick`).
- [ ] No repeated whole-tree/whole-source scans (`D-001 v2:104-105`; `xylem-lang/AGENTS.md:76-77`).
- [ ] No per-event closure/handle allocation in the hot path (libuv handle/request lifetime rules).
- [ ] No goroutine/task-per-request unbounded spawn (Go `effective_go`).
- [ ] No shared mutex across reactor tasks; shard or message-pass instead (Tokio shared-state).
- [ ] No `--hot`-style full re-transpile + synchronous GC on reload (Bun watch-mode docs).
- [ ] No unconditional permission stack traces / unbounded access logging (Deno permissions reference).
- [ ] No FFI/native addon treated as sandbox-preserving (Deno security; WASI capabilities).
- [ ] No second UI model, mirrored port, sibling-adapter dependency or embedded-browser fallback (`D-001 v2:53,79,83`).

**Rule check — original eight anti-trap rules mapped to D-001 v2 clauses:**

| # | Rule (v1) | v2 clause | Design response | Remaining gap |
|---|---|---|---|---|
| 1 | No upward dependencies | §4 matrix `:60-68`; ports `:72-83` | L5 consumes L2/L3/L4a only; **no L7 runtime dep**, no L4b dep | L3 readiness interface must exist |
| 2 | Stable boundaries | §5 `§8` `:74,113-114` | pinned `xylem-native/16`, `xylem-bootstrap-ir/1`, L4a port, L7 artifacts | port/version identities open (`:142`) |
| 3 | Single-pass | `:104-105` | validate/index/layout once per state change; immutable resolved graph | none in design |
| 4 | Explicit ownership | `:90-103` | L5 owns session state; L4a owns document; slots+arenas; no global registry; borrowed ids | representation needs L1 confirmation |
| 5 | Native components at L4→L3 | `:53,119,138-139` | SSR uses the L4a port; L4b maps to native widgets; Canvas embedded | L4a dispatch metadata missing |
| 6 | Capability negotiation + honest diagnostics | `:111-112` | deny-by-default effects; `UiDiagnostic` for unmappable elements | effect→capability table PENDING |
| 7 | Per-layer verification gates | §3 last column; §10 `:130-134` | focused L4a/L5 fixtures per phase (§9); no benchmarks here; `xylem lint` architecture enforcement not shipped | independent verifier required |
| 8 | Escalation, not modification | `:48-49,130-134` | all L0/L1 needs become §8 interface requests | none |

## 8. Interface requests (protected L0/L1 team plus L4a/L7 owners)

1. **L0/L1 readiness interface:** stable, pinned nonblocking registration + timer deadline interface usable from L5 without owning polling internals; document thread-affinity and allocation behavior. If absent, file a defect handover — do not reimplement.
2. **L1 effect-row introspection:** compile-time effect rows (e.g. `[network]`, `[allocation]`, `[synchronisation]` from `std/networking.xy`, `std/runtime.xy`) exposed as a runtime-readable capability descriptor with no ambient authority; align with WASI link-time/runtime capability distinction.
3. **L0/L1 stable native ABI for any addon/FFI:** N-API-style versioned forward compatibility is required before native extenders can be offered; until then native addons are **out of scope** (Deno security: native code bypasses the JS-layer sandbox; `xylem-runtime` is protected).
4. **L1 value/borrow interface for `UiValue` snapshots:** contiguous, borrow-based views so SSR state serialization does not add per-field boxing/refcount traffic.
5. **L4a (platform policy core, not compiler) port:** define/extend the L4a-owned rendering port with a `UiStateSnapshot` schema and `UiHandler` dispatch/effect metadata, so server endpoints and client handlers share one id namespace. L5 must not mirror this port; L4b adapters implement it (`D-001 v2:74-83`). Resolve the open question of a separate serialization port at L4a (`D-001 v2:142-144`).
6. **L7 (delivery plane, not runtime) artifacts:** a stable, versioned identity for the published manifest/lockfile/registry artifacts consumed at build/startup; L5 must never import L7 command implementations or L7 gates at runtime (`D-001 v2:40,56,140-141`).

## 9. Phased milestones with verification gates (no CI/deploy triggers)

| Phase | Deliverable (design artifact until owner authorizes code) | Verification gate |
|---|---|---|
| P0 contract freeze | name decision, L5 placement, downward-only matrix check (no L7 runtime dep, no L4b dep), frozen interface versions | independent review against D-001 v2 matrix/ports and `docs/decisions/README.md` |
| P1 feasibility | request/response for L0/L1 readiness + effect introspection; L4a port draft | accepted interface or recorded handover; no code from this campaign |
| P2 resolution + permissions design | build/startup-time resolution from published L7 artifacts; deny-by-default effect→capability table | frozen-lockfile reproducibility fixture; denial cases typed, no ambient authority; L7 absent at runtime |
| P3 SSR parity | same `UiDocument` + snapshot rendered through the L4a port on server and via L4b web adapter | byte-for-byte parity on `shared-application.json`; `UiDiagnostic` parity for invalid docs; no port mirrored in L5 |
| P4 reactor correctness | bounded ring/heap/posted-work design | deterministic ordering, no starvation, no per-request re-resolution; independently reproduced |
| P5 performance | budget counters only | measurement by protected campaign with paired A/B; no number from this doc |

## 10. Open questions, self-critique, and full source list

**Open questions:** final product name (`xylem-runtime` unavailable); exact `UiStateSnapshot`/handler-dispatch metadata in **L4a** and whether SSR needs a separate serialization port (`D-001 v2:142-144`); version identity format for L2–L7 ports (`:142`); whether L3 supplies readiness as Rust adapter or Xylem-source PAL; TLS boundary; whether native addons are ever supported; whether the missing `ecosystem-readiness/docs/decisions/D-004-product-surface.md` should be created or the decision index renamed.

**Self-critique pass 1 (recorded).** Weakest assumption: L3 could supply a low-allocation readiness source without L0/L1 changes. Contrary evidence: Tokio tasks cost one allocation + 64 bytes (`tokio.rs/tokio/tutorial/spawning`), libuv loops are not thread-safe (`docs.libuv.org`), Deno ops are an RPC boundary (`docs.deno.com/runtime/contributing/architecture/`). **Change:** no scheduler implementation at L5; reactor is consumed, ABI needs moved to §8, costs PENDING. The owner-brief/matrix TCP conflict was left PENDING; SSR parity is a gate, not a shipped feature.

**Self-critique pass 2 (D-001 v2 amendment).** Weak v1 assumption: SSR could call `xylem-web::render_ui_document` directly. v2 shows that is an L5→L4b source dependency mirroring an L4a-owned port (`D-001 v2:18-22,72-83`). **Changes:** SSR consumes the L4a port; `xylem-web` is behavioral evidence only; port-mirroring/sibling-adapter cases added to §7; L7 demoted to delivery plane in frontmatter, §1, §8, §9; rule-check remapped to v2 clauses. No implementation claim added.

**Sources (exact URLs used; local evidence by file:line above):**
- https://nodejs.org/learn/asynchronous-work/event-loop-timers-and-nexttick
- https://docs.libuv.org/en/v1.x/design.html
- https://github.com/libuv/libuv/blob/v1.x/src/unix/core.c
- https://nodejs.org/learn/asynchronous-work/dont-block-the-event-loop
- https://nodejs.org/learn/modules/abi-stability
- https://docs.deno.com/runtime/contributing/architecture/
- https://docs.deno.com/runtime/reference/permissions/
- https://docs.deno.com/runtime/fundamentals/security/
- https://docs.deno.com/runtime/reference/deno_json/
- https://docs.deno.com/runtime/packages/
- https://bun.sh/docs/runtime/http/server.md
- https://bun.com/docs/runtime/watch-mode
- https://bun.sh/guides/http/hot.md
- https://tokio.rs/tokio/tutorial/spawning
- https://tokio.rs/tokio/tutorial/shared-state
- https://tokio.rs/blog/2019-10-scheduler
- https://go.dev/doc/faq
- https://go.dev/doc/effective_go
- https://github.com/golang/go/blob/master/src/runtime/proc.go
- https://github.com/WebAssembly/WASI/blob/main/docs/DesignPrinciples.md
- https://github.com/WebAssembly/WASI/blob/v0.2.11/docs/Capabilities.md
- https://docs.wasmtime.dev/security.html
- https://docs.wasmtime.dev/cli-options.html
- https://docs.wasmtime.dev/
- https://nginx.org/en/docs/dev/development_guide.html
- http://nginx.org/en/docs/ngx_core_module.html
- https://nginx.org/en/docs/events.html
- https://uvicorn.dev/concepts/event-loop/
- https://uvicorn.dev/concepts/asgi/
- https://github.com/MagicStack/uvloop
- Local: `/home/philip/Development/version_2/docs/decisions/D-001-platform-layering.md`, `ecosystem-readiness/DESIGN/README.md`, `ecosystem-readiness/docs/decisions/README.md`, `xylem-lang/AGENTS.md`, `xylem-lang/stdlib/src/std/{networking,runtime}.xy`, `xylem-rust/crates/xylem-{toolchain,cli,wasm}/src/**`, `xylem-platform/crates/xylem-{ui,web}/src/**`, `xylem-platform/crates/xylem-ui/fixtures/shared-application.json`.
