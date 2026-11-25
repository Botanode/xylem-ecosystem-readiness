# Specification disagreements flagged for A003 / language authority

These are **documentation consistency issues**, not compiler defects. No normative
language semantics were changed by this campaign. Do not "resolve" them by editing
the contract to match an implementation; flag to the responsible authority.

| # | Disagreement | Sources | Flagged by | Status |
|---|---|---|---|---|
| 1 | Frozen 1.0 primitive/feature set: `scope.md` §2.1 commits `i32/i64/u64/usize/bool/String/Unit`; `contract.md` §2.1 lists `i8/i16/u8/u16/u32/f32/f64/char` as MUST accept; `contract.md` "Supported language surface" also mentions async, closures, `?`, growable collections | `docs/language/scope.md`, `docs/language/contract.md` | E052, F064 | PENDING_A003 |
| 2 | Standard-library version: `scope.md` says `1.0.0`; `contract.md` §14.3 says `1.15.0` (toolchain asset `lock_integrity.xy` also references `1.15.0` with a fallback digest) | same | F064 | PENDING_A003 |
| 3 | Backend authority: `scope.md` §5.4 says Cranelift supported / C++ lowering experimental; `xylem-lang/AGENTS.md` says LLVM is the release backend | `scope.md`, `AGENTS.md` | F064 | PENDING_A003 |
| 4 | Conformance counts: `scope.md` §5.2 and `contract.md` §13 say 138/138; `scope.md` §8.2 says 154; current manifest has 155 cases | same + `conformance/manifest.json` | F064 | PENDING_A003 |
| 5 | Trap-code range: `scope.md` §2.1 `R6001`–`R6007`; `contract.md` §12.2 `R6001`–`R6009` | same | F064 | PENDING_A003 |
| 6 | `contract.md` L04 vs its Concurrency section on parallel-policy backend support | `contract.md` | F064 | PENDING_A003 |
| 7 | `docs/README.md` published 405 tests while root `README.md` published 409 (the doc-count gate guarded only the first snapshot). Updated to a consistent 409 during F064 integration; the underlying cause is a second unguarded snapshot | `docs/README.md` | F064, A004 | FIXED_IN_SNAPSHOT (guard gap remains) |

## Independent-conformance corpus note

E052 deliberately avoided the ambiguity in item 1 by using only syntax present in
the "Supported language surface" and existing `.xy` files. Until item 1 is
resolved, fixture authors cannot determine a single unambiguous 1.0 surface from
the two normative pages. All 31 corpus cases remain `PENDING_VERIFICATION`.
