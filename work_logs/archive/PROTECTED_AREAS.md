# Protected engineering areas — do not modify

Another campaign is actively changing the compiler's fundamental execution
architecture (`integration/native-swarm-100` in `xylem-rust`; benchmark harness WIP
in `xylem-research`). The following subsystems are **owned by that campaign**.

## Forbidden subsystems (any repository)

- Native representation.
- Native primitive lowering.
- Integer machine operations.
- Bitwise operations.
- Wrapping arithmetic.
- Numeric constant representation.
- Canonical IR definitions.
- Native ABI.
- Native memory layout.
- Native vector implementation.
- Native map implementation.
- Native string implementation.
- Ownership lowering.
- Borrow analysis.
- Reference counting.
- Copy-on-write.
- LLVM lowering.
- LLVM optimization.
- Compiler optimization passes.
- Runtime execution architecture.
- Benchmark harness implementation.
- Performance certification infrastructure.
- Existing arithmetic and ownership formal verification work.
- Bootstrap implementation.

## Concrete paths currently dirty with protected WIP (never edit)

From `git status` at campaign start:

```text
xylem-rust/crates/xylem-ast/src/lib.rs
xylem-rust/crates/xylem-ast/src/integer_intrinsics.rs
xylem-rust/crates/xylem-codegen/src/interpreter/intrinsics/mod.rs
xylem-rust/crates/xylem-codegen/src/interpreter/intrinsics/machine.rs
xylem-rust/crates/xylem-effects/src/lib.rs
xylem-rust/crates/xylem-ir-validation/src/instructions/intrinsics.rs
xylem-rust/crates/xylem-llvm/src/full_lower.rs
xylem-rust/crates/xylem-llvm/src/native_prims.rs
xylem-rust/crates/xylem-native/src/lib.rs
xylem-rust/crates/xylem-types/src/checker/calls.rs
xylem-rust/crates/xylem-types/src/checker/constants.rs
xylem-rust/crates/xylem-types/src/checker/intrinsics.rs
xylem-rust/crates/xylem-types/src/integer.rs
xylem-rust/crates/xylem-types/src/machine.rs
xylem-research/xylem-benchmarks/harness/**  (all modified files)
xylem-research/xylem-benchmarks/reports/**
xylem-research/xylem-benchmarks/scripts/**
xylem-research/xylem-benchmarks/specifications/**
```

This list is a floor, not a ceiling. If a planned edit touches a file in a
protected crate and is not purely a stable tooling surface (see
`COMPATIBILITY_NOTES.md`), escalate to A004 before proceeding.

## Defect discovery procedure (do not fix, hand over)

1. Create a minimal reproducer in an **independently owned fixture directory**
   (e.g. `ecosystem-worktrees/xylem-lang/independent-conformance/...`).
2. Record the exact observed failure, compiler revision and invocation.
3. Identify the suspected responsible subsystem.
4. Write a handover using `DEFECT_HANDOVERS/TEMPLATE.yaml`.
5. Continue unrelated work.

**Never** introduce a workaround in developer tooling that silently conceals a
compiler defect. Tooling must report the defect faithfully; a suppressed error is
worse than a visible one.

## Resource isolation

The native team may be building, testing and measuring. To avoid contaminating
measurements:

- Do **not** start heavy builds on the measurement host during protected sessions.
- Do **not** run large fuzz campaigns, large test suites, native benchmarks or
  unrestricted parallel compilation.
- Prefer source implementation, documentation and fixture development.
- Run only focused, tooling-specific verification; mark everything else
  `IMPLEMENTED / PENDING_VERIFICATION`.
- Do not repeatedly interrupt the performance campaign to verify our changes.

Allowed: tooling-specific builds/tests, LSP tests, formatter tests, independent
fixture execution, doc validation, platform unit tests, packaging tests.
Restricted: full compiler rebuilds on the measurement host, large concurrent
campaigns, native benchmark execution, protected-code edits, unauthorized CI/deploy.
