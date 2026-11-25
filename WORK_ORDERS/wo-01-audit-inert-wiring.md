# WO-01 — Audit every native arm for inert wiring

**Worktree:** `ecosystem-worktrees/task-native-vec-default`
**Branch:** `task/native-vec-default`
**Owns:** nothing. This task is read-only plus one report file.
**Report to:** `ecosystem-readiness/reports/wo-01-inert-wiring.md` (create it).

## Read first

- `ecosystem-readiness/wiki/decisions/inert-wiring.md`
- `ecosystem-readiness/wiki/state.md`

## Task

For **every** native representation arm in `crates/xylem-llvm/src/full_lower.rs`
and the `lower_emit/*` modules, determine whether the arm actually changes
emitted IR when its gate is on.

The known-suspect list as of 2026-11-26, marked by the searches that found them:

```
3381  let _exit_rc = self.rc_decision("xylem_rt_a_drop", temp);
3440  let _adapter = self.general_adapter_at_use(temp);
4887  let _closure_capture_native = self.closure_native_at();
4934  let _closure_call_native = closure_symbol.is_some() && self.closure_native_at();
5279  let _enum_authority = self.enum_site_proven(dest);
```

Search for more with: bindings starting `_` whose right side is a `self.` call,
`let _ = self.`, and const `WIRE_GUIDE` strings that describe an integration in
prose.

## Method

For each arm, write a scratch test that lowers one fixture twice with only the
gate toggled and compares the text. A program that exercises the construct is
enough; the fixtures in that construct's existing test suite are the right
starting point. Do **not** keep the scratch tests; the point is the verdict.

## Deliverable

A table in the report: file, line, arm, gate, verdict (`LIVE`, `INERT`,
`PARTIAL`), evidence (the fixture and what differs or does not), and the
acceptance test a fix would need. Order by how much of the goal the arm unblocks.

## Rules

- No performance benchmarks.
- Do not edit any source file. This task produces a verdict table only.
- If you find an arm that is inert and whose gate defaults ON, say so loudly:
  that means production already believes something it does not do.
