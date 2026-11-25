# Xylem Ecosystem & Production-Readiness Campaign — Control Plane

This directory is the **independent** engineering campaign control plane. It is
separate from the native compiler / performance campaign.

## Purpose

Make Xylem practical to learn, develop with, distribute, integrate and deploy —
while a separate team makes Xylem correct and fast. We extend existing tooling;
we do not build parallel architectures.

## Operating rules (non-negotiable)

1. **Protected areas are off-limits.** Native representation, native primitive
   lowering, integer machine operations, bitwise operations, and the benchmark
   harness are owned by the compiler campaign. No edits, and no workarounds that
   hide compiler defects. Defects are handed over, not patched.
2. **Work only in isolated worktrees/branches.** See `OWNERSHIP_REGISTRY.yaml`.
   Never edit a `main` working tree that the performance campaign may be using.
3. **Consume stable, pinned interfaces.** Consume released artifacts and their
   documented CLI, diagnostic, IR, and ABI surfaces. Never depend on unpublished
   WIP in protected crates.
4. **Extend, do not duplicate.** Inspect existing implementations first. If a
   tool already exists (LSP, formatter, CLI, conformance runner, docs), extend
   it.
5. **Verify honestly.** `IMPLEMENTED / PENDING_VERIFICATION` is the default
   claim until a check actually runs and passes. Do not run heavy builds or
   benchmarks on a shared measurement host.
6. **No unauthorized CI, push, deploy or toolchain-pin changes.**

The exact pinned revisions, artifact digests, and stable-interface list live in
`work_logs/archive/PINNED_DEPENDENCY.md` and
`work_logs/archive/COMPATIBILITY_NOTES.md`. `toolchain.toml` in `xylem-lang`
remains the source of truth for the pin.

## Tooling language rule

New tooling is Xylem-only (D-007). The `tools/*.py` and `tools/*.sh` helpers in
this repository are **deprecated historical artifacts** kept for reproducibility
of earlier evidence; no new features go into them. Xylem replacements are being
built under `xylem-lang/tools/`.

## Directory layout

```text
ecosystem-readiness/
├── README.md                 # this file: purpose, rules, layout
├── AGENTS.md                 # agent rules + documentation policy
├── OWNERSHIP_REGISTRY.yaml   # agent -> repo/branch/owned paths/status
├── ASSIGNMENTS.yaml          # all 100 specialist assignments (A001..I100)
├── WORK_ORDERS/              # one bounded work order per dispatched agent
├── DEFECT_HANDOVERS/         # compiler defects escalated (never fixed here)
├── docs/decisions/           # accepted campaign decisions
└── work_logs/archive/        # completed campaign phases and control records
```

## Worktrees

| Repository | Integration branch | Worktree | Baseline |
|---|---|---|---|
| xylem-rust   | `integration/ecosystem-readiness` | `ecosystem-worktrees/xylem-rust`   | `28cd5cb` |
| xylem-lang   | `integration/ecosystem-readiness` | `ecosystem-worktrees/xylem-lang`   | `da35dfe` |
| xylem-platform | `integration/ecosystem-readiness` | `ecosystem-worktrees/xylem-platform` | `d5a08ae` |

`xylem-research` is **not** checked out here: its working tree contains active
benchmark-harness WIP owned by the performance campaign. We do not touch it.

## Documentation

| Where | Contents |
| --- | --- |
| `README.md` | This file: the single entry point. |
| `AGENTS.md` | Agent rules and documentation policy. |
| `docs/decisions/` | Accepted campaign decisions. |
| `work_logs/README.md` | Phase index; no active phase log yet. |
| `work_logs/archive/` | Governance backlog, dispatch log, integration status, and the former control documents. |
| `WORK_ORDERS/`, `DEFECT_HANDOVERS/` | Operational YAML records and their READMEs. |

Do not add handover, status, briefing, wave, or dispatch documents beside
current material. Record campaign history in `work_logs/archive/`.

## Concurrency policy

100 assignments are a division of responsibility, not 100 simultaneous processes.
Concurrency is capped by task independence and host resources. Read-only
exploration is cheap; heavy builds/tests are run only when isolated and focused,
never concurrently with performance measurement windows.
