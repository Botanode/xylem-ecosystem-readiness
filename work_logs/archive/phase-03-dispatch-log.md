# Dispatch log — Wave 1 and Wave 2

Each entry is the recorded work order issued to the agent. Status starts at
`dispatched` and moves to `implemented_pending_verification` on completion report,
then `verified` only after independent verification by A004.

## Wave 1 — independent, low-contention

### E052 — Independent conformance corpus
```yaml
agent_id: E052
squad: E
repository: xylem-lang
starting_revision: da35dfe
branch: task/ecosystem/conformance
worktree: ecosystem-worktrees/task-conformance
objective: "Create a NEW independently-owned black-box corpus with YAML per-case metadata; do not rewrite the existing manifest-driven corpus."
owned_files: [independent-conformance/**]
allowed_write_paths: [worktree:independent-conformance/]
protected_areas: [conformance/manifest.json, conformance/case-ids.txt, conformance/coverage.md, scripts/**, compiler/src/**]
existing_implementation: "conformance/manifest.json (155 cases), scripts/check-conformance.xy"
required_changes: [README.md, SCHEMA.md, 14 category dirs, 20+ YAML+source fixtures, tools/validate_corpus.py, CATALOG.md]
required_tests: [python3 independent-conformance/tools/validate_corpus.py]
required_verification: "Python validator only; no compiler; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [pinned artifact identities from toolchain.toml]
acceptance_criteria: [schema valid, ids unique, sources exist, spec refs present, validator exits 0]
integration_owner: A004
status: dispatched
```

### F064 — Developer language guides
```yaml
agent_id: F064
squad: F
repository: xylem-lang
starting_revision: da35dfe
branch: task/ecosystem/documentation
worktree: ecosystem-worktrees/task-documentation
objective: "Add truthful per-topic guide pages with the five campaign status tags, mapped to scope.md §1 vocabulary."
owned_files: [docs/language/guides/**]
allowed_write_paths: [worktree:docs/language/guides/]
protected_areas: [docs/README.md, docs/language/contract.md, docs/language/scope.md, grammar.ebnf, scripts/**]
existing_implementation: "docs/language/{contract.md,scope.md,grammar.ebnf}; status vocabulary in scope.md §1"
required_changes: [README.md index, 11 topic guides, tools/check_guides.py]
required_tests: [python3 docs/language/guides/tools/check_guides.py]
required_verification: "Python validator only; no .xy doc gates; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [A003 status vocabulary]
acceptance_criteria: [frontmatter keys present, allowed status tags, links resolve, no unverified IMPLEMENTED_AND_VERIFIED]
integration_owner: A004
status: dispatched
```

### G074 — Realistic example applications
```yaml
agent_id: G074
squad: G
repository: xylem-lang
starting_revision: da35dfe
branch: task/ecosystem/examples
worktree: ecosystem-worktrees/task-examples
objective: "Create 3 realistic apps (config-counter, text-stats, task-list) using only currently supported syntax/APIs."
owned_files: [examples/config-counter/**, examples/text-stats/**, examples/task-list/**, examples/ecosystem_examples_check.py]
allowed_write_paths: [worktree:examples/ (new dirs only)]
protected_areas: [existing examples/phase*, scripts/**, compiler/src/**]
existing_implementation: "examples/phase8/xylem.toml, examples/*/tests/smoke.xy, stdlib/src/std/**"
required_changes: [3 apps with README/xylem.toml/src/fixtures/tests/expected-output, structural validator]
required_tests: [python3 examples/ecosystem_examples_check.py]
required_verification: "structural only; no compile; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [F064 doc conventions]
acceptance_criteria: [required files present, README headings present, no invented APIs, gaps recorded]
integration_owner: A004
status: dispatched
```

### I100 — Platform layout tests and status docs
```yaml
agent_id: I100
squad: I
repository: xylem-platform
starting_revision: d5a08ae
branch: task/ecosystem/platform
worktree: ecosystem-worktrees/task-platform
objective: "Add GPU-free deterministic layout geometry and UI invariant tests; document current crate status and pin drift."
owned_files: [crates/xylem-desktop/tests/layout_geometry.rs, crates/xylem-ui/tests/document_invariants.rs, docs/CRATE_STATUS.md]
allowed_write_paths: [worktree: those three paths]
protected_areas: [Cargo.toml, Cargo.lock, xylem-web, xylem-platform-cli, compositor integration tests, compiler pins]
existing_implementation: "crates/xylem-desktop/src/layout.rs, crates/xylem-ui/src/lib.rs + fixtures.rs"
required_changes: [10+ pure layout tests, UI invariant test target, status doc]
required_tests: [tests written, not run]
required_verification: "no cargo (git compiler deps / shared host); IMPLEMENTED / PENDING_VERIFICATION"
dependencies: []
acceptance_criteria: [no GPU/display, #[ignore] with reason for unimplemented behavior, honest pin-drift note]
integration_owner: A004
status: dispatched
```

## Wave 2 — tooling extension (one owner per file boundary)

### B016/B006 — LSP protocol hardening
```yaml
agent_id: B016
squad: B
repository: xylem-rust
starting_revision: 28cd5cb
branch: task/ecosystem/lsp
worktree: ecosystem-worktrees/task-lsp
objective: "Negotiate LSP position encoding (utf-16/utf-32/utf-8), add didClose, stale-version rejection and diagnostic suppression, robust -32700 parse errors, honest capability recording, partial-analysis fallback."
owned_files: [crates/xylem-toolchain/src/lsp.rs, crates/xylem-toolchain/tests/lsp_semantics.rs, crates/xylem-toolchain/tests/lsp_protocol.rs]
allowed_write_paths: [worktree: those files; api_surface.rs only if public API must change]
protected_areas: [all protected compiler crates; no new server architecture]
existing_implementation: "lsp.rs: Server/handle_message/offset_at/position_at/diagnostic_json/didOpen/didChange/didSave/workspace; lsp_semantics.rs (~46 tests)"
required_changes: [centralized position conversion, lifecycle/versioning, robust JSON-RPC, capability recording]
required_tests: [lsp_protocol.rs raw JSON-RPC regressions for Unicode/CRLF/stale versions/didClose/parse errors]
required_verification: "no cargo build/test (shared host); IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [A002 compatibility contract]
acceptance_criteria: [existing lsp_semantics behavior preserved, no public API break without golden update]
integration_owner: A004
status: dispatched
```

### C024/C017 — Formatter config and preservation
```yaml
agent_id: C024
squad: C
repository: xylem-rust
starting_revision: 28cd5cb
branch: task/ecosystem/formatter
worktree: ecosystem-worktrees/task-formatter
objective: "Add FormatConfig with default-preserving behavior, configurable line endings and conservative line width; strengthen comment preservation and idempotence."
owned_files: [crates/xylem-toolchain/src/formatter.rs, crates/xylem-toolchain/tests/formatter_contract.rs, crates/xylem-toolchain/tests/formatter_regression.rs]
allowed_write_paths: [worktree: those files]
protected_areas: [lexer/parser/compiler internals; no competing formatter]
existing_implementation: "formatter.rs: format_source/scan_line/shift_leading_indent/FormatOutcome; formatter_contract.rs (11 tests)"
required_changes: [FormatConfig, format_source_with_config, configurable newline handling, safe wrapping only]
required_tests: [idempotence, trivia preservation, CRLF, check-only non-mutation, incomplete source safety]
required_verification: "no cargo build/test; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [A002 formatter contract]
acceptance_criteria: [default output byte-identical, no dropped comments, invalid source returned unchanged]
integration_owner: A004
status: dispatched
```

### D035/D036 — CLI doctor and completions
```yaml
agent_id: D035
squad: D
repository: xylem-rust
starting_revision: 28cd5cb
branch: task/ecosystem/cli
worktree: ecosystem-worktrees/task-cli
objective: "Implement read-only xylem doctor, shell completions (bash/zsh/fish), and machine-readable version output using the existing CLI JSON envelope."
owned_files: [crates/xylem-cli/src/main.rs, lib.rs, doctor.rs, completions.rs, tests/doctor_contract.rs, tests/completions_contract.rs]
allowed_write_paths: [worktree: those files]
protected_areas: [no clap, no machine mutation, no web command dispatch, protected compiler crates]
existing_implementation: "main.rs::run/usage, lib.rs CLI_SCHEMA=xylem-cli-v1 + failure_report"
required_changes: [doctor with probe abstraction + text/JSON, completions generator, version --format json, exit codes]
required_tests: [doctor_contract.rs, completions_contract.rs]
required_verification: "no cargo build/test; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: [pinned compatibility identities]
acceptance_criteria: [read-only, no root, deterministic exit codes, no extra dependencies]
integration_owner: A004
status: dispatched
```

### H077/H080/H088 — Distribution manifest and installer
```yaml
agent_id: H077
squad: H
repository: xylem-rust
starting_revision: 28cd5cb
branch: task/ecosystem/distribution
worktree: ecosystem-worktrees/task-distribution
objective: "Create schema-tagged toolchain manifest generator, read-only installer/uninstaller with hash verification and rollback, release layout and reproducibility docs against the pinned artifacts."
owned_files: [distribution/**]
allowed_write_paths: [worktree:distribution/]
protected_areas: [toolchain.toml pin, CI, compiler source, remote fetch]
existing_implementation: "xylem-lang/toolchain.toml pins; no existing toolchain manifest or install scripts"
required_changes: [manifest.schema.json, make_manifest.py, install.py, uninstall.py, RELEASE_LAYOUT.md, REPRODUCIBILITY.md, COMPATIBILITY.md, check_distribution.py]
required_tests: [python3 distribution/tools/check_distribution.py]
required_verification: "Python only; report actual checker result"
dependencies: [PINNED_DEPENDENCY.md]
acceptance_criteria: [values equal pins, no writes outside --prefix, no root, no release build claimed]
integration_owner: A004
status: dispatched
```

### I091 — GPU resource lifecycle diagnostics
```yaml
agent_id: I091
squad: I
repository: xylem-platform
starting_revision: d5a08ae
branch: task/ecosystem/platform-gpu
worktree: ecosystem-worktrees/task-platform-gpu
objective: "Add additive WgpuDiagnostics, bounded image cache with explicit invalidation, mock-device frame-order tests, and a resource-lifecycle document."
owned_files: [crates/xylem-graphics-wgpu/**, crates/xylem-graphics/src/backend.rs (only if non-breaking)]
allowed_write_paths: [worktree: those paths]
protected_areas: [Cargo.toml/lock, compiler crates, GPU adapter/display, other platform crates]
existing_implementation: "WgpuDevice images HashMap, WgpuError, WgpuOptions; RecordingDevice in xylem-graphics"
required_changes: [WgpuDiagnostics + stats(), bounded cache + eviction/clear, resize invalidation, mock tests, GPU_LIFECYCLE.md]
required_tests: [no-adapter unit tests for frame-order errors and cache accounting]
required_verification: "no cargo/GPU; IMPLEMENTED / PENDING_VERIFICATION"
dependencies: []
acceptance_criteria: [additive API, no breaking GpuDevice trait change, skip conditions documented]
integration_owner: A004
status: dispatched
```
