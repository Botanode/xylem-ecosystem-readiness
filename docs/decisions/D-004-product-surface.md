# D-004 — Xylem ecosystem product surface

Status: ACCEPTED (naming and ownership only; not a feature specification)
Date: 2026-11-25
Owner: campaign owner via A001/A004
Related: D-001 (layering), D-002 (plugins), D-003 (conformance).

## Decision

Two developer-facing product surfaces are recognized. Neither is the compiler,
and neither is implemented as a named product today.

| Product | Name | Current home | Status |
|---|---|---|---|
| Frontend framework | `xylem-web-framework` | Xylem-source layer in `xylem-lang/stdlib/src/std/web/**` plus examples; browser build pipeline remains Rust `xylem-platform/crates/xylem-web` with generated `runtime.js` | `IMPLEMENTED_BUT_LIMITED` |
| Server-side runtime (Deno/Node analogue) | `xylem-<server-runtime>` (name TBD) | Capabilities scattered across `xylem-cli` (`run`/`eval`/`repl`), `std/networking`, `std/process`, `std/filesystem`, `std/streams`, `xylem-toolchain` package/registry/lockfile, backend host | `SPECIFIED_NOT_IMPLEMENTED` |

`xylem-runtime` is **not** available as a name: it is the protected compiler
execution-runtime crate in `xylem-rust/crates/xylem-runtime`.

## Evidence today

1. `xylem-web-framework` layer: `stdlib/src/std/web/{dom,forms,http,navigation,storage}.xy`
   host adapters; pure primitives `url.xy`/`html.xy` plus `examples/web-framework/`
   and `examples/web-router/` executed with the pinned compiler; Rust `xylem-web`
   build pipeline with `WL-40`, `WL-57..62` browser evidence (not a Xylem framework).
2. `xylem-<server-runtime>` layer: proven `std/networking::loopback` via
   `examples/networking-echo/`, filesystem/process/streams modules, CLI execution
   commands, package/registry/lockfile APIs. Missing: event loop, async I/O,
   runtime module resolution, server lifecycle, permission model, stable runtime API.

## Native target name registry (intent only)

| Proposed label | Current reality | Status | Gate |
|---|---|---|---|
| `xylem-desktop` | Already a Rust crate in `xylem-platform/crates/xylem-desktop` | `IMPLEMENTED_BUT_LIMITED` (Rust adapter) | Name collision; no second adapter without owner ruling |
| `xylem-linux-desktop` | No package; Linux path served by Rust adapter | `SPECIFIED_NOT_IMPLEMENTED` | Defined Xylem-side API and ownership decision |
| `xylem-native-mobile` | No package, SDK, device or signer | `PLANNED` | `WL-64`/`WL-65` |
| `xylem-native-*` | No packages | `PLANNED` | Compiler maturity, cross-target backends |

Do not create packages under these names in this campaign. Do not repurpose the
existing `xylem-desktop` crate. Native targets depend on the protected compiler
campaign reaching maturity and demonstrating C-level performance; that is an
external gate, not something this campaign may assert.

## Boundaries and performance policy

- Protected: native representation/lowering, numeric ops, canonical IR, native
  ABI/layout/collections/strings, ownership/borrowing/RC/COW, LLVM, compiler
  passes, runtime execution architecture, benchmark harness/certification,
  bootstrap.
- Tooling-owned: Xylem-source framework primitives, examples, conformance
  fixtures, tooling adapters, distribution manifests, capability evidence.
- No performance numbers here. C-level claims require the protected campaign's
  paired A/B, exact artifact identities and independent reproduction.

## Open items

- Choose the server-runtime name once its minimal API surface is defined.
- Decide whether framework primitives become a named stdlib package or repository.
- Keep `xylem-lang/docs/tooling/cross-target-capabilities.md` as the live
  capability status source.
