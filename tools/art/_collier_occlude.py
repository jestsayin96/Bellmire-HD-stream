#!/usr/bin/env python3
"""_collier_occlude.py - WHERE ON THE COLLIER'S FRONT FLANK IS THERE CLEAR AIR?

  blender -b -noaudio -P tools/art/_collier_occlude.py -- --repo <repo>

WHY THIS EXISTS, AND WHY IT IS NOT A THIRD ARC GUESS. Pass 5 swung the vent
arc out to -78 to clear the shovel and the outermost vent went to a sliver.
Pass 9 pulled it in to -48/-22/+4/+30 and the +4 vent went to ZERO, because
something stands at centre-front. Both passes changed the BEARING and learned
one bearing's worth each time, at a render apiece. The team lead's 07:58 row
says the next single change is THE OCCLUDER OR THE ROW HEIGHT, not the
bearing - and you cannot move an occluder you have not identified.

So this measures the whole front arc at once, without rendering anything:
build the body, throw away the vent span, and BVH-raycast the front camera's
own ray at a grid of sample points across each candidate vent MOUTH. A sample
point whose ray reaches it is clear air; one that is stopped short is occluded,
and the polygon that stopped it is attributed back to the span that owns it, so
the output NAMES the blocker instead of guessing at it.

*** IT ANSWERS THE VIEWER'S QUESTION AND NOT THE OBJECT'S. *** `mask_of`
renders a group alone and reports how BIG a vent is; that is the pass-11 lie of
17 Nov and it reads healthy for a vent parked behind a shovel. Visible mouth
area through the shipping camera is the thing a viewer counts, so that is what
is counted here, foreshortening included: a mouth square-on to the camera
presents cos(0)=1 of itself and one at -78 presents cos(78)=0.21, and the
`proj` column carries that factor explicitly rather than leaving it implicit.

*** REV 1 IS A BUG FIX ON REV 0 AND THE BUG WAS THE PASS-11 FAULT AGAIN. ***
Rev 0 sampled a grid across the mouth's OUTER FACE DISC only. It therefore read
`vis 0.000` for the shipped +24 vent, which the committed glow-only render
shows as a 135 px mark - the fourth-biggest thing on the front. Both were
right about different things: the disc at +24 IS buried in the earth, and the
CONE'S FLANK still stands out of it and is lit. Measuring one chosen surface of
a cue and calling it the cue is `head_glow_px: 156` beside "the head has no
face at all", so rev 1 samples THE REAL MOUTH SOLID - the face centroids of the
same `scone` the builder adds, transformed to the bearing under test - and
nothing else changed. An instrument that disagrees with a render I already hold
is the suspect, not the render; this one was.

*** IT IS NOT A PASS AND THERE IS NO THRESHOLD IN IT. *** Same ruling as
_streamscale.py (05:58, 25 Nov): no lane invents a MIN_CUE_PX. This prints a
visible fraction per bearing and the name of whatever blocks the rest. ZERO is
the only reading that is a verdict on its own. Everything else goes beside a
picture somebody looked at.

*** IT GOES RED ON EMPTY. *** A run that cast no rays, or one where every
bearing at every height reads fully clear, is RED - the first compared nothing
and the second means the vent span was not actually removed from the BVH, so
the probe is measuring a body with no occluders in it at all.
"""
import os, sys, json, math, argparse

import bpy  # noqa: F401  (imported for its side effects / mathutils parity)
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import minibosses as M       # noqa: E402

# The visible projected area of a mouth at bearing 0 with NOTHING in front of
# it. `proj` is reported as a share of this, so 1.00 means "as much of this
# mouth as the camera could ever see" and 0.00 means gone.
MOUTH_REF = 0.0

# The shipping front camera, measured off minibossfit/_beadle_ab: ORTHO,
# azimuth 0, elevation 12. An ortho camera has ONE ray direction for the whole
# frame, which is why a per-bearing probe is meaningful at all.
# ELEVATION IS 6.0, NOT 12.0, AND REV 0 HAD IT WRONG. `hero_front.png` is
# written by minibossfit.shoot, which hard-codes `math.radians(6.0)`; the 12.0
# in lordgen.VIEWS and _beadle_ab belongs to the SOLO contact sheets, which are
# not the renders any number in this pass is taken off.
FRONT_AZ, FRONT_EL = 0.0, 6.0
MOUTH_R = 0.074          # scone(0.088, 0.074, 0.082): the OUTER face radius
MOUTH_OUT = 0.041        # half the mouth's height, so we sample its outer face
VENT_R = 0.760           # mouth centre radius, from the builder
BACKOFF = 12.0           # ray start, well outside the body's own extent


def _args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", default="_collier_occlude.json")
    ap.add_argument("--step", type=float, default=2.0)
    ap.add_argument("--lo", type=float, default=-88.0)
    ap.add_argument("--hi", type=float, default=88.0)
    return ap.parse_args(a)


def ray_dir():
    a, e = math.radians(FRONT_AZ), math.radians(FRONT_EL)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                math.sin(e))).normalized()
    return -d            # camera sits along +d from the body and looks back


def mouth_samples(deg, z):
    """THE REAL MOUTH SOLID, not a disc across its end.

    Builds the SAME `scone(0.088, 0.074, 0.082, 12)` the builder adds for a
    vent mouth, transformed to the bearing and height under test, and returns
    one sample per face centroid pushed a hair along its own normal. The cone's
    FLANK is therefore sampled as well as its end, which is the whole of rev
    1's bug fix: at +24 the end disc is inside the earth and the flank is not.

    A face whose normal points away from the camera is dropped - a back face
    cannot be seen whether it is occluded or not, and counting it would dilute
    every reading with geometry no viewer could ever see.
    """
    a = math.radians(deg)
    d = Vector((math.sin(a), -math.cos(a), 0.0))
    loc = tuple(d * VENT_R + Vector((0.0, -0.040, z)))
    vs, fs = L.scone(0.088, 0.074, 0.082, 12)
    vs = L.xform(vs, loc, (math.pi * 0.5, 0.0, a), (1, 1, 1))
    rd = ray_dir()
    pts, area = [], 0.0
    for f in fs:
        if len(f) < 3:
            continue
        ps = [Vector(vs[i]) for i in f]
        c = sum(ps, Vector((0.0, 0.0, 0.0))) / float(len(ps))
        n = (ps[1] - ps[0]).cross(ps[2] - ps[0])
        if n.length < 1e-12:
            continue
        n.normalize()
        # faces are wound outward; a face facing the camera has n . rd < 0
        facing = -n.dot(rd)
        if facing <= 0.02:
            continue
        # projected area of this face, so `proj` is a real projected-area share
        ar = 0.0
        for i in range(1, len(ps) - 1):
            ar += (ps[i] - ps[0]).cross(ps[i + 1] - ps[0]).length * 0.5
        pts.append((c + n * 1e-4, ar * facing))
        area += ar * facing
    return pts, area


def main():
    ns = _args()
    rep = {"body": "collier", "camera": {"az": FRONT_AZ, "el": FRONT_EL,
                                         "type": "ORTHO"},
           "method": "BVH raycast of the front camera ray at a grid across each "
                     "candidate vent mouth's outer face; the vent span is "
                     "REMOVED from the BVH so a mouth never occludes itself. "
                     "`proj` = visible fraction * cos(bearing), the share of a "
                     "square-on mouth this bearing presents to the camera.",
           "not_a_pass": "no threshold here and there must not be one (05:58 "
                         "ruling, 25 Nov). ZERO is the only reading that is a "
                         "verdict on its own.",
           "errors": [], "rows": {}}

    global MOUTH_REF
    _, MOUTH_REF = mouth_samples(0.0, 0.298)
    rep["mouth_ref_m2"] = round(MOUTH_REF, 6)

    P = M.collier()
    spans = getattr(P, "spans", {})
    if "vents" not in spans:
        rep["errors"].append("collier declares no `vents` span - cannot remove "
                             "the vent geometry from the BVH, so every reading "
                             "would be a mouth occluding itself. RED.")
        _dump(ns, rep)
        return
    v0, v1 = spans["vents"]
    rep["vent_span"] = [v0, v1]

    # Which span owns each item, so a blocker can be NAMED and not guessed at.
    owner = {}
    for name, (s, e) in spans.items():
        for i in range(s, e):
            owner[i] = name

    verts, polys, face_owner = [], [], []
    for i, (vs, fs, _slot) in enumerate(P.items):
        if v0 <= i < v1:
            continue                      # the vents themselves
        off = len(verts)
        verts.extend([Vector(v) for v in vs])
        who = owner.get(i, "unassigned_item_%d" % i)
        for f in fs:
            polys.append(tuple(idx + off for idx in f))
            face_owner.append(who)
    if not polys:
        rep["errors"].append("BVH has zero polygons after removing the vent "
                             "span - nothing to occlude against. RED.")
        _dump(ns, rep)
        return
    rep["bvh"] = {"verts": len(verts), "polys": len(polys),
                  "spans_present": sorted(set(face_owner))}

    tree = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    rd = ray_dir()
    rep["ray_dir"] = [round(c, 5) for c in rd]

    # The row heights: the two the body ships (0.250 and 0.298) plus the band
    # above and below them, so the ROW HEIGHT option is measured rather than
    # argued. Shipped values are flagged so nobody reads a probe row as a ship.
    heights = [float(x) for x in os.environ.get(
        "OCCL_Z", "0.190,0.220,0.250,0.280,0.298,0.330,0.360").split(",")]
    shipped = {0.250, 0.298}
    casts = 0
    deg = ns.lo
    degs = []
    while deg <= ns.hi + 1e-9:
        degs.append(round(deg, 2))
        deg += ns.step

    for z in heights:
        row = []
        for dg in degs:
            pts, area = mouth_samples(dg, z)
            vis_a, blockers = 0.0, {}
            for p, pa in pts:
                origin = p - rd * BACKOFF
                hit = tree.ray_cast(origin, rd, BACKOFF * 2.0)
                casts += 1
                if hit[0] is None or hit[3] >= BACKOFF - 1e-3:
                    vis_a += pa
                else:
                    who = face_owner[hit[2]] if hit[2] is not None else "?"
                    blockers[who] = round(blockers.get(who, 0.0) + pa, 5)
            frac = (vis_a / area) if area > 1e-12 else 0.0
            row.append({
                "deg": dg,
                "vis_frac": round(frac, 3),
                # `proj` is the VISIBLE PROJECTED AREA in m^2 of the mouth
                # solid's camera-facing faces. Foreshortening is already in it
                # (each face is weighted by -n.rd), so there is no cos() factor
                # applied on top - rev 0 applied one to a disc and double
                # counted the obliquity it had already built in.
                "proj_m2": round(vis_a, 6),
                "proj": round(vis_a / MOUTH_REF, 3) if MOUTH_REF else 0.0,
                "faces": len(pts),
                "blocked_by": dict(sorted(blockers.items(),
                                          key=lambda kv: -kv[1])),
            })
        rep["rows"]["z=%.3f%s" % (z, " SHIPPED" if z in shipped else "")] = row

    # ================= THE VALIDATION ARM. THIS IS NOT OPTIONAL. =============
    # An occlusion probe is a NUMBER, and this body's whole history is numbers
    # that disagreed with pictures. So before any bearing out of this file is
    # allowed to pick a fix, it is checked against a render that already
    # exists: `collier_stream/_vent_marks.json`, the labelled glow-only A/B of
    # the SHIPPED arc. The mark-to-bearing mapping is not a guess - at
    # CELL_X/FRAME_W = 135.71 px/m the four marks' measured gaps (29.9, 53.4,
    # 59.1 px) match the four bearings' world-x gaps (31.9, 51.1, 59.9 px), and
    # screen x rises with world x, so cx 409/439/492/551 are -78/-42/-10/+24
    # left to right.
    # THE TEST IS RANK ORDER, NOT MAGNITUDE. A ray probe counts mouth area and
    # a render counts lit pixels through a view transform with bloom in it;
    # those are different units and demanding agreement in value would be
    # false precision. But if the probe cannot even AGREE WHICH VENT IS THE
    # SMALL ONE, it is not fit to choose a bearing, and it says so here rather
    # than being quietly believed.
    # IT GOES RED WHEN IT CANNOT CHECK ITSELF, TOO: no marks file, or a marks
    # file with the wrong number of front marks, is RED, not skipped.
    SHIP = ((-78.0, 0.250), (-42.0, 0.298), (-10.0, 0.298), (24.0, 0.250))
    mk = os.path.join(ns.repo, "renders", "art", "minibosses",
                      "collier_stream", "_vent_marks.json")
    val = {"marks_file": mk, "mapping": "cx 409/439/492/551 = -78/-42/-10/+24, "
           "proved by gap arithmetic at 135.71 px/m"}
    try:
        front = json.load(open(mk))["hero_front.png"]["full"]["sizes_px"]
    except Exception as exc:                       # noqa: BLE001
        front = None
        val["error"] = "cannot read %s: %s" % (mk, exc)
        rep["errors"].append("validation arm could not read the marks file - a "
                             "probe that cannot check itself against a render "
                             "is RED, not green. %s" % exc)
    if front is not None:
        # the four VENT marks are the four largest ON-ROW marks, which for the
        # shipped front row are sizes_px[0:4] re-ordered to bearing order by
        # the centroid mapping above: 38(-78), 460(-42), 449(-10), 135(+24)
        if len(front) < 4:
            rep["errors"].append("marks file front row has %d marks, fewer than "
                                 "the four vents this body ships - cannot "
                                 "validate. RED." % len(front))
        else:
            rend = [front[3], front[0], front[1], front[2]]
            probe = []
            for dg, z in SHIP:
                key = "z=%.3f SHIPPED" % z
                cell = next(c for c in rep["rows"][key]
                            if abs(c["deg"] - dg) < 1e-6)
                probe.append(cell["proj_m2"])
            val["bearings"] = [d for d, _ in SHIP]
            val["render_mark_px"] = rend
            val["probe_proj_m2"] = probe
            r_small = rend.index(min(rend))
            p_small = probe.index(min(probe))
            val["render_smallest_bearing"] = SHIP[r_small][0]
            val["probe_smallest_bearing"] = SHIP[p_small][0]
            val["agrees_on_smallest"] = (r_small == p_small)
            # Spearman-free rank check: same ordering of all four
            rr = sorted(range(4), key=lambda i: rend[i])
            pp = sorted(range(4), key=lambda i: probe[i])
            val["render_rank"] = [SHIP[i][0] for i in rr]
            val["probe_rank"] = [SHIP[i][0] for i in pp]
            val["rank_identical"] = (rr == pp)
            if not val["agrees_on_smallest"]:
                rep["errors"].append(
                    "VALIDATION FAILED: the render says the smallest vent is "
                    "%+.0f and this probe says %+.0f. The render is the "
                    "evidence and this probe is the suspect - do not pick a "
                    "bearing out of it until it agrees."
                    % (SHIP[r_small][0], SHIP[p_small][0]))
    rep["validation"] = val

    rep["casts"] = casts
    if casts == 0:
        rep["errors"].append("zero rays cast - a run over nothing is RED")
    else:
        allclear = all(c["vis_frac"] >= 0.999
                       for row in rep["rows"].values() for c in row)
        if allclear:
            rep["errors"].append(
                "every bearing at every height reads fully clear - the vent "
                "span was almost certainly NOT removed from the BVH, or the "
                "ray direction is wrong. A probe that cannot find the shovel "
                "is not measuring this body. RED.")
    rep["ok"] = not rep["errors"]
    _dump(ns, rep)


def _dump(ns, rep):
    rep.setdefault("ok", not rep.get("errors"))
    out = os.path.join(ns.repo, "renders", "art", "minibosses",
                       "collier_stream", ns.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(rep, open(out, "w"), indent=1)
    print("WROTE %s ok=%s errors=%s" % (out, rep["ok"], rep["errors"]))


main()
