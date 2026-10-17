# Contributing

1. Use Bend 2.0.37, Lean 4.34.0, Python 3.13, and a system Clang >=14.
2. Install the versions pinned in requirements.txt.
3. Run `./run_checks.sh`, then `python scripts/readiness.py`.
4. Keep all 31 source laws intact. Do not use unsafe definitions, proof holes,
   skipped laws, or weakened statements to obtain a passing verdict.
5. Preserve explicit scope limitations: the proven pass is Expr → abstract
   stack VM. Bend's native Nat runtime has a 2^48−1 bound.
6. Do not change benchmark claims without regenerating the measured reports.
7. Intentional failures belong in negative/ and must never be imported by
   production sources. Their expected exit status is part of acceptance.

The GitHub workflow has to pass after upload. Local success does not claim
that the remote GitHub runner has already been tested. Original project contributions use MIT; preserve upstream licenses and notices as documented in THIRD_PARTY_NOTICES.md.
