"""_t5_rxproof - THE PROVING RENDER FOR THE TIER-5 PRESCRIPTION.

A prescription nobody has looked at is a guess with arithmetic on it. This file
reads `_rx/_t5_rx.json`, carries every legendary weapon to the real posed hand
AT THE PRESCRIBED TRIPLE AND GRIP SHIFT, renders front/side/back on the body,
re-runs the SHIPPED acceptance gates (blank, border, seen-against-body-only,
lance, floor, show) and composites three contact sheets to be LOOKED AT.

IT IS THE SAME GATES AS artifactfit, DELIBERATELY. A prescription scored by a
kinder instrument than the one that found the red is not a fix.

RED ON EMPTY: a kind with no prescription, a mesh that imports nothing, a
weapon that renders empty alone, or a `show` computed over no views is a FAIL
ROW. An empty sheet is a FAIL, not a pass.
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


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier)
    rxdir = os.path.join(outdir, "_rx")
    cells = os.path.join(rxdir, "cells")
    tmpdir = os.path.join(rxdir, "_tmp")
    for d in (cells, tmpdir):
        os.makedirs(d, exist_ok=True)
    with open(os.path.join(rxdir, "_t5_rx.json"), encoding="utf-8") as fh:
        RX = json.load(fh)
    if not RX.get("rx"):
        raise SystemExit("RXPROOF FAIL - empty prescription, nothing to prove.")

    tier_paths, bare = AF.kinds_tier(a.gear, a.tier)
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
    print("RXPROOF basis selftest PASSED order=%s" % order)

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

    reg, errors, blanks, clipped, blind, laths = {}, [], [], [], [], []
    floor_breaks, lances, body_only, imgs = [], [], {}, {}

    for kind in sorted(tier_paths):
        rxk = RX["rx"].get(kind)
        if not rxk or not rxk.get("prescribed_triple"):
            errors.append("%s: NO PRESCRIPTION - FAIL, not a skipped cell" % kind)
            continue
        res_path = tier_paths[kind]
        deg = [float(d) for d in rxk["prescribed_triple"]]
        gx = float(rxk.get("prescribed_grip_x") or 0.0)
        objs, path = AF.load_res(a.repo, res_path)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            errors.append("%s: no mesh from %s - FAIL" % (kind, res_path))
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            continue
        cr = GC.carry(a.gear, res_path)
        hs = cr["hand_scale"]
        lv = WF.world_verts(meshes)
        if not lv:
            errors.append("%s: zero vertices - FAIL" % kind)
            continue
        local_ext = sorted([max(v[i] for v in lv) - min(v[i] for v in lv)
                            for i in range(3)])
        li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
        laxis = li.index(max(li))
        Rslot = AF.slot_basis(deg, order)
        T = Matrix.Translation(Vector((gx, 0.0, 0.0)))
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ T @ Rslot @ S @ o.matrix_world
        bpy.context.view_layer.update()
        wv = WF.world_verts(meshes)
        far = [v for v in wv if (v - slot).length > WF.FIST_R]
        if not far:
            errors.append("%s: every vertex inside the fist - clip test empty" % kind)
            continue
        n_clip = sum(1 for v in far if WF.inside(body_trees, v))
        n_ground = sum(1 for v in wv if v.z < -0.002)
        zs = [v.z for v in wv]
        lw = ((base @ Rslot).to_3x3() @ Vector(
            tuple(1.0 if i == laxis else 0.0 for i in range(3)))).normalized()
        hang = math.degrees(math.acos(min(1.0, max(-1.0,
                                                   abs(lw.dot(Vector((0, 0, 1))))))))
        aspect = max(li) / max(1e-6, sorted(li)[1])
        rec = dict(kind=kind, model=res_path, prescribed=deg, grip_x=gx,
                   hand_scale=hs, verts=len(wv), checked=len(far),
                   clip=n_clip, clip_frac=round(n_clip / float(len(far)), 4),
                   ground=n_ground,
                   floor_depth=round(max(0.0, -min(zs)), 4),
                   hang_deg_from_vertical=round(hang, 1),
                   aspect=round(aspect, 2), tip_z=round(max(zs), 3),
                   reach=round(max(zs) - slot.z, 3),
                   drop=round(slot.z - min(zs), 3))
        if n_ground:
            floor_breaks.append("%s: %d verts below the floor, deepest %.3f m"
                                % (kind, n_ground, rec["floor_depth"]))
        if aspect >= 2.0 and kind not in ("bow", "crossbow") and hang > 60.0:
            lances.append("%s: long axis %.0f deg from vertical - STILL A LANCE"
                          % (kind, hang))

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
            png = os.path.join(cells, "%s_%s.png" % (kind, vname))
            B = WF.render_to(png)
            imgs.setdefault(vname, {})[kind] = B
            WF.show(body, False)
            Cim = WF.render_to(os.path.join(tmpdir, "_w_%s_%s.png" % (kind, vname)))
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
                clipped.append(os.path.basename(png))
            changed = np.abs(B - A).max(axis=2) > WF.DIFF_EPS
            mask = Cim[:, :, 3] > WF.DIFF_EPS
            covered = int((changed & mask).sum())
            alone = int(mask.sum())
            if alone == 0:
                errors.append("%s/%s: weapon renders EMPTY alone - seen would "
                              "be over nothing" % (kind, vname))
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
        mid_px = local_ext[1] * hs * WF.PX_PER_M
        mins = rec.get("minor", {})
        rec["mid_px"] = round(mid_px, 1)
        if mid_px <= 1.0 or not mins:
            errors.append("%s: cannot compute `show` (mid_px %.2f over %d views)"
                          " - FAIL, not a 1.0" % (kind, mid_px, len(mins)))
        else:
            rec["best_minor"] = max(mins.values())
            rec["show"] = round(rec["best_minor"] / mid_px, 3)
            if rec["show"] < WF.SHOW_MIN:
                laths.append("%s: show %.2f - the carry never shows its broad "
                             "face" % (kind, rec["show"]))
        rec["proving_views"] = proving
        if proving < WF.MIN_PROVING:
            blind.append("%s: only %d of %d views show the weapon"
                         % (kind, proving, len(WF.VIEWS)))
        reg[kind] = rec
        print("  PROOF %-13s rot=%s gx=%+.3f hang=%.1f clip=%d/%d cf=%.3f "
              "ground=%d show=%s proving=%d border=%s"
              % (kind, deg, gx, hang, n_clip, len(far), rec["clip_frac"],
                 n_ground, rec.get("show"), proving,
                 max(rec["border"].values())))
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)

    if not reg:
        raise SystemExit("RXPROOF FAIL - EMPTY REGISTER, nothing proved.")
    if len(reg) != len(tier_paths):
        errors.append("register has %d of %d cells" % (len(reg), len(tier_paths)))

    # contact sheets - one per view, downscaled 4x, LOOKED AT after this run.
    sheetdir = os.path.join(rxdir, "_sheets")
    os.makedirs(sheetdir, exist_ok=True)
    sheets = {}
    for vname, _az in WF.VIEWS:
        d = imgs.get(vname, {})
        if not d:
            errors.append("sheet %s: NO cells - an empty sheet is a FAIL" % vname)
            continue
        ks = sorted(d)
        q = 4
        ch, cw = WF.CELL_Y // q, WF.CELL_X // q
        cols = 5
        rows = int(math.ceil(len(ks) / float(cols)))
        sh = np.zeros((rows * ch, cols * cw, 4), dtype=np.float32)
        for i, k in enumerate(ks):
            small = d[k][::q, ::q, :]
            r, c = divmod(i, cols)
            sh[r * ch:r * ch + small.shape[0],
               c * cw:c * cw + small.shape[1], :] = small[:ch, :cw, :]
        if float(sh[:, :, 3].max()) <= WF.DIFF_EPS:
            errors.append("sheet %s is BLANK - FAIL" % vname)
        p = os.path.join(sheetdir, "rx_%s.png" % vname)
        im = bpy.data.images.new("sh_" + vname, sh.shape[1], sh.shape[0],
                                 alpha=True)
        # *** THE FLIP, FOUND BY LOOKING, 17:52 CT. ***
        # My first sheet wrote `sh[::-1]` and every knight on it came out
        # UPSIDE DOWN, while the cell PNGs Blender saved straight to disk were
        # upright. WF.render_to already returns a TOP-DOWN array, so the extra
        # reverse inverted each cell. A contact sheet that turns the figure
        # over is exactly the instrument that would make a good carry read as
        # a bad one - the cells are the evidence, the sheet was the suspect.
        im.pixels = sh.reshape(-1)
        im.filepath_raw = p
        im.file_format = 'PNG'
        im.save()
        sheets[vname] = p
        print("  SHEET %s %s  order=%s" % (vname, p, ",".join(ks)))

    ok = (not errors and not blanks and not clipped and not blind
          and not laths and not floor_breaks and not lances)
    out = dict(verdict="GREEN" if ok else "FAIL", ok=ok, tool="_t5_rxproof",
               tier=a.tier, hero=hinfo, handslot=[round(v, 4) for v in slot],
               cells=len(reg), views=[v for v, _ in WF.VIEWS],
               euler_order=order, basis_selftest=ST,
               seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN, show_min=WF.SHOW_MIN,
               min_proving=WF.MIN_PROVING, px_per_m=WF.PX_PER_M,
               sheets=sheets, laths=laths, floor_breaks=floor_breaks,
               lances=lances, blanks=blanks, frame_clips=clipped,
               blind_views=blind, errors=errors, models=reg)
    jp = os.path.join(rxdir, "_t5_rxproof.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("RXPROOF_DONE %s verdict=%s blanks=%d frameclips=%d blind=%d "
          "laths=%d floor=%d lances=%d errors=%d"
          % (jp, out["verdict"], len(blanks), len(clipped), len(blind),
             len(laths), len(floor_breaks), len(lances), len(errors)))
    for nm, lst in (("ERR", errors), ("BLANK", blanks), ("FRAMECLIP", clipped),
                    ("BLIND", blind), ("LATH", laths),
                    ("FLOOR", floor_breaks), ("LANCE", lances)):
        for x in lst:
            print("  %s %s" % (nm, x))


if __name__ == "__main__":
    main()
