"""_worldfit_packshot - A LABELLED PICTURE OF THE PACK base_dz_m FINDING.

  blender -b -noaudio -P tools/art/_worldfit_packshot.py -- --repo <repo>
          [--manifest renders/art/worldfit/_packs_manifest.json]

20 Nov 2026, 08:4x CT. 669 pack files measured this run; 180 sink below their
pivot and 22 FLOAT above it. The team lead's 07:58 row is that the SIGN is half
the instruction - a single shift applied to the whole abs() list fixes the
sinkers and buries every floater - so the sheet has to show BOTH SIGNS through
one camera against one floor line, or it is not evidence for the claim.

THREE THINGS FIXED FROM `_worldfit_baseshot`, ALL OF THEM FAULTS I LISTED
AGAINST MY OWN SHEET LAST RUN AND NOT NEW WORK:
  1. *** EVERY MODEL IS LABELLED *** with its name and its signed base_dz_m.
     The old sheet was four props and a bar and you had to read the JSON to know
     which was which.
  2. The floor slab is 0.30 m thick, not 0.06 m, so it reads as a FLOOR and not
     as a pale line. "Below the floor" is the whole verdict; it must be visible.
  3. *** THE LABELS ARE THEMSELVES CHECKED, PER LABEL. *** A caption that failed
     to render would make the sheet MORE misleading than no caption at all - the
     exact fault class as `head_glow_px: 156` beside "the head has no face", and
     a labels-only alpha total would go green while one glyph was missing. Each
     label's own camera-space box is read for opaque pixels, and the arm goes RED
     ON EMPTY: zero labels found is a red sheet, never a clean one.

Picks come OFF THE MANIFEST by rank, never by eye or by memory.
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view as w2c

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G  # noqa: E402


def pick(man):
    """The worst float, the worst sinks, and a flush control - BY RANK."""
    rows = []
    for d, v in man["dirs"].items():
        root = v["root"]
        for r in v["rows"]:
            if r.get("base_dz_m") is None or r["errors"]:
                continue
            rows.append((d, root, r))
    floats = sorted((r for r in rows if r[2]["base_dir"] == "float"),
                    key=lambda t: -t[2]["base_dz_m"])
    sinks = sorted((r for r in rows if r[2]["base_dir"] == "sink"),
                   key=lambda t: t[2]["base_dz_m"])
    flush = sorted((r for r in rows if r[2]["base_dir"] == "flush"),
                   key=lambda t: abs(t[2]["base_dz_m"]))
    out = []
    if floats:
        out.append(floats[0])
    out += sinks[:2]
    # the probe suspect: the 2x2x2 trap tile, named so the sheet answers it
    for t in rows:
        if t[2]["file"].startswith("tileSpikes.gltf"):
            out.append(t)
            break
    if flush:
        out.append(flush[0])
    return out


def mat(name, rgba, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = rgba
    b.inputs["Roughness"].default_value = 0.6
    if emit:
        b.inputs["Emission Color"].default_value = rgba
        b.inputs["Emission Strength"].default_value = emit
    return m


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--manifest", default="renders/art/worldfit/_packs_manifest.json")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    mpath = args.manifest if os.path.isabs(args.manifest) else os.path.join(args.repo, args.manifest)
    with open(mpath, encoding="utf-8") as f:
        man = json.load(f)
    picks = pick(man)
    if not picks:
        raise RuntimeError("no picks off the manifest - refusing to render a sheet")
    out = args.out or os.path.join(args.repo, "renders", "art", "worldfit", "_pack_base_offsets.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    bpy.ops.wm.read_homefile(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = 2000, 900
    sc.render.film_transparent = False
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.07, 0.08, 0.10, 1)
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

    floor_m = mat("floor", (0.33, 0.30, 0.27, 1))
    bar_m = mat("bar", (0.90, 0.72, 0.25, 1), emit=0.8)
    lab_sink = mat("lab_sink", (1.0, 0.45, 0.35, 1), emit=2.2)
    lab_float = mat("lab_float", (0.45, 0.80, 1.0, 1), emit=2.2)
    lab_flush = mat("lab_flush", (0.80, 0.86, 0.80, 1), emit=2.2)

    placed, labels, report = [], [], []
    x = 0.0
    for d, root, r in picks:
        path = os.path.join(root, r.get("rel", r["file"]).replace("/", os.sep))
        if not os.path.isfile(path):
            report.append({"file": r["file"], "error": "missing: " + path})
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        new = [o for o in bpy.data.objects if o not in before]
        meshes = [o for o in new if o.type == 'MESH']
        if not meshes:
            report.append({"file": r["file"], "error": "no meshes"})
            continue
        bpy.context.view_layer.update()
        mn, mx, _ = G.world_bounds(meshes)
        # THE PIVOT GOES TO z=0, the slab's top face. Nothing is re-centred:
        # this is literally what a spawner that trusts the pivot does.
        shift = x - (mn.x + mx.x) / 2.0
        for o in [o for o in new if o.parent is None]:
            o.location.x += shift
        bpy.context.view_layer.update()
        mn2, mx2, _ = G.world_bounds(meshes)
        report.append({"file": r["file"], "dir": d, "base_dz_m": round(mn2.z, 4),
                       "top_m": round(mx2.z, 4), "base_dir": r["base_dir"],
                       "below_floor": bool(mn2.z < -0.05),
                       "manifest_base_dz_m": r["base_dz_m"]})
        placed += meshes

        # --- the label, directly under the model, facing the side camera ---
        cu = bpy.data.curves.new(name="t_" + r["file"], type='FONT')
        cu.body = "%s\n%+0.3f m" % (r["file"].replace(".gltf.glb", "").replace(".gltf", "")
                                    .replace(".glb", ""), r["base_dz_m"])
        cu.align_x = 'CENTER'
        cu.size = 0.42
        t = bpy.data.objects.new("lab_" + r["file"], cu)
        sc.collection.objects.link(t)
        t.location = (x, -3.2, min(mn2.z, 0.0) - 1.0)
        t.rotation_euler = (math.radians(90), 0, 0)
        t.data.materials.append(lab_sink if r["base_dir"] == "sink" else
                                lab_float if r["base_dir"] == "float" else lab_flush)
        labels.append((r["file"], t))
        x += max(mx.x - mn.x, 2.6) + 1.6

    if not placed:
        raise RuntimeError("nothing placed - refusing to report a sheet")
    span = x

    # *** THE SLAB MUST RUN UNDER EVERYTHING, AND IN THE FIRST RENDER IT DID NOT. ***
    # I looked at the sheet: the slab was sized off `span` alone and started to
    # the RIGHT of the 1.80 m bar and of Roof_Log - so the one model whose whole
    # finding is that it FLOATS had no floor line beneath it, and "+3.849 m" was
    # readable only from the caption. A floor-relative verdict with no floor in
    # the frame is the picture equivalent of a green number nobody can see.
    # The extent is now taken from the placed geometry itself, bar included.
    mnp, mxp, _ = G.world_bounds(placed)
    x_lo = min(mnp.x, -3.0) - 1.5
    x_hi = max(mxp.x, span) + 1.5
    bpy.ops.mesh.primitive_cube_add(size=1)
    sl = bpy.context.object
    # *** AND THE SECOND LOOK FOUND THE REAL CAUSE, WHICH WAS ARITHMETIC. ***
    # `primitive_cube_add(size=1)` is a UNIT cube spanning -0.5..+0.5, so a
    # scale of s gives a width of s, NOT 2s. Both this sheet and
    # `_worldfit_baseshot` halved their own floor by writing `width / 2`, which
    # is why extending the extent moved the slab barely at all on the re-render.
    # The number said "the slab spans the sheet" and the picture said it did
    # not, and the picture was right - same rule as pass 11.
    sl.scale = (x_hi - x_lo, 12.0, 0.30)              # THICK, so it reads as a floor
    sl.location = ((x_lo + x_hi) / 2.0, 0.0, -0.15)
    sl.data.materials.append(floor_m)
    bpy.ops.mesh.primitive_cube_add(size=1)
    bar = bpy.context.object
    bar.scale = (0.12, 0.12, 1.80)
    bar.location = (-2.2, 0.0, 0.90)
    bar.data.materials.append(bar_m)
    cu = bpy.data.curves.new("t_bar", type='FONT')
    cu.body = "1.80 m\nhuman"
    cu.align_x = 'CENTER'
    cu.size = 0.42
    barlab = bpy.data.objects.new("lab_bar", cu)
    sc.collection.objects.link(barlab)
    barlab.location = (-2.2, -3.2, -1.0)
    barlab.rotation_euler = (math.radians(90), 0, 0)
    barlab.data.materials.append(lab_flush)
    labels.append(("1.80 m bar", barlab))

    everything = placed + [sl, bar] + [t for _, t in labels]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(everything)
    cx, cz = (mn.x + mx.x) / 2.0, (mn.z + mx.z) / 2.0
    w, h = mx.x - mn.x, mx.z - mn.z

    cam_d = bpy.data.cameras.new("c")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = max(w, h * sc.render.resolution_x / sc.render.resolution_y) * 1.08
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    dist = max(w, h) * 3.0 + 12.0
    cam.location = (cx, mn.y - dist, cz)
    cam.rotation_euler = (math.radians(90), 0, 0)
    cam_d.clip_start = 0.01
    cam_d.clip_end = dist * 4.0                       # TRAP 1: never the default
    sc.camera = cam

    for loc, e in (((cx - w, mn.y - dist * 0.6, cz + h), 6.0),
                   ((cx + w, mn.y - dist * 0.4, cz + h * 0.4), 3.5)):
        lt = bpy.data.lights.new("l", 'AREA')
        lt.energy = e * 1000
        lt.size = max(w, 6.0)
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
    checks = {"nonblank": bool(lum.max() - lum.min() > 0.05),
              "lum_min": round(float(lum.min()), 4), "lum_max": round(float(lum.max()), 4)}

    # --- props-only pass: the border question is about the PROPS, not the slab ---
    for ob in (sl, bar, barlab):
        ob.hide_render = True
    for _, t in labels:
        t.hide_render = True
    sc.render.film_transparent = True
    probe = os.path.join(os.path.dirname(out), "_pack_base_offsets_propsonly.png")
    sc.render.filepath = probe
    bpy.ops.render.render(write_still=True)
    pi = bpy.data.images.load(probe)
    pi.colorspace_settings.name = 'Non-Color'
    pa = np.array(pi.pixels[:], dtype=np.float32).reshape(pi.size[1], pi.size[0], 4)
    al = pa[:, :, 3]
    checks["props_opaque_frac"] = round(float((al > 0.5).mean()), 4)
    checks["props_border_frac"] = round(float((np.concatenate(
        [al[0], al[-1], al[:, 0], al[:, -1]]) > 0.5).mean()), 4)
    checks["props_visible"] = checks["props_opaque_frac"] > 0.002
    checks["border_clear"] = checks["props_border_frac"] < 0.002

    # --- LABELS-ONLY pass, read PER LABEL in its own camera-space box ---
    for ob in placed:
        ob.hide_render = True
    for _, t in labels:
        t.hide_render = False
    lab_png = os.path.join(os.path.dirname(out), "_pack_base_offsets_labelsonly.png")
    sc.render.filepath = lab_png
    bpy.ops.render.render(write_still=True)
    li = bpy.data.images.load(lab_png)
    li.colorspace_settings.name = 'Non-Color'
    la = np.array(li.pixels[:], dtype=np.float32).reshape(li.size[1], li.size[0], 4)
    lalpha = la[:, :, 3]
    H, W = lalpha.shape
    dg = bpy.context.evaluated_depsgraph_get()
    per_label, blank_labels = {}, []
    for name, t in labels:
        te = t.evaluated_get(dg)
        pts = [te.matrix_world @ v for v in [__import__("mathutils").Vector(c)
                                             for c in te.bound_box]]
        us, vs = [], []
        for p in pts:
            co = w2c(sc, cam, p)
            us.append(co.x)
            vs.append(co.y)
        x0 = max(0, int(min(us) * W) - 4)
        x1 = min(W, int(max(us) * W) + 4)
        y0 = max(0, int(min(vs) * H) - 4)
        y1 = min(H, int(max(vs) * H) + 4)
        box = lalpha[y0:y1, x0:x1]
        n = int((box > 0.5).sum()) if box.size else 0
        per_label[name] = {"opaque_px": n, "box": [x0, y0, x1, y1],
                           "in_frame": bool(0 <= min(us) and max(us) <= 1
                                            and 0 <= min(vs) and max(vs) <= 1)}
        if n < 20 or not per_label[name]["in_frame"]:
            blank_labels.append(name)
    checks["labels_expected"] = len(labels)
    checks["labels_read"] = len(per_label)
    checks["labels_blank_or_clipped"] = blank_labels
    # RED ON EMPTY: a labels pass over zero labels is not a green labels pass.
    checks["labels_ok"] = bool(len(per_label) == len(labels) and len(labels) > 0
                               and not blank_labels)

    rep = {"png": os.path.relpath(out, args.repo).replace("\\", "/"),
           "placed": report, "labels": per_label, "checks": checks,
           "floorgeom_stamp": man["floorgeom"]["stamp"]}
    with open(os.path.join(os.path.dirname(out), "_pack_base_offsets.json"),
              "w", encoding="utf-8") as fh:
        json.dump(rep, fh, indent=1, sort_keys=True)
    print("PACKSHOT " + json.dumps(rep))
    good = (checks["nonblank"] and checks["border_clear"]
            and checks["props_visible"] and checks["labels_ok"])
    print("PACKSHOT " + ("GREEN - not blank, props visible, nothing clipped, every "
                         "label rendered in frame" if good else
                         "RED - blank, invisible, clipped, or a label missing: %s"
                         % (blank_labels or "see checks")))
    return 0


if __name__ == "__main__":
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    sys.exit(main(a))
