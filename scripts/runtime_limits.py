#!/usr/bin/env python3
import json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    cases=[('largest_input','x','281474976710655',0),('multiplication_below_limit','xx*','16777215',0),('multiplication_above_limit','xx*','16777216',1),('input_above_limit','x','281474976710656',2)]
    rows=[]
    for label,expr,x,want in cases:
        p=subprocess.run([str(ROOT/'bin/oracle'),expr,x],capture_output=True,text=True,timeout=15)
        assert p.returncode==want,(label,p.returncode,p.stdout,p.stderr)
        rows.append({'label':label,'postfix':expr,'x':x,'expected_exit':want,'exit_code':p.returncode,'stdout':p.stdout.strip(),'stderr':p.stderr.strip()})
    out={'native_nat_max':2**48-1,'source':'bin/oracle.c: NAT_IMM, nat_chk, nat_mul','universal_native_preservation_proven':False,'source_theorems_unchanged':True,'cases':rows}
    (ROOT/'reports/runtime-limits.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
if __name__=='__main__':main()
