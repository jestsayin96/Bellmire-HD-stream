"""_facingread.py - DOES THIS BODY HAVE A FRONT, OR IS THE BACK THE SAME PICTURE?

  blender -b -noaudio -P tools/art/_facingread.py -- --repo <repo> \
      --keys badger,thatcher,mealman,bellman,beadle

WHY THIS EXISTS. The Beadle shipped with a pale band that wrapped its head, so
the figure read identically from front and back and had NO FACING, and every
number in its register passed. The badger reproduced that fault at passes 2
and 3 while its own builder comment claimed the facing was "geometric by
construction". Twice now a comment predicted a MECHANISM and no one measured
the OUTCOME. This file measures the outcome.

THE VIEWER'S QUESTION, AND IT IS A COMPARISON, NOT A PROPERTY. A viewer behind
a body sees its back; a viewer in front sees its front. They have a facing if
those two pictures are TELLABLE APART. So: render front and back through ONE
camera framing, MIRROR THE BACK IN X (a back view is the front's mirror - not
mirroring it would score every left/right asymmetry as facing twice over), and
ask how much of the picture changed.

  sil_iou     intersection over union of the two alpha silhouettes. 1.000
              means the OUTLINE is the same shape from both sides - whatever
              facing exists is carried inside the outline and will not survive
              being small on screen.
  in_diff_frac over the silhouette INTERSECTION, the fraction of pixels whose
              screen luma differs by more than 0.08. This is the interior
              read: a face, an open coat, a tool on one hip.
  in_mean_abs the mean absolute luma difference over that intersection.
  in_diff_thirds
              THE SAME in_diff_frac COMPUTED SEPARATELY OVER THE TOP, MIDDLE
              AND BOTTOM THIRD of the body's own vertical extent, plus their
              spread (max - min). ADDED 27 NOV 2026 AND HERE IS WHY, because
              the whole-body number ALONE WAS WRONG ONCE AND IT WAS WRONG IN
              MY FAVOUR. The census of all 70 bodies put `stopper` worst at
              0.1794; the picture said stopper is FINE - it has a pale face
              mask with two eyes - and its score is low only because an
              enormous symmetric hexagonal vat rim is most of its pixels and
              DILUTES THE FRACTION. A body that is mostly gear scores as
              facing-less however good its face is. The thirds separate the
              two causes because DILUTION IS UNIFORM AND A DEAD REGION IS NOT:
                  stopper  top 0.186 / mid 0.202 / bot 0.110  spread 0.092
                           -> flat, so the low score is dilution, not a fault
                  bellman  top 0.482 / mid 0.119 / bot 0.033  spread 0.449
                           -> the bottom 44% of the body was genuinely DEAD
              THIS IS STILL NOT A PASS MARK and no bar is set on the spread
              either. It splits a low score into "mostly prop" and "has a
              dead region"; WHICH REGION AND WHETHER THE DIFFERENCE IS A
              FACING is a question only the picture answers.

THERE IS NO PASS MARK IN THIS FILE AND THAT IS DELIBERATE. A bare threshold
invented here would be exactly the kind of unearned number this lane has
shipped before. It runs over a LIST of keys so the body under test is read
against bodies already in the game, and the comparison is the result. Read the
spread, then look at the two pictures it wrote.

WHAT IT CANNOT SEE, SAID PLAINLY:
 1. IT CANNOT ATTRIBUTE. A body that is left/right asymmetric - the badger is
    mid-stride with one hand up on the yoke - scores a difference that is
    POSTURE, not facing. The number answers "are the two pictures different";
    it does not answer "is the difference a face". Looking at the pair does.
 2. It measures VALUE, not hue or shape semantics.
 3. A high in_diff_frac on a body whose silhouettes barely overlap is about a
    small intersection. `inter_px` is printed so that can be seen.
 4. RED ON EMPTY: if either silhouette or the intersection is under MIN_PX,
    nothing here was measured and the cell says so rather than reporting a
    tidy ratio over nothing.
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
import lordlib as L          # noqa: E402,F401
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402,F401
import minibossgen as MG     # noqa: E402
import minibossfit as F      # noqa: E402

MIN_PX = 2000


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def _band(inter, y0, y1, i):
    """The i-th of three horizontal bands over the body's own vertical extent."""
    h = (y1 - y0 + 1) / 3.0
    a = y0 + int(round(i * h))
    b = y0 + int(round((i + 1) * h)) if i < 2 else y1 + 1
    m = np.zeros_like(inter)
    m[a:b, :] = True
    return m


def _one(key, outdir, errs):
    _clear()
    objs, meta = MG.build_miniboss(key)
    mn, mx, pts = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    cent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    sc = bpy.context.scene
    G.set_engine(sc)
    sc.render.resolution_x = sc.render.resolution_y = 760
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    if sc.world is None:
        sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    bg = next((n for n in sc.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    rig = F.even_lights(cent, radius, meta["aura"])
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = max(mx.x - mn.x, mx.z - mn.z) * 1.18
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    sc.camera = cam
    got = {}
    for vname, az in (("front", 0.0), ("back", 180.0)):
        # THE LIGHTS FOLLOW THE CAMERA, exactly as the shipped hero sheet does.
        # If they did not, the back would be measured in the front's lighting
        # and the difference would partly be a lighting difference.
        F.aim_lights(rig, cent, radius, az)
        a, e = math.radians(az), math.radians(6.0)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        cam.location = cent + dirv * (radius * 4.0 + 4.0)
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
        depth = [(p - cam.location).dot(fwd) for p in pts]
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 8.0
        path = os.path.join(outdir, "%s_%s.png" % (key, vname))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        got[vname] = G.read_png(path)
    Ff, Bb = got["front"], got["back"][:, ::-1, :]      # mirror the back in x
    af = Ff[:, :, 3] > 0.5
    ab = Bb[:, :, 3] > 0.5
    inter = af & ab
    union = af | ab
    nf, nb, ni, nu = int(af.sum()), int(ab.sum()), int(inter.sum()), int(union.sum())
    cell = {"front_px": nf, "back_px": nb, "inter_px": ni, "union_px": nu}
    if nf < MIN_PX or nb < MIN_PX or ni < MIN_PX:
        cell["red"] = ("a silhouette or the intersection is under %d px - "
                       "NOTHING WAS MEASURED for this body" % MIN_PX)
        errs.append("%s: silhouettes too small (f %d b %d i %d)"
                    % (key, nf, nb, ni))
        return cell
    d = np.abs(_luma(Ff) - _luma(Bb))
    cell["sil_iou"] = round(ni / float(nu), 4)
    cell["in_diff_frac"] = round(float((d[inter] > 0.08).mean()), 4)
    cell["in_mean_abs"] = round(float(d[inter].mean()), 4)
    # ---- PER-THIRD BREAKDOWN, over the BODY's own vertical extent (not the
    # frame's): a body that does not fill the frame would otherwise get empty
    # bands at top and bottom and read as dead where there is simply nothing.
    rows = np.flatnonzero(union.any(axis=1))
    if rows.size < 3:
        cell["thirds_red"] = ("the union spans %d image rows - NOTHING WAS "
                              "MEASURED per third" % int(rows.size))
        return cell
    y0, y1 = int(rows[0]), int(rows[-1])
    h = (y1 - y0 + 1) / 3.0
    names = ("top", "mid", "bot")
    th, reds = {}, []
    for i, nm in enumerate(names):
        a = y0 + int(round(i * h))
        b = y0 + int(round((i + 1) * h)) if i < 2 else y1 + 1
        band = np.zeros_like(inter)
        band[a:b, :] = True
        sel = inter & band
        n = int(sel.sum())
        # RED ON EMPTY: a fraction over a handful of pixels is not a reading.
        if n < MIN_PX // 3:
            th[nm] = None
            reds.append("%s band has %d intersection px (floor %d)"
                        % (nm, n, MIN_PX // 3))
        else:
            th[nm] = round(float((d[sel] > 0.08).mean()), 4)
    cell["in_diff_thirds"] = th
    cell["thirds_px"] = {nm: int((inter & _band(inter, y0, y1, i)).sum())
                         for i, nm in enumerate(names)}
    vals = [v for v in th.values() if v is not None]
    if len(vals) == 3:
        cell["thirds_spread"] = round(max(vals) - min(vals), 4)
    else:
        cell["thirds_red"] = "; ".join(reds)
    return cell


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", required=True)
    ap.add_argument("--tag", default="")
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_facingread")
    os.makedirs(outdir, exist_ok=True)
    errs = []
    rep = {"tag": args.tag, "bodies": {}, "errors": errs,
           "asks": "are the FRONT and the MIRRORED BACK of this body tellable "
                   "apart, in outline (sil_iou) and inside it (in_diff_frac)",
           "cannot_see": "WHETHER THE DIFFERENCE IS A FACING. Posture, stride "
                         "and one-sided gear all score here. No pass mark is "
                         "set in this file on purpose - read the bodies "
                         "against each other and then look at the pictures."}
    for key in [k.strip() for k in args.keys.split(",") if k.strip()]:
        if key not in M.BUILDERS:
            errs.append("%s: no builder" % key)
            continue
        try:
            rep["bodies"][key] = _one(key, outdir, errs)
        except Exception as e:
            errs.append("%s: %r" % (key, e))
    rep["ok"] = not errs
    out = os.path.join(outdir, "_facingread%s.json" % args.tag)
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print(json.dumps(rep, indent=1))


main()
