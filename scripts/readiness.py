#!/usr/bin/env python3
"""Local release acceptance, not a claim that GitHub-hosted CI has run."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import yaml
ROOT=Path(__file__).resolve().parents[1]

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def load(name):
    return json.loads((ROOT/name).read_text())

def main():
    if not __debug__:
        raise SystemExit('Run acceptance with assertions enabled, never python -O.')
    v=load('reports/verification.json');o=load('reports/oracle.json');b=load('reports/benchmark.json');vision=load('reports/vision.json');limits=load('reports/runtime-limits.json')
    assert len(v['checks'])==4 and all(q['pass'] and q['exit_code']==q['expected_exit'] for q in v['checks'])
    assert v['laws']==31 and v['all_laws_implemented'] and not v['placeholders_or_unsafe']
    assert all(sha(ROOT/name)==digest for name,digest in v['sha256'].items())
    assert o['formulas']==o['unique_formulas']==500 and o['mismatches']==0
    assert all(q['rejected'] for q in o['invalid_inputs']) and o['derivative_mutation_detected']
    assert b['samples']==45 and len(b['summary'])==9
    raw_b=[json.loads(s) for s in (ROOT/'raw/benchmark.jsonl').read_text().splitlines()]
    assert len(raw_b)==45 and len({(q['depth'],q['threads'],q['rep']) for q in raw_b})==45
    assert all(q['ast_nodes']==6*2**q['depth']-1 and q['diff_nodes']==10*2**q['depth']-1 and q['optimized_nodes']==4*2**q['depth']-1 for q in raw_b)
    raw_o=[json.loads(s) for s in (ROOT/'raw/oracle.jsonl').read_text().splitlines()]
    assert len(raw_o)==500 and len({q['postfix'] for q in raw_o})==500
    assert all(all(q[k] for k in ['symbolic_ok','optimized_ok','exact_ok','numeric_ok']) for q in raw_o)
    assert vision['pass'] and vision['negative_controls_detected']
    assert vision['dashboard_sha256']==sha(ROOT/'visuals/dashboard.png')
    assert vision['layout_sha256']==sha(ROOT/'visuals/dashboard-layout.json')
    assert all(q['exit_code']==q['expected_exit'] for q in limits['cases']) and limits['native_nat_max']==2**48-1
    workflow=yaml.load((ROOT/'.github/workflows/verify.yml').read_text(),Loader=yaml.BaseLoader)
    assert set(workflow['on'])=={'push','pull_request','workflow_dispatch'}
    assert workflow['permissions']=={'contents':'read'}
    steps=workflow['jobs']['verify']['steps']
    assert any('./run_checks.sh' in q.get('run','') for q in steps)
    lean_step=next(q for q in steps if q.get('uses','').startswith('leanprover/lean-action@'))
    assert all(re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}',q['uses']) for q in steps if 'uses' in q)
    assert 'MIT License' in (ROOT/'LICENSE').read_text()
    assert 'Apache License' in (ROOT/'LICENSES/Apache-2.0-Bend.txt').read_text()
    assert (ROOT/'THIRD_PARTY_NOTICES.md').is_file()
    assert lean_step['with']['auto-config']=='false' and lean_step['with']['build']=='false'
    assert (ROOT/'lean-toolchain').read_text().strip()=='leanprover/lean4:v4.34.0'
    assert os.access(ROOT/'run_checks.sh',os.X_OK)
    authored=[]
    for p in ROOT.rglob('*'):
        if not p.is_file() or any(q in {'.git','.venv','__pycache__','logs','reports','raw','bin','evidence'} for q in p.relative_to(ROOT).parts):
            continue
        if p.suffix in {'.py','.bend','.md','.sh','.yml','.yaml','.txt'} or p.name in {'.gitignore','lean-toolchain'}:
            authored.append(p)
    secret_patterns=[r'gh[pousr]_[A-Za-z0-9_]{20,}',r'github_pat_[A-Za-z0-9_]{20,}',r'AKIA[A-Z0-9]{16}',r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----']
    findings=[]
    for p in authored:
        s=p.read_text()
        if re.search('[\u0400-\u04ff]',s):findings.append({'file':str(p.relative_to(ROOT)),'kind':'non-English Cyrillic text'})
        if p.suffix in {'.py','.sh','.yml','.yaml'} and re.search(r'/(?:data|skills)/',s):
            findings.append({'file':str(p.relative_to(ROOT)),'kind':'hard-coded agent path'})
        if any(re.search(pattern,s) for pattern in secret_patterns):findings.append({'file':str(p.relative_to(ROOT)),'kind':'potential credential'})
    assert not findings,findings
    if not (ROOT/'.git').exists():
        subprocess.run(['git','init','-q','--initial-branch=main'],cwd=ROOT,check=True)
    for p in ['bin/oracle','logs/recheck-suite.txt']:
        r=subprocess.run(['git','check-ignore','-q',p],cwd=ROOT)
        assert r.returncode==0,p
    evidence=ROOT/'evidence/acceptance';evidence.mkdir(parents=True,exist_ok=True)
    for name in ['final-proof','final-verdict','final-tests','final-negative-proof']:
        shutil.copy2(ROOT/f'logs/{name}.txt',evidence/f'{name}.txt')
    shutil.copy2(ROOT/'logs/replay-proof-export.txt',evidence/'proof-export.txt')
    table=[]
    for q in b['summary']:
        table.append(f"| {q['actual_ast_depth']} | {q['threads']} | {q['median_pipeline_ms']:g} | {q['min_pipeline_ms']:g}–{q['max_pipeline_ms']:g} |")
    stamp=datetime.datetime.now(datetime.timezone.utc).isoformat()
    results=f'''# Local acceptance results\n\nRechecked at {stamp}.\n\n- 31 laws accepted by Bend and independently by BendTT (`--verdict`).\n- 12 concrete proof examples accepted.\n- 500 unique SymPy formulas: zero mismatches; VM and numerical controls passed.\n- Seven malformed inputs and the deliberately false proof were rejected.\n- Four native Nat boundary tests passed.\n- 45 isolated benchmark measurements; eight AST edges and three visual mutation controls passed.\n- Text/layout checks passed. Manual image review status is recorded separately.\n\n## Benchmark: fresh measurements\n\nFive measured runs and one warm-up for each configuration. Integer millisecond timer; synthetic balanced workload.\n\n| Actual AST depth | CPU threads | Median diff + optimize, ms | Measured range, ms |\n|---|---|---|---|\n'''+ '\n'.join(table)+'''\n\nDepth-18 derivative node count: 655,359 → 262,143 (about 60% fewer nodes).\nThese measurements are not a general native speedup guarantee.\n\n## Publication boundaries\n\n- The proven pass is Expr → abstract stack VM, not Bend's native C backend or Clang.\n- Native Nat is limited to 2^48−1. Universal native execution is not proven.\n- The GitHub Actions configuration is prepared and checked locally; remote CI has not run.\n- Original project materials use MIT; upstream Bend runtime portions retain Apache-2.0. See LICENSE-NOTICE.md and THIRD_PARTY_NOTICES.md.\n'''
    (ROOT/'RESULTS.md').write_text(results)
    report={'timestamp_utc':stamp,'local_acceptance':'passed','laws':31,'formulas':500,'mismatches':0,'benchmark_samples':45,'visual_automated_checks':'passed','source_scan_findings':findings,'authored_files_scanned':len(authored),'workflow_yaml':'parsed and local checks passed','github_hosted_workflow':'not yet run','publication_performed':False,'license':'MIT for original project materials; upstream Bend runtime remains Apache-2.0','native_nat_max':2**48-1,'native_backend_verified':False,'manual_visual_review':load('reports/manual-review.json') if (ROOT/'reports/manual-review.json').exists() else {'status':'pending'},'source_hashes':v['sha256']}
    (ROOT/'reports/readiness.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({k:val for k,val in report.items() if k!='source_hashes'},indent=2))
if __name__=='__main__':
    main()
