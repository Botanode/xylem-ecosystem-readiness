# Independent improvements outside native lowering

Dated record of work done alongside the native campaign. Detail lives in
[`../../work_logs/phase-01-independent-improvements.md`](../../work_logs/phase-01-independent-improvements.md);
this page is the pointer and the durable claims.

## Scope and ownership (2026-11-26)

On 2026-11-26 the `xylem-rust` working tree on top of `b542c76` had live
uncommitted work in `crates/xylem-llvm/src/` and `crates/xylem-native/src/`.
Those paths were treated as read-only, together with the lead-owned
`native_wiring.rs`, `native_frame.rs`, and `xylem-compiler/src/lowering.rs`.
Independent work was limited to `xylem-parser`, repository documentation,
`xylem-lang` conformance metadata, and the `xylem-rust` formatter pin/format
pass.

`xylem-platform@47730c4` was not built: its workspace pins remote
`xylem-rust@a1711807…`, which is absent locally and differs from this tree.

## Landed (2026-11-26)

- `xylem-parser` node-id allocation now uses `checked_add` and reports `E5001`
  once instead of overflowing when `parse_from` receives `usize::MAX`. Test
  `maximum_node_base_is_reported_without_panicking` passes with the crate's 31
  tests. Committed in `14d7154` after the integration agent absorbed the
  working-tree edits.
- `xylem-rust/README.md` no longer claims the repository has no `docs/` or
  `work_logs/`; both are listed in the layout table. Committed in `14d7154`.
- `xylem-lang` conformance now executes the `iter::skip` ordering oracle:
  `stdlib-iter-skip-order` is a manifest case (`cranelift-full`, stdout
  `689735254`, exit 0), the case inventory lists it, and the LLVM equivalence
  matrix is regenerated to 156 cases / 724 rows. Verified under the interpreter
  and a native `cranelift-full` build; the canonical pinned bootstrap is not
  installed, so the Xylem harness was not run end to end. The `xylem-lang`
  edit is uncommitted.
- `xylem-lang/AGENTS.md` now points performance readers at
  `../../native-migration/BLOCKER_REGISTRY.md` and
  `../../ecosystem-readiness/DESIGN/PERFORMANCE_GUARDRAILS.md`, and no longer
  cites the absent `docs/development/PERFORMANCE.md` as canonical. The
  `xylem-lang` edit is uncommitted.
- `xylem-rust/rust-toolchain.toml` is pinned to `1.99.1` (committed in
  `14d7154`). Commit `7b9d7ab` applies one formatting pass to 290 tracked
  files; `cargo fmt --all -- --check` now exits 0 and `git status` is clean.
  The worktree was clean when the format ran, so no live source edit was
  rewritten or included.

## Open findings

- **F1 — resolved.** `xylem-lang@be737aa`, commit `0b3e6c5` added
  `conformance/cases/stdlib-iter-skip-order.xy` and its `iter.xy` symlink; it
  is now a manifest case and inventory entry, so the `std/iter::skip`
  forward-order fix has an automated guard.
- **F2 — resolved.** On 2026-11-26, rustfmt 1.10.0-stable reported 2,427 diff
  sites across 307 files at `b542c76`; rustfmt 1.9.0 and nightly-2026-09-09
  matched, and wider-width/heuristic configs increased it. The toolchain is
  pinned to `1.99.1` and commit `7b9d7ab` reformats 290 tracked files with no
  source changes. `cargo fmt --all -- --check` exits 0 and `git status` is
  clean in `xylem-rust`.
- **F3 — resolved.** `xylem-lang/AGENTS.md` no longer cites
  `docs/development/performance-program/BLOCKER_REGISTER.md` or
  `docs/development/PERFORMANCE.md`; both references were repointed to the
  surviving registry and guardrails documents.

## Method notes

- The lexer/parser fuzz, totality, IR-validator coverage, and constant-folding
  suites were read and run first; they are already strong, so no speculative
  tests were added there.
- No benchmark was executed and no performance claim is made.
- `xylem-platform` changes were avoided because they could not be compiled
  against the pinned dependency in this workspace.
