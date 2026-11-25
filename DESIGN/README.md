# Platform product design research (design-only, no implementation)

Owner directive: design every platform product; do NOT implement. Research
existing products deeply, avoid the compiler's efficiency traps, and iterate /
analyze / optimize the designs on paper with evidence.

## Ground rules

1. **No code changes, no builds, no pushes, no CI.** Output is Markdown design
   documents only, under this directory.
2. **Primary sources only.** Official docs, specifications, first-party source
   code and first-party benchmarks; cite exact URLs and local `file:line`.
3. **Honest status.** Every feature is tagged `IMPLEMENTED_AND_VERIFIED`,
   `IMPLEMENTED_BUT_LIMITED`, `EXPERIMENTAL`, `SPECIFIED_NOT_IMPLEMENTED`, or
   `PLANNED`. No advertised future capability as production-ready.
4. **Performance discipline.** No invented numbers. A claimed cost must cite a
   primary source or be marked `PENDING_VERIFICATION`. Designs must include a
   budget and an anti-pattern checklist derived from the compiler campaign's
   documented failures.
5. **Protected areas stay protected.** Native representation/lowering, IR, ABI,
   ownership/RC, LLVM, compiler passes, runtime architecture, benchmark harness
   and bootstrap are owned by another campaign. Designs may request interfaces;
   they may not implement or modify them.
6. **Reuse over novelty.** Map each design to existing Xylem assets
   (`xylem-platform/crates/*`, `xylem-lang/stdlib/src/std/**`, `xylem-toolchain`,
   `xylem-wasm`) and name what is missing before proposing anything new.

## Inputs every design must read

- `ecosystem-readiness/ecosystem-readiness/docs/decisions/D-004-product-surface.md` (names and gates)
- `ecosystem-readiness/STATUS.md` and `SPEC_DISAGREEMENTS.md`
- `xylem-lang/docs/tooling/cross-target-capabilities.md` (live capability matrix)
- `xylem-lang/docs/development/WORKLOG.md` / `ROADMAP.md` (WL-40, WL-57..WL-67)
- `xylem-lang/AGENTS.md` (verification rule, architecture authority)
- `xylem-platform/README.md` and `xylem-platform/AGENTS.md`
- `xylem-rust/crates/xylem-wasm/src/lib.rs` (IR→WASM subset)

## Design documents

| File | Product | Agent |
|---|---|---|
| `WEB_FRAMEWORK.md` | `xylem-web-framework` (frontend) | D-WEB |
| `SERVER_RUNTIME.md` | `xylem-<server-runtime>` (Deno/Node analogue) | D-SERVER |
| `DESKTOP.md` | `xylem-linux-desktop` / desktop collision with existing `xylem-desktop` crate | D-DESKTOP |
| `MOBILE.md` | `xylem-native-mobile` | D-MOBILE |
| `GRAPHICS.md` | graphics/renderer surface (`xylem-graphics`, wgpu adapter) | D-GRAPHICS |
| `TOOLING_DISTRIBUTION.md` | CLI, packages, registry, reproducible distribution | D-TOOLING |
| `PERFORMANCE_GUARDRAILS.md` | cross-cutting anti-patterns and measurement discipline | D-PERF |

| `LOTUS_PORT.md` | Lotus meta-kernel port assessment: layer collision, D-001 v3 candidate, Options A/B/C | A004 |

Related research (integrated into `xylem-lang`):
`docs/development/WASM_EFFICIENCY_RESEARCH.md` — what an efficient WASM build
entails, the tooling-owned vs protected-compiler split, and why an opt-in
Binaryen `wasm-opt` adapter must re-validate ABI exports.

## Required structure for each design doc

1. Frontmatter: `doc_id`, `status: SPECIFIED_NOT_IMPLEMENTED`, `last_updated`,
   `last_verified: PENDING_INDEPENDENT_VERIFICATION`.
2. Current Xylem assets and exact gaps (with file paths).
3. Existing products studied (primary sources) and the traps they fell into.
4. Design options with tradeoffs; recommended option and why.
5. Data/model/lifetime design: ownership, memory layout, allocation strategy,
   hot paths, and what is explicitly out of scope.
6. API sketch — signatures and behavior only, no implementation.
7. Performance budget + anti-pattern checklist (from `PERFORMANCE_GUARDRAILS.md`).
8. Interface requests to the protected compiler team (if any).
9. Phased milestones with verification gates; no CI/deploy triggers.
10. Open questions and full source list.

## Iteration policy

Designs are not final on first write. Each agent should perform at least one
self-critique pass: identify the weakest assumption, seek contrary primary
evidence, revise the design, and record what changed. A004 then cross-reviews
all documents for contradictions and shared dependency conflicts.
