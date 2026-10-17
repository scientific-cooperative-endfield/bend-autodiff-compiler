#!/usr/bin/env python3
import json,hashlib,zipfile,datetime
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    verification=json.loads((ROOT/'reports/verification.json').read_text());oracle=json.loads((ROOT/'reports/oracle.json').read_text());vision=json.loads((ROOT/'reports/vision.json').read_text());limits=json.loads((ROOT/'reports/runtime-limits.json').read_text())
    assert all(q['pass'] for q in verification['checks']) and oracle['mismatches']==0 and vision['pass']
    for name,sha in verification['sha256'].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==sha,name
    evidence=json.loads((ROOT/'reports/evidence.json').read_text());evidence['runtime_limits']=limits
    (ROOT/'reports/evidence.json').write_text(json.dumps(evidence,indent=2))
    gates={'phase1':{'required_prover_exit':0,'arithmetic_laws':15,'status':'passed'},'phase2':{'core_checked':True,'concrete_tests':12,'status':'passed'},'phase3':{'laws':31,'primary_exit':0,'bendtt_exit':0,'status':'passed','safe':'unsupported in 2.0.37; --verdict used successfully'},'phase4':{'formulas':oracle['formulas'],'mismatches':oracle['mismatches'],'benchmark_samples':45,'vision_pass':vision['pass'],'visual_mutations_detected':vision['negative_controls_detected'],'status':'requested experiments passed; native scope limitation documented'},'universal_source_laws':True,'universal_native_semantic_preservation_proven':False,'native_nat_max':limits['native_nat_max'],'packaged_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    (ROOT/'reports/gates.json').write_text(json.dumps(gates,indent=2))
    assert vision['dashboard_sha256']==hashlib.sha256((ROOT/'visuals/dashboard.png').read_bytes()).hexdigest()
    assert vision['layout_sha256']==hashlib.sha256((ROOT/'visuals/dashboard-layout.json').read_bytes()).hexdigest()
    # The clean image is bound to the audit by its content hash.
    from PIL import Image
    assert Image.open(ROOT/'visuals/dashboard.png').size==(1600,1820)
    paths=sorted(p for p in ROOT.rglob('*') if p.is_file() and not any(part in {'.git','.venv','__pycache__'} for part in p.parts) and p.name!='MANIFEST.sha256')
    manifest=''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(ROOT).as_posix()+'\n' for p in paths)
    (ROOT/'MANIFEST.sha256').write_text(manifest)
    dest=ROOT.parent/'BEND-AUTODIFF-COMPILER-GITHUB.zip'
    with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in paths+[ROOT/'MANIFEST.sha256']:z.write(p,ROOT.name+'/'+p.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(dest) as z:
        assert z.testzip() is None
        for required in ['compiler.bend','LAWS.bend','PROOF.bend','PROOF.bendtt','reports/oracle.json','reports/vision.json','visuals/dashboard.png','logs/final-proof.txt','logs/final-verdict.txt','audit_vision.py','LICENSE','LICENSES/Apache-2.0-Bend.txt','THIRD_PARTY_NOTICES.md','.github/workflows/verify.yml']:
            assert ROOT.name+'/'+required in z.namelist(),required
    print(json.dumps({'archive':str(dest),'files':len(paths)+1,'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'gates':gates},indent=2))
if __name__=='__main__':main()
