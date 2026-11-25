# WO-02 — Port the real enum wiring onto the integration branch

**Worktree:** `ecosystem-worktrees/task-native-vec-default` (fresh worktree off it)
**Branch:** `task/nat-enum-port`
**Owns:** `crates/xylem-llvm/src/full_lower.rs`, `crates/xylem-llvm/src/native_enum.rs`,
`crates/xylem-llvm/src/native_enum_lower.rs`, `crates/xylem-llvm/tests/native_enum_wiring.rs`
**Depends on:** nothing. Can run in parallel with WO-01.

## Read first

- `ecosystem-readiness/wiki/subsystems/enum.md` — the correct integration order.
- `ecosystem-readiness/wiki/decisions/rollback-invariant.md` — how rollback breaks.
- `ecosystem-readiness/wiki/failures.md` — the traps, especially 2 and 3.

## Context

A working implementation exists, uncommitted, on
`ecosystem-worktrees/task-native-enum-native`. It is verified: `--lib` 169/169;
`native_enum_wiring`, `impl_struct`, `cross_backend_differential`, `sw311_enum`,
`e029_enums`, `t07_option` all green with `XYLEM_LLVM_NATIVE_ENUM` on **and**
off; `impl_vec`, `i060_map`, `g044_drop`, `p0_abi_verifier` green.

The integration branch instead has an inert seam:

```rust
// full_lower.rs:5279
let _enum_authority = self.enum_site_proven(dest);
```

`enum_site_proven` returns a bool nothing branches on, and
`native_wiring.rs` carries `enum_facts` + `enum_site_evidence` that nothing
consumes. Do **not** re-implement the emitter or planner — they are correct.

## Task

1. Diff the uncommitted work on `task-native-enum-native` against the
   integration branch's `full_lower.rs`.
2. Reconcile the two seams. The integration branch routes facts through
   `FunctionWiring`; the port can either extend that or carry the
   `NativeEnumSiteAuthority` through `lower_function` as the reference
   implementation does. Pick one, do not carry both. A second decision path is
   a competing architecture and is forbidden.
3. Delete the inert `enum_site_proven` binding once its replacement is live.
   Do not leave a `let _` behind.
4. Bring over `tests/native_enum_wiring.rs`. All three of its tests must pass on
   the integration branch.
5. Run the full matrix from the acceptance line below.

## Acceptance

```sh
cd ecosystem-worktrees/task-nat-enum-port
for t in native_enum_wiring impl_struct cross_backend_differential \
         sw311_enum e029_enums t07_option impl_vec i060_map g044_drop \
         p0_abi_verifier; do
  for g in "" 1; do
    XYLEM_LLVM_NATIVE_ENUM=$g cargo test -p xylem-llvm --test $t
  done
done
cargo test -p xylem-llvm --lib
XYLEM_LLVM_NATIVE_STRUCT=0 cargo test -p xylem-llvm --test impl_struct
```

Every run green. Report counts, not adjectives.

## Rules

- No performance benchmarks.
- Do not change any gate's default in this task. Wiring only; the default flip is
  a separate, later decision.
- Do not touch files owned by `T-DOMPHI-FIX`, `T-FRAMES-FIX` or `T-VECABI-HOOK`
  (`repr.rs`, `native_cell_plan.rs`, `native_frame.rs`, `native_prims.rs`,
  `native_wiring.rs` unless you clear it with the coordinator first).
