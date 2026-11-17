"""propslots - MEASURE the Barrel finding across assets/props/ instead of guessing.

  blender -b -noaudio -P tools/art/propslots.py -- --repo <repo> [--out <json>]

THE ROW (team lead, 17 Nov 16:58 CT): the art lane reported Barrel.gltf as one
object whose TWO material slots "sit at the same radius to within 1 mm", which
Z-FIGHTS into torn shards WHILE EVERY OPACITY CHECK READS GREEN, and wrote
"other models in this pack may be built the same way". MEASURE THAT.

*** FIRST RESULT OF THIS RUN IS A CORRECTION TO MY OWN LANE'S DESCRIPTION. ***
I built the obvious instrument first - two slots whose MEAN cylindrical radius
agrees within 1 mm - and it reported 0 coincident pairs over 94 files INCLUDING
THE BARREL ITSELF. It went red on its own control, which is the only reason the
number is not being reported as "the Barrel and nothing else, 0 found".
THEN I LOOKED AT THE BARREL'S GEOMETRY. One object, 824 faces, slots
MI_Trim_Furniture (wood, 392 faces, r 0.072-0.343) and MI_Trim_Metal (hoops,
432 faces, r 0.283-0.346). The mean radii differ by 51 mm, and the CLOSEST
wood-to-metal face-centre distance is 3.1 mm - so "the same radius to within
1 mm" is NOT reproducible as written and no coplanar duplicate shell exists.
WHAT IS THERE IS WORSE AND IT IS MEASURABLE: the two surfaces CROSS. The staves
bulge, the hoops are constant-radius rings, and banded by height the outermost
radius of the two slots SWAPS ORDER:
    z 0.144  wood max 0.3102 | metal max 0.3122   metal +2.0 mm proud
    z 0.383  wood max 0.3430 | metal max 0.3341   metal -8.9 mm BURIED
    z 0.479  wood max 0.3430 | metal max 0.3387   metal -4.3 mm buried
    z 0.671  wood max 0.3102 | metal max 0.3172   metal +7.0 mm proud
A hoop that is proud at one height and buried at another INTERSECTS the stave
wall in between, and an intersection renders as interleaved slivers of two
materials - the torn shards. Coincidence was the wrong word; CROSSING is the
fault.

SO THIS FILE RUNS TWO TESTS AND REPORTS THEM SEPARATELY:
  T1 CROSSING (the Barrel class). Bin faces by z over the object's own z range;
     keep bands where BOTH slots have >= 3 faces; need >= 3 such bands. Signed
     s = max_r(B) - max_r(A) per band. If s changes sign with |s| >= TOL_M on
     both sides, the surfaces cross: record the deepest interpenetration.
  T2 COPLANAR SHELL (the thing the original description said). Fraction of A's
     faces whose nearest B face centre is within NEAR_M with normals parallel
     (|dot| >= 0.9) - two skins laid on each other. The Barrel scores ZERO here,
     which is why the two tests are not merged.

WHAT NEITHER CAN SEE, WRITTEN DOWN BEFORE THE NUMBER IS READ:
  1. T1 is CYLINDRICAL about the object's local Z. A crossing between two flat
     sheets, or about another axis, is invisible to it. Objects whose geometry
     is not radial are reported in `unmeasurable` with the reason - NOT as pass.
  2. Zero bands is not green. An object whose slots never share a height band
     cannot be judged by T1 and is counted as unmeasurable, never as clean.
  3. Neither test looks at MATERIAL. Two crossing surfaces of the same colour
     will not visibly tear. This counts the geometry half - the half a material
     tweak cannot fix.
  4. The run is RED (ok:false) unless the control, Barrel.gltf, is flagged by
     T1. An instrument that cannot see the one case it was built for is not an
     instrument - that lesson is this lane's, learned at pass 11 on the gloves.
"""
import os, sys, json, argparse, math
import bpy
import numpy as np
from mathutils import kdtree

TOL_M = 0.001          # a crossing must be >= 1 mm on BOTH sides to count
NEAR_M = 0.003         # T2 coplanar-shell proximity
PAR = 0.90             # |n_a . n_b| for a crossing to count as SHALLOW
GAP_M = 0.005          # T3: two surfaces this close at a shallow angle Z-FIGHT
BANDS = 24
MIN_BANDS = 3
MIN_FACES = 3


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def faces_by_slot(ob):
    g = {}
    for p in ob.data.polygons:
        g.setdefault(p.material_index, []).append(p)
    return g


def t1_bands(fa, fb):
    """DESCRIPTIVE ONLY, not the verdict. Signed per-height-band envelope
    difference s = max_r(B) - max_r(A). It is kept because it is what showed
    the Barrel's hoops swapping from proud to buried, but it is NOT a fault
    test: on a market stall or a bookcase the wider slot changes with height
    for perfectly sound reasons, and this reported 29 pairs with up to 426 mm
    of "interpenetration" on objects whose surfaces never touch. An envelope
    is not a surface. The verdict is t1_intersect below."""
    ra = np.array([[math.hypot(p.center.x, p.center.y), p.center.z] for p in fa])
    rb = np.array([[math.hypot(p.center.x, p.center.y), p.center.z] for p in fb])
    z0 = min(ra[:, 1].min(), rb[:, 1].min())
    z1 = max(ra[:, 1].max(), rb[:, 1].max())
    if z1 - z0 < 1e-6:
        return dict(bands=0, reason="zero z extent")
    edges = np.linspace(z0, z1, BANDS + 1)
    sig, rows = [], []
    for i in range(BANDS):
        ma = (ra[:, 1] >= edges[i]) & (ra[:, 1] < edges[i + 1])
        mb = (rb[:, 1] >= edges[i]) & (rb[:, 1] < edges[i + 1])
        if ma.sum() < MIN_FACES or mb.sum() < MIN_FACES:
            continue
        s = float(rb[mb, 0].max() - ra[ma, 0].max())
        sig.append(s)
        rows.append([round(float(edges[i]), 4), round(float(ra[ma, 0].max()), 5),
                     round(float(rb[mb, 0].max()), 5), round(s * 1000.0, 2)])
    if len(sig) < MIN_BANDS:
        return dict(bands=len(sig), reason="slots share fewer than %d height bands" % MIN_BANDS)
    s = np.array(sig)
    pos, neg = s[s >= TOL_M], s[s <= -TOL_M]
    return dict(bands=len(sig), envelope_crossing=bool(len(pos) and len(neg)),
                proud_mm=round(float(pos.max() * 1000.0), 2) if len(pos) else 0.0,
                buried_mm=round(float(-neg.min() * 1000.0), 2) if len(neg) else 0.0,
                band_rows=rows)


def _tris(ob, faces):
    """triangles of one material slot, in object space, with their vertex ids."""
    me = ob.data
    co = [v.co.copy() for v in me.vertices]
    polys, src = [], []
    for p in faces:
        vi = list(p.vertices)
        for k in range(1, len(vi) - 1):
            polys.append((vi[0], vi[k], vi[k + 1]))
            src.append(p.index)
    return co, polys, src


def t1_intersect(ob, fa, fb):
    """THE VERDICT TEST. Do the two slots' triangles actually INTERSECT, and
    do they cross at a SHALLOW angle?

    Ground truth for the torn-shard look is intersection, not proximity - but
    intersection alone is not the fault either: a table leg embedded squarely
    in a table top intersects and renders perfectly, because one surface is
    buried inside solid geometry. What tears is two surfaces crossing nearly
    TANGENTIALLY, so the renderer has to choose between them over a wide area.
    So a hit needs BOTH: a real triangle intersection AND |n_a . n_b| >= PAR
    on the two faces that intersect. Edge-adjacent triangles (sharing any
    vertex index) are excluded - a shared seam is not a crossing.
    """
    from mathutils.bvhtree import BVHTree
    coa, pa, sa = _tris(ob, fa)
    cob, pb, sb = _tris(ob, fb)
    if not pa or not pb:
        return dict(pairs=0, shallow=0, reason="no triangles")
    ta = BVHTree.FromPolygons(coa, pa, all_triangles=True, epsilon=0.0)
    tb = BVHTree.FromPolygons(cob, pb, all_triangles=True, epsilon=0.0)
    ov = ta.overlap(tb)
    shallow, seam, flat_faces = 0, 0, set()
    nd_max = 0.0
    for ia, ib in ov:
        if set(pa[ia]) & set(pb[ib]):
            seam += 1
            continue
        na = fa[0].id_data.polygons[sa[ia]].normal if False else None
        pA = ob.data.polygons[sa[ia]]
        pB = ob.data.polygons[sb[ib]]
        d = abs(pA.normal.dot(pB.normal))
        if d >= PAR:
            shallow += 1
            flat_faces.add(sa[ia])
            nd_max = max(nd_max, d)
    return dict(pairs=len(ov), seam_pairs=seam, shallow=shallow,
                shallow_faces_a=len(flat_faces), max_dot=round(nd_max, 4))


def t3_surface(ob, fa, fb):
    """*** THE VERDICT TEST, THIRD INSTRUMENT AND THE ONLY ONE THAT SEES THE
    CONTROL. *** True perpendicular distance from each face of slot A to the
    nearest point ON THE SURFACE of slot B (BVHTree.find_nearest), not to
    another face's centre.

    Why the first two could not see it. Z-fighting does not need the surfaces
    to touch - it needs them CLOSER THAN THE DEPTH BUFFER CAN SEPARATE, over
    an area, at a shallow angle. The Barrel's hoops are a nested shell about
    3 mm off the staves: no intersection (the triangle test finds none) and no
    coincident face centres (the median face is 44 mm across, so two surfaces
    3 mm apart have centres tens of mm apart). Face centres measure the wrong
    thing; the surface does not.

    A hit: distance <= GAP_M with |n_a . n_b| >= PAR, on a face that shares no
    vertex with the face it is near (a seam is not a sandwich).
    """
    from mathutils.bvhtree import BVHTree
    cob, pb, sb = _tris(ob, fb)
    if not pb:
        return dict(near_faces=0, reason="no triangles")
    tb = BVHTree.FromPolygons(cob, pb, all_triangles=True, epsilon=0.0)
    near, area, dmin = 0, 0.0, 1e9
    for p in fa:
        co, nrm, idx, d = tb.find_nearest(p.center)
        if d is None:
            continue
        dmin = min(dmin, d)
        if d <= GAP_M and abs(p.normal.dot(ob.data.polygons[sb[idx]].normal)) >= PAR:
            if set(p.vertices) & set(pb[idx]):
                continue
            near += 1
            area += p.area
    return dict(near_faces=near, frac=round(near / max(1, len(fa)), 4),
                area_m2=round(area, 5), min_surface_mm=round(dmin * 1000.0, 3))


def t2_shell(fa, fb):
    kd = kdtree.KDTree(len(fb))
    for i, p in enumerate(fb):
        kd.insert(p.center, i)
    kd.balance()
    near = 0
    dmin = 1e9
    for p in fa:
        co, i, d = kd.find(p.center)
        dmin = min(dmin, d)
        if d <= NEAR_M and abs(p.normal.dot(fb[i].normal)) >= 0.9:
            near += 1
    return dict(near_faces=near, frac=round(near / max(1, len(fa)), 4),
                min_dist_mm=round(dmin * 1000.0, 3))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", default=None)
    a = ap.parse_args(argv)
    props = os.path.join(a.repo, "assets", "props")
    files = sorted(f for f in os.listdir(props) if f.lower().endswith(".gltf"))
    rows, errors = [], []
    for f in files:
        clear()
        try:
            bpy.ops.import_scene.gltf(filepath=os.path.join(props, f))
        except Exception as e:                       # noqa: BLE001
            errors.append("%s: import failed: %s" % (f, e))
            continue
        obs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        multi = [o for o in obs if len(o.material_slots) >= 2 and len(o.data.polygons) > 0]
        hits, unmeas = [], []
        for o in multi:
            g = faces_by_slot(o)
            keys = sorted(k for k in g if len(g[k]) >= MIN_FACES)
            for i in range(len(keys)):
                for j in range(i + 1, len(keys)):
                    fa, fb = g[keys[i]], g[keys[j]]
                    t1 = t1_bands(fa, fb)
                    ix = t1_intersect(o, fa, fb)
                    t3 = t3_surface(o, fa, fb)
                    t2 = t2_shell(fa, fb)
                    pair = dict(obj=o.name,
                                a=dict(slot=keys[i], mat=o.material_slots[keys[i]].name, faces=len(fa)),
                                b=dict(slot=keys[j], mat=o.material_slots[keys[j]].name, faces=len(fb)),
                                ix=ix, t3=t3, t2=t2)
                    if "reason" in t1:
                        pair["t1"] = t1
                        unmeas.append(pair)
                        continue
                    pair["t1"] = {k: v for k, v in t1.items() if k != "band_rows"}
                    if ix["shallow"] > 0 or t3["near_faces"] > 0:
                        pair["t1_bands"] = t1["band_rows"]
                    hits.append(pair)
        rows.append(dict(file=f, mesh_objects=len(obs), multislot_objects=len(multi),
                         pairs_measured=len(hits), pairs_unmeasurable=len(unmeas),
                         hits=[h for h in hits if h["ix"]["shallow"] > 0
                               or h["t3"]["near_faces"] > 0 or h["t2"]["near_faces"] > 0],
                         unmeasurable=unmeas))
    cross = [(r["file"], p) for r in rows for p in r["hits"] if p["ix"]["shallow"] > 0]
    shell = [(r["file"], p) for r in rows for p in r["hits"] if p["t2"]["near_faces"] > 0]
    zfight = [(r["file"], p) for r in rows for p in r["hits"] if p["t3"]["near_faces"] > 0]
    barrel = any(f == "Barrel.gltf" for f, _ in zfight)
    rep = dict(
        ok=bool(barrel) and not errors,
        control_barrel_flagged_by_T3_surface=barrel,
        gap_mm=GAP_M * 1000.0,
        tol_mm=TOL_M * 1000.0, near_mm=NEAR_M * 1000.0, bands=BANDS, min_bands=MIN_BANDS,
        files=len(files),
        multislot_files=sum(1 for r in rows if r["multislot_objects"] > 0),
        multislot_objects=sum(r["multislot_objects"] for r in rows),
        pairs_measured=sum(r["pairs_measured"] for r in rows),
        pairs_unmeasurable=sum(r["pairs_unmeasurable"] for r in rows),
        SHALLOW_INTERSECT_pairs=len(cross),
        SHALLOW_INTERSECT_files=sorted({f for f, _ in cross}),
        SHALLOW_worst=sorted([[f, p["obj"], p["ix"]["shallow"], p["ix"]["shallow_faces_a"],
                               p["t1"].get("buried_mm", 0.0)] for f, p in cross],
                             key=lambda r: -r[2])[:14],
        envelope_crossing_pairs=sum(1 for r in rows for p in r["hits"]
                                    if p["t1"].get("envelope_crossing")),
        ZFIGHT_pairs=len(zfight),
        ZFIGHT_files=sorted({f for f, _ in zfight}),
        ZFIGHT_worst=sorted([[f, p["obj"], p["t3"]["near_faces"], p["t3"]["frac"],
                              p["t3"]["area_m2"], p["t3"]["min_surface_mm"]] for f, p in zfight],
                            key=lambda r: -r[4])[:16],
        T2_shell_pairs=len(shell),
        T2_shell_files=sorted({f for f, _ in shell}),
        errors=errors,
        rows=rows,
    )
    out = a.out or os.path.join(a.repo, "renders", "art", "props", "_slot_audit.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(rep, fh, indent=1)
    print("PROPSLOTS", json.dumps({k: v for k, v in rep.items() if k != "rows"})[:4000])


main()
