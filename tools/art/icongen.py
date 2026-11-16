"""icongen - D73, a rendered face for every one of the 454 named items.

  blender -b -noaudio -P tools/art/icongen.py -- --repo <repo> [--limit N] [--res 256]

An icon is not a worn model (that is D74). It is a small rendered image that
identifies an item wherever it is NAMED - the hub's Satchel and hero sheet, the
shop, the Chronicle, chat's answer to a !hero. Generated parametrically from
each item's own fields, so 454 icons need no sculpts at all.

Shares lordgen's render rig, bounds-derived clipping and blank check: a camera
left on default clip renders an empty transparent image and reports success,
and every written PNG is re-opened and asserted to have opaque pixels.
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
import lordlib as L            # noqa: E402
import icons as IC             # noqa: E402
from lordgen import (purge, set_engine, world_bounds, read_png, write_png,
                     box2, draw_text)   # noqa: E402

VIEW = Vector((0.42, -1.0, 0.34)).normalized()


def srgb(h):
    h = h.lstrip('#')
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def records(repo):
    d = json.load(open(os.path.join(repo, "data", "items.json"), encoding="utf-8"))
    # D94c-2: the cloak shade step needs the whole list to assign (see icons.py)
    IC.register_cloaks(d.get("accessories", {}))
    recs = []
    for key, e in d["accessories"].items():
        if not isinstance(e, dict):
            continue
        stat = next((s for s in IC.STAT_ORDER if s in e), None)
        recs.append(dict(key=key, name=e["name"], fam=e["slot"], cost=e["cost"],
                         colour=None, stat=stat, group="accessory"))
    for key, e in d["cosmetics"].items():
        if not isinstance(e, dict) or "colour" not in e:
            continue
        recs.append(dict(key=key, name=e["name"], fam=e["kind"], cost=e["cost"],
                         colour=e["colour"], stat=None, group="cosmetic"))
    lo, hi = {}, {}
    for r in recs:
        lo[r["fam"]] = min(lo.get(r["fam"], 1e9), r["cost"])
        hi[r["fam"]] = max(hi.get(r["fam"], 0), r["cost"])
    for r in recs:
        span = max(1.0, hi[r["fam"]] - lo[r["fam"]])
        r["orn"] = (r["cost"] - lo[r["fam"]]) / span
    return recs


def context(r):
    h = 0
    for ch in r["key"]:
        h = (h * 131 + ord(ch)) & 0xFFFFFFFF
    orn = r["orn"]
    metal = IC.METALS[min(3, int(orn * 4.0))]
    if r["colour"]:
        cloth = srgb(r["colour"])
        gem = tuple(min(1.0, c * 1.5 + 0.12) for c in cloth)
    else:
        # accessories carry no colour, so the key picks a leather tone - and a
        # CLOAK picks a dye instead (D94c). One shared rule in icons.cloth_tone,
        # mirrored in gear.gd, or the hub icon and the hero are two objects.
        cloth = IC.cloth_tone(r["fam"], r["key"], r["name"])
        gem = IC.STAT_GEM.get(r["stat"], (0.70, 0.70, 0.74))
    return dict(variant=IC.variant_for(r["fam"], r["key"], r["name"], h),
                orn=orn, metal=metal, cloth=cloth, gem=gem,
                D=IC.sig(r["key"], r["name"]),
                metal_name=IC.METAL_NAMES[min(3, int(orn * 4.0))])


def make_icon(r, ctx, outdir, res):
    mats = {'metal': L.mat_solid("m", ctx['metal'], 0.34, 0.85),
            'cloth': L.mat_solid("c", ctx['cloth'], 0.68, 0.02),
            'dark': L.mat_solid("d", tuple(c * 0.42 for c in ctx['cloth']), 0.72, 0.03),
            'gem': L.mat_solid("g", ctx['gem'], 0.18, 0.12)}
    P = IC.build(r["key"], r["fam"], ctx)
    groups = {}
    for verts, faces, slot in P.items:
        gv, gf = groups.setdefault(slot, ([], []))
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(i + off for i in f) for f in faces])
    objs = [L.make("%s_%s" % (r["key"], s), gv, gf, mats.get(s, mats['cloth']))
            for s, (gv, gf) in groups.items() if gf]
    if not objs:
        raise RuntimeError("no geometry for %s" % r["key"])

    scene = bpy.context.scene
    set_engine(scene)
    scene.render.resolution_x = scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.10, 0.11, 0.13, 1.0)
        bg.inputs['Strength'].default_value = 1.0

    mn, mx, pts = world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.15, (mx - mn).length / 2.0)
    for nm, d, e, col in (("k", (0.7, -1.0, 0.8), 3.0, (1.0, 0.98, 0.94)),
                          ("f", (-0.9, -0.5, 0.2), 1.3, (0.74, 0.80, 1.0)),
                          ("r", (0.0, 0.9, 0.5), 1.8, (1.0, 0.92, 0.80))):
        li = bpy.data.lights.new(nm, type='SUN')
        li.energy, li.color = e, col
        ob = bpy.data.objects.new(nm, li)
        bpy.context.collection.objects.link(ob)
        dirv = Vector(d).normalized()
        ob.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    dist = radius * 4.0 + 2.0
    cam.location = center + VIEW * dist
    cam.rotation_euler = VIEW.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    depth = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.ortho_scale = max(wide, tall) * 1.14
    cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
    cam_d.clip_end = max(depth) + radius * 2.0 + 5.0
    path = os.path.join(outdir, "%s.png" % r["key"])
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path, sum(len(o.data.polygons) for o in objs)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", type=int, default=256)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--fam", default="")
    args = ap.parse_args(argv)

    recs = records(args.repo)
    if args.fam:
        recs = [r for r in recs if r["fam"] == args.fam]
    if args.limit:
        byfam = {}
        keep = []
        for r in recs:
            n = byfam.get(r["fam"], 0)
            if n < args.limit:
                keep.append(r)
                byfam[r["fam"]] = n + 1
        recs = keep

    root = os.path.join(args.repo, "assets", "icons", "items")
    report = {"ok": True, "n": 0, "errors": [], "by_family": {}, "index": {}}
    for r in recs:
        outdir = os.path.join(root, r["fam"])
        os.makedirs(outdir, exist_ok=True)
        purge()
        try:
            ctx = context(r)
            path, faces = make_icon(r, ctx, outdir, args.res)
            report["n"] += 1
            report["by_family"][r["fam"]] = report["by_family"].get(r["fam"], 0) + 1
            report["index"][r["key"]] = dict(name=r["name"], fam=r["fam"], cost=r["cost"],
                                             variant=ctx["variant"], metal=ctx["metal_name"],
                                             stat=r["stat"], colour=r["colour"], faces=faces)
        except Exception:
            import traceback
            report["ok"] = False
            report["errors"].append("%s: %s" % (r["key"], traceback.format_exc()[-400:]))

    # blank check + one contact sheet per family
    purge()
    blanks = []
    sheets_dir = os.path.join(args.repo, "renders", "art", "icons")
    os.makedirs(sheets_dir, exist_ok=True)
    for fam in IC.ORDER:
        fr = sorted([r for r in recs if r["fam"] == fam], key=lambda r: r["key"])
        if not fr:
            continue
        cell = args.res // 2
        cols = int(math.ceil(math.sqrt(len(fr) * 1.3)))
        rows = int(math.ceil(len(fr) / float(cols)))
        lab = 20
        sheet = np.zeros((rows * (cell + lab) + 26, cols * cell, 4), dtype=np.float32)
        sheet[..., 0:3] = np.array((0.07, 0.075, 0.09))
        sheet[..., 3] = 1.0
        draw_text(sheet, "%s  %d ITEMS" % (fam, len(fr)), 8, 7, 2, (0.88, 0.82, 0.68))
        for i, r in enumerate(fr):
            p = os.path.join(root, fam, "%s.png" % r["key"])
            if not os.path.isfile(p):
                blanks.append([r["key"], "missing"])
                continue
            a = read_png(p)
            n = int((a[..., 3] > 0.02).sum())
            if n < 40:
                blanks.append([r["key"], "blank: %d opaque px" % n])
            a = box2(a)
            cx, cy = (i % cols) * cell, (i // cols) * (cell + lab) + 26
            al = a[..., 3:4]
            dst = sheet[cy:cy + cell, cx:cx + cell, 0:3]
            sheet[cy:cy + cell, cx:cx + cell, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            draw_text(sheet, r["key"][:15], cx + 3, cy + cell + 5, 1, (0.62, 0.60, 0.54))
        write_png(os.path.join(sheets_dir, "_%s.png" % fam), sheet)
    report["blank_failures"] = blanks
    if blanks:
        report["ok"] = False
    with open(os.path.join(sheets_dir, "_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("ICONGEN_REPORT " + json.dumps({"ok": report["ok"], "n": report["n"],
                                          "by_family": report["by_family"],
                                          "blanks": blanks[:6], "errors": report["errors"][:2]}))


if __name__ == "__main__":
    main()
