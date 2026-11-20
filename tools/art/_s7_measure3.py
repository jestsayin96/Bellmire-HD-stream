# S7 fit pass, step 0: MEASURE. No renders, no fix - numbers only, so the solve that follows
# is derived from the posed body and the real shells and not from memory.
# Axes: Blender +Z up, HERO FRONT = -Y (proved in _s7_fit2.py).
import bpy, sys, os, json
A=sys.argv[sys.argv.index("--")+1:]
OUT=A[0]
W5=r"C:\hd adventure\bellmire-art"
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO=os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb")
BODY={"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
ARMS={"Knight_ArmLeft","Knight_ArmRight"}; LEGS={"Knight_LegLeft","Knight_LegRight"}
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
NECK_Z=1.235

def pts(objs):
    dg=bpy.context.evaluated_depsgraph_get(); out=[]
    for o in objs:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
        out+=[tuple(mw@v.co) for v in me.vertices]; oe.to_mesh_clear()
    return out

def ext(ps):
    if not ps: return None
    return {"n":len(ps),
            "x":[round(min(p[0] for p in ps),4),round(max(p[0] for p in ps),4)],
            "y":[round(min(p[1] for p in ps),4),round(max(p[1] for p in ps),4)],
            "z":[round(min(p[2] for p in ps),4),round(max(p[2] for p in ps),4)]}

def hero():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=HERO)
    sc=bpy.context.scene
    arm=next(o for o in sc.objects if o.type=='ARMATURE')
    act=bpy.data.actions.get("Idle")
    if not arm.animation_data: arm.animation_data_create()
    arm.animation_data.action=act; sc.frame_set(int(act.frame_range[0]))
    bpy.context.view_layer.update(); return sc

sc=hero()
R={}
body=[o for o in sc.objects if o.type=='MESH' and o.name in BODY]
torso=[o for o in sc.objects if o.name=="Knight_Body"]
arms=[o for o in sc.objects if o.name in ARMS]
legs=[o for o in sc.objects if o.name in LEGS]
bp=pts(body); tp=pts(torso); ap=pts(arms); lp=pts(legs)
R["body_all"]=ext(bp); R["torso"]=ext(tp); R["arms"]=ext(ap); R["legs"]=ext(lp)
R["legs_top_z"]=round(max(p[2] for p in lp),4)
R["arms_outer_absx"]=round(max(abs(p[0]) for p in ap),4)
R["arms_z"]=[round(min(p[2] for p in ap),4),round(max(p[2] for p in ap),4)]
# torso profile per 0.05 z band - the slot the shell must wrap
prof={}
z=0.35
while z<1.30:
    b=[p for p in tp if z<=p[2]<z+0.05]
    prof["%.2f"%z]=ext(b); z+=0.05
R["torso_profile"]=prof
# every body mesh per band, for the hem/belt question
prof2={}
z=0.35
while z<1.30:
    b=[p for p in bp if z<=p[2]<z+0.05]
    prof2["%.2f"%z]=ext(b); z+=0.05
R["body_profile"]=prof2

R["shells"]={}
for name in NAMES:
    sc=hero()
    before={o.name for o in sc.objects if o.type=='MESH'}
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    shell=[o for o in sc.objects if o.type=='MESH' and o.name not in before]
    raw=pts(shell)
    cc=[p for p in raw if abs(p[0])<0.20]
    collar=max(p[2] for p in cc)
    dz=NECK_Z-collar
    sp=[(p[0],p[1],p[2]+dz) for p in raw]
    d={"collar_z_raw":round(collar,4),"dz":round(dz,4),"bounds_placed":ext(sp),
       "tris":sum(len(o.data.polygons) for o in shell),
       "n_objs":len(shell)}
    # core plate = central column only, no pauldrons/horns
    d["core_absx_by_band"]={}
    d["band"]={}
    z=0.35
    while z<1.30:
        b=[p for p in sp if z<=p[2]<z+0.05]
        d["band"]["%.2f"%z]=ext(b)
        core=[p for p in b if abs(p[0])<0.45]
        d["core_absx_by_band"]["%.2f"%z]=round(max((abs(p[0]) for p in core),default=0.0),4)
        z+=0.05
    # how much of the shell sits BEHIND the body centre plane (y>0) - the back-coverage question
    d["y_back_max"]=round(max(p[1] for p in sp),4)
    d["y_front_min"]=round(min(p[1] for p in sp),4)
    d["n_verts_behind_centre"]=sum(1 for p in sp if p[1]>0.05)
    d["n_verts_total"]=len(sp)
    R["shells"][name]=d

os.makedirs(os.path.dirname(OUT),exist_ok=True)
with open(OUT,"w") as f: json.dump(R,f,indent=1)
print("MEASURE3 DONE")
