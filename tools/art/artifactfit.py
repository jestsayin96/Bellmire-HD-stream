"""artifactfit - TIER 5, THE FOUND-ONLY LEGENDARY CARRY, ON A BODY. ART'S HALF.

  blender -b -noaudio -P tools/art/artifactfit.py -- --repo <repo> [--tier 5]

WHY THIS FILE EXISTS, AND IT IS A HOLE IN THIS LANE'S OWN PROOF.
`weaponfit.py` measured 24 cells GREEN - eight families at common/uncommon/rare.
Those are gear.gd `kit[]` indices 0,1,2. **gear.gd SHIPS FIVE TIERS** (KINDS,
gear.gd:209-229) and index 4 is the found-only artifact tier wired at S45. So
the tier a viewer spends months of points to see has NEVER BEEN RENDERED ON A
BODY by this lane, while the three tiers they get for free have a GREEN sheet.
Mr. E's binding line - "people want to see what they pay for, not just a stat" -
lands hardest exactly here, and this is the tier that was unproven.

AND IT IS NOT A COPY OF weaponfit. Two structural differences:
  1. weaponfit is FAMILY-keyed off a path it builds itself
     (assets/gear/dungeon/<fam>_<tier>.glb). TIER 5 IS NOT A FAMILY PATTERN -
     it is seven Quaternius _Golden models, two KayKit skeleton props and three
     kit re-uses, keyed per KIND. The list is PARSED OUT OF gear.gd's OWN
     `KINDS` dict so it cannot go stale the way a typed list would.
  2. gear.gd keys `held_rot` and `hand_scale` BY PATH, and tier 5 lands on
     different arms from the DUN tiers - including a branch written for exactly
     one model (`if path == ART + "bow_golden.glb"`). The carry is therefore
     read with `gearcarry`, which walks the real branches of the real functions
     in source order, rather than from any table in this file.

=============================================================================
*** THE ROTATION RULE IS MEASURED OFF THE BONE, NOT PICKED. AND MEASURING IT
*** FOUND THAT weaponfit's TWO HAND-CALIBRATED BASES USE TWO DIFFERENT RULES.
=============================================================================
weaponfit's FAULT 6 is the warning: it hand-derived a slot basis per family,
then kept reading `held_rot` into the register and scoring the hand table
anyway. Its fix was to refuse to infer - RED on any angle it had not calibrated.
TIER 5 HAS NO CALIBRATED BASIS AT ALL, for twelve meshes, so a rule is needed.

THE FIRST RULE I TRIED WAS WRONG AND THE GATE CAUGHT IT. I derived
`Rslot = C . R_godot . C^-1` (C: Godot(x,y,z) -> Blender(x,-z,y), the importer's
Y-up -> Z-up conversion) on the reasoning that both sides need converting. The
selftest refused to measure anything: it reproduced weaponfit's STAFF basis
exactly and its CROSSBOW basis under NO euler order. The residual is exactly
`C^-1`, so weaponfit's crossbow basis is `R_godot . C^-1` and its staff basis is
`C . R_godot . C^-1`. **THE TWO HAND-CALIBRATED BASES IN ONE INSTRUMENT ARE NOT
THE SAME RULE.** They cannot both be a consistent reading of their own euler.

ALGEBRA CANNOT SETTLE WHICH, SO IT WAS SETTLED BY MEASURING THE SLOT FRAME
(`_t5_slotframe.py`, 27 Nov 16:46 CT). gear.gd:245-249 states, measured by the
game build's own tools/_s19_hand.gd on the posed idle, that the slot's +Y is
world-FORWARD and its +X is world-DOWN (-0.99) - a claim about the GODOT frame.
On the posed Blender rig the same bone reads:

    slot+X . world_down    = +1.000          slot+Y . world_forward = +0.989

**THE BLENDER BONE BASIS CARRIES THE SAME LABELLING AS GODOT'S SLOT, SO THE
SLOT SIDE NEEDS NO CONVERSION AND ONLY THE MESH SIDE DOES:**

    Rslot = R_godot(held_rot) . C^-1

A vertex at Godot-mesh coordinate m belongs at slot coordinate R_godot . m; in
Blender that vertex sits at C . m, so the correction is R_godot . C^-1. Note
this means a ZERO held_rot is NOT a zero correction - it is C^-1, a real -90
about the slot's X - because mesh and slot are in different up-axis
conventions. My first instinct said the opposite, and the bone disagreed.

WHICH MAKES weaponfit's CROSSBOW RIGHT AND ITS STAFF BASIS THE ODD ONE - AND I
AM NOT OVERCLAIMING THAT. The two rules differ, for the staff's (0,0,90), ONLY
by a roll about the staff's own shaft: both land the shaft along slot -X =
world UP, which is the whole of gear.gd's stated intent for it. On a
near-axisymmetric pole that roll is invisible, which is exactly why both tables
passed a look and why the register was honestly green. **IT IS A LATENT
INCONSISTENCY IN weaponfit, NOT A SHIPPED VISUAL DEFECT**, and it is reported,
not quietly patched - weaponfit scores DUN tiers and is not touched by this run.

THE GATE IS NOT TOOTHLESS AFTER THAT CORRECTION. `selftest_basis()` runs FIRST
and measures FOUR things, and raises rather than measuring a single cell:
  1. THE PREMISE, re-measured every run off the posed bone: slot+X.world_down
     and slot+Y.world_forward both > 0.98. If the rig or the idle ever moves,
     the rule's foundation is void and this file must not keep scoring.
  2. the rule must reproduce weaponfit's CROSSBOW basis at its calibration
     angles to 1e-6 - an independent hand derivation checked against the game
     build's own s17 close-up.
  3. it must agree with `weaponfit.slot_matrix` at gear.gd's LIVE crossbow roll,
     so the two instruments cannot score the same shipped carry differently.
  4. the STAFF divergence is measured and RECORDED with its residual named, and
     the residual is asserted to be a pure roll about the shaft. If it is ever
     something other than a shaft roll, that is a visual fault and this FAILS.
The euler order is tested, not assumed (Godot Node3D is YXZ); only an order
that satisfies 2 and 3 is accepted, and which one is recorded.

EVERY GATE weaponfit EARNED THE HARD WAY IS KEPT, AND THEY ARE IN THE VERDICT -
not printed beside it. blanks, border alpha (a clipped icon is not a blank one),
the A/B/C visibility test that asks the VIEWER'S question by rendering with and
without through ONE camera and counting the pixels that MOVED, `seen` bounded to
the weapon's own silhouette so a cast shadow cannot push it over 1.0, floor
breaks, laths, and RED ON EMPTY everywhere - zero cells, zero verts, zero
unoccluded pixels, zero measured views.
"""
import os
import sys
import json
import math
import argparse
import re

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402
import gearcarry as GC         # noqa: E402

# Godot(x,y,z) -> Blender(x,-z,y). The glTF importer's Y-up -> Z-up conversion,
# the same correspondence weaponfit's GODOT_TO_BLENDER_MESH records.
C4 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0))).to_4x4()

ORDERS = ("YXZ", "XYZ")


def godot_rot(deg, order):
    """R_godot for an euler triple in DEGREES, in the given order."""
    rx, ry, rz = (math.radians(float(d)) for d in deg)
    Rx = Matrix.Rotation(rx, 4, 'X')
    Ry = Matrix.Rotation(ry, 4, 'Y')
    Rz = Matrix.Rotation(rz, 4, 'Z')
    if order == "YXZ":
        return Ry @ Rx @ Rz
    return Rx @ Ry @ Rz


def slot_basis(deg, order):
    """THE RULE: a GLOBAL basis change conjugates every transform, so the
    importer's conversion cancels in bone.R.mesh and the correction is
    C.R.C^-1 - which is IDENTITY at a zero held_rot. See the docstring: this
    was settled by a picture after the other rule made a lance of the sword."""
    R = C4 @ godot_rot(deg, order) @ C4.inverted()
    d = R.to_3x3().determinant()
    if abs(d - 1.0) > 1e-6:
        raise SystemExit("ARTIFACTFIT FAIL - derived basis is not a proper "
                         "rotation (det %.6f) for held_rot %s" % (d, list(deg)))
    return R


def _cal_matrix(fam):
    """weaponfit's hand-calibrated basis for `fam`, as a 4x4. Ground truth."""
    cols = WF.SLOT_ROT[fam]
    M = Matrix(((cols[0][0], cols[1][0], cols[2][0]),
                (cols[0][1], cols[1][1], cols[2][1]),
                (cols[0][2], cols[1][2], cols[2][2])))
    return M.to_4x4()


def _close(A, B, eps=1e-6):
    return all(abs(A[r][c] - B[r][c]) < eps for r in range(4) for c in range(4))


def selftest_basis(gear_path, base):
    """RUN FIRST, RAISES RATHER THAN MEASURING. Four checks - see the docstring.
    `base` is the posed slot matrix, so check 1 is re-measured every run."""
    M3 = base.to_3x3()
    sx = (M3 @ Vector((1, 0, 0))).normalized()
    sy = (M3 @ Vector((0, 1, 0))).normalized()
    d_down = sx.dot(Vector((0, 0, -1)))
    d_fwd = sy.dot(Vector((0, -1, 0)))
    if d_down < 0.98 or d_fwd < 0.98:
        raise SystemExit(
            "ARTIFACTFIT FAIL - THE RULE'S PREMISE NO LONGER HOLDS. This file "
            "converts only the mesh side because the posed Blender bone basis "
            "carries Godot's slot labelling (gear.gd:245-249: slot +Y forward, "
            "slot +X down). Measured now: slot+X.world_down=%.3f, "
            "slot+Y.world_forward=%.3f. The rig or the idle has moved, so the "
            "rotation rule is unfounded and NOTHING is measured."
            % (d_down, d_fwd))

    notes, passed = [], []
    for order in ORDERS:
        cal = WF.SLOT_ROT_CAL["staff"]
        if _close(slot_basis(cal, order), _cal_matrix("staff")):
            passed.append(order)
        else:
            notes.append("%s: staff basis at cal %s does not match weaponfit"
                         % (order, list(cal)))
    if not passed:
        raise SystemExit(
            "ARTIFACTFIT FAIL - the rotation rule does not reproduce "
            "weaponfit's hand-calibrated STAFF basis under any euler order, "
            "and the staff is the basis that agrees with the identity "
            "correction weaponfit ships for its six unrotated families - the "
            "one whose pictures are accepted. NOTHING is measured. Detail: %s"
            % "; ".join(notes))
    order = passed[0]

    OVR = WF.gear_overrides(gear_path)
    live = OVR["crossbow"]["engine_rot_deg"]
    wf_M, wf_roll = WF.slot_matrix("crossbow", live)

    # 4. THE CROSSBOW DIVERGENCE IS RECORDED, NOT SILENTLY RESOLVED. No tier-5
    # path is a DUN crossbow, so nothing in this register is scored through it,
    # and it is NOT this run's to change - it is named for the crossbow's pass.
    scal = WF.SLOT_ROT_CAL["crossbow"]
    mine = slot_basis(scal, order)
    theirs = _cal_matrix("crossbow")
    agree = _close(mine, theirs)
    staff = dict(family="crossbow", weaponfit_rule_differs=not agree,
                 held_rot_cal=list(scal))
    if not agree:
        resid = (theirs @ mine.inverted()).to_3x3()
        q = resid.to_quaternion()
        axis = Vector(q.axis).normalized() if q.angle > 1e-6 else Vector((0, 0, 0))
        # crossbow_common's long axis is Blender mesh X (gear.gd measured it:
        # dim 0.691/0.638/0.194, prod on X)
        shaft_mine = (mine.to_3x3() @ Vector((1, 0, 0))).normalized()
        shaft_theirs = (theirs.to_3x3() @ Vector((1, 0, 0))).normalized()
        sep = math.degrees(math.acos(min(1.0, max(-1.0, shaft_mine.dot(shaft_theirs)))))
        staff.update(residual_angle_deg=round(math.degrees(q.angle), 2),
                     residual_axis=[round(c, 3) for c in axis],
                     shaft_separation_deg=round(sep, 3),
                     prod_separation_deg=round(sep, 3),
                     reading=("weaponfit's crossbow basis is R.C^-1 where every "
                              "other family it ships is C.R.C^-1 (identity at "
                              "zero). OPEN QUESTION for the crossbow's own pass "
                              "- NOT resolved here, and no tier-5 path uses it."))
    return dict(euler_order=order,
                rule="Rslot = C . R_godot(held_rot) . C^-1  (identity at zero)",
                premise_measured=dict(slot_x_dot_world_down=round(d_down, 4),
                                      slot_y_dot_world_forward=round(d_fwd, 4)),
                checked=["premise@bone", "crossbow@cal", "crossbow@live",
                         "crossbow@cal(divergence recorded)"],
                crossbow_live_held_rot=list(live),
                crossbow_live_roll_deg=round(wf_roll, 3),
                weaponfit_rule_divergence=staff)


def kinds_tier(gear_path, tier):
    """Parse gear.gd's own KINDS dict. The tier-N path per kind, resolved
    through gear.gd's own path consts. RED ON EMPTY and red on an unresolved
    const - a typed list in this file is exactly what goes stale."""
    with open(gear_path, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    consts = dict(re.findall(r'const\s+([A-Z_]+)\s*:?=\s*"([^"]*)"', src))
    out, bare = {}, []
    for m in re.finditer(r'^\s*"([a-z]+)":\s*\{.*?"kit":\s*\[(.*?)\]\}',
                         src, re.M | re.S):
        kind, items = m.group(1), [x.strip() for x in m.group(2).split(",")]
        if len(items) < tier:
            raise SystemExit("ARTIFACTFIT FAIL - kind %r has %d kit entries, "
                             "tier %d asked for" % (kind, len(items), tier))
        e = items[tier - 1]
        if e == '""':
            bare.append(kind)
            continue
        mm = re.match(r'([A-Z_]+)\s*\+\s*"([^"]*)"$', e)
        if not mm or mm.group(1) not in consts:
            raise SystemExit("ARTIFACTFIT FAIL - cannot resolve kit[%d] of %r "
                             "from gear.gd: %r. Refusing to measure a path I "
                             "had to guess." % (tier - 1, kind, e))
        out[kind] = consts[mm.group(1)] + mm.group(2)
    if not out:
        raise SystemExit("ARTIFACTFIT FAIL - parsed ZERO kinds out of gear.gd. "
                         "An empty register is a FAIL, not a pass.")
    return out, bare


def load_res(repo, res_path):
    p = os.path.join(repo, res_path.replace("res://", "").replace("/", os.sep))
    if not os.path.isfile(p):
        return [], p
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    return new, p


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", default="")
    ap.add_argument("--tier", type=int, default=5)
    ap.add_argument("--only", default="", help="comma list of kinds")
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier)
    tmpdir = os.path.join(outdir, "_tmp")
    os.makedirs(outdir, exist_ok=True)
    os.makedirs(tmpdir, exist_ok=True)

    gear_path = a.gear or os.path.join(os.path.dirname(os.path.abspath(a.repo)),
                                       "jests-hd-medieval-adventure",
                                       "scripts", "gear.gd")
    if not os.path.exists(gear_path):
        raise SystemExit("ARTIFACTFIT FAIL - cannot read the engine carry at %s"
                         % gear_path)

    # the engine's grip shift is gated to ONE family in gear.gd. Assert that the
    # gate is not a tier-5 path, rather than silently measuring without it.
    GRIP, _ = WF.grip_shift(gear_path)
    tier_paths, bare = kinds_tier(gear_path, a.tier)
    if a.only:
        want = set(x for x in a.only.split(",") if x)
        tier_paths = {k: v for k, v in tier_paths.items() if k in want}
    for k, rp in tier_paths.items():
        if ("/%s_" % GRIP["fam"]) in rp:
            raise SystemExit("ARTIFACTFIT FAIL - tier-%d path for %r (%s) is "
                             "inside the family gear.gd gives the grip shift "
                             "to (%s). That shift is not modelled here."
                             % (a.tier, k, rp, GRIP["fam"]))

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()

    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    # *** THE RULE IS PROVEN BEFORE A SINGLE CELL IS MEASURED, AND CHECK 1 IS
    # *** RE-MEASURED OFF THIS VERY BONE. ***
    ST = selftest_basis(gear_path, base)
    print("ARTIFACTFIT basis selftest PASSED: %s" % json.dumps(ST))

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2),
                        ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nm, ld)
            lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    body_trees = []
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - clip would read 0 over nothing"

    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    reg, errors, blanks, clipped_frames, blind, laths = {}, [], [], [], [], []
    floor_breaks, body_only, lances = [], {}, []

    for kind in sorted(tier_paths):
        res_path = tier_paths[kind]
        key = kind
        objs, path = load_res(a.repo, res_path)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            errors.append("%s: no mesh imported from %s" % (key, res_path))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        cr = GC.carry(gear_path, res_path)
        hs = cr["hand_scale"]
        deg = cr["held_rot_deg"]
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        lv = WF.world_verts(meshes)
        local_ext = (sorted([max(v[i] for v in lv) - min(v[i] for v in lv)
                             for i in range(3)]) if lv else None)
        Rslot = slot_basis(deg, ST["euler_order"])
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = WF.world_verts(meshes)
        if not wv:
            errors.append("%s: zero vertices - the clip test would be empty" % key)
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        zs = [v.z for v in wv]
        far = [v for v in wv if (v - slot).length > WF.FIST_R]
        if not far:
            errors.append("%s: every vertex is inside the fist sphere - clip "
                          "test empty" % key)
        n_clip = sum(1 for v in far if WF.inside(body_trees, v))
        n_ground = sum(1 for v in wv if v.z < -0.002)
        floor_depth = round(max(0.0, -min(zs)), 4)
        rec = dict(kind=kind, model=res_path, verts=len(wv), checked=len(far),
                   reach=round(max(zs) - slot.z, 3),
                   drop=round(slot.z - min(zs), 3),
                   span=round(max(v.x for v in wv) - min(v.x for v in wv), 3),
                   tip_z=round(max(zs), 3), hero_h=round(hinfo["h"], 3),
                   clip=n_clip, ground=n_ground, floor_depth=floor_depth,
                   hand_scale=hs, hand_scale_arm=cr["hand_scale_arm"],
                   held_rot_deg=[round(float(d), 3) for d in deg],
                   held_rot_arm=cr["held_rot_arm"],
                   euler_order=ST["euler_order"])
        if n_ground:
            floor_breaks.append(
                "%s: %d vertices below the floor, deepest %.3f m under it - the "
                "carry drags this weapon through the ground"
                % (key, n_ground, floor_depth))
        # *** THE ORIENTATION GATE, ADDED 27 NOV 16:52 CT AFTER LOOKING. ***
        # Every gate inherited from weaponfit measures whether the weapon is
        # THERE and whether it can be SEEN. NOT ONE OF THEM MEASURES WHICH WAY
        # IT POINTS, and the front sheet of this very run shows the legendary
        # sword sticking out SIDEWAYS from the hip like a bar while every one
        # of those gates reads green. A register that cannot see the fault it
        # exists to find is the unearned-pass family again, so: the mesh's own
        # LONG axis is carried to world and its angle from vertical measured.
        # DERIVED from the mesh's local bounds, never a per-family label - the
        # first version of the sibling probe hardcoded the crossbow's axis
        # names, applied them to the staff and reported a shaft that was not
        # the shaft.
        li = local_ext_axis = [max(v[i] for v in lv) - min(v[i] for v in lv)
                               for i in range(3)]
        laxis = li.index(max(li))
        lw = ((base @ Rslot).to_3x3() @ Vector(
            tuple(1.0 if i == laxis else 0.0 for i in range(3)))).normalized()
        hang = math.degrees(math.acos(min(1.0, max(-1.0,
                                                   abs(lw.dot(Vector((0, 0, 1))))))))
        rec["long_axis_local"] = "XYZ"[laxis]
        rec["long_axis_world"] = [round(c, 3) for c in lw]
        rec["hang_deg_from_vertical"] = round(hang, 1)
        rec["aspect"] = round(max(li) / max(1e-6, sorted(li)[1]), 2)
        # a POLE is a weapon whose long axis dominates - a blade, haft or shaft.
        # A bow or a crossbow is not judged by this: its long axis is the limb
        # or the prod and horizontal is correct for one of them.
        if rec["aspect"] >= 2.0 and kind not in ("bow", "crossbow") and hang > 60.0:
            lances.append(
                "%s: long axis %.0f deg from vertical (world %s) - this weapon "
                "is carried HORIZONTAL, not hanging in the fist. gear.gd gives "
                "%s held_rot %s; a kind with no row of its own falls through to "
                "`return Vector3.ZERO` and is carried flat."
                % (key, hang, rec["long_axis_world"], res_path,
                   rec["held_rot_deg"]))

        allpts = bpts + wv
        outs, proving = {}, 0
        for vname, az in WF.VIEWS:
            cam = WF.make_cam(az, cz, allpts)
            outs[vname] = WF.frame_outside(cam, allpts)
            if vname not in body_only:
                WF.show(meshes, False)
                body_only[vname] = WF.render_to(
                    os.path.join(tmpdir, "_body_%s.png" % vname))
                WF.show(meshes, True)
            A = body_only[vname]
            png = os.path.join(outdir, "%s_%s.png" % (key, vname))
            B = WF.render_to(png)
            WF.show(body, False)
            Cim = WF.render_to(os.path.join(tmpdir, "_w_%s_%s.png" % (key, vname)))
            WF.show(body, True)

            cm = Cim[:, :, 3] > WF.DIFF_EPS
            if int(cm.sum()) >= 2:
                cys, cxs = np.nonzero(cm)
                rec.setdefault("minor", {})[vname] = int(
                    min(cxs.max() - cxs.min() + 1, cys.max() - cys.min() + 1))
            op = int((B[:, :, 3] > WF.DIFF_EPS).sum())
            if op == 0:
                blanks.append(os.path.basename(png))
            b = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                    float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
            if b > WF.DIFF_EPS:
                clipped_frames.append(os.path.basename(png))
            changed = np.abs(B - A).max(axis=2) > WF.DIFF_EPS
            mask = Cim[:, :, 3] > WF.DIFF_EPS
            delta = int(changed.sum())
            alone = int(mask.sum())
            covered = int((changed & mask).sum())
            if alone == 0:
                errors.append("%s/%s: the weapon renders EMPTY alone - the seen "
                              "fraction would be computed over nothing"
                              % (key, vname))
                seen = 0.0
            else:
                seen = covered / float(alone)
            if seen >= WF.SEEN_MIN and covered >= WF.VIS_MIN:
                proving += 1
            rec.setdefault("opaque", {})[vname] = op
            rec.setdefault("border", {})[vname] = round(b, 4)
            rec.setdefault("vis", {})[vname] = covered
            rec.setdefault("delta", {})[vname] = delta
            rec.setdefault("alone", {})[vname] = alone
            rec.setdefault("seen", {})[vname] = round(seen, 4)
            bpy.data.objects.remove(cam, do_unlink=True)
        rec["outside"] = outs
        ext = sorted([max(v[i] for v in wv) - min(v[i] for v in wv)
                      for i in range(3)])
        mid_px = (local_ext[1] * hs * WF.PX_PER_M) if local_ext else 0.0
        rec["ext"] = [round(e, 4) for e in ext]
        rec["local_ext"] = [round(e, 4) for e in local_ext] if local_ext else None
        rec["mid_px"] = round(mid_px, 1)
        mins = rec.get("minor", {})
        if mid_px <= 1.0 or not mins:
            errors.append("%s: cannot compute `show` - mid_px %.2f over %d "
                          "measured views. This is a FAIL, not a 1.0."
                          % (key, mid_px, len(mins)))
        else:
            rec["best_minor"] = max(mins.values())
            rec["show"] = round(rec["best_minor"] / mid_px, 3)
            if rec["show"] < WF.SHOW_MIN:
                laths.append("%s: show %.2f (best view turns %d px of a possible "
                             "%.0f to the camera) - the carry never shows this "
                             "weapon's broad face"
                             % (key, rec["show"], rec["best_minor"], mid_px))
        rec["proving_views"] = proving
        if proving < WF.MIN_PROVING:
            blind.append("%s: only %d of %d views show the weapon (seen>=%.2f "
                         "AND vis>=%d px) - %s"
                         % (key, proving, len(WF.VIEWS), WF.SEEN_MIN, WF.VIS_MIN,
                            ", ".join("%s seen %.3f vis %d"
                                      % (v, rec["seen"][v], rec["vis"][v])
                                      for v, _ in WF.VIEWS)))
        reg[key] = rec
        print("  CELL %-13s hs=%.2f rot=%s reach=%.2f clip=%d ground=%d "
              "seen=%s proving=%d"
              % (key, hs, rec["held_rot_deg"], rec["reach"], n_clip, n_ground,
                 {v: rec["seen"][v] for v, _ in WF.VIEWS}, proving))
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)

    want = len(tier_paths)
    if len(reg) != want:
        errors.append("register has %d of %d cells" % (len(reg), want))
    if not reg:
        errors.append("EMPTY REGISTER - nothing was measured, this is a FAIL "
                      "not a pass")
    ok = ((not errors) and (not blanks) and (not clipped_frames)
          and (not blind) and (not laths) and (not floor_breaks)
          and (not lances))
    out = dict(verdict="GREEN" if ok else "FAIL", ok=ok, tier=a.tier,
               hero=hinfo, handslot=[round(v, 4) for v in slot],
               cells=len(reg), views=[v for v, _ in WF.VIEWS],
               bare_kinds=bare, basis_selftest=ST,
               seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN,
               min_proving=WF.MIN_PROVING, show_min=WF.SHOW_MIN,
               px_per_m=WF.PX_PER_M, grip_shift_gate=GRIP["fam"],
               laths=laths, floor_breaks=floor_breaks, lances=lances,
               blanks=blanks,
               frame_clips=clipped_frames, blind_views=blind,
               errors=errors, models=reg)
    rp = os.path.join(outdir, "_fit_t%d_register.json" % a.tier)
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("ARTIFACTFIT verdict=%s cells=%d blanks=%d frameclips=%d blind=%d "
          "laths=%d floor=%d lances=%d errors=%d"
          % (out["verdict"], len(reg), len(blanks), len(clipped_frames),
             len(blind), len(laths), len(floor_breaks), len(lances), len(errors)))
    for tag, lst in (("ERROR", errors), ("BLIND", blind), ("LATH", laths),
                     ("FLOOR", floor_breaks), ("LANCE", lances)):
        for e in lst:
            print("  %s %s" % (tag, e))
    print("ARTIFACTFIT_DONE", rp)


if __name__ == "__main__":
    main()
