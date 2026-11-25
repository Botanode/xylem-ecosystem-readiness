# Phase 04 — Platform product design research (design-only)

Status: ACTIVE
Date: 2026-11-25
Owner: campaign owner via A001/A004

## Objective

Design every platform product without implementing it, using live primary-source
research, and avoid the inefficiency patterns that hurt the compiler campaign.

## Produced

Nine design documents under `DESIGN/`, each with frontmatter, primary-source
citations, a self-critique pass, layer placement, plugin boundary, conformance
mapping and an honest status:

- `WEB_FRAMEWORK.md` — Aurelia 2 study and a plain-JS-feeling L5 authoring model
  over the L4a shared UI contract.
- `SERVER_RUNTIME.md` — L5 thin reactor/server runtime with SSR via L4a.
- `DESKTOP.md` — L4b GTK/libadwaita adapter over L3; name-collision analysis.
- `MOBILE.md` — L4b native iOS/Android adapter; WL-64/65 provisioning gates.
- `GRAPHICS.md` — L3 substrate plus L4b Canvas adapter; no competing UI system.
- `SHARED_UI.md` — canonical L4a policy core and rendering port.
- `TOOLING_DISTRIBUTION.md` — L7 delivery plane, staged identity ladder.
- `PERFORMANCE_GUARDRAILS.md` — compiler failure modes mapped to design rules.
- `README.md` — index and design conventions.

Decisions recorded: D-001 v2 (layering), D-002 (plugins), D-003 (app
conformance), D-004 (product surface). The cited WASM efficiency research was
integrated into `xylem-lang/docs/development/WASM_EFFICIENCY_RESEARCH.md`.

## Key design corrections

- D-001 v1 had an L3→L4 source-dependency inversion. v2 splits L4 into L4a
  (shared UI policy core owning the rendering port) and L4b (target adapters
  implementing it over L3). L7 is a delivery plane, not a runtime tier.
- The existing `xylem-desktop` crate mixes L3 host code with L4a consumption;
  recorded as a gap/interface request, not changed.
- `xylem lint` only enforces style rules W7001–W7004; architecture enforcement
  is an L7 design item, not a shipped capability.
- Compiler-owned L0/L1, benchmark harness and performance certification remain
  protected; no performance numbers were asserted.

## Lotus assessment (added 2026-11-25)

Read-only study of `/home/philip/Development/lotus` at `5577f76` produced
`DESIGN/LOTUS_PORT.md`. Finding: Lotus's L0/L1 are a domain-neutral platform
kernel and its L2–L7 are application-owned — a different namespace from Xylem
D-001 v2. Proposed amendment: split Xylem L2 into L2a (host capabilities) and
L2b (Lotus kernel contracts/pure logic with host-injected adapters), and name
each product's internal Lotus-style layers `<product>.A2..A7`. Three porting
options recorded; owner selected Option A (contracts/port), recorded as D-005.
The layer amendment introduces L2a/L2b and product-local `A2..A7` namespaces.
Execution is explicitly deferred until the protected compiler campaign reaches
maturity and demonstrated C-level performance; no porting work is authorized.
No Lotus file was modified (its uncommitted `lotus-docs` changes were left
alone).

## Lotus contract phase started (owner decision, 2026-11-25)

D-005 was amended from a compiler-performance gate to capability-based gating;
the contract phase is authorized. Four isolated worktrees were opened from
`integration/ecosystem-readiness` with fixed shared APIs:

- `task/ecosystem/lotus-core` — contract IDs, refusal envelope, version negotiation.
- `task/ecosystem/lotus-capability` — closed capability catalog, manifest validation.
- `task/ecosystem/lotus-logic` — pure graph/workflow/audit/evidence rules.
- `task/ecosystem/lotus-schemas` — JSON schemas, fixtures, stdlib-only validator.

Scope is strictly contracts/pure logic at L2b. No host adapters, SQLite/HTTP/
WASM/threads, no compiler changes, no performance claims. Lotus revision
`5577f7660048be268bb0007cb212083af44b93eb` is the pinned reference spec.

## Lotus contract phase verification (2026-11-25)

All four L1–L4 work orders were independently reproduced with the exact pinned
compiler (`7082acd9…`, SHA-256 confirmed in-tree) and merged. A004 reconciled
L1's refusal envelope with L4's canonical `lotus.refusal/v1` schema: codes
mapped to `UMS-REF-0009` / `UMS-REF-0048`, added `context` and `remediation`,
deterministic UUID-shaped correlation IDs, and `major >= 1` parser alignment.

Reproducible gate: `ecosystem-readiness/tools/verify_lotus_contract_phase.sh`
reported `RESULT: PASS` with 9 Xylem contract modules, 9 passing Xylem tests,
`xylem test lotus` = `9 passed, 0 failed`, and the stdlib-only validator =
`OK: 6 schemas, 18 fixtures, 6 contracts verified` plus 17 validator tests.

Compiler defect `XY-003` (leading `||` on a continuation line parsed as an empty
closure, `E3004`) was independently reproduced with the pinned compiler and
handed over; no compiler file was edited.

Remaining goal coverage was completed on `task/ecosystem/lotus-completion`:
added `plugin.xy`, 6 additional schemas and 18 additional fixtures. Final
integrated tree: 10 contract modules, 12 schemas, 36 fixtures; `xylem test lotus`
= `10 passed, 0 failed`; validator = `OK: 12 schemas, 36 fixtures, 12 contracts
verified`; 17 validator tests pass; `RESULT: PASS` from the phase harness;
all five doc gates pass. Final pushed head `f89d589` (local == remote),
protected-path diff count 0.

## L2b ports and platform consumer (2026-11-25)

Implemented four versioned host-injected port interfaces in Xylem source:
storage (`lotus.storage/v1`), clock (`lotus.clock/v1`), rng (`lotus.rng/v1`)
and transport (`lotus.transport/v1`). Each injects an effectful function value
and carries a canonical `contract_id`; no host intrinsic or Rust Lotus runtime
is used. `lotus/tests/p1_ports.xy` verifies all four with deterministic stubs.

Added `examples/lotus-web-consumer/`, an L5 web-side product that reads a
version string through the injected storage port, negotiates it via the versioned
Lotus contract, and handles an unknown major with `UMS-REF-0009`. Pinned-compiler
run matches expected output byte-for-byte; example validator now covers 8 apps /
241 checks. Final verification: phase harness `RESULT: PASS`, all five doc gates
pass, `xylem test lotus` = `11 passed, 0 failed`, 12 schemas / 36 fixtures verified.
Pushed head `47296aa` (local == remote), protected-path diff count 0.

## All four platform families verified (2026-11-25)

Added pinned-compiler-verified consumers for the three missing families,
importing the same versioned Lotus contracts and injected ports:
`lotus-server-consumer` (storage + transport), `lotus-desktop-consumer`
(storage + clock, fixed tick 1234), `lotus-mobile-consumer` (storage + RNG,
fixed draw 42). Each proves accepted `lotus.plugin/v1` and refused
`lotus.plugin/v9` with `UMS-REF-0009`, with byte-exact expected output.

Final verification: example validator 11 apps / 331 checks; `xylem test lotus`
11 passed / 0 failed; validator 12 schemas / 36 fixtures / 12 contracts;
phase harness `RESULT: PASS`; all five doc gates pass; protected-path count 0.
Pushed head `c395ca9` (local == remote, after one transient GitHub 500 retry).
No OS/GPU/network/SDK functionality, Rust Lotus runtime or performance claim.

## Full native crate port authorized (owner, 2026-11-25)

Owner confirmed: port everything from Lotus that can be implemented in Xylem
source. D-005 amended from "all four families verified" to FULL NATIVE CRATE
PORT IN PROGRESS. Five isolated work orders opened with distinct file ownership:
C1 core (namespaced IDs, refusal registry, version helpers), C2 application
(capability requirements, plan resolution, target validation), C3 pure logic
(graph/workflow/audit/evidence full behaviour), C4 ops/catalog/supply-chain
(bounded logger, registry, SBOM/policy models), C5 runtime/engine/SDK
composition. Rules: no Rust Lotus runtime, no protected compiler edits, no Cargo
changes, no performance claims, no duplication of Xylem toolchain/UI/CLI/LSP/
distribution; host-bound backends remain deferred behind the L2b ports. The
verification harness now counts both `lotus/contracts/*.xy` and new
`lotus/modules/*.xy`.

## Full native crate port: first three squads integrated (2026-11-25)

C1 (core): full namespaced-ID grammar, refusal registry/severity/remediation,
public correlation helper, strict parse accessors, `is_supported`.
C2 (application): capability requirements, plan/provider resolution, target
validation with explicit wasm/browser refusal.
C5 (composition): runtime context, forward-only engine lifecycle/hooks, SDK
facade/version check.

All reproduced with the pinned compiler and merged. `xylem test lotus` =
`14 passed, 0 failed`; phase harness `RESULT: PASS`; pushed head `679c025`
(local == remote). C3 (graph/workflow/audit/evidence) and C4 (ops/catalog/
supply-chain) still running.

## In-house skills and coding conventions program (owner, 2026-11-25)

Owner requested opinionated coding conventions and a comprehensive agent skills
catalogue to prevent maintainable-code regressions like the compiler's repeated
architecture churn. All outputs must live in the project's own library
`xylem-lang/.agents/skills/` — not in the harness or campaign folder — and must
be prescriptive (MUST / MUST NOT / DEFAULT TO) with checkable completion criteria
and primary-source citations. Four research squads are writing twelve skills:
orientation/code-style/module-layout (S1), api-design/ports/lotus-kernel (S2),
testing/performance-guardrails/review (S3), app-archetypes/documentation/
agent-workflow (S4). The canonical `INDEX.md` will be updated by A004 after
review; existing compiler/performance skills remain authoritative for their areas
and are referenced rather than duplicated.

## In-house skill library consolidated (2026-11-25)

The 77-skill engineering pack supplied at `xylem-agent-skills/` was copied into
the canonical in-house library `xylem-lang/.agents/skills/`, joined by the 12
platform skills authored here and the 17 pre-existing compiler/quality skills:
106 skills total. A unified `SKILL-CATALOG.md` and extended `validate.py` were
added; `install.py` was retargeted to `.agents/skills`; repository `AGENTS.md`
gained a condensed routing table. An accuracy pass resolved 174 local references
to 0 unresolved. Validator: `Validated 106 skill files; 0 errors`. All five doc
gates, example validator and Lotus harness pass. Pushed `f2e46ae`.

## High-quality app delivery skills (owner objective, 2026-11-25)

New active objective: write skills that enable agents to design, write, build
and compile high-quality Xylem applications through strict, rigorous,
opinionated delivery. Two work orders are authoring six in-house skills:
`xylem-app-research`, `xylem-app-design`, `xylem-app-implementation` (A) and
`xylem-app-build`, `xylem-app-verification`, `xylem-app-delivery` (B). All must
live in `xylem-lang/.agents/skills/`, use MUST/MUST NOT/DEFAULT TO rules,
checkable exit evidence and cited primary sources, and point to existing
specialist skills rather than duplicating them. The unified catalog, validator,
INDEX and AGENTS routing will be updated after review.

## Skill installation scope (owner decision, 2026-11-25)

Owner confirmed skills remain installed only in the integration worktrees
(xylem-lang `af74c1f`, xylem-rust `876d0a0`, xylem-platform `02ea426`, 112 skills
each). The main working trees have large pending deletion sets (xylem-lang 222
files including `.agents/skills/`; xylem-rust 112 files including `AGENTS.md`),
so they were deliberately left untouched. The canonical source remains
https://github.com/Botanode/xylem-agent-skills.

## Active objective: Lotus → Cedar → Orchid (owner, 2026-11-25)

Owner directive: finish porting Lotus, then port Cedar and Orchid (both L6
applications built on Lotus). Skill gate enforced: every port work order must
read and apply the in-house app-delivery, Lotus-kernel, API-design, modular
design and workflow skills from the worktree, and cite them in final reports.
Pushed Lotus integration head `c37ed68` with `xylem test lotus` = 20 passed /
0 failed. Cedar and Orchid are being mapped into product-local `A2..A7` before
first-slice implementation; host-bound backends remain deferred.

## Cedar Phase 1 work order opened (2026-11-25)

CEDAR_PORT.md (design-only, skill-gated) recommends Phase 1 =
`cedar.A2+A3+A4`: USIL 0.1 lossless parse → canonical model → SHA-256 fingerprint
→ immutable revision with lineage/approval → requirement→criterion→verification
map, with nine named negative fixtures and byte-exact expected output. Isolated
worktree `task/ecosystem/cedar-phase1` opened; implementation must apply the
app-delivery and Lotus-kernel skills, import L2b contracts/ports by relative path,
copy no proprietary Cedar source, and prove non-vacuity with mislabelled/wrong-$id
fixtures. No host adapters (git, sandbox, Tauri, GraphQL) in this phase.

## Lotus port complete (2026-11-25)

All six remaining Lotus subsystems ported and integrated: store, events,
service/RPC contracts, plugin host, advisory/provenance, and graph/workflow
depth. Final verification: `xylem test lotus` = **22 passed, 0 failed**; phase
harness `RESULT: PASS`; validator 12 schemas / 36 fixtures / 12 contracts;
all five documentation gates pass. Pushed xylem-lang `b2ad8e1`. The Lotus
kernel at L2b now covers contracts, ports and portable pure modules; host
adapters (SQLite/HTTP/WASM/process/clock/RNG implementations) and performance
claims remain deferred per D-005.

Three modular/plugin design skills (`xylem-modular-design`,
`xylem-plugin-architecture`, `xylem-extension-points`) were written, registered
and propagated. Validator: **115 skills, 0 errors** in xylem-lang (`b2ad8e1`),
xylem-rust (`dddefbd`), xylem-platform (`4af6051`) and canonical repo
(`eccf54d`).

Per the active objective (Lotus → Cedar → Orchid), Phase 1 work orders are open
for Cedar (`cedar.A2..A4`: USIL → revision → requirement/test map) and Orchid
(`orchid.A2..A3`: schema-v3 document → typed operations → revision/history).
Both are skill-gated and import the completed L2b kernel rather than duplicating
it. No Cedar/Orchid source text or license was copied.

## Three-port sequence complete; compiler-support work started (2026-11-25)

Lotus, Cedar and Orchid Phase 1 are integrated into xylem-lang
`integration/ecosystem-readiness`: Lotus at L2b (contracts, ports, modules),
Cedar Phase 1 under `apps/cedar` (USIL → revision → requirement/test map,
13 tests), Orchid Phase 1 under `apps/orchid` (schema-v3 document → typed
operations → revision/history, 2 tests). All pinned-compiler runs pass and all
byte-exact expected outputs match. All three are original reference
implementations; no Rust Lotus/Cedar/Orchid source, license text or host
adapter was imported.

Compiler-support work (allowed adjacent scope, no protected compiler edits):
- `ecosystem-readiness/tools/sweep_ecosystem.sh` — one-command regression sweep
  over corpus, Lotus, 11 examples, both app ports, five doc gates and skills.
- `ecosystem-readiness/tools/compiler_surface_report.py` — deterministic
  `check --json` surface report (modules/functions/diagnostics) for 13 workloads
  with pinned artifact hashes; explicitly not a benchmark.
The sweep immediately found and fixed a real missing `allocation` effect in
`examples/text-stats/tests/stats.xy`; final sweep `PASS=23 FAIL=0`, compiler
surface `13 workloads, 0 failing`.

## Compiler-support evidence added (2026-11-25)

Ran the whole independent conformance corpus against the pinned compiler:
`selected 31, PASS 31, FAIL 0, SKIP 0`; full per-case evidence in
`ecosystem-readiness/reports/conformance-full.json`. All 31 cases promoted to
`IMPLEMENTED`; `validate_corpus.py` reports `CORPUS VALIDATION OK`. Pushed
`dfe85af` (local == remote); protected-path diff count remains 0.

This gives the compiler team a 31-case black-box diagnostic baseline, the
24-gate ecosystem sweep and a 13-workload deterministic compiler-surface report.
No benchmark, performance claim or protected compiler edit was involved.

## Cedar/Orchid Phase 2 work orders opened (2026-11-25)

Per the active objective, the full ports continue beyond Phase 1:
- Cedar Phase 2 (`cedar.A5`) — spec/plan → requirement assessment against L2b
  evidence through injected ports; closed verdict vocabulary and waivers; negative
  fixtures for missing/stale evidence, waiver defects and separation of duty.
- Orchid Phase 2 — statically registered plugins using `lotus.plugin/v1` and the
  L2b plugin host; deterministic registry, capability broker, negative fixtures
  for duplicate ids, major v9, malformed ids, unknown capabilities, ambiguous
  providers and untrusted privileged requests.

Both are isolated worktrees, additive-only under their app directories, skill-
gated, and required to keep Phase 1 byte-exact outputs unchanged. No host adapters,
dynamic loading, network/GPU, or performance claims.

## Cedar Phase 2 complete (2026-11-25)

Cedar Phase 2 (`cedar.A5`) integrated and pushed at `7528588`: closed verdict
vocabulary, evidence assessment through an injected port, waivers with exact
requirement/revision/policy binding and assessor≠approver, 14 new negative and
byte-exact fixtures. `xylem test apps/cedar` = **28 passed, 0 failed**; Phase 1
report and all 12 Phase 1 fixtures remain byte-exact. No host adapters, network,
real clock/RNG, new refusal codes or performance claims. Orchid Phase 2 still in
flight; after it lands the full ecosystem sweep will be re-run and promoted.

## Cedar/Orchid Phase 3 work orders opened (2026-11-25)

- Cedar Phase 3 (`cedar.A6`): pure SDK/CLI facade over existing Xylem commands
  (`xylem check`, `xylem test`, `xylem lint`), a versioned stable operation map
  and byte-exact facade report. No second CLI/LSP/build system.
- Orchid Phase 3: sequential, statically defined graph/workflow reusing L2b
  graph contracts, with deterministic topological order, cycle/dangling-edge
  refusal, pure step budgets and checkpoint/resume through the injected storage
  port. No threads/timers/network/dynamic execution.

Both are isolated, additive-only, skill-gated and required to preserve all
Phase 1 and Phase 2 byte-exact outputs. Full sweep currently PASS=24 FAIL=0,
pushed `5e8b48d`; compiler surface covers 15 workloads with 0 failures.

## Cedar Phase 3 complete (2026-11-25)

Cedar Phase 3 (`cedar.A6`) integrated and pushed at `ec79ab7`: versioned
`cedar.sdk/v1` facade, closed operation map, static command map naming only
existing Xylem commands, byte-exact facade fixtures and refusals for unknown
operations/commands. `xylem test apps/cedar` = **38 passed, 0 failed**; all
Phase 1 and Phase 2 outputs remain byte-exact. No second CLI/LSP/build system,
host adapters or performance claims. Orchid Phase 3 still in flight.

## Cedar/Orchid Phase 4 work orders opened (2026-11-25)

- Cedar Phase 4 (`cedar.A7`): pure L4a-shaped view projections of Phase 1-3
  results, with explicit capability-negotiation diagnostics for unmappable
  elements. No rendering, DOM, GPU, host adapter or second UI model.
- Orchid Phase 4: session/ACL/audit mappings as pure logic using L2b audit and
  storage port; deny-by-default grants, tenant isolation, deterministic fixed
  epoch, opaque secret ids; no real auth provider, crypto, network or host.

Both are isolated, additive-only, skill-gated and required to preserve Phase 1-3
byte-exact outputs. Baseline: full sweep PASS=24 FAIL=0, compiler surface 16
workloads / 0 failures, pushed `b0e825b`.

## Cedar Phase 4 complete (2026-11-25)

Cedar Phase 4 (`cedar.A7`) integrated and pushed at `ef570f1`: versioned
`cedar.view/v1` seam producing deterministic L4a-shaped view data with typed
capability diagnostics (UI-012/014/017) for unmappable elements, no second UI
model or renderer. `xylem test apps/cedar` = **47 passed, 0 failed**; all Phase
1-3 byte-exact outputs preserved. Cedar's documented phases 1-4 are now ported;
host adapters and real UI rendering remain deferred. Orchid Phase 4 in flight.

## Orchid Phase 5 work order opened (2026-11-25)

Orchid's final documented phase — thin SDK facade — is in an isolated worktree.
It adds a versioned `orchid.sdk/v1` operation map delegating to Phases 1-4, a
static command map limited to existing Xylem commands, and byte-exact fixtures.
No second CLI/LSP, host adapter, dynamic loading, network/GPU or performance
claim. All Phase 1-4 reports must stay byte-exact. Baseline: sweep PASS=24
FAIL=0, compiler surface 17 workloads / 0 failures, pushed `4ff9cc3`.

## Full port prerequisite complete; compiler support ongoing (2026-11-25)

All documented application phases are now ported and integrated:
- Cedar Phases 1-4 (`cedar.A2..A7`): USIL/revision/map, evidence assessment and
  waivers, facade, L4a view projections. `xylem test apps/cedar` = 47 passed / 0.
- Orchid Phases 1-5: document/dispatch/history, static plugins, sequential
  graph/workflow, session/ACL/audit, SDK facade. `xylem test apps/orchid` = 7
  passed / 0.
The native/host backends (SQLite, HTTP, WASM, GPU, process, Tauri, GraphQL, git
worktrees) remain explicitly deferred as host adapters.

Compiler-support work continues with no protected edits: 24-gate ecosystem
sweep, 18-workload deterministic compiler-surface report, 34-case full
conformance run (all PASS) including three new effect-row cases (E4001 local and
transitive, accepted when declared). Pushed `cbca25b`; protected-path diff 0.

## Ecosystem inventory + diagnostic drift tool (2026-11-25)

Ready (no new host capability): further Lotus behaviour depth is exhausted — the
remaining Lotus work is host-bound; Xylem web-framework modules, platform product
adapters, and the ESLint/Biome-style linter extension are designed but unbuilt.

Blocked (need SDK/authorization): Cedar Tauri/GraphQL/git-worktree/sandbox/
external-agent/release JSON (`CEDAR_PORT.md:111-120`); Orchid GPU/WASM/threaded
runners/TCP-filesystem/registry/bench/CLI hosts (`ORCHID_PORT.md:141-152`).

Built `ecosystem-readiness/tools/diagnostic_drift.py`: compares two
`run_corpus.py` reports for case/status/diagnostic-code/stdout/exit drift.
Self-comparison of the 34-case baseline: `drift findings: 0`, `RESULT: NO_DRIFT`,
exit 0. Negative control (3-case report vs 34-case baseline): 33 drift findings,
exit 1. Baseline stored at `reports/conformance-baseline.json`.

## Xylem web framework implementation opened (2026-11-25)

Owner wants an Aurelia-2-feeling Xylem web framework with better WASM-backed
performance: `.html`/`.xylem` component pairs, lifecycle hooks, two-way binding
modes, convention over configuration, plugin-centric services, modular design.
Two isolated work orders with a fixed shared API:
- `task/ecosystem/web-framework-core` — framework modules (`component`,
  `services`, `router`, `app`) and black-box tests.
- `task/ecosystem/web-framework-app` — example app with component pairs, L7
  pair/binding checker, routes, services and byte-exact fixtures.
Rules: reuse L2b contracts, L4a as sole UI model, numeric WASM ABI, no VDOM,
no HTML parser, no hydration, no JS runtime, no performance claims.

## Capability-gating policy (owner, 2026-11-25)

Owner directive: do not wait for compiler performance work. Build every
prerequisite that the pinned compiler and current L4a/web contracts already
support; record genuine capability gaps as DEFERRED and continue independent
work. No performance claim may depend on the protected benchmark campaign.
Current deferred list for the web framework: no browser HTML/CSS/DOM, no
hydration, no dynamic component-private state, no general HTML parser; these are
design boundaries, not blockers. Missing compiler capabilities are recorded in
the relevant design doc / phase log when encountered, never silently worked
around.

The L4a adapter work order (`task/ecosystem/l4a-adapter`) is building the
`.view` -> `UiDocument` generator that feeds the existing `xylem web build --ui`
path.

## Xylem web framework prerequisites complete (2026-11-25)

The Aurelia-like Xylem web framework path is implemented and verified:
- framework core (`framework/web/{component,services,router,app}.xy`) with binding
  modes, eight lifecycle phases, static services and declarative routing;
- example app (`examples/web-framework-aurelia/`) with `.xylem`/`.view` pairs,
  lifecycle traces, plugin, routes, L7 checker and byte-exact fixtures;
- L4a adapter (`framework/web/tools/emit_l4a.py`) emitting bare `UiDocument`
  for the existing `xylem web build --ui` path (11 Python tests pass);
- build orchestrator (`framework/web/tools/build_web.py`) that prepares, never
  executes, the web build (plan status PREPARED, build_executed false);
- `xylem-web-framework` skill registered across canonical repo and all three
  repositories (116 skills, 0 validator errors), with token-first styling rule.

Verification actually run: pinned framework test 1 passed; web example test 1
passed; L4a tests 11 passed; component checker PASS + five typed negative
fixtures; full ecosystem sweep 28 PASS / 0 FAIL; compiler-surface report 20
workloads / 0 failures; five documentation gates pass. Pushed `34d3320`
(local == remote). Protected-path diff remains 0.

DEFERRED: browser HTML/CSS/DOM, hydration/SSR, general HTML parser, dynamic
component-private state, raw CSS/media queries/animations, Canvas scene
authoring, non-Click runtime behavior, and all performance measurement.

## Tooling language rule and live benchmark TUI (2026-11-25)

Owner directive: **never build anything in Python**. A briefly drafted Python
benchmark-TUI prototype was removed; no Python replacement was kept. New
tooling is written in Xylem source. (Earlier campaign Python validators remain
as pre-existing artifacts; their removal needs an owner decision.)

New work order `task/ecosystem/bench-tui` builds a live benchmark progress TUI
entirely in Xylem under `tools/bench-tui/`: staged Run/Stage model, JSONL event
logging via `append_text`, ANSI dashboard with progress/elapsed/ETA, simulation
mode, and authorization-gated real plan runner using `std/process::spawn` +
`wait_timeout`. Byte-exact `--once --no-color` fixtures and refusal evidence are
required. No benchmark execution in verification.

## Developer tooling expansion (2026-11-25)

Owner asked for Vite/HMR-like tooling and cross-target build support. Two new
Xylem-only work orders (D-007) opened:
- `task/ecosystem/dev-server` — loopback dev server, polling mtime watcher,
  server-side HMR signaling, deterministic `--once` fixtures; browser client
  hookup explicitly DEFERRED.
- `task/ecosystem/target-matrix` — closed target registry, honest build plans for
  web/linux-native and DEFERRED desktop/mobile targets, env-only doctor,
  unified-target matrix. No build execution or performance claims.

Both are isolated, additive-only under `tools/<name>/`, skill-gated, and must
pass pinned-compiler check/run/test with byte-exact fixtures. Bench TUI work
order (`task/ecosystem/bench-tui`) is still in flight; all three remain
PENDING_INDEPENDENT_VERIFICATION until parent reproduction.

## Host measurement window — source only (owner, 2026-11-25)

Owner confirmed benchmarks are running NOW. All in-flight agents were told to
STOP executing pinned-compiler checks, builds, tests, servers, sweeps and
validators. Only Xylem source, fixtures and docs may be written. Nothing new is
merged or pushed while unverified. D-007 strengthened: every development tool is
Xylem-only, with a staged migration plan for earlier Python/Bash artifacts.
Resume verification only after owner confirmation that the window is closed.

## Testing platform work orders opened (2026-11-25)

Owner noted the existing test surface is not a proper framework. Two isolated,
Xylem-source-only work orders (D-007, host measurement window active):
- `task/ecosystem/test-platform-core` — declarative test plan model, plan parsing
  and human/JSON reporters; unit cases orchestrate existing `xylem test`.
- `task/ecosystem/test-platform-cli` — bounded runner, target adapters for
  unit/native/web/desktop/mobile with env-gated authorization, `run/list/
  doctor/targets` CLI, dry-run mode.
Both are additive under `tools/test-platform/`, no verification, no merge/push,
and all claims `IMPLEMENTED / PENDING_VERIFICATION`.

## All developer-tool work orders source-complete (2026-11-25)

Held in isolated worktrees, all `IMPLEMENTED / PENDING_VERIFICATION`, no merge,
push, compiler check, build, test, server or benchmark executed:

| Worktree | Tool |
|---|---|
| `task-bench-tui` | live benchmark TUI (Xylem source; ANSI dashboard, gated runner) |
| `task-target-matrix` | cross-target planner (web/native LIMITED, desktop/mobile DEFERRED) |
| `task-dev-server` | loopback dev server + mtime watcher + server-side HMR signal |
| `task-test-platform-core` | test plan model, zero-config discovery, human/JSON reports |
| `task-test-platform-cli` | `xe` one-command runner, gated e2e adapters, doctor |
| `task-quality-gate` | fmt → lint → check → test orchestrator with dry-run + JSON |
| `task-lint-extensions` | W7010–W7015 Xylem lint rules + JSON rule config |

D-007 governs: all tools Xylem source only. Earlier Python/Bash artifacts are
deprecated with a staged migration plan. Source-only reconciliation applied to
the test platform CLI: `discover` imported from core `plan.xy`, duplicate import
removed, README assumptions updated.

## PENDING

- Owner rulings: server-runtime name, `xylem-desktop` collision, packaging
  layout, and whether web primitives become a named package.
- Port identity formats (`RenderPortV1`, state-layout descriptor), SSR port,
  mobile permission/lifecycle mapping, accessibility ownership contracts.
- SDKs/devices/signers for macOS, Windows, iOS, Android (WL-63–WL-67).
- All status tags remain `PENDING_INDEPENDENT_VERIFICATION` until reproduced;
  no implementation is authorized by this phase.
