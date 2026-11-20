"""worldfit - MEASURE A WHOLE DIRECTORY OF WORLD-PLACED ART, so the game
build can wire a pack directory per cycle instead of one barrel at a time.

  blender -b -noaudio -P tools/art/worldfit.py -- --repo <repo> --dir assets/props
                                                  [--geom-repo <shipping tree>]

WHY, 20 Nov 2026 07:5x CT. Mr. E's 07:24 directive: wire an ENTIRE PACK
DIRECTORY per cycle, 10-20 assets, and Tier 1 is the world-placed systems -
town buildings (15), dungeon props (47), nature (68). The art lane's job on a
pack it did not model is NOT to re-model it: it is to hand the game build the
numbers that decide placement, and to say which files cannot be placed as they
stand. A run that tells the game build exactly what to wire is worth more than
a run that makes something new (Mr. E, 16 Nov 04:46).

WHAT IS MEASURED, per file, off the EVALUATED depsgraph (lordgen.world_bounds -
modifiers and parenting applied; an object that is not the active one never
gets its matrix_world evaluated, which has aimed a camera at empty space in
this lane before):

  dims_m x/y/z      world-space AABB after import, metres
  footprint_m       max(x, y) - the term the corridor gate takes
  height_m          z extent
  base_dz_m         min_z. *** THE PLACEMENT NUMBER. *** A model whose pivot is
                    at its own centre sinks half its height into the floor when
                    a spawner puts it at y=0. Positive floats, negative sinks.
  centre_dx/dy_m    how far the footprint centre sits off the pivot, so a
                    spawner can centre a prop in a cell instead of in its file
  cells             ceil(footprint / floorgen's G) - how many corridor cells it eats
  corridor / lid    floorgeom's two-term verdict against the SHIPPING tree
  unit_flag         authored-scale suspicion: a 7 mm barrel is a cm/m mix-up,
                    not a small barrel (models in this repo run from ~2 to ~700
                    units and a default clip_end has rendered empty before)

*** GOES RED ON EMPTY, AND ON ZERO. *** A file that imports no mesh is an error
row, never an omission; a run that measured no files at all prints RED. A
manifest that quietly skipped the half of the pack it could not read would be
the decorative-gate fault this lane has already shipped twice.

*** THE FLOORGEOM NUMBERS CARRY THEIR TREE. *** floorgeom.require_current()
refuses to write this manifest out of a worktree whose floorgen.gd no longer
agrees with origin/main's - the fault the team lead found in _leech_span.json
at 06:58 CT. Point --geom-repo at the tree that ships.
"""
import argparse
import json
import math
import os
import sys
import time

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G        # noqa: E402
import floorgeom as FG     # noqa: E402

EXT = (".glb", ".gltf")
# A human body is 1.80 m tall and the knight's own measured top is 1.30 m in
# model units; anything under 1 cm or over 60 m is flagged, not rejected.
TINY_M, HUGE_M = 0.01, 60.0
# Below this a base offset is modelling noise, not a placement instruction.
BASE_EPS_M = 0.05


def measure(path):
    """One file, in a FRESH empty scene. Returns a row dict; never raises."""
    row = {"file": os.path.basename(path), "errors": []}
    try:
        bpy.ops.wm.read_homefile(use_empty=True)
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        new = [o for o in bpy.data.objects if o not in before]
    except Exception as e:                                    # noqa: BLE001
        row["errors"].append("import failed: %r" % (e,))
        return row
    meshes = [o for o in new if o.type == "MESH"]
    row["objects"] = len(new)
    row["meshes"] = len(meshes)
    if not meshes:
        row["errors"].append("no meshes imported - NOT counted as a pass")
        return row
    bpy.context.view_layer.update()
    mn, mx, pts = G.world_bounds(meshes)
    row["verts"] = len(pts)
    mats = set()
    for o in meshes:
        for s in o.material_slots:
            if s.material:
                mats.add(s.material.name)
    row["materials"] = len(mats)
    dx, dy, dz = mx.x - mn.x, mx.y - mn.y, mx.z - mn.z
    row["dims_m"] = [round(dx, 4), round(dy, 4), round(dz, 4)]
    row["footprint_m"] = round(max(dx, dy), 4)
    row["height_m"] = round(dz, 4)
    row["base_dz_m"] = round(mn.z, 4)
    row["centre_dx_m"] = round((mn.x + mx.x) / 2.0, 4)
    row["centre_dy_m"] = round((mn.y + mx.y) / 2.0, 4)
    # *** THIS ARM CRIED WOLF ON ITS FIRST RUN AND THE PICTURE SETTLED IT. ***
    # It read `dz < 1 cm` and flagged Table_Fork (0.0505 x 0.2626 x 0.0062 m) as
    # a cm/m mix-up. That is a correctly authored 26 cm fork lying FLAT, 6 mm
    # thick. A unit mix-up shrinks ALL THREE axes, so only the LARGEST dimension
    # can carry the test; a thin axis is a shape, not a scale.
    if max(dx, dy, dz) < TINY_M:
        row["unit_flag"] = "SUSPECT TINY - largest axis under %g m: a cm/mm mix-up or an empty shell" % TINY_M
    elif max(dx, dy, dz) > HUGE_M:
        row["unit_flag"] = "SUSPECT HUGE - largest axis over %g m: another unit, or a whole scene" % HUGE_M
    else:
        row["unit_flag"] = None
    return row


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--dir", required=True, default=None, action="append",
                    help="repo-relative directory of .glb/.gltf; repeatable")
    ap.add_argument("--dungeon-dir", default=None, action="append",
                    help="a --dir whose contents are DUNGEON-placed, so floorgeom's "
                         "corridor and lid verdicts BIND. Everything else is "
                         "world/town-placed and gets the same numbers marked "
                         "informational - an 18 m tree is not ROOM-LOCKED in a town.")
    ap.add_argument("--geom-repo", default="")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)

    geom = FG.read(args.geom_repo or args.repo)
    prov = FG.require_current(geom)          # refuses a stale tree outright
    print("WORLDFIT " + FG.stamp(geom))
    cell = geom["cell_m"]
    if not cell:
        raise RuntimeError("floorgeom could not read the cell size - refusing to count cells")

    man = {"generated_ct": time.strftime("%Y-%m-%dT%H:%M:%S"),
           "floorgeom": {"corridor_clear_m": geom["corridor_clear_m"],
                         "lid_underside_m": geom["lid_underside_m"],
                         "cell_m": cell, "read_from": geom["at"],
                         "stamp": FG.stamp(geom), "drift": prov["drift"],
                         "read_from_tree": prov["repo"], "ref_commit": prov["ref_commit"]},
           "dirs": {}, "errors": []}

    total = 0
    for d in args.dir:
        root = os.path.join(args.repo, d)
        if not os.path.isdir(root):
            man["errors"].append("%s is not a directory" % d)
            continue
        files = sorted(f for f in os.listdir(root) if f.lower().endswith(EXT))
        rows = []
        for i, f in enumerate(files):
            row = measure(os.path.join(root, f))
            if row.get("footprint_m") is not None:
                v, errs = FG.verdict(geom, row["footprint_m"], row["height_m"])
                row["corridor"] = v["corridor"]
                row["corridor_margin_m"] = v["corridor_margin_m"]
                row["lid"] = v["lid"]
                row["lid_clear_m"] = v["lid_clear_m"]
                row["cells"] = int(math.ceil(row["footprint_m"] / cell)) or 1
                row["errors"] += errs
                # base_dz_m is NOT a fault on its own: it is how far the mesh
                # reaches below its own pivot. Place the pivot at floor level
                # and THAT much goes through the floor. Pedestal2's 15 mm is
                # modelling noise; Banner_1_Cloth's -2.25 m is a banner whose
                # pivot is its wall mount, and it would hang through the floor.
                # 5 cm is the line between noise and a placement number.
                row["needs_base_offset"] = abs(row["base_dz_m"]) > BASE_EPS_M
                row["base_note"] = ("sinks %.3f m below its pivot" % -row["base_dz_m"]
                                    if row["base_dz_m"] < -BASE_EPS_M else
                                    ("floats %.3f m above its pivot" % row["base_dz_m"]
                                     if row["base_dz_m"] > BASE_EPS_M else "pivot at the base"))
                row["needs_centring"] = (abs(row["centre_dx_m"]) > BASE_EPS_M
                                         or abs(row["centre_dy_m"]) > BASE_EPS_M)
            rows.append(row)
            total += 1
            print("WORLDFIT %s %d/%d %s %s" % (d, i + 1, len(files), f,
                                               row.get("dims_m") or row["errors"]))
            sys.stdout.flush()
        ok = [r for r in rows if not r["errors"]]
        binding = d in (args.dungeon_dir or [])
        for r in rows:
            r["verdict_scope"] = "dungeon (binding)" if binding else \
                "world/town - corridor and lid are INFORMATIONAL here"
        man["dirs"][d] = {
            "scope": "dungeon" if binding else "world",
            "files": len(files), "measured": len(ok), "failed": len(rows) - len(ok),
            ("room_locked" if binding else "wider_than_a_corridor_FYI"):
                sorted(r["file"] for r in ok if r["corridor"] == "ROOM-LOCKED"),
            ("through_lid" if binding else "taller_than_the_lid_FYI"):
                sorted(r["file"] for r in ok if r["lid"] == "THROUGH-LID"),
            "unit_flagged": sorted(r["file"] for r in ok if r["unit_flag"]),
            "needs_base_offset": sorted(r["file"] for r in ok if r["needs_base_offset"]),
            "tallest": max((r["height_m"] for r in ok), default=None),
            "widest_footprint_m": max((r["footprint_m"] for r in ok), default=None),
            "rows": rows,
        }

    out = args.out or os.path.join(args.repo, "renders", "art", "worldfit", "_manifest.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(man, f, indent=1, sort_keys=True)
    bad = sum(v["failed"] for v in man["dirs"].values()) + len(man["errors"])
    # RED ON ZERO: a manifest over no files is not a green manifest.
    print("WORLDFIT " + ("RED - measured 0 files" if total == 0 else
                         ("GREEN - %d files, 0 unreadable" % total if bad == 0 else
                          "AMBER - %d files, %d unreadable/erroring" % (total, bad))))
    print("WORLDFIT wrote " + out)
    return 0


if __name__ == "__main__":
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    sys.exit(main(a))
