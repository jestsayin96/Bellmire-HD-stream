#!/usr/bin/env python3
"""_modcover.py - decide WALL vs OPEN LATTICE from geometry alone. No Blender.

Art lane, 28 Nov 2026, written during the fifth hour of the house-wide
Blender/Godot/git bridge outage.

THE QUESTION IT ANSWERS. `_chapelmeasure.py` cannot run without a bridge, and
the step it was going to unblock is the one that matters: which of the pack's
wall modules are SOLID WALLS and which are OPEN TIMBER LATTICE. The Hall chose
`Wall_Plaster_WoodGrid` off its NAME, the module is a lattice, and tier 1
rendered as a building you could see straight through. That is the fault this
answers, and it is answerable from geometry: a solid wall covers its own
in-plane bounding box; a lattice is mostly air.

HOW. For each mesh node: decode every triangle to world space, take the node's
THINNEST world axis as the wall normal, and rasterise the UNION of the
triangles projected onto the remaining two axes into a grid.
`cover` = filled cells / all cells.

UNION, NOT SUM, AND THAT IS THE WHOLE DESIGN. Summing projected triangle area
double-counts a wall's front and back faces and reads ~2.0 for a solid wall -
a metric that cannot distinguish 'solid' from 'solid, twice'. A rasterised
union is bounded in [0,1] and is literally the viewer's question: what
fraction of this wall's plane is blocked.

*** WHAT THIS INSTRUMENT CANNOT SEE. READ BEFORE TRUSTING A NUMBER. ***
It never renders.
  - It is BLIND TO COLOUR and to material. A solid wall of the wrong plaster
    reads 1.00 here. The Hall's weak tier 2 -> 3 step is invisible to it.
  - It is BLIND TO WHETHER A PROGRESSION READS at a glance. That needs the
    side-by-side sheet and an eye.
  - It is a PROXY for the rendered `hole_frac`, not that number. It answers
    'is this module mostly air', and nothing about how it looks lit.
  - It is PER MODULE, so it is blind to ASSEMBLY faults - a gable hole between
    a roof and a wall belongs to no single node and will not appear here.
  - A one-sided quad and a two-sided quad both read 1.00. Backface culling in
    the engine can still make a 1.00 wall vanish from one side.
  - Thin trim, railings and window frames are MEANT to be mostly air. A low
    cover is a flag to look at, not a fault by itself.
A green sheet from this tool is NOT a fit proof and must never be reported as
one. The chapel ladder still cannot ship without renders looked at by eye.

RED ON EMPTY, inherited from `_glbprobe.py` and extended: zero triangles, a
degenerate in-plane box, or zero filled cells is an ERROR, not a clean pass.
A metric computed over nothing reads green and means nothing.

VALIDATION. `--validate` refuses to report a table at all unless it first
separates the one pair whose truth was established BY RENDER:
`Wall_Plaster_WoodGrid` (lattice, doc fault 1, rendered evidence) must come
out well below `Wall_Plaster_Straight` (solid). If it does not, the
instrument is RED and says so instead of producing numbers.
"""
import sys, os, json, struct, argparse, re

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _glbprobe import load_glb, mat_mul, trs_matrix, xform, base_name

CTYPE = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
         5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_accessor(js, binc, ai):
    """Decode an accessor to a list of tuples. Honest about what it refuses."""
    acc = js["accessors"][ai]
    if "sparse" in acc:
        raise ValueError("sparse accessor %d not supported" % ai)
    n = acc.get("count", 0)
    ncomp = NCOMP[acc["type"]]
    fmt, sz = CTYPE[acc["componentType"]]
    if "bufferView" not in acc:
        return [tuple([0] * ncomp)] * n
    bv = js["bufferViews"][acc["bufferView"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride") or (sz * ncomp)
    out = []
    s = struct.Struct("<" + fmt * ncomp)
    for i in range(n):
        out.append(s.unpack_from(binc, base + i * stride))
    return out


def node_triangles(js, binc, node, m):
    """World-space triangles for one mesh node."""
    tris = []
    skipped = 0
    for p in js["meshes"][node["mesh"]].get("primitives", []):
        if p.get("mode", 4) != 4:
            skipped += 1
            continue
        pi = p.get("attributes", {}).get("POSITION")
        if pi is None:
            skipped += 1
            continue
        try:
            pos = read_accessor(js, binc, pi)
        except ValueError:
            skipped += 1
            continue
        wpos = [xform(m, v) for v in pos]
        if "indices" in p:
            try:
                idx = [i[0] for i in read_accessor(js, binc, p["indices"])]
            except ValueError:
                skipped += 1
                continue
        else:
            idx = list(range(len(wpos)))
        for k in range(0, len(idx) - 2, 3):
            a, b, c = idx[k], idx[k + 1], idx[k + 2]
            if a < len(wpos) and b < len(wpos) and c < len(wpos):
                tris.append((wpos[a], wpos[b], wpos[c]))
    return tris, skipped


def cover_of(tris, grid=128):
    """Rasterised UNION coverage of tris projected down their thinnest axis."""
    rec = {"tris": len(tris), "errors": []}
    if not tris:
        rec["errors"].append("RED ON EMPTY: zero triangles")
        return rec
    lo = [min(v[k] for t in tris for v in t) for k in range(3)]
    hi = [max(v[k] for t in tris for v in t) for k in range(3)]
    dims = [hi[k] - lo[k] for k in range(3)]
    nrm = min(range(3), key=lambda k: dims[k])
    ip = [k for k in range(3) if k != nrm]
    rec["normal_axis"] = "xyz"[nrm]
    rec["dims"] = [round(d, 4) for d in dims]
    rec["thickness"] = round(dims[nrm], 4)
    w, h = dims[ip[0]], dims[ip[1]]
    if w <= 1e-6 or h <= 1e-6:
        rec["errors"].append("RED ON EMPTY: degenerate in-plane box %gx%g" % (w, h))
        return rec
    rec["plane_m2"] = round(w * h, 4)
    rec["thin_ratio"] = round(dims[nrm] / max(w, h), 4)

    cells = bytearray(grid * grid)
    u0, v0 = lo[ip[0]], lo[ip[1]]
    su, sv = (grid - 1e-9) / w, (grid - 1e-9) / h
    for t in tris:
        pu = [(v[ip[0]] - u0) * su for v in t]
        pv = [(v[ip[1]] - v0) * sv for v in t]
        x0 = max(0, int(min(pu))); x1 = min(grid - 1, int(max(pu)))
        y0 = max(0, int(min(pv))); y1 = min(grid - 1, int(max(pv)))
        if x1 < x0 or y1 < y0:
            continue
        ax, ay = pu[0], pv[0]
        bx, by = pu[1], pv[1]
        cx, cy = pu[2], pv[2]
        d = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
        if abs(d) < 1e-12:
            # Degenerate in projection (edge-on sliver): mark its bbox row/col
            # rather than drop it. A wall seen edge-on is still solid.
            for yy in range(y0, y1 + 1):
                row = yy * grid
                for xx in range(x0, x1 + 1):
                    cells[row + xx] = 1
            continue
        inv = 1.0 / d
        for yy in range(y0, y1 + 1):
            py = yy + 0.5
            row = yy * grid
            for xx in range(x0, x1 + 1):
                px = xx + 0.5
                l1 = ((bx - px) * (cy - py) - (by - py) * (cx - px)) * inv
                if l1 < -1e-9: continue
                l2 = ((cx - px) * (ay - py) - (cy - py) * (ax - px)) * inv
                if l2 < -1e-9: continue
                l3 = 1.0 - l1 - l2
                if l3 < -1e-9: continue
                cells[row + xx] = 1
    filled = sum(cells)
    if filled == 0:
        rec["errors"].append("RED ON EMPTY: zero filled cells over %d tris" % len(tris))
        return rec
    rec["cover"] = round(filled / float(grid * grid), 4)
    rec["grid"] = grid
    return rec


def sweep(path, grid=128, tri_cap=30000):
    js, binc = load_glb(path)
    nodes = js.get("nodes", [])
    scene = js.get("scenes", [{}])[js.get("scene", 0)] if js.get("scenes") else {}
    roots = scene.get("nodes", list(range(len(nodes))))
    ident = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    world, stack, seen = {}, [(r, ident) for r in roots], set()
    while stack:
        ni, parent = stack.pop()
        if ni in seen:
            continue
        seen.add(ni)
        m = mat_mul(parent, trs_matrix(nodes[ni]))
        world[ni] = m
        for c in nodes[ni].get("children", []):
            stack.append((c, m))

    out = {"file": os.path.basename(path), "modules": {}, "errors": [],
           "skipped_large": [], "prim_skips": 0}
    for ni, node in enumerate(nodes):
        if "mesh" not in node or ni not in world:
            continue
        nm = node.get("name", "<node%d>" % ni)
        base = base_name(nm)
        tris, sk = node_triangles(js, binc, node, world[ni])
        out["prim_skips"] += sk
        if len(tris) > tri_cap:
            out["skipped_large"].append({"node": base, "tris": len(tris)})
            continue
        rec = cover_of(tris, grid)
        out["modules"].setdefault(base, []).append(rec)

    if not out["modules"]:
        out["errors"].append("RED ON EMPTY: no mesh nodes measured in %s" % path)
    agg = {}
    for base, recs in out["modules"].items():
        cov = [r["cover"] for r in recs if "cover" in r]
        errs = [e for r in recs for e in r["errors"]]
        a = {"n": len(recs), "errors": errs}
        if cov:
            a["cover_min"] = min(cov)
            a["cover_med"] = sorted(cov)[len(cov) // 2]
            a["cover_max"] = max(cov)
            a["tris_med"] = sorted(r["tris"] for r in recs)[len(recs) // 2]
            a["thin_ratio_med"] = sorted(
                r.get("thin_ratio", 9.9) for r in recs)[len(recs) // 2]
        agg[base] = a
    out["agg"] = agg
    return out


GROUND_TRUTH_LATTICE = "Wall_Plaster_WoodGrid"
GROUND_TRUTH_SOLID = "Wall_Plaster_Straight"


def validate(allagg):
    """Refuse to report unless the known-by-render pair separates."""
    v = {"pair": [GROUND_TRUTH_SOLID, GROUND_TRUTH_LATTICE]}
    sol = allagg.get(GROUND_TRUTH_SOLID, {})
    lat = allagg.get(GROUND_TRUTH_LATTICE, {})
    if "cover_med" not in sol or "cover_med" not in lat:
        v["verdict"] = "RED"
        v["why"] = ("RED ON EMPTY: one or both ground-truth modules absent from "
                    "the sweep, so the instrument was never checked against a "
                    "known answer. solid=%r lattice=%r"
                    % (sol.get("cover_med"), lat.get("cover_med")))
        return v
    v["solid_cover_med"] = sol["cover_med"]
    v["lattice_cover_med"] = lat["cover_med"]
    v["margin"] = round(sol["cover_med"] - lat["cover_med"], 4)
    v["solid_n"] = sol["n"]
    v["lattice_n"] = lat["n"]
    if v["margin"] < 0.20:
        v["verdict"] = "RED"
        v["why"] = ("the module PROVEN see-through by render does not separate "
                    "from the module proven solid (margin %.4f < 0.20). The "
                    "instrument cannot tell a wall from a hole and its table is "
                    "worthless. Do not use it." % v["margin"])
    else:
        v["verdict"] = "GREEN"
        v["why"] = ("separates the one pair whose truth came from a PICTURE: "
                    "solid %.4f vs lattice %.4f, margin %.4f."
                    % (v["solid_cover_med"], v["lattice_cover_med"], v["margin"]))
    return v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb", nargs="+")
    ap.add_argument("--grid", type=int, default=128)
    ap.add_argument("--out")
    ap.add_argument("--validate", action="store_true")
    a = ap.parse_args()

    files, allagg = [], {}
    for p in a.glb:
        try:
            r = sweep(p, a.grid)
        except Exception as e:
            files.append({"file": os.path.basename(p),
                          "errors": ["EXCEPTION: %s: %s" % (type(e).__name__, e)]})
            continue
        slim = {k: r[k] for k in ("file", "errors", "skipped_large", "prim_skips")}
        slim["agg"] = r["agg"]
        files.append(slim)
        for base, ag in r["agg"].items():
            if "cover_med" not in ag:
                continue
            t = allagg.setdefault(base, {"n": 0, "cov": [], "tris": [], "errors": []})
            t["n"] += ag["n"]
            t["cov"].append(ag["cover_med"])
            t["tris"].append(ag.get("tris_med", 0))
            t["errors"] += ag["errors"]
    rolled = {}
    for base, t in allagg.items():
        c = sorted(t["cov"])
        rolled[base] = {"n": t["n"], "cover_med": c[len(c) // 2],
                        "cover_min": c[0], "cover_max": c[-1],
                        "tris_med": sorted(t["tris"])[len(t["tris"]) // 2],
                        "errors": t["errors"]}
    res = {"files": files, "modules": rolled,
           "blindness": ("NEVER RENDERS. Blind to colour, to material, to whether a "
                         "progression reads, to assembly faults such as a gable hole, "
                         "and to backface culling. NOT a fit proof.")}
    res["validation"] = validate(rolled)
    if res["validation"]["verdict"] != "GREEN":
        res["modules"] = "WITHHELD - instrument failed validation, see validation.why"
    txt = json.dumps(res, indent=1)
    if a.out:
        os.makedirs(os.path.dirname(a.out), exist_ok=True)
        open(a.out, "w").write(txt)
    print(txt[:4000])
    return 0 if res["validation"]["verdict"] == "GREEN" else 2


if __name__ == "__main__":
    sys.exit(main())


# ---------------------------------------------------------------------------
# THROUGHLIGHT MODE - added 28 Nov 2026 05:5x CT, same outage.
#
# Supersedes the backing test in docs/art/TOWN_LATTICE_AUDIT.md finding 2, and
# does so for a reason worth stating: that test asked whether some OTHER node
# in the wall plane COVERS THE BAY'S AREA, treating the backer as an opaque
# rectangle. A bay backed by a second lattice therefore scored as BACKED. This
# rasterises the backer's actual triangles into the bay's own grid, so a
# lattice behind a lattice reads as the hole it is.
#
# hole_frac = 1 - (union coverage of EVERY triangle whose centroid sits within
# `depth` of the bay's plane, projected into the bay's in-plane window).
# That is the viewer's question for a wall plane: what fraction of this bay has
# nothing in it at all.
#
# STILL BLIND TO EVERYTHING LISTED AT THE TOP. In particular it cannot see what
# lies DEEPER than `depth` - a solid far wall 6 m back will not close a hole
# here, and should not: you would be looking into the building's inside, which
# is the open-shed look this lane already noted by eye.
# ---------------------------------------------------------------------------

def throughlight(path, target, grid=128, depth=1.0, tri_cap=30000):
    js, binc = load_glb(path)
    nodes = js.get("nodes", [])
    scene = js.get("scenes", [{}])[js.get("scene", 0)] if js.get("scenes") else {}
    roots = scene.get("nodes", list(range(len(nodes))))
    ident = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    world, stack, seen = {}, [(r, ident) for r in roots], set()
    while stack:
        ni, parent = stack.pop()
        if ni in seen:
            continue
        seen.add(ni)
        m = mat_mul(parent, trs_matrix(nodes[ni]))
        world[ni] = m
        for c in nodes[ni].get("children", []):
            stack.append((c, m))

    cache = {}
    for ni, node in enumerate(nodes):
        if "mesh" not in node or ni not in world:
            continue
        tris, _ = node_triangles(js, binc, node, world[ni])
        if len(tris) <= tri_cap:
            cache[ni] = tris

    out = {"file": os.path.basename(path), "target": target,
           "depth_m": depth, "bays": [], "errors": []}
    for ni, node in enumerate(nodes):
        if ni not in cache:
            continue
        if base_name(node.get("name", "")) != target:
            continue
        tris = cache[ni]
        if not tris:
            out["errors"].append("RED ON EMPTY: bay node %d has zero tris" % ni)
            continue
        lo = [min(v[k] for t in tris for v in t) for k in range(3)]
        hi = [max(v[k] for t in tris for v in t) for k in range(3)]
        dims = [hi[k] - lo[k] for k in range(3)]
        nrm = min(range(3), key=lambda k: dims[k])
        ip = [k for k in range(3) if k != nrm]
        cn = (lo[nrm] + hi[nrm]) / 2.0
        w, h = dims[ip[0]], dims[ip[1]]
        if w <= 1e-6 or h <= 1e-6:
            out["errors"].append("RED ON EMPTY: bay node %d degenerate" % ni)
            continue
        # every triangle near this wall plane and inside the bay's window
        near = []
        for mj, mt in cache.items():
            for t in mt:
                zc = (t[0][nrm] + t[1][nrm] + t[2][nrm]) / 3.0
                if abs(zc - cn) > depth:
                    continue
                if max(v[ip[0]] for v in t) < lo[ip[0]] or min(v[ip[0]] for v in t) > hi[ip[0]]:
                    continue
                if max(v[ip[1]] for v in t) < lo[ip[1]] or min(v[ip[1]] for v in t) > hi[ip[1]]:
                    continue
                near.append(t)
        rec = cover_of(tris, grid)
        full = _cover_in_window(near, lo, hi, ip, grid)
        out["bays"].append({
            "node": ni, "name": node.get("name", ""),
            "band_y": [round(lo[1], 2), round(hi[1], 2)],
            # --- ADDITIVE, 28 Nov 06:4x CT: world placement, so a fix can be
            # --- APPLIED to a named instance rather than only counted. No
            # --- existing field's value is touched by these.
            "centre": [round((lo[k] + hi[k]) / 2.0, 3) for k in range(3)],
            "lo_xyz": [round(lo[k], 3) for k in range(3)],
            "hi_xyz": [round(hi[k], 3) for k in range(3)],
            "normal_axis": "xyz"[nrm],
            "normal_centre": round(cn, 3),
            "size_inplane": [round(w, 3), round(h, 3)],
            "axes_inplane": "".join("xyz"[k] for k in ip),
            "cover_self": rec.get("cover"),
            "cover_plane": full["cover"] if "cover" in full else None,
            "hole_frac": (round(1.0 - full["cover"], 4) if "cover" in full else None),
            "tris_self": len(tris), "tris_plane": len(near),
            "errors": rec["errors"] + full["errors"],
        })
    if not out["bays"]:
        out["errors"].append("RED ON EMPTY: zero instances of %r in %s - a sweep "
                             "over no bays reads clean and means nothing"
                             % (target, out["file"]))
    return out


def _cover_in_window(tris, lo, hi, ip, grid):
    """Union coverage of `tris` inside a FIXED window (the bay's own box)."""
    rec = {"errors": []}
    if not tris:
        rec["errors"].append("RED ON EMPTY: zero triangles in window")
        return rec
    u0, v0 = lo[ip[0]], lo[ip[1]]
    w, h = hi[ip[0]] - u0, hi[ip[1]] - v0
    su, sv = (grid - 1e-9) / w, (grid - 1e-9) / h
    cells = bytearray(grid * grid)
    for t in tris:
        pu = [(v[ip[0]] - u0) * su for v in t]
        pv = [(v[ip[1]] - v0) * sv for v in t]
        x0 = max(0, int(min(pu))); x1 = min(grid - 1, int(max(pu)))
        y0 = max(0, int(min(pv))); y1 = min(grid - 1, int(max(pv)))
        if x1 < x0 or y1 < y0:
            continue
        ax, ay, bx, by, cx, cy = pu[0], pv[0], pu[1], pv[1], pu[2], pv[2]
        d = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
        if abs(d) < 1e-12:
            for yy in range(y0, y1 + 1):
                row = yy * grid
                for xx in range(x0, x1 + 1):
                    cells[row + xx] = 1
            continue
        inv = 1.0 / d
        for yy in range(y0, y1 + 1):
            py = yy + 0.5
            row = yy * grid
            for xx in range(x0, x1 + 1):
                px = xx + 0.5
                l1 = ((bx - px) * (cy - py) - (by - py) * (cx - px)) * inv
                if l1 < -1e-9: continue
                l2 = ((cx - px) * (ay - py) - (cy - py) * (ax - px)) * inv
                if l2 < -1e-9: continue
                if 1.0 - l1 - l2 < -1e-9: continue
                cells[row + xx] = 1
    f = sum(cells)
    if f == 0:
        rec["errors"].append("RED ON EMPTY: zero filled cells in window")
        return rec
    rec["cover"] = round(f / float(grid * grid), 4)
    return rec
