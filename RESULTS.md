# Local acceptance results

Rechecked at 2026-10-17T07:29:31.706985+00:00.

- 31 laws accepted by Bend and independently by BendTT (`--verdict`).
- 12 concrete proof examples accepted.
- 500 unique SymPy formulas: zero mismatches; VM and numerical controls passed.
- Seven malformed inputs and the deliberately false proof were rejected.
- Four native Nat boundary tests passed.
- 45 isolated benchmark measurements; eight AST edges and three visual mutation controls passed.
- Text/layout checks passed. Manual image review status is recorded separately.

## Benchmark: fresh measurements

Five measured runs and one warm-up for each configuration. Integer millisecond timer; synthetic balanced workload.

| Actual AST depth | CPU threads | Median diff + optimize, ms | Measured range, ms |
|---|---|---|---|
| 16 | 1 | 4 | 3–6 |
| 16 | 2 | 2 | 2–3 |
| 16 | 4 | 2 | 2–2 |
| 17 | 1 | 8 | 7–8 |
| 17 | 2 | 5 | 5–6 |
| 17 | 4 | 6 | 5–6 |
| 18 | 1 | 29 | 17–38 |
| 18 | 2 | 12 | 9–17 |
| 18 | 4 | 13 | 12–13 |

Depth-18 derivative node count: 655,359 → 262,143 (about 60% fewer nodes).
These measurements are not a general native speedup guarantee.

## Publication boundaries

- The proven pass is Expr → abstract stack VM, not Bend's native C backend or Clang.
- Native Nat is limited to 2^48−1. Universal native execution is not proven.
- The GitHub Actions configuration is prepared and checked locally; remote CI has not run.
- Original project materials use MIT; upstream Bend runtime portions retain Apache-2.0. See LICENSE-NOTICE.md and THIRD_PARTY_NOTICES.md.
