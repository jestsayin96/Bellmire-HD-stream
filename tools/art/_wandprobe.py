
import os, sys, json
import bpy
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF
import weaponfit as WF
repo = sys.argv[sys.argv.index("--")+1]
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
roots, body, hinfo = MF.import_hero(repo)
rig = next(o for o in roots if o.type=='ARMATURE')
bpy.context.view_layer.update()
pb = rig.pose.bones["handslot.r"]
base = rig.matrix_world @ pb.matrix
slot = base @ Vector((0,0,0))
path = os.path.join(repo, "assets", "gear", "wand_crystal.glb")
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=path)
new = [o for o in bpy.data.objects if o not in before]
mesh = [o for o in new if o.type=='MESH']
bpy.context.view_layer.update()
def bnds(objs):
    v = WF.world_verts(objs)
    return [[round(min(p[i] for p in v),3) for i in range(3)],
            [round(max(p[i] for p in v),3) for i in range(3)]]
out = {"slot":[round(x,3) for x in slot],
       "new_objs":[(o.name,o.type,o.parent.name if o.parent else None) for o in new],
       "raw_bounds": bnds(mesh)}
M,_ = WF.slot_matrix("staff")
root = [o for o in new if o.parent is None]
out["roots"] = [o.name for o in root]
out["root_mw_before"] = [[round(x,3) for x in r] for r in root[0].matrix_world]
for o in root: o.matrix_world = base @ M @ o.matrix_world
bpy.context.view_layer.update()
out["bounds_after_mul"] = bnds(mesh)
# ALTERNATIVE: SET the matrix rather than compose onto the glTF conversion
for o in root: o.matrix_world = base @ M
bpy.context.view_layer.update()
out["bounds_after_set"] = bnds(mesh)
print("PROBE " + json.dumps(out))
