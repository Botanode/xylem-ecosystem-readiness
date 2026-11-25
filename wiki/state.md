# Campaign state — as of 2026-11-26

Base facts. Repos are siblings under the workspace root; the Rust compiler is
`xylem-rust`, the canonical language is `xylem-lang`.

## Repositories

- `xylem-rust` `main` stood at `55d50e8` on 2026-11-26.
- The campaign integration branch is `task/native-vec-default`, 29 commits ahead
  of that `main` at `e53c650`.
- 87 task worktrees exist under `ecosystem-worktrees/`. Only six are for this
  campaign (`task-*-native`, `task-native-vec-default`, `task-native-cranelift-parity`).
  The other 80 are ecosystem tasks and are **not** in scope. Seven have an empty
  branch name and lookups of work in them (`task-authority`, `task-calls-native`,
  `task-cells-native`, `task-domphi`, `task-integration`, `task-perf-inliner`,
  `task-strings-native`, `task-tier0-validity`, `task-vec-native`) show large
  dirty trees; those are pre-existing campaign snapshots and are not a source of
  truth.

## Verified default-on native paths

As of `task/native-vec-default@e53c650`, per `NATIVE_SWARM_REGISTRY.yaml`:

- Vec mutation — `impl_vec` 8/8, `sw02_vec_mutate` 25/25, rollback green.
- Typed I64 map insert/remove — `i060_map` 10/10, `impl_map` 10/10.
- Owned string compare — `sw087_string` 16/16, `impl_string` 10/10.
- Generic layout bridge + adapter bodies — `j063_generic_spec` 7/7.
- Baselines: `--lib` 169 passed, `cross_backend_differential` 4/4,
  `p0_abi_verifier` 23/23.

## The central problem: inert wiring

On 2026-11-26 a survey of `crates/xylem-llvm/src/full_lower.rs` at `e53c650`
found four placeholders that compute a value and discard it:

```
3381  let _exit_rc = self.rc_decision("xylem_rt_a_drop", temp);
3440  let _adapter = self.general_adapter_at_use(temp);
4887  let _closure_capture_native = self.closure_native_at();
4934  let _closure_call_native = closure_symbol.is_some() && self.closure_native_at();
5279  let _enum_authority = self.enum_site_proven(dest);
```

A later commit (`d9c52f2`, `e53c650`) described the closure and enum authorities
as "wired into production lowering". The calls existed; their results were
unused. An integration that only adds the call is not an integration.

Verified with the enum case on 2026-11-26: the branch's `enum_site_proven`
returns a bool that no arm branches on, so the emitted IR is identical with
`XYLEM_LLVM_NATIVE_ENUM=1` and unset.

## Work completed but not integrated

On 2026-11-26 the Enum site authority was genuinely wired to emission on
`task/native-enum-native` (uncommitted, 3 source files + 1 test file). It
replaces the boxed `a_variant`/`a_extract`/`a_is_variant` helpers at proved
sites, plans correctly sized `[N x i64]` slots, and keeps rollback
byte-identical. See [subsystems/enum.md](subsystems/enum.md).

## Blockers

`NATIVE_SWARM_REGISTRY.yaml` names three external owners on 2026-11-26 whose
files must not be edited: `T-DOMPHI-FIX` (`repr.rs`, `native_cell_plan.rs`),
`T-FRAMES-FIX` (`native_frame.rs`, frame canaries), `T-VECABI-HOOK`
(`native_wiring.rs`, `native_prims.rs`, vec_get, vecabi canaries). Those owners
were described as working in `/tmp/opencode/swarm/...`, which is outside this
workspace and cannot be inspected. Treat their file sets as read-only until the
registry says otherwise.
