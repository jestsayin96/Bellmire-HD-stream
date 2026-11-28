"""_t5_dagread - WHY THE LEGENDARY DAGGER READS BLIND, AND WHICH FIX IS HONEST.

THE RED THIS CLOSES. `_t5_rxproof.json` carries exactly one residual:
`blind_views: ["dagger: only 1 of 3 views show the weapon"]`. The carry is
geometrically right (hang 0.1 deg, no ground, clip_frac 0.35 under the 0.37
ceiling) and the weapon still fails WF.VIS_MIN on front (403 px) and back
(190 px) against a 900 px floor. The team lead LOOKED at `rx_front.png` and
confirmed the front cell reads empty, so the fault is real and not the gate.

WHY THIS TOOL EXISTS RATHER THAN A ONE-LINE EDIT. My own prescription last
hour was `hand_scale 0.5 -> ~0.75`. That number buys pixels by making the
object BIGGER, and gear.gd:304 records the golden dagger's .blend length as
1.39 m - so 0.5 carries a 0.69 m blade and 0.75 carries a 1.04 m one, which
is a short sword, not a dagger. Mr. E's rule is that things look like what
they are FOR. Meanwhile the register's own numbers say the front view sees
the THIN EDGE: `minor` front 13 px against side 32 px at the same scale. A
weapon photographed edge-on is the exact fault WF.VIS_MIN's comment was
written about. So there are two candidate fixes and they are not equivalent:
  (A) scale it up  - more pixels, wrong object.
  (B) turn its broad face to the viewer - same object, more pixels.
This tool MEASURES BOTH on the real posed body through the shipped gates and
lets the pictures decide, instead of applying the number I guessed.

ONLY held_rot TRIPLES ARE SEARCHED, DELIBERATELY. A world-space spin about
the hand would read better and be unprescribable: the engine applies a
held_rot Vector3, so a fix it cannot express is not a fix.

RED ON EMPTY: no candidate, no mesh, a weapon that renders empty alone, or a
`show` over no views is a FAIL row, not a skipped one.
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

KIND = "dagger"
GRID = [-90.0, 0.0, 90.0, 180.0]
HANG_MAX = 15.0          # _t5_rx.json: "upright" gate
CLIP_FRAC_MAX = 0.37     # _t5_rx.json clip_frac_max, calibrated there
HS_SWEEP = [0.6, 0.7, 0.75, 0.8, 0.9]


def place(objs, rest, base, Rslot, gx, hs):
    """Re-place from the IMPORTED rest matrix every time.

    rxproof multiplies into `o.matrix_world` once per kind and then throws the
    object away. This tool re-places the same object dozens of times, so a
    cumulative multiply would compound every earlier candidate into the next
    one and every number after the first would be of a pose nobody chose.
    """
    T = Matrix.Translation(Vector((gx, 0.0, 0.0)))
    S = Matrix.Diagonal((hs,) * 3).to_4x4()
    for o in objs:
        if o.parent is None:
            o.matrix_world = base @ T @ Rslot @ S @ rest[o.name]
    bpy.context.view_layer.update()


def geom(meshes, body_trees, slot, base, Rslot, laxis):
    wv = WF.world_verts(meshes)
    if not wv:
        return None
    far = [v for v in wv if (v - slot).length > WF.FIST_R]
    if not far:
        return None
    n_clip = sum(1 for v in far if WF.inside(body_trees, v))
    zs = [v.z for v in wv]
    lw = ((base @ Rslot).to_3x3() @ Vector(
        tuple(1.0 if i == laxis else 0.0 for i in range(3)))).normalized()
    hang = math.degrees(math.acos(min(1.0, max(-1.0,
                                               abs(lw.dot(Vector((0, 0, 1))))))))
    ext = [max(v[i] for v in wv) - min(v[i] for v in wv) for i in range(3)]
    return dict(verts=len(wv), checked=len(far), clip=n_clip,
                clip_frac=round(n_clip / float(len(far)), 4),
                ground=sum(1 for v in wv if v.z < -0.002),
                floor_depth=round(max(0.0, -min(zs)), 4),
                hang_deg_from_vertical=round(hang, 1),
                tip_z=round(max(zs), 3), drop=round(slot.z - min(zs), 3),
                world_len_m=round(max(ext), 4),
                key=tuple(round(c, 3) for v in (
                    min(wv, key=lambda p: p.x), max(wv, key=lambda p: p.x),
                    min(wv, key=lambda p: p.z), max(wv, key=lambda p: p.z))
                    for c in (v.x, v.y, v.z)))


def measure(meshes, body, bpts, cz, body_only, cams, tag, cells, mid_px):
    """The SHIPPED gates: vis, seen, border, blank, minor, show, proving."""
    rec = dict(minor={}, opaque={}, border={}, vis={}, seen={})
    proving, errs, blanks, clips = 0, [], [], []
    wv = WF.world_verts(meshes)
    for vname, az in WF.VIEWS:
        cam = WF.make_cam(az, cz, bpts + wv)
        # MY OWN CHECK: the cached body frame is only comparable if the camera
        # is config-independent. Position/rotation/ortho_scale must match the
        # frame the body was shot in, or `changed` measures the camera.
        sig = (tuple(round(c, 6) for c in cam.location),
               tuple(round(c, 6) for c in cam.rotation_euler),
               round(cam.data.ortho_scale, 6))
        if vname in cams:
            assert sig == cams[vname], (
                "DAGREAD FAIL - camera moved between configs on %s: %r vs %r"
                % (vname, sig, cams[vname]))
        else:
            cams[vname] = sig
        if vname not in body_only:
            WF.show(meshes, False)
            body_only[vname] = WF.render_to(
                os.path.join(cells, "_body_%s.png" % vname))
            WF.show(meshes, True)
        A = body_only[vname]
        png = os.path.join(cells, "%s_%s_%s.png" % (KIND, tag, vname))
        B = WF.render_to(png)
        WF.show(body, False)
        Cim = WF.render_to(os.path.join(cells, "_alone_%s_%s.png" % (tag, vname)))
        WF.show(body, True)
        cm = Cim[:, :, 3] > WF.DIFF_EPS
        if int(cm.sum()) >= 2:
            cys, cxs = np.nonzero(cm)
            rec["minor"][vname] = int(min(cxs.max() - cxs.min() + 1,
                                          cys.max() - cys.min() + 1))
        op = int((B[:, :, 3] > WF.DIFF_EPS).sum())
        if op == 0:
            blanks.append(os.path.basename(png))
        b = max(float(B[0, :, 3].max()), float(B[-1, :, 3].max()),
                float(B[:, 0, 3].max()), float(B[:, -1, 3].max()))
        if b > WF.DIFF_EPS:
            clips.append(os.path.basename(png))
        changed = np.abs(B - A).max(axis=2) > WF.DIFF_EPS
        alone = int(cm.sum())
        covered = int((changed & cm).sum())
        if alone == 0:
            errs.append("%s/%s: weapon renders EMPTY alone" % (tag, vname))
            seen = 0.0
        else:
            seen = covered / float(alone)
        if seen >= WF.SEEN_MIN and covered >= WF.VIS_MIN:
            proving += 1
        rec["opaque"][vname] = op
        rec["border"][vname] = round(b, 4)
        rec["vis"][vname] = covered
        rec["seen"][vname] = round(seen, 4)
        rec["cell_%s" % vname] = png
        bpy.data.objects.remove(cam, do_unlink=True)
    rec["proving_views"] = proving
    rec["blanks"], rec["frame_clips"], rec["errors"] = blanks, clips, errs
    if mid_px <= 1.0 or not rec["minor"]:
        rec["errors"].append("cannot compute show (mid_px %.2f over %d views)"
                             % (mid_px, len(rec["minor"])))
    else:
        rec["best_minor"] = max(rec["minor"].values())
        rec["mid_px"] = round(mid_px, 1)
        rec["show"] = round(rec["best_minor"] / mid_px, 3)
        rec["lath"] = rec["show"] < WF.SHOW_MIN
    rec["blind"] = proving < WF.MIN_PROVING
    return rec


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier, "_rx",
                          "_dagread")
    cells = os.path.join(outdir, "cells")
    os.makedirs(cells, exist_ok=True)

    tier_paths, _bare = AF.kinds_tier(a.gear, a.tier)
    res_path = tier_paths[KIND]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    slot = base @ Vector((0, 0, 0))
    ST = AF.selftest_basis(a.gear, base)
    order = ST["euler_order"]
    print("DAGREAD basis selftest PASSED order=%s" % order, flush=True)

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

    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH from the body"
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    objs, path = AF.load_res(a.repo, res_path)
    meshes = [o for o in objs if o.type == 'MESH']
    assert meshes, "DAGREAD FAIL - no mesh from %s" % res_path
    rest = {o.name: o.matrix_world.copy() for o in objs}
    cr = GC.carry(a.gear, res_path)
    hs_engine = cr["hand_scale"]
    lv = WF.world_verts(meshes)
    li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
    laxis = li.index(max(li))
    local_ext = sorted(li)
    print("DAGREAD engine carry hand_scale=%s arm=%s local_ext=%s"
          % (hs_engine, cr["hand_scale_arm"], [round(x, 4) for x in local_ext]),
          flush=True)

    # ---- STAGE 1: geometry only, every held_rot triple on the 90-deg grid ----
    passing, seen_keys = [], {}
    for x in GRID:
        for y in GRID:
            for z in GRID:
                deg = [x, y, z]
                Rslot = AF.slot_basis(deg, order)
                place(objs, rest, base, Rslot, 0.0, hs_engine)
                gm = geom(meshes, body_trees, slot, base, Rslot, laxis)
                if gm is None:
                    continue
                ok = (gm["hang_deg_from_vertical"] <= HANG_MAX
                      and gm["ground"] == 0
                      and gm["clip_frac"] <= CLIP_FRAC_MAX)
                if not ok:
                    continue
                k = gm.pop("key")
                if k in seen_keys:
                    seen_keys[k]["same_geometry_triples"].append(deg)
                    continue
                gm["triple"] = deg
                gm["same_geometry_triples"] = [deg]
                seen_keys[k] = gm
                passing.append(gm)
    print("DAGREAD stage1 %d of %d triples pass geometry, %d distinct geometries"
          % (sum(len(g["same_geometry_triples"]) for g in passing),
             len(GRID) ** 3, len(passing)), flush=True)
    assert passing, "DAGREAD FAIL - NO triple passes geometry. Red on empty."

    # ---- STAGE 2: render every distinct passing geometry at the ENGINE scale --
    body_only, cams, results = {}, {}, []
    mid_px_engine = local_ext[1] * hs_engine * WF.PX_PER_M
    for i, gm in enumerate(passing):
        deg = gm["triple"]
        Rslot = AF.slot_basis(deg, order)
        place(objs, rest, base, Rslot, 0.0, hs_engine)
        tag = "t%+04d%+04d%+04d_hs%03d" % (deg[0], deg[1], deg[2],
                                           round(hs_engine * 100))
        rec = measure(meshes, body, bpts, cz, body_only, cams, tag, cells,
                      mid_px_engine)
        rec.update(arm="B_face", triple=deg, hand_scale=hs_engine,
                   **{k: v for k, v in gm.items() if k != "triple"})
        results.append(rec)
        print("  FACE %-22s hs=%.2f hang=%4.1f len=%.3f cf=%.3f vis=%s "
              "proving=%d show=%s border=%.3f"
              % (deg, hs_engine, gm["hang_deg_from_vertical"],
                 gm["world_len_m"], gm["clip_frac"], rec["vis"],
                 rec["proving_views"], rec.get("show"),
                 max(rec["border"].values())), flush=True)

    # ---- STAGE 3: the prescribed triple, hand_scale sweep (my own guess) -----
    with open(os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier,
                           "_rx", "_t5_rx.json"), encoding="utf-8") as fh:
        RX = json.load(fh)
    pres = [float(d) for d in RX["rx"][KIND]["prescribed_triple"]]
    gx = float(RX["rx"][KIND].get("prescribed_grip_x") or 0.0)
    for hs in HS_SWEEP:
        Rslot = AF.slot_basis(pres, order)
        place(objs, rest, base, Rslot, gx, hs)
        gm = geom(meshes, body_trees, slot, base, Rslot, laxis)
        assert gm is not None, "DAGREAD FAIL - prescribed triple has no geometry"
        gm.pop("key")
        tag = "pres_hs%03d" % round(hs * 100)
        rec = measure(meshes, body, bpts, cz, body_only, cams, tag, cells,
                      local_ext[1] * hs * WF.PX_PER_M)
        rec.update(arm="A_scale", triple=pres, hand_scale=hs, **gm)
        results.append(rec)
        print("  SCALE hs=%.2f hang=%4.1f len=%.3f cf=%.3f ground=%d vis=%s "
              "proving=%d show=%s border=%.3f"
              % (hs, gm["hang_deg_from_vertical"], gm["world_len_m"],
                 gm["clip_frac"], gm["ground"], rec["vis"],
                 rec["proving_views"], rec.get("show"),
                 max(rec["border"].values())), flush=True)

    clean = [r for r in results
             if r["proving_views"] >= WF.MIN_PROVING and not r["blanks"]
             and not r["frame_clips"] and not r["errors"] and not r.get("lath")
             and r["ground"] == 0 and r["clip_frac"] <= CLIP_FRAC_MAX
             and r["hang_deg_from_vertical"] <= HANG_MAX]
    # Prefer a fix that does NOT change the object's size, then the one with
    # the most proving views, then the smallest blade.
    clean.sort(key=lambda r: (r["arm"] != "B_face", -r["proving_views"],
                              r["world_len_m"]))
    out = dict(tool="_t5_dagread", tier=a.tier, kind=KIND, model=res_path,
               hero=hinfo, handslot=[round(v, 4) for v in slot],
               euler_order=order, basis_selftest=ST,
               engine_hand_scale=hs_engine,
               engine_hand_scale_arm=cr["hand_scale_arm"],
               gates=dict(seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN,
                          show_min=WF.SHOW_MIN, min_proving=WF.MIN_PROVING,
                          hang_max=HANG_MAX, clip_frac_max=CLIP_FRAC_MAX,
                          px_per_m=WF.PX_PER_M),
               local_ext=[round(x, 4) for x in local_ext],
               prescribed_triple_before=pres,
               candidates=len(results), clean=len(clean),
               recommended=(clean[0] if clean else None),
               results=results)
    jp = os.path.join(outdir, "_t5_dagread.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    r0 = clean[0] if clean else None
    print("DAGREAD_DONE %s candidates=%d clean=%d" % (jp, len(results), len(clean)),
          flush=True)
    if r0 is None:
        print("  DAGREAD NO CLEAN CANDIDATE - the red stands and I will say so.",
              flush=True)
    else:
        print("  DAGREAD RECOMMEND arm=%s triple=%s hand_scale=%.2f len=%.3f m "
              "vis=%s proving=%d show=%s"
              % (r0["arm"], r0["triple"], r0["hand_scale"], r0["world_len_m"],
                 r0["vis"], r0["proving_views"], r0.get("show")), flush=True)


if __name__ == "__main__":
    main()
