---
doc_id: PERF-GUARDRAILS-001
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
owner: D-PERF (platform product design campaign)
scope: cross-cutting guardrail for all DESIGN/*.md
---

# Performance guardrails (cross-cutting, design-only)

**Authority.** `docs/decisions/D-001-platform-layering.md` **v2 (ACCEPTED,
amended 2026-11-25)** is the authoritative layer contract. Its engineering rules
are reproduced below as R1–R8; this document adds evidence, measurement
discipline and review mechanics around them. It does not add, weaken or
reinterpret a rule. In particular v2 fixes the v1 `L3→L4` dependency inversion,
puts the rendering **port in L4a (policy core)** and its implementation in L4b
(target adapters), makes L7 a delivery/developer **plane**, and separates source
dependency direction from runtime call/data flow (`D-001:3-26,58-93,140-141`).

L0 (machine substrate: ABI, IR, codegen, execution) and L1 (value model,
ownership, RC/COW, collections, traps) are **PROTECTED** (`D-001:37-38,48-49,126`;
`xylem-lang/AGENTS.md:14-20`). **No performance claim, certification, build,
benchmark, push or CI action originates in this design campaign**
(`ecosystem-readiness/DESIGN/README.md:8-11`; `D-001:146-147`). Every cited cost
below is qualitative historical evidence from the protected campaign, not a
claim made here; **no performance numbers are asserted in this document**.
Unfilled budget values are `PENDING_VERIFICATION`.

## 1. Layer contract (R1–R8, v2 authoritative)

| ID | v2 rule | Source |
|---|---|---|
| R1 | **Downward source dependencies only**, per the v2 matrix. `L3` must **not** depend on `L4a`; `L4b` implements the `L4a` port and never makes `L3` depend on `L4a`; `L5` consumes `L4a`, not `L4b` directly; `L6` does not reach `L3/L1/L0`; adapters do not depend on sibling adapters. | `D-001:58-70,74-82` |
| R2 | **Ports are owned by the layer that owns the abstraction.** The UI rendering port is in `L4a`, the readiness/input/surface port in `L3`, the capability interface in `L2`. Adapters implement ports; they do not define or mirror them. Every boundary has a versioned identity; no unpublished L0/L1 internals. | `D-001:72-83,113-114` |
| R3 | **Source dependency direction ≠ control/data flow.** Lower layers may emit events upper layers subscribe to; the upper layer establishes the subscription. Lower layers never store references to upper-layer-owned state; cross-boundary callbacks have explicit lifetimes, numeric ids and borrowed snapshots rather than captured owned data. | `D-001:18-19,85-93` |
| R4 | **Single-pass processing and layer-owned state.** Validation, indexing and layout computed once per state change and reused; no repeated whole-tree scans or repeated parsing. Each layer owns its state; only explicit versioned capability/plugin registries are shared. | `D-001:95-105` |
| R5 | **No boxed per-node values in hot paths.** Contiguous storage/arenas and borrowed views; refcount/COW traffic visible and bounded; no global mutable registry. | `D-001:100-103` |
| R6 | **Typed failure semantics and honest diagnostics.** Lower layers report typed errors upward, no panic or silent fallback; unmappable elements/unsupported capabilities yield `UiDiagnostic`s and graceful degradation; incompatible artifacts fail before use. | `D-001:107-114` |
| R7 | **Per-layer verification gates.** Focused correctness fixtures runnable without upper layers; no heavy builds or benchmark campaigns on a shared host; no performance claims from this campaign; optimization/certification stay with L0/L1. | `D-001:46-56,146-147` |
| R8 | **Escalation, not modification.** Missing lower-layer interface ⇒ interface request or defect handover, never a protected-code edit. Architecture enforcement is an L7 design item, not a shipped capability. | `D-001:48-49,126,132-134` |

## 2. Existing assets and exact gaps

- Consumable: `L4a` `xylem-ui` policy core (single source of truth),
  `L4b` target adapters (`xylem-web`, `xylem-desktop`, planned mobile),
  `L3` substrate/event loop and `xylem-graphics`/wgpu as `Canvas` substrate,
  `L2` capability modules, `L7` CLI/tooling, and published L0 artifact metadata
  (`D-001:46-56,116-126`). Protected harness interfaces are documented for
  protocol reference only (`xylem-rust/crates/xylem-bench/src/bin/compile-time.rs:1-14`;
  `xylem-rust/crates/xylem-bench/src/main.rs:1-6`).
- Gaps: exact version-identity format for L2–L7 ports; whether L5 SSR needs a
  separate serialization port; unmappable-element negotiation on mobile without
  devices; `xylem-desktop` name-collision ruling; architecture lint not shipped;
  no product-facing counter schema or budget; the GPU evidence is a single host
  with blocking readback and is not a cross-adapter result
  (`D-001:130-145`; `ecosystem-worktrees/xylem-lang/docs/development/ROADMAP.md:136-139`).
  All gaps: `PENDING_VERIFICATION`.

## 3. Compiler failure → design rule → evidence

| # | Documented compiler inefficiency / cause (qualitative) | Design rule for platform products | Evidence (exact file:line) |
|---|---|---|---|
| F1 | Values are boxed `AValue` heap objects with manual refcounting reached through out-of-line C helpers; allocator/refcount/reference traffic dominates executed instructions | **R5:** no heap allocation per UI/document node; contiguous arenas + borrow views; RC/COW counted, not hidden | `xylem-lang/docs/development/PERFORMANCE.md:18,50-52`; `D-001:100-103` |
| F2 | Large C ABI helper table makes every operation an opaque call; the optimizer cannot see through it | **R2/R3:** only versioned, typed ports owned by the owning layer; no opaque per-node helper calls or mirrored port interfaces inside a hot path | `PERFORMANCE.md:63-74`; `AGENTS.md:107-115`; `D-001:72-83` |
| F3 | Cells/frames per temp and frame teardown walks keep managed state alive across calls | **R4/R5:** state (layout, validation, bindings) computed once into stable indexed storage; no per-event frame walk or per-temp cell | `PERFORMANCE.md:64`; `xylem-lang/work_logs/archive/development/performance-program/NATIVE_REPRESENTATION_CURRENT_STATE.md:46-49`; `.../NATIVE_FALLBACK_REASON_TABLE.md:27-34` |
| F4 | Recursive RC/reclamation, unshare locks and child copying; split release authority leaves plans inert | **R5:** single authority for release/ownership; bounded RC/COW; no global mutable lock in a hot path | `PERFORMANCE.md:65,67`; `work_logs/archive/campaign/NATIVE_DEFAULT_SCOREBOARD.md:27`; `D-001:100-103` |
| F5 | Repeated whole-program/nested scans and source copying; superlinear compile growth on larger inputs | **R4:** single-pass indexing with integer IDs/maps; no repeated whole-tree scan or re-parse | `PERFORMANCE.md:76-86,247-250`; `AGENTS.md:76-77`; `ecosystem-worktrees/xylem-lang/docs/development/WORKLOG.md:2529-2530` |
| F6 | Textual type/CSE keys and append loops were proposed as fixes but later falsified | **R4:** borrow/index once, then measure; no mandated interning or buffer rewrite without protected-campaign A/B | `PERFORMANCE.md:82-86`; `xylem-lang/work_logs/archive/development/performance-program/PERFORMANCE_LEDGER.md:150-157,167` |
| F7 | IR/ABI churn, textual IR, pointer round-trips, missing proof facts; migrations require versioning | **R2/R8:** consume only published versioned identities; file requests; never patch L0/L1 or mirror their internals | `PERFORMANCE.md:97-113`; `AGENTS.md:109-115`; `D-001:72-83,133-134` |
| F8 | Benchmark contamination: stale baselines, parallel harnesses under load, debug timings mistaken for release, checksum mismatches | **R7:** frozen workload + checksum gate, exact artifact identities, quiet host, paired A/B only by protected campaign | `WORKLOG.md:2126,2224,4449,4467`; `PERFORMANCE.md:218,245-250`; `D-001:146-147` |
| F9 | Helper-count reduction falsified as a speed predictor; one-workload diagnostics are not certification | **R7:** counters are canaries, not results; no suite-wide or campaign-origin claim | `NATIVE_REPRESENTATION_CURRENT_STATE.md:59-61`; `PERFORMANCE_LEDGER.md:117-122,163-167`; `NATIVE_DEFAULT_SCOREBOARD.md:33-58` |
| F10 | Harness validity: failing/signal-killed compilers and stale artifacts must be rejected; scratch collisions; wrapper hash ≠ compiler hash | **R2/R7:** status/exit check, artifact checksum and identity on every measurement; no self-referential PASS | `xylem-rust/crates/xylem-bench/tests/compile_time_contract.rs:1-5,19-20,69-113`; `.../src/bin/compile-time.rs:8-14`; `work_logs/archive/campaign/NATIVE_DEFERRED_VERIFICATION_HANDOVER.md:65-77` |
| F11 | **v1 layering inversion**: `L3` adapters were required to render the `L4` document, forcing upward source dependencies and duplicated UI models | **R1/R3:** port stays in `L4a`; `L4b` implements it and consumes `L3`; runtime flow may go upward via subscriptions, source flow never does | `D-001:3,9-12,24-26,74-82,85-93` |

## 4. External primary corroboration

| Source (exact URL, fetched 2026-11-25) | Guardrail consequence |
|---|---|
| https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html | Ports are technology-agnostic entry points owned by the application component; adapters translate exchanges; a port may have multiple adapters; adapter code has maintenance cost ⇒ R2/R5 |
| https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html (cited by `D-001:14`) | Source dependencies point inward toward policy; frameworks are details ⇒ R1/R2 |
| https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff650258(v=pandp.10) (cited by `D-001:15`) | Layered-application guidance behind the v2 split ⇒ R1 |
| https://nnethercote.github.io/perf-book/benchmarking.html | Wall-time has high variance; cycles/instruction counts are lower-variance alternatives; realistic workloads; summaries need care |
| https://nnethercote.github.io/perf-book/heap-allocations.html | Rc/Arc on rarely shared values raises allocation rate; `clone`, `format!`, per-line `String` allocate; reuse collections; allocation regression tests ⇒ R5 and allocation-count budget |
| https://llvm.org/docs/Frontend/PerformanceTips.html | Entry-block allocas for SROA/mem2reg; avoid aggregate values; GEP/`inbounds`, `noalias`/`nonnull`, `readonly`, cold-path metadata, IRCE/LICM ⇒ facts originate in L0, not guessed at L3/L4b (R2/R8) |
| https://llvm.org/docs/Passes.html (`licm`, `argpromotion`, `gvn`) | LICM needs alias proof; scalar promotion needs no aliasing stores/calls ⇒ compute once, expose facts, no hidden state (R4/R5) |
| https://llvm.org/docs/FaultMaps.html | Implicit checks are profitable only when failures are rare and heal ⇒ proofs stay in L0; products must not delete checks (R8) |
| https://webassembly.org/docs/faq/ | Native binary decoding is much faster than JS parsing; mobile parse can be slow; stable portable encoding is a design goal ⇒ startup/bundle-size fields and no format churn (R2) |
| https://wgpu.rs/doc/wgpu_examples/timestamp_queries/index.html and https://wgpu.rs/doc/wgpu/struct.Queue.html | GPU timing needs `TIMESTAMP_QUERY`, `QuerySet`→resolve buffer→copy and a queried timestamp period ⇒ graphics budget fields record adapter/feature/period, not raw ticks |
| https://docs.unity3d.com/Packages/com.unity.entities@0.51/manual/ecs_components.html | Chunks of parallel arrays with no gaps; managed components need an extra index lookup; favor small components ⇒ contiguous L4a/L4b storage, no boxed per-node values (R5) |

## 5. Measurement discipline: safe vs forbidden

**Safe in this campaign:** describing budgets as blank fields; citing protected
evidence with `file:line`; writing correctness fixtures, counter schemas, port
identity requests and layer-diagram reviews on paper; recording artifact/host
identities as fields to fill later; eventually running *focused per-layer
correctness fixtures* that need no upper layer (R7).

**Forbidden:** builds, benchmarks, profilers, CI/deploy triggers, pushes
(`DESIGN/README.md:8-11`); touching L0/L1, the benchmark harness or IR/ABI
(`AGENTS.md:14-20`; `D-001:126`); any speedup, parity, FPS, memory or size
**claim**; relabelling Cranelift as LLVM; merging numbers from different
compiler/host pairs (`AGENTS.md:27-33`; `PERFORMANCE.md:7,193`). A v2-specific
forbidden pattern is treating an L4b adapter's local type or a mirrored port as
the policy contract — the boundary then protects nothing (`D-001:20-22,83`).

**Verification protocol (recorded here, not executed).**
1. **Correctness fixtures:** fixed checksum/differential oracle plus
   trap/diagnostic equality; status and stderr byte-identical
   (`AGENTS.md:46-54`; `compile-time.rs:8-9`).
2. **Resource counters:** allocation count, RC/COW increments, helper census,
   instruction count — exact, not sampled (`AGENTS.md:99`; `PERFORMANCE.md:195`).
3. **Artifact identities:** compiler hash, backend/host hash, toolchain pin,
   IR/native ABI version, workload and wrapper hashes recorded separately; port
   identity/version recorded at each layer boundary (`AGENTS.md:97`;
   `NATIVE_DEFERRED_VERIFICATION_HANDOVER.md:67-77`; `D-001:113-114`).
4. **Quiet host:** no competing benchmarks, CPU pinning and load recorded as an
   invocation convention; saturated-host readings are invalid, not failures
   (`AGENTS.md:138-142`; `PERFORMANCE_LEDGER.md:115-122`; `WORKLOG.md:2224,4449`).
5. **Paired A/B only by the protected campaign:** interleaved A/B, at least three
   samples, harness threshold with wider bounds for noisy kernels, LLVM release
   baseline, independent reproduction; below-noise structural changes land with
   a semantic + structural canary and an explicit "no wall-time gain claimed"
   note (`AGENTS.md:46-54,97-99`; `PERFORMANCE.md:193`).
6. **Three baselines kept separate:** clean compile, incremental compile,
   generated-program runtime (`PERFORMANCE.md:194`); for graphics, GPU
   timestamps with period normalization and readback accounted for (wgpu URLs).
7. **Non-vacuity:** a canary that removes no target structure is a failure; a
   PASS against its own stale baseline is structural only
   (`NATIVE_DEFERRED_VERIFICATION_HANDOVER.md:149-156,72-75`).
8. **Flow check:** for every upward event/subscription, confirm the subscription
   is established above, no lower layer stores upper-owned state, and callbacks
   use explicit lifetimes/ids/snapshots (`D-001:85-93`).

## 6. Performance budget template (fill later; no numbers here)

Copy into every product design. All values `PENDING_VERIFICATION` until the
protected campaign fills them; units and workload must be stated explicitly.

| Field | Value | Workload / fixture | Host & artifact IDs | Port/layer IDs | Owner |
|---|---|---|---|---|---|
| Cold startup (first interactive/request) | PENDING_VERIFICATION | | | | |
| Warm startup / reload | PENDING_VERIFICATION | | | | |
| Steady-state latency or throughput | PENDING_VERIFICATION | | | | |
| Steady-state frame time / p95 (L3/L4b) | PENDING_VERIFICATION | | | | |
| Peak RSS / working set | PENDING_VERIFICATION | | | | |
| Binary size (installed artifact) | PENDING_VERIFICATION | | | | |
| Bundle/payload size (web/mobile, compressed) | PENDING_VERIFICATION | | | | |
| Allocation count per operation / per node | PENDING_VERIFICATION | | | | |
| RC/COW increments and helper calls per op | PENDING_VERIFICATION | | | | |
| GPU adapter, feature set, timestamp period | PENDING_VERIFICATION | | | | |
| Upward callbacks / borrowed-snapshot count per state change | PENDING_VERIFICATION | | | | |
| Budget source & decision record | PENDING_VERIFICATION | | | | |

Budget rules: one workload per row; no geomean hides a failing row
(`AGENTS.md:97`; WL-88 at `WORKLOG.md:2639`); a product may not set its own
compiler or runtime baseline; size fields use official WebAssembly portability
goals as context, not invented targets (`webassembly.org/docs/faq/`).

## 7. A004 anti-pattern review checklist

Mark PASS / FAIL / N_A with evidence; any FAIL is a review bar, not a build gate.

- [ ] R1: v2 dependency matrix respected — `L3 ↛ L4a`, `L4b` implements the port
      and has no sibling-adapter dependency, `L5` uses `L4a` not `L4b`, `L6`
      uses no `L3/L1/L0`, and no runtime layer depends on `L7` (`D-001:58-70,140-141`).
- [ ] R2: each consumed port named with owner layer and version identity; no
      mirrored or adapter-defined port; no unpublished L0/L1 internals (`D-001:72-83,113-114`).
- [ ] R3: source dependencies listed separately from runtime call/data flow;
      subscriptions established above; no lower-layer reference to upper state;
      callbacks use explicit lifetimes, numeric ids or borrowed snapshots (`D-001:85-93`).
- [ ] R4: one validation/index/layout pass per state change; no repeated tree
      scan or re-parse; each layer's state ownership declared; only explicit
      versioned registries shared (`D-001:95-105`; F5, F6).
- [ ] R5: no boxed per-node values in hot paths; contiguous/arena storage and
      borrowed views; RC/COW bounded and visible; no global mutable registry
      (`D-001:100-103`; F1, F3, F4).
- [ ] R6: unsupported capability or unmappable UI element yields a typed error
      or `UiDiagnostic` and graceful degradation; incompatible artifacts fail
      before use; no fabricated support (`D-001:107-114`; `DESIGN/README.md:13-15`).
- [ ] R7: focused per-layer correctness fixtures named; no heavy build or
      benchmark campaign proposed; no performance claim or number in the doc
      (`D-001:46-56,146-147`; F8, F9).
- [ ] R8: every L0/L1 gap is an interface request or defect handover with no
      protected-file edit; architecture enforcement marked as unshipped L7 item
      (`D-001:126,132-134`; `AGENTS.md:14-20`).
- [ ] Budget table present with PENDING fields, named workload, host, artifact
      and port/layer IDs; no invented number (§6).
- [ ] Status tags honest; no future capability advertised as production-ready
      (`DESIGN/README.md:13-15`; `NATIVE_DEFAULT_SCOREBOARD.md:49-58`).

## 8. Interface requests to protected campaign (no edits)

1. Published identity/version format for L0–L7 ports and artifact hashes so L7
   tooling can pin them (R2/R8; open item `D-001:142-145`).
2. Product-facing counter contract (allocations, RC/COW, helper census, GPU
   timestamp period) documented, not implemented by this campaign (§5).
3. Clarification of contested optimization guidance before any product adopts
   interning or buffer-rewrite designs (F6; §10).
4. L4a rendering-port and L3 readiness/input/surface-port definitions with
   per-target degradation diagnostics; composition/wiring stays at L6/L7
   (`D-001:74-82,107-114`).

## 9. Phased review gates (design-only; no CI/deploy triggers)

- **G0 — Layering:** R1/R2 pass; layer and downward dependencies declared;
  port owner named; no v1 inversion.
- **G1 — Flow/lifetime:** R3 pass; upward events, callback lifetimes and
  borrowed-snapshot rules stated.
- **G2 — State/data:** R4/R5/R6 pass; ownership, storage and degradation drawn;
  budget table present with PENDING fields.
- **G3 — Evidence/handover:** citation audit; no campaign-origin claim or
  number; A004 complete; interface requests filed; A004 cross-doc contradiction
  report resolved.

## 10. Self-critique (one pass)

**Weakest assumption:** the v1 rule set and the idea that "intern types/names"
or "remove quadratic concat" are universal product rules. Contrary primary
evidence: v2 explicitly records that v1 contained an `L3→L4` dependency
inversion (`D-001:3,9-12`), so the layer contract itself was unsafe; and the
protected campaign falsified full interning and the concat rewrite while
correcting stale compiler findings (`PERFORMANCE_LEDGER.md:150-157,167,137-142`).
**Revision:** R1–R8 were replaced by v2 rules (ports, no `L3→L4a`, L7 plane,
source-vs-flow direction); F6 became "borrow/index once, then measure"; F11 was
added for the inversion. A second contradiction — backend labelling and
proxy-as-result — remains recorded at F8/F9 and is handled by §5. A third:
cross-language equivalence figures are not reproducible as claimed
(`AGENTS.md:72-75`; `PERFORMANCE.md:218`), so none are inferred here. Nothing in
this document changes protected code or asserts a performance result.

## 11. Open questions / PENDING

- PENDING: all budget values and units; per-layer counter schemas.
- PENDING: version-identity format for L2–L7 ports; SSR serialization port;
  mobile unmappable-element negotiation; `xylem-desktop` name collision.
- PENDING: architecture lint enforcement as an L7 design item (`D-001:132-134`).
- PENDING: whether any one-workload diagnostic survives quiet paired A/B —
  answer belongs to the protected campaign only.

## 12. Full source list

**Local primary:** `ecosystem-readiness/DESIGN/README.md:8-11,13-15,53-73`;
`docs/decisions/D-001-platform-layering.md` **v2**: `:3-26,28-42,44-56,58-70,72-93,95-105,107-114,116-126,128-147`;
`xylem-lang/AGENTS.md:14-20,25-33,37-54,56-66,72-99,101-142`;
`xylem-rust/AGENTS.md` (LLVM/correctness/verification sections);
`xylem-lang/docs/development/PERFORMANCE.md:3-18,24-54,57-74,76-113,193-197,207-263`;
`xylem-lang/work_logs/archive/development/performance-program/PERFORMANCE_LEDGER.md:108-177`;
`.../NATIVE_REPRESENTATION_CURRENT_STATE.md:31-61`;
`.../NATIVE_FALLBACK_REASON_TABLE.md:23-34,45-47`;
`.../NATIVE_COVERAGE_SCOREBOARD.md:77-87,169-176`;
`work_logs/archive/campaign/NATIVE_DEFAULT_SCOREBOARD.md:11-12,14-58`;
`.../NATIVE_LOWERING_HANDOVER.md:195-206,215-245`;
`.../NATIVE_IMPLEMENTATION_CAMPAIGN_FINAL.md:3-11,61-98`;
`.../NATIVE_DEFERRED_VERIFICATION_HANDOVER.md:65-77,149-164`;
`xylem-rust/crates/xylem-bench/src/bin/compile-time.rs:1-14`;
`xylem-rust/crates/xylem-bench/src/main.rs:1-6`;
`xylem-rust/crates/xylem-bench/tests/compile_time_contract.rs:1-5,19-20,69-126`;
`ecosystem-worktrees/xylem-lang/docs/development/WORKLOG.md:2126,2130,2224,2529-2530,2639,4449,4467`;
`ecosystem-worktrees/xylem-lang/docs/development/ROADMAP.md:136-139`.

**External primary (fetched 2026-11-25):** AWS Hexagonal architecture
https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html ;
Clean Architecture https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html ;
Microsoft layered architecture https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff650258(v=pandp.10) ;
Rust Performance Book https://nnethercote.github.io/perf-book/benchmarking.html ,
https://nnethercote.github.io/perf-book/heap-allocations.html ;
LLVM https://llvm.org/docs/Frontend/PerformanceTips.html ,
https://llvm.org/docs/Passes.html , https://llvm.org/docs/FaultMaps.html ;
WebAssembly https://webassembly.org/docs/faq/ ;
wgpu https://wgpu.rs/doc/wgpu_examples/timestamp_queries/index.html ,
https://wgpu.rs/doc/wgpu/struct.Queue.html ;
Unity ECS https://docs.unity3d.com/Packages/com.unity.entities@0.51/manual/ecs_components.html .
