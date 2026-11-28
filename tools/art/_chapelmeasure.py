"""_chapelmeasure - measure the pack modules the Chapel ladder may need, AND
LOOK AT EACH WALL CANDIDATE, before a single line of chapelgen.py is written.
BACKGROUND BLENDER ONLY (blender -b); never the live session.

  blender -b -noaudio -P tools/art/_chapelmeasure.py -- --out <json> --shots <dir>

WHY THIS IS NOT A COPY OF _hallmeasure.py
-----------------------------------------
`_hallmeasure.py` measured a HARDCODED list of 16 module names. That list was
written from the design doc, and the design doc had chosen
`Wall_Plaster_WoodGrid` because the NAME reads "timber-framed". The module is
an OPEN TIMBER LATTICE. The first Hall tier-1 render was a building you could
see straight through, and every gate in the house passed it - blank, border,
subject-moved and hero-seen are all blind to a lattice, because a lattice is
not blank, not clipped, not missing and not small. It is just not a wall.
That cost the 02:34 firing a pass, and it was caught by LOOKING.

So this script does two things that one did not:

  1. IT ENUMERATES THE PACK instead of trusting a name list. Anything matching
     the chapel patterns gets measured, and the choice is made afterwards from
     the table, not beforehand from a guess.
  2. IT RENDERS EVERY WALL-LIKE CANDIDATE FACE-ON AND RUNS townlib.solidity
     ON IT. A wall whose hole_frac is near a solid sibling's is a wall; one
     that sits far above it is a lattice, a railing or an arcade - whatever
     its name says. The number is comparative, so the table is sorted and the
     siblings are printed next to each other.

WHAT THIS STILL CANNOT SEE - stated so the next seat does not trust it blind:
  - A wall that is solid but the WRONG MATERIAL. hole_frac says nothing about
    colour, and the Hall's tier 2->3 step is already weak because both tiers
    wear the same plaster and the same red tile.
  - A GABLE HOLE. An opening at the silhouette edge reads as background, not
    as a hole - townlib.solidity says so itself, and the Hall shipped that
    hole twice before the side-by-side sheet caught it. A chapel with a
    two-slope roof over a box WILL have open gable triangles. Assume it.
  - Whether the piece is in Bellmire's voice. Only looking says that.
  - RED ON EMPTY is inherited from townlib.solidity: a silhouette under
    1000 px returns -1, not a comfortable zero.
"""
import argparse, glob, json, os, sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import townlib as T

W5 = r"C:\hd adventure\bellmire-art"
PACKS = [
    (r"C:\hd adventure\_packs\Medieval_Village_MegaKit"
     r"\Medieval Village MegaKit[Standard]\glTF"),
    # CASTLE IS REMOVED, AND NOT BECAUSE OF A PATH BUG.
    # Its 11 models DO exist, nested one level deeper at
    # `_packs\Castle\Castle\Castle_Building_Blocks\*.FBX`, and three of them
    # (Cathedral_Window, Cornice, Pillar_*) are the best chapel vocabulary on
    # this disk. They are STILL NOT USABLE: `docs/art/ASSET_SOURCES.md` (~line
    # 643, pack-catalogue firing 24 Nov) records **NO LICENCE FILE FOUND** for
    # this pack - no licence, readme, terms, credit or URL anywhere in the tree
    # or the zip, and an empty FBX author field. Status: NOT CLEARED, import
    # GATED until a licence is supplied by the source or by Mr. E.
    # Making the scan recursive would have "fixed" the zero-module error by
    # feeding UNLICENSED geometry into a shipping ladder. Deleted on purpose.
    # THE CLEARED CHAPEL SOURCE IS `Church1_blend` - Blendswap 75990 "Medieval
    # Church" by Daniel74, **CC0 1.0**, licence HTML read off disk (entry ~line
    # 369). It is a monolithic .blend/.dae, not a module kit, so it needs a
    # Collada/blend path rather than this glTF one.
]

# Patterns, NOT a chosen list. Everything that matches is measured and the
# wall-like ones are rendered. Choosing happens after, off the table.
PATTERNS = ["Wall_*", "Corner_*", "Roof_*", "Floor_*", "Stairs_*", "Prop_*",
            "Arch*", "Column*", "Pillar*", "Window*", "Door*", "Tower*",
            "Spire*", "Bell*", "*Chapel*", "*Church*", "*Temple*", "*Altar*"]
WALL_LIKE = ("Wall_", "Arch", "Column", "Pillar", "Window", "Door")


def bounds(objs):
    """World-space bounds off the EVALUATED depsgraph.

    TRAP 3: an object that is not the active one never gets matrix_world
    evaluated by some paths, so this walks the depsgraph explicitly."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in objs:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        mw = oe.matrix_world
        for c in oe.bound_box:
            pts.append(mw @ Vector(c))
    if not pts:
        return None, None, []
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, pts


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # MEASURED 28 Nov: Castle ships 11 .fbx and ZERO .gltf/.glb, so a gltf-only
    # importer silently contributes nothing from a pack the plan names as a root.
    if os.path.splitext(path)[1].lower() == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o.type == 'MESH']
    if objs:
        bpy.context.view_layer.objects.active = objs[0]
    bpy.context.view_layer.update()
    return objs


def measure(objs):
    mn, mx, pts = bounds(objs)
    if mn is None:
        return None, None
    c = (mn + mx) / 2.0
    mats = sorted({sl.material.name for o in objs for sl in o.material_slots
                   if sl.material is not None})
    return {
        "dims": [round(mx.x - mn.x, 4), round(mx.y - mn.y, 4), round(mx.z - mn.z, 4)],
        "min": [round(v, 4) for v in mn], "max": [round(v, 4) for v in mx],
        "centre": [round(v, 4) for v in c],
        "n_mesh": len(objs),
        "n_tri": sum(len(o.data.polygons) for o in objs),
        "materials": mats,
    }, (mn, mx, pts)


def shoot_face_on(objs, box, out_png):
    """Render the module face-on so solidity() has something to scan.

    TRAP 1: the camera distance and clip planes come from the MEASURED bounds,
    never from a default. A clip_end of 100 on a 700-unit animal renders an
    empty transparent frame AND REPORTS SUCCESS."""
    mn, mx, pts = box
    centre = (mn + mx) / 2.0
    radius = max((mx - mn).length / 2.0, 1e-4)
    scene = bpy.context.scene
    T.scene_setup(900, 900)
    cam, cam_d = T.new_ortho_cam(scene)
    # azimuth 0 = face-on to +Y, elevation 0 = dead level: a lattice can only
    # be told from a wall head-on. An angled shot fills its own gaps.
    T.aim_cam(cam, cam_d, pts, centre, radius, 0.0, 0.0, 900, 900)
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--shots", required=True)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    os.makedirs(a.shots, exist_ok=True)

    rep = {"packs": PACKS, "modules": {}, "solidity": {}, "errors": [],
           "note": "module choice is NOT made here; it is made off this table"}

    found = {}
    for pk in PACKS:
        if not os.path.isdir(pk):
            rep["errors"].append("MISSING PACK %s" % pk)
            continue
        before = len(found)
        # FIX 28 Nov 10:5x CT: the MegaKit's own directory is
        # `Medieval Village MegaKit[Standard]`, and `glob` reads `[Standard]` as a
        # CHARACTER CLASS matching one of {S,t,a,n,d,r}. The pattern therefore
        # matched no real directory and this pass reported
        # "NO MODULES MATCHED - patterns or pack paths are wrong" with the paths
        # perfectly correct. PROVEN before fixing: naive glob 0 hits, escaped 20.
        # glob.escape() the DIRECTORY only - the pattern itself must stay live.
        for pat in PATTERNS:
            for ext in ("gltf", "glb", "fbx"):
                for p in glob.glob(os.path.join(glob.escape(pk), pat + "." + ext)):
                    found[os.path.splitext(os.path.basename(p))[0]] = p
        # FIX 3: RED ON EMPTY *PER PACK*. The old check only fired when EVERY pack
        # came back empty, so one silently-dead pack read as a clean run.
        if len(found) == before:
            rep["errors"].append(
                "PACK CONTRIBUTED ZERO MODULES - %s (patterns, extension or path)" % pk)
    if not found:
        rep["errors"].append("NO MODULES MATCHED - patterns or pack paths are wrong")

    for name in sorted(found):
        p = found[name]
        try:
            objs = load(p)
            m, box = measure(objs)
            if m is None:
                rep["errors"].append("NO MESH %s" % name)
                continue
            rep["modules"][name] = m
            if name.startswith(WALL_LIKE):
                png = os.path.join(a.shots, "_faceon_%s.png" % name)
                shoot_face_on(objs, box, png)
                s = T.solidity(png)
                s["png"] = os.path.relpath(png, W5).replace("\\", "/")
                # RED ON EMPTY is inherited: hole_px -1 means the subject did
                # not render, which is a FAULT, not a clean wall.
                if s.get("red_on_empty"):
                    rep["errors"].append(
                        "RED ON EMPTY - %s rendered under 1000 px, shot is bad" % name)
                rep["solidity"][name] = s
        except Exception as e:                                  # noqa: BLE001
            rep["errors"].append("%s: %s" % (name, e))

    # Sort the wall verdict so siblings sit next to each other and a lattice
    # stands out from the walls it is named like.
    rep["solidity_sorted"] = sorted(
        ((k, v.get("hole_frac", -1.0)) for k, v in rep["solidity"].items()),
        key=lambda kv: kv[1])

    with open(a.out, "w") as f:
        json.dump(rep, f, indent=1)
    print("CHAPELMEASURE " + json.dumps(
        {"n_modules": len(rep["modules"]), "n_walls_shot": len(rep["solidity"]),
         "errors": rep["errors"][:12],
         "solidity_sorted": rep["solidity_sorted"]}))


main()
