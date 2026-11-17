
import sys,json,math
sys.path.append(r"C:\hd adventure\bellmire-art\tools\art")
import minibossgen as MG
objs,info = MG.build_miniboss("sluicekeeper_chibi")
glow=[o for o in objs if o.name.endswith("_glow")][0]
gz=[glow.matrix_world @ v.co for v in glow.data.vertices]
gz=[p for p in gz if p.z>0.2]
cx=sum(p.x for p in gz)/len(gz); cy=sum(p.y for p in gz)/len(gz)
ang=[(math.atan2(p.y-cy,p.x-cx), math.hypot(p.x-cx,p.y-cy)) for p in gz]
def rr_at(a):
    best=9.9; rr=0.0
    for aa,r in ang:
        d=abs((aa-a+math.pi)-math.floor((aa-a+math.pi)/(2*math.pi))*2*math.pi-math.pi)
        if d<best: best=d; rr=r
    return rr
out={}
for o in objs:
    if not o.name.endswith("_dark"): continue
    bad=[]
    for v in o.data.vertices:
        p=o.matrix_world @ v.co
        if p.z<0.30:
            a=math.atan2(p.y-cy,p.x-cx); r=math.hypot(p.x-cx,p.y-cy)
            if r>rr_at(a): bad.append([round(p.x,2),round(p.y,2),round(p.z,2),round(r,2),round(rr_at(a),2)])
    out["n_outside"]=len(bad); out["sample"]=bad[:12]
print("PROBE "+json.dumps(out))
