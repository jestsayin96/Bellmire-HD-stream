# S7 pass 2 MEASUREMENT. The team lead's row says widen the chest plate band out to the body's
# half-width plus clearance. Before I widen anything I must know, per z band:
#   - the TORSO's own half-width (the thing the plate has to cover - not the arms, which the
#     plate is not meant to cover and which would inflate the target)
#   - the SHELL CORE's own reach (|x| <= core, i.e. the plate, not the horns)
# so the widen factor is derived per band and not guessed, and so I can see where the plate
# band ENDS and the skirt/belt begin.
# RED ON EMPTY: a band with no torso verts or no shell verts reports null and is counted.
import bpy, sys, os, json, math, mathutils
import numpy as np
A=sys.argv[sys.argv.index("--")+1:]
OUT=A[0]
W5=r"C:\hd adventure\bellmire-art"
PK=r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO=os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb")
BODY={"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
LEGS={"Knight_LegLeft","Knight_LegRight"}
NAMES=["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]
NECK_Z=1.235; CORE=0.45; STEP=0.04

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
    bpy.context.view_layer.update()
    return sc

def band_reach(points, z0, z1, limit=None):
    b=[p for p in points if z0<=p[2]<z1 and (limit is None or abs(p[0])<=limit)]
    if not b: return None,0
    return max(abs(p[0]) for p in b), len(b)

rep={"step":STEP,"core":CORE,"shells":{},"errors":[]}
sc=build_hero()
torso=[o for o in sc.objects if o.name=="Knight_Body"]
tp=pts(torso)
lp=pts([o for o in sc.objects if o.name in LEGS])
LEGS_TOP=max(p[2] for p in lp)
rep["legs_top_z"]=round(LEGS_TOP,4)
rep["torso_z"]=[round(min(p[2] for p in tp),4),round(max(p[2] for p in tp),4)]

zs=[round(z,3) for z in np.arange(0.48,1.30,STEP)]
torso_hw={}
for z in zs:
    r,n=band_reach(tp,z,z+STEP)
    torso_hw[z]=(None if r is None else round(r,4), n)
rep["torso_hw"]={str(k):v for k,v in torso_hw.items()}

for name in NAMES:
    sc=build_hero()
    before={o.name for o in sc.objects if o.type=='MESH'}
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    shell=[o for o in sc.objects if o.type=='MESH' and o.name not in before]
    if not shell:
        rep["errors"].append("%s: RED no mesh imported"%name); continue
    for o in shell:
        o.data.transform(o.matrix_world); o.matrix_world=mathutils.Matrix.Identity(4)
    bpy.context.view_layer.update()
    raw=pts(shell)
    cc=[p for p in raw if abs(p[0])<0.20]
    dz=NECK_Z-max(p[2] for p in cc)
    sp=[(p[0],p[1],p[2]+dz) for p in raw]
    rows={}
    for z in zs:
        core_r,core_n=band_reach(sp,z,z+STEP,CORE)
        full_r,full_n=band_reach(sp,z,z+STEP,None)
        thw=torso_hw[z][0]
        gap=None
        if core_r is not None and thw is not None:
            gap=round(thw+0.030-core_r,4)   # positive = plate is NARROWER than it must be
        rows[str(z)]={"core_reach":(None if core_r is None else round(core_r,4)),
                      "core_n":core_n,
                      "full_reach":(None if full_r is None else round(full_r,4)),
                      "full_n":full_n,
                      "torso_hw":thw,"need_widen_m":gap}
    rep["shells"][name]={"dz":round(dz,4),
                         "shell_z":[round(min(p[2] for p in sp),4),round(max(p[2] for p in sp),4)],
                         "shell_x_max":round(max(abs(p[0]) for p in sp),4),
                         "core_x_max":round(max((abs(p[0]) for p in sp if abs(p[0])<=CORE),default=0),4),
                         "verts":len(sp),"bands":rows}
    for o in shell: bpy.data.objects.remove(o,do_unlink=True)

empty=sum(1 for z in zs if torso_hw[z][0] is None)
if empty==len(zs): rep["errors"].append("RED torso_hw measured 0 bands")
open(OUT,"w").write(json.dumps(rep,indent=1))
print("MEASURE4 bands=%d empty_torso_bands=%d errors=%d"%(len(zs),empty,len(rep["errors"])))
print("DONE")
