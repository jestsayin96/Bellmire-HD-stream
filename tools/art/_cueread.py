#!/usr/bin/env python3
"""CUE READ CENSUS - CAN THE PARTY SEE WHAT THE FIGHT IS ABOUT, FROM EVERY SIDE?

  blender -b -noaudio -P tools/art/_cueread.py -- --repo <repo> --keys k,k

WHY THIS EXISTS. Every miniboss in this file is built around ONE readable
object - four lit vents, five pegs on a rim, a bag that fills a band a stroke,
a lamp on a belt. The register already asserts the CREATURE is visible past the
hero (`seen: 1.0`) and that no view is blank or frame-clipped. NONE of those
numbers asks the only question a viewer actually asks, which is whether the
CUE can be seen. The collier is the proof: it is shut on a live fire, its four
vents are all on the -Y arc by construction, and from behind it is a mound of
earth with a man on it. Every number in its register was green.

THE METHOD IS THE ONE THAT SURVIVED 17 NOV, PASS 11, AND NO OTHER.
`mask_of` renders a group ALONE. That answers how BIG the cue is and reads a
healthy number for a vent parked behind a shovel - it is the same family of
lie as `head_glow_px: 156` beside "the head has no face at all". Measuring the
glow OUTSIDE the body's alpha is the other wrong answer, because a cue that
sits inside the silhouette scores zero for every body ever built.
So: render the body TWICE through the SAME CAMERA - once as it ships, once
with the glow material swapped for the body material (MB_CUEOFF=1, no vertex
moved) - and COUNT THE PIXELS THAT MOVED. Occlusion, depth, the shovel and the
view transform are then the renderer's problem, which is where they belong.

*** IT GOES RED ON EMPTY, AND THAT ARM IS THE POINT. ***
A metric computed over zero pairs reads green and means nothing (System 1, the
centre-band occupancy that could not move). So:
  - a key whose A/B pair is MISSING on any view is RED, never skipped;
  - a key that moves ZERO pixels on ALL THREE views is RED as NO-CUE, because
    that is either a body with no cue at all or an A/B that did not take;
  - a run that compares ZERO pairs is RED, whatever else it found.
A key that moves pixels on some views and none on others is the fault this
instrument was built to find: CUE BLIND on the views that read zero.
"""
import os, sys, json, argparse
import bpy, numpy as np

VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
# 8/255: above PNG round-trip and dither, far below any lit material change.
THRESH = 8.0 / 255.0


def load_rgba(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'   # sRGB bytes round-trip
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return a


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", required=True)
    ap.add_argument("--out", default="_cueread.json")
    # WHICH ARM IS THE CUE-OFF ONE. `_cueC` (both slots) is the honest headline;
    # `_cueB` (glow only) and `_cueD` (bone only) attribute the cue to a slot.
    ap.add_argument("--atag", default="_cueA")
    ap.add_argument("--btag", default="_cueC")
    ap.add_argument("--slot", default="both")
    args = ap.parse_args(argv)

    root = os.path.join(args.repo, "renders", "art", "minibosses")
    rep = {"ok": True, "errors": [], "pairs_compared": 0, "thresh_255": 8,
           "slot": args.slot, "arms": [args.atag, args.btag],
           "method": "A/B through one camera, pixels MOVED; glow->body swap",
           "bodies": {}}

    for key in [k for k in args.keys.split(",") if k.strip()]:
        key = key.strip()
        ent = {"views": {}, "cue_blind_views": [], "verdict": None}
        for v in VIEWS:
            pa = os.path.join(root, key + args.atag, v)
            pb = os.path.join(root, key + args.btag, v)
            if not (os.path.exists(pa) and os.path.exists(pb)):
                ent["views"][v] = {"error": "PAIR MISSING"}
                rep["errors"].append("%s/%s: A/B pair missing" % (key, v))
                rep["ok"] = False
                continue
            A, B = load_rgba(pa), load_rgba(pb)
            if A.shape != B.shape:
                ent["views"][v] = {"error": "SHAPE MISMATCH"}
                rep["errors"].append("%s/%s: shape mismatch" % (key, v))
                rep["ok"] = False
                continue
            opaque = (A[..., 3] > 0.5)
            moved = (np.abs(A[..., :3] - B[..., :3]).max(axis=2) > THRESH) & opaque
            n_moved, n_op = int(moved.sum()), int(opaque.sum())
            ent["views"][v] = {
                "cue_px": n_moved,
                "body_px": n_op,
                "cue_frac": round(n_moved / n_op, 5) if n_op else 0.0,
            }
            rep["pairs_compared"] += 1
            if n_moved == 0:
                ent["cue_blind_views"].append(v)

        # *** A SLOT-SCOPED RUN IS AN ATTRIBUTION, NOT A VERDICT. ***
        # `--slot glow` alone calls pledgeman/blower/stopper RED, and all three
        # are CORRECT bodies whose count is pale geometry, not emissive. A file
        # on disk saying RED is one read away from somebody chasing a fault
        # that is not there, so a slot run says so in its own verdict string.
        _scoped = args.slot != "both"
        got = [d for d in ent["views"].values() if "cue_px" in d]
        tot = sum(d["cue_px"] for d in got)
        if len(got) != len(VIEWS):
            ent["verdict"] = "RED - INCOMPLETE"
        elif tot == 0:
            ent["verdict"] = ("NOT A VERDICT (slot=%s): no %s cue on any view"
                              % (args.slot, args.slot)) if _scoped else \
                             "RED - NO CUE ON ANY VIEW"
            if not _scoped:
                rep["errors"].append("%s: cue moves zero pixels on all three"
                                     " views - no cue, or the A/B did not take" % key)
                rep["ok"] = False
        elif ent["cue_blind_views"]:
            ent["verdict"] = ("NOT A VERDICT (slot=%s): no %s cue from %%s"
                              % (args.slot, args.slot)) % ", ".join(
                                 v.replace("hero_", "").replace(".png", "").upper()
                                 for v in ent["cue_blind_views"]) if _scoped else \
                             "RED - CUE BLIND FROM %s" % ", ".join(
                v.replace("hero_", "").replace(".png", "").upper()
                for v in ent["cue_blind_views"])
            if not _scoped:
                rep["errors"].append("%s: cue invisible from %s" %
                                     (key, ent["cue_blind_views"]))
                rep["ok"] = False
        else:
            ent["verdict"] = ("slot=%s present on all three views" % args.slot) \
                             if _scoped else "GREEN - cue reads on all three views"
        ent["cue_px_total"] = tot
        # THE WEAKEST VIEW IS THE ONE THAT MATTERS, and it is REPORTED, not
        # judged. Zero is a fault anybody can agree on; "41 is too few" is a
        # THRESHOLD, and a threshold picked off ten bodies is chosen and not
        # measured - the backlamp guard's bar was set over all 44 with both
        # arms of a known A/B to separate, and this one has no such calibration
        # yet. So the number goes in the file and the bar waits for the full
        # sweep. Do not add a MIN_CUE_PX constant here off this sample.
        if got:
            ent["weakest_view"] = min(
                ((d["cue_px"], v) for v, d in ent["views"].items() if "cue_px" in d))[::-1]
        rep["bodies"][key] = ent

    # RED ON EMPTY - the arm that stops this reading green over nothing.
    if rep["pairs_compared"] == 0:
        rep["ok"] = False
        rep["errors"].append("RED ON EMPTY: zero A/B pairs compared - this "
                             "instrument measured NOTHING and must not read green")

    weak = sorted((e["weakest_view"][1], k) for k, e in rep["bodies"].items()
                  if "weakest_view" in e)
    rep["weakest_views_ranked"] = [{"key": k, "cue_px": n} for n, k in weak]
    out = os.path.join(root, args.out)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1)
    print("CUEREAD ok=%s pairs=%d errors=%d -> %s"
          % (rep["ok"], rep["pairs_compared"], len(rep["errors"]), out))
    for k, e in rep["bodies"].items():
        print("  %-12s %-46s %s" % (k, e["verdict"],
              {v.replace("hero_", "").replace(".png", ""): d.get("cue_px", "MISSING")
               for v, d in e["views"].items()}))


main()
