#!/usr/bin/env bash
# Verify the Lotus contract phase in a Xylem worktree.
# Usage: verify_lotus_contract_phase.sh <worktree-root>
# No compiler builds, no network, no CI. Uses only the pinned artifact.
set -uo pipefail

ROOT="${1:?usage: verify_lotus_contract_phase.sh <worktree-root>}"
BASE="/home/philip/Development/version_2"
BOOT="$BASE/xylem-lang/target/pinned-toolchain/artifacts/xylem.previous-7082acd9"
HOST="$BASE/xylem-lang/target/pinned-toolchain/artifacts/xylem-backend-host"
export XYLEM_BOOTSTRAP="$BOOT"
export XYLEM_BACKEND_HOST="$HOST"
export XYLEM_STDLIB_ROOT="$ROOT/stdlib/src"

fail=0
cd "$ROOT" || exit 2

echo "== structure =="
for path in lotus/contracts lotus/tests lotus/schemas lotus/fixtures lotus/tools; do
  if [[ -d "$path" ]]; then echo "OK $path"; else echo "FAIL missing $path"; fail=1; fi
done

echo "== Xylem contract and kernel modules =="
shopt -s nullglob
modules=(lotus/contracts/*.xy lotus/modules/*.xy)
if (( ${#modules[@]} == 0 )); then echo "FAIL no kernel modules"; fail=1; else echo "OK module count ${#modules[@]}"; fi

echo "== Xylem contract tests (compile + execute) =="
tests=(lotus/tests/*.xy)
if (( ${#tests[@]} == 0 )); then echo "FAIL no contract tests"; fail=1; fi
for t in "${tests[@]}"; do
  out=$(timeout 90 "$BOOT" check "$t" 2>&1); rc=$?
  if (( rc == 0 )); then echo "OK check $t :: $(echo "$out" | tail -1)"; else echo "FAIL check $t: $out"; fail=1; fi
done
for t in "${tests[@]}"; do
  out=$(timeout 90 "$BOOT" test "$t" 2>&1); rc=$?
  if (( rc == 0 )); then echo "OK test $t :: $(echo "$out" | tail -2 | tr '\n' ' ')"; else echo "FAIL test $t: $out"; fail=1; fi
done

echo "== project-level test gate =="
if [[ -f lotus/xylem.toml ]]; then
  out=$(timeout 120 "$BOOT" test lotus 2>&1); rc=$?
  if (( rc == 0 )); then echo "OK xylem test lotus :: $(echo "$out" | tail -1)"; else echo "FAIL xylem test lotus: $out"; fail=1; fi
else
  echo "FAIL missing lotus/xylem.toml"; fail=1
fi

echo "== schema/fixture validator =="
if [[ -f lotus/tools/validate_lotus.py ]]; then
  out=$(python3 lotus/tools/validate_lotus.py --fixtures lotus/fixtures 2>&1); rc=$?
  if (( rc == 0 )); then echo "OK validator :: $(echo "$out" | tail -1)"; else echo "FAIL validator: $out"; fail=1; fi
  out=$(python3 lotus/tools/test_validate_lotus.py 2>&1); rc=$?
  if (( rc == 0 )); then echo "OK validator tests :: $(echo "$out" | tail -1)"; else echo "FAIL validator tests: $out"; fail=1; fi
else
  echo "FAIL missing validate_lotus.py"; fail=1
fi

echo "RESULT: $( (( fail == 0 )) && echo PASS || echo FAIL )"
exit "$fail"
