# Cedar port assessment — design only

Status: `SPECIFIED_NOT_IMPLEMENTED` — direction only; implementation needs a separate, owner-authorised work order.
Date: 2026-11-25
Reading basis: Cedar at `43e238ce8b322a44810eaaaa65b9906b41ccc3a9` (clean, read-only).
No Cedar or Xylem source, pin, toolchain or CI file was modified.

Citation prefixes: `[C]` = `/home/philip/Development/cedar/`; `[X]` = `/home/philip/Development/version_2/`;
`[XL]` = `/home/philip/Development/version_2/ecosystem-worktrees/xylem-lang/` (the
`integration/ecosystem-readiness` worktree); `[S]` =
`/home/philip/Development/version_2/ecosystem-worktrees/xylem-lang/.agents/skills/`.

**Skill gate applied** — in-house library at `[S]`: `xylem-app-research/SKILL.md:30-38`
(claim/evidence table), `xylem-app-design/SKILL.md:10-24` (acceptance criteria first),
`xylem-app-delivery/SKILL.md:23-40,71-78` (seven gates + ledger),
`xylem-platform-orientation/SKILL.md:36-75` (product-local placement),
`xylem-agent-workflow/SKILL.md:25-59` (ownership, independent verifier).

## 0. Framing and placement record

Cedar is an **application**, not a platform component: it "owns the engineering
domain and its product surfaces" and "relies on the Lotus kernel" without forking
or absorbing it (`[C]README.md:24-27`). It is **L6** (`[X]docs/decisions/D-001-platform-layering.md:31,55`).
Its own L2–L7 numbering (`[C]docs/architecture.md:7-18`) collides with Xylem's
global stack, so application-owned layers are renamed `cedar.A2..A7`
(`[X]docs/decisions/D-005-lotus-port-strategy.md:161-186`;
`[S]xylem-platform-orientation/SKILL.md:70-75`).

Design record per D-003 §1 (`[X]docs/decisions/D-003-platform-app-conformance.md:14-17`):

- **Layer / downward deps:** L6; only L2b versioned contracts and host-injected
  ports, plus the L4a UI port for view projections. Never L0/L1/L3, sibling
  adapters or a Rust Lotus runtime (`[X]D-001:46-56,72-84`; `[X]D-005:188-203`).
- **Plugin boundary map:** Cedar providers implement Xylem-owned ports; each
  boundary carries `family/vN`, `api_version`, capabilities and an explicit
  lifecycle/error path (`[X]docs/decisions/D-002-plugin-centric-platform.md:34-65`;
  `[S]xylem-platform-orientation/SKILL.md:55-69`).
- **Data ownership:** Cedar Domain A writes USIL/revisions, Domain C work,
  Domain D verdicts/candidates; the kernel owns evidence records and applicability
  (`[C]docs/architecture.md:35-44`).
- **Out of scope:** everything in §3, plus all performance certification.

Cedar is proprietary (`[C]docs/license-decision.md:3-11,23-27`; `[C]Cargo.toml:29`):
we write original reference implementations of contract identities and observable
behaviour only — never Cedar source, fixture wording or `LICENSE` text. No Rust
runtime, host adapter, performance claim or BLAKE3 equivalence is imported.

### Research gate: claim/evidence table (mandatory artifact)

Acceptance criteria (consumer-level, each fixture-checkable; no performance
claim): **AC-1** a reviewer can place every Cedar layer at L6/`cedar.A2..A7` with
only downward edges; **AC-2** no contract already owned by L2b is redefined;
**AC-3** USIL parse → canonical fingerprint → immutable revision → requirement→test
map is reproducible from pinned inputs; **AC-4** an agent run stays a claim, never
a verdict; **AC-5** first-slice fixtures produce byte-exact reports and named
refusals under the pinned compiler; **AC-6** the port copies no proprietary source
and makes no performance claim.

| ID | Claim | Label | Evidence (`file:line`) | Acceptance criterion served | Contradiction / action |
|----|-------|-------|------------------------|-----------------------------|------------------------|
| C-1 | Cedar is an L6 application relying on the kernel, not a platform component | VERIFIED | `[C]README.md:24-27`; `[X]D-001:31,55` | AC-1 | none |
| C-2 | Cedar's internal L2–L7 must be renamed `cedar.A2..A7` | VERIFIED | `[C]docs/architecture.md:7-18`; `[X]D-005:161-186` | AC-1 | Cedar doc says it "owns its implementations of L2–L7"; D-005 namespace wins |
| C-3 | L2b already owns refusal/version/graph/evidence/plugin contracts and four injected ports | VERIFIED | `[XL]lotus/README.md:34-49,129-140`; `[XL]lotus/CONTRACT_CATALOG.md:3-16` | AC-2 | catalog still `PENDING_VERIFICATION` → no duplicate implementation |
| C-4 | Cedar fingerprint is BLAKE3; Xylem port substitutes SHA-256 | VERIFIED | `[C]crates/usdp-compiler/src/fingerprint.rs:12-29`; `[XL]lotus/README.md:100-101` | AC-3 | no byte-compatibility claim; note the digest explicitly |
| C-5 | An agent implementation result is a claim, never verification evidence or a verdict | VERIFIED | `[C]docs/architecture.md:290-294`; `[C]crates/usdp-verify/src/satisfaction.rs:1-8` | AC-4 | none |
| C-6 | Pinned compiler + byte-exact diff + named independent verifier are required for any PASS | VERIFIED | `[XL]toolchain.toml:2-13`; `[X]ecosystem-readiness/tools/verify_lotus_contract_phase.sh:7-58`; `[XL]AGENTS.md:58-62` | AC-5 | no fixture executed in this research → all results pending |
| C-7 | Porting must not import Cedar source or license, and Cedar's own release is not a port blocker | VERIFIED | `[C]docs/license-decision.md:23-27`; `[C]IMPLEMENTATION_STATUS.md:82-114` | AC-6 | Cedar release `NOT READY` is a fact about Cedar only |
| C-8 | Requirement→criterion→verification-step mapping exists as portable pure data | INFERRED | `[C]crates/usdp-engineering/src/spec.rs:113-120`; `[C]crates/usdp-engineering/src/plan.rs:119-143,154-180` | AC-3 | compile-derived inference; must be executed by a Phase 1 fixture |
| C-9 | This design has been independently reproduced | UNKNOWN / PENDING_INDEPENDENT_VERIFICATION | `[XL]AGENTS.md:58-62` | AC-5 | name a verifier in the work order |

## 1. Cedar domain model and stable contracts

| Concern | Stable contract / record (behaviour to preserve) | Authoritative writer | Portable identity / invariant | Citation |
|---|---|---|---|---|
| **Cross-domain read seams** | `ModelDto`, `RevisionDto`, `WorkflowDto`; `StorePort::get_revision/get_model`, `WorkflowPort::get_workflow` — reads only, never cross-domain writes | Application DTO layer | serde-serialisable shapes; `Result<_, Refusal>` on every read | `[C]crates/usdp-contracts/src/dto.rs:6-31`; `[C]crates/usdp-contracts/src/ports.rs:6-27` |
| **USIL intent** | Grammar `usil@0.1`, profile `architecture@0.1`; lossless source tree, spans, source map; canonical `SemanticModel` (type/enum/record/component/resource/relation/operation/requirement); `Fingerprint` | Domain A | Identity = `(namespace, declaration-kind, stable opaque ID)`; labels, order, layout, comments are **not** identity; every source byte preserved; canonical fingerprint over versioned domain separator + canonical bytes | `[C]docs/usil-reference.md:3,16-36,54-66`; `[C]crates/usdp-syntax/src/lib.rs:10-23`; `[C]crates/usdp-model/src/lib.rs:10-28`; `[C]crates/usdp-compiler/src/fingerprint.rs:12-29` |
| **Revisions** | `Revision`, `Publication`, `Lineage`, `Approval`, `DiffReport`, `RevisionService`, codec registry | Domain A | Immutable publication (no update/delete path); publication refused without fingerprint, namespace and source provenance; publisher cannot approve own revision; approval bound to exactly one revision; skipped/duplicate approvals refused; lineage survives store reopen | `[C]crates/usdp-revision/src/lib.rs:10-28,286-329,330-363,366-428,430-479,605-674`; `[C]docs/architecture.md:50-53` |
| **Work plans** | `EngineeringSpecification` (`usdp.engineering-specification/v1`) → pinned `RepositoryContext` → sealed `EngineeringPlan` (`usdp.engineering-plan/v1`) → `EngineeringTaskDraft` + `VerificationStep`; then `usdp-work` proposals/tasks/fenced claims/budgets/cycles | Domain E writes drafts; Domain C owns task lifecycle | Each requirement carries independently identifiable `AcceptanceCriterion` with a `VerificationMethod`; each task carries `requirement_ids`, `criterion_ids`, `required_verification` and a bounded budget; coverage/reference/dependency/staleness defects are closed codes `UMS-REF-0096`–`UMS-REF-0100`; a task draft is **not** a work record and completion is not acceptance | `[C]crates/usdp-engineering/src/spec.rs:5-9,84-97,113-120,143-211`; `[C]crates/usdp-engineering/src/plan.rs:23-45,119-143,154-180`; `[C]docs/architecture.md:144-159`; `[C]crates/usdp-work/src/lib.rs:10-30`; `[C]docs/user-guide.md:91-99` |
| **Agent runs** | Provider-neutral `CodingAgentProvider`, `AgentExecutionManager`, `ImplementationRequest`/`ImplementationResult`, execution states, budget, resume checkpoint, model channel grant | Domain E | Pins to spec revision, base commit, workspace and task; duration bound cancels and `resume` is a new attempt; claimed paths must stay inside allowed write prefixes; result is an **implementation claim**, never a verdict or acceptance evidence | `[C]crates/usdp-engineering/src/lib.rs:19-39`; `[C]docs/architecture.md:188-216,248-294` |
| **Evidence / verdicts** | Kernel-owned evidence records + applicability; Cedar-owned `VerdictMapper`, `Finding`, `Waiver`, `VerificationPolicy`, `RequirementAssessment`, `DeliveryCandidate`, `DeliveryDecisionRecord` | Kernel owns evidence/applicability; Domain D owns verdicts, findings, waivers, candidates, decisions | Closed verdict vocabulary `SATISFIED`/`NOT_SATISFIED`/`UNRESOLVED`/`INCONCLUSIVE`/`NOT_APPLICABLE`; satisfaction needs a finding **plus** evidence that is present, trusted, `IntendedModel`, and pinned to exact revision and policy — stale or code-derived evidence is `UNRESOLVED`; waivers are separate records, never `SATISFIED` | `[C]docs/verification-acceptance.md:7-29,35-45`; `[C]crates/usdp-verify/src/satisfaction.rs:14-21,33-73,110-132`; `[C]crates/usdp-delivery/src/lib.rs:10-20`; `[C]docs/architecture.md:35-44` |

## 2. Portable crate → `cedar.A2..A7` → existing Xylem consumer

`A2` = contracts/DTOs, `A3` = domain model/engine/state, `A4` = persistence
mappings, `A5` = application runtime/policy, `A6` = SDK/API/CLI, `A7` =
UI/deployment/conformance (`[X]D-005:179-186`). "Covered" means an L2b contract/module
or app-delivery skill already owns that behaviour: **do not duplicate it**.

| Cedar crate (behaviour only) | `cedar.A*` | Consume from Xylem (do not reimplement) | Already covered → new work |
|---|---|---|---|
| `usdp-contracts` | A2 | L2b `lotus.contract.id/v1`, `lotus.refusal/v1`, `lotus.contract.version/v1` (`[XL]lotus/README.md:34-49`); API design via `[S]xylem-app-design/SKILL.md:22-24` | **Covered:** versioned identity, refusal envelope, negotiation. **New:** Cedar-specific DTO field shapes and read-port signatures only |
| `usdp-syntax` | A3 | `[S]xylem-app-implementation/SKILL.md:14-24` pinned idioms | **Covered:** parser method, not grammar. **New:** USIL lossless tree/spans |
| `usdp-model` | A3 | L2b `lotus.graph/v1` for generic graph validation (`[XL]lotus/README.md:42`) | **Covered:** graph/edge checks. **New:** USIL declaration kinds, references, canonical model |
| `usdp-compiler` | A3 | L2b `contract_id`/`parse_contract_id` and closed refusal codes (`[S]xylem-app-design/SKILL.md:12`; `[S]xylem-platform-orientation/SKILL.md:55-61`) | **Covered:** boundary identity/refusals. **New:** phased validation, canonical encoding, fingerprint (SHA-256 with explicit note, no equivalence claim) |
| `usdp-revision` | A4 mapping + A5 policy | L2b `lotus.audit/v1`, host-injected `lotus.storage/v1` (`[XL]lotus/README.md:129-140`); `[S]xylem-evidence-and-claims` | **Covered:** audit chain, storage port. **New:** immutable revision, lineage, approval state machine, impact invalidation; deterministic in-memory stub only |
| `usdp-engineering` (spec/repo/plan subset) | A3 + A5 | `[S]xylem-app-research/SKILL.md:10-38`, `[S]xylem-app-design/SKILL.md:10-24` | **Covered:** research/design method. **New:** engineering spec, repository context, plan, requirement→criterion→verification map |
| `usdp-work` | A5 | L2b `lotus.workflow/v1` (`[XL]lotus/README.md:46`); `[S]xylem-agent-workflow/SKILL.md:25-59` for ownership/handover | **Covered:** workflow definition/state machine. **New:** Cedar proposal/claim/budget/cycle policy only |
| `usdp-verify` | A5 | L2b `lotus.evidence/v1`; `[S]xylem-app-verification/SKILL.md:23-83`, `[S]xylem-evidence-and-claims` | **Covered:** evidence records/applicability, verification protocol. **New:** Cedar verdict/finding/waiver mapping and `RequirementAssessment` |
| `usdp-delivery` | A5 | `[S]xylem-app-delivery/SKILL.md:23-40,71-78` seven gates + ledger; `[S]xylem-app-verification/SKILL.md:70-83` independent verifier | **Covered:** gate ordering, ledger, verifier rule. **New:** delivery-candidate/decision record shape only |
| `usdp-runtime` | A5 | L2b `lotus.workflow/v1`, `lotus.transport/v1`, `lotus.clock/v1` (`[XL]lotus/README.md:135-140`) | **Covered:** plan/run mechanics, dispatch ports. **New:** Cedar W3 loop glue with injected dispatch |
| `usdp-sdk` | A6 | `[S]xylem-platform-orientation/SKILL.md:36-53` | **Covered:** layering/API rules. **New:** thin facade over A2–A5; no second CLI/LSP |
| `usdp-cli` | A6 / L7 | Existing `xylem lint --json` catalog (`[X]D-003:31-43`) | **Covered:** lint/LSP/CLI infrastructure. **New:** at most Cedar-named commands extending existing tooling |
| `usdp-frontend` (pure views) | A7 | L4a `UiDocument` + rendering port (`[X]D-001:52-53`; `[X]D-002:13-21`) | **Covered:** L4a UI contract. **New:** text/graph/verification view projections only |
| `usdp-profile-api`, `usdp-edit` | A2 / A4 | L2b version negotiation; L4a document | Defer; keep edits typed and source-preserving |
| `usdp-conformance` | A7 | `[S]xylem-app-verification/SKILL.md:23-83`; L7 `PLT-*` direction (`[X]D-003:44-56`) | **Covered:** fixture/harness protocol. **New:** Cedar case register only |
| `usdp-graphql`, `usdp-agent-bridge` | — | — | **Host-bound — defer (§3)** |

Cedar's pinned git Lotus dependencies (`[C]Cargo.toml:37-46`) are **not** port
targets — they map to L2b contracts and injected ports.

## 3. Host-bound / deferred explicitly

1. **Tauri desktop shell** — `@tauri-apps/api` 2.12.4 (`[C]desktop/package.json:10,15,20`),
   built separately (`[C]README.md:41-48`); L4b adapter territory with the existing
   `xylem-desktop` name collision (`[X]ecosystem-readiness/docs/decisions/D-004-product-surface.md:34-44`).
2. **GraphQL server** — `usdp-graphql-server` on `async-graphql`/`axum`/`tokio`
   (`[C]crates/usdp-graphql/Cargo.toml:[[bin]]`); host HTTP adapter; Xylem's server
   runtime is `SPECIFIED_NOT_IMPLEMENTED` (`[X]D-004:15-16,28-30`).
3. **Git worktree execution** — `WorkspaceManager`/`LocalGitProvider`
   (`[C]docs/architecture.md:163-186`); OS filesystem/process adapter, a D-005
   non-goal (`[X]D-005:117-123`).
4. **Sandboxed command execution** — Bubblewrap mount/network namespace, refusal
   `UMS-REF-0123` when absent (`[C]docs/architecture.md:218-236,312-315`); no
   unsandboxed fallback.
5. **External coding agents** — concrete provider programs, model channel proxy
   (`[C]docs/architecture.md:248-286`; no vendor provider bundled,
   `[C]IMPLEMENTATION_STATUS.md:63-68`); external credential/process boundary.
6. **Release candidate JSON** — `release-candidate.json` and readiness records
   (`[C]docs/verification-acceptance.md:57-64`); generated L7 evidence, not an
   A-layer contract; new status document classes are forbidden (`[X]D-003:61-63`).

## 4. Strict delivery gates, phased order and first slice

The delivery ledger must have one row per gate — `gate | route skill | exit
criterion | artifact path | status | evidence ref | verifier | STOP?`
(`[S]xylem-app-delivery/SKILL.md:71-78`). Planned rows for this work order:

| Gate | Route skill | Exit criterion → artifact | Status now |
|---|---|---|---|
| 1 Research | `[S]xylem-app-research/SKILL.md` | Citation-backed claim table (§0) | ARTIFACT PRESENT; PENDING_INDEPENDENT_VERIFICATION |
| 2 Design | `[S]xylem-app-design/SKILL.md`, `[S]xylem-platform-orientation/SKILL.md` | Placement, downward edges, plugin map, AC-1…AC-6 → this document | ARTIFACT PRESENT; pending |
| 3 Implementation | `[S]xylem-app-implementation/SKILL.md` | Owned-path diff + app README; no pin/CI change | NOT RUN |
| 4 Build | `[S]xylem-app-build/SKILL.md` | Pinned hashes, bounded commands, artifact sha256 → build record | NOT RUN |
| 5 Verification | `[S]xylem-app-verification/SKILL.md` | Positive + negative byte-exact fixtures, named verifier → evidence table | NOT RUN |
| 6 Review | `[S]xylem-code-review/SKILL.md` | Findings dispositioned; no performance claim → review ledger | NOT RUN |
| 7 Integration | `[S]xylem-agent-workflow/SKILL.md` | Worktree/work-order ownership, A004 gate, `merge --no-ff`, recorded head | NOT RUN |

A gate with no artifact is `NOT RUN`, never PASS; a failed gate triggers STOP with
the command, exit code, hash and any `XY-NNNN` handover
(`[S]xylem-app-delivery/SKILL.md:38-69`; `[S]xylem-agent-workflow/SKILL.md:33-47`).

**Phase 1 — smallest credible slice (`cedar.A2` + `A3` + `A4` mapping): USIL
parse/validate + immutable revision + requirement→test map.** Land one coherent
end-to-end unit (`[S]xylem-app-implementation/SKILL.md:10-12`): (a) lossless parse
of `usil 0.1 / profile architecture@0.1 / namespace …`; (b) canonical model and
deterministic fingerprint (SHA-256 substitution noted); (c) publish an immutable
revision refusing missing fingerprint, namespace or source provenance, with parent
lineage and approval bound to the exact revision; (d) pure
requirement→criterion→`VerificationStep` map (`[C].../plan.rs:119-143`) emitted as
fixture output. In-memory injected storage stub only — no store, git, sandbox or
network adapter. This crosses one boundary (source bytes → canonical revision →
requirement/test map) and is checkable with the pinned compiler.

**Concrete negative fixtures and byte-exact oracles** (accept fixture `F-ACCEPT`
plus one negative per accepted shape; `[S]xylem-app-verification/SKILL.md:23-54`):

| Fixture | Stimulus | Required observable |
|---|---|---|
| F-ACCEPT | canonical USIL baseline | canonical fingerprint line, revision id, `R1 -> C1 -> BehaviouralTest`, `RESULT: PASS` |
| F-MAJOR | contract major `v9` | `UMS-REF-0009`, no published revision |
| F-ID | malformed stable id | `UMS-REF-0048` |
| F-FP / F-SRC | empty fingerprint / empty source bytes | `E-FINGERPRINT-UNSPECIFIED` / `E-SOURCE-PROVENANCE-CHANGED` |
| F-SELF / F-REBIND | publisher approves own revision / approval submitted for another revision | `E-SEC-SEPARATION-OF-DUTY` / `E-REFERENCE` |
| F-STALE | new fingerprint on parent, then old approval reused | approval invalidated; no `SATISFIED` |
| F-COVER / F-CYCLE | requirement with no criterion/verification; cyclic requirement dependencies | `UMS-REF-0099` / `UMS-REF-0098` |

Each fixture ships `expected-output/report.txt`; `diff -u expected-output/report.txt
actual.txt` must be clean for stdout, stderr and status, with no expected file
rewritten to follow a changed program (`[S]xylem-app-verification/SKILL.md:39-54`).
Non-vacuity is proven by a mislabelled fixture and a wrong `$id` being rejected
(`[S]xylem-app-verification/SKILL.md:31-34`). Verification runs under the pinned
bootstrap sha256 `7082acd9…` and backend host sha256 `2e2d75fb…`
(`[XL]toolchain.toml:2-13`), using bounded `check` → `test` → project gate →
consumer `run` and `RESULT: PASS` only when `fail == 0`
(`[X]ecosystem-readiness/tools/verify_lotus_contract_phase.sh:7-58`).

**Phase 2 (`A5`)** — spec/plan → requirement assessment against L2b evidence
through injected ports; closed verdict vocabulary and waivers. **Phase 3 (`A6`)**
— thin SDK/CLI facade on existing tooling. **Phase 4 (`A7`)** — pure view
projections through the L4a port. Each phase repeats all seven gates.

## 5. Non-duplication rules

1. **Skill library:** all skills live in the in-house library; no external pack is
   authoritative (`[X]docs/decisions/D-006-in-house-agent-skills.md:8-19`). Route
   through the six app-delivery skills; never take a forbidden shortcut
   (`[S]xylem-app-delivery/SKILL.md:42-60`).
2. **Agent workflow / ownership:** isolated branch, reviewed work order, exact
   owned paths, no second status/dispatch/briefing document
   (`[S]xylem-agent-workflow/SKILL.md:25-35,53-59`; `[X]D-003:58-64`). Self-produced
   evidence is never a PASS (`[XL]AGENTS.md:58-62`).
3. **Evidence and claims:** the kernel owns evidence/applicability; an agent result
   is a claim, not a verdict (`[C]docs/architecture.md:35-44,290-294`). Port verdict/
   finding/waiver policy only; never import a second evidence system or treat task
   completion as acceptance (`[C]crates/usdp-verify/src/satisfaction.rs:1-8`).
4. **Toolchain distribution:** no Cargo pin, Rust toolchain import, protected L0/L1
   edit, CI/deploy trigger or second CLI/LSP/distribution layer (`[X]D-005:28-38,117-123`;
   `[X]D-002:46-65`; `[S]xylem-platform-orientation/SKILL.md:77-85`). Release
   builds stay with the protected LLVM campaign (`[XL]AGENTS.md:25-33`).
5. **Licensing:** write original reference implementations of contracts/behaviour;
   do not copy Cedar source, fixture wording or license text, and claim no
   derivative-work right (`[C]docs/license-decision.md:23-27`).

## 6. Honest status / PENDING

- **Design only.** No port code written, no compiler command executed, no fixture
  run, no gate passed. All claims are `PENDING_INDEPENDENT_VERIFICATION`
  (`[XL]AGENTS.md:58-62`); gates 3–7 are `NOT RUN`.
- **No performance claims** of any kind; compiler maturity belongs to the
  protected campaign (`[X]D-005:125-150`). Cedar's `UMS-DEC-022` performance
  baseline (`[C]ADRS.md:30`) is unported.
- Xylem L2b catalog rows still read `PENDING_VERIFICATION`
  (`[XL]lotus/CONTRACT_CATALOG.md:3-16`); the `UMS-REF-* →` Xylem diagnostic-code
  mapping and exact identity namespace are open (`[X]D-005:229-236`).
- Cedar's own release is `NOT READY` on `UG-9`/`UG-10` and independent review is
  absent (`[C]IMPLEMENTATION_STATUS.md:82-114`); these are facts about Cedar, not
  inherited blockers. SHA-256 is the substitution digest; no BLAKE3 byte identity
  is asserted (`[XL]lotus/README.md:96-106`).
- A separate owner-authorised work order, reviewed `allowed_write_paths`, named
  independent verifier and isolated `task/ecosystem/<slug>` worktree are required
  before Phase 1 (`[S]xylem-agent-workflow/SKILL.md:25-31,49-59`). A pinned-compiler
  defect blocks the relevant fixture and becomes `DEFECT_HANDOVERS/XY-NNNN.yaml`
  with STOP (`[S]xylem-app-build/SKILL.md:68-80`;
  `[S]xylem-app-delivery/SKILL.md:62-69`).
EOF
wc -lw /home/philip/Development/version_2/ecosystem-readiness/DESIGN/CEDAR_PORT.md