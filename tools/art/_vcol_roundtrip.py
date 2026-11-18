"""_vcol_roundtrip - DOES THE BAKED SHEEN SURVIVE THE .glb, OR ONLY MY RENDERS?

  blender -b -noaudio -P tools/art/_vcol_roundtrip.py -- --repo <repo> [--key greener]

WHY THIS EXISTS. docs/art/METAL_READ.md named the baked highlight as candidate 1
and said, as a parenthesis, that "vertex colours survive glTF export; a Blender
shader-node network does not". That sentence is the whole load-bearing
assumption of the fix and it was WRITTEN FROM MEMORY. If COLOR_0 does not
round-trip, the Greener's copper is fixed in renders/art/ and unfixed in the
game - which is strictly worse than an open fault, because the register would
carry a number saying it was closed.

So this exports the body the generator ships, re-imports that .glb into a clean
scene, and reads the colours back OFF THE RE-IMPORTED MESH. It compares the
authored spread with the re-imported one. It goes RED on:
  - no colour attribute on the re-imported mesh at all
  - a colour attribute that is FLAT (every vertex the same) when the authored
    one was not - the failure mode where the exporter keeps the attribute and
    drops the variation
  - a re-imported spread that disagrees with the authored one beyond tolerance
It also reports whether the re-imported MATERIAL is wired to the attribute,
because the attribute surviving and nothing reading it is the same outcome as
it not surviving.
"""
import os
import sys
import json
import argparse

import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

# the mean is compared LOOSELY and the range STRICTLY, on purpose. The glTF
# exporter SPLITS vertices wherever corner data differs, so 308 authored
# vertices come back as ~1054 and the duplicates re-weight the mean - an exact
# mean match is not expected and demanding one would be a gate that fails on
# correct behaviour. What must survive exactly is the RANGE: the darkest and
# brightest colour in the ramp, which duplication cannot move.
TOL_MEAN = 0.06
TOL_RANGE = 0.02


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _read_cols(me):
    at = me.color_attributes.get(L.VCOL_NAME)
    if at is None:
        # the importer is free to rename; take the only one if there is one
        if len(me.color_attributes) == 1:
            at = me.color_attributes[0]
        else:
            return None, None
    cols = [tuple(d.color)[:3] for d in at.data]
    return at.name, cols


def _stats(cols):
    if not cols:
        return None
    n = len(cols)
    mins = [min(c[k] for c in cols) for k in range(3)]
    maxs = [max(c[k] for c in cols) for k in range(3)]
    means = [sum(c[k] for c in cols) / n for k in range(3)]
    # the spread is the thing that matters: a ramp that exports FLAT has a
    # surviving attribute and no surviving sheen.
    spread = max(maxs[k] - mins[k] for k in range(3))
    return dict(n=n, min=[round(v, 4) for v in mins],
                max=[round(v, 4) for v in maxs],
                mean=[round(v, 4) for v in means], spread=round(spread, 4))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="greener")
    ap.add_argument("--slot", default="bone")
    args = ap.parse_args(argv)
    key, slot = args.key, args.slot
    rep = {"ok": True, "errors": [], "key": key, "slot": slot}

    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_metal_tmp")
    os.makedirs(tmp, exist_ok=True)
    path = os.path.join(tmp, "_rt_%s.glb" % key)

    _clear()
    objs, _info = MG.build_miniboss(key)
    want = next((o for o in objs if o.name == "%s_%s" % (key, slot)), None)
    if want is None:
        rep["errors"].append("built body has no object %s_%s" % (key, slot))
        rep["ok"] = False
        print("VCOLRT " + json.dumps(rep))
        return
    rep["authored_items_painted"] = int(want.get("vcol_items", 0))
    if rep["authored_items_painted"] <= 0:
        rep["errors"].append("the authored mesh carries NO painted items - "
                             "nothing to round-trip, RED ON EMPTY")
        rep["ok"] = False
    nm, cols = _read_cols(want.data)
    rep["authored"] = {"attr": nm, "stats": _stats(cols)}
    if cols is None:
        rep["errors"].append("the authored mesh has no colour attribute")
        rep["ok"] = False
        print("VCOLRT " + json.dumps(rep))
        return

    # *** EVERYTHING NEEDED FROM THE AUTHORED MESH IS TAKEN NOW, BEFORE THE
    # *** SCENE IS CLEARED. The first version of this file read
    # want.data.vertices AFTER _clear() and died with "StructRNA of type Object
    # has been removed" - and BLENDER STILL EXITED 0, so the batch above
    # recorded rc=0 and no verdict line at all. A return code is not a verdict
    # for a -P script; only the printed line is. Recorded because it is exactly
    # the failure this whole file exists to catch, in the prover itself.
    nv = len(want.data.vertices)
    rep["authored_verts"] = nv

    ok, msg = __import__("lordgen").export_glb(objs, path)
    rep["export"] = {"ok": bool(ok), "msg": msg,
                     "bytes": os.path.getsize(path) if os.path.exists(path) else 0}
    if not ok or not rep["export"]["bytes"]:
        rep["errors"].append("export failed: %s" % msg)
        rep["ok"] = False
        print("VCOLRT " + json.dumps(rep))
        return

    _clear()
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    news = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    rep["reimported_meshes"] = sorted(o.name for o in news)
    # the re-imported object keeping its name is not guaranteed; match on the
    # vertex count of the authored mesh instead, which is - taken above, while
    # the authored mesh still existed.
    # match by NAME first; the exporter's vertex splitting makes vertex count
    # useless as an identity test, which the first version of this file learned
    # the hard way (308 authored vertices came back as 1054).
    want_name = "%s_%s" % (key, slot)
    cand = [o for o in news if o.name == want_name] or \
           [o for o in news if want_name in o.name]
    if not cand:
        rep["errors"].append("no re-imported mesh named %s (got %s, authored "
                             "%d verts)" % (want_name, rep["reimported_meshes"], nv))
        rep["ok"] = False
        print("VCOLRT " + json.dumps(rep))
        return
    got = cand[0]
    rep["reimported_verts"] = len(got.data.vertices)
    rnm, rcols = _read_cols(got.data)
    rep["reimported"] = {"obj": got.name, "attr": rnm, "stats": _stats(rcols)}
    if rcols is None:
        rep["errors"].append("THE COLOUR ATTRIBUTE DID NOT SURVIVE THE .glb - "
                             "the sheen exists only in art's renders and not in "
                             "the game. The fix is NOT shippable as built.")
        rep["ok"] = False
    else:
        a, b = rep["authored"]["stats"], rep["reimported"]["stats"]
        if b["spread"] < 0.05:
            rep["errors"].append("the attribute survived but is FLAT (spread "
                                 "%.4f) - the ramp was dropped" % b["spread"])
            rep["ok"] = False
        for k in range(3):
            for fld, tol in (("min", TOL_RANGE), ("max", TOL_RANGE),
                             ("mean", TOL_MEAN)):
                if abs(a[fld][k] - b[fld][k]) > tol:
                    rep["errors"].append(
                        "channel %d %s moved %.4f -> %.4f across the .glb, "
                        "beyond tol %.3f" % (k, fld, a[fld][k], b[fld][k], tol))
                    rep["ok"] = False
    # does anything READ it on the way back in?
    uses = []
    for ms in got.data.materials:
        if ms is None or not ms.use_nodes:
            continue
        for n in ms.node_tree.nodes:
            if n.type in ('ATTRIBUTE', 'VERTEX_COLOR'):
                uses.append((ms.name, n.type,
                             getattr(n, "attribute_name", getattr(n, "layer_name", ""))))
    rep["reimported_material_reads_attr"] = uses
    if not uses:
        rep["errors"].append("the re-imported MATERIAL reads no colour "
                             "attribute - the data survived and nothing shows "
                             "it, which is the same outcome for a viewer")
        rep["ok"] = False
    print("VCOLRT " + json.dumps(rep))


main()
