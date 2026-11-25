# Integration gate procedure (A004)

Never merge into production `main`. All merges go task branch →
`integration/ecosystem-readiness` in the same repository.

## Pre-merge checklist (run for every task branch)

1. **Ownership check**
   - `git -C <repo> diff --name-only integration/ecosystem-readiness..task/ecosystem/<slug>`
   - Compare against `OWNERSHIP_REGISTRY.yaml` `allowed_write_paths`.
   - Any file outside the allowed set → reject and return to the agent.

2. **Protected-area check**
   - The diff must contain no path from `PROTECTED_AREAS.md`.
   - For `xylem-rust`, confirm no edit to `xylem-ast`, `xylem-codegen`,
     `xylem-effects`, `xylem-ir-validation`, `xylem-llvm`, `xylem-native`,
     `xylem-types`, `xylem-compiler` lowering internals, or `xylem-bench`.
   - For `xylem-research`, confirm no edit at all (not checked out here).

3. **Pin check**
   - No change to `toolchain.toml`, `Cargo.toml`/`Cargo.lock` dependency pins,
     `rust-toolchain.toml`, or compatibility identifier constants.

4. **Verification honesty check**
   - Completion record must state exactly which checks RAN and their result.
   - `IMPLEMENTED / PENDING_VERIFICATION` is acceptable; a claimed pass with no
     executed command is not.

5. **No-duplication check**
   - Confirm the change extends an existing file/API listed in
     `COMPATIBILITY_NOTES.md`, not a new parallel implementation.

6. **Merge**
   - `git -C <repo> merge --no-ff task/ecosystem/<slug>` into the integration
     branch from the matching integration worktree.
   - Resolve conflicts favoring the existing stable interface contract.
   - Update `STATUS.md` and `OWNERSHIP_REGISTRY.yaml`.

## Merge ordering (avoid known conflict boundaries)

1. E052 (conformance), F064 (docs), G074 (examples), H077 (distribution) — disjoint.
2. I100 (desktop/ui tests + docs) and I091 (graphics-wgpu) — disjoint file sets.
3. C024 (formatter), D035 (CLI) — disjoint crates.
4. B016 (lsp.rs) — LAST among xylem-rust tooling merges, because subsequent
   LSP feature work (symbols, signature help) will be stacked on top of it.

## Verification policy at integration

- Run ONLY cheap, focused checks: Python validators, `cargo fmt --check`,
  or a single targeted test if the host is provably quiet.
- Do NOT run `scripts/check.sh`, full `cargo test --workspace`, native benchmarks,
  or fuzz campaigns.
- If a check is skipped, record why (shared host / missing artifact / heavy dep).
