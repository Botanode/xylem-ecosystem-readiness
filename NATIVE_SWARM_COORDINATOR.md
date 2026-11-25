# Native execution swarm — coordinator

The session agent is the sole coordinator and the only writer of
`NATIVE_SWARM_REGISTRY.yaml`. Task ownership is exclusive: an agent owns only
its listed files and works only in its assigned worktree. No agent changes
another agent's files, merges to `main`, force-pushes, or runs benchmarks.

## Method

1. Inspect existing branches, worktrees and uncommitted work before assigning.
2. Reuse, repair and integrate existing modules; never create a competing
   representation authority or second lowering architecture.
3. Each task must name its file set, dependencies and acceptance evidence.
4. Verify with pinned focused tests, IR verification/build, differential
   equivalence, trap equivalence and rollback before integration.
5. Integrate through `task/native-vec-default` only after verification.

## Current state

Verified default-on native paths: Vec mutation, typed-I64 Map, owned-string
compare, A001 generic layout bridge with adapter bodies. RC event stream is
single-authority but substitution is disabled. Closure thunks, frame/cell
elimination, enum/Option lowering, Cranelift parity and consolidation remain.

Coordinator control plane: `Botanode/xylem-ecosystem-readiness`.
Integration branch: `Botanode/xylem-rust` `task/native-vec-default`.
