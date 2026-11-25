---
doc_id: ORCHID_PORT
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
---

# Orchid port design — research → design only

**Scope.** Read-only study. Orchid root `/home/philip/Development/orchid` at
full HEAD `fced0a1a3a5edc5cc48a72a9f8d2b2ead5397210`, clean. Xylem integration
worktree `/home/philip/Development/version_2/ecosystem-worktrees/xylem-lang` on
`integration/ecosystem-readiness` at `c37ed68f37c931d59b4d2a2a4ee7dc61d5be9bcb`,
clean, observed 2026-11-25T01:36Z. Pinned bootstrap: source
`5ff0ba2a949aea8acb08fe5cc4e8a5dbd855dcc4`, artifact sha256
`7082acd9baf0d0370a84efd67f25ae3dab470dce4b0ba440f945b7687748704c`; backend
host `7fe37434c868908cea37fc55475929cea2a15590` / sha256 `2e2d75fb…`; protocol
ids `xylem-bootstrap-ir/1`, `xylem-native/16` (`X:xylem-lang/toolchain.toml:1-20`).
No external URL was consulted for this record. Prefixes: `O:` =
`/home/philip/Development/orchid/`, `X:` = `/home/philip/Development/version_2/`.
No code, Cargo pin, protected path, compiler file, adapter or CI trigger was
touched. No performance claim is made.

**Skills applied** (worktree paths):
`X:ecosystem-worktrees/xylem-lang/.agents/skills/xylem-app-research/SKILL.md:10-57`
(source ranking, revision pin, claim labels, claim/evidence table),
`.../xylem-app-design/SKILL.md:10-40` (criteria first, placement, effects,
fixtures, ADR),
`.../xylem-app-delivery/SKILL.md:23-78` (ordered gates, ledger, STOP),
`.../xylem-platform-orientation/SKILL.md:12-99` (L0–L7 map, ports, version/refusal),
`.../xylem-agent-workflow/SKILL.md:37-59` (pinned compiler, focused checks,
independent verification, final-report evidence).

### Delivery ledger (gate 1–2 artifacts here; gates 3–7 NOT RUN)

| Gate | Route skill | Exit criterion | Artifact | Status | Evidence | Verifier | STOP? |
|---|---|---|---|---|---|---|---|
| 1 Research | `xylem-app-research` | citation table, no invented facts | §2 below | VERIFIED (this agent) | exact `file:line` rows | PENDING_INDEPENDENT_VERIFICATION | no |
| 2 Design | `xylem-app-design` | criteria, layers, plugin map, effects, fixtures | §1, §3–§8, ADR-P1 | VERIFIED (this agent, design only) | D-001/D-002/D-003/D-005 cites | PENDING_INDEPENDENT_VERIFICATION | no |
| 3 Implementation | `xylem-app-implementation` | owned diff, README contract | — | NOT RUN | work order required | — | n/a |
| 4 Build | `xylem-app-build` | pinned compiler commands, hashes | — | NOT RUN | toolchain pin above | — | n/a |
| 5 Verification | `xylem-app-verification` | byte-exact ± fixtures, named verifier | — | NOT RUN | §7 fixture plan | — | n/a |
| 6 Review | `xylem-platform-review` | evidence-backed findings | — | NOT RUN | — | — | n/a |
| 7 Integration | `xylem-agent-workflow` | A004 checklist, push authorization | — | NOT RUN | — | — | n/a |

## 1. Acceptance criteria for the first slice (consumer-observable)

AC1 — a caller dispatches `document.create-project` then `document.rename`
through injected storage/clock stubs and receives the byte-exact
`DispatchResult` sequence (revision 1→2, evidence timestamp from the fixed
clock, exit 0) (`O:docs/architecture.md:163-185`). AC2 — a stale
`expected_revision` returns the named conflict refusal and the stored document
bytes are unchanged (`O:crates/orchid-session/src/lib.rs:45-49,191-195`). AC3 —
`lotus.plugin/v9` is refused with `UMS-REF-0009` and a malformed id with
`UMS-REF-0048`; neither defaults (`X:.../lotus/contracts/core.xy:75-118`;
`.../contracts/refusal.xy:64-138`). AC4 — a failed batch leaves document,
revision and undo history byte-exact (`O:docs/architecture.md:153-155`). AC5 —
undo then redo reproduces the earlier and later document JSON exactly
(`O:crates/orchid-engine/src/engine.rs:654-705`). AC6 — structural gate reports
zero protected/Cargo/Rust-runtime changes and no host API in portable sources
(`O:scripts/check-architecture.mjs:223-244,263-294`). All criteria are
pinned-compiler checkable; none asserts timing.

## 2. Claim/evidence table

| ID | Claim | Label | Evidence (`file:line`) | AC served | Contradiction / action |
|---|---|---|---|---|---|
| R1 | Orchid is an L6 engine/SDK; Lotus owns platform services, Lily the UI | VERIFIED | `O:README.md:3-11`; `O:docs/architecture.md:29-37`; `X:docs/decisions/D-001-platform-layering.md:31-42,55` | AC1 | none |
| R2 | One schema-v3 COW document with typed IDs, fingerprint and validation | VERIFIED | `O:crates/orchid-core/src/document.rs:29,174-188,214-256,262-267,478` | AC1, AC4, AC5 | none |
| R3 | Dispatch is atomic with evidence; failure leaves document unchanged | VERIFIED | `O:docs/architecture.md:122-155`; `O:crates/orchid-engine/src/engine.rs:31-40,361-480` | AC1, AC4 | none |
| R4 | Product-local `orchid.A2..A7` is the accepted namespace | PLANNED (decision intent) | `X:docs/decisions/D-005-lotus-port-strategy.md:161-186` | AC1 | needs work order before implementation |
| R5 | L2b owns four versioned injected ports with declared effect rows | VERIFIED | `X:.../lotus/README.md:129-140`; `.../ports/{storage,clock,rng,transport}.xy:8-45` | AC1 | none |
| R6 | ID/refusal/version rules already exist in the kernel | VERIFIED | `X:.../lotus/contracts/core.xy:17-22,75-118`; `.../refusal.xy:64-138`; `.../version.xy:11-59` | AC3 | do not reimplement |
| R7 | Evidence, audit-chain and workflow-state rules already exist in the kernel | VERIFIED | `X:.../lotus/contracts/evidence.xy:39-89`; `.../audit.xy:84-132`; `.../workflow.xy:212-224`; `.../modules/workflow_def.xy:94-243` | AC1 | use as projections |
| R8 | Prior claim that `events.xy` and `rpc.xy` are both merged | DOWNGRADED / PARTIALLY REJECTED | `rpc.xy` merged: `X:.../xylem-lang/lotus/modules/rpc.xy:1-23`, `lotus/tests/l7_rpc.xy`; `events.xy` absent from integration tree, untracked on `task-port-events`: `X:ecosystem-worktrees/task-port-events/lotus/modules/events.xy:1-18` | AC3 | map RPC only; events stays UNKNOWN until merged |
| R9 | Pinned compiler/backend identities are recorded | VERIFIED | `X:xylem-lang/toolchain.toml:1-20` | AC1–AC6 | no check executed in this design task |
| R10 | Portable crate list and host-API guard are authoritative | VERIFIED | `O:scripts/check-architecture.mjs:157-168,263-294` | AC6 | none |
| R11 | Xylem lint is style-only; LSP has no lint integration | VERIFIED | `X:docs/decisions/D-003-platform-app-conformance.md:31-43` | AC6 | no duplicate CLI/LSP |
| R12 | No performance claim may transfer from Rust benches | VERIFIED | `X:D-005:199-200`; `X:ecosystem-readiness/DESIGN/README.md:16-19` | AC6 | none |
| R13 | Ported slices are not yet implemented | PLANNED | `X:D-005:140-150`; `X:ecosystem-readiness/DESIGN/README.md:9-15` | AC1–AC6 | separate work order required |

## 3. Stable contracts and refusal vocabulary (one table)

| Contract / identity | Orchid owner | Kernel counterpart | Covered? / status |
|---|---|---|---|
| Document `v3`, extension `orchid.morphTargets` | `orchid-core` (`.../document.rs:29,33`) | none; ID grammar only | New at `orchid.A2/A3` |
| `orchid.operation/v1`, descriptor with id/version/permission/schemas/effects and `Stability` | `orchid-engine` (`.../catalog.rs:17-19`; `.../operation.rs:13-43`) | `lotus.plugin/v1`, `lotus.manifest/v1` (`X:.../contracts/plugin.xy:16-124`, `.../manifest.xy:265-323`) | Envelope covered; Orchid schemas product-owned |
| `DispatchResult` / `ExecutionEvidence` (`ORCHID-*` codes) | `orchid-engine` (`.../engine.rs:31-40`; `.../evidence.rs:9-29`) | `lotus.evidence/v1`, `lotus.audit/v1` (`X:.../contracts/evidence.xy:15-24,39-89`, `.../audit.xy:22-132`) | **Yes** for chain/bundle; one projection only |
| `orchid.type/v1` (`TypeId`, `TypeRef`, `TypedValue`, conversions) | `orchid-types` (`.../lib.rs:19,65-264`) | `catalog.xy:12-58`, `version.xy:11-59` | Partial; no second catalog |
| `orchid.graph/v1`, `.checkpoint/v1`, `.lease/v1`, `orchid.remote/v1` | `orchid-graph` (`.../lib.rs:30-72`) | `contracts/graph.xy:18-32,75-105`; `modules/graph_exec.xy:30-143` | **Yes** for cycle/edge/binding; runners product-owned |
| `orchid.plugin/v1`, `.node/v1`, `.capability/v1` | `orchid-plugin-api` (`.../lib.rs:28-43`; `.../capability.rs:13`) | `plugin.xy`, `capability.xy:10-65`, `plugin_host.xy:23-201` | **Yes**; map, do not fork |
| `orchid.registry/v1`, `orchid.plugin-package/v1` | `orchid-plugin-registry` (`.../lib.rs:38`, `.../package.rs:20`) | `plugin_host.xy:96-201` | Lifecycle covered; index product-owned |
| `orchid.session/v1` + `auth`, `acl`, `audit`, `secret`, `key-trust` (`ORCHID-STORAGE-CONFLICT`, …) | `orchid-session` (`.../lib.rs:17-49`) | `ports/storage.xy`, `audit.xy:84-132`, `refusal.xy` | **Yes** for port/chain; tenancy product-owned |
| `orchid.pipeline/v1`, `orchid.worker/v1`, `orchid.agent/v1` | respective crates (`pipeline:34`, `worker:14`, `agent:18`) | `workflow_def.xy:94-243`; `rpc.xy:1-23`; `transport.xy` | Definition/RPC covered; worker mapping PENDING (events) |
| Snapshot `v1` / `EngineState` | `orchid-engine` (`snapshot.rs:15`, `engine.rs:79-91`) | `modules/store.xy:18-229` via storage port | **Yes** for mechanics; schema product-owned |

Refusals: translate `ORCHID-*` ↔ canonical `UMS-REF-*` once at the boundary;
unknown major → `UMS-REF-0009`, malformed id → `UMS-REF-0048`, storage conflict
→ `ORCHID-STORAGE-CONFLICT` (`X:.../lotus/README.md:59-61`;
`O:docs/project-plan.md:227-247`). The kernel registers `UMS-REF-0009` and `UMS-REF-0048` explicitly (`X:.../lotus/contracts/refusal.xy:9-10,57-58`, `.../version.xy:11-59`, `.../examples/lotus-web-consumer/README.md:55-61`). Never reinterpret an older schema under a
newer contract.

## 4. Layer matrix and plugin-boundary map

| Edge (source → target) | Via | Direction |
|---|---|---|
| `orchid.A2..A7` → L2b contracts/ports | relative import + injected function value | downward only |
| `orchid.A3` engine → `orchid.A2` core/types | owned product contract | downward |
| `orchid.A6` SDK → `orchid.A3/A5` | facade (`X:.../modules/sdk.xy:14-51`) | downward |
| L2b → host (files/network/clock/RNG) | injected port, no adapter compiled in kernel | downward, no upward reference |

| Plugin boundary | id | api_version | capabilities | lifecycle |
|---|---|---|---|---|
| Core operations/nodes | `orchid.core` | `orchid.plugin/v1` → `lotus.plugin/v1` | `document.read/write`, `graph.node.register` (`O:.../plugin-api/src/lib.rs:187-238`) | install → activate → deactivate → unload (`O:.../plugin-api/src/lib.rs:1611-1628`; `X:.../modules/plugin_host.xy:96-132`) |
| First-party creative plugins | `orchid.plugin.<domain>`, explicit list | same | declared operation/node contributions (`O:docs/architecture.md:93-96`) | atomic registration, static only (`X:D-002:48-59`) |
| Host ports (not plugins) | `lotus.storage/v1`, `.clock/v1`, `.rng/v1`, `.transport/v1` | `contract_id(family, 1)` | `StorageRead/Write`, `NowMillis`, `NextU64`, `SendText` | injected by L3/L7 host; effect rows `[allocation]`, `[external]`, `[external]`, `[network, allocation]` (`X:.../lotus/ports/*.xy`) |

## 5. Module/ownership/effects map — crate → `orchid.A2..A7` → L2b

Portable set is fixed by the architecture guard (`O:scripts/check-architecture.mjs:157-168,263-294`).
"C" marks an existing kernel rule the port consumes rather than duplicates.

| Crate | Layer / state owned | Consumes (L2b) | Effects / injected ports (injector) | C |
|---|---|---|---|---|
| `orchid-core` | A2 IDs/DTOs, A3 document/COW/validation/migration/fingerprint | `contracts/core.xy`, `refusal.xy`, `version.xy` | `[allocation]`; none | IDs/refusal/version |
| `orchid-types` | A2 type descriptors/conversions | `modules/catalog.xy`, `version.xy` | `[allocation]`; none | partial catalog |
| `orchid-assets` | A2 asset port, A4 byte mapping | `ports/storage.xy`, `core.xy` | `[allocation]`; storage (host) | id/durable bytes |
| `orchid-engine` | A3 registry/dispatch/history/evidence, A5 workflow policy | `evidence.xy`, `audit.xy`, `workflow.xy`, `workflow_def.xy`, `clock.xy` | `[external, allocation]`; clock (host), storage for snapshots | evidence/audit/state |
| `orchid-graph` | A3 model/compiler/executor/cache, A5 runner policy | `graph.xy`, `graph_exec.xy`, `clock/storage/transport.xy` | `[allocation]` + `[external]`/`[network, allocation]` via injected fn; host | cycle/edge/binding |
| `orchid-plugin-api` | A2 extension contracts | `plugin.xy`, `capability.xy`, `manifest.xy`, `version.xy` | `[allocation]`; none | full |
| `orchid-plugin-registry` | A5 lifecycle/resolution, A2 package DTO | `plugin_host.xy:96-201`, `storage.xy` | `[allocation]`; storage (host) | lifecycle |
| `orchid-session` | A4 persistence mappings, A5 authn/ACL/secrets | `storage.xy`, `audit.xy`, `evidence.xy`, `refusal.xy` | `[allocation]`; storage + security clock (host) | chain/port |
| `orchid-pipeline` | A5 fixed source→sheet stages, stage hashes | `workflow_def.xy:94-243`, `storage.xy` | `[allocation]`; storage (host) | definition |
| `orchid-worker`, `orchid-agent` | A2 envelope, A5 bounded loop | `refusal.xy`, `rpc.xy:1-23`, `plugin_host.xy:166-201`; `transport.xy` | `[network, allocation]`; transport (host) | partial / PENDING |
| `orchid-sdk` | A6 supported facade | `runtime.xy:19-81`, `sdk.xy:14-51`, `version.xy` | propagation of injected rows unchanged; host | composition/facade |

Every edge points downward; L2b never stores upper-layer state. One canonical
implementation per behaviour; no boxed per-node hot path or repeated whole-tree
scan (`X:D-001:85-105`; `.../xylem-app-design/SKILL.md:18-20`).

## 6. Explicitly DEFERRED host-bound crates

No adapter is ported in this campaign (`O:docs/contributing.md:23-48`):

1. GPU/render plugins: `orchid-gpu`, `orchid-plugin-render-gpu/render2d/render3d`
   device paths (`O:Cargo.toml:126`; `O:docs/architecture.md:382-392`).
2. WASM sandbox: `orchid-plugin-wasm`, `wasmtime` pin (`O:Cargo.toml:102`;
   `O:docs/architecture.md:312-321`).
3. Native worker/async: `orchid-host-files` worker bridge, `ThreadedRunner`,
   `WorkerPoolRunner`, `SystemTimer`, `ScheduledRemoteRunner`
   (`O:crates/orchid-sdk/src/lib.rs:78-102,1160-1211`).
4. TCP/filesystem hosts: `orchid-host-tcp`, file checkpoint/lease/package/audit/
   token/secret stores (`O:docs/architecture.md:74-75,286-304`); only injected
   ports are consumed.
5. Registry server: `orchid-registry-server` HTTP publish/resolve/download
   (`O:docs/architecture.md:323-326`) — distribution is Xylem L7.
6. Benchmark harness: `orchid-bench`, `scripts/bench-wasm.mjs`, browser perf
   (`O:docs/project-plan.md:365-376`) — no number or budget asserted.
7. `orchid-cli`, `orchid-wasm` hosts (`O:crates/orchid-cli/src/main.rs:1-17,21-31`;
   `O:crates/orchid-wasm/src/lib.rs:1-8,90-119`) — duplicate L7 delivery / need L4a.
8. Rust Lotus adapters `orchid-lotus`, `orchid-lotus-durable` (`O:Cargo.toml:104-113`)
   and `orchid-codegen` CLI (`O:scripts/check-architecture.mjs:297-318`) — no
   Rust runtime import; generated catalog data may be a fixture only.

## 7. Phased order, first slice and pinned fixtures

Phase 0 A2 contract spine (IDs, refusal map, schema identities). **Phase 1 first
credible slice:** document model (`v3`) + typed operations + revision/history —
`orchid-core` document/validation/fingerprint/COW, minimal `orchid-types`,
`orchid-engine` descriptor dispatch for `document.create-project`,
`document.rename`, `document.summary`, `part.create`, evidence projection,
`expected_revision`, undo/redo, `EngineLimits`
(`O:crates/orchid-engine/src/limits.rs:12-18`); in-memory storage stub, fixed
clock; no plugins, graphs, pipeline, auth provider or UI. Phases 2–5 add
statically registered plugins, sequential graph/workflow, session/ACL/audit
mappings, then SDK facade. Phase 6 hosts remain deferred (§6).

Fixture plan, all with the pinned compiler (R9): `fixtures/document-v3-accept.json`,
`fixtures/document-v2-refuse.json`, `fixtures/plugin-major-v9-refuse.json`
(`UMS-REF-0009`), `fixtures/id-malformed-refuse.json` (`UMS-REF-0048`),
`fixtures/dispatch-roundtrip/input.json` + `expected-output/report.txt`
(byte-exact, AC1), `fixtures/stale-revision-refuse.json` (AC2),
`fixtures/failed-batch/report.txt` (AC4), `fixtures/undo-redo/report.txt` (AC5),
`fixtures/audit-broken-chain.json` (negative), injected clock `1234` / RNG `42`
stubs as in `X:.../lotus/tests/p1_ports.xy:1-60`, and byte-exact `check`/`test`/
`run` reports as in `X:.../examples/lotus-web-consumer/README.md:25-77`. Run
stdlib-only `X:.../lotus/tools/validate_lotus.py` for accept/reject pairs and
the structural gate for AC6. Each run records command, exit code, artifact
hash and verifier; all are `PENDING_INDEPENDENT_VERIFICATION` until reproduced.

## 8. Non-duplication rules

1. UI: consume L4a `xylem-ui` contract; no second UI/renderer (`X:D-001:52-53,138`).
2. Toolchain: no L0/L1, IR/ABI, ownership/RC or benchmark-harness edit; interface
   requests only (`X:DESIGN/README.md:19-24`).
3. CLI/LSP: no second CLI, linter or LSP; today's linter is `W7001`–`W7004` and
   the LSP does not consume it (`X:D-003:31-43`).
4. Distribution: no second package registry/SBOM/version authority (`X:ecosystem-readiness/docs/decisions/D-004-product-surface.md:32-55`).
5. Skills: use the canonical in-house library (`X:D-006:8-19,35-40`).
6. Plugin/capability and contracts: one plugin seam (`X:D-002:9-21,34-65`), one
   port owner per abstraction (`X:D-001:72-83`); keep `orchid.*/v1` and
   `lotus.*/v1` distinct, translate at the boundary (`X:D-005:188-203`).

## 9. ADR-P1 (proposed), open questions, honest status

**ADR-P1 — keep Orchid a product-local L6 application over L2b contracts.**
Context: Orchid has its own document/revision/evidence semantics, while Xylem
already owns contracts/ports and delivery layers (R1–R7, R10–R11). Decision:
port creative contracts to `orchid.A2..A7` and consume L2b rules via injected
ports; reject alternatives (A) pinning Orchid's Rust crates/Runtime, (B)
flattening Orchid into L2b, (C) duplicating UI/CLI/plugin layers. Status:
`proposed` (no authorizing work order). Consequences: no byte compatibility with
Rust artifacts is claimed; migration gate is the byte-exact fixture set in §7
plus structural gate; rollback is to drop the product-local modules without
touching protected paths. Invariants: every boundary `family/vN`, every refusal
canonical, no host adapter in portable sources.

Open questions: exact `ORCHID-*` → `UMS-REF-*` code map (UNKNOWN); whether
Xylem-native storage alone suffices for snapshots (UNKNOWN); whether `A2..A7`
gets L7 lint codes (UNKNOWN); whether `xylem.lotus.*` vs `lotus.*` governs new
projections (PLANNED, `X:D-005:229-238`); `events.xy` mapping (UNKNOWN, R8).

Status: `SPECIFIED_NOT_IMPLEMENTED`; every row above is
`PENDING_INDEPENDENT_VERIFICATION` until a second agent reproduces it. No
fixture was executed for this design; gates 3–7 are NOT RUN; no performance
figure, speed-up or cross-platform guarantee is asserted.

**Sources:** all cited `file:line` above; `O:docs/{architecture,project-plan,contributing,getting-started,cli,sdk,browser,lotus-integration}.md`,
workspace and crate `Cargo.toml`s and public `lib.rs` APIs; `X:docs/decisions/D-001..D-006`,
`X:ecosystem-worktrees/xylem-lang/lotus/{README.md,CONTRACT_CATALOG.md,contracts/*,ports/*,modules/*,tests/*}`.
