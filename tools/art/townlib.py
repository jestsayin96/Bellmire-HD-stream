"""townlib - the town harness helpers, shared by the tier-ladder generators.

WHY THIS FILE EXISTS AND WHAT IT DELIBERATELY DOES NOT DO
---------------------------------------------------------
`townbuildgen.py` (the well ladder) carries these helpers inline and it is
GREEN and shipped. The Hall ladder needs the same gates, so the honest choices
were (a) import them out of `townbuildgen`, which is impossible because that
module calls `main()` at import time, (b) refactor `townbuildgen` to import
from here, or (c) lift them into a sibling and leave the green harness alone.

**(c), deliberately.** A refactor of a shipped green harness to save ~120 lines
of duplication is a risk with no render behind it, on a two-week deadline. The
duplication is stated here so the next seat knows both copies exist and that
`townbuildgen.py` is the ORIGINAL - if these two ever disagree, that one is
right and this one is the suspect.

THE GATES AND WHAT EACH CANNOT SEE - carried over verbatim in intent:
  1. BLANK        - opaque pixels > 0. Cannot see a CLIPPED subject.
  2. BORDER       - zero alpha on the 1-px frame. Cannot see a subject that is
                    merely small.
  3. SUBJECT SEEN - render with and without, count the pixels that MOVED. This
                    is the one that catches an empty frame carrying a PASS, the
                    way the tier-5 spear's side-on gate did on 27 Nov. RED ON
                    EMPTY: below the floor is RED, because a metric over zero
                    pixels reads green and means nothing.
  4. HERO SEEN    - the same difference for the body, measured SEPARATELY. A
                    sheet whose scale reference failed to render is worse than
                    one with no reference, because the eye trusts it.
  5. SIZE         - the committed .glb's bytes. New this ladder: every gate the
                    texture run had went GREEN over a 28.1 MB `lm_hall`, so
                    "is this sane to commit" was a question nothing asked.
NONE OF THEM CAN SAY THE PROGRESSION READS. Only looking says that.
"""
import math, os

import bpy, numpy as np
from mathutils import Vector

import lordgen as G
import lordlib as L

W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures",
                    "Characters", "gltf", "Knight.glb")
VIEWS = (("front", 0.0, 10.0), ("three_quarter", 38.0, 14.0),
         ("side", 90.0, 10.0), ("back", 180.0, 10.0))

# *** THE 16 MESHES IN Knight.glb ARE NOT ONE BODY. *** Eight are the figure;
# the rest are loose equipment variants (swords, four shields, an Icosphere
# spanning z -1.0..+1.0) stacked in the same file. Keeping them made the first
# well sheet frame a sword hanging in the air and squeezed the three wells to
# 15% of frame width - and `hero_moved_px` read 20-37k and PASSED, ON THE WRONG
# OBJECT. A with/without difference proves something moved, never that it was
# the thing you named. WHITELIST BY EXACT NAME, NEVER BY SUBSTRING.
BODY = {"Knight_Body", "Knight_Head", "Knight_Helmet", "Knight_ArmLeft",
        "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight", "Knight_Cape"}
HERO_STANDS = 2.453      # helmet top, measured; the figure, not the AABB


def add_hero(dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=HERO)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    arm = next((o for o in new if o.type == 'ARMATURE'), None)
    if arm is not None and "Idle" in bpy.data.actions:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)
    keep = []
    for o in meshes:
        if o.name.split(".")[0] in BODY:
            keep.append(o)
        else:
            o.hide_render = True
    if not keep:
        keep = meshes
    # Move the ARMATURE only - the meshes are parented to it, so moving both
    # displaced every child twice, which was the other half of the bad sheet.
    for o in [o for o in new if o.parent is None]:
        o.location = (o.location.x + dx, o.location.y, o.location.z)
    bpy.context.view_layer.update()
    return keep, list(new)


def ground_plane(sx, sy, cx=0.0, mat=None):
    if mat is None:
        mat = L.mat_solid("gnd", (0.21, 0.20, 0.18), 0.95, 0.0)
    v, f = L.box(sx, sy, 0.12)
    ob = L.make("ground", v, f, mat)
    ob.location = (cx, 0.0, -0.06)
    return ob


def alpha_px(p):
    return int((G.read_png(p)[..., 3] > 0.03).sum())


def moved_px(p1, p2):
    a, b = G.read_png(p1), G.read_png(p2)
    return int((np.abs(a - b).max(axis=2) > 0.02).sum())


def moved_box(p1, p2):
    """The moved pixels AND the box they occupy.

    A bare moved-pixel count is not scale-aware, and the Hall ladder is where
    that bit: against a 22.4 m tier-3 hall the 2.453 m hero moves only ~650 px
    at 900x820 and the old floor of 1500 called it ABSENT. It is not absent -
    it is correctly tiny, because the building really is nine times its height.
    The question a scale reference has to answer is "can the eye read it", and
    that is a HEIGHT in pixels, not an area. So both are reported and the gate
    asks for a legible height as well as a non-trivial area."""
    a, b = G.read_png(p1), G.read_png(p2)
    m = np.abs(a - b).max(axis=2) > 0.02
    n = int(m.sum())
    if n == 0:
        return {"px": 0, "h_px": 0, "w_px": 0}
    ys, xs = np.where(m)
    return {"px": n, "h_px": int(ys.max() - ys.min() + 1),
            "w_px": int(xs.max() - xs.min() + 1)}


def border_px(p):
    a = G.read_png(p)
    e = np.concatenate([a[0, :, 3], a[-1, :, 3], a[:, 0, 3], a[:, -1, 3]])
    return int((e > 0.03).sum())


def aim_cam(cam, cam_d, pts, center, radius, az, el, resx, resy, pad=1.08):
    """Frame from the MEASURED point cloud. TRAP 1: clip_start/clip_end come
    off the measured depth span, never off defaults - a default clip_end of 100
    renders an empty transparent image AND REPORTS SUCCESS."""
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                math.sin(e))).normalized()
    cam.location = center + d * (radius * 4.0 + 2.0)
    cam.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    m3 = cam.matrix_world.to_3x3()
    right = (m3 @ Vector((1, 0, 0))).normalized()
    up = (m3 @ Vector((0, 1, 0))).normalized()
    fwd = (m3 @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    cam_d.ortho_scale = max(wide, tall * (resx / float(resy))) * pad
    dep = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(dep) - radius * 0.5)
    cam_d.clip_end = max(dep) + radius * 2.0 + 5.0


def scene_setup(resx, resy):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.055, 0.06, 0.075, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    return scene, eng


def new_ortho_cam(scene):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    return cam, cam_d


def solidity(path):
    """SEE-THROUGH TEST: transparent pixels INSIDE the subject's own silhouette.

    Added 28 Nov 02:5x CT after looking at the first Hall tier-1 render, which
    every existing gate passed and which YOU COULD SEE STRAIGHT THROUGH. The
    design doc had picked `Wall_Plaster_WoodGrid` off its NAME ("timber-framed")
    and the module is an OPEN TIMBER LATTICE. Blank, border, subject-moved and
    hero-seen are all blind to it: a lattice is not blank, not clipped, not
    missing and not small - it is just not a wall.

    Scanline fill: for each row, count transparent pixels strictly between the
    leftmost and rightmost opaque pixel. Doors and windows count too, so this
    is a COMPARATIVE number, not a pass mark - the honest use is before/after
    on the same subject and camera.

    WHAT IT CANNOT SEE: a wall that is solid but the WRONG material; a hole in
    the roof that no scanline crosses between two opaque pixels (an opening at
    the very silhouette edge reads as background, not as a hole); and anything
    about colour. RED ON EMPTY: a silhouette under 1000 px returns -1 rather
    than a comfortable zero, because a metric over no subject reads perfect.
    """
    a = G.read_png(path)
    op = a[..., 3] > 0.03
    if int(op.sum()) < 1000:
        return {"silhouette_px": int(op.sum()), "hole_px": -1,
                "hole_frac": -1.0, "red_on_empty": True}
    holes = 0
    for row in op:
        idx = np.flatnonzero(row)
        if idx.size < 2:
            continue
        holes += int((~row[idx[0]:idx[-1] + 1]).sum())
    sil = int(op.sum())
    return {"silhouette_px": sil, "hole_px": holes,
            "hole_frac": round(holes / float(sil + holes), 4),
            "red_on_empty": False}


# ---------------------------------------------------------------------------
# LADDER GATE - added 28 Nov 2026 07:5x CT by the 07:34 ART firing.
# ---------------------------------------------------------------------------
LADDER_H_FRAC_FLOOR = 0.16


def ladder_gate(sil, order, heights_m, resy,
                growth="free", scale_tol=1.6, distinct_tol=0.03):
    """Gate the SIDE-BY-SIDE tier sheet - the thing a tier ladder is accepted on.

    WHY THIS EXISTS. `townbuildgen.py` spends THREE EXTRA RENDERS per tier
    measuring `sil` (per-tier silhouette px / h_px / w_px), records it in the
    report, and then never reads it in a single error branch. On 28 Nov the
    well ladder ran three times at 06:46, 06:49 and 06:50 while the script was
    being edited. All three printed `verdict: GREEN, errors: []`. The 06:46
    draft framed the sheet THREE TIMES TOO FAR AWAY - every tier about 1/9 the
    area of the fixed version, labels unchanged at full size - and no gate
    could tell the broken draft from the fixed one. The author fixed it BY EYE.
    The header of this very file already named the hole ("BORDER - cannot see a
    subject that is merely small") and nothing closed it. This closes it.

    THE FLOOR IS DERIVED, NOT GUESSED, AND px/m WOULD HAVE BEEN WRONG.
    The first instinct was a pixels-per-metre floor off the well's 150-164
    px/m. That would have RED-flagged the shipped, GREEN, good-looking HALL
    ladder, which runs at 25.8-31.2 px/m purely because a 19.8 m hall needs
    more world in the same 1680x760 frame. Size-independent measure: the
    smallest tier's height as a FRACTION OF SHEET HEIGHT.
        known-bad  well 06:46 draft : 0.112  (0.113 / 0.151 / 0.112)  RY 760
        known-good hall, tightest   : 0.217  (0.217 / 0.418 / 0.743)  RY 820
        known-good well 06:50       : 0.350  (0.350 / 0.478 / 0.354)  RY 760
    The floor is the GEOMETRIC MIDPOINT of the two nearest neighbours,
    sqrt(0.112 * 0.217) = 0.156 -> 0.16. It sits 1.43x above the bad sheet and
    1.36x below the tightest good one: centred in log space rather than tuned
    to either sample. NOTE the hall sheet is 820 px tall and the well sheet
    760 - an earlier draft of this docstring read the hall at 760 and quoted
    0.234. That was wrong and the margin is thinner than it claimed.

    GROWTH IS DECLARED, NOT ASSUMED. `hallgen.py` asserts
    `hs[0] < hs[1] < hs[2]`. That is right FOR THE HALL and WRONG as a ladder
    rule: run it on the well and it fires on the GOOD sheet, because the
    tier-3 Fountain (1.64 m) is legitimately SHORTER than the tier-2 roofed
    Well Kept (2.415 m). A fountain is not taller than a well-house; that
    ladder progresses by RICHNESS, not height. So the caller DECLARES:
      growth="monotonic" - each tier taller and larger than the last (hall)
      growth="free"      - progression is by richness (well); only distinctness
                           is required, and the sheet is judged by eye.

    WHAT THIS GATE CANNOT SEE, SAID BEFORE THE NUMBERS:
      - whether the WEAR reads. It is a size and separation check. A tier-1
        rendered large and clean passes every number here and still fails the
        spec, which is that tier 1 is patched and make-do.
      - whether the three read in the RIGHT ORDER, or read as one town at all.
      - colour, value or material separation between tiers.
      - overlap between neighbouring tiers (the well sheet prevents that by
        construction in the span layout, not by a gate).
      - anything about the hero scale figure; that is a separate gate.
    A PASS HERE IS NOT A DONE LADDER. The sheet still has to be looked at.

    Returns a list of error strings - empty means pass.
    """
    errs = []

    # 1. RED ON EMPTY. The question: what does a PASS look like if the subject
    #    is absent? Without this, a missing tier simply vanishes from the dict
    #    and every surviving number reads fine.
    if not sil:
        return ["LADDER RED ON EMPTY: no silhouettes measured at all"]
    if not order:
        return ["LADDER RED ON EMPTY: empty tier order"]
    missing = [k for k in order if k not in sil]
    if missing:
        errs.append("LADDER RED ON EMPTY: no silhouette for %s" % missing)
    for k in order:
        v = sil.get(k)
        if not v:
            continue
        if int(v.get("px", 0)) <= 0 or int(v.get("h_px", 0)) <= 0:
            errs.append("TIER NOT RENDERED: %s px=%s h_px=%s"
                        % (k, v.get("px"), v.get("h_px")))
    if errs:
        return errs
    if not resy:
        return ["LADDER RED ON EMPTY: sheet height is zero"]

    # 2. SCALE FLOOR - catches the whole sheet framed too far away.
    fr = {k: sil[k]["h_px"] / float(resy) for k in order}
    small = min(fr, key=fr.get)
    if fr[small] < LADDER_H_FRAC_FLOOR:
        errs.append(
            "SHEET TOO SMALL TO READ: %s is %0.3f of sheet height, floor %0.2f "
            "(all tiers %s)" % (small, fr[small], LADDER_H_FRAC_FLOOR,
                                {k: round(fr[k], 3) for k in order}))

    # 3. ONE SCALE - the sheet's whole claim is "one pivot, one camera, one
    #    scale". Catches ONE tier at the wrong scale, which the floor misses
    #    because the floor only looks at the smallest. Deliberately LOOSE:
    #    the camera is perspective, not ortho, so tiers at different depths
    #    foreshorten differently - the hall spreads 1.21 legitimately.
    ppm = {}
    for k in order:
        hm = float(heights_m.get(k, 0) or 0)
        if hm > 0:
            ppm[k] = sil[k]["h_px"] / hm
    if len(ppm) >= 2:
        lo, hi = min(ppm.values()), max(ppm.values())
        if lo > 0 and hi / lo > scale_tol:
            errs.append("TIERS NOT AT ONE SCALE: px/m spread %0.2fx > %0.2fx %s"
                        % (hi / lo, scale_tol,
                           {k: round(v, 1) for k, v in ppm.items()}))
    elif heights_m:
        errs.append("LADDER RED ON EMPTY: no usable tier heights for scale check")

    # 4. DISTINCTNESS - catches the copy-paste bug where two tiers are the same
    #    mesh. Cheap, and the only thing a number can honestly say about a
    #    "free" progression.
    for i in range(len(order)):
        for j in range(i + 1, len(order)):
            a, b = sil[order[i]]["px"], sil[order[j]]["px"]
            if max(a, b) <= 0:
                continue
            if abs(a - b) / float(max(a, b)) < distinct_tol:
                errs.append("TIERS NOT DISTINCT: %s and %s within %0.1f%% "
                            "(%d vs %d px)" % (order[i], order[j],
                                               distinct_tol * 100, a, b))

    # 5. DECLARED GROWTH.
    if growth == "monotonic":
        hs = [sil[k]["h_px"] for k in order]
        ar = [sil[k]["px"] for k in order]
        if not all(hs[i] < hs[i + 1] for i in range(len(hs) - 1)):
            errs.append("SILHOUETTE HEIGHT NOT MONOTONIC: %s" % hs)
        if not all(ar[i] < ar[i + 1] for i in range(len(ar) - 1)):
            errs.append("SILHOUETTE AREA NOT MONOTONIC: %s" % ar)
    elif growth != "free":
        errs.append("LADDER GATE MISUSED: unknown growth %r" % (growth,))
    return errs
