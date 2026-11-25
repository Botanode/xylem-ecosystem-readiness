# Decision: rollback must be byte-identical

**Date:** 2026-11-26.

## The rule

Every change that flips a representation behind `XYLEM_LLVM_NATIVE_*` ships a
rollback that reproduces the previous lowering **byte for byte** for affected
fixtures. The registry already requires this (`ownership.required_before_integration`);
this page records how it breaks in practice.

## How it breaks

Adding a native slot to a temp removes its boxed cell. If a second decision
path (the aggregate/struct plan, the cell plan, a `Move` copy) still believes
the temp has a cell, the module fails with one of:

```
native aggregate %tN is assigned from non-aggregate %tM
missing full-value value %tN in `<fn>` block B instruction I
missing full-value cell %tN in `<fn>` (type Some(Named("...")))
```

On 2026-11-26 the enum work reproduced the third of these with
`XYLEM_LLVM_NATIVE_STRUCT=0`, from two causes:

1. The enum slot plan ignored `native_struct_enabled()`, so native slots
   survived into the rollback path where the struct plan that keeps
   `needs_cell` consistent was off. Fixed by ANDing the switch: an inline enum
   slot is an aggregate slot and obeys the same rollback.
2. `lower_function` recomputed `native_struct_vectors` as
   `enum_slots_enabled || plan`, which resurrected the aggregate plan with the
   struct gate off. Fixed by ANDing `native_struct_enabled()`.

## The check that catches it

Run the affected suite twice, once with the switch unset and once with it `=0`,
and require identical pass counts. A rollback bug shows as a suite that passes
with the gate unset and fails with it `=0`.

Worth doing in one process as well: lower the same program several times in a
row with the switch toggled between rounds. That is what exposed cause 2, which
a fresh process would have hidden behind a clean environment.

## Related

Adding a slot for one construct must not silently promote an unrelated temp.
On 2026-11-26 a `Move`-propagation loop gave slots to struct and reference
temps and broke `impl_struct` and `cross_backend_differential`. The fix was to
constrain propagation to temps whose type the same authority proved.
