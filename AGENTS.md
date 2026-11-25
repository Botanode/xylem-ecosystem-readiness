# Agent instructions: ecosystem-readiness

## Documentation policy

Code, tests, and generated artifacts are the source of truth. Documentation
records intent and history; it never overrides the tree.

The documentation surface is:

- `README.md` — the single entry point: what this project is, how to build and
  verify it, and where the authoritative code lives.
- `work_logs/phase-NN-*.md` — one log per phase. Active phases stay here;
  completed phases move to `work_logs/archive/`.
- `docs/decisions/` — accepted decision records, condensed to an index plus the
  decision text.

Do not add handover, status, briefing, wave, dispatch, scoreboard, or duplicate
work-log documents. When a doc claim and the tree disagree, fix or archive the
document; never change code to match a stale document.
