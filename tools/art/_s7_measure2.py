# S7 measure v2: hero BODY MESHES ONLY in the Idle pose, plus armour slice profiles.
# Blender axes after glTF import: +Z up, FRONT = -Y (proved: foot.l tail y=-0.096 = the toe,
# and the prompt's model axes put the toe at +Z, so model +Z == Blender -Y).
import bpy, sys, json, os
OUT = sys.argv[sys.argv.index("--")+1]
W5 = r"C:\hd adventure\bellmire-art"
PK = r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
BODY = {"Knight_Body","Knight_Head","Knight_ArmLeft","Knight_ArmRight","Knight_LegLeft","Knight_LegRight"}
res={}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(W5,"addons","kaykit_character_pack_adventures","Characters","gltf","Knight.glb"))
arm = next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
act = bpy.data.actions.get("Idle")
res["idle_found"] = act is not None
if act:
    if not arm.animation_data:
        arm.animation_data_create()
    arm.animation_data.action = act
    res["idle_frame_range"] = list(act.frame_range)
    bpy.context.scene.frame_set(int(act.frame_range[0]))
bpy.context.view_layer.update()

meshes = [o for o in bpy.context.scene.objects if o.type=='MESH' and o.name in BODY]
res["body_meshes"] = [o.name for o in meshes]
dg = bpy.context.evaluated_depsgraph_get()
pts=[]
per={}
for o in meshes:
    oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
    pl=[(mw@v.co) for v in me.vertices]
    per[o.name]={"lo":[round(min(p[i] for p in pl),4) for i in range(3)],
                 "hi":[round(max(p[i] for p in pl),4) for i in range(3)],"n":len(pl)}
    pts += [(p.x,p.y,p.z) for p in pl]
    oe.to_mesh_clear()
res["per_mesh"]=per
res["body_all"]={"lo":[round(min(p[i] for p in pts),4) for i in range(3)],
                 "hi":[round(max(p[i] for p in pts),4) for i in range(3)],"n":len(pts)}

# torso only (no arms/legs/head) in z bands, 0.05 steps
tor = [o for o in meshes if o.name=="Knight_Body"]
tp=[]
for o in tor:
    oe=o.evaluated_get(dg); me=oe.to_mesh(); mw=oe.matrix_world
    tp += [tuple(mw@v.co) for v in me.vertices]
    oe.to_mesh_clear()
bands={}
z=0.55
while z < 1.30:
    s=[p for p in tp if z<=p[2]<z+0.05]
    if s:
        bands["%.2f"%z]={"n":len(s),"x":[round(min(p[0] for p in s),4),round(max(p[0] for p in s),4)],
                         "y":[round(min(p[1] for p in s),4),round(max(p[1] for p in s),4)]}
    z+=0.05
res["torso_bands_z"]=bands
res["torso_bounds"]={"lo":[round(min(p[i] for p in tp),4) for i in range(3)],
                     "hi":[round(max(p[i] for p in tp),4) for i in range(3)],"n":len(tp)}

# armour slice profiles: for each, z-bands with x and y extents, to find its facing & neck hole
arms={}
for name in ["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(PK,"OBJ",name+".obj"))
    dg2=bpy.context.evaluated_depsgraph_get()
    ap=[]
    for o in bpy.context.scene.objects:
        if o.type!='MESH': continue
        oe=o.evaluated_get(dg2); me=oe.to_mesh(); mw=oe.matrix_world
        ap += [tuple(mw@v.co) for v in me.vertices]
        oe.to_mesh_clear()
    lo=[min(p[i] for p in ap) for i in range(3)]; hi=[max(p[i] for p in ap) for i in range(3)]
    h=hi[2]-lo[2]
    prof={}
    for f in range(10):
        z0=lo[2]+h*f/10.0; z1=lo[2]+h*(f+1)/10.0
        s=[p for p in ap if z0<=p[2]<=z1]
        if s:
            prof["%d"%f]={"n":len(s),"x":[round(min(p[0] for p in s),3),round(max(p[0] for p in s),3)],
                          "y":[round(min(p[1] for p in s),3),round(max(p[1] for p in s),3)]}
    arms[name]={"lo":[round(c,4) for c in lo],"hi":[round(c,4) for c in hi],
                "size":[round(hi[i]-lo[i],4) for i in range(3)],"profile_z":prof,"verts":len(ap)}
res["armours"]=arms
with open(OUT,"w") as f: json.dump(res,f,indent=1)
print("WROTE",OUT)
