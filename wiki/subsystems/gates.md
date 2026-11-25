# Subsystem: representation gates

Environment switches read at lowering time in
`crates/xylem-llvm/src/full_lower.rs`. State as of `task/native-vec-default@e53c650`
(2026-11-26).

## Default ON (rollback by setting `=0`)

| Switch | Function | Covers |
| --- | --- | --- |
| `XYLEM_LLVM_ABI_VERIFY` | `abi_verify_enabled` | P0 call-edge verification. Correctness gate. |
| `XYLEM_LLVM_NATIVE_STRING` | `native_string_enabled` | Native string reads. |
| `XYLEM_LLVM_NATIVE_SLICE` | `native_slice_enabled` | Two-word slices. |
| `XYLEM_LLVM_NATIVE_MAP` | `native_map_enabled` | Map lookup specialization. |
| `XYLEM_LLVM_NATIVE_VEC` | `native_vec_enabled` | Native vector representation. |
| `XYLEM_LLVM_NATIVE_STRUCT` | `native_struct_enabled` | Inline aggregate slots. Also gates enum slots. |
| `XYLEM_LLVM_NATIVE_VEC_MUTATE` | plan-level | Vec mutation. |
| `XYLEM_LLVM_NATIVE_MAP_TYPED` | plan-level | Typed I64 map insert/remove. |
| `XYLEM_LLVM_GENERAL_NATIVE` | `general_native_enabled` | General native storage. |
| `XYLEM_LLVM_FRAME_ELISION` | `frame_elision_enabled` | Frame elision. |

## Default OFF (opt-in with `=1`)

| Switch | Covers |
| --- | --- |
| `XYLEM_LLVM_NATIVE_ENUM` | Enum / Option native lowering. |
| `XYLEM_LLVM_NATIVE_CLOSURE` | Closure environments and thunks. |
| `XYLEM_LLVM_NATIVE_PLACE` | Mutable field-place borrows. |
| `XYLEM_LLVM_NATIVE_REF_ABI` | Reference ABI. |
| `XYLEM_LLVM_NATIVE_STRUCT_CTOR` | Struct constructor plan. |
| `XYLEM_LLVM_NATIVE_METADATA` | LLVM metadata emission. |
| `XYLEM_LLVM_UNIQUE_OWNERSHIP` | Move / unique ownership. |

## Why the split matters

The default-ON set is the verified spine. Everything default-OFF is either
unverified, or verified but not yet given the full pinned-suite run the
registry requires before a default flip.

An agent promoting a gate from OFF to ON must run, with the gate on and with it
off: `--lib`, the construct's own suite, `impl_*`, `cross_backend_differential`,
`p0_abi_verifier`, and any construct whose plan touches the same slot class. A
green construct suite alone is not sufficient; see failure modes 2 and 3 in
[failures.md](../failures.md).

## Reading a gate correctly

`std::env::var(...).map(|v| v != "0" && v != "false").unwrap_or(true)` means
default ON. `matches!(v.to_ascii_lowercase().as_str(), "1"|"true"|"on")` means
default OFF. Do not infer the default from the doc comment; the comment has been
wrong before.
