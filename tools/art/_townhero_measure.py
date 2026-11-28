import os, sys, json
import bpy
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import lordgen as G
W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures", "Characters", "gltf", "Knight.glb")
G.purge()
bpy.ops.import_scene.gltf(filepath=HERE and HERO)
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
acts = sorted(a.name for a in bpy.data.actions)
rep = {"n_mesh": len(meshes), "actions_n": len(acts), "has_Idle": "Idle" in acts}
bpy.context.view_layer.update()
mn, mx, _ = G.world_bounds(meshes)
rep["rest_dims_m"] = [round(v, 4) for v in (mx.x-mn.x, mx.y-mn.y, mx.z-mn.z)]
rep["rest_min_z"] = round(mn.z, 4)
# pose to Idle frame 1 if present
arm = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
if arm and "Idle" in acts:
    if arm.animation_data is None: arm.animation_data_create()
    arm.animation_data.action = bpy.data.actions["Idle"]
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    mn2, mx2, _ = G.world_bounds(meshes)
    rep["idle_dims_m"] = [round(v,4) for v in (mx2.x-mn2.x, mx2.y-mn2.y, mx2.z-mn2.z)]
    rep["idle_min_z"] = round(mn2.z, 4)
    bones = {}
    for nm in ("hand.r","hand.l","foot.l","head","chest","hips","spine"):
        pb = arm.pose.bones.get(nm)
        if pb: bones[nm] = [round(v,4) for v in (arm.matrix_world @ pb.head)]
    rep["bones_world"] = bones
print("HERO " + json.dumps(rep))
