"""_ol_back.py - THE BACK VIEW OF THE OVERLOOKER, WHICH NOBODY HAD EVER SHOT.

The team lead's 16:58 row, 25 Nov: "Render the back at the same 160 px rung, in
colour and as pure silhouette, look at it, and say in your own words whether the
facing reads." Pass 3 and pass 4 both flagged this against themselves - the
driver shoots front, three_quarter and side, and the one view that tests a body
whose entire mechanic is A TURNED HEAD is the one view that was never taken.
That is the Beadle fault (a figure that reads the same front and back has no
facing) on the body built to answer it.

WHY THIS IS NOT "just add 180 to lordgen.VIEWS AND RERUN". Two reasons:

  1. lordgen.VIEWS is shared by the lords, the twelve creatures and all 63
     minibosses. Adding a view there re-renders and re-reports 63 bodies to
     answer one question about one of them. So VIEWS is patched FOR THIS
     PROCESS ONLY and nothing on disk changes for any other key.
  2. A back.png rendered in a different invocation from the front.png it is
     compared against is not a comparison - ortho scale, the lamp rig and the
     clip range are all derived per run from measured bounds. FRONT, SIDE AND
     BACK ARE SHOT IN ONE PASS HERE, through one camera rig, so a difference
     between two panels is a difference in the BODY.

WHAT THIS HARNESS CANNOT SEE, SAID BEFORE IT IS TRUSTED:
  - The lamp rig is FRONT-BIASED by construction (lordgen.add_lights: key SUN
    at (0.9,-1.0,0.85), i.e. in front; the only lamp behind the body is the
    aura-coloured rim). The back view WILL be darker and cooler than the front
    and that is the rig, not the model. So the facing verdict is taken off the
    SILHOUETTE row, where alpha is lighting-independent, and the colour row is
    read only for what the shading adds.
  - Alpha coverage says a thing is THERE, never that it is DISTINGUISHABLE.
    The pass-11 lesson from 17 Nov: mask_of answers how big, not whether seen.
    So the facing is judged by asking whether front and back silhouettes DIFFER
    at the rung - a number over one picture is a suspect, a difference between
    two pictures through one camera is evidence.

  blender -b -noaudio -P tools/art/_ol_back.py -- --repo <repo>
"""
import os
import sys
import math
import argparse
import json

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossgen as MBG    # noqa: E402

KEY = "overlooker"
# front and back at the SAME elevation so the pair is a mirror of one question
# and not two different cameras; side carried at its shipped 11.0 for context.
MY_VIEWS = (("front", 0.0, 12.0), ("side", 90.0, 11.0), ("back", 180.0, 12.0))
A_EPS = 2.0 / 255.0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x980")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))

    out = {"ok": True, "errors": [], "views": {}}
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_ol_back4")
    os.makedirs(outdir, exist_ok=True)

    G.purge()
    objs, info = MBG.build_miniboss(KEY)
    mn, mx, _ = G.world_bounds(objs)
    out["bounds"] = dict(size=[round(mx.x - mn.x, 3), round(mx.y - mn.y, 3),
                               round(mx.z - mn.z, 3)],
                         parts=len(objs),
                         faces=sum(len(o.data.polygons) for o in objs))

    # PATCH FOR THIS PROCESS ONLY - see the header. Restored in a finally so an
    # exception here can never leave a mutated VIEWS behind for an import that
    # follows in the same interpreter.
    saved = G.VIEWS
    try:
        G.VIEWS = MY_VIEWS
        written, eng, cam = G.render_views(objs, KEY, outdir, resx, resy, info)
    finally:
        G.VIEWS = saved
    out["engine"], out["cam"] = eng, cam

    # BLANK AND BORDER, per view, read back off the written bytes.
    for p in written:
        v = os.path.splitext(os.path.basename(p))[0]
        A = G.read_png(p)
        al = A[:, :, 3]
        rec = {"file": os.path.basename(p), "res": [int(al.shape[1]), int(al.shape[0])]}
        if not (al > A_EPS).any():
            out["ok"] = False
            out["errors"].append("RED %s: frame is BLANK" % v)
            out["views"][v] = rec
            continue
        edge = float(max(al[0, :].max(), al[-1, :].max(),
                         al[:, 0].max(), al[:, -1].max()))
        rec["border_alpha"] = round(edge, 4)
        if edge > A_EPS:
            out["ok"] = False
            out["errors"].append("RED %s: body touches the frame border (a=%.3f)"
                                 % (v, edge))
        ys, xs = np.where(al > A_EPS)
        rec["opaque_px"] = int((al > A_EPS).sum())
        rec["bbox_px"] = [int(xs.min()), int(ys.min()),
                          int(xs.max() + 1), int(ys.max() + 1)]
        rec["wh"] = [rec["bbox_px"][2] - rec["bbox_px"][0],
                     rec["bbox_px"][3] - rec["bbox_px"][1]]
        out["views"][v] = rec

    # back.png also goes into the register's own view dir, so the body the game
    # build loads carries the proof beside its other three views rather than in
    # a side folder only this harness knows about.
    src = os.path.join(outdir, "back.png")
    dst = os.path.join(args.repo, "renders", "art", "minibosses", KEY, "back.png")
    if os.path.isfile(src):
        with open(src, "rb") as f:
            b = f.read()
        with open(dst, "wb") as f:
            f.write(b)
        out["copied_to"] = os.path.relpath(dst, args.repo)

    rp = os.path.join(outdir, "_back_report.json")
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(out, indent=1))
    print("[ol_back] %s" % ("OK" if out["ok"] else "RED"))
    if not out["ok"]:
        sys.exit(2)


main()
