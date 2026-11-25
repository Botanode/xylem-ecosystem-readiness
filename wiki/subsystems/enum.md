# Subsystem: enum / Option native lowering

## Where it lives

| File | Role |
| --- | --- |
| `crates/xylem-llvm/src/native_enum.rs` | Layout proof: dense `i64` discriminants, legal zero niche for `Option<&T>`, `ValueClasses` union-find, dominators, `dominating_guard`, `plan_program`. |
| `crates/xylem-llvm/src/native_enum_lower.rs` | `NativeEnumSiteAuthority` (the decision), `EnumLowerEmitter` (the code), `SiteVerdict`, `BoxReason`. |
| `crates/xylem-llvm/src/full_lower.rs` | Consumption: the `Variant` / `Extract` / `IsVariant` arms. |
| `crates/xylem-llvm/tests/native_enum_wiring.rs` | Proves the gate changes emitted IR (added 2026-11-26). |

## The shape of a correct integration

On 2026-11-26 the working implementation on `task/native-enum-native` did this,
in this order. Order matters; causes 1 and 2 of
[rollback-invariant.md](../decisions/rollback-invariant.md) came from getting it
wrong.

1. **One authority per program.** `NativeEnumSiteAuthority::from_env(program)`
   is built in `lower_program`, not per function, not per instruction. A second
   planner would be a competing architecture.
2. **Plan slots before slots exist.** `needed_temps` returns the sources and
   destinations the authority proved. `native_aggregates` is filled from that
   *before* `aggregate_slots` is built. Doing it after silently produces no
   slots and a `missing full-value value` at lowering time.
3. **Size the slots.** The struct layout resolver does not know enums. Add an
   enum lookup (`enum_layout_words`) that follows the same monomorphized order
   the proof uses: `Applied` name before bare `Named`.
4. **Respect the rollback switch** when adding those slots and when deciding
   whether the aggregate plan runs at all.
5. **Constrain Move/Assign propagation** to temps the same authority proved.
   An unconstrained loop promotes structs and references and breaks unrelated
   suites.
6. **Try native, fall through to the helper.** Every arm keeps the incumbent
   call for unproved sites. Never delete the boxed path.

## Gating

`XYLEM_LLVM_NATIVE_ENUM` — native lowering is the default as of 2026-11-26;
`0`/`false`/`off` restores the boxed fallback byte-for-byte. The flip was
verified with the gate-toggling tests (`native_enum_wiring.rs`,
`native_authority_wiring.rs`) and the enum suites (`sw311_enum`, `e029_enums`,
`t07_option`) plus `cross_backend_differential`.

Also gated by `XYLEM_LLVM_NATIVE_STRUCT`, because an enum slot is an aggregate
slot.

## What stays boxed deliberately

- Managed `Option<&T>` without a registered vec/map niche witness.
- Any payload containing a mutable reference.
- Sources that escape into a call, container, store, closure or return.
- Sites with zero or multiple `Variant` producers (params, joins).
- Boxed destinations for `Extract`: a native slot has no `AValue` to write.

## Pitfall: trap_site and raw

`decide` builds `NativeSite` with `trap_site: 0, raw: false`. Those are
placeholders. `SiteVerdict::classify` fills them from the coordinator's
instruction site and the destination representation. A consumer that reads
`decide`'s output directly gets the placeholder. Go through `classify`.
