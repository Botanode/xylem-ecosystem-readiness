#!/usr/bin/env python3
"""Compare two full-conformance reports and report black-box diagnostic drift.

No compiler build, benchmark or performance claim. Inputs are reports produced by
independent-conformance/tools/run_corpus.py.
"""
import argparse
import json
from pathlib import Path


def load(path):
    data = json.loads(Path(path).read_text())
    cases = {c['id']: c for c in data.get('cases', [])}
    return data, cases


def codes(case):
    observed = case.get('observed', {})
    runs = observed.get('runs', [])
    result = []
    for run in runs:
        result.extend(run.get('observed_diagnostic_codes', []))
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--baseline', required=True)
    ap.add_argument('--candidate', required=True)
    args = ap.parse_args()

    base_meta, base = load(args.baseline)
    cand_meta, cand = load(args.candidate)
    drift = []

    for case_id in sorted(set(base) | set(cand)):
        b, c = base.get(case_id), cand.get(case_id)
        if b is None:
            drift.append((case_id, 'ADDED', str(c.get('status'))))
            continue
        if c is None:
            drift.append((case_id, 'REMOVED', str(b.get('status'))))
            continue
        if b.get('status') != c.get('status'):
            drift.append((case_id, 'STATUS', f"{b.get('status')} -> {c.get('status')}"))
        if codes(b) != codes(c):
            drift.append((case_id, 'CODES', f"{codes(b)} -> {codes(c)}"))
        if b.get('observed', {}).get('stdout') != c.get('observed', {}).get('stdout'):
            drift.append((case_id, 'STDOUT', 'changed'))
        if b.get('observed', {}).get('exit') != c.get('observed', {}).get('exit'):
            drift.append((case_id, 'EXIT', f"{b.get('observed',{}).get('exit')} -> {c.get('observed',{}).get('exit')}"))

    print(f"baseline cases: {len(base)} | candidate cases: {len(cand)}")
    print(f"baseline compiler: {base_meta.get('compiler')}")
    print(f"candidate compiler: {cand_meta.get('compiler')}")
    print(f"drift findings: {len(drift)}")
    for row in drift:
        print('DRIFT', *row)
    print('RESULT:', 'NO_DRIFT' if not drift else 'DRIFT_DETECTED')
    raise SystemExit(bool(drift))


if __name__ == '__main__':
    main()
