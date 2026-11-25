# Recurring failure modes

Each entry names the symptom, the cause, and the check that catches it before it
costs a session. Add to this page whenever a subagent loses time.

## 1. Inert wiring

**Symptom:** commit says "wired into production lowering"; emitted IR is
unchanged with the gate on.

**Cause:** `let _x = self.authority(...)` — the call is present, its result
dropped.

**Check:** lower one fixture twice toggling only the gate and assert the
texts differ. See [decisions/inert-wiring.md](decisions/inert-wiring.md).

## 2. Rollback broken by a new slot

**Symptom:** affected suite passes with the gate unset, fails with it `=0`;
error `missing full-value value %tN`.

**Cause:** a plan added a slot without honouring the representation switch, or
`lower_function` recomputed a plan by `OR`ing a new switch into it.

**Check:** run the suite in both rollback states. See
[decisions/rollback-invariant.md](decisions/rollback-invariant.md).

## 3. Over-promotion through Move

**Symptom:** unrelated suites (`impl_struct`, `cross_backend_differential`)
fail after a change to one construct; error mentions `Named("Point")` or a
`FieldStore` instruction.

**Cause:** propagation over `Move`/`Assign` promoting temps the authority never
proved.

**Check:** constrain propagation to temps whose type the proving authority
accepts, then rerun the two differential suites.

## 4. Chasing an environment race

**Symptom:** a fixture passes in a scratch test and fails inside its own suite,
single-threaded, with identical source and flags.

**Cause (observed 2026-11-26):** it was not a race. The suite's helper
(`with_switch`) sets and then *removes* the variable around each call, and the
failure was on a later call in the same test than the one being blamed. Read
the suite's wrapper before assuming parallelism.

**Check:** add a temporary `eprintln!` of the env state and the call index
inside the suite's own `lower()`. Do not build a parallel reproduction and
conclude from it.

## 5. Assuming a fixture is the one failing

**Symptom:** an hour spent on the first item of a `SHAPES` array.

**Cause:** the panic points at the helper, not the loop iteration.

**Check:** print the loop label with the env state before lowering.

## 6. Trusting the registry over the tree

**Symptom:** a task says `INTEGRATED`; the behaviour is absent.

**Cause:** the registry records commit landings, sometimes optimistic.

**Check:** verify against emitted IR or a test run before reusing a claim. When a
claim is wrong, correct the registry in the same session that found it.

## 7. Benchmarking

Not a failure mode to fix — a rule. The campaign forbids performance
benchmarks. Verification is correctness: pinned tests, differential runs, ABI
verification, generated-code inspection.
