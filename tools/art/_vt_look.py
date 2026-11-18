"""_vt_look - THE PICTURE BESIDE THE VIEW-TRANSFORM TABLE.

  blender -b -noaudio -P tools/art/_vt_look.py -- --repo <repo> --key greener

The 22:58 ART row asked for a bounded A/B measured as pass 10 measured it, and
_metal_read.py produces those numbers. This produces the thing a number cannot:
the same body, same rig, same camera, under each candidate view transform, side
by side, so the transform's effect can be NAMED and not only scored.

It exists because this lane has twice shipped a number that answered a different
question from the sentence beside it, and both times the render was what caught
it. A saturation table that says "the gap got worse" should be checkable by eye.

CHANGES NO DEFAULT. The transform is set on the scene inside this reader only,
after lordgen.set_engine, exactly as _metal_read.py does it, and it is proved by
readback before a pixel is read.

ASSERTS, AND GOES RED:
  - every tile must have opaque pixels (a transparent tile is a failed render
    that reports success - three blank batches were caught this way)
  - every tile must have a CLEAR BORDER: a body touching the frame edge is
    clipped, and a blank check cannot see a clip
  - a transform that does not apply is an error, never a silent fall back
"""
import os
import sys
import math
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402

TILE = (420, 560)
VIEWS = (("front", 0.0, 2.0), ("side", 90.0, 2.0), ("back", 180.0, 2.0))
TRANSFORMS = ("AgX", "Standard", "Khronos PBR Neutral")


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _mats(key):
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_vb", body, rough, metal),
        'dark': L.mat_solid(key + "_vd", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_vn", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_vg", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    return M.apply_overrides(key, mats)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="greener")
    args = ap.parse_args(argv)
    key = args.key
    out = os.path.join(args.repo, "renders", "art", "minibosses")
    tmp = os.path.join(out, "_vt_look_tmp")
    os.makedirs(tmp, exist_ok=True)
    rep = {"ok": True, "errors": [], "key": key, "transforms": list(TRANSFORMS),
           "views": [v[0] for v in VIEWS], "tiles": {}}

    _clear()
    mats = _mats(key)
    P = M.BUILDERS[key]()
    height = M.CANON[key][1]
    probe = M.merge_objs(key, P.items, mats, suffix="probe",
                         vcols=getattr(P, "vcols", None))
    mn, mx, _ = G.world_bounds(probe)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in probe:
        bpy.data.objects.remove(ob, do_unlink=True)

    obs = M.merge_objs(key, P.items, mats, suffix="full",
                       vcols=getattr(P, "vcols", None))
    for ob in obs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(obs)

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = TILE
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    ctr = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rad = max(1e-3, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    d = rad * 4.0
    cam = bpy.data.cameras.new("vl_cam")
    cam.type = 'ORTHO'
    # 1.50 not _metal_read's 1.34: this is a LOOK shot of the whole body and the
    # border assert must have room to mean something. The numbers come from
    # _metal_read, which keeps its own framing - this file measures nothing.
    cam.ortho_scale = rad * 1.50
    cam.clip_start = max(0.01, d - rad * 3.0)
    cam.clip_end = d + rad * 3.0
    camob = bpy.data.objects.new("vl_cam", cam)
    scene.collection.objects.link(camob)
    scene.camera = camob
    for ang, energy in ((40.0, 3.4), (-120.0, 1.5)):
        li = bpy.data.lights.new("vl_l", 'SUN')
        li.energy = energy
        lo = bpy.data.objects.new("vl_l", li)
        scene.collection.objects.link(lo)
        lo.rotation_euler = (math.radians(55.0), 0.0, math.radians(ang))

    grid = {}
    for vt in TRANSFORMS:
        try:
            scene.view_settings.view_transform = vt
        except Exception as e:
            rep["ok"] = False
            rep["errors"].append("transform %r not available: %s" % (vt, e))
            continue
        if scene.view_settings.view_transform != vt:
            rep["ok"] = False
            rep["errors"].append("transform %r did not apply (scene reports %r)"
                                 % (vt, scene.view_settings.view_transform))
            continue
        for vname, yaw, pitch in VIEWS:
            a_ = math.radians(yaw)
            p_ = math.radians(pitch)
            camob.location = (ctr.x + d * math.sin(a_) * math.cos(p_),
                              ctr.y - d * math.cos(a_) * math.cos(p_),
                              ctr.z + d * math.sin(p_))
            camob.rotation_euler = (math.radians(90.0 - pitch), 0.0, a_)
            bpy.context.view_layer.update()
            path = os.path.join(tmp, "%s_%s_%s.png"
                                % (key, vt.replace(" ", "_"), vname))
            scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            img = G.read_png(path)
            al = img[..., 3]
            opaque = int((al > 0.02).sum())
            b = 3
            border = float(max(al[:b, :].max(), al[-b:, :].max(),
                               al[:, :b].max(), al[:, -b:].max()))
            cellk = "%s/%s" % (vt, vname)
            rep["tiles"][cellk] = {"opaque_px": opaque,
                                   "border_alpha": round(border, 4)}
            if opaque < 2000:
                rep["ok"] = False
                rep["errors"].append("%s: %d opaque px - BLANK OR NEAR-BLANK RENDER"
                                     % (cellk, opaque))
            if border > 0.02:
                rep["ok"] = False
                rep["errors"].append("%s: border alpha %.3f - THE BODY IS CLIPPED BY "
                                     "THE FRAME, which a blank check cannot see"
                                     % (cellk, border))
            grid[(vt, vname)] = img

    if grid:
        h, w = TILE[1], TILE[0]
        rows = len(TRANSFORMS)
        cols = len(VIEWS)
        # RGBA: lordgen.write_png sets four channels, so a three-channel
        # array would be written as garbage or refused.
        sheet = np.zeros((h * rows, w * cols, 4), dtype=np.float32)
        sheet[..., 0:3] = 0.08
        sheet[..., 3] = 1.0
        for ri, vt in enumerate(TRANSFORMS):
            for ci, (vname, _, _) in enumerate(VIEWS):
                img = grid.get((vt, vname))
                if img is None:
                    continue
                al = img[..., 3:4]
                tile = img[..., 0:3] * al + 0.08 * (1.0 - al)
                sheet[ri * h:(ri + 1) * h, ci * w:(ci + 1) * w, 0:3] = tile
        # 2 px rules so the nine cells are unambiguous
        for ri in range(1, rows):
            sheet[ri * h - 1:ri * h + 1, :, 0:3] = 0.55
        for ci in range(1, cols):
            sheet[:, ci * w - 1:ci * w + 1, 0:3] = 0.55
        spath = os.path.join(out, "_vt_look_sheet.png")
        G.write_png(spath, sheet)
        rep["sheet"] = spath
        rep["sheet_layout"] = ("rows top->bottom: %s ; cols left->right: %s"
                               % (", ".join(TRANSFORMS),
                                  ", ".join(v[0] for v in VIEWS)))
    else:
        rep["ok"] = False
        rep["errors"].append("no tiles rendered - red on empty")

    print("VTLOOK " + json.dumps(rep))


main()
