"""_wandbake - bake the +30.5 X node translation out of wand_crystal.glb.

Measured cause (tools/art/_wandfit.py pass 1): the shipped glb's single mesh
node carries a translation of 30.5 on X. The mesh-local origin IS at the base
of the grip, as docs/art/ASSET_SOURCES.md says - but the NODE above it sits
thirty metres out, so ANY consumer that respects the node transform (Godot's
glTF import does, and a BoneAttachment3D parents the imported scene) places
this wand thirty metres from the hand. Nothing in scripts/ references it yet,
so fixing it now costs nothing and removes a trap the game build would
otherwise walk into when it writes the gear.gd row.

Applies the object transform into the mesh and re-exports. Vertex count and
mesh-local extents are asserted unchanged; only the origin offset moves.
"""
import os, sys, json
import bpy
repo = sys.argv[sys.argv.index("--")+1]
path = os.path.join(repo, "assets", "gear", "wand_crystal.glb")
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=path)
objs = [o for o in bpy.data.objects if o.type=='MESH']
assert len(objs)==1, "expected exactly one mesh, got %d" % len(objs)
ob = objs[0]
before_v = len(ob.data.vertices)
before_mw = [list(r) for r in ob.matrix_world]
before_world = [ob.matrix_world @ v.co for v in ob.data.vertices]
bw_min = [min(p[i] for p in before_world) for i in range(3)]
bw_max = [max(p[i] for p in before_world) for i in range(3)]
# the node translation is the whole defect: zero it, keeping rotation/scale
loc = list(ob.location)
ob.location = (0.0, 0.0, 0.0)
bpy.context.view_layer.update()
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.context.view_layer.update()
after_world = [ob.matrix_world @ v.co for v in ob.data.vertices]
aw_min = [min(p[i] for p in after_world) for i in range(3)]
aw_max = [max(p[i] for p in after_world) for i in range(3)]
assert len(ob.data.vertices)==before_v, "vertex count moved"
size_b = [round(bw_max[i]-bw_min[i],6) for i in range(3)]
size_a = [round(aw_max[i]-aw_min[i],6) for i in range(3)]
assert size_b==size_a, "extents changed: %s -> %s" % (size_b, size_a)
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True)
print("WANDBAKE " + json.dumps({"node_loc_removed":[round(x,4) for x in loc],
      "verts":before_v, "size":size_a,
      "bounds_before":[[round(x,3) for x in bw_min],[round(x,3) for x in bw_max]],
      "bounds_after":[[round(x,3) for x in aw_min],[round(x,3) for x in aw_max]]}))
