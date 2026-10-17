#!/usr/bin/env python3
"""Bounded, mutation-tested audit of this static compiler dashboard.
Not a general proof that arbitrary graphics contain no artifacts.
"""
import json, math, copy, hashlib
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parent

def rgb(s):return np.array(tuple(bytes.fromhex(s.lstrip('#'))),dtype=float)
def luminance(c):
    a=rgb(c)/255;v=np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4)
    return float(v@np.array([.2126,.7152,.0722]))
def contrast(a,b):
    x,y=sorted([luminance(a),luminance(b)]);return (y+.05)/(x+.05)
def audit(path,meta,tag):
    img=Image.open(path).convert('RGB');a=np.asarray(img);h,w=a.shape[:2]
    gray=cv2.cvtColor(a,cv2.COLOR_RGB2GRAY);canny=cv2.Canny(gray,70,140);issues=[];boxes=[];ratios=[];blank=[]
    for t in meta['texts']:
        b=list(map(int,t['box']));x0,y0,x1,y1=b
        if x0<0 or y0<0 or x1>w or y1>h:issues.append(('overflow',b))
        ratio=contrast(t['fg'],t['bg']);ratios.append(ratio)
        if ratio<4.5:issues.append(('contrast',b))
        roi=a[max(0,y0):min(h,y1),max(0,x0):min(w,x1)].astype(float)
        if roi.size and np.sum(np.max(np.abs(roi-rgb(t['fg'])),axis=2)<25)<max(2,len(t['text'])):
            blank.append(t['text']);issues.append(('missing_text',b))
        boxes.append(b)
    overlaps=[]
    for i,b in enumerate(boxes):
      for j,c in enumerate(boxes[:i]):
        if min(b[2],c[2])>max(b[0],c[0]) and min(b[3],c[3])>max(b[1],c[1]):
          overlaps.append([i,j]);issues.append(('text_overlap',b))
    broken=[];edge_coverage=[]
    for k,e in enumerate(meta['edges']):
        p=np.array(e['a']);q=np.array(e['b']);n=max(4,int(np.linalg.norm(q-p)))
        pts=np.rint(np.linspace(p,q,n)).astype(int);ok=[]
        for x,y in pts[2:-2]:
            roi=a[max(0,y-2):min(h,y+3),max(0,x-2):min(w,x+3)].astype(float)
            ok.append(bool(np.any(np.max(np.abs(roi-rgb(e['color'])),axis=2)<35)))
        coverage=sum(ok)/len(ok);edge_coverage.append(coverage)
        if coverage<.97:
            broken.append(k);issues.append(('broken_ast_edge',[*np.minimum(p,q),*np.maximum(p,q)]))
    nearblack=(np.max(a,axis=2)<8).astype(np.uint8)
    n,labels,stats,centers=cv2.connectedComponentsWithStats(nearblack,8)
    black_blobs=[]
    for x,y,bw,bh,area in stats[1:]:
        if int(area)>=256:
            box=[int(x),int(y),int(x+bw),int(y+bh)];black_blobs.append({'box':box,'area':int(area)});issues.append(('black_hole',box))
    raw=json.loads((ROOT/'raw/demo.json').read_text())
    scalar_values=[q[k] for q in raw for k in ['x','value','gradient','vm_value','vm_gradient']]
    finite=all(math.isfinite(v) for v in scalar_values);assert finite
    marked=img.copy();d=ImageDraw.Draw(marked)
    for kind,box in issues:d.rectangle(tuple(map(float,box)),outline='red',width=4)
    marked.save(ROOT/f'visuals/audit-{tag}-annotated.png')
    result={'pass':not issues,'dimensions':[w,h],'finite_demo_values':finite,'png_finite':bool(np.isfinite(a).all()),'rgb_range':[int(a.min()),int(a.max())],'luminance_percentiles':np.percentile(gray,[0,1,25,50,75,99,100]).tolist(),'canny_edge_pixels':int(np.count_nonzero(canny)),'minimum_text_contrast_ratio':min(ratios),'audited_layout_text_elements':len(ratios),'missing_text':blank,'overlapping_layout_text_pairs':overlaps,'ast_edges_checked':len(meta['edges']),'minimum_ast_edge_coverage':min(edge_coverage),'broken_ast_edges':broken,'unexpected_nearblack_components':black_blobs,'issues':[{'type':k,'box':list(map(float,b))} for k,b in issues],'interactive_zones':'not applicable: static PNG','scope':['Checks 56 authored layout text boxes; chart readability/layout separately checked by canonical browser verifier.','PNG pixel finiteness cannot establish absence of upstream NaN/Inf; scalar demo data checked separately.','Canny is descriptive; targeted continuity checks only concern the eight known AST edges.']}
    return result

def main():
    meta=json.loads((ROOT/'visuals/dashboard-layout.json').read_text());path=ROOT/'visuals/dashboard.png';clean=audit(path,meta,'clean');results={'clean':clean,'mutations':{}}
    # Each negative control modifies visible pixels, not just audit metadata.
    im=Image.open(path).convert('RGB');d=ImageDraw.Draw(im);d.rectangle((1470,650,1510,690),fill='black');p=ROOT/'visuals/mutation-black.png';im.save(p);results['mutations']['black_hole']=audit(p,meta,'mutation-black')
    im=Image.open(path).convert('RGB');d=ImageDraw.Draw(im);e=meta['edges'][0];cx=(e['a'][0]+e['b'][0])/2;cy=(e['a'][1]+e['b'][1])/2;d.rectangle((cx-13,cy-8,cx+13,cy+8),fill='white');p=ROOT/'visuals/mutation-edge.png';im.save(p);results['mutations']['edge_gap']=audit(p,meta,'mutation-edge')
    im=Image.open(path).convert('RGB');d=ImageDraw.Draw(im);t=next(t for t in meta['texts'] if t['text']=='OK  optimize_sound');d.rectangle(tuple(t['box']),fill=t['bg']);p=ROOT/'visuals/mutation-text.png';im.save(p);results['mutations']['erased_status']=audit(p,meta,'mutation-text')
    results['negative_controls_detected']=all(not q['pass'] for q in results['mutations'].values())
    results['pass']=clean['pass'] and results['negative_controls_detected']
    results['dashboard_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    results['layout_sha256']=hashlib.sha256((ROOT/'visuals/dashboard-layout.json').read_bytes()).hexdigest()
    (ROOT/'reports/vision.json').write_text(json.dumps(results,indent=2,ensure_ascii=False))
    print(json.dumps({'pass':results['pass'],'clean_pass':clean['pass'],'min_contrast':clean['minimum_text_contrast_ratio'],'min_edge_coverage':clean['minimum_ast_edge_coverage'],'clean_issues':clean['issues'],'negative_controls_detected':results['negative_controls_detected'],'mutation_issues':{k:[i['type'] for i in q['issues']] for k,q in results['mutations'].items()}},indent=2))
    if not results['pass']:raise SystemExit(1)
if __name__=='__main__':main()
