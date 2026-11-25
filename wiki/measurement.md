# Measuring progress toward native-by-default

There is no single percentage. The honest indicators, and what each one misses.
All figures below were read on 2026-11-26 from `task/native-final@795fa55`.

## 1. Boxed-helper census — `tests/box_census.tsv`

**133 lines.** Each line is a runtime helper that a fixture still reaches,
with a category and a justification.

What it measures: which boxed helpers are still on a hot path somewhere.

What it misses: a line is one *kind* of helper, not a count of dynamic
occurrences, and some lines are legitimately permanent (printing, FFI, traps).
Removing a line requires proving the helper is unreachable from every fixture,
which is why the enum work only *added* a line (map insert became reachable once
enum lowering stopped reboxing first) rather than removing any.

Target: no line whose justification is "representation", only lines whose
justification is "foreign", "trap" or "semantics".

## 2. `AValue` occurrences in the runtime

**483 hits in `crates/xylem-native/src/cranelift_runtime.c`.**

What it measures: nothing about the goal. The count includes the struct
definition, `A_VALUE_*` constants, comments, and every helper that must stay for
fallback, dynamic boundaries, interop and traps. Do not use it as a progress
bar; it was misread that way on 2026-11-26.

## 3. Gate defaults — `wiki/subsystems/gates.md`

Count of representation gates defaulting ON. Ten ON, seven OFF on 2026-11-26.

What it measures: how many representation decisions run without an env var.

What it misses: a gate defaulting ON may still be inert (see
[decisions/inert-wiring.md](decisions/inert-wiring.md)). Only the
gate-toggles-IR test proves it counts.

## 4. Behavioural coverage — the real one

For each language construct, does a test prove that toggling its gate changes
emitted IR, and does the rollback stay byte-identical?

| Construct | Gate | Toggle test |
| --- | --- | --- |
| Vec mutation | `NATIVE_VEC_MUTATE` | `impl_vec`, `sw02_vec_mutate` |
| Typed I64 Map | `NATIVE_MAP_TYPED` | `i060_map`, `impl_map` |
| String compare | `NATIVE_STRING` | `sw087_string`, `impl_string` |
| Generic adapters | `NATIVE_GENERIC_LAYOUTS` | `j063_generic_spec` |
| Enum / Option | `NATIVE_ENUM` | `native_enum_wiring`, `native_authority_wiring` |
| Closures | `NATIVE_CLOSURE` | **none — arms still inert** |
| References | `NATIVE_REF_ABI` | none verified |
| Frame elision | `FRAME_ELISION` | none verified |
| RC substitution | `native_wiring` fragment | `native_rc_stream_migration` |
| Structs | `NATIVE_STRUCT` | `impl_struct` |

Six of ten rows have a live toggle test. The four without one are the honest
remaining gap, and two of them (closures, references) also lack live arms.
