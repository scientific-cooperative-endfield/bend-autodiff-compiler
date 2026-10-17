#!/usr/bin/env python3
import json, subprocess, statistics, time, resource, os, platform
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def run(depth,threads,rep):
    before=resource.getrusage(resource.RUSAGE_CHILDREN);start=time.perf_counter()
    p=subprocess.run([str(ROOT/'bin/bench'),'--threads',str(threads),str(depth)],capture_output=True,text=True,timeout=120,check=True)
    wall=time.perf_counter()-start;after=resource.getrusage(resource.RUSAGE_CHILDREN)
    r=json.loads(p.stdout);assert r['threads']==threads
    leaves=2**depth
    assert r['ast_nodes']==6*leaves-1 and r['diff_nodes']==10*leaves-1 and r['optimized_nodes']==4*leaves-1
    r.update(rep=rep,actual_ast_depth=depth+2,wall_seconds=wall,cpu_seconds=after.ru_utime+after.ru_stime-before.ru_utime-before.ru_stime)
    return r
def main():
    rows=[]
    with (ROOT/'raw/benchmark.jsonl').open('w') as f:
      for depth in [14,15,16]:
       for threads in [1,2,4]:
        run(depth,threads,-1)
        for rep in range(5):
          r=run(depth,threads,rep);rows.append(r);f.write(json.dumps(r)+'\n');f.flush()
    summary=[]
    for d in [14,15,16]:
     baseline=statistics.median(q['diff_ms']+q['optimize_ms'] for q in rows if q['depth']==d and q['threads']==1)
     for t in [1,2,4]:
      rr=[q for q in rows if q['depth']==d and q['threads']==t]
      med=statistics.median(q['diff_ms']+q['optimize_ms'] for q in rr)
      q=rr[0];summary.append({'depth':d,'actual_ast_depth':d+2,'threads':t,'repetitions':5,'ast_nodes':q['ast_nodes'],'diff_nodes':q['diff_nodes'],'optimized_nodes':q['optimized_nodes'],'compression_ratio':q['diff_nodes']/q['optimized_nodes'],'node_reduction_percent':100*(1-q['optimized_nodes']/q['diff_nodes']),'median_diff_ms':statistics.median(q['diff_ms'] for q in rr),'median_optimize_ms':statistics.median(q['optimize_ms'] for q in rr),'median_pipeline_ms':med,'min_pipeline_ms':min(q['diff_ms']+q['optimize_ms'] for q in rr),'max_pipeline_ms':max(q['diff_ms']+q['optimize_ms'] for q in rr),'speedup_vs_1_thread':baseline/med if med else None,'median_cpu_over_wall':statistics.median(q['cpu_seconds']/q['wall_seconds'] for q in rr)})
    quota=Path('/sys/fs/cgroup/cpu.max');quota=quota.read_text().strip() if quota.exists() else None
    report={'workload':'balanced sum of leaves (x*x + 0), constructed independently in each branch','timer_unit':'integer milliseconds, IO.now; tree generation and counting excluded from stage timings','repetitions':5,'warmups_per_configuration':1,'samples':len(rows),'logical_cpus':os.cpu_count(),'affinity_cpus':len(os.sched_getaffinity(0)),'cgroup_cpu_max':quota,'platform':platform.platform(),'summary':summary,'limitations':['Synthetic balanced workload only; not a general performance claim.','CPU/wall includes whole process and is not a scheduler trace.','Source-to-VM theorem does not verify Bend native code generation or Clang.','No zero-allocation claim: symbolic differentiation constructs new trees.']}
    (ROOT/'reports/benchmark.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
if __name__=='__main__':main()
