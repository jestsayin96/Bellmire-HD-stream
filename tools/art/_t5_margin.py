"""_t5_margin - CLOSING THE TWO TIER-5 CELLS THAT ONLY PROVE 2 OF 3 VIEWS.

The 19:58 CT plan row, 27 Nov 2026: eleven of the thirteen legendary carries
are closed; take the REMAINING TWO to a real posed body front/side/back and
close them by LOOKING. Measured off `_rx/_t5_rxproof.json`, not off any prompt,
the two are the only cells with `proving_views == 2`:

    dagger  vis front 1598 / side  567 / back 1219   (side under VIS_MIN 900)
    wand    vis front 1423 / side 1314 / back  790   (back under VIS_MIN 900)

MIN_PROVING is 2, so both score GREEN in the shipped register and neither is
in `blind_views`. THAT IS THE MARGIN, NOT A PASS: a gate set at two views
cannot tell a carry that reads from three angles from one that reads from two,
and the third view is a real viewer's real angle.

ONE VARIABLE PER SWEEP, DELIBERATELY. Three sweeps, each moving exactly one
number, each judged on its own render:

  A  dagger roll   : held_rot (0, y, 90), y in 0..65, hand_scale FIXED at the
                     0.60 the engine ships since S163. Scale is NOT re-opened.
  B  wand scale    : held_rot FIXED at the prescribed (0, 0, 90), hand_scale
                     swept 0.62 (engine) .. 1.20.
  C  wand roll     : at sweep B's CHOSEN scale, held_rot (0, y, 90), y in
                     20..50. Runs after B and names the scale it inherited.
  D  dagger grip   : held_rot and hand_scale both FIXED at the shipped values,
                     grip x swept 0 .. -0.30 m. ADDED AFTER SWEEP A FAILED,
                     and the reason is stated rather than hidden: A moved the
                     only lever I had thought of and the side view got WORSE
                     at every step, so reporting "the lever failed" without
                     trying the OTHER lever gear.gd already ships would have
                     been a half-answer. `position.x` in the slot frame is
                     that lever - gear.gd carries it today as
                     `STAFF_GRIP_SHIFT` - and the slot's +X is world DOWN, so
                     a NEGATIVE x RAISES the weapon in the fist and lifts the
                     blade clear of the pauldron that is eating it.

The roll term is the euler's `y` because Godot's YXZ basis is Ry * Rx * Rz with
Ry OUTERMOST, i.e. applied in the PARENT (slot) frame - so `y` is a roll about
the slot's own forward axis. That is the same mechanism gear.gd already ships
for the crossbow at (-90, 35, 90), derived there, re-used here, not invented.

GATES ARE THE SHIPPED ONES, NOT A KINDER SET - the same WF constants
artifactfit and _t5_rxproof use: blank, border alpha (frame clip), body-mask
`seen`, absolute `vis`, body clip, floor break, `show`.

RED ON EMPTY, EVERYWHERE: an arm whose mesh imports nothing, whose weapon
renders empty alone, whose `show` would be computed over no views, a sweep
with no arms, or a contact sheet with no opaque pixel is a FAIL ROW. It is
never a skipped cell and never a silent 1.0.

WHAT THIS TOOL CANNOT SEE, STATED BEFORE IT RUNS. `vis` counts pixels that
MOVED when the weapon was added, so it answers the viewer's question about
QUANTITY and says nothing about SHAPE: a wand scaled until a long dull shaft
clears the arm can gain hundreds of pixels and still read as a stick, and a
gem that doubles in size reads better at the same pixel count. The sheets are
written for exactly that question and the verdict is not final until they have
been looked at.
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

# The two cells at the margin, and the base triple each is measured against.
# dagger: (0,0,90) is what gear.gd SHIPS today (S163). wand: (0,0,90) is the
# PRESCRIPTION; the engine still returns Vector3.ZERO and lays it flat.
BASE = {"dagger": (0.0, 0.0, 90.0), "wand": (0.0, 0.0, 90.0)}
DAGGER_ROLLS = [0.0, 20.0, 35.0, 50.0, 65.0]
WAND_SCALES = [0.62, 0.80, 1.00, 1.20]
WAND_ROLLS = [20.0, 35.0, 50.0]
DAGGER_GRIPS = [0.0, -0.10, -0.20, -0.30]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier, "_margin")
    cells = os.path.join(outdir, "cells")
    tmpdir = os.path.join(outdir, "_tmp")
    sheetdir = os.path.join(outdir, "_sheets")
    for d in (cells, tmpdir, sheetdir):
        os.makedirs(d, exist_ok=True)

    tier_paths, _bare = AF.kinds_tier(a.gear, a.tier)
    for k in BASE:
        if k not in tier_paths:
            raise SystemExit("MARGIN FAIL - kind %r is not in the tier-%d set; "
                             "the tier moved under this tool." % (k, a.tier))

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    slot = base @ Vector((0, 0, 0))
    ST = AF.selftest_basis(a.gear, base)
    order = ST["euler_order"]
    print("MARGIN basis selftest PASSED order=%s" % order)

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
    assert body_trees, "no BVH from the body"
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    errors = []
    body_only = {}

    def score(kind, tag, deg, hs, gx=0.0):
        """Carry ONE arm to the hand, render three views, score the shipped
        gates. Returns a record; every failure mode is a row, never a skip."""
        res_path = tier_paths[kind]
        objs, _path = AF.load_res(a.repo, res_path)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            errors.append("%s/%s: no mesh from %s - FAIL" % (kind, tag, res_path))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            return None
        cr = GC.carry(a.gear, res_path)
        lv = WF.world_verts(meshes)
        if not lv:
            errors.append("%s/%s: zero vertices - FAIL" % (kind, tag))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            return None
        li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
        local_ext = sorted(li)
        laxis = li.index(max(li))
        Rslot = AF.slot_basis(list(deg), order)
        T = Matrix.Translation(Vector((gx, 0.0, 0.0)))
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ T @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = WF.world_verts(meshes)
        far = [v for v in wv if (v - slot).length > WF.FIST_R]
        if not far:
            errors.append("%s/%s: every vertex inside the fist - clip test "
                          "empty, nothing measured" % (kind, tag))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            return None
        n_clip = sum(1 for v in far if WF.inside(body_trees, v))
        n_ground = sum(1 for v in wv if v.z < -0.002)
        zs = [v.z for v in wv]
        lw = ((base @ Rslot).to_3x3() @ Vector(
            tuple(1.0 if i == laxis else 0.0 for i in range(3)))).normalized()
        hang = math.degrees(math.acos(min(1.0, max(-1.0,
                                                   abs(lw.dot(Vector((0, 0, 1))))))))
        world_long = max(li) * hs
        rec = dict(kind=kind, tag=tag, held_rot=list(deg), hand_scale=hs,
                   grip_x=gx,
                   engine_held_rot_deg=cr["held_rot_deg"],
                   engine_hand_scale=cr["hand_scale"],
                   verts=len(wv), checked=len(far), clip=n_clip,
                   clip_frac=round(n_clip / float(len(far)), 4),
                   ground=n_ground, floor_depth=round(max(0.0, -min(zs)), 4),
                   hang_deg_from_vertical=round(hang, 1),
                   world_long_m=round(world_long, 3),
                   frac_of_hero_h=round(world_long / float(hinfo["h"]), 3),
                   tip_z=round(max(zs), 3), reach=round(max(zs) - slot.z, 3))
        allpts = bpts + wv
        proving = 0
        for vname, az in WF.VIEWS:
            cam = WF.make_cam(az, cz, allpts)
            if vname not in body_only:
                WF.show(meshes, False)
                body_only[vname] = WF.render_to(
                    os.path.join(tmpdir, "_body_%s.png" % vname))
                WF.show(meshes, True)
            A = body_only[vname]
            png = os.path.join(cells, "%s_%s_%s.png" % (kind, tag, vname))
            B = WF.render_to(png)
            WF.show(body, False)
            Cim = WF.render_to(os.path.join(tmpdir, "_w_%s.png" % vname))
            WF.show(body, True)
            cm = Cim[:, :, 3] > WF.DIFF_EPS
            if int(cm.sum()) >= 2:
                cys, cxs = np.nonzero(cm)
                rec.setdefault("minor", {})[vname] = int(
                    min(cxs.max() - cxs.min() + 1, cys.max() - cys.min() + 1))
            op = int((B[:, :, 3] > WF.DIFF_EPS).sum())
            if op == 0:
                errors.append("%s/%s/%s: BLANK cell" % (kind, tag, vname))
            b = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                    float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
            changed = np.abs(B - A).max(axis=2) > WF.DIFF_EPS
            mask = Cim[:, :, 3] > WF.DIFF_EPS
            covered = int((changed & mask).sum())
            alone = int(mask.sum())
            if alone == 0:
                errors.append("%s/%s/%s: weapon renders EMPTY alone - `seen` "
                              "would be over nothing" % (kind, tag, vname))
                seen = 0.0
            else:
                seen = covered / float(alone)
            if seen >= WF.SEEN_MIN and covered >= WF.VIS_MIN:
                proving += 1
            rec.setdefault("opaque", {})[vname] = op
            rec.setdefault("border", {})[vname] = round(b, 4)
            rec.setdefault("vis", {})[vname] = covered
            rec.setdefault("seen", {})[vname] = round(seen, 4)
            bpy.data.objects.remove(cam, do_unlink=True)
        mins = rec.get("minor", {})
        mid_px = local_ext[1] * hs * WF.PX_PER_M
        rec["mid_px"] = round(mid_px, 1)
        if mid_px <= 1.0 or not mins:
            errors.append("%s/%s: cannot compute `show` (mid_px %.2f over %d "
                          "views) - FAIL, not a 1.0" % (kind, tag, mid_px, len(mins)))
        else:
            rec["best_minor"] = max(mins.values())
            rec["show"] = round(rec["best_minor"] / mid_px, 3)
        rec["proving_views"] = proving
        rec["min_vis"] = min(rec["vis"].values())
        rec["max_border"] = max(rec["border"].values())
        rec["frame_clip"] = rec["max_border"] > WF.DIFF_EPS
        rec["floor_break"] = n_ground > 0
        rec["lath"] = bool(rec.get("show") is not None
                           and rec["show"] < WF.SHOW_MIN)
        rec["clean"] = (not rec["frame_clip"] and not rec["floor_break"]
                        and not rec["lath"])
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
        print("  ARM %-7s %-16s rot=%s hs=%.2f hang=%.1f clipf=%.3f "
              "gx=%+.2f vis=%s proving=%d show=%s border=%.3f long=%.2fm"
              % (kind, tag, tuple(deg), hs, hang, rec["clip_frac"], gx,
                 [rec["vis"][v] for v, _ in WF.VIEWS], proving,
                 rec.get("show"), rec["max_border"], world_long))
        return rec

    sweeps = {}

    # ---- SWEEP A: the dagger's roll. hand_scale is the shipped 0.60, fixed.
    hs_dag = GC.carry(a.gear, tier_paths["dagger"])["hand_scale"]
    A_arms = []
    for y in DAGGER_ROLLS:
        r = score("dagger", "rollY%03d" % int(y),
                  (BASE["dagger"][0], y, BASE["dagger"][2]), hs_dag)
        if r:
            A_arms.append(r)
    if not A_arms:
        errors.append("SWEEP A produced NO arms - an empty sweep is a FAIL")
    sweeps["A_dagger_roll"] = dict(
        variable="held_rot y (roll about the slot's forward axis)",
        fixed=dict(hand_scale=hs_dag, held_rot_xz=[BASE["dagger"][0],
                                                   BASE["dagger"][2]]),
        arms=A_arms)

    # ---- SWEEP B: the wand's hand_scale. held_rot fixed at the prescription.
    B_arms = []
    for hs in WAND_SCALES:
        r = score("wand", "hs%03d" % int(round(hs * 100)), BASE["wand"], hs)
        if r:
            B_arms.append(r)
    if not B_arms:
        errors.append("SWEEP B produced NO arms - an empty sweep is a FAIL")
    # THE CHOICE RULE, STATED BEFORE IT IS APPLIED: the SMALLEST hand_scale
    # whose WORST view clears VIS_MIN with no frame clip, no floor break and
    # no lath. Smallest, because a legendary wand that has to be grown into a
    # staff to be seen is a different weapon, not a fixed one.
    chosen = None
    for r in sorted(B_arms, key=lambda r: r["hand_scale"]):
        if r["min_vis"] >= WF.VIS_MIN and r["clean"]:
            chosen = r
            break
    sweeps["B_wand_scale"] = dict(
        variable="hand_scale",
        fixed=dict(held_rot=list(BASE["wand"])),
        rule="smallest hand_scale with min(vis) >= VIS_MIN and no frame clip, "
             "floor break or lath",
        chosen=(chosen["tag"] if chosen else None),
        chosen_hand_scale=(chosen["hand_scale"] if chosen else None),
        arms=B_arms)

    # ---- SWEEP C: the wand's roll AT SWEEP B's chosen scale.
    C_arms = []
    hs_c = chosen["hand_scale"] if chosen else None
    if hs_c is None:
        errors.append("SWEEP C NOT RUN - sweep B cleared VIS_MIN at no scale, "
                      "so there is no scale to roll at. This is a reported "
                      "RED, not a skipped sweep.")
    else:
        for y in WAND_ROLLS:
            r = score("wand", "hs%03d_rollY%03d" % (int(round(hs_c * 100)), int(y)),
                      (BASE["wand"][0], y, BASE["wand"][2]), hs_c)
            if r:
                C_arms.append(r)
        if not C_arms:
            errors.append("SWEEP C produced NO arms - an empty sweep is a FAIL")
    sweeps["C_wand_roll"] = dict(
        variable="held_rot y (roll about the slot's forward axis)",
        fixed=dict(hand_scale=hs_c, held_rot_xz=[BASE["wand"][0], BASE["wand"][2]]),
        inherited_from="B_wand_scale",
        arms=C_arms)

    # ---- SWEEP D: the dagger's grip shift. rot and scale BOTH fixed at the
    # shipped values; the only thing that moves is where the blade sits in the
    # fist. See the docstring for why this sweep exists at all.
    D_arms = []
    for gx in DAGGER_GRIPS:
        r = score("dagger", "gx%03d" % int(round(abs(gx) * 100)),
                  BASE["dagger"], hs_dag, gx)
        if r:
            D_arms.append(r)
    if not D_arms:
        errors.append("SWEEP D produced NO arms - an empty sweep is a FAIL")
    sweeps["D_dagger_grip"] = dict(
        variable="grip x (slot-frame offset; slot +X is world DOWN, so "
                 "negative RAISES the blade in the fist)",
        fixed=dict(hand_scale=hs_dag, held_rot=list(BASE["dagger"])),
        arms=D_arms)

    # ---- contact sheets. ONE PER VIEW PER SWEEP, the honest flip idiom:
    # each cell is flipped to top-down on load and the whole sheet is flipped
    # back on write, so the row order a human reads matches the printed order.
    sheets = {}
    for sname, sw in sweeps.items():
        for vname, _az in WF.VIEWS:
            arms = sw["arms"]
            if not arms:
                errors.append("sheet %s/%s: NO cells - an empty sheet is a "
                              "FAIL" % (sname, vname))
                continue
            arrs, labels = [], []
            for r in arms:
                p = os.path.join(cells, "%s_%s_%s.png"
                                 % (r["kind"], r["tag"], vname))
                im = bpy.data.images.load(p, check_existing=False)
                w, h = im.size
                arrs.append(np.array(im.pixels[:], dtype=np.float32
                                     ).reshape(h, w, 4)[::-1])
                bpy.data.images.remove(im)
                labels.append(r["tag"])
            q = 2
            ch, cw = arrs[0].shape[0] // q, arrs[0].shape[1] // q
            cols = len(arrs)
            sh = np.zeros((ch, cols * cw, 4), dtype=np.float32)
            for i, arr in enumerate(arrs):
                s = arr[::q, ::q, :][:ch, :cw, :]
                sh[:s.shape[0], i * cw:i * cw + s.shape[1], :] = s
            if float(sh[:, :, 3].max()) <= WF.DIFF_EPS:
                errors.append("sheet %s/%s is BLANK - FAIL" % (sname, vname))
            p = os.path.join(sheetdir, "%s_%s.png" % (sname, vname))
            o = bpy.data.images.new("s_%s_%s" % (sname, vname),
                                    sh.shape[1], sh.shape[0], alpha=True)
            o.pixels = sh[::-1].reshape(-1)
            o.filepath_raw = p
            o.file_format = 'PNG'
            o.save()
            sheets["%s/%s" % (sname, vname)] = p
            print("  SHEET %s %s  left-to-right=%s" % (sname, vname, ",".join(labels)))

    n_arms = sum(len(s["arms"]) for s in sweeps.values())
    if n_arms == 0:
        raise SystemExit("MARGIN FAIL - EMPTY REGISTER, nothing measured.")
    ok = not errors
    out = dict(verdict="GREEN" if ok else "FAIL", ok=ok, tool="_t5_margin",
               tier=a.tier, hero=hinfo, handslot=[round(v, 4) for v in slot],
               euler_order=order, basis_selftest=ST,
               seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN,
               show_min=WF.SHOW_MIN, min_proving=WF.MIN_PROVING,
               px_per_m=WF.PX_PER_M, views=[v for v, _ in WF.VIEWS],
               arms=n_arms, sheets=sheets, errors=errors, sweeps=sweeps)
    jp = os.path.join(outdir, "_t5_margin.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("MARGIN_DONE %s verdict=%s arms=%d errors=%d"
          % (jp, out["verdict"], n_arms, len(errors)))
    for e in errors:
        print("  ERR %s" % e)


if __name__ == "__main__":
    main()
