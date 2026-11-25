# Tasks

The machine-readable registry is `ecosystem-readiness/NATIVE_SWARM_REGISTRY.yaml`.
It is the single source of truth for ownership, dependencies and blockers. This
page explains how to read it and records corrections.

## Rules

- One owner per task, one owner per file set. File sets are disjoint.
- The coordinator is the only writer of the registry.
- A task is `INTEGRATED` only when the behaviour is observable in emitted IR or
  a test run, not when the commit lands. See
  [decisions/inert-wiring.md](decisions/inert-wiring.md).
- Every task names an acceptance line that a verifier can run.

## Status vocabulary

`OPEN` — unassigned, unblocked. `ASSIGNED` — owner named, not started.
`IN_PROGRESS` — owner working. `PARTIAL` — some of the acceptance is met and
verified, the rest is not. `VERIFIED` — acceptance met, tests green, not merged.
`INTEGRATED` — merged into `task/native-vec-default` and green there.
`BLOCKED` — cannot proceed; the blocker field says why.

## Corrections log

Date-stamped, newest first. When the registry and the tree disagree, fix the
registry here and in the yaml.

- **2026-11-26** — NAT-04 and NAT-02 were marked `INTEGRATED`, citing commits
  `d9c52f2` and `e53c650`. Verified false on that date: the closure and enum
  arms compute an authority result and discard it (`_closure_capture_native`,
  `_enum_authority`). Emitted IR is identical with the gates on and off. Status
  corrected to `PARTIAL` with the real acceptance test named.
- **2026-11-26** — NAT-06 described stale documentation claims as removed. The
  `WIRE_GUIDE` consts are gone from the integration branch but still present on
  `task/native-enum-native`, where the guide was superseded by a real
  implementation.

## Reading task state quickly

```sh
cd ecosystem-worktrees/task-native-vec-default
git log --oneline 149e525..HEAD        # what landed since the last audited point
grep -n "_[a-z_]* = self\." crates/xylem-llvm/src/full_lower.rs   # inert wiring
```
