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
- Enum / Option site authority — default-on as of 2026-11-26 on
  `task/native-clean@d9ed8dc`, based directly on `e53c650`. Gate-toggling IR
  tests `native_authority_wiring` 4/4 and `native_enum_wiring` 3/3;
  `sw311_enum` 22/22, `e029_enums` 14/14, `t07_option` 4/4, `llvm_backend`
  38/38 (including the interpreter differential that exposed three latent
  promotion bugs), `box_justification` 4/4. The boxed path is restored by
  `XYLEM_LLVM_NATIVE_ENUM=0`. The legacy enum scanner, its unused
  `FunctionWiring` field and all discarded-result placeholders were deleted.
  Five full-suite failures remain on the base (`n06_helper_elim`,
  `native_aggregate_guard`, `native_collection_helpers`, `native_place_impl`,
  `sw009_prims_wiring`); all five reproduce with `XYLEM_LLVM_NATIVE_ENUM=0`
  and are inherited from `e53c650`, not introduced by the default flip.
- Baselines: `--lib` 171 passed, `cross_backend_differential` 4/4,
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

Resolved for the enum on 2026-11-26: the real implementation from
`task/nat-enum-port` was integrated into `task/native-vec-default` and now
drives the `Variant` / `Extract` / `IsVariant` arms through one program-wide
`NativeEnumSiteAuthority`. The gate-toggling tests prove the emitted IR changes;
the legacy scanner and all five discarded-result placeholders were deleted, not
renamed. See [subsystems/enum.md](subsystems/enum.md). The closure and RC
placeholders remain fail-closed and are tracked in the registry.

## Blockers

`NATIVE_SWARM_REGISTRY.yaml` names three external owners on 2026-11-26 whose
files must not be edited: `T-DOMPHI-FIX` (`repr.rs`, `native_cell_plan.rs`),
`T-FRAMES-FIX` (`native_frame.rs`, frame canaries), `T-VECABI-HOOK`
(`native_wiring.rs`, `native_prims.rs`, vec_get, vecabi canaries). Those owners
were described as working in `/tmp/opencode/swarm/...`, which is outside this
workspace and cannot be inspected. Treat their file sets as read-only until the
registry says otherwise.

## Update — branches moved under the coordinator (2026-11-26)

During the session the repository owner committed directly to the campaign
branches, in parallel with agent work:

- `task/native-vec-default@8704b11` — "record canonical cell RC descriptors in
  the audited event stream". Contains the enum port identically to
  `task/nat-enum-port@5a60ffc` (zero diff on the enum files).
- `task/native-final@795fa55` — "default native enum lowering and remove inert
  wiring". Defaults `XYLEM_LLVM_NATIVE_ENUM` ON with `0`/`false`/`off` as the
  rollback, and adds the `xylem_rt_a_map_insert_i64_bits` line to
  `tests/box_census.tsv`, which became reachable once enum lowering went live.

Uncommitted edits held in `task-native-vec-default` were discarded on discovery,
because `8704b11` already contained the same work. **Lesson: run
`git log --oneline -3` on the target worktree before editing or merging into it;
the owner commits directly.**

Verification on `task/native-final@795fa55`, run 2026-11-26 with the gate at its
new default: `--lib` 169, `native_authority_wiring` 4, `native_enum_wiring` 3,
`sw311_enum` 14, `e029_enums` 22, plus `t07_option`, `cross_backend_differential`,
`p0_abi_verifier`, `impl_struct`, `box_justification`, `a004_wiring_consistency`,
and the same three enum suites again under `XYLEM_LLVM_NATIVE_ENUM=0`.
