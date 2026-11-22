"""xbowparts - THE PARTS THE PACK CROSSBOWS DO NOT HAVE: stirrup, string, bolt.

WHY. System 2's crossbow cell has been red since 14:3x on 21 Nov for one
reason a viewer would recognise: "a flat plank forward of the hand and nothing
anyone would call a crossbow". The camber hypothesis was REFUTED by this lane
(show 0.643 against SHOW_MIN 0.70) and the 35 deg roll is the game build's to
land in gear.gd. What is left, and what the team lead named as the next art
route, is that there is NO BOWSTRING AND NO STIRRUP on any of the three. The
prod is a bare lath, so even a correctly carried crossbow reads as a tray.

A stirrup hangs PERPENDICULAR to the prod, so it has silhouette where the prod
has none - which is why it reads from the side view, the one view that shows
the plank at its worst.

WHAT IS HONEST ABOUT THIS AND WHAT IS NOT, SAID BEFORE THE NUMBERS:
  * `show` is a BBOX-MINOR measure and the grip ALREADY hangs to local z
    -0.1145. A stirrup at the nose cannot move a bbox the grip already sets,
    so THIS DOES NOT CLOSE THE LATH and I do not claim it does. The roll does.
  * adding geometry can only GROW a local extent, and `show`'s denominator is
    the local MIDDLE extent, so every part here can only push `show` DOWN or
    leave it. There is no direction in which this change can buy itself an
    unearned pass - the opposite of the camber route, which shrank the very
    extent it was divided by. The parts are nonetheless built INSIDE the
    existing Y envelope so the denominator is provably untouched, and
    _s2_stirrup_ab.py prints the before/after mid extent rather than asserting.

EVERYTHING IS AUTHORED IN THE MESH'S OWN LOCAL FRAME (the glTF importer frame,
measured by _s2_xbow_probe*.py, NOT guessed):
    +X  prod across, symmetric          common +-0.3455
    +Y  butt (+0.105) ... nose (-0.533); the prod belly reaches y -0.533 at
        |x| ~0.15 and the lath TIPS recurve BACK to y ~-0.30 at |x| 0.345
    +Z  up; stock top ~+0.08, stock underside at the nose ~-0.008, grip -0.1145
NO CARRY ROTATION IS BAKED IN. The 35 deg roll is gear.gd's, this hour; a
baked roll would double it. Refusing that bake was right and it stays refused.

WEAR IS A VARIABLE (rule 2): common is thin rough iron on a stone-grey prod,
uncommon a heavier strap, rare a thicker, cleaner, taller loop in the tier's
own gold - the receipt for what the viewer paid for, not a bigger crossbow.
"""
import math

import bmesh
import bpy
from mathutils import Vector

# per tier: (metal material for the stirrup, cord material, strap thickness,
#            strap width across X, loop depth in Z, loop length in Y)
TIER = {
    "common":   ("Stone",  "WoodDark",  0.030, 0.050, 0.132, 0.150),
    "uncommon": ("Metal",  "BrownDark", 0.035, 0.055, 0.140, 0.156),
    "rare":     ("Gold",   "White",     0.042, 0.062, 0.150, 0.160),
}
CORD = {"common": 0.012, "uncommon": 0.013, "rare": 0.014}


def _mat(obj, name):
    """Slot index of a material already on the mesh. RED ON MISSING: a part
    silently falling back to slot 0 is how a gold crossbow ships a grey loop."""
    # Blender suffixes a re-imported datablock (".001"); the A/B harness imports
    # both variants in one session, so the slot must be matched on the stem.
    for i, m in enumerate(obj.data.materials):
        if m is not None and m.name.split(".")[0] == name:
            return i
    raise RuntimeError("%s: no material %r on the mesh (has %s) - refusing to "
                       "guess a slot" % (obj.name, name,
                                         [m.name if m else None for m in obj.data.materials]))


def _tube(bm, path, half_x, half_r, mat_i):
    """Square-section tube along a polyline lying in the Y-Z plane.

    half_x is the half width ACROSS the prod (a flat strap, not a wire);
    half_r is the half thickness in the path's own radial direction.
    """
    rings = []
    n = len(path)
    for i, p in enumerate(path):
        nxt = path[min(i + 1, n - 1)]
        prv = path[max(i - 1, 0)]
        t = (Vector(nxt) - Vector(prv))
        if t.length < 1e-9:
            t = Vector((0.0, 1.0, 0.0))
        t.normalize()
        # radial in the Y-Z plane: the tangent turned 90 deg
        rad = Vector((0.0, -t.z, t.y)).normalized()
        c = Vector(p)
        rings.append([bm.verts.new(c + rad * half_r + Vector((sx * half_x, 0, 0)))
                      for sx in (-1, 1)]
                     + [bm.verts.new(c - rad * half_r + Vector((sx * half_x, 0, 0)))
                        for sx in (1, -1)])
    faces = []
    for i in range(n - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(4):
            faces.append(bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k])))
    # cap both ends so the piece is closed (the clip test ray-casts it)
    faces.append(bm.faces.new(tuple(rings[0])))
    faces.append(bm.faces.new(tuple(reversed(rings[-1]))))
    for f in faces:
        f.material_index = mat_i
    return faces


def add_parts(obj, tier, with_stirrup=True, with_string=True, with_bolt=True):
    """Add the missing parts to an imported pack crossbow, IN PLACE.

    Returns a dict of what was built, for the register. Measures its own
    anchors off the mesh rather than trusting the numbers in this docstring:
    the three tiers are DIFFERENT SIZES (common prod 0.691, rare 1.045) and a
    hard-coded tip would put the rare crossbow's string in mid air.
    """
    metal_name, cord_name, strap_t, strap_w, loop_dz, loop_dy = TIER[tier]
    mi_metal, mi_cord = _mat(obj, metal_name), _mat(obj, cord_name)
    cord_r = CORD[tier]

    mw = obj.matrix_world
    pts = [mw @ v.co for v in obj.data.vertices]
    mny = min(p.y for p in pts)
    mxy = max(p.y for p in pts)
    mxx = max(p.x for p in pts)
    mxz = max(p.z for p in pts)

    # --- lath tips, MEASURED: the outermost 6% of the prod span
    tipband = [p for p in pts if p.x > mxx * 0.94]
    assert tipband, "no prod tip band found - refusing to anchor a string on nothing"
    tip_y = sum(p.y for p in tipband) / len(tipband)
    tip_z = sum(p.z for p in tipband) / len(tipband)
    tip_x = mxx - cord_r

    # --- the nut: the top of the stock behind the prod, measured
    # the nut sits on the stock's TOP at its own Y, measured there and nowhere
    # else: a max taken over the whole butt would put it on top of the grip.
    nut_y = tip_y + (mxy - tip_y) * 0.45
    nutband = [p for p in pts if abs(p.x) < 0.07 and abs(p.y - nut_y) < 0.07 * (mxy - mny) + 0.03]
    assert nutband, "no stock top at the nut's Y - refusing to float a string"
    nut_z = max(p.z for p in nutband) + cord_r * 0.6

    # --- the stock underside at the nose, measured, so the loop hangs off wood
    nose_band = [p for p in pts if p.y < mny + 0.09 * (mxy - mny) and abs(p.x) < 0.08]
    assert nose_band, "no nose band - refusing to hang a stirrup in mid air"
    under_z = min(p.z for p in nose_band)
    loop_y0 = mny + 0.004                 # INSIDE the envelope: Y extent unchanged
    loop_y1 = loop_y0 + loop_dy
    cy = (loop_y0 + loop_y1) / 2.0
    top_z = under_z + strap_t * 0.5       # the strap's top sits in the stock
    bot_z = top_z - loop_dz

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    # bmesh works in LOCAL coords; everything above is in the importer frame
    mwi = mw.inverted()

    built = {}
    if with_stirrup:
        # a plain oval loop, flattened on top where it meets the stock
        ry, rz = (loop_y1 - loop_y0) / 2.0, (top_z - bot_z) / 2.0
        czm = (top_z + bot_z) / 2.0
        path = []
        N = 18
        for i in range(N + 1):
            a = 6.283185307 * i / N
            sy, sz = math.sin(a), math.cos(a)
            zz = czm + rz * sz * (0.80 if sz > 0 else 1.0)   # flatter crown
            path.append(mwi @ Vector((0.0, cy + ry * sy, zz)))
        _tube(bm, path, strap_w * 0.5, strap_t * 0.5, mi_metal)
        built["stirrup"] = {"y": [round(loop_y0, 4), round(loop_y1, 4)],
                            "z": [round(bot_z, 4), round(top_z, 4)],
                            "strap_t": strap_t, "strap_w": strap_w,
                            "hung_from_under_z": round(under_z, 4)}
    if with_string:
        for sx in (-1.0, 1.0):
            path = [mwi @ Vector((sx * tip_x, tip_y, tip_z)),
                    mwi @ Vector((sx * tip_x * 0.45, (tip_y + nut_y) / 2.0,
                                  (tip_z + nut_z) / 2.0)),
                    mwi @ Vector((0.0, nut_y, nut_z))]
            _tube(bm, path, cord_r, cord_r, mi_cord)
        built["string"] = {"tip": [round(tip_x, 4), round(tip_y, 4), round(tip_z, 4)],
                           "nut": [round(nut_y, 4), round(nut_z, 4)], "r": cord_r,
                           "note": "drawn to the nut - a loaded crossbow, not a bare lath"}
    if with_bolt:
        shaft_z = nut_z + cord_r * 0.4
        y_fore = mny + 0.055 * (mxy - mny)
        path = [mwi @ Vector((0.0, nut_y, shaft_z)), mwi @ Vector((0.0, y_fore, shaft_z))]
        _tube(bm, path, cord_r * 0.8, cord_r * 0.8, mi_cord)
        head = [mwi @ Vector((0.0, y_fore, shaft_z)),
                mwi @ Vector((0.0, y_fore - 0.030, shaft_z))]
        _tube(bm, head, cord_r * 1.5, cord_r * 1.5, mi_metal)
        built["bolt"] = {"y": [round(y_fore - 0.030, 4), round(nut_y, 4)],
                         "z": round(shaft_z, 4)}

    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return built


# =============================================================================
# EXPORT. The shipped glb is OVERWRITTEN in place, so nothing downstream has to
# be rewired: gear.gd already points at assets/gear/dungeon/crossbow_<tier>.glb
# and keeps pointing at it. THE PRISTINE PACK COPY IS THE BACKUP and it is not
# in this repo - it is
#   C:\hd adventure\_packs\kaykit_dungeon_pack_CC0\Models\gltf\crossbow_<tier>.gltf.glb
# (KayKit, CC0, recorded in docs/art/ASSET_SOURCES.md). Re-running this on an
# ALREADY augmented glb would add a second stirrup, so the entry point refuses
# a mesh that already carries one: the vertex count is the witness.
#   blender -b -noaudio -P tools/art/xbowparts.py -- --repo <repo> [--dry]
# =============================================================================
BASE_VERTS = {"common": 395, "uncommon": 531, "rare": 688}   # measured, _s2_xbow_probe.py


def _export_main():
    import argparse
    import json
    import os
    import sys
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--dry", action="store_true")
    a = ap.parse_args(argv)
    out = {}
    for tier in ("common", "uncommon", "rare"):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        p = os.path.join(a.repo, "assets", "gear", "dungeon", "crossbow_%s.glb" % tier)
        bpy.ops.import_scene.gltf(filepath=p)
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        if len(meshes) != 1:
            raise SystemExit("XBOWPARTS FAIL - %s has %d meshes, expected 1" % (p, len(meshes)))
        ob = meshes[0]
        n = len(ob.data.vertices)
        if n != BASE_VERTS[tier]:
            raise SystemExit("XBOWPARTS FAIL - %s has %d verts, the pristine pack mesh has %d. "
                             "Refusing to add a SECOND stirrup to an already augmented glb; "
                             "restore from the pack first." % (p, n, BASE_VERTS[tier]))
        built = add_parts(ob, tier)
        built["verts_before"], built["verts_after"] = n, len(ob.data.vertices)
        if not a.dry:
            for o in bpy.context.scene.objects:
                o.select_set(True)
            bpy.ops.export_scene.gltf(filepath=p, export_format='GLB', use_selection=False)
        out[tier] = built
    print("XBOWPARTS " + json.dumps(out))


if __name__ == "__main__":
    _export_main()
