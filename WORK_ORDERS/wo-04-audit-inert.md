# WO-04 — Behavioural audit of remaining unconsumed modules

**Worktree:** `ecosystem-worktrees/task-native-final` (read-only)
**Owns:** `ecosystem-readiness/reports/wo-04-consumption-audit.md` only.
**Do not edit any source file.**

## Read first

- `ecosystem-readiness/wiki/consumption-map.md` — the starting hypothesis.
- `ecosystem-readiness/wiki/decisions/inert-wiring.md` — the standard.

## Task

Confirm or refute the consumption map by **behaviour**, not by grep. For each
module below, lower a fixture that exercises it with the relevant gate on and
off and compare the emitted IR:

`native_ref_abi`, `native_place_impl`, `native_field_mut`, `native_move`
(`XYLEM_LLVM_UNIQUE_OWNERSHIP`), `native_metadata`, and the closure call/drop
arms (`native_closure_impl`, `XYLEM_LLVM_NATIVE_CLOSURE`).

Scratch tests are fine; do not commit them. If `native_wiring.rs` blocks a gate
because an external owner holds it, note that and move on rather than editing.

## Deliverable

One table: module, gate, fixture, `LIVE` / `INERT` / `PARTIAL`, what differs in
the IR, and the single test that would prove a fix. Order by how much of the
campaign each one unblocks. Put the table in the report file and print a
five-line summary.

## Rules

- No performance benchmarks.
- No source edits. If you believe a fix is trivial, describe it; do not apply it.
