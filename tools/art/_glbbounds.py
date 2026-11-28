import json, struct, sys, os

def load_glb(path):
    with open(path,'rb') as f: data=f.read()
    magic,ver,length = struct.unpack_from('<III',data,0)
    assert magic==0x46546C67, "not glb"
    off=12; js=None; bin_=None
    while off < length:
        clen,ctype = struct.unpack_from('<II',data,off); off+=8
        chunk=data[off:off+clen]; off+=clen
        if ctype==0x4E4F534A: js=json.loads(chunk.decode('utf-8'))
        elif ctype==0x004E4942: bin_=chunk
    return js,bin_

def mat_mul(a,b):
    r=[0.0]*16
    for i in range(4):
        for j in range(4):
            r[i*4+j]=sum(a[i*4+k]*b[k*4+j] for k in range(4))
    return r
def ident(): return [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
def trs(n):
    t=n.get('translation',[0,0,0]); r=n.get('rotation',[0,0,0,1]); s=n.get('scale',[1,1,1])
    if 'matrix' in n:
        m=n['matrix']  # column-major
        return [m[0],m[4],m[8],m[12], m[1],m[5],m[9],m[13], m[2],m[6],m[10],m[14], m[3],m[7],m[11],m[15]]
    x,y,z,w=r
    R=[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w), 0,
       2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w), 0,
       2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y), 0,
       0,0,0,1]
    for i in range(3):
        for j in range(3): R[i*4+j]*=s[j]
    R[3]=t[0]; R[7]=t[1]; R[11]=t[2]
    return R
def xform(m,p):
    x,y,z=p
    return (m[0]*x+m[1]*y+m[2]*z+m[3], m[4]*x+m[5]*y+m[6]*z+m[7], m[8]*x+m[9]*y+m[10]*z+m[11])

def bounds(path):
    js,_=load_glb(path)
    lo=[1e30]*3; hi=[-1e30]*3; nmesh=0; nprim=0
    accs=js.get('accessors',[])
    def walk(ni, parent):
        nonlocal nmesh,nprim
        n=js['nodes'][ni]
        m=mat_mul(parent,trs(n))
        if 'mesh' in n:
            nmesh+=1
            for prim in js['meshes'][n['mesh']].get('primitives',[]):
                pi=prim.get('attributes',{}).get('POSITION')
                if pi is None: continue
                nprim+=1
                a=accs[pi]
                mn=a.get('min'); mx=a.get('max')
                if not mn or not mx: continue
                for cx in (mn[0],mx[0]):
                    for cy in (mn[1],mx[1]):
                        for cz in (mn[2],mx[2]):
                            w=xform(m,(cx,cy,cz))
                            for k in range(3):
                                lo[k]=min(lo[k],w[k]); hi[k]=max(hi[k],w[k])
        for c in n.get('children',[]): walk(c,m)
    scene=js.get('scene',0)
    for ni in js['scenes'][scene].get('nodes',[]): walk(ni, ident())
    return lo,hi,nmesh,nprim,len(js.get('materials',[])),len(js.get('images',[]))

def sibling_gate(root):
    """THE CHEAPEST GATE IN THE HOUSE. A committed .glb with no .glb.import
    sibling cannot load in Godot until a Godot run generates one. The prompt
    records that this has already bitten twice. RED ON EMPTY: if the walk
    finds no .glb at all, that is a RED, not a clean tree - a mistyped root
    would otherwise report 'all good'."""
    missing=[]; total=0
    for dirpath,dirnames,files in os.walk(root):
        dirnames[:]=[d for d in dirnames if d not in ('.git','_to_delete','__pycache__')]
        for f in files:
            if f.endswith('.glb'):
                total+=1
                fp=os.path.join(dirpath,f)
                if not os.path.exists(fp+'.import'):
                    missing.append(fp)
    if total==0:
        return total, None
    return total, sorted(missing)

if __name__=="__main__":
    args=[a for a in sys.argv[1:]]
    if args and args[0]=="--siblings":
        root=args[1] if len(args)>1 else "."
        total,missing=sibling_gate(root)
        if missing is None:
            print(f"SIBLING GATE: *** RED ON EMPTY *** no .glb found under {root!r}")
            sys.exit(2)
        print(f"SIBLING GATE under {root!r}: {total} .glb, {len(missing)} without a .glb.import sibling")
        for m in missing: print("   MISSING .import:", m)
        sys.exit(1 if missing else 0)

    for p in args:
        if not os.path.exists(p): print(f"MISSING {p}"); continue
        lo,hi,nm,np_,nmat,nimg=bounds(p)
        d=[hi[k]-lo[k] for k in range(3)]
        print(f"{os.path.basename(p):<22} glTF Y-UP dims(x,y,z)=({d[0]:.4f},{d[1]:.4f},{d[2]:.4f})  "
              f"HEIGHT(y)={d[1]:.4f}  ymin={lo[1]:+.4f} ymax={hi[1]:+.4f}  "
              f"meshes={nm} prims={np_} mats={nmat} imgs={nimg}")

# ---------------------------------------------------------------------------
# WHY THIS FILE EXISTS - 28 Nov 2026 08:3x-09:2x CT, written with the Blender
# bridge DOWN for an eighth consecutive run.
#
# It is a glTF/GLB reader in PURE PYTHON: no Blender, no numpy, no PIL. It
# parses the GLB container, walks the scene graph applying each node's TRS (or
# `matrix`), and transforms the eight corners of every POSITION accessor's
# declared min/max into world space. That gives the true shipped bounds of a
# mesh on a seat that cannot start Blender - which is the only reason this
# lane could measure anything at all today.
#
# IT ALSO ANSWERS THE AXIS QUESTION THAT NEARLY COST ME A FALSE REPORT.
# `renders/art/town/_report.json` records `dims` as (x, y, z) in BLENDER space,
# which is Z-UP, so `dims[2]` IS the height and `townbuildgen.py:390` reads it
# correctly. The shipped .glb is glTF, which is Y-UP, so THIS tool prints the
# height in slot [1]. Both are right. I spent a cycle believing the report was
# axis-scrambled because I compared slot [2] of one to slot [2] of the other.
# PRINT THE AXIS LABEL, ALWAYS - this tool does, the report does not, and the
# report is the one the game build lane reads.
#
# `imgs=` IS THE NUMBER THAT MATTERED. It counts glTF images, i.e. texture
# maps actually embedded in the shipped mesh. The well ladder reads imgs=0 at
# all three tiers; the hall ladder reads 3 / 6 / 7. That single column is what
# turned "the fountain looks flat to me" into a measured fault. See
# docs/art/WELL_TIER3_MATERIAL_READ.md.
#
# WHAT IT CANNOT SEE, said before the numbers:
#   - vertex colours and material base-colour factors. imgs=0 does NOT mean
#     "untextured and therefore grey" on its own; a mesh can be richly
#     coloured by material factors alone. imgs=0 is a PROMPT to go look at the
#     render, never a verdict by itself. On the well it agreed with the eye;
#     do not let it stand in for the eye next time.
#   - anything about scale relative to a body. It reports world units only.
#   - accessors with no declared min/max are SKIPPED silently by the spec's
#     allowance; such a mesh would under-report its bounds. No shipped mesh in
#     this tree hit that path today, but a future one could.
