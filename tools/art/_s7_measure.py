# System 7 measurement: KayKit hero body torso slot + the five Quaternius armour bodies.
# Run: blender -b -noaudio -P _s7_measure.py -- <outjson>
import bpy, sys, json, os, mathutils

OUT = sys.argv[sys.argv.index("--")+1]
W5 = r"C:\hd adventure\bellmire-art"
PK = r"C:\hd adventure\_packs\quaternius_ultimate_rpg_items_CC0\Ultimate RPG Items Pack - Aug 2019"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures", "Characters", "gltf", "Knight.glb")

def wipe():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def world_bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    lo = [1e18]*3; hi = [-1e18]*3
    n = 0
    for o in objs:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        mw = oe.matrix_world
        for v in me.vertices:
            p = mw @ v.co
            for i in range(3):
                lo[i] = min(lo[i], p[i]); hi[i] = max(hi[i], p[i])
            n += 1
        oe.to_mesh_clear()
    return {"lo": lo, "hi": hi, "verts": n}

res = {}

# ---------- hero ----------
wipe()
bpy.ops.import_scene.gltf(filepath=HERO)
objs = list(bpy.context.scene.objects)
res["hero_objects"] = [(o.name, o.type) for o in objs]
res["hero_actions"] = [a.name for a in bpy.data.actions][:80]
arm = next((o for o in objs if o.type == 'ARMATURE'), None)
res["hero_bounds_rest"] = world_bounds(objs)
if arm:
    res["hero_bone_count"] = len(arm.data.bones)
    want = ("chest","spine","head","hand","foot","torso","body","upperarm","shoulder","neck","hips","leg")
    bl = {}
    for b in arm.data.bones:
        nm = b.name
        if any(w in nm.lower() for w in want):
            hw = arm.matrix_world @ b.head_local
            tw = arm.matrix_world @ b.tail_local
            bl[nm] = {"head": [round(c,4) for c in hw], "tail": [round(c,4) for c in tw]}
    res["hero_bones"] = bl
    res["hero_all_bones"] = [b.name for b in arm.data.bones]
# mesh-only bounds and a torso slab measurement in the rest pose
meshes = [o for o in objs if o.type == 'MESH']
res["hero_mesh_names"] = [o.name for o in meshes]

# torso slab: slice the body mesh between y 0.80 and 1.05 (Blender Z is up for gltf import ->
# gltf +Y up becomes Blender +Z). Measure the slab's X width and Y depth.
dg = bpy.context.evaluated_depsgraph_get()
slabs = {}
for lo_h, hi_h, tag in [(0.80,1.05,"chest_0.80_1.05"), (0.60,0.80,"waist_0.60_0.80"), (1.05,1.30,"head_1.05_1.30")]:
    xs=[]; ys=[]; cnt=0
    for o in meshes:
        oe = o.evaluated_get(dg); me = oe.to_mesh(); mw = oe.matrix_world
        for v in me.vertices:
            p = mw @ v.co
            if lo_h <= p.z <= hi_h:
                xs.append(p.x); ys.append(p.y); cnt+=1
        oe.to_mesh_clear()
    slabs[tag] = {"n":cnt, "x":[round(min(xs),4),round(max(xs),4)] if xs else None,
                  "y":[round(min(ys),4),round(max(ys),4)] if ys else None}
res["hero_slabs"] = slabs

# ---------- armours ----------
arms = {}
for name in ["Armor_Black","Armor_Golden","Armor_Leather","Armor_Metal","Armor_Metal2"]:
    wipe()
    p = os.path.join(PK, "OBJ", name + ".obj")
    bpy.ops.wm.obj_import(filepath=p)
    objs = list(bpy.context.scene.objects)
    b = world_bounds(objs)
    tris = 0; mats=set()
    for o in objs:
        if o.type=='MESH':
            o.data.calc_loop_triangles()
            tris += len(o.data.loop_triangles)
            for m in o.data.materials:
                if m: mats.add(m.name)
    size = [round(b["hi"][i]-b["lo"][i],4) for i in range(3)]
    arms[name] = {"objects":[o.name for o in objs], "lo":[round(c,4) for c in b["lo"]],
                  "hi":[round(c,4) for c in b["hi"]], "size":size, "tris":tris,
                  "materials":sorted(mats)}
res["armours"] = arms

with open(OUT,"w") as f:
    json.dump(res,f,indent=1)
print("WROTE", OUT)
