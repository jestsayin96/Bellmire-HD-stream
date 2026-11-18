"""_drover_brown_ab - ONE QUESTION, ASKED AS AN A/B.

The team lead's 04:07 row: "the Drover's body reads markedly BROWNER in
hero_back.png than in hero_front.png. I believe that is your lighting rig and
not the material, and I am NOT calling it a fault - but you are the only lane
that can say."

I am not answering it by reading the code, because reading the code is how
this lane has twice talked itself into a number. ONE THING CHANGES between
arm A and arm B: the colour of the `rim` light in lordgen.add_lights.

  A  rim = info['aura'], i.e. SHIPPED. The Drover's aura is (0.86,0.78,0.62),
     a warm tan, and the rim sits at (0.1, 1.0, 0.55) - BEHIND the body.
  B  rim = (1,1,1), white, same energy, same place. Nothing else differs:
     same geometry, same materials, same key, same fill, same cameras.

If the front/back colour split survives arm B it is the MATERIAL. If it
collapses, it is the RIG - and specifically the aura-coloured rim, which the
back camera looks straight into and the front camera does not.

  blender -b -noaudio -P tools/art/_drover_brown_ab.py -- --repo <repo>
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossgen as MG     # noqa: E402

KEY = "drover"
RES = (520, 700)
# front is -Y for every body in this register; back is +Y. Same 12 deg of
# elevation as lordgen's own front view so the two arms differ in ONE thing.
CAMS = (("front", Vector((0.0, -1.0, 0.0))), ("back", Vector((0.0, 1.0, 0.0))))
ELEV = 12.0


def lights(center, radius, rim_col):
    """lordgen.add_lights, verbatim, with rim colour as the ONLY parameter."""
    specs = (("key", (0.9, -1.0, 0.85), 'SUN', 2.3, (1.0, 0.97, 0.92)),
             ("fill", (-1.0, -0.6, 0.35), 'AREA', 1.0, (0.72, 0.80, 1.0)),
             ("rim", (0.1, 1.0, 0.55), 'AREA', 1.0, rim_col))
    made = []
    for name, d, kind, e, col in specs:
        li = bpy.data.lights.new(name, type=kind)
        li.color = col
        if kind == 'SUN':
            li.energy = e
        else:
            li.energy = 1400.0 * (radius / 3.0) ** 2 * (0.85 if name == "rim" else 0.75)
            li.size = radius * 2.2
        ob = bpy.data.objects.new(name, li)
        bpy.context.collection.objects.link(ob)
        dirv = Vector(d).normalized()
        ob.location = center + dirv * (radius * 4.0)
        ob.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        made.append(ob)
    return made


def measure(path):
    a = G.read_png(path)
    al = a[:, :, 3]
    m = al > 0.55
    n = int(m.sum())
    if n == 0:
        return None
    rgb = a[:, :, :3][m]
    mean = rgb.mean(axis=0)
    mx, mn = rgb.max(axis=1), rgb.min(axis=1)
    sat = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    # "browner" is warm-minus-cool over value: a single scalar either arm can
    # move. Positive = warm.
    warm = float(((rgb[:, 0] - rgb[:, 2]) / np.maximum(mx, 1e-6)).mean())
    return dict(px=n, mean=[round(float(v), 4) for v in mean],
                sat=round(float(sat.mean()), 4), warm=round(warm, 4),
                value=round(float(mx.mean()), 4))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    outdir = os.path.join(a.repo, "renders", "art", "minibosses", "_brown_ab")
    os.makedirs(outdir, exist_ok=True)

    G.purge()
    objs, info = MG.build_miniboss(KEY)
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")

    mn, mx, pts = G.world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    out = {"arms": {}, "errors": []}
    arms = (("A_shipped_aura", tuple(info['aura'])), ("B_white_rim", (1.0, 1.0, 1.0)))
    for arm, rim in arms:
        for ob in [o for o in bpy.data.objects if o.type == 'LIGHT']:
            bpy.data.objects.remove(ob, do_unlink=True)
        lights(center, radius, rim)
        res = {}
        for vname, base in CAMS:
            e = math.radians(ELEV)
            dirv = Vector((base.x * math.cos(e), base.y * math.cos(e), math.sin(e))).normalized()
            cam.location = center + dirv * (radius * 4.0 + 2.0)
            cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
            bpy.context.view_layer.update()
            mw = cam.matrix_world
            right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
            up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
            fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
            wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
            tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
            depth = [(p - cam.location).dot(fwd) for p in pts]
            cam_d.ortho_scale = max(tall, wide * (RES[1] / float(RES[0]))) * 1.10
            cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
            cam_d.clip_end = max(depth) + radius * 2.0 + 5.0
            path = os.path.join(outdir, "%s_%s.png" % (arm, vname))
            scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            m = measure(path)
            if m is None:
                out["errors"].append("BLANK %s %s" % (arm, vname))
            res[vname] = m
        out["arms"][arm] = res

    for arm, r in out["arms"].items():
        if r.get("front") and r.get("back"):
            out.setdefault("warm_gap", {})[arm] = round(r["back"]["warm"] - r["front"]["warm"], 4)
            out.setdefault("sat_gap", {})[arm] = round(r["back"]["sat"] - r["front"]["sat"], 4)
    g = out.get("warm_gap", {})
    if "A_shipped_aura" in g and "B_white_rim" in g:
        out["verdict"] = ("RIG" if abs(g["B_white_rim"]) < abs(g["A_shipped_aura"]) * 0.5
                          else "MATERIAL")
        out["collapse_frac"] = (round(abs(g["B_white_rim"]) / abs(g["A_shipped_aura"]), 4)
                                if abs(g["A_shipped_aura"]) > 1e-9 else None)
    else:
        out["verdict"] = "NO READ"
    json.dump(out, open(os.path.join(outdir, "_brown_ab.json"), "w"), indent=1)
    print("BROWN_AB " + json.dumps(out))


main()
