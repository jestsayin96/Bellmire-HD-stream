"""Second, independent glb AABB reader - a CROSS-CHECK for tools/art/glb_bounds.py.

WHY TWO. glb_bounds.py was written 25 Nov with the Blender bridge down, and the
whole _fit_coverage_audit.json table rests on it. One instrument checking itself
is not a check. This file was written separately from the glTF spec - node TRS
composed recursively down the scene graph, the eight corners of each primitive's
accessor min/max pushed through the accumulated world matrix - and NOT by reading
the other file.

RESULT, 25 Nov 2026 ~20:4x CT, over all 76 assets/monsters/minibosses/*.glb:
  raw_h / size_x / size_z   76/76 agree within 0.002
  footprint_diag            76/76
  corridor 11.0 m verdict   76/76
  breach_h                  76/76 within 0.05
  register creature_h       37/37 agree (joined out of the 28 _fit_*_register.json
                            `pairs` maps; the in_register set matches body-for-body)

IT FOUND ONE FAULT, in prose not geometry: both the audit's `_breach_note` and
the doc said the highest recommended `h` in MINIBOSS_FIT.md was 3.45 m. That is
the tallyman row, the fourth of fourteen, not the column maximum, which is
bellman at 4.00 m. Margin is 1.60 m, not 2.15 m. Both files are corrected.
The room-lock verdict did not move: 5.60 m > 4.00 m.

WHAT IT CANNOT SEE. Geometry only. No render, no visibility, no facing, no
occlusion - it answers how BIG a body is and says NOTHING about whether it reads.
Agreement here is not a fit pass and must never be reported as one.

Usage:  python3 tools/art/glb_bounds_crosscheck.py <file.glb> [...]   -> one json per line
"""
import json, struct, sys, os, math
def chunks(p):
    with open(p,'rb') as f:
        magic,ver,total = struct.unpack('<III', f.read(12))
        assert magic==0x46546C67, p
        js=None
        while f.tell() < total:
            hdr=f.read(8)
            if len(hdr)<8: break
            ln,ty = struct.unpack('<II', hdr)
            data=f.read(ln)
            if ty==0x4E4F534A: js=json.loads(data.decode('utf-8'))
        return js
def mul(a,b):
    return [sum(a[i*4+k]*b[k*4+j] for k in range(4)) for i in range(4) for j in range(4)]
def trs(n):
    if 'matrix' in n:
        m=n['matrix']  # column-major
        return [m[0],m[4],m[8],m[12], m[1],m[5],m[9],m[13], m[2],m[6],m[10],m[14], m[3],m[7],m[11],m[15]]
    t=n.get('translation',[0,0,0]); r=n.get('rotation',[0,0,0,1]); s=n.get('scale',[1,1,1])
    x,y,z,w=r
    R=[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),0,
       2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),0,
       2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y),0,
       0,0,0,1]
    S=[s[0],0,0,0, 0,s[1],0,0, 0,0,s[2],0, 0,0,0,1]
    T=[1,0,0,t[0], 0,1,0,t[1], 0,0,1,t[2], 0,0,0,1]
    return mul(T, mul(R,S))
def xf(m,p):
    return [m[0]*p[0]+m[1]*p[1]+m[2]*p[2]+m[3],
            m[4]*p[0]+m[5]*p[1]+m[6]*p[2]+m[7],
            m[8]*p[0]+m[9]*p[1]+m[10]*p[2]+m[11]]
def bounds(p):
    g=chunks(p)
    if not g: return None
    lo=[math.inf]*3; hi=[-math.inf]*3
    nodes=g.get('nodes',[]); meshes=g.get('meshes',[]); acc=g.get('accessors',[])
    def walk(i,par):
        n=nodes[i]; m=mul(par,trs(n))
        if 'mesh' in n:
            for prim in meshes[n['mesh']].get('primitives',[]):
                ai=prim.get('attributes',{}).get('POSITION')
                if ai is None: continue
                a=acc[ai]
                if 'min' not in a or 'max' not in a: continue
                mn,mx=a['min'],a['max']
                for cx in (mn[0],mx[0]):
                    for cy in (mn[1],mx[1]):
                        for cz in (mn[2],mx[2]):
                            w=xf(m,[cx,cy,cz])
                            for k in range(3):
                                lo[k]=min(lo[k],w[k]); hi[k]=max(hi[k],w[k])
        for c in n.get('children',[]): walk(c,m)
    I=[1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    scs=g.get('scenes',[])
    roots = scs[g.get('scene',0)].get('nodes',[]) if scs else range(len(nodes))
    for r in roots: walk(r,I)
    if lo[0]==math.inf: return None
    return lo,hi
if __name__=='__main__':
    for p in sys.argv[1:]:
        b=bounds(p)
        name=os.path.basename(p)[:-4]
        if b is None: print(json.dumps({"body":name,"err":"no positions"})); continue
        lo,hi=b
        print(json.dumps({"body":name,"h":round(hi[1]-lo[1],4),
            "size_x":round(hi[0]-lo[0],4),"size_z":round(hi[2]-lo[2],4)}))
