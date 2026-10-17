# BEND-AUTODIFF-COMPILER

A verified polynomial core over Nat[x], a symbolic differentiator,
an algebraic optimizer, and a compiler targeting a stack virtual machine.

## Results

- Bend 2.0.37; Lean 4.34.0 for BendTT; Clang 15.0.7; SymPy 1.14.0.
- Phase 1: 15 foundational arithmetic laws; `bend PROOF.bend` — exit 0.
- Phase 2: Expr/eval/diff/optimize/compile/exec_vm; 12 checked examples.
- Phase 3: 31 laws in total; both the standard check AND `--verdict` — exit 0,
  `ALL PROOFS CHECK`. No production law has been omitted.
- Phase 4: 500 unique random formulas, seed=20261017, zero mismatches;
  45 isolated benchmark measurements; a visual audit with three separate
  mutation-based negative controls.

## Important scope limitations

**This is not end-to-end verification of a native compiler at CompCert's level.**
The general theorems concern source-level Bend functions and the mathematical
semantics of Nat, Expr, and lists. The verified pass is Expr → instructions →
abstract VM, for any Expr, input x, and stack tail s.

This project does not verify Bend's C backend, Clang optimizations, the
scheduler, memory management, or FFI. The additional BendTT check validates
the translated proofs, but the translation itself also remains within the
trust boundary. PROOF.bendtt is included for inspection.

**Native Nat in the installed runtime is limited to 2^48−1 = 281474976710655.**
This is explicit in the generated C (`NAT_IMM`, `nat_chk`, `nat_mul`) and has
been checked with boundary tests. Multiplication beyond that range produces
a runtime error; an oversized input is rejected by the parser. Therefore,
the universal source-level theorem does NOT imply successful native execution
for arbitrarily large natural numbers. All empirical oracle and benchmark
tests stay within the supported range. The universal source laws were not
weakened to accommodate this runtime limitation.

`diff_correct` proves that eval(diff(e),x) equals the formal tangent semantics
of polynomials, defined by the sum rule and Leibniz's product rule. A separate
connection to real analysis or the limit definition of the derivative has not
been formalized in Bend. SymPy checks polynomial identities for derivatives
on 500 samples; these are independent tests, not a substitute for the general
proof.

The claim of being the "first in the world" has not been investigated and is
not asserted. Zero allocation is not claimed: differentiation creates new
trees. Rust, Verus, and Miri are not used here because the core is written in
the explicitly requested Bend language. FPS is not applicable: the dashboard
is a static PNG rather than an interactive renderer.

## Contents

- `compiler.bend` — pure core with independent parallel calls.
- `LAWS.bend` — 15 arithmetic laws plus 16 compiler and helper laws.
- `PROOF.bend` — proofs using structural induction and rewriting.
- `PROOF.bendtt` — export for the independent kernel.
- `tests.bend` — computational witnesses for all simplification rules and VM execution.
- `oracle.bend` — type-checked postfix frontend and JSON driver.
- `bench.bend` — deep balanced-tree generator and timers.
- `bin/` — native Linux x86-64 binaries and generated C.
- `raw/` — all 500 formulas and their results, 45 measurements, and chart data.
- `reports/` — verification, oracle, benchmark, Nat-limit, and visual-audit
  reports, plus the consolidated numerical evidence object.
- `logs/` — installation, guide/base, builds, and initial/final checks.
- `checkpoints/` — source snapshots organized by phase.
- `negative/` — a separate, INTENTIONALLY FALSE proof of 0=1; it is not
  imported by production files and must be rejected.
- `visuals/dashboard.png` — before/after AST, f/f′, and the status of all 31 laws.
- `visuals/curves_notion_agent_chart.html` — a standalone chart for Notion.
- `visuals/chart-captures/` — light/dark captures at 320/1200px.
- `visuals/mutation-*`, `visuals/audit-*-annotated.png` — negative-control
  images and detected-defect annotations; these are test fixtures, not the
  final dashboard PNG.
- `audit_vision.py` — OpenCV/NumPy/Pillow audit and negative controls.
- `scripts/` — reproducible tests, measurements, and dashboard generation.
- `MANIFEST.sha256` — checksums of the archived files.

## Reproduction

Requirements: Linux x86-64, Bend 2.0.37, Lean 4.34.0, and Clang >=14.
`install.sh` is the saved official installer with the release version and
SHA-256 pinned. Read it first; then run `sh install.sh` if needed.
Lean can be installed through elan:
`elan toolchain install leanprover/lean4:v4.34.0`.
All three commands — `bend`, `lean`, and `clang` — must be on PATH.

```sh
python -m pip install -r requirements.txt
bend PROOF.bend
bend PROOF.bend --verdict
bend tests.bend
mkdir -p bin
bend oracle.bend -o bin/oracle
bend bench.bend -o bin/bench
python scripts/oracle.py
python scripts/benchmark.py
python scripts/runtime_limits.py
python audit_vision.py
```

Alternatively, run `./run_checks.sh`. `env.sh` provides portable defaults; configure PATH/BEND_HOME/ELAN_HOME if your tools are installed elsewhere.
Regenerating the dashboard requires Liberation Sans and `fc-match`.
`dashboard.py` uses the included, checked capture of the canonical HTML chart.
If chart data changes, regenerate that capture. HTML validation in this
session used Notion's inline-charts tooling. The exact command, authoring-card
version, and results are recorded in logs/chart-*.txt. The HTML needs Chart.js
from the CDN specified in it; the PNG does not require network access.

This release **does not support `--safe`**: the option is rejected as unknown.
The actual additional kernel check is `--verdict`, which succeeded with Lean.
`-x` denotes an erased variable, not a general requirement for unused variables.
Unused pattern fields use `_`; reusable variables use `+`.

Example input: `bin/oracle --threads 2 'xx*x2*+1+' 2`.
The postfix interface accepts x, digits 0..9, +, and * without spaces. This is
only the test driver's interface, NOT a restriction on the universal Expr
type, whose Const constructor contains Nat. The example returns value 9 and
derivative 6, including through the VM.
The VM is total: an arithmetic instruction with insufficient operands returns
Nil. The compile_sound theorem establishes that compiled expressions do not
suffer this operand shortage for any initial stack tail.

## Oracle methodology

The 500 unique ASTs contain 15–111 nodes and have degree at most 8; degree −1
denotes the zero polynomial. The generator caps the value at x=3 at 100000
to avoid conflating algebraic checks with runtime limits. For each tree:

1. SymPy checks that the returned derivative is identical to sympy.diff(f,x).
2. SymPy checks that optimize(e) is identical to e.
3. Native Bend evaluates f and f′ at one point in {0,1,2,3}; the outputs of
   both VM programs are checked separately — 2000 comparisons in total.
4. An independent interpreter evaluates the original AST over Python Fraction
   to compute a central difference with h=1e−20 and relative-error tolerance
   1e−30. This is a numerical control, not a definition of differentiation
   on discrete Nat.
5. Seven malformed inputs are rejected. A +1 mutation of the derivative
   is detected.

## Benchmark methodology

The workload is a full balanced sum tree with leaves `(x*x + 0)`.
The depth parameter 14,15,16 corresponds to actual AST depth 16,17,18,
measured in edges along the longest branch. Configurations use 1,2,4 threads,
with one warm-up and five independent measured runs each. Final measurements
were taken WITHOUT a concurrent oracle run. The preliminary concurrent series
is marked as discarded in logs and is excluded from the report.

IO.now returns integer milliseconds. The diff and optimize stages are timed
separately; tree generation and node counting are excluded from stage times.
Median pipeline time is the median of paired per-run stage sums, not the sum
of stage medians. Node count means logical tree size, not unique heap
allocations or DAG nodes.
At depth 18, the original AST has 393215 nodes, its derivative tree has 655359,
and the optimized derivative has 262143. Current median pipeline times for 1/2/4 threads are generated in RESULTS.md. This is a short synthetic workload with timer quantization
and container resource limits, not evidence of a general twofold speedup.

## Visual-audit scope

The original clean PNG had 56 authored layout text elements, minimum contrast
6.03:1, and eight known AST edges with 100% sampled coverage. No overlaps
between those text elements or canvas overflow were found. Histogram, Canny,
and unexpected black-component checks were also run. The English edition
re-runs these checks after translating and re-rendering; its current metrics
are in `reports/vision.json`.
Chart readability and layout were checked separately using the canonical
browser verifier in four configurations. Manual image-preview review was
unavailable for this English edition; see reports/manual-review.json.
A static PNG has no interactive zones.

Three independent pixel mutations — a black square, a broken edge, and an
erased optimize_sound label — are all detected. In addition, the formal
checker rejects the false proof of 0=1. The CV report is not a universal
guarantee against every possible visual anomaly. Finite PNG pixel values do
not prove that no NaN/Inf occurred before rendering; the demo chart data is
checked separately. 3D highlights, Z-buffer faults, and T-junctions do not
apply to this artifact.

## GitHub handoff

All authored project text is in English. This edition is rechecked locally;
current commands, timestamps, results, and known limits are in RESULTS.md and
reports/readiness.json. The 31 laws are unchanged. Fresh verification,
native rebuilds, 500 oracle formulas, boundary tests, benchmark measurements,
and visual mutation controls are run by `./run_checks.sh`.

The repository includes a GitHub Actions workflow, a pinned lean-toolchain,
a portable env.sh, .gitignore, contributor instructions, and explicit MIT/upstream license notices. No remote repository is created or published by
these scripts. Remote CI has not yet run on GitHub. Original project materials are licensed under MIT. Bend runtime portions retain Apache-2.0; see LICENSE-NOTICE.md and THIRD_PARTY_NOTICES.md.

The archive includes generated binaries and host-specific logs for evidence;
.gitignore excludes these from a default `git add .`. Selected proof and
acceptance outputs are retained in evidence/acceptance/ for version control.
The prebuilt chart HTML and its browser captures are included. The portable
acceptance suite re-renders the dashboard and audits it without depending
on Notion's private chart-builder path.

## License

Original project code and documentation: **MIT** (LICENSE).
Upstream Bend runtime portions: **Apache-2.0** (LICENSES/Apache-2.0-Bend.txt).
Third-party attribution and scope: THIRD_PARTY_NOTICES.md.

## Uploading to GitHub

1. Extract this archive and open the BEND-AUTODIFF-COMPILER-GITHUB directory.
2. Inspect LICENSE, THIRD_PARTY_NOTICES.md, RESULTS.md, and reports/readiness.json.
3. Create an empty repository on GitHub, then run:

```sh
git init -b main
git add .
git commit -m "Initial verified compiler prototype"
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

Replace YOUR_REPOSITORY_URL with your own repository URL. The archive contains
no Git history or preconfigured remote. .gitignore excludes generated native
binaries and host-specific logs from the default commit; selected acceptance
evidence is versioned under evidence/acceptance/. GitHub Actions will start
automatically on the first push. Its actions are pinned to exact commit IDs.
Local acceptance and a clean-checkout simulation are included; a green
GitHub-hosted run can only be confirmed after the first actual push.
