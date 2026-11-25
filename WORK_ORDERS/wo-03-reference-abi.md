# WO-03 — Make the native reference ABI live

**Base:** `ecosystem-worktrees/task-native-final` @ `795fa55`
**Branch:** `task/nat-ref-abi` (create off `795fa55`)
**Owns:** `crates/xylem-llvm/src/full_lower.rs`, `crates/xylem-llvm/src/native_ref_abi.rs`,
`crates/xylem-llvm/tests/native_ref_abi_wiring.rs` (new)
**Does not own:** `native_place_impl.rs`, `native_field_mut.rs`, `native_struct_ctor.rs`
(another task), `repr.rs`, `native_cell_plan.rs`, `native_frame.rs`,
`native_prims.rs`, `native_wiring.rs` (external owners — read, do not edit).

## Read first

- `ecosystem-readiness/wiki/consumption-map.md` — `native_ref_abi` has **0**
  production consumers at `795fa55`. That is the gap.
- `ecosystem-readiness/wiki/decisions/inert-wiring.md` — what a real integration
  looks like, and why a call with a discarded result does not count.
- `ecosystem-readiness/wiki/decisions/rollback-invariant.md` — the failure you
  will most likely cause.
- `ecosystem-readiness/wiki/subsystems/enum.md` — the reference integration, in
  the order that worked. Follow the same shape.

## The task

`native_ref_abi` proves a native reference form and has an emitter, but
`full_lower` never reads it (grep `native_ref_abi::` in `full_lower.rs` → 0
hits). References still lower through the boxed `xylem_rt_a_ref*` helpers.

Make the proved form live:

1. Build the plan **once per program** in `lower_program` and carry it into
   `lower_function`, exactly as `NativeEnumSiteAuthority` is carried.
2. Consult it in the `Borrow`, `BorrowPlace`, `Reborrow`, `Load`, `TakeRef` and
   `Store` arms. A proved site emits the native form; every unproved site falls
   through to the existing boxed helper, unchanged, with its trap site intact.
3. Do not add a second decision path. If the plan already has a query, use it.

## Acceptance

Create `crates/xylem-llvm/tests/native_ref_abi_wiring.rs` with a **behavioural**
test: lower one fixture twice toggling only the gate, assert the texts differ,
assert the boxed helper call disappears, assert the rollback direction carries
no native marker. No source-grep assertions.

Then report counts for, with the gate at its default and with `=0`:

```sh
cargo test -p xylem-llvm --lib
for t in native_ref_abi_wiring sw312_refabi cross_backend_differential \
         p0_abi_verifier impl_struct g044_drop t07_option; do
  cargo test -p xylem-llvm --test $t
done
XYLEM_LLVM_NATIVE_STRUCT=0 cargo test -p xylem-llvm --test impl_struct
```

## Rules

- No performance benchmarks.
- Do not change a gate's default. Wiring only.
- Do not touch files another external owner holds.
- If a proved site cannot be emitted without changing ownership or drop order,
  leave it boxed and say so in the report. Fail closed.
