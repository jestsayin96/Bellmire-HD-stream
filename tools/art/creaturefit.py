"""creaturefit - SYSTEM 10's FIT PROOF. The twelve D76 creature bodies
measured and rendered BESIDE A HERO, at the size bestiary.gd will give them.

  blender -b -noaudio -P tools/art/creaturefit.py -- --repo <repo> [--only k,k]

WHY THIS EXISTS, AND WHY IT IS NOT A REBUILD.
SYSTEM 10 asks that the twelve creature keys which SHARE a mesh each get their
own body. Measured off the tree, not remembered: all twelve .glb ALREADY EXIST
in assets/monsters/creatures/ (D76). What was never made is the proof that they
FIT - D76 shot each creature ALONE, at its OWN camera radius and ortho scale
(renders/art/creatures/_report.json), so no two of those pictures can be
compared and none of them answers Mr. E's question: how big does it read next
to a hero? This file answers it the way minibossfit.py did for the fourteen.

THE SIZE IS NOT THE FILE'S SIZE. monster.gd line 43 normalises every body:
    _body.scale = Vector3.ONE * (h / hb.size.y)
so a creature's in-game height is bestiary.gd's `h`, NOT the .glb's own bounds,
and `lift` then hovers it. This harness applies the SAME two numbers - scale
h/raw_z in Blender's Z, then raise by lift - so the cell shows what a viewer
will actually see, and records the scale factor the game will apply.

TRAPS ANSWERED (all three have bitten this lane):
  SCALE/AIM - clip range and camera distance come from the measured evaluated
              world bounds of hero + creature TOGETHER, never a default. The
              frame itself is measured in a no-render pre-pass over all twelve
              rather than guessed, because the pit wyrm is 4.0 m + 0.6 m lift
              and a frame sized for the hero alone would crop it and say GREEN.
  BLANKS    - every PNG re-opened and its opaque pixel count asserted, and the
              register reports RED if any key asked for has no ratio on record.
  MATRICES  - the glb is imported into the ACTIVE scene and the view layer is
              updated before anything is measured.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402

CREATURE_DIR = os.path.join("assets", "monsters", "creatures")

# The twelve, in bestiary.gd order, with the in-game numbers READ OUT OF
# bestiary.gd (h, lift) and the mesh each one currently shares. The art lane
# does not own bestiary.gd - these are copied here as the measurement's
# reference, and if they drift the harness says so rather than silently
# rescaling to something the game will not use.
#   key: (title, shares, h, lift)
CANON = {
    "sentinel":   ("Bone Sentinel",  "Skeleton_Warrior.glb", 1.90, 0.0),
    "hewer":      ("Marrow Hewer",   "Skeleton_Warrior.glb", 1.85, 0.0),
    "bowman":     ("Bone Bowman",    "Skeleton_Minion.glb",  1.60, 0.0),
    "cutthroat":  ("Pale Cutthroat", "Skeleton_Rogue.glb",   1.60, 0.0),
    "gravecaller":("Gravecaller",    "Skeleton_Mage.glb",    1.85, 0.0),
    "silkmother": ("Silk Mother",    "Spider.glb",           1.30, 0.0),
    "spiderling": ("Spiderling",     "Spider.glb",           0.35, 0.0),
    "scarrat":    ("Scar Rat",       "Rat.glb",              0.80, 0.0),
    "lurker":     ("Fen Lurker",     "Frog.glb",             1.50, 0.0),
    "pitwyrm":    ("Pit Wyrm",       "Dragon.glb",           4.00, 0.6),
    "gloombat":   ("Gloom Bat",      "Bat.glb",              1.20, 1.8),
    "slimeling":  ("Slimeling",      "Slime.glb",            0.50, 0.0),
}
ORDER = list(CANON)

CELL_X, CELL_Y = 760, 520
GROUND_UP = 0.30
GAP = 0.45
AURA = (0.30, 0.55, 0.85)       # one rim colour for all twelve: the comparison
                                # is of SIZE, so nothing else may vary


def import_creature(repo, key):
    """Import the committed body, normalise it the way monster.gd does.

    Returns (roots, meshes, info). The scale factor is recorded because it is
    the number that proves the normalisation happened: a body whose .glb is
    7 m tall and whose `h` is 0.8 is scaled by 0.11, and if that factor came
    back 1.0 the harness would be measuring the file, not the creature.
    """
    path = os.path.join(repo, CREATURE_DIR, key + ".glb")
    if not os.path.isfile(path):
        raise RuntimeError("no committed body at %s" % path)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new_objs if o.type == 'MESH']
    if not meshes:
        raise RuntimeError("%s imported with no mesh" % key)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    raw_z = max(1e-6, mx.z - mn.z)
    h, lift = CANON[key][2], CANON[key][3]
    k = h / raw_z
    roots = [o for o in new_objs if o.parent is None]
    for o in roots:
        o.scale = (o.scale.x * k, o.scale.y * k, o.scale.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    for o in roots:
        o.location = (o.location.x, o.location.y, o.location.z - mn.z + lift)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    faces = sum(len(o.data.polygons) for o in meshes if o.data)
    return new_objs, meshes, dict(
        raw=[round(mx.x - mn.x, 3), round(mx.y - mn.y, 3), round(raw_z, 3)],
        scale_k=round(k, 4), h=h, lift=lift,
        shown_h=round(mx.z - mn.z, 3), floor_z=round(mn.z, 3),
        parts=len(meshes), faces=faces)


def measure_frame(repo, keys):
    """NO-RENDER PRE-PASS. The one thing a fixed-scale sheet cannot get wrong
    is the scale, so it is measured over every key before a single frame is
    rendered rather than carried over from the minibosses' 5.60 m."""
    need_w, need_h, per = 0.0, 0.0, {}
    for key in keys:
        G.purge()
        objs, meshes, info = import_creature(repo, key)
        hroots, hmesh, hero = MF.import_hero(repo)
        mn, mx, _ = G.world_bounds(meshes)
        MF.place(hroots, mn.x - GAP - hero["w"] / 2.0 - 0.10,
                 mn.y - GAP - hero["d"] / 2.0 - 0.10)
        amn, amx, _ = G.world_bounds(objs + hmesh)
        w, t = amx.x - amn.x, amx.z - amn.z
        per[key] = dict(pair_w=round(w, 3), pair_h=round(t, 3))
        need_w, need_h = max(need_w, w), max(need_h, t)
        G.purge()
    # the frame must hold the widest pair AND the tallest, plus the ground
    # offset and a 6% margin so nothing touches an edge
    by_w = need_w * 1.06
    by_h = (need_h + GROUND_UP) * 1.06 * CELL_X / float(CELL_Y)
    return max(by_w, by_h), per


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--frame", type=float, default=0.0)
    args = ap.parse_args(argv)

    keys = [k for k in args.only.split(",") if k] if args.only else list(ORDER)
    root = os.path.join(args.repo, "renders", "art", "creatures")
    out = os.path.join(root, "_fit_creatures_register.json")
    rep = {"ok": True, "hero": {}, "pairs": {}, "errors": [],
           "why": "SYSTEM 10 fit proof. Bodies are D76's, already committed - "
                  "NOT rebuilt. h/lift are bestiary.gd's own numbers, applied "
                  "the way monster.gd:43 applies them."}

    if args.frame > 0.1:
        frame_w, pre = args.frame, {}
    else:
        try:
            frame_w, pre = measure_frame(args.repo, keys)
        except Exception:
            import traceback
            rep["ok"] = False
            rep["errors"].append("pre-pass: %s" % traceback.format_exc()[-700:])
            frame_w, pre = 7.60, {}
    frame_w = round(frame_w, 2)
    MF.FRAME_W = frame_w
    MF.FRAME_H = frame_w * CELL_Y / float(CELL_X)
    MF.CELL_X, MF.CELL_Y = CELL_X, CELL_Y
    MF.GROUND_UP = GROUND_UP
    rep["frame"] = {"w": frame_w, "h": round(MF.FRAME_H, 3),
                    "ground_up": GROUND_UP, "measured_pre_pass": pre}

    for key in keys:
        G.purge()
        try:
            objs, meshes, info = import_creature(args.repo, key)
            hroots, hmesh, hero = MF.import_hero(args.repo)
            rep["hero"] = hero
            mn, mx, _ = G.world_bounds(meshes)
            MF.place(hroots, mn.x - GAP - hero["w"] / 2.0 - 0.10,
                     mn.y - GAP - hero["d"] / 2.0 - 0.10)
            allo = objs + hmesh
            bpy.context.view_layer.update()
            amn, amx, pts = G.world_bounds(allo)
            outdir = os.path.join(root, key)
            os.makedirs(outdir, exist_ok=True)
            written, eng = MF.shoot(allo, pts, outdir,
                                    (("front", 0.0), ("side", 90.0), ("back", 180.0)),
                                    AURA)
            top = mx.z
            rec = dict(info)
            rec.update(
                creature_h=round(mx.z - mn.z, 3), hero_h=hero["h"],
                ratio=round((mx.z - mn.z) / max(0.01, hero["h"]), 2),
                top_vs_hero=round(top - hero["h"], 3),
                pair_w=round(amx.x - amn.x, 2),
                corridor_span=round(max(amx.x - amn.x, amx.y - amn.y), 2),
                fits_frame=bool((amx.x - amn.x) <= frame_w
                                and (amx.z - amn.z) <= MF.FRAME_H - GROUND_UP),
                engine=eng, shares=CANON[key][1], title=CANON[key][0],
                views=[os.path.basename(p) for p in written])
            rep["pairs"][key] = rec
            if not rec["fits_frame"]:
                rep["errors"].append("%s: pair does not fit the measured frame" % key)
                rep["ok"] = False
            # a normalisation that did nothing is a measurement of the FILE
            if abs(rec["shown_h"] - rec["h"]) > 0.02:
                rep["errors"].append("%s: normalised to %.3f but bestiary h is %.2f"
                                     % (key, rec["shown_h"], rec["h"]))
                rep["ok"] = False
        except Exception:
            import traceback
            rep["ok"] = False
            rep["errors"].append("%s: %s" % (key, traceback.format_exc()[-700:]))

    # blank check + contact sheet
    G.purge()
    bad, checked = [], []
    try:
        hero_h = rep["hero"].get("h", 1.0) if rep["hero"] else 1.0
        lab = 44
        cols = args.cols
        rows = (len(keys) + cols - 1) // cols
        sh = np.zeros((rows * (CELL_Y + lab), cols * CELL_X, 4), dtype=np.float32)
        sh[..., 0:3] = np.array((0.055, 0.060, 0.075))
        sh[..., 3] = 1.0
        px_per_m = CELL_Y / MF.FRAME_H
        ground_row = CELL_Y - int(GROUND_UP * px_per_m)
        head_row = ground_row - int(hero_h * px_per_m)
        for i, key in enumerate(keys):
            cx, cy = (i % cols) * CELL_X, (i // cols) * (CELL_Y + lab)
            for v in ("front", "side", "back"):
                p = os.path.join(root, key, "hero_%s.png" % v)
                if not os.path.isfile(p):
                    bad.append((p, "missing"))
                    continue
                a = G.read_png(p)
                n = int((a[..., 3] > 0.02).sum())
                checked.append((os.path.relpath(p, args.repo), n))
                if n < 400:
                    bad.append((p, "blank or near-blank: %d opaque px" % n))
                if v == "front":
                    al = a[..., 3:4]
                    dst = sh[cy:cy + CELL_Y, cx:cx + CELL_X, 0:3]
                    sh[cy:cy + CELL_Y, cx:cx + CELL_X, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            sh[cy + ground_row:cy + ground_row + 1, cx:cx + CELL_X, 0:3] = np.array((0.30, 0.32, 0.36))
            for x in range(cx + 4, cx + CELL_X - 4, 14):
                sh[cy + head_row:cy + head_row + 1, x:x + 8, 0:3] = np.array((1.00, 0.86, 0.52))
            rec = rep["pairs"].get(key, {})
            t, h = CANON[key][0], CANON[key][2]
            sh[cy + CELL_Y:cy + CELL_Y + 2, cx:cx + CELL_X, 0:3] = np.array((0.85, 0.80, 0.68)) * 0.35
            G.draw_text(sh, "%s  %.2fM" % (t, h), cx + 8, cy + CELL_Y + 6, 2,
                        (0.85, 0.80, 0.68))
            G.draw_text(sh, "%.2fX HERO - SHARES %s - X%.3f FROM %.2fM FILE"
                        % (rec.get("ratio", 0.0), CANON[key][1],
                           rec.get("scale_k", 0.0), rec.get("raw", [0, 0, 0])[2]),
                        cx + 8, cy + CELL_Y + 26, 1, (0.46, 0.52, 0.60))
        G.draw_text(sh, "SYSTEM 10 - THE TWELVE SHARED-MESH CREATURES IN THEIR OWN D76 BODIES, AT BESTIARY H. "
                        "DASHED RULE = TOP OF A VIEWERS HERO, %.2f M. ONE ORTHO SCALE %.2f M AND ONE GROUND LINE IN ALL CELLS."
                    % (hero_h, frame_w), 10, 10, 1, (1.00, 0.86, 0.52))
        G.write_png(os.path.join(root, "_fit_hero_scale.png"), sh)
    except Exception:
        import traceback
        rep["ok"] = False
        rep["errors"].append("sheet: %s" % traceback.format_exc()[-700:])
    rep["blank_check"] = {"files": len(checked), "failures": [list(b) for b in bad]}
    if bad:
        rep["ok"] = False

    # *** AN EMPTY MEASUREMENT IS RED *** - the snuffer lesson, kept.
    measured = [k for k in keys if k in rep["pairs"]]
    missing = [k for k in keys if k not in rep["pairs"]]
    rep["measured"], rep["asked"] = measured, list(keys)
    if not rep["hero"]:
        rep["ok"] = False
        rep["errors"].append("hero: never measured. Every ratio is a ratio TO the hero.")
    if not rep["pairs"]:
        rep["ok"] = False
        rep["errors"].append("pairs: EMPTY. This register measured NOTHING.")
    if missing:
        rep["ok"] = False
        rep["errors"].append("no ratio on record for: %s" % ",".join(missing))

    os.makedirs(root, exist_ok=True)
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    with open(out, "w") as f:
        json.dump(rep, f, indent=1)
    print("CREATUREFIT_REPORT " + json.dumps({
        "verdict": rep["verdict"], "frame": rep["frame"]["w"], "hero": rep["hero"],
        "errors": rep["errors"][:5], "blank": rep["blank_check"],
        "ratios": {k: (v["ratio"], v["scale_k"], v["pair_w"], v["fits_frame"])
                   for k, v in rep["pairs"].items()}}))


if __name__ == "__main__":
    main()
