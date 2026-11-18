"""_vcol_regression - DID THE SHARED MERGE MOVE ANY OF THE OTHER BODIES?

  blender -b -noaudio -P tools/art/_vcol_regression.py -- --repo <repo> \
      --keys dyer,tanner,reeve --tag before|after

18 Nov. The vertex-colour change replaced FOUR private copies of the merge loop
(minibossgen, _metal_read, _trade_read, _colour_read) with one shared function
in minibosses.py. That is a refactor underneath 24 shipped bodies, and a
refactor that silently re-lights 24 bodies would be far worse than the one fault
it was made to fix. "It is byte-identical by construction" is an argument, not
evidence.

So: build the named bodies and hash the GEOMETRY AND THE MATERIAL STATE that
the renderer actually consumes - every vertex coordinate, every face, and each
material's base colour, roughness, metallic and specular. Run it on the old code
and on the new and compare the hashes. Geometry hashing beats comparing PNGs
because it cannot be fooled by a render that happens to look the same, and it is
not subject to a renderer's own run-to-run noise.
"""
import os
import sys
import json
import hashlib
import argparse

import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _socket(bsdf, names):
    for nm in names:
        if nm in bsdf.inputs:
            try:
                v = bsdf.inputs[nm].default_value
                try:
                    return [round(float(x), 6) for x in v]
                except TypeError:
                    return round(float(v), 6)
            except Exception:
                pass
    return None


def _mat_state(ms):
    if ms is None:
        return None
    out = {"name": ms.name, "nodes": sorted(n.type for n in ms.node_tree.nodes)
           if ms.use_nodes else []}
    if ms.use_nodes:
        for n in ms.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                out["base"] = _socket(n, ['Base Color'])
                out["rough"] = _socket(n, ['Roughness'])
                out["metal"] = _socket(n, ['Metallic'])
                out["spec"] = _socket(n, ['Specular IOR Level', 'Specular'])
            if n.type == 'EMISSION':
                out["emit"] = _socket(n, ['Color'])
                out["emit_str"] = _socket(n, ['Strength'])
    return out


def _body_hash(key):
    _clear()
    objs, _ = MG.build_miniboss(key)
    h = hashlib.sha256()
    per = []
    for ob in objs:
        me = ob.data
        h.update(ob.name.encode())
        for v in me.vertices:
            h.update(("%.6f,%.6f,%.6f;" % (v.co.x, v.co.y, v.co.z)).encode())
        for po in me.polygons:
            h.update((",".join(str(i) for i in po.vertices) + ";").encode())
        st = [_mat_state(ms) for ms in me.materials]
        h.update(json.dumps(st, sort_keys=True).encode())
        h.update(("|%.6f,%.6f,%.6f|%.6f,%.6f,%.6f|"
                  % (ob.scale.x, ob.scale.y, ob.scale.z,
                     ob.location.x, ob.location.y, ob.location.z)).encode())
        per.append({"obj": ob.name, "verts": len(me.vertices),
                    "faces": len(me.polygons),
                    "vcol_attrs": sorted(a.name for a in me.color_attributes),
                    "vcol_items": int(ob.get("vcol_items", 0)),
                    "mats": st})
    return h.hexdigest(), per


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", default="")
    ap.add_argument("--tag", default="after")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    keys = [k.strip() for k in args.keys.split(",") if k.strip()] or list(M.ORDER)
    rep = {"ok": True, "errors": [], "tag": args.tag, "by_key": {}}
    for key in keys:
        try:
            hh, per = _body_hash(key)
            rep["by_key"][key] = {"hash": hh, "objs": per}
        except Exception as e:
            rep["errors"].append("%s: %s" % (key, e))
            rep["ok"] = False
    out = args.out or os.path.join(args.repo, "renders", "art", "minibosses",
                                   "_vcol_regression_%s.json" % args.tag)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(rep, f, indent=1, sort_keys=True)
    print("VCOLREG " + json.dumps({"ok": rep["ok"], "n": len(rep["by_key"]),
                                   "errors": rep["errors"], "out": out,
                                   "hashes": {k: v["hash"][:16]
                                              for k, v in rep["by_key"].items()}}))


main()
