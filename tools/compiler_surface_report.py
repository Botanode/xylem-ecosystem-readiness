#!/usr/bin/env python3
"""Generate a deterministic compiler-surface report from the pinned compiler.

Runs `xylem check --json` over the ecosystem's Xylem workloads and records
module/function counts and diagnostics. This is a source-level regression
surface, NOT a benchmark: no timings, ratios or performance claims.
"""
import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

BASE = Path('/home/philip/Development/version_2')
BOOT = BASE / 'xylem-lang/target/pinned-toolchain/artifacts/xylem.previous-7082acd9'
HOST = BASE / 'xylem-lang/target/pinned-toolchain/artifacts/xylem-backend-host'

WORKLOADS = [
    'examples/config-counter/src/main.xy',
    'examples/text-stats/src/main.xy',
    'examples/task-list/src/main.xy',
    'examples/web-router/src/main.xy',
    'examples/project-inspector/src/main.xy',
    'examples/networking-echo/src/main.xy',
    'examples/web-framework/src/main.xy',
    'examples/lotus-web-consumer/src/main.xy',
    'examples/lotus-server-consumer/src/main.xy',
    'examples/lotus-desktop-consumer/src/main.xy',
    'examples/lotus-mobile-consumer/src/main.xy',
    'apps/cedar/src/main.xy',
    'apps/cedar/src/assessment_main.xy',
    'apps/orchid/src/main.xy',
    'apps/orchid/src/plugin_report.xy',
    'apps/orchid/src/graph_report.xy',
    'apps/orchid/src/session_report.xy',
    'apps/orchid/src/sdk_report.xy',
    'examples/web-framework-aurelia/src/main.xy',
    'framework/web/tests/framework.xy',
]


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', type=Path, required=True)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    root = args.root.resolve()
    env = {
        'PATH': '/usr/bin:/bin',
        'XYLEM_BOOTSTRAP': str(BOOT),
        'XYLEM_BACKEND_HOST': str(HOST),
        'XYLEM_STDLIB_ROOT': str(root / 'stdlib/src'),
    }
    rows = []
    for rel in WORKLOADS:
        path = root / rel
        if not path.is_file():
            rows.append({'workload': rel, 'status': 'MISSING'})
            continue
        proc = subprocess.run(
            [str(BOOT), 'check', rel, '--json'],
            cwd=root, env=env, capture_output=True, text=True, timeout=90,
        )
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError:
            payload = {'raw_stdout': proc.stdout[-500:], 'raw_stderr': proc.stderr[-500:]}
        rows.append({
            'workload': rel,
            'exit': proc.returncode,
            'source_sha256': sha256(path),
            'modules': payload.get('modules'),
            'functions': payload.get('functions'),
            'ok': payload.get('ok'),
            'diagnostics': payload.get('diagnostics'),
        })
    report = {
        'generated_utc': datetime.now(timezone.utc).isoformat(),
        'purpose': 'source-level compiler regression surface; not a benchmark',
        'compiler_sha256': sha256(BOOT),
        'backend_host_path': str(HOST),
        'backend_host_sha256': sha256(HOST),
        'workloads': rows,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    bad = [r['workload'] for r in rows if r.get('exit') != 0 or r.get('ok') is not True]
    print(f'compiler-surface: {len(rows)} workloads, {len(bad)} failing')
    for name in bad:
        print('FAIL', name)
    print('report:', args.out)
    raise SystemExit(bool(bad))


if __name__ == '__main__':
    main()
