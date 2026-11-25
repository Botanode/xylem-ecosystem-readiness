# Stable interfaces consumed by this campaign

These are the supported surfaces developer tooling may use. They are deliberately
chosen to be independent of the native compiler's in-flight internal redesign.

## Stable (safe to consume)

- **Compiler CLI commands and exit statuses** (`xylem-rust/crates/xylem-cli/src`):
  `check`, `build`, `run`, `test`, `fmt`, `lsp`, `version` and their `--help` text.
  Consume as a process boundary; do not link to private compiler internals.
- **Diagnostics**: existing diagnostic codes, severity, messages and source
  locations from `xylem-diagnostics` / CLI rendering. Structured output must reuse
  existing codes and location contracts.
- **Source locations**: byte offsets + line/column as already exposed to tooling;
  LSP position encoding is negotiated at the protocol boundary (B006).
- **Language Server Protocol** (`xylem-toolchain/src/lsp.rs`): standard LSP
  methods and capabilities already implemented. Extend behind LSP, never a
  proprietary editor protocol.
- **Formatter interface** (`xylem-toolchain/src/formatter.rs`): existing format /
  check-only entry point and config surface. Preserve its API contract.
- **Module / package information**: `xylem-toolchain` manifest, lockfile, resolver
  and package APIs; `xylem.toml` / `xylem.lock` file formats.
- **Toolchain manifest / pin**: `xylem-lang/toolchain.toml` and artifact hashes
  (see `PINNED_DEPENDENCY.md`).
- **Platform crate public APIs** (`xylem-platform/crates/*/src/lib.rs`), which are
  independent of compiler native lowering.

## Fragile / do not depend on unpublished detail

- Native representation, primitive lowering, machine integer ops, bitwise/wrapping
  arithmetic, numeric constant representation, canonical IR internals.
- Native ABI / memory layout / native vector, map, string implementations.
- Ownership lowering, borrow analysis, reference counting, copy-on-write.
- LLVM lowering/optimization, compiler optimization passes, runtime execution.
- Benchmark harness internals and performance certification (`xylem-research`,
  `xylem-rust/crates/xylem-bench`).
- Any symbol currently present only as uncommitted WIP in a protected crate.

## Adaptation policy

- If a required interface is missing, add a local adapter in owned tooling code,
  or file an interface request under `DEFECT_HANDOVERS/`.
- Re-check this file at each integration merge; the native transformation may
  change internals. Tooling must keep consuming the stable boundaries above.
- Rust tooling and Xylem-written tooling (`compiler/src/cli_lsp.xy`, `lsp_*.xy`)
  are two implementations of one contract. Preserve compatibility with the
  intended self-hosted direction: changes to the Rust LSP/formatter contract must
  remain consistent with the Xylem-written implementation's observable behavior.
