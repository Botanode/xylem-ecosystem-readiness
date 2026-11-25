#!/usr/bin/env bash
# Supervised subagent dispatch.
#
# The first wave of agents died silently: `opencode run` exited without output
# and nothing noticed. This wrapper makes failure loud and checkable.
#
# Usage: dispatch.sh <id> <work-order> <worktree> <expect-path> <instruction>
#   id           short name for logs
#   work-order   path to the work order the agent must read
#   worktree     directory the agent works in
#   expect-path  file the agent must create or modify ("" to skip the check)
#   instruction  the prompt
#
# Exit: 0 when the agent finished AND expect-path exists; 2 when the agent
# exited non-zero; 3 when it exited 0 but produced nothing.

set -uo pipefail
id="$1"; wo="$2"; wt="$3"; expect="$4"; instruction="$5"
logdir="${XYLEM_DISPATCH_LOGS:-/tmp/xylem-dispatch}"
mkdir -p "$logdir"
log="$logdir/$id.log"

{
  echo "=== $id ==="
  echo "started: $(date -Is)"
  echo "work-order: $wo"
  echo "worktree: $wt"
} > "$log"

before=""
if [ -n "$expect" ] && [ -e "$expect" ]; then
  before="$(sha1sum "$expect" | cut -d' ' -f1)"
fi

cd "$wt" || { echo "no such worktree: $wt" >> "$log"; exit 2; }

timeout "${XYLEM_DISPATCH_TIMEOUT:-5400}" \
  opencode run --auto --archived --title "$id" \
  "Read $wo first, then every wiki page it names. Work only inside $wt. $instruction" \
  >> "$log" 2>&1
status=$?

{
  echo "---"
  echo "exit: $status"
  echo "finished: $(date -Is)"
} >> "$log"

if [ "$status" -ne 0 ]; then
  echo "$id FAILED (exit $status) — see $log"
  exit 2
fi

if [ -n "$expect" ]; then
  if [ ! -e "$expect" ]; then
    echo "$id EXITED CLEAN BUT $expect IS MISSING — see $log"
    exit 3
  fi
  if [ -n "$before" ] && [ "$(sha1sum "$expect" | cut -d' ' -f1)" = "$before" ]; then
    echo "$id EXITED CLEAN BUT $expect IS UNCHANGED — see $log"
    exit 3
  fi
fi

echo "$id OK — log $log"
