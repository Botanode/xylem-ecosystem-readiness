# Lotus port assessment — design only

Status: SPECIFIED_NOT_IMPLEMENTED (direction accepted as D-005 Option A; implementation requires a separate work order)
Date: 2026-11-25
Owner: A004 cross-review
Sources: read-only study of `/home/philip/Development/lotus` at `5577f76`
(worktree has unrelated uncommitted `lotus-docs` changes; not touched).

## 1. What Lotus actually is

Lotus is a domain-neutral Rust **platform kernel**. It owns L0 primitives and
L1 platform services; each host application owns its own L2–L7 platform
(`lotus/README.md:5,19-29`; `lotus/docs/architecture.md:10-14,41-56`). It is
explicitly not an application framework and does not define a UI, domain model,
application runtime or deployment process. Reference `sdk → engine → runtime →
{plugin-host, graph, store}` composition is optional
(`docs/architecture.md:93-115`).

Kernel L0/L1 crates (20) cover: core IDs/versions/refusals/time/correlation;
application manifests and capability resolution; security; plugin API/host;
graph contracts/compiler/executors; workflow; events; store/audit; catalog;
evidence; ops; transport; runtime/engine/SDK foundations; advisory/supply-chain.
Four application-evidence crates (example platform, scaffold, CLI, bench) are
not platform authority (`docs/architecture.md:60-91`).

Stable contracts are versioned `lotus.<name>/v<major>` with JSON/JSON Schema
2020-12, WIT for plugins, and canonical JSON for store revisions
(`docs/contracts.md:27-140`). Unknown majors, malformed envelopes and ambiguous
providers are **refused explicitly**; no silent fallback or implicit upgrade.

## 2. The collision with Xylem D-001 v2

| Concern | Lotus | Xylem D-001 v2 | Consequence |
|---|---|---|---|
| L0/L1 | Lotus core primitives + platform services | Protected compiler substrate (ABI/IR/codegen/value model) | Lotus L0/L1 cannot be implemented at Xylem L0/L1 |
| L2–L7 | Application-owned domain → engine → state → runtime → SDK → UI/deployment | Xylem host capabilities → substrate → shared UI → frameworks → apps → developer plane | Number collision; pasting numbers would create two incompatible meanings |
| L7 | UI, deployment, release, conformance | Developer/delivery tooling plane | Different concerns with the same number |
| Ownership | Lotus never depends on application code | Xylem adapters never depend on sibling adapters; ports owned by abstraction owner | Compatible in spirit, but namespaces must be separated |

## 3. Portability findings

Portable as contracts/pure logic: contract identities and JSON schemas, refusal
envelope + `UMS-REF-*` registry (`lotus-ops/src/refusal-codes.csv:1-2,183`),
namespaced-ID grammar, closed 10-capability catalog
(`lotus-application/src/capability.rs:16-65`), manifest/plan validation, graph
model/compiler, workflow definition/state machine, audit hash chain, evidence
rules, telemetry snapshot shapes, advisory normalization/SBOM/policy models.

Host-bound (must stay adapters): SQLite/SeaORM + migrations + backups, tokio
threads and async bridges, HTTP/`ureq`/TCP, wasmtime and child-process plugin
frames, browser bridge, `Uuid::new_v4()`/`Utc::now()`, `/proc` memory sampling
(`lotus-store/src/store.rs:43-80,439-445`; `lotus-graph/src/worker.rs:195-220`;
`lotus-plugin-host/src/{wasm.rs,process.rs}`; `lotus-core/src/{ids.rs,correlation.rs}`).

Honest limits to preserve: native target only in the reference application;
WASM/browser are plugin boundaries, not verified app runtimes; no OS sandbox;
at-least-once only; no C ABI; host owns authN/policy/background coordination
(`docs/project-specification.md:257-294`; `docs/guides/bindings.md:95-107`;
`docs/architecture/application-platform-contract.md:493-497,670-708`).

## 4. Recommended layer amendment (D-001 v3 candidate)

Keep one global Xylem L0–L7 numbering, but split L2 and namespace each host
product's internal Lotus-style layers:

```text
L0/L1  protected compiler substrate                (unchanged)
L2a    Xylem host capabilities: fs/process/net/web  (unchanged L2)
L2b    Lotus kernel: contracts + pure algorithms + host-injected ports  [NEW]
L3     platform substrate: event loop/surface/device
L4a    shared UI policy core + rendering port
L4b    target UI adapters
L5     frameworks/services (web framework, server runtime)
L6     applications
L7     developer/delivery plane

Product-internal namespace: <product>.A2..A7
  A2 domain contracts/DTOs/adapters   A3 domain model/engine/state
  A4 persistence mappings             A5 application runtime/policy
  A6 SDK/API/CLI                      A7 UI/deployment/conformance
```

Rationale:
- L2b gives the Lotus kernel an explicit home **above** the protected compiler
  and **below** platform substrates; every L3–L7 product can consume it.
- Ports-and-adapters rule (D-001 v2 §5) is preserved: L2b owns contracts and
  pure rules; storage/transport/clock/RNG/WASM are host-injected adapters
  registered by L3/L7, not compiled into the kernel.
- Product-internal `A2..A7` layers are Lotus's application-owned stack without
  colliding with global Xylem layer numbers.
- `xylem-ui` remains the only UI contract (L4a); Lotus must not become a second
  capability/UI seam (D-002).

## 5. Porting options

### Option A — Contract/port, no Rust port (RECOMMENDED)
Port Lotus's stable contracts, capability catalog, refusal vocabulary, manifest
validation, graph/workflow pure logic and evidence patterns into Xylem source at
L2b; implement Xylem-owned L7 conformance checks (`PLT-*`) using Lotus's
executable-evidence template. Keep Rust crates as a *reference specification*
only. Pros: no duplicate runtime, no Rust/unsafe/dependency-policy import,
fits D-001/D-002/D-003. Cons: significant Xylem-source work; semantics must be
re-verified.

### Option B — Pin Lotus crates as a Rust dependency kernel
Consume `lotus-sdk` contract-only features from a pinned revision; use the
reference runtime/store/transport only where Xylem has no equivalent. Pros:
fastest path to the full service set. Cons: imports Rust 1.99.1 toolchain,
SeaORM/tokio/wasmtime/ureq and a second plugin/capability system; high risk of
competing with Xylem L5/L7 tooling; Lotus forbids `unsafe` and has its own
hardening/dependency gates that would need reconciling.

### Option C — Layer model only
Adopt the amended L2b + product `A2..A7` namespace and Lotus-style conformance
manifests, without porting Lotus services. Pros: cheap, resolves numbering and
governance. Cons: does not deliver the platform kernel the user asked for.

## 6. Module mapping (Option A)

| Lotus module | Xylem placement | Action |
|---|---|---|
| `lotus-core` (IDs, refusals, versions) | L2b | Port contract + vocabulary; reuse existing Xylem diagnostic codes where they cover the same role |
| `lotus-application` (manifest/capabilities) | L2b + L7 checker | Port manifest/plan validation; map capabilities onto D-002 plugin registry |
| `lotus-security`, `lotus-plugin-api/-host` | L2b + L3 adapters | Port contracts/lifecycle; no second UI/capability seam; host owns authN/policy |
| `lotus-graph`, `lotus-workflow`, `lotus-events` | L2b pure logic + L3/L5 adapters | Port contracts/compiler/state machine; execution adapters host-owned |
| `lotus-store`, `lotus-audit`, `lotus-evidence` | L2b ports + L3/L7 adapters | Port hash chain/evidence rules; storage backend via existing Xylem filesystem/streams |
| `lotus-ops`, `lotus-transport` | L7 tooling + L2b contracts | Port bounded schemas/refusal registry; do not duplicate Xylem CLI/LSP |
| `lotus-advisory`, `lotus-supply-chain` | L7 distribution | Map to our SBOM/manifest/compat checker; avoid duplicate version authority |
| example platform/scaffold/CLI/bench | L6/L7 evidence patterns | Port conformance patterns, not the crates; keep honest target matrix |

## 7. Gates and PENDING

- Owner selected Option A; recorded as `docs/decisions/D-005-lotus-port-strategy.md`.
  Implementation still requires a separate work order.
- Pending: exact contract identity namespace (`xylem.lotus.*` vs `lotus.*`),
  mapping of `UMS-REF-*` to Xylem diagnostic codes, whether support SQLite or
  only Xylem-native storage, host responsibility for clocks/RNG/WASM/process,
  and whether `A2..A7` conformance is enforced by L7 lint codes.
- No performance claims. Lotus's bench budgets are Rust-specific; Xylem
  correctness fixtures only, paired A/B belongs to the protected campaign.
- All facts here are `PENDING_INDEPENDENT_VERIFICATION` until executed.
