#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p bin logs reports raw visuals
if [ -n "${PYTHONOPTIMIZE:-}" ]; then
  echo "PYTHONOPTIMIZE must be unset: acceptance assertions must run." >&2
  exit 2
fi
command -v bend >/dev/null
command -v lean >/dev/null
command -v clang >/dev/null
bend PROOF.bend > logs/replay-proof.txt 2>&1
bend PROOF.bend --verdict > logs/replay-verdict.txt 2>&1
bend PROOF.bend -o PROOF.bendtt > logs/replay-proof-export.txt 2>&1
bend tests.bend > logs/replay-tests.txt 2>&1
bend oracle.bend -o bin/oracle > logs/replay-oracle-build.txt 2>&1
bend bench.bend -o bin/bench > logs/replay-bench-build.txt 2>&1
bend oracle.bend -o bin/oracle.c > logs/replay-oracle-c.txt 2>&1
bend bench.bend -o bin/bench.c > logs/replay-bench-c.txt 2>&1
python scripts/verify.py
python scripts/oracle.py
# Run benchmarks without concurrent oracle or rendering work.
python scripts/benchmark.py
python scripts/runtime_limits.py
python scripts/present.py
# Optional canonical chart regeneration requires the Notion chart builder.
# The exact prebuilt fragment and four browser captures ship in visuals/.
python scripts/dashboard.py
python audit_vision.py
