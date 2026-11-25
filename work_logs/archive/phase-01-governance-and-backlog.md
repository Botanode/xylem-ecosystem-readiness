# Campaign backlog and dependency ordering

Status legend: `TODO` · `DISPATCHED` · `IMPLEMENTED / PENDING_VERIFICATION` · `VERIFIED` · `BLOCKED`.
A box is never ticked on self-report; see `xylem-lang/AGENTS.md` verification rule.

## Wave 0 — Governance (A001–A004) — COMPLETE

- [x] Protected ownership registry (`OWNERSHIP_REGISTRY.yaml`, `PROTECTED_AREAS.md`)
- [x] Pinned stable compiler dependency (`PINNED_DEPENDENCY.md`, `COMPATIBILITY_NOTES.md`)
- [x] 100 deduplicated assignments (`ASSIGNMENTS.yaml`)
- [x] Isolated integration worktrees (3 repos) off committed revisions
- [x] Read-only tooling inventory (4 exploration agents) → feeds Wave 1 dedup

## Wave 1 — Independent, low-contention implementation (dispatch first)

These squads work in separate repos/worktrees and need no compiler rebuild:

| Squad | Branch / worktree | First deliverable | Depends on |
|---|---|---|---|
| E (conformance) | `task/ecosystem/conformance` in xylem-lang | Corpus skeleton + YAML schema + first fixtures in `independent-conformance/` | pinned pin only |
| F (docs) | `task/ecosystem/documentation` in xylem-lang | Docs map + status classification scheme + verified examples | A003 |
| G (examples) | `task/ecosystem/examples` in xylem-lang | 2–3 realistic example apps with README + expected output | F (doc conventions) |
| H (distribution) | `task/ecosystem/distribution` in xylem-rust+lang | `manifest.json` schema + compatibility matrix + release layout | pinned pin |
| I (platform) | `task/ecosystem/platform` in xylem-platform | Pure layout geometry tests + error-handling cleanup | none |

## Wave 2 — Tooling extension (needs exploration results; strict no-duplication)

| Squad | Branch / worktree | First deliverable | Depends on |
|---|---|---|---|
| B (LSP) | `task/ecosystem/lsp` in xylem-rust | Position encoding + document sync hardening in existing `lsp.rs` | exploration of `lsp.rs` |
| C (formatter) | `task/ecosystem/formatter` in xylem-rust | Idempotence + comment-preservation fixtures in `formatter.rs` tests | exploration of `formatter.rs` |
| D (CLI) | `task/ecosystem/cli` in xylem-rust | `doctor` + machine-readable diagnostics via existing CLI contract | exploration of CLI/diagnostics |

## Integration

- Each squad works on its own `task/ecosystem/<slug>` branch created from
  `integration/ecosystem-readiness`.
- A004 reviews owned paths, checks no protected file was touched, and merges into
  `integration/ecosystem-readiness` only after focused verification passes.
- Never merge into production `main`; no push / CI / deploy without authorization.

## Deferred / explicitly not done here

- Full compiler rebuilds, native benchmarks, performance certification.
- Any edit to protected subsystems (hand over instead).
- Toolchain-pin updates (recorded decision + independent confirmation required).
- WASM compiler architecture work.
