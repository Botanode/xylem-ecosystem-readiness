# Campaign status — final

Date: 2026-11-25. All claims below were independently reproduced by A004.

## Governance

| Item | Status |
|---|---|
| Protected ownership registry + integration gate | ESTABLISHED |
| Pinned compiler dependency + compatibility notes | ESTABLISHED |
| 100 deduplicated assignments | ESTABLISHED |
| Isolated integration worktrees (rust/lang/platform) | ESTABLISHED |
| `xylem-research` exclusion (active benchmark WIP) | ESTABLISHED |
| Tooling inventories (no duplicated tools) | COMPLETE |
| Spec disagreements register (7 items, for A003) | ESTABLISHED |

## Delivered work (13 agents, 2 iterations)

| Agent | Deliverable | Verification (reproduced) |
|---|---|---|
| E052 | 31-case independent YAML conformance corpus | validator PASS; 5 doc gates PASS |
| F064 | 11 developer guides + status tags | guide validator PASS; 5 doc gates PASS |
| G074 | 3 realistic example apps | structural validator PASS; **all 3 compiled/run with pinned compiler, outputs match byte-for-byte** |
| E051 | Bounded conformance oracle runner | 8 Python tests PASS; dry-run + real 5-case run PASS |
| I100 | 19 GPU-free layout/UI tests | 13 UI + 16 layout PASS (3 documented ignores) |
| I091 | GPU diagnostics + bounded cache | 9 mock + 1 headless-adapter tests PASS |
| H077 | Toolchain manifest + installer/rollback | 23/23 checks PASS |
| H082 | Deterministic SBOM + 13-identity compatibility checker | 7 tests PASS; 13/13 identities MATCH |
| D035 | `doctor`, completions, JSON `version` | check PASS; 7 + 9 tests PASS |
| D027 | `xylem init` + 4 templates | 9 init + 7 completions tests PASS |
| C024 | `FormatConfig` + preservation guards | 11 + 8 tests PASS |
| B016 | LSP encoding/lifecycle/JSON-RPC hardening | 9 protocol + 48 semantics tests PASS |
| B015 | LSP document/workspace symbols + prepareRename | 10 protocol + 48 semantics + 9 symbol tests PASS |

## Verification highlights

- **Pinned compiler used for real execution**: `xylem.previous-7082acd9`, sha
  `7082acd…` (exact `toolchain.toml` pin). All three example apps pass `check`
  and produce their expected output exactly; `task-list` was built natively and
  all three commands match expected files byte-for-byte.
- **5 conformance cases promoted to `IMPLEMENTED`** from a bounded real run
  (`--execute --limit 5`): 2 control-flow accepted, 2 diagnostics rejected,
  1 trap. 26 remain `PENDING_VERIFICATION`. Evidence in
  `independent-conformance/VERIFICATION_LOG.md`.
- All 5 documentation gates pass on the merged tree with the pinned compiler.
- Python validators pass; distribution and compatibility checkers pass.
- No compiler rebuild, native benchmark, fuzz campaign, CI, push to `main`,
  or deploy triggered. `xylem-research` never checked out.

## GitHub state

Pushed to three new remote branches (no PRs opened, `main` untouched):

| Repository | Branch | Local == remote | Files changed vs baseline |
|---|---|---|---:|
| xylem-lang | `integration/ecosystem-readiness` | `0f57f9b` | 123 |
| xylem-rust | `integration/ecosystem-readiness` | `12b20aa` | 27 |
| xylem-platform | `integration/ecosystem-readiness` | `354ddc8` | 5 |

Final protected-path regex over all diffs: **0 hits** in all three repos.

## Defects found and fixed in campaign-owned code

1. Examples: match-arm `return`, `usize` literals, `vec_new()` inference,
   `String` move-on-compare, `&mut` reborrow in a loop (5 real compiler errors).
2. Validator hard-required `PENDING_VERIFICATION`; now accepts `VERIFIED`.
3. D035 zsh candidate flattening and doctor test lookup.
4. I091 `contains(&key)` type error.
5. B016 three incorrect test expectations.
6. F064 doc-count snapshot (14 → 152) and stale 405 → 409 claim.

No compiler defect was found; no handover was needed.

## Product surface decision (owner, 2026-11-25)

Recorded in `PRODUCT_SURFACE_DECISION.md`: `xylem-web-framework` labels the
frontend surface; the Deno/Node-like runtime uses placeholder
`xylem-<server-runtime>` (name TBD). `xylem-runtime` is unavailable (protected
compiler crate). Frontend is `IMPLEMENTED_BUT_LIMITED`; server runtime is
`SPECIFIED_NOT_IMPLEMENTED`. Native target names (`xylem-desktop`,
`xylem-linux-desktop`, `xylem-native-mobile`, `xylem-native-*`) are recorded as a
future name registry with collisions/gates; no such packages are created here.
No performance claims; compiler work is protected.

## Cross-target capability work (owner direction, 2026-11-25)

Owner goal: Xylem apps across desktop, web, networking, Linux and beyond, with
JS/TS-like web capability via a Xylem-side web framework. Honest boundary:
- Full JS/TS parity is **not** claimed: no general HTML parser/DOM, no complete
  event/async/fetch/WebGL/worker API surface, no npm ecosystem; compiler WASM
  backend work is protected (`WL-40` only records a validated subset).
- `xylem_web_framework` does not exist as a named entity. The browser pipeline
  is Rust `xylem-platform/crates/xylem-web` (with generated `runtime.js`), and
  the Xylem-written surface is `stdlib/src/std/web/**`.
- Owner chose **Framework primitives**: add verifiable Xylem std/web building
  blocks (URL/percent encoding, HTML escaping/elements) plus a verified example,
  while Rust `xylem-web` remains the browser build target.
- Grounded capability matrix is at
  `xylem-lang/docs/tooling/cross-target-capabilities.md`: Linux desktop, web,
  loopback networking and headless GPU are `IMPLEMENTED_BUT_LIMITED`;
  macOS/Windows/iOS/Android are `SPECIFIED_NOT_IMPLEMENTED` (WL-63–WL-67).
- No performance claims: native/LLVM optimization belongs to the protected
  compiler campaign. This campaign adds correctness fixtures only.

## Compiler defect handover

`DEFECT_HANDOVERS/XY-001.yaml`: pinned compiler falsely reports `E3101 use of
moved value` when the same owned `String` is returned from two alternative
branches after an earlier borrow by `split`. Independently reproduced by A004
with a minimal reproducer and control case. Suspected subsystem: ownership
lowering / borrow analysis (**protected**). Not fixed here; the affected example
documents the adaptation.

## Platform language direction (owner decision, 2026-11-25)

`xylem-platform` is intentionally Rust native adapters: its README says the
existing Rust implementations are preserved and its `AGENTS.md` forbids changing
them without a separately scoped port. There are zero `.xy` files there. The
campaign directive also forbids competing graphics/UI/web implementations.

Owner chose **"Add Xylem-side examples"**: keep the Rust adapters, and add
realistic Xylem programs under `xylem-lang/examples/` that exercise the
Xylem-written platform surface already present in `stdlib/src/std/`
(`web/navigation`, `web/forms`, `web/dom`, `web/storage`, `filesystem`,
`networking`, `process`). Two such examples are in flight on dedicated task
branches; no Rust platform crate was rewritten.

## Remaining PENDING_VERIFICATION

- 26 conformance cases; full workspace `cargo check --workspace --all-targets`;
  cross-backend equivalence; compositor/Xvfb/Chrome tests; release builds,
  clean-system installation, macOS/Windows (not claimed), toolchain pin changes.
- 7 documentation disagreements await A003 resolution; no normative semantics
  were changed.
- The control plane `ecosystem-readiness/` is local-only (workspace root is not
  a git repository); it is not part of the pushed branches.
