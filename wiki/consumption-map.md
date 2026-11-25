# Consumption map — which native modules production lowering actually uses

Measured 2026-11-26 on `xylem-rust@task/native-final:795fa55` by grepping each
module's name across `crates/xylem-llvm/src/` and requiring a hit outside the
module's own file and `lib.rs`. A module that only appears in its own file and
in `lib.rs` is declared but unconsumed.

## Consumed (production lowering reads the module)

| Module | Consumer | Evidence |
| --- | --- | --- |
| `native_enum` / `native_enum_lower` | `full_lower` arms | `native_enum_wiring` proves IR changes |
| `native_closure` | `full_lower` construct arm | **one** live arm (`closure_native_at`) |
| `native_struct_ctor` | `native_generic_layouts` | feeds generic layout bridge |
| `native_generic` / `native_generic_layouts` | `native_wiring` | `j063_generic_spec` |
| `native_vec_mutate` | plan consumed in `full_lower` | `impl_vec` |
| `native_map_full` | `full_lower` map arms | `i060_map` |
| `native_dyn` | `full_lower` DynCall | `sw12_dyn` |
| `native_prims` | `full_lower` PrimPlan | SW16 suite |
| `native_rc_events` | `native_wiring::rc_stream` | `native_rc_stream_migration` |

## Declared but NOT consumed (no production reader)

| Module | State | Notes |
| --- | --- | --- |
| `native_ref_abi` | **0 consumers in `full_lower`** | referenced only by `native_place_impl`, `native_struct_ctor`, `repr.rs` and its own tests. References still lower through the boxed `a_ref_*` helpers. |
| `native_place_impl` / `native_field_mut` | 0 consumers | only reference each other and `lib.rs` |
| `native_move` | 0 consumers | `unique_ownership_enabled` is never queried |
| `native_metadata` | 0 consumers | emission gate never read |
| `native_closure_impl` (call/drop) | partially | construct arm live; call and drop arms not |

## Why this matters

A module with an emitter and a passing unit suite looks complete in a registry
and in `lib.rs` comments. It contributes nothing until `full_lower` reads it.
The `native_enum` history is the worked example: planner, emitter and tests all
existed for months while the arm discarded the decision.

**Rule:** a module is "natively lowered" only when it appears in this page's
consumed table with a gate-toggles-IR test named beside it.

## Superseded

An earlier reading on 2026-11-26 said closures had 0 live arms
(`_closure_capture_native` discarded). By `795fa55` the construct arm is live;
the call and drop arms are not.
