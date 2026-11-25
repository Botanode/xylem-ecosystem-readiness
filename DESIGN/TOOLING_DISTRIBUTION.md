---
doc_id: "TOOLING_DISTRIBUTION"
status: SPECIFIED_NOT_IMPLEMENTED
last_updated: 2026-11-25
last_verified: PENDING_INDEPENDENT_VERIFICATION
---

# Tooling, packaging and distribution (Xylem)

Design-only. No code, builds, CI, or protected-layer changes are authorized here.

## 1. Scope and layering placement

This product is **L7 — the developer/delivery plane** under the accepted
layering contract v2 (`docs/decisions/D-001-platform-layering.md:2,40–41,56`).
L7 consumes **published stable interfaces from every runtime layer L0–L6 as
data**, and **no runtime layer depends on L7** — it is a plane, not a runtime
tier (v2 §2, §11). Interfaces consumed as data:

- L0 identities: `xylem-native/16` native ABI, `xylem-bootstrap-ir/1` canonical
  IR, LLVM pin `21.1.8` (min `21.1`) — `xylem-lang/toolchain.toml`,
  `xylem-rust/AGENTS.md`.
- L2 surface: stdlib source revision `e19bc963…` and backend-host request/result
  schemas.
- L3–L6 surfaces *only when published*: platform capability matrix (L3), L4a
  UI-contract identity (never the document itself), L5 build schemas, L6 app
  fixtures/test manifests as verification inputs. No port is mirrored or
  redefined here.

**Dependency direction (v2 §§4–5):** source dependencies point downward toward
stable policy; L7 may consume L1–L6 published interfaces (v2 §4, L7 row) plus
L0 ABI/IR identities as data, while nothing consumes L7. L7 must not edit or reimplement L0/L1 internals, must not
define a port owned by another layer (L4a owns the UI rendering port, L3 the
platform port, L2 the capability port), must not contain L6 business logic, and
must not make a runtime tier depend on developer tooling. Composition/wiring may
live at L7 but never in a core (§5). Every lower-layer need is an interface
request (§8) or defect handover, never a patch.

**Rule-check (the eight anti-compiler-trap rules re-read against D-001 v2
§§3–8, 10):**

| Rule | Conformance of this design |
|---|---|
| 1 No upward deps / plane not runtime / no business logic | L7 consumes L0–L6 published interfaces; no runtime layer depends on L7 (v2 §2, §11). Packaging, identity and verification only; product semantics (L4a policy, L5 services, L6 apps) never enter the manifest, lockfile or installer. |
| 2 Stable boundaries / port ownership | Only versioned identities (`xylem-cli-v1`, `xylem-diagnostic-v1`, `xylem-native/16`, `xylem-bootstrap-ir/1`, lock v3) and published ports are consumed. No port is mirrored in L7; no native transformation internals. |
| 3 Single-pass | Resolve once into a canonical graph, hash once per artifact, parse each manifest once — v2 §7 requires validation/indexing/layout once per state change, no repeated whole-tree scans (§7 below). |
| 4 Explicit ownership | Installed artifacts are owned by a version directory; rollback state is an explicit sidecar. L7's package/registry cache is an explicit versioned registry, not a global mutable one; no boxed per-node hot paths (v2 §7). |
| 5 Ports and adapters (v2 §5; replaces v1 "L4→L3") | L7 does not own or reimplement a UI/platform/capability port; L4a is the single UI policy core and L4b target adapters implement its port. Packaging must not embed an adapter-specific or duplicated UI model. |
| 6 Honest diagnostics / typed failure | Unsupported targets/platforms report typed `UNSUPPORTED` diagnostics, never silent fallback; unknown identities and incompatible artifacts fail **before use** (v2 §8). |
| 7 Per-layer gates | L7 gate = tool contract tests, doc gates, distribution checker (v2 §3); architecture enforcement is an L7 *design item*, not a shipped capability (v2 §10). No benchmark campaign or performance claims here. |
| 8 Escalation, not modification | Missing lower-layer interfaces become §8 requests or defect handovers; no L0/L1 edits, no protected-layer substitution (v2 §8, §11). |

## 2. Current Xylem assets and exact gaps

All paths are relative to the workspace; status tags follow `DESIGN/README.md`.

| Asset | Location | Status |
|---|---|---|
| Manifest / project model | `xylem-rust/crates/xylem-toolchain/src/manifest.rs` | IMPLEMENTED_AND_VERIFIED (docs) |
| v3 lockfile, workspace lock, atomic write | `…/src/lockfile.rs` | IMPLEMENTED_BUT_LIMITED (`file:938–944`: registry graph verification explicitly not wired into migration) |
| Registry index, content-addressed cache, Ed25519 index signature, vendor layout | `…/src/registry.rs` | IMPLEMENTED_BUT_LIMITED (no network transport implementation) |
| Offline resolution, lock verification, vendoring, `PackageOptions` | `…/src/registry_resolve.rs` | IMPLEMENTED_BUT_LIMITED (`file:1–7`: no network here) |
| `PackageCache` | `…/src/cache.rs` | IMPLEMENTED_BUT_LIMITED (`file:6`: "not yet wired into resolution or builds") |
| CLI `lock migrate/resolve`, `vendor`, `build --locked/--offline/--vendor/--cache` | `xylem-rust/crates/xylem-cli/src/main.rs:108–145,516–819` | IMPLEMENTED_AND_VERIFIED (docs `docs/tooling.md`) |
| Distribution schema, manifest generator, installer/uninstaller (dry-run/no-network), SBOM, compatibility checker | `ecosystem-worktrees/xylem-rust/distribution/` | IMPLEMENTED_BUT_LIMITED (identity-only; `distribution/README.md:12–16`) |
| Pins | `xylem-lang/toolchain.toml` (`5ff0ba2…`/`7082acd9…`, host `7fe37434…`/`2e2d75fb…`) | IMPLEMENTED_AND_VERIFIED |
| Capability matrix | `xylem-lang/docs/tooling/cross-target-capabilities.md` | IMPLEMENTED_BUT_LIMITED |
| Spec conflicts | `ecosystem-readiness/work_logs/archive/SPEC_DISAGREEMENTS.md` | PENDING_A003 (stdlib 1.0.0 vs 1.15.0; backend authority; counts) |

**Exact gaps:** (a) no release packaging in CI; (b) no signing identity, no
provenance, no release pipeline (`distribution/SBOM_AND_COMPATIBILITY.md:88–105`);
(c) no network index refresh (`docs/tooling.md:1150–1157`); (d) registry archives
are one-UTF-8-source only (`docs/tooling.md:1143–1146`); (e) web target cannot be
described by v3 lock (`lockfile.rs:696–701`); (f) workspace lock records member
digests only, not a single resolved multi-member graph.

**Missing-sidecar problem:** `docs/tooling.md` §"Local release tooling" names
`scripts/generate-sbom.py`, `scripts/package-release.sh`, `scripts/install-xylem.sh`,
`scripts/check-release-install.sh`, `scripts/check-install-layout.sh`, which do
**not** exist in the snapshot, while `crates/xylem-toolchain/tests/ci_contract.rs`
still asserts several of them. The real scripts are under `distribution/tools/`
(`install.py`, `uninstall.py`, `make_manifest.py`, `sbom.py`,
`check_compatibility.py`, `check_distribution.py`). Reconciliation proposal
(§4 Option C / §9 Phase 0): keep pins unchanged; make `distribution/tools/`
the single authority, rewrite the doc section as a pointer, and retire the stale
`ci_contract.rs` assertions through a defect handover — **never** add `scripts/`
shims to satisfy a stale doc (root `AGENTS.md`: doc never overrides tree).

## 3. Existing products studied and traps (primary sources)

Comparison (every row cites an exact primary URL):

| Tool | Identity / pinning | Integrity & offline | Trap relevant to Xylem |
|---|---|---|---|
| Cargo `Cargo.toml` vs `Cargo.lock` | Lock records exact revisions "maintained by Cargo", check into VCS; `cargo update` opts in | `https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html` | Hand-pinning `rev` in manifest is "tedious and error prone"; a lock is not a signature. |
| Cargo registry cache / vendoring | `registry/index`, `registry/cache`, `registry/src`; `cargo vendor` emits config | `--locked` asserts no resolution change; `--offline` may resolve **differently** than online; `--frozen` = both | `https://doc.rust-lang.org/cargo/commands/cargo-vendor.html`; `https://doc.rust-lang.org/cargo/guide/cargo-home.html` | Offline resolution divergence means "offline passed" is not "release reproducible". |
| Cargo workspaces / resolver | One resolver for whole workspace; virtual workspace must set `resolver` | resolver `2`/`3` for edition 2021/2024 | `https://doc.rust-lang.org/cargo/reference/workspaces.html`; `https://doc.rust-lang.org/cargo/reference/resolver.html` | A per-member pin without a workspace-wide resolver can select different feature sets. |
| rustup toolchains | `rust-toolchain.toml` channel/components/targets/profile; pin a date | `https://rust-lang.github.io/rustup/overrides.html`; `https://rust-lang.github.io/rustup/concepts/channels.html` | Missing components; `--force` installs newest despite missing component — a silent drift risk if copied naively. |
| npm `package-lock.json` | Exact tree, `integrity` sha512/SRI | `https://docs.npmjs.com/cli/v10/configuring-npm/package-lock-json` | Lock describes a tree, not a build; no signed identity. |
| pnpm | `pnpm-lock.yaml`, store hard links, `index.db` hashes, `--frozen-lockfile`, `--offline` | integrity mismatch is a hard failure since v11.4.0 | `https://pnpm.io/settings/store`; `https://pnpm.io/cli/install` | Store is "mutually trusted users" only — a shared cache is a trust boundary. |
| Deno | `deno.lock` exact version + integrity; `deno ci` = rm node_modules + frozen install; `vendor/` for hermetic | `https://docs.deno.com/runtime/packages`; `https://docs.deno.com/runtime/packages/supply_chain` | Frozen lock alone is not hermetic if remote source disappears. |
| Bun | text `bun.lock` (v1.2+), `--frozen-lockfile`, network concurrency default 64 | `https://bun.sh/docs/pm/lockfile`; `https://bun.sh/docs/pm/cli/install` | Unbounded parallelism knobs; must be bounded for reproducible, low-host-cost verification. |
| Nix | `flake.lock` graph with `rev` + NAR `narHash`; fixed-output derivations hash network inputs | `https://nix.dev/manual/nix/2.36/command-ref/new-cli/nix3-flake`; `https://nix.dev/manual/nix/2.26/language/advanced-attributes.html` | Input-addressing causes massive rebuilds when a URL changes; content-addressed outputs decouple path from fetch URL. |
| SLSA | Build L0–L3: L1 provenance exists, L2 signed + hosted, L3 hardened | `https://slsa.dev/spec/v1.0/levels` (page notes v1.2 is current; v1.0 retired) | Provenance at L1 may be unsigned; no source track in v1.0. |
| Sigstore / Cosign | Ephemeral key + Fulcio OIDC cert + Rekor log; verify identity, issuer, root of trust, log inclusion | `https://docs.sigstore.dev/about/overview` | No long-lived key to manage, but verification must check all four properties. |
| in-toto | Signed layout + functionary link files + artifact rules | `https://in-toto.io/docs/getting-started/` | Audit found layout/link replay and "functionaries do not verify" issues (`https://in-toto.io/blog/2023/security-audit/`) — tool cannot replace design discipline. |
| sccache | Compiler wrapper; cache key from compiler identity/flags/inputs/env; local + remote | `https://github.com/mozilla/sccache` | Cache hits need same compiler version and source path (`SCCACHE_BASEDIRS`); cold cache is a real cost. |

## 4. Design options and recommendation

- **A — Full signing now.** Adopt Cosign keyless + SLSA L2 provenance immediately.
  Rejected: requires a hosted build platform and OIDC identity we do not have;
  claiming it would be false (`distribution/SBOM_AND_COMPATIBILITY.md:90–105`).
- **B — Hash-only distribution.** Ship sha256 pins and the existing identity SBOM,
  no signatures. Honest and implementable, but cannot detect tampering by anyone
  who can rewrite the manifest hash table.
- **C — Staged identity ladder (RECOMMENDED).** Keep the current manifest, pins and
  SBOM as the single authority; add (i) a deterministic release *build record*
  that binds artifact hashes to a source revision and build inputs, (ii) optional
  detached Ed25519 signatures with an explicit pinned trust key (reusing the
  existing `verify_index_signature` design pattern in `registry.rs:188–224`), and
  (iii) only after a hosted signer exists, Cosign/SLSA-L2 provenance. Reconcile
  docs/tooling and `ci_contract.rs` to the `distribution/tools/` authority first.
  This matches SLSA's own ladder (L1 → L2) and never advertises unverified trust.

## 5. Data / model / lifetime design

- **Ownership:** one immutable `ReleaseBundle` = manifest + manifest schema +
  artifacts + SBOM + build record + optional signature sidecars, all under a
  single version directory `<prefix>/xylem-toolchain/<version>/`. Install writes
  a sibling `.xylem-rollback.json` snapshot before replacing files; uninstall
  restores from it and refuses paths escaping the version directory
  (`distribution/tools/install.py`, `uninstall.py`).
- **Canonical layout:** records sorted by key, LF endings, no timestamps unless
  explicitly requested — mirrors v3 lock canonicality (`lockfile.rs:279–285`).
- **Memory/hot paths:** parsing is per-state-change, not per-command;
  verify-by-digest streams files rather than whole-tree scans; the hot path is
  "hash artifact → compare pinned digest → compare identity constants".
- **Explicitly out of scope:** compiler/native/LLVM internals (L0/L1), capability
  runtime semantics and ports (L2), UI policy core and target adapters
  (L4a/L4b), L3 platform ports, framework/app business logic (L5/L6),
  performance certification, multi-platform support, network index refresh,
  multi-file registry archives. L3–L6 may be *read* as published inputs only.

## 6. API sketch (signatures and behavior only)

```text
# L7 CLI/namespace — no implementation implied
xylem release verify --manifest <file> [--bundle <dir>] [--offline] [--json]
    -> { schema:"xylem-cli-v1", ok:bool, matched:[identity], mismatched:[identity],
         unsigned:bool, artifacts:[{path, sha256, verified:bool}] }

xylem release record --manifest <file> --source-revision <sha> --artifacts <dir> \
    --out <build-record> [--json]
    -> deterministic record: source revision, pinned identities, artifact digests,
       build-input identities. No timestamp by default.

xylem release sign --bundle <dir> --key <path>     # optional, pin-verified key
xylem release verify-signature --bundle <dir> --key <path>

# manifest fields proposed (additive; additionalProperties remains false only after schema bump)
"integrity": { "algorithm":"sha256", "manifestSha256":"<hex>" }
"provenance": { "format":"xylem-build-record-v1", "signature":"<pem-or-null>" }
"trust":      { "mode":"unsigned"|"pinned-key"|"sigstore", "keyId":"<id-or-null>" }
```

Behavior: `verify` is read-only and offline-capable; it never edits pins. Any
MISMATCH or MISSING is nonzero. `record` refuses if a source revision is absent.

## 7. Performance budget + anti-pattern checklist

Budget (no invented numbers; claims remain `PENDING_VERIFICATION` until measured):
one manifest parse, one artifact hash pass, one identity-constant pass per
verification; bounded parallelism (at most the operator-selected `--jobs`);
zero network and zero privileged operations in `verify`/`check_distribution`.

Anti-pattern checklist (derived from D-001 rules and the compiler campaign):

- [ ] No repeated whole-tree scan across `verify`, `record` and `sign`.
- [ ] No re-parsing the same manifest or source document in multiple commands.
- [ ] No cold-cache "full rebuild" triggered by a verification command.
- [ ] No unbounded parallelism (Bun's default 64 is a knob, not a target).
- [ ] Installer performs no network and no privileged/root work; it writes only
      under `--prefix` (`distribution/README.md:42`).
- [ ] No fabricated support: unsupported target/platform → explicit diagnostic
      (`distribution/README.md:23–34`).
- [ ] No signature claim without an identity; no SBOM hash invented where no
      on-disk hash exists (`SBOM_AND_COMPATIBILITY.md:61–65`).
- [ ] No "offline passed" presented as release reproducible (Cargo `--offline`
      caveat above).

## 8. Interface requests to protected teams

1. **L0:** publish a stable, versioned "build-input identity" accessor exposing
   the existing IR/ABI/LLVM/artifact constants as data, so L7 never parses Rust
   source for identities (today `check_compatibility.py` matches source text).
2. **L0:** publish a pinned artifact-digest hook for the compiler/backend-host
   binaries so `record` can hash real artifacts rather than trust `toolchain.toml`.
3. **L2:** confirm the stdlib revision/version conflict (`SPEC_DISAGREEMENTS.md`
   items 2) so the lockfile `[stdlib]` identity is unambiguous.
4. **L3–L6:** none currently required. v2 permits L7 to consume their published
   interfaces, but this product needs no new port from the L3 substrate, L4a
   policy core, L4b adapters, L5 frameworks or L6 apps; if one appears, it is
   filed as a request, never mirrored in L7 (v2 §5).
5. **L0/L1:** no change requested to canonical IR, native ABI, LLVM pin, or
   ownership/lowering. No protected file is modified by this design.

## 9. Phased milestones with verification gates (no CI/deploy triggers)

| Phase | Deliverable (design intent) | Verification gate |
|---|---|---|
| 0 Reconcile sidecars | Rewrite `docs/tooling.md` release section to point at `distribution/tools/`; hand over stale `ci_contract.rs` assertions. Pins unchanged. | Doc/ tree consistency check passes; no pin diff. |
| 1 Deterministic record | `xylem release record` + schema; binds source revision + pinned identities + artifact digests. | Two runs byte-identical; mismatch on any pin change; no artifact built by this phase. |
| 2 Verify hardening | `xylem release verify` offline, bounded jobs, read-only. | Tamper fixture fails; no write outside prefix; unsupported target diagnosed. |
| 3 Optional pinned signatures | Detached Ed25519 with explicit trust key; reuses `verify_index_signature` pattern. | Verify fails on unknown key id / tampered bytes (mirrors `registry.rs:580–631` test). |
| 4 Hosted provenance (future) | SLSA L2 / Cosign keyless only after a hosted build platform and OIDC identity exist. | Level claimed only if signature + host + verification all demonstrated; else stays `PLANNED`. |

Each phase remains `PENDING_INDEPENDENT_VERIFICATION` until another agent
reproduces its commands and output. No CI, tag, or deploy is triggered by this doc.

## 10. Open questions, self-critique, and full source list

Open questions: (1) Who owns the signing identity and trust-root distribution?
(2) Will crates.io-style trusted publishing ever apply to a Xylem registry?
(3) Does the workspace lock need a single multi-member resolved graph rather
than member digests? (4) Which sidecar layout wins for `scripts/` vs `libexec/`?

**Self-critique pass.** Weakest assumption: that an Ed25519-signed release record
is meaningfully stronger than the existing sha256 pins. Contrary evidence:
in-toto's audit shows replay and "functionaries do not verify" weaknesses even
with signatures, and crates.io trusted publishing explicitly lists provenance
verification as *out of scope* (`https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html`).
Revision: signatures are demoted to an **optional** phase 3 with an explicit
trust key, and the recommended path stays hash+identity honesty (Option C) until
a hosted signer exists (phase 4). Second weakness: claiming SLSA guidance while
the spec site marks v1.0 retired and v1.2 current — corrected by citing both and
treating only the level definitions as stable. Third: "no repeated parsing" is
an aspiration until measured; marked `PENDING_VERIFICATION`, not a result.

Sources (all primary; exact URLs):
- https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html
- https://doc.rust-lang.org/cargo/guide/cargo-home.html
- https://doc.rust-lang.org/cargo/commands/cargo-vendor.html
- https://doc.rust-lang.org/cargo/reference/workspaces.html
- https://doc.rust-lang.org/cargo/reference/resolver.html
- https://rust-lang.github.io/rustup/overrides.html
- https://rust-lang.github.io/rustup/concepts/channels.html
- https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html
- https://docs.npmjs.com/cli/v10/configuring-npm/package-lock-json
- https://pnpm.io/settings/store ; https://pnpm.io/cli/install
- https://docs.deno.com/runtime/packages ; https://docs.deno.com/runtime/packages/supply_chain
- https://bun.sh/docs/pm/lockfile ; https://bun.sh/docs/pm/cli/install
- https://nix.dev/manual/nix/2.36/command-ref/new-cli/nix3-flake
- https://nix.dev/manual/nix/2.26/language/advanced-attributes.html
- https://slsa.dev/spec/v1.0/levels ; https://slsa.dev/spec/v1.0/provenance ; https://slsa.dev/spec/v1.0/requirements
- https://docs.sigstore.dev/about/overview ; https://docs.sigstore.dev/cosign/signing/overview
- https://in-toto.io/docs/getting-started/ ; https://in-toto.io/blog/2023/security-audit/
- https://cyclonedx.org/specification/overview
- https://github.com/mozilla/sccache
- Local: `docs/decisions/D-001-platform-layering.md` (v2, amended 2026-11-25;
  §§2,3,4,5,7,8,10,11), `xylem-lang/toolchain.toml`,
- Ports/adapters rationale cited by D-001 v2 §1:
  `https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html`,
  `https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html`,
  `https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff650258(v=pandp.10)`
  `xylem-rust/{AGENTS.md,docs/tooling.md,crates/xylem-toolchain/src/*}`,
  `ecosystem-worktrees/xylem-rust/distribution/*`,
  `ecosystem-readiness/work_logs/archive/SPEC_DISAGREEMENTS.md`.
