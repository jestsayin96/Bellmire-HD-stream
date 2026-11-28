"""_t5_dagface - THE CARRY THAT TURNS THE BLADE'S FACE TO THE FRONT CAMERA.

WHAT MY OWN FIRST TWO TOOLS MISSED, AND IT WAS MY FILTER THAT MISSED IT.
`_t5_dagread` stage 1 filtered the 90-degree grid on hang <= 15, ground == 0
AND clip_frac <= 0.37, then deduped. It reported "1 distinct geometry" and I
wrote that a front-facing carry was NOT REACHABLE. That conclusion was wrong
and the filter is why: `_t5_dagcensus`, which filters NOTHING, finds 24
upright triples of which EIGHT put the broad local axis along world X - the
face the front and back cameras see. The best of them, (0, 0, 90), misses the
clip ceiling by 1.4 points: clip_frac 0.384 against 0.370. My tool threw it
away without printing it, which is how a search tells you something does not
exist when what happened is that you did not look at it.

(0, 0, 90) is also the triple gear.gd already ships for the bow, the one cell
the team lead confirmed correct BY EYE.

WHY A SCALE BUMP MAY CARRY IT ANYWAY. clip_frac is verts-inside-body over
verts-outside-the-fist, and it FALLS as the weapon grows: the prescribed
carry runs 0.352 at hand_scale 0.50 and 0.289 at 0.75. So a face-front carry
at a modest bump may clear the same ceiling the edge-on carry clears, while
showing a blade instead of a hairline. That is the one combination neither
earlier tool tested, and it is the only candidate that buys READABILITY
rather than LENGTH.

Same shipped gates as rxproof. RED ON EMPTY.
"""
import os, sys, json, argparse
import bpy
from mathutils import Vector, bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402
import gearcarry as GC         # noqa: E402
import artifactfit as AF       # noqa: E402
import _t5_dagread as DR       # noqa: E402

FACE_TRIPLES = [[0.0, 0.0, 90.0], [180.0, 180.0, 90.0],
                [0.0, 180.0, 90.0], [180.0, 0.0, -90.0]]
HS = [0.5, 0.55, 0.6, 0.65, 0.7]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier, "_rx",
                          "_dagface")
    cells = os.path.join(outdir, "cells")
    os.makedirs(cells, exist_ok=True)

    tier_paths, _b = AF.kinds_tier(a.gear, a.tier)
    res_path = tier_paths[DR.KIND]
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
    print("DAGFACE basis selftest PASSED order=%s" % order, flush=True)

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
    _mn, _mx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    objs, _p = AF.load_res(a.repo, res_path)
    meshes = [o for o in objs if o.type == 'MESH']
    assert meshes, "DAGFACE FAIL - no mesh"
    rest = {o.name: o.matrix_world.copy() for o in objs}
    hs_engine = GC.carry(a.gear, res_path)["hand_scale"]
    lv = WF.world_verts(meshes)
    li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
    laxis = li.index(max(li))
    local_ext = sorted(li)

    body_only, cams, results = {}, {}, []
    for deg in FACE_TRIPLES:
        for hs in HS:
            Rslot = AF.slot_basis(deg, order)
            DR.place(objs, rest, base, Rslot, 0.0, hs)
            gm = DR.geom(meshes, body_trees, slot, base, Rslot, laxis)
            assert gm is not None, "DAGFACE FAIL - no geometry at %s" % deg
            gm.pop("key")
            tag = "f%+04d%+04d%+04d_hs%03d" % (deg[0], deg[1], deg[2],
                                               round(hs * 100))
            rec = DR.measure(meshes, body, bpts, cz, body_only, cams, tag,
                             cells, local_ext[1] * hs * WF.PX_PER_M)
            rec.update(triple=deg, hand_scale=hs, **gm)
            rec["geom_ok"] = (gm["hang_deg_from_vertical"] <= DR.HANG_MAX
                              and gm["ground"] == 0
                              and gm["clip_frac"] <= DR.CLIP_FRAC_MAX)
            results.append(rec)
            print("  FACE %-20s hs=%.2f hang=%4.1f len=%.3f cf=%.3f geom_ok=%s "
                  "minor=%s vis=%s proving=%d show=%s border=%.3f"
                  % (deg, hs, gm["hang_deg_from_vertical"], gm["world_len_m"],
                     gm["clip_frac"], rec["geom_ok"], rec["minor"], rec["vis"],
                     rec["proving_views"], rec.get("show"),
                     max(rec["border"].values())), flush=True)

    clean = [r for r in results
             if r["geom_ok"] and r["proving_views"] >= WF.MIN_PROVING
             and not r["blanks"] and not r["frame_clips"] and not r["errors"]
             and not r.get("lath")]
    clean.sort(key=lambda r: (r["hand_scale"], -min(r["vis"].values())))
    out = dict(tool="_t5_dagface", tier=a.tier, kind=DR.KIND, model=res_path,
               hero=hinfo, euler_order=order, basis_selftest=ST,
               engine_hand_scale=hs_engine,
               local_ext=[round(x, 4) for x in local_ext],
               gates=dict(seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN,
                          show_min=WF.SHOW_MIN, min_proving=WF.MIN_PROVING,
                          hang_max=DR.HANG_MAX,
                          clip_frac_max=DR.CLIP_FRAC_MAX),
               triples=FACE_TRIPLES, hand_scales=HS,
               candidates=len(results), clean=len(clean),
               recommended=(clean[0] if clean else None), results=results)
    jp = os.path.join(outdir, "_t5_dagface.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("DAGFACE_DONE %s candidates=%d clean=%d"
          % (jp, len(results), len(clean)), flush=True)
    if not clean:
        print("  DAGFACE NO CLEAN FACE-FRONT CARRY - say so, do not round a gate.",
              flush=True)
    else:
        r0 = clean[0]
        print("  DAGFACE RECOMMEND triple=%s hs=%.2f len=%.3f m cf=%.3f vis=%s "
              "proving=%d show=%s"
              % (r0["triple"], r0["hand_scale"], r0["world_len_m"],
                 r0["clip_frac"], r0["vis"], r0["proving_views"],
                 r0.get("show")), flush=True)


if __name__ == "__main__":
    main()
