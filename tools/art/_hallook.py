
"""_hallook - LOOK AT THE HALL THAT ALREADY EXISTS, BESIDE THE MEASURED BODY.
Before authoring a tier ladder: does lm_hall.glb read as a hall, and which
tier does it read as? A number cannot answer that. This renders it.
"""
import json, os, sys
import bpy, numpy as np
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import lordgen as G, lordlib as L
W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures", "Characters", "gltf", "Knight.glb")
BODY = {"Knight_Body","Knight_Head","Knight_Helmet","Knight_ArmLeft",
        "Knight_ArmRight","Knight_LegLeft","Knight_LegRight","Knight_Cape"}

def add_hero(dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=HERO)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in new if o.type == 'ARMATURE'), None)
    if arm is not None and "Idle" in bpy.data.actions:
        if arm.animation_data is None: arm.animation_data_create()
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)
    keep = []
    for o in [o for o in new if o.type == 'MESH']:
        if o.name.split(".")[0] in BODY: keep.append(o)
        else: o.hide_render = True
    for o in [o for o in new if o.parent is None]:
        o.location = (o.location.x + dx, o.location.y, o.location.z)
    bpy.context.view_layer.update()
    return keep

def aim_cam(cam, cam_d, pts, center, radius, az, el, resx, resy, pad=1.08):
    import math
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a)*math.cos(e), -math.cos(a)*math.cos(e), math.sin(e))).normalized()
    cam.location = center + d * (radius*4.0 + 2.0)
    cam.rotation_euler = d.to_track_quat('Z','Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1,0,0))).normalized()
    up = (mw.to_3x3() @ Vector((0,1,0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0,0,-1))).normalized()
    wide = max(abs((p-center).dot(right)) for p in pts)*2.0
    tall = max(abs((p-center).dot(up)) for p in pts)*2.0
    cam_d.ortho_scale = max(wide, tall*(resx/float(resy)))*pad
    dep = [(p-cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(dep) - radius*0.5)
    cam_d.clip_end = max(dep) + radius*2.0 + 5.0

def main():
    RX, RY = 1100, 900
    G.purge()
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RX, RY
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None: scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.055,0.06,0.075,1.0)
        bg.inputs['Strength'].default_value = 1.0
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(W5,"assets","buildings","lm_hall.glb"))
    hall = [o for o in bpy.data.objects if o not in before and o.type=='MESH']
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(hall)
    hero = add_hero(dx=mx.x + 1.2)
    gmat = L.mat_solid("gnd", (0.21,0.20,0.18), 0.95, 0.0)
    span = max(mx.x-mn.x, mx.y-mn.y)
    gv, gf = L.box(span*1.5, span*1.5, 0.12)
    gnd = L.make("ground", gv, gf, gmat); gnd.location = ((mn.x+mx.x)/2.0, 0.0, -0.06)
    bpy.context.view_layer.update()
    allm = hall + hero + [gnd]
    mn2, mx2, pts = G.world_bounds(allm)
    center = (mn2+mx2)/2.0; radius = max(1.0, (mx2-mn2).length/2.0)
    G.add_lights(center, radius, (0.85,0.88,0.95))
    cam_d = bpy.data.cameras.new("cam"); cam_d.type='ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam); scene.camera = cam
    outd = os.path.join(W5,"renders","art","town","_probe","lm_hall_tex"); os.makedirs(outd, exist_ok=True)
    rep = {"dims":[round(v,4) for v in (mx.x-mn.x,mx.y-mn.y,mx.z-mn.z)],
           "min":[round(mn.x,4),round(mn.y,4),round(mn.z,4)],
           "centre_xy":[round(((mn+mx)/2).x,4), round(((mn+mx)/2).y,4)],
           "n_tri": sum(len(o.data.polygons) for o in hall),
           "n_mesh": len(hall), "views":{}}
    for vname, az, el in (("front",0.0,10.0),("three_quarter",38.0,14.0),("side",90.0,10.0),("back",180.0,10.0)):
        aim_cam(cam, cam_d, pts, center, radius, az, el, RX, RY)
        p = os.path.join(outd, "%s.png" % vname)
        scene.render.filepath = p; bpy.ops.render.render(write_still=True)
        a = G.read_png(p)
        op = int((a[...,3] > 0.03).sum())
        e = np.concatenate([a[0,:,3],a[-1,:,3],a[:,0,3],a[:,-1,3]])
        rep["views"][vname] = {"opaque_px": op, "border_alpha_px": int((e>0.03).sum())}
    json.dump(rep, open(os.path.join(outd,"_report.json"),"w"), indent=1)
    print("HALLOOK " + json.dumps(rep))
main()
