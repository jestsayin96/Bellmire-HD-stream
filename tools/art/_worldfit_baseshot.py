"""_worldfit_baseshot - A PICTURE OF THE base_dz_m FINDING.

  blender -b -noaudio -P tools/art/_worldfit_baseshot.py -- --repo <repo>

The manifest says Banner_1_Cloth reaches 2.25 m BELOW its own pivot. A number
like that is exactly the kind this lane has shipped wrong twice (a `head_glow_px`
of 156 beside "the head has no face"), so it gets a picture: each file placed
with its PIVOT AT y=0 on a floor slab, viewed from the side, orthographic, with
a 1.80 m human bar beside it. Anything hanging below the slab's top face is
hanging through the dungeon floor, and you can SEE it.

Blank AND border checked with numpy, Non-Color, like every other sheet here.
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G  # noqa: E402

# chosen OFF THE MANIFEST, not by eye: the three worst sinkers in the two
# dungeon-placed directories, plus a control the manifest says is clean.
PICKS = [("assets/props", "Banner_1_Cloth.gltf"),
         ("assets/dungeon", "Fence_Straight_Modular.glb"),
         ("assets/props", "Workbench_Drawers.gltf"),
         ("assets/props", "Barrel.gltf")]


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    out = args.out or os.path.join(args.repo, "renders", "art", "worldfit", "_base_offsets.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    bpy.ops.wm.read_homefile(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = 1600, 700
    sc.render.film_transparent = False
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.08, 0.09, 0.11, 1)
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

    def mat(name, rgba):
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = rgba
        b.inputs["Roughness"].default_value = 0.6
        return m

    floor_m = mat("floor", (0.30, 0.28, 0.26, 1))
    bar_m = mat("bar", (0.90, 0.72, 0.25, 1))

    placed, report = [], []
    x = 0.0
    for d, f in PICKS:
        path = os.path.join(args.repo, d, f)
        if not os.path.isfile(path):
            report.append({"file": f, "error": "missing"})
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        new = [o for o in bpy.data.objects if o not in before]
        meshes = [o for o in new if o.type == 'MESH']
        if not meshes:
            report.append({"file": f, "error": "no meshes"})
            continue
        bpy.context.view_layer.update()
        mn, mx, _ = G.world_bounds(meshes)
        # the PIVOT goes to the slab's top face (z=0). Nothing is re-centred -
        # that is the whole point: this is what a spawner at floor level does.
        for o in [o for o in new if o.parent is None]:
            o.location.x += x
        bpy.context.view_layer.update()
        mn2, mx2, _ = G.world_bounds(meshes)
        report.append({"file": f, "dir": d, "base_dz_m": round(mn2.z, 4),
                       "top_m": round(mx2.z, 4),
                       "below_floor": bool(mn2.z < -0.05)})
        placed += meshes
        x += max(mx.x - mn.x, 1.2) + 1.0

    if not placed:
        raise RuntimeError("nothing placed - refusing to report a sheet")
    span = x
    # floor slab: top face EXACTLY z=0, so "below the slab" is unambiguous
    bpy.ops.mesh.primitive_cube_add(size=1)
    sl = bpy.context.object
    sl.scale = (span / 2.0 + 2.0, 3.0, 0.06)
    sl.location = (span / 2.0 - 1.0, 0.0, -0.06)
    sl.data.materials.append(floor_m)
    # 1.80 m human bar at the left
    bpy.ops.mesh.primitive_cube_add(size=1)
    bar = bpy.context.object
    bar.scale = (0.10, 0.10, 1.80)
    bar.location = (-1.6, 0.0, 0.90)
    bar.data.materials.append(bar_m)

    everything = placed + [sl, bar]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(everything)
    cx, cz = (mn.x + mx.x) / 2.0, (mn.z + mx.z) / 2.0
    w, h = mx.x - mn.x, mx.z - mn.z

    cam_d = bpy.data.cameras.new("c")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = max(w, h * sc.render.resolution_x / sc.render.resolution_y) * 1.12
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    dist = max(w, h) * 3.0 + 10.0
    cam.location = (cx, mn.y - dist, cz)
    cam.rotation_euler = (math.radians(90), 0, 0)
    cam_d.clip_start = 0.01
    cam_d.clip_end = dist * 4.0          # TRAP 1: never the default 100
    sc.camera = cam

    for loc, e in (((cx - w, mn.y - dist * 0.6, cz + h), 5.0),
                   ((cx + w, mn.y - dist * 0.4, cz + h * 0.4), 3.0)):
        lt = bpy.data.lights.new("l", 'AREA')
        lt.energy = e * 1000
        lt.size = max(w, 4.0)
        ob = bpy.data.objects.new("l", lt)
        ob.location = loc
        ob.rotation_euler = (math.radians(70), 0, 0)
        sc.collection.objects.link(ob)

    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)

    img = bpy.data.images.load(out)
    img.colorspace_settings.name = 'Non-Color'
    a = np.array(img.pixels[:], dtype=np.float32).reshape(img.size[1], img.size[0], 4)
    lum = a[:, :, :3].max(axis=2)
    # NOT an alpha check: this sheet is rendered on an opaque background, so the
    # blank test has to be CONTRAST, and the border test asks whether anything
    # bright runs off the edge (a clipped prop is not a blank one).
    checks = {
        "nonblank": bool(lum.max() - lum.min() > 0.05),
        "lum_min": round(float(lum.min()), 4), "lum_max": round(float(lum.max()), 4),
        "border_hot_frac": round(float((np.concatenate(
            [lum[0], lum[-1], lum[:, 0], lum[:, -1]]) > 0.30).mean()), 4),
    }
    # *** THE BORDER ARM CRIED WOLF ON ITS FIRST RUN: border_hot_frac 1.0. ***
    # It was reading the FLOOR SLAB, which is MEANT to run off both edges of a
    # side view. "Is anything bright at the edge" is not the viewer's question;
    # "is a PROP cut by the frame" is. So the props are re-rendered ALONE on
    # transparent, and the border is read off THAT alpha. Same lesson as pass 11:
    # when a number and a picture disagree, the number is the suspect.
    for ob in (sl, bar):
        ob.hide_render = True
    sc.render.film_transparent = True
    probe = os.path.join(os.path.dirname(out), "_base_offsets_propsonly.png")
    sc.render.filepath = probe
    bpy.ops.render.render(write_still=True)
    pi = bpy.data.images.load(probe)
    pi.colorspace_settings.name = 'Non-Color'
    pa = np.array(pi.pixels[:], dtype=np.float32).reshape(pi.size[1], pi.size[0], 4)
    al = pa[:, :, 3]
    checks["props_opaque_frac"] = round(float((al > 0.5).mean()), 4)
    checks["props_border_frac"] = round(float((np.concatenate(
        [al[0], al[-1], al[:, 0], al[:, -1]]) > 0.5).mean()), 4)
    # RED ON EMPTY: zero opaque prop pixels is a blank sheet, not a clean one.
    checks["props_visible"] = checks["props_opaque_frac"] > 0.002
    checks["border_clear"] = checks["props_border_frac"] < 0.002
    rep = {"png": os.path.relpath(out, args.repo).replace("\\", "/"),
           "placed": report, "checks": checks}
    with open(os.path.join(os.path.dirname(out), "_base_offsets.json"),
              "w", encoding="utf-8") as fh:
        json.dump(rep, fh, indent=1, sort_keys=True)
    print("BASESHOT " + json.dumps(rep))
    good = checks["nonblank"] and checks["border_clear"] and checks["props_visible"]
    print("BASESHOT " + ("GREEN - not blank, props visible, no prop touches the frame"
                         if good else "RED - blank, invisible or clipped at the frame"))
    return 0


if __name__ == "__main__":
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    sys.exit(main(a))
