"""_bg_ground_ab - DOES THE CREATURE FLOAT, OR IS IT THE CAMERA?

PASS 4, 20 Nov 2026. I looked at hero_side.png after the scale-up and saw the
creature's lowest pixel sitting 41 px BELOW the hero's. On a sheet whose whole
job is "both of these stand on the same floor, look how much bigger one is",
a foot line that disagrees is the fault that would make the ratio a lie.

minibossfit's own comment says the camera is elevated 6 deg and that a DEPTH
offset therefore becomes an IMAGE-HEIGHT offset. That is an explanation, not
evidence, and an explanation beside a picture is exactly what this lane has
been caught trusting twice. So this is an A/B AND IT CAN MOVE: render the side
view twice, once at the harness's 6 deg and once at 0 deg, with nothing else
changed, and measure the foot-row delta in each.

  - If the delta collapses toward 0 at 0 deg, the bodies are ON the floor and
    the 41 px is projection. Nothing to fix in the art.
  - If it survives at 0 deg, one of the two is FLOATING and the ratio in the
    register is measured off a body that is not standing on anything.

GOES RED ON EMPTY: if either mask has no opaque pixels the row is an error,
not a zero - a delta computed over nothing would read as a perfect pass.
"""
import os, sys, math, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, numpy as np
from mathutils import Vector
import lordgen as G
import minibossfit as F
import monstervariants as MV


def _mask_rows(path):
    a = G.read_png(path)
    m = a[:, :, 3] > F.DIFF_EPS
    if not m.any():
        return None
    rows = np.where(m.any(axis=1))[0]
    return int(rows.min()), int(rows.max()), int(m.sum())


def shoot_one(objs, outpath, mn, mx, radius, elev_deg, aura, hide=()):
    scene = bpy.context.scene
    cam = scene.camera
    a, e = math.radians(90.0), math.radians(elev_deg)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    drop = math.sin(e) * (mx.y - mn.y) / 2.0
    target = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0,
                     F.FRAME_H / 2.0 - F.GROUND_UP - drop))
    cam.location = target + dirv * (radius * 4.0 + 4.0)
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    for o in objs:
        o.hide_render = o in hide
    scene.render.filepath = outpath
    bpy.ops.render.render(write_still=True)
    for o in objs:
        o.hide_render = False
    return outpath


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    repo = argv[argv.index("--repo") + 1]
    key = "broodglut"
    G.purge()
    meshes, roots, info = MV.build_variant(key, repo)
    hroots, hmesh, hero = F.import_hero(repo)
    mn, mx, _ = G.world_bounds(meshes)
    F.place(hroots, mn.x - F.GAP - hero["w"] / 2.0 - 0.10,
            mn.y - F.GAP - hero["d"] / 2.0 - 0.10)
    allo = meshes + hmesh
    bpy.context.view_layer.update()
    amn, amx, pts = G.world_bounds(allo)

    # THE WORLD-SPACE ANSWER FIRST - it costs nothing and it is the only one
    # that is not a picture. If both min z are 0 the bodies ARE on the floor.
    cmn, cmx, _ = G.world_bounds(meshes)
    hmn, hmx, _ = G.world_bounds(hmesh)

    need_w = (amx.x - amn.x) * 1.08
    if need_w > F.FRAME_W:
        F.FRAME_W = need_w
        F.FRAME_H = need_w * F.CELL_Y / float(F.CELL_X)
    # The scene setup minibossfit does inside shoot(), replicated here rather
    # than refactoring a file five other registers are measured with.
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = F.CELL_X, F.CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes
               if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    radius = max(0.5, (amx - amn).length / 2.0)
    G.add_lights(Vector(((amn.x + amx.x) / 2.0, (amn.y + amx.y) / 2.0,
                         (amn.z + amx.z) / 2.0)), radius, info["aura"])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = F.FRAME_W
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    cam_d.clip_start = 0.01
    cam_d.clip_end = radius * 12.0 + 40.0
    out = os.path.join(repo, "renders", "art", "variants", "_ground")
    os.makedirs(out, exist_ok=True)

    rows = {}
    for tag, elev in (("e6", 6.0), ("e0", 0.0)):
        rec = {}
        for who, keep in (("hero", hmesh), ("cre", meshes)):
            hide = [o for o in allo if o not in keep]
            p = shoot_one(allo, os.path.join(out, "_%s_%s.png" % (who, tag)),
                          amn, amx, radius, elev, info["aura"], hide=hide)
            r = _mask_rows(p)
            if r is None:
                rec[who] = {"error": "EMPTY MASK - this row proves nothing"}
            else:
                rec[who] = {"top": r[0], "bottom": r[1], "px": r[2]}
        if "error" in rec["hero"] or "error" in rec["cre"]:
            rec["foot_delta_px"] = None
            rec["ok"] = False
        else:
            rec["foot_delta_px"] = rec["cre"]["bottom"] - rec["hero"]["bottom"]
            rec["ok"] = True
        rows[tag] = rec

    d6 = rows["e6"]["foot_delta_px"]
    d0 = rows["e0"]["foot_delta_px"]
    rep = {
        "key": key,
        "world_floor": {
            "creature_min_z": round(cmn.z, 5), "creature_max_z": round(cmx.z, 5),
            "hero_min_z": round(hmn.z, 5), "hero_max_z": round(hmx.z, 5),
            "both_on_floor": bool(abs(cmn.z) < 1e-3 and abs(hmn.z) < 1e-3),
        },
        "depth_separation_m": round(abs(((cmn.y + cmx.y) / 2.0)
                                        - ((hmn.y + hmx.y) / 2.0)), 4),
        "frame_w": round(F.FRAME_W, 3), "frame_h": round(F.FRAME_H, 3),
        "px_per_m": round(F.CELL_Y / F.FRAME_H, 3),
        "rows": rows,
        "elev_deg_harness": 6.0,
    }
    if d6 is None or d0 is None:
        rep["verdict"] = "RED - a mask was empty, this test proved nothing"
    elif abs(d0) <= 4 and abs(d6) > abs(d0):
        rep["verdict"] = ("PROJECTION, NOT A FLOAT - the %d px gap at 6 deg "
                          "collapses to %d px at 0 deg" % (d6, d0))
    elif abs(d0) > 4:
        rep["verdict"] = ("FLOAT - %d px of the gap survives with the camera "
                          "level, so a body is off the floor" % d0)
    else:
        rep["verdict"] = "INCONCLUSIVE"
    with open(os.path.join(out, "_ground_ab.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("GROUND_AB", json.dumps(rep["verdict"]))


main()
