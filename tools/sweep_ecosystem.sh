#!/usr/bin/env bash
# Ecosystem regression sweep against the exact pinned compiler.
# Produces fast, source-level signal for the compiler team without running
# benchmarks or rebuilding the compiler.
# Usage: sweep_ecosystem.sh <xylem-lang-worktree-root>
set -uo pipefail

ROOT="${1:?usage: sweep_ecosystem.sh <xylem-lang-worktree-root>}"
BASE="/home/philip/Development/version_2"
BOOT="$BASE/xylem-lang/target/pinned-toolchain/artifacts/xylem.previous-7082acd9"
HOST="$BASE/xylem-lang/target/pinned-toolchain/artifacts/xylem-backend-host"
export XYLEM_BOOTSTRAP="$BOOT" XYLEM_BACKEND_HOST="$HOST" XYLEM_STDLIB_ROOT="$ROOT/stdlib/src"

cd "$ROOT" || exit 2
pass=0
fail=0
declare -a failures

step() {
  local label="$1"; shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  if (( rc == 0 )); then
    printf 'OK   %-38s %s\n' "$label" "$(printf '%s' "$out" | tail -1)"
    pass=$((pass+1))
  else
    printf 'FAIL %-38s %s\n' "$label" "$(printf '%s' "$out" | tail -3 | tr '\n' ' ')"
    fail=$((fail+1))
    failures+=("$label")
  fi
}

echo "=== pinned identities ==="
printf 'compiler sha256 %s\n' "$(sha256sum "$BOOT" | cut -d' ' -f1)"
printf 'backend path    %s\n' "$HOST"

echo "=== contract + corpus gates ==="
step corpus-validator python3 independent-conformance/tools/validate_corpus.py
step corpus-runner-tests python3 independent-conformance/tools/test_run_corpus.py
step lotus-harness bash "$BASE/ecosystem-readiness/tools/verify_lotus_contract_phase.sh" "$ROOT"

echo "=== example gates ==="
step examples-structural python3 examples/ecosystem_examples_check.py
for app in config-counter text-stats task-list web-router project-inspector networking-echo web-framework lotus-web-consumer lotus-server-consumer lotus-desktop-consumer lotus-mobile-consumer; do
  step "test examples/$app" timeout 90 "$BOOT" test "examples/$app"
done

echo "=== web framework gates ==="
step framework-tests timeout 90 "$BOOT" test framework/web/tests/framework.xy
step web-framework-example timeout 90 "$BOOT" test examples/web-framework-aurelia
step l4a-adapter-tests python3 framework/web/tools/test_emit_l4a.py
step web-component-checker python3 examples/web-framework-aurelia/tools/check_components.py examples/web-framework-aurelia

echo "=== application ports ==="
if [[ -d apps/cedar ]]; then step test-apps-cedar timeout 90 "$BOOT" test apps/cedar; fi
if [[ -d apps/orchid ]]; then step test-apps-orchid timeout 90 "$BOOT" test apps/orchid; fi

echo "=== documentation gates ==="
for gate in check-semantic-decisions check-limits-classification check-spec-citations check-markdown-links check-doc-counts; do
  step "$gate" timeout 120 ./scripts/run-xy.sh "scripts/${gate}.xy"
done

echo "=== skills gate ==="
step skills-validator python3 .agents/skills/validate.py

echo "=== compiler surface ==="
step compiler-surface python3 "$BASE/ecosystem-readiness/tools/compiler_surface_report.py" --root "$ROOT" --out "$BASE/ecosystem-readiness/reports/compiler-surface.json"

echo "=== SUMMARISED RESULT: PASS=$pass FAIL=$fail ==="
if (( fail > 0 )); then printf 'failed gates: %s\n' "${failures[*]}"; fi
exit $(( fail > 0 ))
