# S7 FIT PASS. Four faults, four stages, each measured SEPARATELY on its own instrument so the
# gain is attributable - even though they share one render pass.
#
# Axes: Blender +Z up, HERO FRONT = -Y (proved in _s7_fit2.py and unchanged).
#
# STAGE A  as shipped at 01:5x - uniform 1.0, dz to put the collar at the neck, plus the
#          chest-band depth "correction" (y_scale 1.1431, y_offset -0.0465).
# STAGE B  + HEM: scale z about the collar so the shell's bottom lands on the TOP OF THE LEGS
#          (measured, 0.5237) instead of hanging in mid-thigh air.
# STAGE C  + DEPTH, done over the WHOLE torso overlap instead of the chest band. The chest band
#          is unrepresentative and fitting on it is what pushed the shell 0.1 FORWARD and opened
#          the back - stage A's own y_offset is the back-gap fault.
# STAGE D  + OVERHANG TAPER: the pauldrons and horns reach |x|=0.77 at shoulder height where the
#          body is only +-0.43 wide. Remap only the part of x BEYOND the core plate so the
#          outermost shell point at each z lands on the body's own half-width there. The plate
#          itself is never touched.
# STAGE E  + BACK CLOSURE: mirror the clearly-front faces about the body's depth centre to give
#          the open wraps a back. The leather vest has no back panel at all.
#
# EVERY instrument goes RED ON EMPTY. A metric computed over zero rows/verts/pixels is not a pass.
import bpy, sys, os, json, math, mathutils, bmesh
import numpy as np
from mathutils.bvhtree import BVHTree
A=sys.argv[sys.argv.index("--")+1:]
OUTDIR=A[0]; RES=int(A[1]); STAGES=A[2].split(",")
W5=r"C:\hd adventure\bellmire-art"
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO=os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb")
BODY={"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
LEGS={"Knight_LegLeft","Knight_LegRight"}
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
NECK_Z=1.235; CHEST=(0.85,1.12); CLEAR=0.025; HALF=0.88
FLOAT_D=0.12          # a shell vertex further than this from any body surface is hanging in air
os.makedirs(OUTDIR,exist_ok=True)

def pts(objs):
    dg=bpy.context.evaluated_depsgraph_get(); out=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        out+=[tuple(mw@v.co) for v in me.vertices]; oe.to_mesh_clear()
    return out

def tri_soup(objs):
    dg=bpy.context.evaluated_depsgraph_get(); V=[]; F=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        base=len(V); V+= [mw@v.co for v in me.vertices]
        me.calc_loop_triangles()
        F+= [tuple(base+i for i in t.vertices) for t in me.loop_triangles]
        oe.to_mesh_clear()
    return V,F

def build_hero():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=HERO)
    sc=bpy.context.scene
    arm=next(o for o in sc.objects if o.type=='ARMATURE')
    act=bpy.data.actions.get("Idle")
    if not arm.animation_data: arm.animation_data_create()
    arm.animation_data.action=act; sc.frame_set(int(act.frame_range[0]))
    for o in list(sc.objects):
        if o.type=='MESH' and o.name not in BODY:
            o.hide_render=True; o.hide_viewport=True
    bpy.context.view_layer.update()
    sc.render.engine='BLENDER_EEVEE'
    sc.render.resolution_x=RES; sc.render.resolution_y=RES
    sc.render.film_transparent=True
    sc.render.image_settings.file_format='PNG'; sc.render.image_settings.color_mode='RGBA'
    for loc,e in [((4,-5,6),2200),((-5,-4,3),1000),((0,6,4),800)]:
        l=bpy.data.lights.new("L",'POINT'); l.energy=e
        ob=bpy.data.objects.new("L",l); ob.location=loc; sc.collection.objects.link(ob)
    return sc

ctr=mathutils.Vector((0.0,0.0,1.15)); rad=1.5
VIEWS={"front":mathutils.Vector((0,-1,0)),"side":mathutils.Vector((1,0,0)),
       "back":mathutils.Vector((0,1,0))}

def cam_shoot(sc,dirv,path):
    cd=bpy.data.cameras.new("C"); cam=bpy.data.objects.new("C",cd)
    sc.collection.objects.link(cam); sc.camera=cam
    dist=rad*3.0; cd.clip_start=dist*0.05; cd.clip_end=dist*6
    cam.location=ctr+dirv.normalized()*dist
    cam.rotation_euler=(ctr-cam.location).normalized().to_track_quat('-Z','Y').to_euler()
    cd.angle=2*math.atan((rad*HALF)/dist)
    sc.render.filepath=path; bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)

def load(p):
    im=bpy.data.images.load(p); im.colorspace_settings.name='Non-Color'
    a=np.array(im.pixels[:],dtype=np.float32).reshape(RES,RES,4)[::-1]
    bpy.data.images.remove(im); return a

def check(a,b=2):
    al=a[:,:,3]
    return {"opaque":int((al>0.02).sum()),
            "border_alpha":round(float(max(al[:b,:].max(),al[-b:,:].max(),al[:,:b].max(),al[:,-b:].max())),4)}

def z_to_row(z):
    half=rad*HALF; f=(z-ctr.z)/half
    return int(round((1.0-f)*0.5*(RES-1)))

def skin_rows(with_a, bare_a, rows, errs, tag):
    """THE VIEWER'S QUESTION, one camera, with and without. For each image row across the band,
    is the NEAREST-TO-CAMERA opaque pixel still exactly the bare body's? If yes the body stands
    in front of the armour in that row - armour that is not covering. Works from any view; from
    the BACK camera it is the back-gap test. Screen column 0 is nearest-to-camera-left; we scan
    from the side the camera's own basis puts the subject's near surface on, which for both
    front(-Y) and back(+Y) cameras is handled by scanning BOTH ends and taking the body-ness of
    whichever end is opaque in the bare render."""
    body_first=0; armour_first=0; empty=0
    for r in rows:
        w=with_a[r]; bb=bare_a[r]
        idx=np.nonzero(bb[:,3]>0.5)[0]
        if idx.size==0: empty+=1; continue
        hit=False
        for c in (idx[0],idx[-1]):
            if w[c,3]<=0.5: continue
            same=(np.abs(w[c,:3]-bb[c,:3]).max()<=0.03)
            hit=True
            if same: body_first+=1
            else: armour_first+=1
            break
        if not hit: empty+=1
    ok=(body_first+armour_first)>0
    if not ok: errs.append("%s: RED skin_rows tested 0 rows"%tag)
    return {"rows":len(rows),"body_first":body_first,"armour_first":armour_first,
            "empty":empty,"ok":ok}


def bare_area(with_a, bare_a, rows, errs, tag):
    """THE OPEN-BACK QUESTION, asked as an AREA and not as an outline. Inside the bare body's
    own silhouette, across the torso rows, how many pixels still show the BODY'S OWN surface
    unchanged? From the back camera that is exactly 'how much bare back is still on show'.
    It never reaches zero - the arms and the neck are body and are meant to be seen - so it is
    read as a DELTA between stages, which is what it is for.
    WHY IT EXISTS: the skin_rows instrument above samples only the leftmost/rightmost opaque
    column of each row, i.e. the SILHOUETTE EDGE, which is the arm and the head outline and is
    body in every stage by construction. It cannot see armour that covers area inside the
    outline, so it reported every fix as a regression. That is the same family of blindness as
    the head_glow_px fault: it answered a question nobody asked. RED ON EMPTY kept."""
    r0,r1=min(rows),max(rows)+1
    w=with_a[r0:r1]; b=bare_a[r0:r1]
    bm=b[:,:,3]>0.5
    tot=int(bm.sum())
    if tot==0:
        errs.append("%s: RED bare_area tested 0 pixels"%tag)
        return {"band_px":0,"bare_px":0,"bare_pct":None,"ok":False}
    same=(np.abs(w[:,:,:3]-b[:,:,:3]).max(axis=2)<=0.03)&(w[:,:,3]>0.5)&bm
    n=int(same.sum())
    return {"band_px":tot,"bare_px":n,"bare_pct":round(100.0*n/tot,1),"ok":True}

def float_verts(shell_pts, bvh, errs, tag):
    """How much of the shell hangs in air? Distance from every shell vertex to the nearest body
    surface. RED ON EMPTY: zero vertices tested is not a pass."""
    if not shell_pts:
        errs.append("%s: RED float_verts tested 0 verts"%tag)
        return {"n":0,"floating":0,"max_d":None,"ok":False}
    worst=0.0; fl=0
    for p in shell_pts:
        loc,nor,idx,d=bvh.find_nearest(mathutils.Vector(p))
        if d is None: continue
        if d>worst: worst=d
        if d>FLOAT_D: fl+=1
    return {"n":len(shell_pts),"floating":fl,"floating_pct":round(100.0*fl/len(shell_pts),1),
            "max_d":round(worst,4),"ok":True}

# ---------- hero measurements, taken once ----------
sc=build_hero()
body=[o for o in sc.objects if o.type=='MESH' and o.name in BODY]
torso=[o for o in sc.objects if o.name=="Knight_Body"]
legsL=[o for o in sc.objects if o.name in LEGS]
tp=pts(torso); lp=pts(legsL)
LEGS_TOP=max(p[2] for p in lp)
T_Y0=min(p[1] for p in tp); T_Y1=max(p[1] for p in tp)
T_CTR=(T_Y0+T_Y1)/2.0; T_DEPTH=T_Y1-T_Y0
BV,BF=tri_soup(body)
BVH=BVHTree.FromPolygons(BV,BF)
# body half-width per 0.05 z band, for the overhang taper
HW={}
bp=pts(body)
z=0.30
while z<1.35:
    b=[p for p in bp if z<=p[2]<z+0.05]
    HW[round(z,2)]=max((abs(p[0]) for p in b),default=None); z+=0.05
def body_hw(zv):
    k=round(math.floor(zv/0.05)*0.05,2)
    for kk in (k,k-0.05,k+0.05,k-0.10,k+0.10):
        v=HW.get(round(kk,2))
        if v: return v
    return None

rep={"legs_top_z":round(LEGS_TOP,4),"torso_y":[round(T_Y0,4),round(T_Y1,4)],
     "torso_depth":round(T_DEPTH,4),"float_threshold_m":FLOAT_D,
     "clearance_m":CLEAR,"stages":{},"errors":[]}

bare={}
for vn,dv in VIEWS.items():
    p=os.path.join(OUTDIR,"_bare_%s.png"%vn); cam_shoot(sc,dv,p); bare[vn]=load(p)

ROWS=[r for r in [z_to_row(z) for z in np.linspace(0.62,1.18,40)] if 0<=r<RES]


def _taper(shell, edit, pts_fn):
    sp=pts_fn(shell); core=0.45
    reach={}
    for p in sp:
        k=round(math.floor(p[2]/0.05)*0.05,2)
        reach[k]=max(reach.get(k,0.0),abs(p[0]))
    def taper(v):
        ax=abs(v.x)
        if ax<=core: return v
        k=round(math.floor(v.z/0.05)*0.05,2)
        r=reach.get(k,ax); hw=body_hw(v.z)
        if hw is None or r<=core: return v
        allow=max(hw+CLEAR, core+0.01)
        if r<=allow: return v
        kf=(allow-core)/(r-core)
        return mathutils.Vector((math.copysign(core+(ax-core)*kf, v.x), v.y, v.z))
    edit(taper)

def _close_back(shell):
    added=0
    for o in list(shell):
        me=o.data; bm=bmesh.new(); bm.from_mesh(me)
        front=[f for f in bm.faces if (sum(v.co.y for v in f.verts)/len(f.verts))<(T_CTR-0.08)]
        if front:
            geom=list(front); seen=set()
            for f in front:
                for e in f.edges:
                    if e not in seen: seen.add(e); geom.append(e)
                for v in f.verts:
                    if v not in seen: seen.add(v); geom.append(v)
            ret=bmesh.ops.duplicate(bm, geom=geom)
            for v in [g for g in ret["geom"] if isinstance(g,bmesh.types.BMVert)]:
                v.co.y = 2*T_CTR - v.co.y
            nf=[g for g in ret["geom"] if isinstance(g,bmesh.types.BMFace)]
            bmesh.ops.reverse_faces(bm, faces=nf); added+=len(nf)
        bm.to_mesh(me); bm.free(); me.update()
    bpy.context.view_layer.update()
    return added

def apply_stage(shell, stage, raw):
    """Return (transform_record,). Mutates the shell objects' mesh data in world terms by
    editing vertices directly, because stages D/E are not expressible as an object matrix."""
    cc=[p for p in raw if abs(p[0])<0.20]
    collar=max(p[2] for p in cc)
    dz=NECK_Z-collar
    rec={"collar_z_raw":round(collar,4),"dz":round(dz,4)}
    def edit(fn):
        for o in shell:
            me=o.data
            for v in me.vertices:
                v.co=fn(mathutils.Vector(v.co))
            me.update()
        bpy.context.view_layer.update()
    # --- common: collar to neck
    edit(lambda v: mathutils.Vector((v.x, v.y, v.z+dz)))
    if stage=="A":
        # the shipped chest-band depth correction, reproduced exactly
        sp=pts(shell)
        cb=[p for p in sp if CHEST[0]<=p[2]<=CHEST[1]]
        hb=[p for p in tp if CHEST[0]<=p[2]<=CHEST[1]]
        s0=min(p[1] for p in cb); s1=max(p[1] for p in cb)
        h0=min(p[1] for p in hb); h1=max(p[1] for p in hb)
        want=(h1-h0)+2*CLEAR; ys=want/(s1-s0)
        yoff=((h0+h1)/2.0)-((s0+s1)/2.0)*ys
        edit(lambda v: mathutils.Vector((v.x, v.y*ys+yoff, v.z)))
        rec.update(y_scale=round(ys,4), y_offset=round(yoff,4))
        return rec
    if stage=="F":
        # depth recentre -> taper -> back closure, with the hem left where the artist put it.
        sp=pts(shell)
        s0=min(p[1] for p in sp); s1=max(p[1] for p in sp)
        ys=(T_DEPTH+2*CLEAR)/(s1-s0) if (s1-s0)>1e-6 else 1.0
        sctr=(s0+s1)/2.0
        edit(lambda v: mathutils.Vector((v.x,(v.y-sctr)*ys+T_CTR, v.z)))
        rec.update(depth_scale=round(ys,4), depth_shift_to=round(T_CTR,4))
        _taper(shell, edit, pts); rec["taper_core"]=0.45
        rec["back_faces_added"]=_close_back(shell)
        return rec
    # --- B and later: HEM to the top of the legs, scaled about the collar
    sp=pts(shell)
    lo_z=min(p[2] for p in sp)
    span=NECK_Z-lo_z
    want=NECK_Z-LEGS_TOP
    zs=want/span if span>1e-6 else 1.0
    edit(lambda v: mathutils.Vector((v.x, v.y, NECK_Z-(NECK_Z-v.z)*zs)))
    rec["z_scale"]=round(zs,4)
    if stage=="B": return rec
    # --- C and later: DEPTH over the whole torso overlap, centred on the body
    sp=pts(shell)
    s0=min(p[1] for p in sp); s1=max(p[1] for p in sp)
    want_d=T_DEPTH+2*CLEAR
    ys=want_d/(s1-s0) if (s1-s0)>1e-6 else 1.0
    sctr=(s0+s1)/2.0
    edit(lambda v: mathutils.Vector((v.x, (v.y-sctr)*ys+T_CTR, v.z)))
    rec.update(depth_scale=round(ys,4), depth_shift_to=round(T_CTR,4))
    if stage=="C": return rec
    # --- D and later: OVERHANG TAPER. Only |x| beyond the core plate is remapped.
    sp=pts(shell)
    core=0.45          # the core plate never exceeds this (measured: max core |x| 0.4495)
    # per z band, the shell's own outer reach
    reach={}
    for p in sp:
        k=round(math.floor(p[2]/0.05)*0.05,2)
        reach[k]=max(reach.get(k,0.0),abs(p[0]))
    def taper(v):
        ax=abs(v.x)
        if ax<=core: return v
        k=round(math.floor(v.z/0.05)*0.05,2)
        r=reach.get(k,ax); hw=body_hw(v.z)
        if hw is None or r<=core: return v
        allow=max(hw+CLEAR, core+0.01)
        if r<=allow: return v
        kfac=(allow-core)/(r-core)
        return mathutils.Vector((math.copysign(core+(ax-core)*kfac, v.x), v.y, v.z))
    edit(taper)
    rec["taper_core"]=core
    if stage=="D": return rec
    # --- E: BACK CLOSURE. Mirror the clearly-front faces about the body's depth centre.
    added=0
    for o in list(shell):
        me=o.data
        bm=bmesh.new(); bm.from_mesh(me)
        front=[f for f in bm.faces if (sum(v.co.y for v in f.verts)/len(f.verts))<(T_CTR-0.08)]
        if front:
            geom=list(front)
            seen=set()
            for f in front:
                for e in f.edges:
                    if e not in seen: seen.add(e); geom.append(e)
                for v in f.verts:
                    if v not in seen: seen.add(v); geom.append(v)
            ret=bmesh.ops.duplicate(bm, geom=geom)
            new=[g for g in ret["geom"] if isinstance(g,bmesh.types.BMVert)]
            for v in new: v.co.y = 2*T_CTR - v.co.y
            nf=[g for g in ret["geom"] if isinstance(g,bmesh.types.BMFace)]
            bmesh.ops.reverse_faces(bm, faces=nf)
            added+=len(nf)
        bm.to_mesh(me); bm.free(); me.update()
    bpy.context.view_layer.update()
    rec["back_faces_added"]=added
    return rec

for stage in STAGES:
    srep={}
    for name in NAMES:
        sc=build_hero()
        tp_l=pts([o for o in sc.objects if o.name=="Knight_Body"])
        before={o.name for o in sc.objects if o.type=='MESH'}
        bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
        shell=[o for o in sc.objects if o.type=='MESH' and o.name not in before]
        if not shell:
            rep["errors"].append("%s/%s: RED no mesh imported"%(stage,name)); continue
        for o in shell:
            o.data.transform(o.matrix_world)
            o.matrix_world=mathutils.Matrix.Identity(4)
        bpy.context.view_layer.update()
        raw=pts(shell)
        rec=apply_stage(shell, stage, raw)
        sp=pts(shell)
        rec["shell_lo"]=[round(min(p[i] for p in sp),4) for i in range(3)]
        rec["shell_hi"]=[round(max(p[i] for p in sp),4) for i in range(3)]
        # FAULT 1: hem. negative = hangs below the top of the legs.
        rec["hem_above_legs_m"]=round(rec["shell_lo"][2]-LEGS_TOP,4)
        # FAULT 3/4: float. every shell vertex's distance to the nearest body surface.
        rec["float"]=float_verts(sp, BVH, rep["errors"], "%s/%s"%(stage,name))
        rec["views"]={}
        for vn,dv in VIEWS.items():
            p=os.path.join(OUTDIR,"%s_%s_%s.png"%(stage,name,vn)); cam_shoot(sc,dv,p)
            im=load(p); c=check(im); b=bare[vn]
            d=(np.abs(im[:,:,:3]-b[:,:,:3]).max(axis=2)>0.03)|(np.abs(im[:,:,3]-b[:,:,3])>0.03)
            c["moved_px"]=int(d.sum())
            tag="%s/%s/%s"%(stage,name,vn)
            if c["moved_px"]==0: rep["errors"].append(tag+": RED armour moved zero pixels")
            if c["opaque"]==0: rep["errors"].append(tag+": RED blank render")
            if c["border_alpha"]>0.02: rep["errors"].append(tag+": RED frame clip a=%.3f"%c["border_alpha"])
            # FAULT 2: bare skin still frontmost, measured from this very camera
            c["skin"]=skin_rows(im,b,ROWS,rep["errors"],tag)
            c["bare"]=bare_area(im,b,ROWS,rep["errors"],tag)
            rec["views"][vn]=c
        srep[name]=rec
    rep["stages"][stage]=srep

with open(os.path.join(OUTDIR,"_fit3.json"),"w") as f: json.dump(rep,f,indent=1)
print("ERRORS",rep["errors"]); print("DONE")
