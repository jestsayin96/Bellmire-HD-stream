# D94 GLOVES PASS 7 - HOW THICK IS THE ARM, REALLY, AND WHERE IS THE TORSO.
# The _g7_probe numbers say the failing pair is NOT both buried in the torso:
# bellrope_wraps' cuff is 5.2% in the torso and 86.4% in the ARM MESH. So the
# question that decides the fix is: what is the arm's own radius along the
# forearm, in the POSED body, and what clearance is there inboard before the
# torso? If the cuff radius is below the arm radius the glove is INSIDE THE
# ARM and no amount of leaning outboard will show it.
#
# MEASURED, not scanned loosely: rays are cast FROM THE BONE AXIS, in the
# plane perpendicular to the posed forearm direction, 16 ways round, at eight
# stations between the hand and the elbow. The arm meshes and the torso
# meshes are separate trees so an inboard ray reports both numbers.
# Rest-space geometry is what acc_gloves authors in, so the rest anchors are
# printed beside the posed ones - handlen is derived from the REST pair, and a
# wrong handlen is the one number every glove dial is built on.
import os, sys, json, math
import bpy
from mathutils import Vector
REPO = r"C:\hd adventure\bellmire-art"
sys.path.append(os.path.join(REPO, "tools", "art"))
import lordgen as G, e3pogen as EG, showcasegen as SG, showcase as SC, icons as IC
import d94proof as P

BODY = P.BODY
bodydir = os.path.join(REPO, "assets", "characters", "kaykit_adv2")
G.purge()
EG.setup_scene(120, 170, transparent=True)
arm, meshes = EG.import_knight(os.path.join(bodydir, BODY + ".glb"), "g7arm")
for ob in list(meshes):                    # same outfit the proof row uses
    if any(ob.name.split('.')[0].endswith(x) for x in
           ("_Helmet", "_HelmetVisor", "_Hat", "_BearHat", "_Cape")):
        bpy.data.objects.remove(ob, do_unlink=True)
        meshes.remove(ob)
rest = EG.rest_anchors(arm)
EG.pose_at_post(arm)
bpy.context.view_layer.update()
posed = {}
for bn in ("hand.l", "hand.r", "wrist.l", "wrist.r", "lowerarm.l", "lowerarm.r",
           "upperarm.l", "chest", "spine"):
    pb = arm.pose.bones.get(bn)
    if pb is not None:
        posed[bn] = [round(c, 4) for c in (arm.matrix_world @ pb.head)]

armo = [o for o in meshes if "Arm" in o.name]
tors = [o for o in meshes if any(w in o.name for w in ("_Body", "_Head", "_Leg"))]
t_arm, t_tor = SG.bvh_for(armo), SG.bvh_for(tors)

def ray(trees, o, d, maxd=1.2):
    """NEAREST hit, and that correction is the whole point of this pass.
    showcasegen.ray_out takes the OUTERMOST hit, which is right when the ray
    starts on the spine and must find the outside of the torso. Here the ray
    starts INSIDE THE ARM, so outermost-across-trees returned the OTHER arm
    half a metre away: the first run of this probe reported an arm radius of
    0.50-0.58 m and a torso 0.70 m inboard, on a body 1.3 m wide. Those are
    not arm radii, they are the far wall. Nearest hit is the wall I want."""
    best = None
    for t in trees:
        loc, nor, idx, dist = t.ray_cast(o, Vector(d).normalized(), maxd)
        if loc is not None and (best is None or dist < best):
            best = dist
    return best

out = {"rest_anchors": {k: [round(c, 4) for c in v] for k, v in rest.items()
                        if k in ("hand.l", "hand.r", "wrist.l", "wrist.r",
                                 "lowerarm.l", "lowerarm.r", "upperarm.l")},
       "posed_anchors": posed, "arm_meshes": sorted(o.name for o in armo),
       "torso_meshes": sorted(o.name for o in tors), "sides": {}}
# THE NUMBER EVERY GLOVE DIAL IS BUILT ON, derived the way acc_gloves derives it
rhl, rw, rlo = rest["hand.l"], rest["wrist.l"], rest.get("lowerarm.l", rest["wrist.l"])
out["derived_rest"] = {
    "handlen_acc_gloves": round(max(0.12, abs(rhl.x - rw.x) * 2.0), 4),
    "handlen_raw_x2": round(abs(rhl.x - rw.x) * 2.0, 4),
    "forearm": round(max(0.12, abs(rw.x - rlo.x)), 4),
    "ar_forearm_radius_used": round(max(0.12, abs(rhl.x - rw.x) * 2.0) * 0.38, 4),
    "fist_used": round(max(0.12, abs(rhl.x - rw.x) * 2.0), 4)}

for side in ("l", "r"):
    h = Vector(posed["hand." + side])
    w = Vector(posed["wrist." + side])
    e = Vector(posed["lowerarm." + side])
    ax = (e - w)
    if ax.length < 1e-6:
        continue
    ax.normalize()                          # wrist -> elbow, up the forearm
    # two axes across the forearm: one toward the body (inboard) and one across
    up = Vector((0.0, 0.0, 1.0))
    r1 = ax.cross(Vector((0.0, 1.0, 0.0)))
    if r1.length < 1e-6:
        r1 = ax.cross(up)
    r1.normalize()
    r2 = ax.cross(r1).normalized()
    # inboard = toward the spine in x
    inb = Vector((-1.0 if h.x > 0 else 1.0, 0.0, 0.0))
    stations = []
    for k in range(8):
        t = k / 7.0
        o = w + (e - w) * t
        ring = []
        for j in range(16):
            th = 2.0 * math.pi * j / 16.0
            d = (r1 * math.cos(th) + r2 * math.sin(th)).normalized()
            da = ray(t_arm, o, d, 0.8)
            ring.append(None if da is None else round(da, 4))
        got = [v for v in ring if v is not None]
        stations.append({"t": round(t, 3), "z": round(o.z, 4), "x": round(o.x, 4),
                         "arm_r_min": (round(min(got), 4) if got else None),
                         "arm_r_max": (round(max(got), 4) if got else None),
                         "arm_r_mean": (round(sum(got) / len(got), 4) if got else None),
                         "ring": ring,
                         "torso_inboard_m": (lambda v: round(v, 4) if v is not None else None)(
                             ray(t_tor, o, inb, 1.2)),
                         "arm_inboard_m": (lambda v: round(v, 4) if v is not None else None)(
                             ray(t_arm, o, inb, 0.8)),
                         "arm_outboard_m": (lambda v: round(v, 4) if v is not None else None)(
                             ray(t_arm, o, -inb, 0.8)),
                         "torso_gap_m": (lambda a, b: (round(b - a, 4)
                                                       if (a is not None and b is not None) else None))(
                             ray(t_arm, o, inb, 0.8), ray(t_tor, o, inb, 1.2))})
    out["sides"][side] = {"axis_wrist_to_elbow": [round(c, 4) for c in ax],
                          "inboard": [round(c, 4) for c in inb],
                          "stations": stations}
# THE HAND ITSELF. _g7_probe says every one of the six gloves has a hand shell
# 100% inside the body mesh - not one vertex of any shell is visible - so the
# fist number the generator builds from is measured here the same way.
hands = {}
for side in ("l", "r"):
    h = Vector(posed["hand." + side])
    w = Vector(posed["wrist." + side])
    ds = []
    for j in range(26):
        a = 2.0 * math.pi * (j % 13) / 13.0
        b = (-0.6 + 1.2 * (j // 13))
        d = Vector((math.cos(a) * math.cos(b), math.sin(a) * math.cos(b), math.sin(b)))
        v = ray(t_arm, h, d, 0.8)
        if v is not None:
            ds.append(round(v, 4))
    hands[side] = {"n": len(ds), "min": (min(ds) if ds else None),
                   "mean": (round(sum(ds) / len(ds), 4) if ds else None),
                   "max": (max(ds) if ds else None),
                   "hand_to_wrist_posed": round((h - w).length, 4)}
    # and how far the hand surface reaches along the arm axis past hand.<side>
out["hand_radius"] = hands

p = os.path.join(REPO, "renders", "art", "_g7_arm.json")
open(p, "w").write(json.dumps(out, indent=1))
print("G7ARM_DONE", p)
