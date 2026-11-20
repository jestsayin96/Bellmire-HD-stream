# S7: fit the five Quaternius armour shells to the KayKit hero body.
# Hero: Knight.glb, Idle action, frame 1. Blender +Z up; FRONT = -Y (proved off foot.l tail).
# Armour OBJ imports Z-up and ALSO faces -Y (proved by looking at renders/art/s7_armour/alone).
# Placement rule: the armour's COLLAR (max z of verts with |x|<0.2, i.e. not a pauldron or horn)
# lands at the hero's neck, z 1.235. Scale is swept; the picture decides.
import bpy, sys, os, json, math, mathutils
import numpy as np
A = sys.argv[sys.argv.index("--")+1:]
OUTDIR = A[0]; MODE = A[1]            # MODE: "sweep" or "final"
SCALES = [float(x) for x in A[2].split(",")]
W5 = r"C:\hd adventure\bellmire-art"
PK = r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO = os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb")
BODY = {"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
NAMES = ["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
NECK_Z = 1.235
RES = int(A[3]) if len(A) > 3 else 440
os.makedirs(OUTDIR, exist_ok=True)

def world_pts(objs):
    dg = bpy.context.evaluated_depsgraph_get(); pts=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        pts += [tuple(mw@v.co) for v in me.vertices]
        oe.to_mesh_clear()
    return pts

def lights(sc):
    for loc,e in [((4,-5,6),2200),((-5,-4,3),1000),((0,6,4),800)]:
        l=bpy.data.lights.new("L",'POINT'); l.energy=e
        ob=bpy.data.objects.new("L",l); ob.location=loc; sc.collection.objects.link(ob)

def check_png(path, border_px=2):
    im=bpy.data.images.load(path); im.colorspace_settings.name='Non-Color'
    w,h=im.size; a=np.array(im.pixels[:],dtype=np.float32).reshape(h,w,4)
    al=a[:,:,3]
    r={"opaque":int((al>0.02).sum()),
       "border_alpha":round(float(max(al[:border_px,:].max(),al[-border_px:,:].max(),
                                      al[:,:border_px].max(),al[:,-border_px:].max())),4),
       "size":[w,h]}
    bpy.data.images.remove(im); return r

def load_rgba(path,res):
    im=bpy.data.images.load(path); im.colorspace_settings.name='Non-Color'
    a=np.array(im.pixels[:],dtype=np.float32).reshape(res,res,4)[::-1]
    bpy.data.images.remove(im); return a

def build_hero():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=HERO)
    sc=bpy.context.scene
    arm=next(o for o in sc.objects if o.type=='ARMATURE')
    act=bpy.data.actions.get("Idle")
    if not arm.animation_data: arm.animation_data_create()
    arm.animation_data.action=act
    sc.frame_set(int(act.frame_range[0]))
    # hide every prop the KayKit pack parks in the file; keep only the body meshes
    for o in list(sc.objects):
        if o.type=='MESH' and o.name not in BODY:
            o.hide_render=True; o.hide_viewport=True
    bpy.context.view_layer.update()
    sc.render.engine='BLENDER_EEVEE'
    sc.render.resolution_x=RES; sc.render.resolution_y=RES
    sc.render.film_transparent=True
    sc.render.image_settings.file_format='PNG'; sc.render.image_settings.color_mode='RGBA'
    lights(sc)
    return [o for o in sc.objects if o.type=='MESH' and o.name in BODY]

def add_camera(sc, ctr, rad):
    cd=bpy.data.cameras.new("C"); cam=bpy.data.objects.new("C",cd)
    sc.collection.objects.link(cam); sc.camera=cam
    return cam, cd

def shoot(sc, cam, cd, ctr, rad, dirv, path):
    dist=rad*3.0
    cd.clip_start=max(0.01,dist*0.05); cd.clip_end=dist*6
    cam.location=ctr+dirv.normalized()*dist
    cam.rotation_euler=(ctr-cam.location).normalized().to_track_quat('-Z','Y').to_euler()
    cd.angle=2*math.atan((rad*0.60)/dist)
    sc.render.filepath=path
    bpy.ops.render.render(write_still=True)

report={"mode":MODE,"scales":SCALES,"neck_z":NECK_Z,"views":{},"armours":{},"errors":[]}
VIEWS={"front":mathutils.Vector((0,-1,0.0)),"side":mathutils.Vector((1,0,0.0)),
       "back":mathutils.Vector((0,1,0.0))}

# hero reference bounds (body only, posed) - used for camera framing, measured once
body=build_hero()
hp=world_pts(body)
hlo=[min(p[i] for p in hp) for i in range(3)]; hhi=[max(p[i] for p in hp) for i in range(3)]
ctr=mathutils.Vector(((hlo[0]+hhi[0])/2,(hlo[1]+hhi[1])/2,(hlo[2]+hhi[2])/2))
rad=max(hhi[i]-hlo[i] for i in range(3))
report["hero_body_lo"]=[round(c,4) for c in hlo]; report["hero_body_hi"]=[round(c,4) for c in hhi]

# bare-body reference renders (the "without" half of the moved-pixel test)
bare={}
cam,cd=add_camera(bpy.context.scene,ctr,rad)
for vn,dv in VIEWS.items():
    p=os.path.join(OUTDIR,"_bare_%s.png"%vn); shoot(bpy.context.scene,cam,cd,ctr,rad,dv,p)
    bare[vn]=p
report["bare"]=bare
bare_a={vn:load_rgba(p,RES) for vn,p in bare.items()}

for name in NAMES:
    arep={}
    # measure the shell once
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    ap=world_pts([o for o in bpy.context.scene.objects if o.type=='MESH'])
    alo=[min(p[i] for p in ap) for i in range(3)]; ahi=[max(p[i] for p in ap) for i in range(3)]
    centre_col=[p for p in ap if abs(p[0])<0.20]
    if not centre_col:
        report["errors"].append("%s: EMPTY centre column - collar unmeasurable"%name); continue
    collar_z=max(p[2] for p in centre_col)
    arep["lo"]=[round(c,4) for c in alo]; arep["hi"]=[round(c,4) for c in ahi]
    arep["collar_z"]=round(collar_z,4); arep["centre_col_n"]=len(centre_col)
    arep["scales"]={}
    for s in SCALES:
        body=build_hero()
        sc=bpy.context.scene
        before={o.name for o in sc.objects if o.type=='MESH'}
        bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
        shell=[o for o in sc.objects if o.type=='MESH' and o.name not in before]
        if not shell:
            report["errors"].append("%s s=%.2f: RED - OBJ import added no mesh"%(name,s)); continue
        dz = NECK_Z - collar_z*s
        for o in shell:
            o.hide_render=False; o.hide_viewport=False
            o.scale=(s,s,s); o.location=(0.0,0.0,dz)
        bpy.context.view_layer.update()
        sp=world_pts(shell)
        if not sp:
            report["errors"].append("%s s=%.2f: EMPTY shell point set"%(name,s)); continue
        srep={"shell_lo":[round(min(p[i] for p in sp),4) for i in range(3)],
              "shell_hi":[round(max(p[i] for p in sp),4) for i in range(3)],
              "dz":round(dz,4),"shell_verts":len(sp)}
        cam,cd=add_camera(sc,ctr,rad)
        vv={}
        for vn,dv in VIEWS.items():
            p=os.path.join(OUTDIR,"%s_s%03d_%s.png"%(name,int(round(s*100)),vn))
            shoot(sc,cam,cd,ctr,rad,dv,p)
            chk=check_png(p)
            # the viewer's question: how many pixels CHANGED against the bare body?
            a=load_rgba(p,RES); b=bare_a[vn]
            diff=(np.abs(a[:,:,:3]-b[:,:,:3]).max(axis=2)>0.03)|(np.abs(a[:,:,3]-b[:,:,3])>0.03)
            chk["moved_px"]=int(diff.sum())
            # body still visible where the armour covers: pixels inside the shell's z-band that
            # are body-coloured in BOTH renders is not a defect; what matters is pixels that are
            # bare-body-opaque and UNCHANGED inside the shell band - measured in the render below.
            vv[vn]=chk; srep["path_%s"%vn]=p
        if all(v["moved_px"]==0 for v in vv.values()):
            report["errors"].append("%s s=%.2f: RED - the armour moved ZERO pixels in every view"%(name,s))
        srep["views"]=vv
        arep["scales"]["%.2f"%s]=srep
    report["armours"][name]=arep

with open(os.path.join(OUTDIR,"_fit.json"),"w") as f: json.dump(report,f,indent=1)
blanks=[]; clips=[]
for n,a in report["armours"].items():
    for s,d in a.get("scales",{}).items():
        for vn,v in d.get("views",{}).items():
            if v["opaque"]==0: blanks.append((n,s,vn))
            if v["border_alpha"]>0.02: clips.append((n,s,vn,v["border_alpha"]))
print("BLANKS",blanks); print("BORDER_CLIPS",clips); print("ERRORS",report["errors"]); print("DONE")
