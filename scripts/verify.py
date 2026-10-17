#!/usr/bin/env python3
import subprocess,json,hashlib,re,datetime
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    checks=[]
    cmds=[(['bend','PROOF.bend'],0,'final-proof'),(['bend','PROOF.bend','--verdict'],0,'final-verdict'),(['bend','tests.bend'],0,'final-tests'),(['bend','negative/PROOF.bend','--verdict'],1,'final-negative-proof')]
    for cmd,want,name in cmds:
        p=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,timeout=240)
        (ROOT/f'logs/{name}.txt').write_text(p.stdout+p.stderr)
        assert p.returncode==want,(cmd,p.returncode,p.stdout,p.stderr)
        if want==0:assert 'ALL PROOFS CHECK' in p.stdout
        checks.append({'command':cmd,'exit_code':p.returncode,'expected_exit':want,'pass':True})
    text=(ROOT/'PROOF.bend').read_text();laws=re.findall(r'^law (\w+):',(ROOT/'LAWS.bend').read_text(),re.M)
    assert len(laws)==31 and all(re.search(r'^def L\.'+n+r'\(',text,re.M) for n in laws)
    assert not any(t in text for t in ['?TODO','@unsafe','?admit'])
    versions={}
    for cmd in [['bend','version'],['lean','--version'],['clang','--version']]:
        p=subprocess.run(cmd,capture_output=True,text=True,timeout=240);versions[cmd[0]]=(p.stdout+p.stderr).strip();assert p.returncode==0
    assert versions['bend']=='bend 2.0.37', versions['bend']
    assert 'version 4.34.0' in versions['lean'], versions['lean']
    sources={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'LAWS.bend',ROOT/'PROOF.bend',ROOT/'compiler.bend',ROOT/'PROOF.bendtt',ROOT/'oracle.bend',ROOT/'bench.bend',ROOT/'tests.bend']}
    report={'timestamp_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'laws':len(laws),'checks':checks,'versions':versions,'sha256':sources,'all_laws_implemented':True,'placeholders_or_unsafe':False,'scope':'Source-level Nat polynomial evaluator, differentiator vs formal tangent interpretation, simplifier, compiler and total VM; no claim that Bend C backend/Clang are formally verified.'}
    (ROOT/'reports/verification.json').write_text(json.dumps(report,indent=2));print(json.dumps({'laws':len(laws),'checks':checks,'versions':versions},indent=2))
if __name__=='__main__':main()
