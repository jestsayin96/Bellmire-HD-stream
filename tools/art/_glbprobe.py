#!/usr/bin/env python3
"""_glbprobe.py - read a .glb WITHOUT Blender. Art lane, 28 Nov 2026.

Written during the house-wide Blender/git bridge outage. Answers the questions
that are pure bookkeeping - bounds, pivot, node census, triangle counts, and
MATERIAL/TEXTURE IDENTITY BY BYTE HASH - so they do not have to wait on a
bridge.

*** WHAT THIS INSTRUMENT CANNOT SEE. READ THIS BEFORE TRUSTING A NUMBER. ***
It never renders. So it cannot tell a WALL from an open timber LATTICE, it
cannot see a gable hole, it cannot see colour, and it cannot say whether a
progression reads. Those are the three faults that have actually bitten this
lane and NONE of them is visible here. A green sheet from this tool is not a
fit proof and must never be reported as one.
What it CAN say, exactly: which modules were placed, how big the result is,
where its pivot sits, and whether two meshes share the identical texture bytes.

RED ON EMPTY: a file that yields zero meshes or zero POSITION accessors is an
ERROR, not a clean pass. A metric over zero items reads green and means
nothing.
"""
import sys, json, struct, hashlib, argparse, os, re


def base_name(nm):
    """Module name with instance suffixes stripped.

    Strips BOTH Blender's `.001` AND this lane's own `_inst` suffix that
    hallgen.py appends. Splitting on '.' alone was a real bug: it hid every
    lattice bay in a mesh THIS LANE generated and reported town_hall_t1 as
    carrying zero when it carries one, at ground level, unbacked. Fixed
    28 Nov 2026 - see docs/art/TOWN_LATTICE_AUDIT.md finding 2b.
    """
    nm = re.sub(r'\.\d+$', '', nm)
    nm = re.sub(r'_inst$', '', nm)
    return nm


def load_glb(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"glTF":
        raise ValueError("%s: not a GLB (magic %r)" % (path, data[:4]))
    ver, length = struct.unpack_from("<II", data, 4)
    off, js, bin_chunk = 12, None, None
    while off < min(length, len(data)):
        clen, ctype = struct.unpack_from("<II", data, off)
        body = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(body.decode("utf-8"))
        elif ctype == 0x004E4942:
            bin_chunk = body
        off += 8 + clen
        off += (-clen) % 4
    if js is None:
        raise ValueError("%s: no JSON chunk" % path)
    return js, (bin_chunk or b"")


def mat_mul(a, b):
    return [sum(a[i + k * 4] * b[k + j * 4] for k in range(4))
            for j in range(4) for i in range(4)]


def trs_matrix(node):
    if "matrix" in node:
        return list(node["matrix"])
    t = node.get("translation", [0, 0, 0])
    r = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    x, y, z, w = r
    rm = [
        1 - 2*(y*y+z*z), 2*(x*y+z*w),     2*(x*z-y*w),     0,
        2*(x*y-z*w),     1 - 2*(x*x+z*z), 2*(y*z+x*w),     0,
        2*(x*z+y*w),     2*(y*z-x*w),     1 - 2*(x*x+y*y), 0,
        0, 0, 0, 1,
    ]
    for c in range(3):
        for r_ in range(3):
            rm[c*4+r_] *= s[c]
    rm[12], rm[13], rm[14] = t
    return rm


def xform(m, p):
    x, y, z = p
    return [m[0]*x + m[4]*y + m[8]*z + m[12],
            m[1]*x + m[5]*y + m[9]*z + m[13],
            m[2]*x + m[6]*y + m[10]*z + m[14]]


def view_bytes(js, binc, vi):
    v = js["bufferViews"][vi]
    o = v.get("byteOffset", 0)
    return binc[o:o + v["byteLength"]]


def probe(path):
    js, binc = load_glb(path)
    nodes = js.get("nodes", [])
    meshes = js.get("meshes", [])
    mats = js.get("materials", [])
    out = {
        "file": os.path.basename(path),
        "bytes": os.path.getsize(path),
        "errors": [], "warnings": [],
        "n_nodes": len(nodes), "n_meshes": len(meshes), "n_materials": len(mats),
    }

    world = {}
    scene = js.get("scenes", [{}])[js.get("scene", 0)] if js.get("scenes") else {}
    roots = scene.get("nodes", list(range(len(nodes))))
    ident = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    stack = [(r, ident) for r in roots]
    seen = set()
    while stack:
        ni, parent = stack.pop()
        if ni in seen:
            out["warnings"].append("node %d reached twice; graph is not a tree" % ni)
            continue
        seen.add(ni)
        m = mat_mul(parent, trs_matrix(nodes[ni]))
        world[ni] = m
        for c in nodes[ni].get("children", []):
            stack.append((c, m))

    lo = [float("inf")]*3
    hi = [float("-inf")]*3
    tris = 0
    prims = 0
    no_minmax = 0
    node_census = {}
    per_node = []
    for ni, node in enumerate(nodes):
        nm = node.get("name", "<node%d>" % ni)
        if "mesh" not in node:
            continue
        if ni not in world:
            out["warnings"].append("mesh node %d (%s) not in scene graph; skipped" % (ni, nm))
            continue
        m = world[ni]
        base = base_name(nm)
        node_census[base] = node_census.get(base, 0) + 1
        nlo = [float("inf")]*3
        nhi = [float("-inf")]*3
        ntris = 0
        for p in meshes[node["mesh"]].get("primitives", []):
            prims += 1
            pos = p.get("attributes", {}).get("POSITION")
            if pos is None:
                continue
            acc = js["accessors"][pos]
            mn, mx, cnt = acc.get("min"), acc.get("max"), acc.get("count", 0)
            if not mn or not mx:
                no_minmax += 1
                continue
            for cx in (mn[0], mx[0]):
                for cy in (mn[1], mx[1]):
                    for cz in (mn[2], mx[2]):
                        w = xform(m, (cx, cy, cz))
                        for k in range(3):
                            nlo[k] = min(nlo[k], w[k]); nhi[k] = max(nhi[k], w[k])
                            lo[k] = min(lo[k], w[k]);  hi[k] = max(hi[k], w[k])
            if "indices" in p:
                ntris += js["accessors"][p["indices"]].get("count", 0) // 3
            else:
                ntris += cnt // 3
        tris += ntris
        if nlo[0] != float("inf"):
            per_node.append({"node": nm, "tris": ntris,
                             "lo": [round(v, 4) for v in nlo],
                             "hi": [round(v, 4) for v in nhi]})

    if prims == 0:
        out["errors"].append("RED ON EMPTY: zero primitives parsed")
    if lo[0] == float("inf"):
        out["errors"].append("RED ON EMPTY: zero POSITION accessors with min/max; no bounds")
    if no_minmax:
        out["warnings"].append("%d POSITION accessors carried no min/max; skipped" % no_minmax)

    if lo[0] != float("inf"):
        out["bounds_lo"] = [round(v, 4) for v in lo]
        out["bounds_hi"] = [round(v, 4) for v in hi]
        out["dims_m"] = [round(hi[k]-lo[k], 4) for k in range(3)]
        out["centre"] = [round((hi[k]+lo[k])/2.0, 4) for k in range(3)]
        out["bounds_note"] = ("AABB of each primitive's own AABB corners under its world "
                              "matrix - exact for axis-aligned placement, CONSERVATIVE "
                              "(never smaller than truth) under rotation.")
    out["tris"] = tris
    out["n_mesh_nodes"] = len(per_node)
    out["node_census"] = dict(sorted(node_census.items(), key=lambda kv: (-kv[1], kv[0])))
    out["per_node"] = sorted(per_node, key=lambda r: -r["tris"])[:40]

    imgs = []
    for i, im in enumerate(js.get("images", [])):
        rec = {"i": i, "name": im.get("name", ""), "mime": im.get("mimeType", ""),
               "uri": im.get("uri", "")[:80]}
        if "bufferView" in im:
            b = view_bytes(js, binc, im["bufferView"])
            rec["bytes"] = len(b)
            rec["sha1"] = hashlib.sha1(b).hexdigest()
        imgs.append(rec)
    out["images"] = imgs
    hashes = [r["sha1"] for r in imgs if "sha1" in r]
    out["n_images"] = len(imgs)
    out["n_images_embedded"] = len(hashes)
    out["n_images_unique_bytes"] = len(set(hashes))
    if len(hashes) != len(set(hashes)):
        out["warnings"].append("%d embedded images are byte-identical duplicates"
                               % (len(hashes)-len(set(hashes))))

    texmap = js.get("textures", [])

    def img_of(ti):
        if ti is None or ti >= len(texmap):
            return None
        return texmap[ti].get("source")

    ml = []
    for i, mt in enumerate(mats):
        pbr = mt.get("pbrMetallicRoughness", {})
        bc = pbr.get("baseColorTexture", {}).get("index")
        si = img_of(bc)
        ml.append({
            "i": i, "name": mt.get("name", ""),
            "base_image": (imgs[si]["name"] if si is not None and si < len(imgs) else None),
            "base_sha1": (imgs[si].get("sha1", "")[:12] if si is not None and si < len(imgs) else None),
            "base_color_factor": [round(v, 4) for v in pbr.get("baseColorFactor", [1, 1, 1, 1])],
        })
    out["materials"] = ml
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--out")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    res = {"tool": "_glbprobe.py",
           "cannot_see": "no render: blind to lattice-vs-wall, gable holes, colour, readability",
           "files": []}
    bad = 0
    for f in a.files:
        try:
            r = probe(f)
        except Exception as e:
            r = {"file": os.path.basename(f), "errors": ["PARSE FAILED: %s" % e]}
        if r.get("errors"):
            bad += 1
        res["files"].append(r)
        if not a.quiet:
            print("--- %s tris=%s dims=%s centre=%s imgs=%s/%suniq err=%s"
                  % (r.get("file"), r.get("tris"), r.get("dims_m"), r.get("centre"),
                     r.get("n_images"), r.get("n_images_unique_bytes"), r.get("errors")))
    res["n_files"] = len(res["files"])
    res["n_files_with_errors"] = bad
    res["verdict"] = "GREEN" if bad == 0 and res["files"] else "RED"
    if not res["files"]:
        res["note"] = "RED ON EMPTY: no files probed"
    if a.out:
        d = os.path.dirname(a.out)
        if d:
            os.makedirs(d, exist_ok=True)
        with open(a.out, "w") as fh:
            json.dump(res, fh, indent=1)
        print("wrote %s" % a.out)
    print("verdict %s files=%d with_errors=%d" % (res["verdict"], res["n_files"], bad))
    return 1 if res["verdict"] == "RED" else 0


if __name__ == "__main__":
    sys.exit(main())
