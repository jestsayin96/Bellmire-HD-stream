"""_mb_partablate.py - CAN A VIEWER SEE THIS PART ON THIS BODY, FROM THIS ANGLE?

GENERALISED FROM `_ol_eyeablate.py`, 27 Nov 2026. That file asks exactly the
right question and asks it the only honest way, but it is hardcoded to the
overlooker and to its glow mesh, so the fourth body that needed the question
asked would have got a fourth copy of it. This is the same instrument with the
key, the mesh suffix and the contamination guard as arguments. NOTHING ABOUT
THE METHOD IS NEW HERE and nothing about it is weakened.

THE METHOD, restated because it is the lane's hardest-won lesson (pass 11,
17 Nov): DO NOT RENDER THE PART ALONE. `mask_of` answers how BIG a part is and
says nothing about whether it can be SEEN - it will happily report two bright
spheres sitting inside a solid skull. Instead render the body WITH the part and
the same body with that mesh hidden, through ONE camera, and count THE PIXELS
THAT MOVED. The renderer does the occlusion and the number cannot exceed what a
viewer can actually see.

THE THREE GUARDS, ALL CARRIED OVER, ALL LOAD-BEARING:
 1. ABLATION-IS-REAL. If the suffix matches no mesh, or a different number of
    meshes than --expect, the run REFUSES. Ablating nothing scores a tidy 0
    and that zero is indistinguishable from a real finding.
 2. RED ON EMPTY. If either frame of a pair is blank, the pair is refused, not
    scored. A difference over a blank pair is not a measurement.
 3. CONTAMINATION. The scene is TORN DOWN AND REBUILT between the two renders,
    because render_views adds a light rig and a camera every call and a second
    rig changes every lit pixel on the body - that fault once returned "the eye
    pair moves 100.0% of the body", an instrument measuring itself. Any move
    above --guard-pct of the body is REFUSED rather than reported.

WHAT IT CANNOT SEE, SAID PLAINLY:
 - It answers "is this part visible", NOT "is it legible" and not "does it read
   as a face". A part can move 400 px as an ambiguous smudge.
 - It is a VALUE/ALPHA difference. A part that exactly matches what is behind
   it moves few pixels while being geometrically unoccluded.
 - The 160-rung estimate is a scaling of the measured count, not a render at
   that size. It is an estimate and is named one.

  blender -b -noaudio -P tools/art/_mb_partablate.py -- --repo <repo> \
      --key bellman --suffix _glow --expect 1 --tag _bellman_eyes
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossgen as MBG    # noqa: E402

A_EPS = 2.0 / 255.0
D_EPS = 6.0 / 255.0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", required=True)
    ap.add_argument("--suffix", required=True,
                    help="mesh-name suffix to ablate, e.g. _glow")
    ap.add_argument("--expect", type=int, default=1,
                    help="how many meshes that suffix MUST match; mismatch refuses")
    ap.add_argument("--bbox", default="",
                    help="x0,y0,z0,x1,y1,z1 in WORLD space. With this, the "
                         "matched mesh is not hidden whole - only the polygons "
                         "whose centre falls inside the box are deleted. This "
                         "exists because materials are MERGED: `bellman_glow` "
                         "is the eyes AND two bell clappers in one mesh, and "
                         "hiding it whole would answer a question nobody asked.")
    ap.add_argument("--min-polys", type=int, default=1,
                    help="with --bbox, refuse if fewer than this many polygons "
                         "fall in the box - an empty box ablates nothing and "
                         "scores a clean, meaningless 0")
    ap.add_argument("--guard-pct", type=float, default=20.0,
                    help="a move above this %% of the body is refused as contamination")
    ap.add_argument("--views", default="front:0:12,side:90:11,back:180:12")
    ap.add_argument("--res", default="700x980")
    ap.add_argument("--tag", default="")
    args = ap.parse_args(argv)

    VIEWS = tuple((p.split(":")[0], float(p.split(":")[1]), float(p.split(":")[2]))
                  for p in args.views.split(","))
    resx, resy = (int(x) for x in args.res.split("x"))
    outdir = os.path.join(args.repo, "renders", "art", "minibosses",
                          "_partablate" + (args.tag or ""))
    os.makedirs(outdir, exist_ok=True)

    rep = {"ok": True, "errors": [], "views": {}, "key": args.key,
           "suffix": args.suffix, "guard_pct": args.guard_pct,
           "asks": "how many rendered pixels MOVE when this mesh is hidden - "
                   "i.e. how much of it a viewer can actually see",
           "cannot_see": "LEGIBILITY. A visible part is not a readable one, "
                         "and a part the same value as what is behind it moves "
                         "few pixels while being unoccluded."}

    G.purge()
    objs, info = MBG.build_miniboss(args.key)
    hit = [o for o in objs if o.name.endswith(args.suffix)]
    rep["all_objs"] = [o.name for o in objs]
    rep["ablated"] = [o.name for o in hit]
    if len(hit) != args.expect:
        rep["ok"] = False
        rep["errors"].append(
            "REFUSED: suffix %r matched %d meshes, --expect said %d. Ablating "
            "the wrong set (or nothing) scores a tidy number that means "
            "nothing." % (args.suffix, len(hit), args.expect))
        print(json.dumps(rep, indent=1))
        sys.exit(2)

    saved = G.VIEWS
    on = os.path.join(outdir, "on")
    off = os.path.join(outdir, "off")
    os.makedirs(on, exist_ok=True)
    os.makedirs(off, exist_ok=True)
    try:
        G.VIEWS = VIEWS
        G.render_views(objs, args.key, on, resx, resy, info)
        G.purge()                                  # GUARD 3: full teardown
        objs2, info2 = MBG.build_miniboss(args.key)
        hit2 = [o for o in objs2 if o.name.endswith(args.suffix)]
        if len(hit2) != args.expect:
            rep["ok"] = False
            rep["errors"].append("REFUSED: rebuild matched %d meshes, not %d"
                                 % (len(hit2), args.expect))
            print(json.dumps(rep, indent=1))
            sys.exit(2)
        if args.bbox:
            bx = [float(v) for v in args.bbox.split(",")]
            lo = bx[0:3]
            hi = bx[3:6]
            removed = 0
            for o in hit2:
                me = o.data
                mw = o.matrix_world
                doomed = []
                for poly in me.polygons:
                    c = mw @ poly.center
                    if (lo[0] <= c.x <= hi[0] and lo[1] <= c.y <= hi[1]
                            and lo[2] <= c.z <= hi[2]):
                        doomed.append(poly.index)
                if doomed:
                    import bmesh
                    bm = bmesh.new()
                    bm.from_mesh(me)
                    bm.faces.ensure_lookup_table()
                    kill = [bm.faces[i] for i in doomed]
                    bmesh.ops.delete(bm, geom=kill, context="FACES")
                    bm.to_mesh(me)
                    bm.free()
                    removed += len(doomed)
            rep["polys_removed_in_bbox"] = removed
            if removed < args.min_polys:
                rep["ok"] = False
                rep["errors"].append(
                    "REFUSED: the bbox caught %d polygons, --min-polys said at "
                    "least %d. An empty box ablates nothing and the 0 it scores "
                    "looks exactly like a finding." % (removed, args.min_polys))
                print(json.dumps(rep, indent=1))
                sys.exit(2)
        else:
            for o in hit2:
                o.hide_render = True
        G.render_views(objs2, args.key, off, resx, resy, info2)
    finally:
        G.VIEWS = saved

    for vname, _, _ in VIEWS:
        A = G.read_png(os.path.join(on, vname + ".png"))
        B = G.read_png(os.path.join(off, vname + ".png"))
        if not ((A[:, :, 3] > A_EPS).any() and (B[:, :, 3] > A_EPS).any()):
            rep["ok"] = False
            rep["errors"].append("RED %s: one of the ablation pair is BLANK - "
                                 "a difference over a blank pair is refused"
                                 % vname)
            continue
        d = np.abs(A - B).max(axis=2)
        moved = int((d > D_EPS).sum())
        body = int((A[:, :, 3] > A_EPS).sum())
        if moved > (args.guard_pct / 100.0) * body:
            rep["ok"] = False
            rep["errors"].append(
                "RED %s: %d px moved on a %d px body (%.1f%%), over the %.1f%% "
                "guard. The frames differ for a reason other than the "
                "ablation; REFUSED, not scored."
                % (vname, moved, body, 100.0 * moved / max(1, body),
                   args.guard_pct))
        rep["views"][vname] = {
            "moved_px": moved,
            "body_px": body,
            "moved_pct_of_body": round(100.0 * moved / max(1, body), 3),
            "moved_px_at_160_rung_est": round(moved * (160.0 / resx) ** 2, 1),
        }
    print(json.dumps(rep, indent=1))
    with open(os.path.join(outdir, "_partablate.json"), "w") as f:
        json.dump(rep, f, indent=1)
    if not rep["ok"]:
        sys.exit(2)


main()
