#!/usr/bin/env bash
# Which native modules does *lowering* actually read?
#
# A module referenced only by another module's tests or by a sibling proof
# module (native_struct_ctor reading native_ref_abi, say) does not change
# emitted code. Only a caller in the lowering path does.
#
# History that motivated this check: ../wiki/decisions/inert-wiring.md
# A call is necessary but not sufficient: the caller must also USE the result.
# This script finds candidates; confirm with a gate-toggles-IR test.
#
# Usage: check-consumption.sh [crate-dir]   (default crates/xylem-llvm/src)
# Exit: 0 always; this is an inventory, not a gate.

set -uo pipefail
src="${1:-crates/xylem-llvm/src}"
[ -d "$src" ] || { echo "no such directory: $src" >&2; exit 0; }

# Files on the lowering path. lower_emit/ is a child module of full_lower.
lowering=("$src/full_lower.rs")
while IFS= read -r f; do lowering+=("$f"); done < <(find "$src/lower_emit" -name '*.rs' 2>/dev/null)

consumed=(); unconsumed=()

for file in "$src"/native_*.rs; do
  module="$(basename "$file" .rs)"
  [ "$module" = "native_wiring" ] && continue

  found=0
  for caller in "${lowering[@]}"; do
    [ -f "$caller" ] || continue
    # A use path, or a plan/emitter call on the module.
    if grep -qE "${module}::[a-zA-Z_]" "$caller"; then
      found=1
      break
    fi
  done

  if [ "$found" -eq 1 ]; then consumed+=("$module"); else unconsumed+=("$module"); fi
done

echo "READ BY LOWERING (${#consumed[@]}):"
printf '  %s\n' "${consumed[@]}"
echo
echo "NOT READ BY LOWERING (${#unconsumed[@]}):"
printf '  %s\n' "${unconsumed[@]}"
echo
echo "Not read = no effect on emitted code, whatever its tests claim."
echo "Referenced is not consumed; a discarded result is not an integration."
