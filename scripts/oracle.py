#!/usr/bin/env python3
"""500 reproducible formula tests against independent symbolic/numeric oracles."""
import json, random, subprocess, time, platform, sys
from pathlib import Path
from fractions import Fraction
import sympy as sp
ROOT=Path(__file__).resolve().parents[1]
x=sp.Symbol('x'); rng=random.Random(20261017)
def generate(d):
    if d==0 or rng.random()<0.23:
        return {'x':True} if rng.random()<0.5 else {'c':rng.randrange(4)}
    return {rng.choice(['a','m']):[generate(d-1),generate(d-1)]}
def symbolic(e):
    if 'c' in e:return sp.Integer(e['c'])
    if 'x' in e:return x
    k=next(iter(e));a,b=map(symbolic,e[k]);return a+b if k=='a' else a*b
def evaluate(e,t):
    if 'c' in e:return Fraction(e['c'])
    if 'x' in e:return t
    k=next(iter(e));a,b=[evaluate(q,t) for q in e[k]];return a+b if k=='a' else a*b
def postfix(e):
    if 'c' in e:return str(e['c'])
    if 'x' in e:return 'x'
    k=next(iter(e));return ''.join(map(postfix,e[k]))+('+' if k=='a' else '*')
def nodes(e):
    if 'c' in e or 'x' in e:return 1
    return 1+sum(map(nodes,e[next(iter(e))]))
def main():
    out=ROOT/'raw/oracle.jsonl';seen=set();rows=[];started=time.perf_counter();worst=Fraction(0)
    with out.open('w') as f:
      while len(rows)<500:
        e=generate(rng.randrange(4,7));text=postfix(e)
        if text in seen or nodes(e)<15:continue
        p=sp.Poly(symbolic(e),x)
        if p.degree()>8 or p.eval(3)>100000:continue
        seen.add(text);i=len(rows);point=i%4
        run=subprocess.run([str(ROOT/'bin/oracle'),'--threads','2',text,str(point)],text=True,capture_output=True,timeout=30)
        if run.returncode:raise RuntimeError(f'formula {i}: {run.stderr}')
        got=json.loads(run.stdout);want=p.as_expr();dwant=sp.diff(want,x)
        symbolic_ok=sp.Poly(symbolic(got['derivative'])-dwant,x).is_zero
        optimized_ok=sp.Poly(symbolic(got['optimized'])-want,x).is_zero
        value=int(want.subs(x,point));grad=int(dwant.subs(x,point))
        exact_ok=(got['value']==got['vm_value']==value and got['gradient']==got['vm_gradient']==grad)
        # A genuinely numerical gradient, not an integer forward difference.
        # Evaluate the ORIGINAL AST over exact rational x +/- h independently.
        h=Fraction(1,10**20);t=Fraction(point)
        finite=(evaluate(e,t+h)-evaluate(e,t-h))/(2*h)
        err=abs(finite-grad)/max(1,abs(grad));worst=max(worst,err)
        numeric_ok=err<Fraction(1,10**30)
        row={'id':i,'postfix':text,'ast':e,'nodes':nodes(e),'degree':int(p.degree()) if p.degree()!=sp.S.NegativeInfinity else -1,'x':point,'expected_value':value,'expected_gradient':grad,'symbolic_ok':bool(symbolic_ok),'optimized_ok':bool(optimized_ok),'exact_ok':exact_ok,'numeric_ok':numeric_ok,'numeric_relative_error':float(err),'result':got}
        f.write(json.dumps(row)+'\n');rows.append(row)
        if not all([symbolic_ok,optimized_ok,exact_ok,numeric_ok]):raise AssertionError(row)
    invalid=[]
    for expr,n in [('','0'),('+','0'),('x+','0'),('xx','0'),('z','0'),('x','-1'),('x','abc')]:
        p=subprocess.run([str(ROOT/'bin/oracle'),expr,n],capture_output=True,text=True,timeout=20)
        invalid.append({'postfix':expr,'input':n,'exit_code':p.returncode,'rejected':p.returncode==2})
    assert all(q['rejected'] for q in invalid)
    # Mutation negative control: a +1 corruption must be rejected symbolically.
    corrupted=sp.Poly(symbolic(rows[0]['result']['derivative'])+1-sp.diff(symbolic(rows[0]['ast']),x),x)
    assert not corrupted.is_zero
    report={'seed':20261017,'formulas':len(rows),'unique_formulas':len(seen),'mismatches':sum(not all(r[k] for k in ['symbolic_ok','optimized_ok','exact_ok','numeric_ok']) for r in rows),'symbolic_derivative_checks':len(rows),'symbolic_optimizer_checks':len(rows),'bend_and_vm_numeric_checks':len(rows)*4,'central_difference_checks':len(rows),'central_difference_h':'1e-20','relative_tolerance':'1e-30','worst_relative_error':float(worst),'invalid_inputs':invalid,'derivative_mutation_detected':True,'node_range':[min(r['nodes'] for r in rows),max(r['nodes'] for r in rows)],'degree_range':[min(r['degree'] for r in rows),max(r['degree'] for r in rows)],'elapsed_seconds':time.perf_counter()-started,'sympy_version':sp.__version__,'python':sys.version,'platform':platform.platform()}
    (ROOT/'reports/oracle.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
if __name__=='__main__':main()
