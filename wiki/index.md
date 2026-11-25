# Native execution campaign — wiki index

Memory for the campaign to make native representations the default across the
LLVM and Cranelift backends and retire the interpreter-derived `AValue` model.
Written for the next session; every claim is dated or cites a commit.

## Start here

| Page | Summary |
| --- | --- |
| [state.md](state.md) | Where the campaign stood on 2026-11-26: what is verified, what is inert, what blocks. |
| [measurement.md](measurement.md) | Honest progress indicators, and why the `AValue` count is not one. |
| [failures.md](failures.md) | Recurring failure modes that waste agent sessions, and the check that catches each. |

## Decisions

| Page | Summary |
| --- | --- |
| [decisions/inert-wiring.md](decisions/inert-wiring.md) | Why "already wired" claims must be checked against emitted IR, not against the presence of a call. |
| [decisions/rollback-invariant.md](decisions/rollback-invariant.md) | Every gate change ships a rollback that must be byte-identical; how it gets broken. |

## Subsystems

| Page | Summary |
| --- | --- |
| [subsystems/gates.md](subsystems/gates.md) | The environment switches that select native vs boxed lowering. |
| [subsystems/enum.md](subsystems/enum.md) | Enum/Option native lowering: the one real implementation and its tests. |

## Working notes

| Page | Summary |
| --- | --- |
| [tasks.md](tasks.md) | Live task registry summary and how to read `NATIVE_SWARM_REGISTRY.yaml`. |
