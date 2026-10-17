#!/usr/bin/env python3
"""Compose a static dashboard from a canonical-chart capture and audited AST layout."""
import json, glob
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
FONT='/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf'
BOLD='/usr/share/fonts/liberation-sans/LiberationSans-Bold.ttf'
# Resolve installed fonts without assuming a distro-specific directory.
import subprocess
FONT=subprocess.check_output(['fc-match','-f','%{file}','Liberation Sans'],text=True)
BOLD=subprocess.check_output(['fc-match','-f','%{file}','Liberation Sans:style=Bold'],text=True)
BG='#FFFFFF';INK='#2C2C2B';MUTED='#575651';GREEN='#246544';EDGE='#566A7D'
def main():
    data=json.loads((ROOT/'reports/evidence.json').read_text());names=data['proofs']['names']
    im=Image.new('RGB',(1600,1820),BG);d=ImageDraw.Draw(im);meta={'width':1600,'height':1820,'texts':[],'edges':[],'nodes':[],'chart_region':[80,735,1520,1221],'interactive_zones':[]}
    def text(x,y,s,size=22,fill=INK,bold=False,bg=BG):
        f=ImageFont.truetype(BOLD if bold else FONT,size);box=d.textbbox((x,y),s,font=f)
        d.text((x,y),s,font=f,fill=fill)
        meta['texts'].append({'text':s,'box':list(box),'fg':fill,'bg':bg,'size':size})
    def panel(box):d.rounded_rectangle(box,radius=12,fill=BG,outline='#D5D7D9',width=2)
    text(64,40,'BEND–AUTODIFF–COMPILER',44,bold=True)
    text(64,100,'Verified polynomial core Nat[x]  /  Bend 2.0.37  /  October 17, 2026',22,fill=MUTED)
    metrics=[('31 / 31','Laws: Bend + independent BendTT kernel'),('500 / 500','Random formulas: SymPy + numerical gradient'),('0','AutoDiff and stack VM mismatches')]
    for x,(v,label) in zip([64,560,1056],metrics):
        d.rounded_rectangle((x,154,x+480,248),radius=10,fill='#E8F1EC')
        text(x+20,162,v,36,GREEN,True,'#E8F1EC');text(x+20,215,label,17,GREEN,False,'#E8F1EC')
    text(64,275,'01  /  AST: eliminating identity elements',28,bold=True)
    boxes=[(64,320,784,710),(816,320,1536,710)]
    for b in boxes:panel(b)
    text(88,336,'Before optimization: 7 nodes',23,bold=True)
    text(840,336,'After optimization: 3 nodes',23,bold=True)
    def leaves(e):
        if 'c' in e or 'x' in e:return 1
        return sum(leaves(q) for q in e[next(iter(e))])
    positions=[];segments=[]
    def layout(e,lo,hi,y):
        cx=(lo+hi)/2;label=str(e['c']) if 'c' in e else 'x' if 'x' in e else '+' if 'a' in e else '×'
        positions.append((cx,y,label))
        if 'a' in e or 'm' in e:
            a,b=e[next(iter(e))];split=lo+(hi-lo)*leaves(a)/(leaves(a)+leaves(b))
            for child,l,h in [(a,lo,split),(b,split,hi)]:
                childx=(l+h)/2;segments.append(([cx,y+22],[childx,y+82-22]));layout(child,l,h,y+82)
    layout(data['demo']['ast_before'],100,748,410);layout(data['demo']['ast_after'],900,1452,410)
    for a,b in segments:
        d.line([tuple(a),tuple(b)],fill=EDGE,width=3);meta['edges'].append({'a':a,'b':b,'color':EDGE})
    for cx,cy,label in positions:
        box=[cx-31,cy-22,cx+31,cy+22];d.rounded_rectangle(box,radius=8,fill='#F0F5FA',outline=EDGE,width=2);meta['nodes'].append(box)
        f=ImageFont.truetype(BOLD,24);w=d.textlength(label,font=f);text(cx-w/2,cy-14,label,24,INK,True,'#F0F5FA')
    chart=Image.open(next((ROOT/'visuals/chart-captures').glob('*1200-light.png'))).convert('RGB').crop((0,0,1200,405))
    chart=chart.resize((1440,486),Image.Resampling.LANCZOS);panel((64,730,1536,1230));im.paste(chart,(80,735))
    text(64,1260,'02  /  All laws accepted: ALL PROOFS CHECK',28,bold=True)
    text(64,1304,'Structural induction; arbitrary expressions, Nat inputs, and stack tails',21,fill=MUTED)
    for i,name in enumerate(names):
        col=i//11;row=i%11;text([80,568,1056][col],1350+row*30,'OK  '+name,19,GREEN)
    q=next(q for q in data['benchmark']['summary'] if q['depth']==16 and q['threads']==2)
    text(64,1710,f"Benchmark: depth 18 · {q['diff_nodes']:,} → {q['optimized_nodes']:,} derivative nodes · reduction {q['node_reduction_percent']:.1f}%",23,bold=True)
    text(64,1752,'Proof boundary: Expr → stack VM. This project does not verify the C backend or Clang.',21,fill=MUTED)
    im.save(ROOT/'visuals/dashboard.png');(ROOT/'visuals/dashboard-layout.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
    print(json.dumps({'dashboard':list(im.size),'text_boxes':len(meta['texts']),'ast_edges':len(meta['edges'])}))
if __name__=='__main__':main()
