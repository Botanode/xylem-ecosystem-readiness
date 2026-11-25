# Pinned compiler dependency for this campaign

Source of truth: `xylem-lang/toolchain.toml` (committed at `da35dfe`).
We consume **pinned released artifacts and their documented interfaces**, never the
uncommitted native/performance WIP currently present in the `xylem-rust` and
`xylem-research` main working trees.

## Pinned artifacts

| Component | Source revision | Artifact / identity | SHA-256 |
|---|---|---|---|
| Bootstrap compiler (`xylem`) | `5ff0ba2a949aea8acb08fe5cc4e8a5dbd855dcc4` | `xylem`, version `1.0.0` | `7082acd9baf0d0370a84efd67f25ae3dab470dce4b0ba440f945b7687748704c` |
| Backend host (`xylem-backend-host`) | `7fe37434c868908cea37fc55475929cea2a15590` | `xylem-backend-host` | `2e2d75fb2870e1106883351424e954d00680cedb0d7e333e7058056afa5d83b2` |

## Protocol / compatibility identities

| Interface | Identifier | Where asserted |
|---|---|---|
| Canonical IR request schema | `xylem-bootstrap-ir/1` | `toolchain.toml [protocol]`, `xylem-backend-host/src/lib.rs:20` |
| Native backend ABI | `xylem-native/16` | `toolchain.toml [protocol]`, `xylem-native/src/lib.rs:15` |

Language / stdlib / conformance revision recorded in `toolchain.toml [revisions]`:
`e19bc963019076247a803423255ffc1cb1bbf0a5`.

## Campaign worktree baselines

| Repository | Committed baseline | Note |
|---|---|---|
| xylem-rust | `28cd5cb3efc9cba63814b7d6152feadeb64e6a1d` | clean committed snapshot; main tree has unrelated protected WIP |
| xylem-lang | `da35dfef814d9b3b7de1bd3eae844f833f06d92a` | clean |
| xylem-platform | `d5a08ae880b2a85e65828b8e8838026f9b48d10f` | clean |

## Rules

- Tooling code may rely on stable interfaces listed in `COMPATIBILITY_NOTES.md`.
- A tooling change that needs a new compiler interface must ship a **local adapter**
  or a written interface request in `DEFECT_HANDOVERS/`; it must not edit protected
  compiler source.
- Updating this pin requires the same recorded decision + independent confirmation
  that `xylem-lang/AGENTS.md` requires for toolchain-pin changes. This campaign
  does **not** update the pin.
- Compatibility risks from the native transformation are tracked in
  `COMPATIBILITY_NOTES.md`; re-check before any integration merge.
