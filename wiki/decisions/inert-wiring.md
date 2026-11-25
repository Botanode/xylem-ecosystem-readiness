# Decisions: inert wiring is not integration

**Date:** 2026-11-26. **Source:** survey of `xylem-rust` at
`task/native-vec-default@e53c650`.

## The failure

A commit adds `let _x = self.prove_something(...);` inside a lowering arm and
the commit message says the authority is "wired into production lowering".
Nothing changes in the emitted IR, because `_x` is never read. Reviewers and
later agents see the call, trust the claim, and move on.

On 2026-11-26 this had happened five times in `full_lower.rs` (see
[state.md](../state.md)). Two of them landed the same day as commits `d9c52f2`
and `e53c650` describing closure and enum wiring as complete.

## The rule

A representation decision is integrated only when **the emitted IR differs**
with the gate on versus off, for a fixture that should be affected. The gate
must be the only difference between the two runs.

## The check

Lower one fixture twice, toggling only the gate, and compare:

```rust
let boxed  = with_gate(false, || lower(&program));
let native = with_gate(true,  || lower(&program));
assert_ne!(boxed, native, "gate changed no IR, so the authority is inert");
```

Then prove the change is the intended one: the replaced helpers disappear from
the hot path and the native markers appear.

`crates/xylem-llvm/tests/native_enum_wiring.rs` is the worked example (added
2026-11-26).

## Why grep is not enough

`grep -c "enum_site_proven" full_lower.rs` returned a hit on the inert version.
The call was present, the result was dropped. Nothing short of lowering and
diffing distinguishes the two.

## Anti-patterns that produced this

- Naming the binding `_name` to silence an unused-variable warning instead of
  deleting the call. A `let _ = ...` is a signal to stop, not to rename.
- Writing a `WIRE_GUIDE` const string that describes the integration instead of
  performing it. `native_enum_lower.rs` carried one from SWARM100 until
  2026-11-26.
- Marking a task `INTEGRATED` in the registry when the commit landed but the
  behaviour did not.
