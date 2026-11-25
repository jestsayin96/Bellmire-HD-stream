#!/usr/bin/env python3
"""_collier_ventlabel.py - WHICH MARK IS A VENT AND WHICH IS A SEAM?

  blender -b -noaudio -P tools/art/_collier_ventlabel.py -- --repo <repo>

WHY THIS EXISTS, AND IT IS THE SAME FAULT AS 17 NOV PASS 11 FOR THE THIRD TIME.
Every collier reading since pass 7 comes off `MB_CUEOFF=glow`, which turns off
EVERY glow on this body at once: the four vent mouths AND the three ember
seams. So the front A/B's SEVEN marks have been divided into "four vents and
three somethings" BY EYE, and pass 8 ticked a count of four taken that way.
A number that needs an eye to attribute it is not labelled, it is guessed.

So this renders FOUR arms through ONE LOCKED CAMERA:
    full        - the body as it ships
    glowoff     - MB_CUEOFF=glow, every glow swapped for body, no vertex moved
    seamoff     - COLLIER_SEAMOFF=1, the three seams gone, vents untouched
    seamglowoff - both at once: no seam geometry AND no glow
and takes these differences:
    full - glowoff        = every lit mark (vents AND seams)
    seamoff - seamglowoff = THE VENTS ALONE
    full - seamoff        = THE SEAMS ALONE

*** IT USED TO BE THREE ARMS AND THE VENT LABEL WAS WRONG. 25 Nov 10:4x CT. ***
`seamoff - glowoff` was called "the vents" from pass 10 to pass 13. It is not.
`COLLIER_SEAMOFF` SKIPS BUILDING the seam tubes while `MB_CUEOFF=glow` leaves
them standing and recolours them, so that difference also carries the shading
of a body-coloured tube against the bare flank. It reported SEVEN vent marks on
a four-vent body, three of them at the same centroids as three SEAM marks. The
fourth arm removes the confound by construction rather than by tolerance, and
the old difference is still written out, named IMPURE, so the fault can be
reproduced instead of taken on trust.
Each mark is then labelled by construction. The camera is measured ONCE off the
full body and LOCKED, because a camera that re-fits per arm moves every pixel
and the count reads green for nothing (the Beadle's pass-12 lesson).

*** THERE IS NO THRESHOLD IN IT. *** 05:58 ruling, 25 Nov: no lane invents a
MIN_CUE_PX. ZERO is the only reading that is a verdict on its own; everything
else goes beside a picture somebody looked at.

*** RED ON EMPTY, AND RED ON A DIFFERENCE THAT CANNOT EXIST. ***
  - any arm whose render is blank, or touches the frame border, is RED;
  - the vents-only difference reading ZERO marks is RED: that is either a body
    with no vents at all or an A/B that did not take;
  - ANY pixel that moved in BOTH the vents-only and the seams-only difference
    is RED - a mark cannot be a vent and a seam at once, and a labelling that
    is not disjoint makes every count in the file meaningless. Threshold-free;
  - `full - seamoff` reading ZERO marks is RED: COLLIER_SEAMOFF did nothing,
    so the labelling is a fiction and must not be believed;
  - a run that compared no pairs is RED.
"""
import os
import sys
import json
import math
import argparse
from collections import deque

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402,F401
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402,F401
import minibossgen as MG     # noqa: E402

KEY = "collier"
THRESH = 8.0 / 255.0
# The shipping front camera: minibossfit.shoot hard-codes elevation 6.0 and
# ortho_scale FRAME_W on a 760x520 cell. Matched here so a mark's screen x is
# comparable with `_vent_marks.json`.
FRONT_AZ, FRONT_EL = 0.0, 6.0
CELL_X, CELL_Y = 760, 520
FRAME_W = 5.60


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    # pass 11: render a candidate without overwriting the committed pass-10
    # baseline, so the two can be compared mark for mark.
    ap.add_argument("--tag", default="")
    return ap.parse_args(a)


def build(cueoff="", seamoff=False):
    G.purge()
    for k, v in (("MB_CUEOFF", cueoff),
                 ("COLLIER_SEAMOFF", "1" if seamoff else "")):
        if v:
            os.environ[k] = v
        else:
            os.environ.pop(k, None)
    return MG.build_miniboss(KEY)


def rig(scene, center, radius, aura):
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    G.add_lights(center, radius, aura)


def shoot(path, target, radius):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = FRAME_W
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    a, e = math.radians(FRONT_AZ), math.radians(FRONT_EL)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    dist = radius * 4.0 + 4.0
    cam.location = target + dirv * dist
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    cam_d.clip_start = 0.01
    cam_d.clip_end = dist + radius * 3.0 + 8.0
    bpy.context.view_layer.update()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    return path


def marks(m):
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    out = []
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True; px = []
                while q:
                    cy, cx = q.popleft(); px.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                out.append(px)
    return sorted(out, key=len, reverse=True)


def diff_marks(pa, pb):
    A, B = G.read_png(pa), G.read_png(pb)
    assert A.shape == B.shape, "shape %s vs %s" % (A.shape, B.shape)
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    mk = marks(np.maximum(d, da) > THRESH)
    return [{"px": len(p),
             "cx": round(sum(q[1] for q in p) / len(p), 1),
             "cy": round(sum(q[0] for q in p) / len(p), 1)} for p in mk[:14]]


def diff_mask(pa, pb):
    """The boolean mask behind diff_marks - same test, no labelling."""
    A, B = G.read_png(pa), G.read_png(pb)
    assert A.shape == B.shape, "shape %s vs %s" % (A.shape, B.shape)
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    return np.maximum(d, da) > THRESH


def blank_and_border(path):
    a = G.read_png(path)
    al = a[..., 3]
    return (int((al > 0.5).sum()),
            round(max(float(al[0, :].max()), float(al[-1, :].max()),
                      float(al[:, 0].max()), float(al[:, -1].max())), 4))


def main():
    ns = _args()
    out = os.path.join(ns.repo, "renders", "art", "minibosses",
                       "collier_vlabel" + (("_" + ns.tag) if ns.tag else ""))
    os.makedirs(out, exist_ok=True)
    rep = {"key": KEY, "camera": {"az": FRONT_AZ, "el": FRONT_EL,
                                  "ortho": FRAME_W, "cell": [CELL_X, CELL_Y],
                                  "locked": True},
           "not_a_pass": "no threshold; ZERO is the only verdict on its own "
                         "(05:58 ruling, 25 Nov).",
           "arms": {}, "labels": {}, "errors": []}
    scene = bpy.context.scene
    MG.G.set_engine(scene)

    # ---- the camera is measured ONCE off the full body and then LOCKED ----
    objs, info = build()
    mn, mx, _ = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    target = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0,
                     (mn.z + mx.z) / 2.0))
    rep["camera"]["target"] = [round(c, 4) for c in target]
    rig(scene, target, radius, info["aura"])
    paths = {"full": shoot(os.path.join(out, "full_front.png"), target, radius)}

    # *** THE FOURTH ARM, ADDED 25 Nov 10:4x CT, AND IT EXISTS BECAUSE THE
    # *** THREE-ARM LABELLING WAS WRONG AND I CAUGHT IT IN MY OWN OUTPUT. ***
    # The 10:39 run printed SEVEN "vents only" marks on a body with FOUR vents,
    # and three of them sat at the SAME centroids as three "seams only" marks -
    # one of them identical to the pixel (px 5, cx 489.4, cy 299.2) in BOTH
    # lists. A mark cannot be a vent and a seam at once, so the labelling was
    # not disjoint and `vent_mark_count` was a LYING NUMBER.
    # THE MECHANISM, and it is structural, not a tolerance:
    #   `COLLIER_SEAMOFF=1` SKIPS BUILDING the three seam tubes (minibosses.py
    #   :23224), while `MB_CUEOFF=glow` leaves those tubes standing and only
    #   swaps their material. So `seamoff - glowoff` does not isolate the
    #   vents: it also carries the shading difference between a body-coloured
    #   seam tube and the plain flank where no tube exists at all.
    # THE FIX IS A FOURTH ARM, NOT A TOLERANCE. With `seamglowoff` (seams gone
    # AND glow off) the vents are read between two arms that BOTH have no seam
    # geometry, so the only thing that differs is the vent emission:
    #   vents_only = seamoff - seamglowoff     <- nothing to confound it
    # The old difference is KEPT below under its own name, marked IMPURE, so
    # the defect is reproducible by anyone who doubts this note.
    for name, kw in (("glowoff", dict(cueoff="glow")),
                     ("seamoff", dict(seamoff=True)),
                     ("seamglowoff", dict(cueoff="glow", seamoff=True))):
        o2, i2 = build(**kw)
        rig(scene, target, radius, i2["aura"])
        paths[name] = shoot(os.path.join(out, "%s_front.png" % name),
                            target, radius)

    for name, p in paths.items():
        op, edge = blank_and_border(p)
        rep["arms"][name] = {"opaque_px": op, "border_alpha": edge}
        if op == 0:
            rep["errors"].append("%s render is BLANK - RED" % name)
        if edge > 0.02:
            rep["errors"].append("%s touches the frame border (alpha %.3f) - "
                                 "a clipped render is not a blank one and the "
                                 "blank check cannot see it. RED" % (name, edge))

    rep["labels"]["all_lit__full_minus_glowoff"] = diff_marks(
        paths["full"], paths["glowoff"])
    # THE CLEAN VENT LABEL: both arms have NO seam geometry.
    rep["labels"]["vents_only__seamoff_minus_seamglowoff"] = diff_marks(
        paths["seamoff"], paths["seamglowoff"])
    rep["labels"]["seams_only__full_minus_seamoff"] = diff_marks(
        paths["full"], paths["seamoff"])
    # KEPT AND NAMED FOR WHAT IT IS. This is the difference every pass from 10
    # to 13 called "the vents"; it is not, and leaving it in the file is how
    # the next reader checks that claim instead of taking it from me.
    rep["labels"]["IMPURE_legacy_vents__seamoff_minus_glowoff"] = diff_marks(
        paths["seamoff"], paths["glowoff"])

    # *** THE DISJOINTNESS ARM. NO THRESHOLD IN IT - a pixel that moved in
    # *** BOTH differences is ambiguous BY CONSTRUCTION, and ZERO is the only
    # *** reading that is a verdict on its own (05:58 ruling, 25 Nov).
    # A vent is a thing the seams do not touch and a seam is a thing the vents
    # do not touch, so the two masks must not share one pixel. If they do, no
    # count in this file can be believed and it says so instead of printing a
    # number beside the fault.
    vmask = diff_mask(paths["seamoff"], paths["seamglowoff"])
    smask = diff_mask(paths["full"], paths["seamoff"])
    both = int(np.logical_and(vmask, smask).sum())
    lmask = diff_mask(paths["seamoff"], paths["glowoff"])
    rep["labels_disjoint"] = {
        "vent_px": int(vmask.sum()), "seam_px": int(smask.sum()),
        "shared_px": both,
        "legacy_impure_vent_px": int(lmask.sum()),
        "legacy_shared_px": int(np.logical_and(lmask, smask).sum()),
        "_why": "a pixel in BOTH the vents-only and the seams-only difference "
                "is labelled two ways at once. Threshold-free: the only "
                "acceptable value is 0.",
    }
    if both:
        rep["errors"].append(
            "LABELLING IS NOT DISJOINT: %d pixels moved in BOTH the "
            "vents-only and the seams-only difference, so a mark is being "
            "called a vent and a seam at once and NO count in this file can "
            "be believed. This is a fault in THIS INSTRUMENT, not in the "
            "body - do not go looking for it on the collier. RED" % both)

    v = rep["labels"]["vents_only__seamoff_minus_seamglowoff"]
    s = rep["labels"]["seams_only__full_minus_seamoff"]
    if not v:
        rep["errors"].append("VENTS-ONLY difference is EMPTY - either this body "
                             "has no visible vents at all or the A/B did not "
                             "take. RED, never skipped.")
    if not s:
        rep["errors"].append("SEAMS-ONLY difference is EMPTY - COLLIER_SEAMOFF "
                             "changed nothing, so every label in this file is a "
                             "fiction. RED.")
    rep["vent_mark_count"] = len(v)
    rep["seam_mark_count"] = len(s)
    rep["ok"] = not rep["errors"]
    dst = os.path.join(out, "_ventlabel.json")
    json.dump(rep, open(dst, "w"), indent=1)
    print("WROTE %s ok=%s" % (dst, rep["ok"]))
    print("VENTS ONLY (clean):", json.dumps(v))
    print("DISJOINT   :", json.dumps(rep["labels_disjoint"]))
    print("SEAMS ONLY:", json.dumps(s))
    print("ALL LIT   :", json.dumps(rep["labels"]["all_lit__full_minus_glowoff"]))
    print("ERRORS    :", rep["errors"])


main()
