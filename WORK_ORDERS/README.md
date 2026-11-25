# Work orders

Every dispatched agent gets one concrete, bounded work order. Copy `TEMPLATE.yaml`
to `<agent-id>.yaml` before changing an agent's status from `unassigned`.

A work order must name exact files to extend, required tests, required verification
and protected areas to avoid. Vague objectives are not valid work orders.

## Required fields

`agent_id`, `squad`, `repository`, `starting_revision`, `branch`, `objective`,
`owned_files`, `allowed_write_paths`, `protected_areas`, `existing_implementation`,
`required_changes`, `required_tests`, `required_verification`, `dependencies`,
`acceptance_criteria`, `integration_owner`.

## Dispatch log

| Agent | Work order | Status |
|---|---|---|
| A001–A004 | governance (this control plane) | in_progress |
| B/C/D/E/F/G/H/I | created on dispatch after tooling inventory | unassigned |
