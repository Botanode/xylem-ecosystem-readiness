# Compiler defect handovers

When an independent fixture/tool exposes a defect in a **protected** subsystem,
record it here. Do **not** fix protected compiler source and do **not** add a
silent workaround to tooling. Copy `TEMPLATE.yaml` to `XY-NNNN.yaml`.

Handovers are consumed by the compiler / performance campaign
(`integration/native-swarm-100`). A handover must contain a minimal reproducer
that the receiving team can run verbatim.

## Current handovers

(None yet — add as discovered.)

## Rules

- One defect per file; stable `defect_id`.
- Record the exact compiler revision / artifact hash used.
- Expected vs observed behavior must be unambiguous.
- `specification_reference` points to the normative doc, not a guess.
- `suspected_subsystem` is a hypothesis; state confidence.
- Keep the reproducer in an independently owned fixture directory.
