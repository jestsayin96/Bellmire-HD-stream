"""_t5_rx - THE PER-WEAPON PRESCRIPTION THAT CLOSES ARTIFACTFIT'S OWN RED.

Written 27 Nov 2026, clock read off the machine. artifactfit's tier-5 register
came back `verdict: "FAIL"` with 11 of 13 legendary weapons in `lances`, 2
`frame_clips` and 1 `floor_break`. The cause is in the register's own sentence:
`held_rot` in gear.gd has a row for the staff family, the _Golden bow and the
crossbow family, and EVERY OTHER KIND FALLS THROUGH TO `return Vector3.ZERO`.
A mesh built along its own +Y, carried with no rotation, lands along the slot's
own long axis - which is world HORIZONTAL - so eleven legendary weapons are
couched across the chest like lances.

THIS FILE DOES NOT FIX IT. gear.gd is the GAME BUILD'S file. This file
PRESCRIBES: per kind, the euler triple that stands the weapon in the fist,
derived by carrying the real mesh to the real posed hand under artifactfit's
proven rule and SEARCHING, then rendered and looked at.

WHAT IT MEASURES PER CANDIDATE (geometry only, no render - the search is wide):
  hang    - angle of the mesh's OWN long axis from world vertical. DERIVED from
            local bounds, never a per-family label.
  clip    - vertices inside the body's BVH, outside the fist sphere.
  ground  - vertices below the floor.
  proj_minor_ratio - min projected span over the three real view azimuths
            against the mid axis's available width. REPORTED ONLY, NOT GATED.
            My first pass gated it at weaponfit's SHOW_MIN 0.70 as a stand-in
            for `show`, and it read 1.57, 2.75, 3.71 - a FRACTION that cannot
            exceed 1 was reading 3.7, so it was not the quantity I named it.
            The real `show` comes from a render and nothing else.
  tip     - world z of the highest vertex, against the hero's height.

RED ON EMPTY, EVERYWHERE:
  - a kind whose candidate set yields NO passing triple is a FAIL ROW with its
    best near-miss printed, never a skipped row and never a green.
  - a kind whose mesh imports zero vertices is a FAIL, not a 0 score.
  - a search that scores zero candidates for any kind aborts the run.

AND THE TIE-BREAK IS DELIBERATELY CONSERVATIVE: among passing triples the
SIMPLEST wins - fewest non-zero terms, then smallest total magnitude, then
nearest the precedent already in gear.gd. A prescription the engine lane cannot
read off in one line is a prescription it will not take.
"""
import os, sys, json, math, argparse
import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402
import gearcarry as GC         # noqa: E402
import artifactfit as AF       # noqa: E402

UP = Vector((0, 0, 1))

# the candidate grid. Every value is one of: 0, the +-90 the precedent already
# uses, the 180 that flips a weapon end-for-end, and the 35 roll gear.gd itself
# derived for the crossbow. NOT a continuous solve - the engine lane has to
# type these in, so the grid is the set of triples a human would write.
XS = (0.0, -90.0, 90.0, 180.0)
YS = (0.0, 35.0, -35.0, 90.0, -90.0, 180.0)
ZS = (0.0, 90.0, -90.0, 180.0)

HANG_MAX = 25.0      # a weapon standing in the fist. 60 was the lance gate's
                     # floor; a PRESCRIPTION must do better than just-not-a-lance.
# *** WHY `clip` IS NOT GATED AT ZERO. FIRST PASS, 17:38 CT: I required
# *** clip == 0 and ground == 0 and broad >= 0.70, and ZERO of 1248 candidates
# *** passed for ANY of the 13 kinds. An instrument that cannot pass anything
# *** has not measured anything - trap 4 again, in my own new tool.
# *** The shipped acceptance test NEVER gated clip: `_fit_t5_register.json`
# *** carries clip 150 (axe), 451 (bow), 536 (spear) and still reports its
# *** faults as lances/floor/frame only. And the bow - the ONE cell the team
# *** lead confirmed by eye reads correctly - carries (0,0,90) with hang 0.1
# *** AND clip 451. So clip at an upright carry is the grip and guard inside
# *** the fist and forearm, which is by design; clip is the FAULT only when it
# *** is a shaft driven through the torso, and `hang` is what separates those.
# *** So: clip must not get WORSE than the carry gear.gd ships today, and is
# *** ranked, not gated at zero. ground stays hard - a weapon through the
# *** ground is never right.
# *** THIRD PASS, 17:5x CT: `clip_no_worse` WAS REWARDING THE DEFECT. ***
# Six kinds still went red against it, and the baseline is why: the dagger's
# current clip is 0 and the greatsword's is 0 PRECISELY BECAUSE they are held
# out horizontally at arm's length, where a weapon barely touches the body at
# all. Gating "no worse than today" therefore protects the lance. A baseline
# contaminated by the very fault being fixed is not a baseline - that is the
# same family as an instrument that cannot move.
# THE CEILING IS NOW ABSOLUTE AND CALIBRATED OFF THE ONE CELL CONFIRMED BY EYE.
# The team lead looked at `_sheets/t5_front.png` and confirmed the BOW reads
# correctly: upright, strung, in front of the body. The bow's clip at that
# confirmed-good carry is 451 of 1218 checked vertices = 0.370. So a carry may
# bury up to the fraction the bow already buries and no more. Measured off a
# picture somebody looked at, not chosen.
CLIP_FRAC_MAX = 0.37

# *** THE SECOND PASS FOUND THE REAL FAULT AND IT IS NOT THE EULER. 17:4x CT. ***
# With the gate corrected, `hang 0` turned out to be reachable for ALL ELEVEN
# with a SINGLE Z term - and every one of them then FAILED `clip_no_worse`:
# dagger 0 -> 112, greatsword 0 -> 343, sword 93 -> 220, mace 157 -> 454.
# That is not a wrong rotation. These meshes carry their ORIGIN AT THE WEAPON'S
# MIDDLE (gear.gd: "the _Golden set is built along +Y with the grip at the
# origin" - measured here, the origin is mid-shaft, not the grip), so standing
# a 2.3-2.7 m weapon up about its own middle drives the lower half down through
# the hip, the thigh and the cape. AND IT IS THE SAME FAULT AS THE BOW'S
# FLOOR_BREAK: the bow is the one cell the team lead confirmed reads correctly,
# it carries (0,0,90) with hang 0.1, and its 31 sub-floor vertices are its own
# lower limb buried in the ground for exactly this reason.
# SO THE PRESCRIPTION HAS TWO HALVES, AND THE SECOND USES A MECHANISM GEAR.GD
# ALREADY SHIPS: `const STAFF_GRIP_SHIFT := 0.25` applied as
# `.position.x -= STAFF_GRIP_SHIFT`, today gated to the DUN staff family alone.
# A node's `position` is in the PARENT frame, and the slot's +X is world DOWN
# (gear.gd:245-249, re-measured by the basis selftest every run), so a NEGATIVE
# x offset RAISES the weapon in the fist. Per weapon the offset is SOLVED, not
# gridded: the value that puts the weapon's butt BUTT_DROP below the fist.
BUTT_DROP = 0.08     # the butt sits a thumb's width below the fist, not level
                     # with it - a grip held at its very end reads as dropped.


def view_axes(az_deg):
    """(right, up, dir) of weaponfit's camera at this azimuth. front az=0 puts
    the camera at -Y looking toward +Y, so the image right is +X."""
    Rz = Matrix.Rotation(math.radians(az_deg), 3, 'Z')
    return Rz @ Vector((1, 0, 0)), Vector((0, 0, 1)), Rz @ Vector((0, 1, 0))


def score(objs_verts_local, laxis, maxis, Rslot, base, hs, body_trees, slot,
          hero_h, mid_m, grip_x=0.0):
    """Geometry-only score of one candidate. Returns a dict or raises.
    `grip_x` is gear.gd's grip shift: a translation in the SLOT frame along
    slot +X (world DOWN), so a negative value raises the weapon."""
    T = Matrix.Translation(Vector((grip_x, 0.0, 0.0)))
    M = base @ T @ Rslot @ Matrix.Diagonal((hs,) * 3).to_4x4()
    wv = [M @ Vector(v) for v in objs_verts_local]
    if not wv:
        raise RuntimeError("RED ON EMPTY - candidate scored over zero vertices")
    M3 = (base @ Rslot).to_3x3()
    lw = (M3 @ Vector(tuple(1.0 if i == laxis else 0.0
                            for i in range(3)))).normalized()
    hang = math.degrees(math.acos(min(1.0, max(-1.0, abs(lw.dot(UP))))))
    far = [v for v in wv if (v - slot).length > WF.FIST_R]
    if not far:
        raise RuntimeError("RED ON EMPTY - every vertex inside the fist sphere")
    clip = sum(1 for v in far if WF.inside(body_trees, v))
    ground = sum(1 for v in wv if v.z < -0.002)
    depth = round(max(0.0, -min(v.z for v in wv)), 4)
    # broad: the best view's MINOR projected span, as a fraction of the width
    # the mid axis could show. Mirrors `show` without a render.
    best_minor = 0.0
    for _, az in WF.VIEWS:
        r, u, _d = view_axes(az)
        xs = [v.dot(r) for v in wv]
        ys = [v.dot(u) for v in wv]
        best_minor = max(best_minor,
                         min(max(xs) - min(xs), max(ys) - min(ys)))
    broad = best_minor / mid_m if mid_m > 1e-6 else 0.0
    return dict(grip_x=round(grip_x, 4),
                hang=round(hang, 1), clip=clip, checked=len(far),
                clip_frac=round(clip / float(len(far)), 4), ground=ground,
                floor_depth=depth, proj_minor_ratio=round(broad, 3),
                tip_z=round(max(v.z for v in wv), 3),
                over_head=round(max(v.z for v in wv) - hero_h, 3),
                long_axis_world=[round(c, 3) for c in lw])


def simplicity(t):
    nz = sum(1 for v in t if abs(v) > 1e-9)
    return (nz, sum(abs(v) for v in t), [abs(v) for v in t])


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier)
    rxdir = os.path.join(outdir, "_rx")
    tmpdir = os.path.join(rxdir, "_tmp")
    os.makedirs(rxdir, exist_ok=True)
    os.makedirs(tmpdir, exist_ok=True)

    tier_paths, bare = AF.kinds_tier(a.gear, a.tier)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    slot = base @ Vector((0, 0, 0))
    # THE RULE IS PROVEN BEFORE A SINGLE CANDIDATE IS SCORED.
    ST = AF.selftest_basis(a.gear, base)
    order = ST["euler_order"]
    print("RX basis selftest PASSED order=%s" % order)

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
            ld = bpy.data.lights.new(nm, 'SUN'); ld.energy = en
            lo = bpy.data.objects.new(nm, ld); lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    body_trees = []
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH from the body - clip would read 0 over nothing"
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    rx, fails, searched = {}, [], 0
    for kind in sorted(tier_paths):
        res_path = tier_paths[kind]
        objs, path = AF.load_res(a.repo, res_path)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            fails.append("%s: no mesh imported from %s - FAIL, not a skip"
                         % (kind, res_path))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        lv = WF.world_verts(meshes)          # meshes are at import pose = local
        if not lv:
            fails.append("%s: zero vertices - FAIL, not a 0 score" % kind)
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        lvt = [tuple(v) for v in lv]
        cr = GC.carry(a.gear, res_path)
        hs = cr["hand_scale"]
        cur = [float(d) for d in cr["held_rot_deg"]]
        ext = [max(v[i] for v in lvt) - min(v[i] for v in lvt) for i in range(3)]
        laxis = ext.index(max(ext))
        rest = sorted(range(3), key=lambda i: -ext[i])
        maxis = rest[1]
        mid_m = ext[maxis] * hs
        aspect = max(ext) / max(1e-6, sorted(ext)[1])

        cand, n = [], 0
        for x in XS:
            for y in YS:
                for z in ZS:
                    t = (x, y, z)
                    try:
                        s = score(lvt, laxis, maxis,
                                  AF.slot_basis(t, order), base, hs,
                                  body_trees, slot, hinfo["h"], mid_m)
                    except RuntimeError as e:
                        fails.append("%s %s: %s" % (kind, list(t), e))
                        continue
                    n += 1
                    s["triple"] = list(t)
                    s["grip_solved"] = False
                    cand.append(s)
                    # SOLVE the grip shift for any candidate that stands it up.
                    # Only meaningful when the long axis is near vertical; a
                    # horizontal weapon has no butt to drop.
                    if s["hang"] <= HANG_MAX:
                        Rs = AF.slot_basis(t, order)
                        zmin = min((base @ Rs @ Matrix.Diagonal((hs,) * 3)
                                    .to_4x4() @ Vector(v)).z for v in lvt)
                        want = slot.z - BUTT_DROP
                        # slot +X is world DOWN: moving +x LOWERS by that much.
                        gx = -(want - zmin)
                        try:
                            s2 = score(lvt, laxis, maxis, Rs, base, hs,
                                       body_trees, slot, hinfo["h"], mid_m,
                                       grip_x=gx)
                        except RuntimeError as e:
                            fails.append("%s %s grip-solve: %s"
                                         % (kind, list(t), e))
                            continue
                        s2["triple"] = list(t)
                        s2["grip_solved"] = True
                        n += 1
                        cand.append(s2)
        searched += n
        if not cand:
            fails.append("%s: the search scored ZERO candidates - this is a "
                         "FAIL, not an empty prescription" % kind)
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue

        is_launcher = kind in ("bow", "crossbow")
        cur_s = next((s for s in cand if s["triple"] == cur), None)
        if cur_s is None:
            fails.append("%s: gear.gd's OWN triple %s is not in the grid - the "
                         "baseline this prescription is measured against was "
                         "never scored. FAIL, not a prescription." % (kind, cur))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        def gates(s):
            """every gate, named, so the BINDING one is always visible. My
            first pass sorted the near miss by clip and hid which gate bound."""
            return dict(upright=(is_launcher or s["hang"] <= HANG_MAX),
                        no_ground=(s["ground"] == 0),
                        clip_ok=(s["clip_frac"] <= CLIP_FRAC_MAX))
        for s in cand:
            s["gates"] = gates(s)
            s["passes"] = all(s["gates"].values())
        passing = [s for s in cand if s["passes"]]
        rec = dict(kind=kind, model=res_path, hand_scale=hs,
                   current_triple=cur, euler_order=order,
                   local_ext=[round(e, 4) for e in ext],
                   long_axis_local="XYZ"[laxis], mid_axis_local="XYZ"[maxis],
                   aspect=round(aspect, 2), candidates=n,
                   n_passing=len(passing),
                   current_score=cur_s, launcher=is_launcher,
                   clip_frac_max=CLIP_FRAC_MAX,
                   gate_census={g: sum(1 for s in cand if s["gates"][g])
                                for g in ("upright", "no_ground",
                                          "clip_ok")})
        if passing:
            # A CELL THAT ALREADY READS RIGHT MUST NOT BE PRESCRIBED A CHANGE.
            # Pass 3 prescribed the BOW a move from (0,0,90) - the one carry
            # the team lead confirmed by eye - to (-90,0,0), because launchers
            # skip the upright gate so a horizontal bow "passed" and sorted
            # simpler. That is my SORT being wrong, not the bow. gear.gd's own
            # triple now wins every tie, and a grip shift alone is preferred
            # over a new rotation.
            passing.sort(key=lambda s: (s["triple"] != cur,
                                        s["grip_solved"],
                                        simplicity(tuple(s["triple"])),
                                        s["hang"], s["clip_frac"]))
            best = passing[0]
            rec["prescribed_triple"] = best["triple"]
            rec["prescribed_grip_x"] = best["grip_x"]
            rec["prescribed_score"] = best
            rec["changed"] = (best["triple"] != cur)
            rec["alternatives"] = [s["triple"] for s in passing[1:6]]
        else:
            near = sorted(cand, key=lambda s: (
                sum(1 for v in s["gates"].values() if not v),
                s["hang"], s["clip"]))[0]
            rec["prescribed_triple"] = None
            rec["best_near_miss"] = near
            rec["changed"] = False
            fails.append("%s: NO candidate of %d passes. Gate census %s "
                         "(clip_frac ceiling %.2f; gear.gd's own carry is "
                         "clip_frac %.3f). Best near miss %s: hang %.0f "
                         "clip_frac %.3f ground %d, failing %s. This row is RED."
                         % (kind, n, rec["gate_census"], CLIP_FRAC_MAX,
                            cur_s["clip_frac"], near["triple"], near["hang"],
                            near["clip_frac"], near["ground"],
                            [g for g, v in near["gates"].items() if not v]))
        rx[kind] = rec
        ps = rec.get("prescribed_score") or {}
        print("  RX %-13s cur=%s cf %.3f -> rot %s grip_x %s : hang %s "
              "cf %s ground %s  %s (cand %d pass %d)"
              % (kind, cur, cur_s["clip_frac"], rec["prescribed_triple"],
                 ps.get("grip_x"), ps.get("hang"), ps.get("clip_frac"),
                 ps.get("ground"),
                 "SAME-TRIPLE" if ps.get("triple") == cur else "RETURN",
                 n, len(passing)))
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)

    if not rx:
        raise SystemExit("RX FAIL - EMPTY PRESCRIPTION, nothing was searched.")
    if searched == 0:
        raise SystemExit("RX FAIL - zero candidates scored across all kinds.")

    out = dict(tool="_t5_rx", tier=a.tier, hero=hinfo,
               handslot=[round(v, 4) for v in slot],
               euler_order=order, hang_max=HANG_MAX,
               clip_frac_max=CLIP_FRAC_MAX,
               clip_frac_calibration="the BOW at gear.gd's shipped (0,0,90): "
                                     "451 of 1218 checked = 0.370, the one "
                                     "cell confirmed correct by eye",
               butt_drop=BUTT_DROP,
               grip_mechanism="gear.gd STAFF_GRIP_SHIFT: node.position.x -= v, "
                              "slot frame, slot +X is world DOWN",
               grid=dict(x=list(XS), y=list(YS), z=list(ZS)),
               candidates_scored=searched, bare_kinds=bare,
               fails=fails, ok=(not fails), rx=rx)
    jp = os.path.join(rxdir, "_t5_rx.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("RX_DONE %s  kinds=%d fails=%d scored=%d"
          % (jp, len(rx), len(fails), searched))
    for f in fails:
        print("  RXFAIL %s" % f)


if __name__ == "__main__":
    main()
