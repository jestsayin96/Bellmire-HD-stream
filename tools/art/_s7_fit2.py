# S7 final: fit the five Quaternius armour shells to the KayKit hero body, with a MEASURED
# per-armour depth correction, and an instrument that counts body-through-plate poke.
#
# Axes: Blender +Z up. HERO FRONT = -Y (proved: foot.l tail y=-0.096 is the toe, and the model
# axes in scripts/gear.gd put the toe at +Z). The Quaternius shells also face -Y (proved by
# LOOKING at renders/art/s7_armour/alone/_sheet_alone.png: the V-notch, the fauld and the
# forward-swept horns are all on the -Y face).
#
# Transform per armour:
#   1. uniform scale s (swept; 1.00 chosen by looking at _sweep_front.png / _sweep_side.png)
#   2. dz so the shell's COLLAR (max z of verts with |x|<0.20 - not a pauldron, not a horn)
#      lands at the hero's neck z=1.235
#   3. depth: y scaled about the chest band so the shell's front plate clears the hero's chest
#      by CLEAR, and y shifted so the shell's chest centre sits on the hero's chest centre.
# The depth numbers are MEASURED off the posed body, per armour - not a constant.
import bpy, sys, os, json, math, mathutils
import numpy as np
A=sys.argv[sys.argv.index("--")+1:]
OUTDIR=A[0]; S=float(A[1]); RES=int(A[2]); DEPTH=A[3]=="1"
W5=r"C:\hd adventure\bellmire-art"
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO=os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb")
BODY={"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
TORSO="Knight_Body"
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
NECK_Z=1.235; CHEST=(0.85,1.12); CLEAR=0.025; HALF=0.88
os.makedirs(OUTDIR,exist_ok=True)

def pts(objs):
    dg=bpy.context.evaluated_depsgraph_get(); out=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        out+=[tuple(mw@v.co) for v in me.vertices]; oe.to_mesh_clear()
    return out

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

def check_png(p,b=2):
    im=bpy.data.images.load(p); im.colorspace_settings.name='Non-Color'
    w,h=im.size; a=np.array(im.pixels[:],dtype=np.float32).reshape(h,w,4); al=a[:,:,3]
    r={"opaque":int((al>0.02).sum()),
       "border_alpha":round(float(max(al[:b,:].max(),al[-b:,:].max(),al[:,:b].max(),al[:,-b:].max())),4)}
    bpy.data.images.remove(im); return r

def load(p):
    im=bpy.data.images.load(p); im.colorspace_settings.name='Non-Color'
    a=np.array(im.pixels[:],dtype=np.float32).reshape(RES,RES,4)[::-1]
    bpy.data.images.remove(im); return a

def front_first(with_a, bare_a, rows):
    """THE VIEWER'S QUESTION, measured in the SIDE view: for each image row across the chest
    band, which surface is FRONTMOST? Screen-left is the hero's front (-Y), proved by the
    camera basis (cam at +X looking -X, up +Z => screen-right = +Y = the back).
    A row whose frontmost opaque pixel is UNCHANGED from the bare render is a row where the
    body stands in front of the plate - the exact fault seen in _sweep_side.png.
    RED ON EMPTY: ok=False when no row in the band carries an opaque pixel."""
    body_first=0; plate_first=0; empty=0
    for r in rows:
        wrow=with_a[r]; brow=bare_a[r]
        idx=np.nonzero(wrow[:,3]>0.5)[0]
        if idx.size==0:
            empty+=1; continue
        c=idx[0]
        same=(np.abs(wrow[c,:3]-brow[c,:3]).max()<=0.03) and (abs(wrow[c,3]-brow[c,3])<=0.03)
        if same and brow[c,3]>0.5: body_first+=1
        else: plate_first+=1
    return {"rows":len(rows),"body_in_front":body_first,"plate_in_front":plate_first,
            "empty_rows":empty,"ok":(body_first+plate_first)>0}

def z_to_row(z, ctr, rad, res):
    """pixel row for a world z, for the orthographic-ish camera used here (dist=rad*3,
    half-height = rad*0.42 at the subject plane). Row 0 is the TOP of the loaded array."""
    half=rad*HALF
    f=(z-ctr.z)/half            # -1 .. +1, +1 = top
    return int(round((1.0-f)*0.5*(res-1)))

rep={"uniform_scale":S,"depth_correction":DEPTH,"neck_z":NECK_Z,"chest_band":CHEST,
     "clearance_m":CLEAR,"armours":{},"errors":[]}
VIEWS={"front":mathutils.Vector((0,-1,0)),"side":mathutils.Vector((1,0,0)),
       "back":mathutils.Vector((0,1,0))}

sc=build_hero()
body=[o for o in sc.objects if o.type=='MESH' and o.name in BODY]
hp=pts(body)
hlo=[min(p[i] for p in hp) for i in range(3)]; hhi=[max(p[i] for p in hp) for i in range(3)]
# frame on the TORSO + head, not the hair crest, so the piece fills the frame
tors=[o for o in sc.objects if o.name==TORSO]
tp=pts(tors)
ctr=mathutils.Vector((0.0,0.0,1.15)); rad=1.5
rep["hero_torso_lo"]=[round(min(p[i] for p in tp),4) for i in range(3)]
rep["hero_torso_hi"]=[round(max(p[i] for p in tp),4) for i in range(3)]
chest_h=[p for p in tp if CHEST[0]<=p[2]<=CHEST[1]]
if not chest_h: raise SystemExit("RED: hero chest band empty")
h_y0=min(p[1] for p in chest_h); h_y1=max(p[1] for p in chest_h)
rep["hero_chest_y"]=[round(h_y0,4),round(h_y1,4)]
rep["hero_chest_depth"]=round(h_y1-h_y0,4)

def cam_shoot(sc,dirv,path):
    cd=bpy.data.cameras.new("C"); cam=bpy.data.objects.new("C",cd)
    sc.collection.objects.link(cam); sc.camera=cam
    dist=rad*3.0; cd.clip_start=dist*0.05; cd.clip_end=dist*6
    cam.location=ctr+dirv.normalized()*dist
    cam.rotation_euler=(ctr-cam.location).normalized().to_track_quat('-Z','Y').to_euler()
    cd.angle=2*math.atan((rad*HALF)/dist)
    sc.render.filepath=path; bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)

bare={}
for vn,dv in VIEWS.items():
    p=os.path.join(OUTDIR,"_bare_%s.png"%vn); cam_shoot(sc,dv,p); bare[vn]=load(p)

for name in NAMES:
    sc=build_hero()
    tp=pts([o for o in sc.objects if o.name==TORSO])
    before={o.name for o in sc.objects if o.type=='MESH'}
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    shell=[o for o in sc.objects if o.type=='MESH' and o.name not in before]
    if not shell: rep["errors"].append("%s: RED no mesh imported"%name); continue
    raw=pts(shell)
    cc=[p for p in raw if abs(p[0])<0.20]
    if not cc: rep["errors"].append("%s: RED collar column empty"%name); continue
    collar=max(p[2] for p in cc); dz=NECK_Z-collar*S
    for o in shell: o.scale=(S,S,S); o.location=(0.0,0.0,dz)
    bpy.context.view_layer.update()
    sp=pts(shell)
    sc_chest=[p for p in sp if CHEST[0]<=p[2]<=CHEST[1]]
    if not sc_chest: rep["errors"].append("%s: RED shell chest band empty"%name); continue
    s_y0=min(p[1] for p in sc_chest); s_y1=max(p[1] for p in sc_chest)
    # UNCORRECTED side render, so the instrument has a before to move from
    p0=os.path.join(OUTDIR,"%s_side_nodepth.png"%name); cam_shoot(sc,VIEWS["side"],p0)
    rows=[z_to_row(z,ctr,rad,RES) for z in np.linspace(CHEST[0],CHEST[1],40)]
    rows=[r for r in rows if 0<=r<RES]
    before_ff=front_first(load(p0),bare["side"],rows)
    want=(h_y1-h_y0)+2*CLEAR
    ys=want/(s_y1-s_y0) if DEPTH else 1.0
    s_ctr=(s_y0+s_y1)/2.0; h_ctr=(h_y0+h_y1)/2.0
    yoff=(h_ctr-s_ctr*ys) if DEPTH else 0.0
    for o in shell: o.scale=(S,ys*S,S); o.location=(0.0,yoff,dz)
    bpy.context.view_layer.update()
    sp2=pts(shell)
    a={"collar_z":round(collar,4),"dz":round(dz,4),"y_scale":round(ys,4),"y_offset":round(yoff,4),
       "shell_chest_y_uncorrected":[round(s_y0,4),round(s_y1,4)],
       "shell_chest_y_corrected":[round(min(p[1] for p in sp2 if CHEST[0]<=p[2]<=CHEST[1]),4),
                                  round(max(p[1] for p in sp2 if CHEST[0]<=p[2]<=CHEST[1]),4)],
       "shell_lo":[round(min(p[i] for p in sp2),4) for i in range(3)],
       "shell_hi":[round(max(p[i] for p in sp2),4) for i in range(3)],
       "front_first_before":before_ff,"views":{}}
    if not before_ff["ok"]:
        rep["errors"].append("%s: RED front_first tested 0 rows (before)"%name)
    for vn,dv in VIEWS.items():
        p=os.path.join(OUTDIR,"%s_%s.png"%(name,vn)); cam_shoot(sc,dv,p)
        c=check_png(p); im=load(p); b=bare[vn]
        d=(np.abs(im[:,:,:3]-b[:,:,:3]).max(axis=2)>0.03)|(np.abs(im[:,:,3]-b[:,:,3])>0.03)
        c["moved_px"]=int(d.sum())
        if c["moved_px"]==0: rep["errors"].append("%s %s: RED armour moved zero pixels"%(name,vn))
        if c["opaque"]==0: rep["errors"].append("%s %s: RED blank render"%(name,vn))
        if c["border_alpha"]>0.02: rep["errors"].append("%s %s: RED frame clip a=%.3f"%(name,vn,c["border_alpha"]))
        a["views"][vn]=c
    aft=front_first(load(os.path.join(OUTDIR,"%s_side.png"%name)),bare["side"],rows)
    a["front_first_after"]=aft
    if not aft["ok"]: rep["errors"].append("%s: RED front_first tested 0 rows (after)"%name)
    rep["armours"][name]=a

with open(os.path.join(OUTDIR,"_fit2.json"),"w") as f: json.dump(rep,f,indent=1)
print("ERRORS",rep["errors"]); print("DONE")
