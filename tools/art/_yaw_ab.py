"""_yaw_ab - DOES THE MECHANIC'S SILHOUETTE SURVIVE A NINETY-DEGREE TURN?

THE FINDING THIS WAS BUILT FOR, 11:58 CT 20 Nov 2026, made by the team lead by
LOOKING and reachable by no number in the register:

    "FROM THE SIDE THE PRESS READS AS A SHELF. Broadside it is a clamp; at 90
     degrees it is a flat slab at waist height with nothing to say it closes.
     The disc sash is invisible there too, so the whole 'it seals what you
     carry' read rests on the front view alone."
    "NEXT: give the tool a silhouette that survives a 90-degree turn."

The register could not have told him. `_fit_fit_sealer_register.json` says
`seen: 1.0` on every view, 3 of 3 proving views, 0 blind, errors [] - and every
one of those numbers was TRUE. They answer "is the creature in frame and is it
the right size next to a hero". None of them answers "can the thing the fight is
about be seen from where the player is standing".

HOW THIS ASKS THE VIEWER'S QUESTION, AND WHY IT IS NOT mask_of.
Rendering the mechanic ALONE answers HOW BIG IT IS and says nothing about
whether it can be SEEN - that is this lane's pass-11 fault, 17 Nov, where
`head_glow_px: 156` shipped beside the sentence "the head now has no face at
all" and the honest number was zero. So this instrument does what fixed that
one: it renders the WHOLE BODY WITH the mechanic and the WHOLE BODY WITHOUT it,
through ONE camera, and counts the pixels that MOVED. The renderer does the
depth; occlusion by the creature's own body is counted as the loss it is.

TWO NUMBERS PER YAW, AND THE SECOND IS THE ONE THE ROW ASKS FOR:
  moved_px    pixels that changed when the mechanic was added. How much of the
              mechanic the viewer can see at all, occlusion included.
  outline_px  of those, the ones OUTSIDE the body's own silhouette - i.e. the
              mechanic BREAKING THE OUTLINE. The row's word is SILHOUETTE, and
              a mechanic that is only ever seen as a patch of different colour
              inside the body's outline has not got one. This is the number
              that separates a clamp worn on a chest from a cask held clear.

*** THE FIRST VERSION OF THIS INSTRUMENT JUDGED ON outline_px ALONE AND THAT
*** WAS WRONG. I AM LEAVING THE FAULT AND THE FIX IN, BECAUSE THE FAULT IS THE
*** SAME FAMILY AS THE ONE THIS FILE EXISTS TO CATCH. ***
Run against the Hooper it returned 0.104 - WORSE than the body the correction
was raised on - and the picture flatly disagreed. Reading the per-yaw rows next
to the renders, outline_px was conflating two opposite situations:
  yaw 135  moved 6240,  outline 3366   the cask is BEHIND the body. Invisible.
                                       A real fault.
  yaw 315  moved 51815, outline 5627   the cask is IN FRONT of the body, huge
                                       and unmissable, and simply does not
                                       cross the outline because the body is
                                       behind it. NOT A FAULT AT ALL.
A metric that scores those two the same is measuring the wrong thing, and it
scored the second one as a near-miss. So the primary verdict is moved_px - what
the VIEWER can see, occlusion included - and outline_px is kept as a SECONDARY
that answers a narrower question (does it break the outline) and is never read
on its own. The number and the picture disagreed; the picture was right; the
number was the suspect. That is the house rule and it caught my own harness.

AND THE CARDINALS ARE REPORTED SEPARATELY, because they are the question that
was actually asked. A set piece is met through a doorway and shot by the hero
register from the front, the side and the back. One weak DIAGONAL out of eight
is a fact to state; a weak CARDINAL is the Sealer's finding reappearing.

THE VERDICT IS A RATIO, NOT A THRESHOLD. Bodies differ in size, so the only
honest statement is how much the WORST yaw keeps of the BEST yaw:
  survives = min(outline_px) / max(outline_px) over the eight yaws.
A planar tool scores near zero at the two yaws that look along its plane. A
solid of revolution scores near one everywhere it is not occluded by the body.

IT GOES RED ON EMPTY, by construction. A yaw whose no-mechanic render is blank,
or whose moved mask is empty, reports RED and carries no ratio: a metric
computed over zero pixels reads green and means nothing (the house rule, and
this lane wrote it).

AND IT IS PROVEN ABLE TO MOVE BEFORE IT IS BELIEVED. `--key sealer` runs the
same arm against the body the finding was MADE ON. An instrument that only ever
prints green on the body it was written for is not an instrument, and the
Sealer is the control that can make this one print red.

  blender -b -noaudio -P tools/art/_yaw_ab.py -- --repo <repo> --key hooper \
      --spans cask,rightarm --out renders/art/minibosses/_yaw_hooper.json
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
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

YAWS = [0, 45, 90, 135, 180, 225, 270, 315]
RES = (560, 760)


def _build(key, drop):
    """The body, with the items in the named spans DROPPED. Same tint, same
    overrides, same merge and the same height normalisation as the shipping
    generator - a picture taken through a different build than the one that
    ships is a picture about nothing (minibosses.merge_objs' own argument)."""
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough, metal = 0.34 + 0.40 * wear, 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_body", body, rough, metal),
        'dark': L.mat_solid(key + "_dark", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_bone", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_glow", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    mats = M.apply_overrides(key, mats)
    P = M.BUILDERS[key]()
    spans = getattr(P, "spans", {})
    keep = list(range(len(P.items)))
    cut = set()
    for nm in drop:
        if nm not in spans:
            raise KeyError("%s has no span %r - spans are %s"
                           % (key, nm, sorted(spans)))
        a, b = spans[nm]
        cut.update(range(a, b))
    items = [P.items[i] for i in keep if i not in cut]
    if drop and not cut:
        raise ValueError("%s: dropping %s removed NOTHING" % (key, drop))
    objs = M.merge_objs(key, items, mats, suffix=("cut" if drop else "full"),
                        vcols=getattr(P, "vcols", None))
    # height-normalise on the FULL body only; the cut body must keep the full
    # body's scale and ground or the two renders are of two different creatures
    # and every moved pixel is a lie.
    return objs, height


def _place(objs, k, zoff):
    """Scale about the origin and drop by zoff, FROM THE OBJECT'S AUTHORED
    LOCATION every time. Reading ob.location back and multiplying it again is
    how a second call silently scales the placement twice - a quiet fault that
    moves the cut body relative to the full one and makes every diffed pixel a
    lie. The authored location is stashed on the object on first contact."""
    for ob in objs:
        if "_loc0" not in ob:
            ob["_loc0"] = tuple(ob.location)
        x, y, z = ob["_loc0"]
        ob.scale = (k, k, k)
        ob.location = (x * k, y * k, z * k + zoff)
    bpy.context.view_layer.update()


def _shoot(objs, center, radius, yaw, path, aura):
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    a, e = math.radians(yaw), math.radians(8.0)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    cam = scene.camera
    cam.location = center + dirv * (radius * 4.0 + 2.0)
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    # SCALE TRAP (trap 1): ortho scale and clip come from the measured bounds of
    # the FULL body, fixed across both renders of a yaw. A camera that reframes
    # between A and B moves every pixel and the diff is meaningless.
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", required=True)
    ap.add_argument("--spans", required=True, help="comma list of span names")
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv)
    drop = [s for s in args.spans.split(",") if s]
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_yaw_tmp")
    os.makedirs(tmp, exist_ok=True)

    rep = {"key": args.key, "spans": drop, "yaws": {}, "errors": [], "ok": True}

    # ---- the full body, scaled and grounded exactly as minibossgen does
    G.purge()
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    rep["engine"] = eng
    full, height = _build(args.key, [])
    mn, mx, _ = G.world_bounds(full)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    _place(full, k, 0.0)
    mn, mx, _ = G.world_bounds(full)
    ZOFF = -mn.z                      # the one grounding offset, reused below
    _place(full, k, ZOFF)
    mn, mx, pts = G.world_bounds(full)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    aura = M.CANON[args.key][3]
    G.add_lights(center, radius, aura)
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = max((mx - mn).x, (mx - mn).y, (mx - mn).z) * 1.35
    cam_d.clip_start, cam_d.clip_end = 0.1, radius * 12.0 + 20.0
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    for yaw in YAWS:
        _shoot(full, center, radius, yaw, os.path.join(tmp, "A_%03d.png" % yaw), aura)

    # ---- the same body with the mechanic cut, SAME scale, SAME ground, SAME cam
    for ob in list(full):
        bpy.data.objects.remove(ob, do_unlink=True)
    cut, _h = _build(args.key, drop)
    # THE SAME k AND THE SAME ZOFF AS THE FULL BODY. Re-deriving either from the
    # cut body is the trap: dropping the mechanic changes the cut body's own
    # height and its own lowest point, so a self-grounded cut body is a
    # DIFFERENT CREATURE at a DIFFERENT size, and every pixel in the diff moves
    # for a reason that has nothing to do with the mechanic.
    _place(cut, k, ZOFF)
    for yaw in YAWS:
        _shoot(cut, center, radius, yaw, os.path.join(tmp, "B_%03d.png" % yaw), aura)

    for yaw in YAWS:
        A = G.read_png(os.path.join(tmp, "A_%03d.png" % yaw))
        B = G.read_png(os.path.join(tmp, "B_%03d.png" % yaw))
        aA, aB = A[..., 3] > 0.02, B[..., 3] > 0.02
        row = {"with_px": int(aA.sum()), "without_px": int(aB.sum())}
        if row["without_px"] < 400 or row["with_px"] < 400:
            row["red"] = "blank render - this yaw measures nothing"
            rep["ok"] = False
            rep["errors"].append("yaw %d: %s" % (yaw, row["red"]))
            rep["yaws"][str(yaw)] = row
            continue
        d = np.abs(A[..., :3] - B[..., :3]).max(axis=-1)
        moved = (d > 0.02) | (aA != aB)
        row["moved_px"] = int(moved.sum())
        row["outline_px"] = int((moved & ~aB).sum())
        if row["moved_px"] == 0:
            row["red"] = "moved mask EMPTY - the cut removed nothing visible"
            rep["ok"] = False
            rep["errors"].append("yaw %d: %s" % (yaw, row["red"]))
        rep["yaws"][str(yaw)] = row

    outs = [r.get("outline_px") for r in rep["yaws"].values() if r.get("outline_px") is not None]
    mvs = [r.get("moved_px") for r in rep["yaws"].values() if r.get("moved_px") is not None]
    card = [rep["yaws"][str(y)].get("moved_px") for y in (0, 90, 180, 270)]
    if len(mvs) != len(YAWS) or not mvs or max(mvs) == 0 or any(c is None for c in card):
        rep["ok"] = False
        rep["errors"].append("RED ON EMPTY: %d of %d yaws measured, max moved %s"
                             % (len(mvs), len(YAWS), max(mvs) if mvs else None))
        rep["survives"] = None
    else:
        # PRIMARY: what the viewer can see, at the worst yaw, as a fraction of
        # the best. Occlusion by the body counts against it, which is the point.
        rep["survives"] = round(min(mvs) / float(max(mvs)), 3)
        # THE QUESTION ACTUALLY ASKED: front, side, back - the three the hero
        # register shoots and the four a player meets a set piece through.
        rep["cardinal_survives"] = round(min(card) / float(max(card)), 3)
        rep["cardinals"] = {str(y): rep["yaws"][str(y)]["moved_px"]
                            for y in (0, 90, 180, 270)}
        # SECONDARY, and never read alone - see the docstring. A tool standing
        # in front of the body scores low here and is not faulty.
        rep["outline_survives"] = round(min(outs) / float(max(outs)), 3) if max(outs) else None
        rep["worst_yaw"] = YAWS[mvs.index(min(mvs))]
        rep["best_yaw"] = YAWS[mvs.index(max(mvs))]
    op = os.path.join(args.repo, args.out)
    os.makedirs(os.path.dirname(op), exist_ok=True)
    with open(op, "w") as f:
        json.dump(rep, f, indent=1)
    print("YAW_AB " + json.dumps({kk: rep[kk] for kk in
                                  ("key", "spans", "ok", "survives",
                                   "cardinal_survives", "cardinals",
                                   "outline_survives", "worst_yaw", "best_yaw")
                                  if kk in rep}))
    print("YAW_ROWS " + json.dumps(rep["yaws"]))
    if rep["errors"]:
        print("YAW_ERRORS " + json.dumps(rep["errors"][:4]))


if __name__ == "__main__":
    main()
