"""monstervariants.py - THE SECOND CLASS OF MINIBOSS.

PART 2 of the supervisor's 21:50 CT directive of 19 Nov 2026, which carries
Mr. E's own recipe verbatim in substance: take a creature that already exists
in the CC0/QAL packs, RECOLOUR it, SCALE IT UP past its regular version, give
it a character name and a mechanic that changes the fight, and fit-proof it on
a hero body to the same standard as the thirty-six procedural minibosses.

  blender -b -noaudio -P tools/art/monstervariants.py -- --repo <W5> \
      [--only <key>] [--export] [--fit] [--prove-red]

THE RULE THIS FILE OBEYS FIRST (Mr. E, 16 Nov 04:46): DO NOT MAKE WHAT ALREADY
EXISTS. Nothing here is modelled. Every triangle is the pack author's, and the
only two things this file does to it are the two things the directive asks for:
a different palette and a bigger number. That is the whole point of the class -
it is cheap on purpose, and the saving is why a second source of minibosses is
worth having at all.

*** THE PALETTE IS NOT A TINT, AND IT IS NOT MINE EITHER. ***
Measured, not remembered, 19 Nov 2026 22:4x CT: the Bestiary - Dungeon Monsters
Kit ships THREE base-colour maps per creature, and this repo committed only the
first. `T_Puglin_BaseColor_1` (mean rgb 0.388/0.393/0.127, dominant olive) is
the regular `puglin` in bestiary.gd. `_2` (0.437/0.205/0.207, dominant
0.438/0.188/0.188) is a RED skin by the same author, hand-authored over the
same UVs, and `_3` is a teal one. So the recolour costs nothing, keeps the
normal and ORM detail intact, and cannot go muddy the way a multiply tint over
an olive map would. Mr. E's own example for this class was "a regular Goblin is
small and green, its variant is 1.5x and dark red/black" - the Puglin is the
nearest thing this repo has to that goblin and the author already drew the red.

*** THE ONE THING THIS CLASS CANNOT DO, SAID HERE RATHER THAN DISCOVERED LATER. ***
The thirty-six hold a SILHOUETTE test: throw the colour away and each must read
as itself. A pack variant CANNOT pass that against its own regular version,
because it IS its own regular version - same mesh, same pose, same outline.
What separates them is SCALE and COLOUR, and scale is the half of that which
survives a silhouette. This is a property of the class the directive asked for,
not a defect in this creature, and the register records the silhouette ratio
rather than pretending the test was passed.

LICENCE. Quaternius Asset License (QAL) v1.0 - worldwide, royalty-free,
perpetual, commercial use permitted, no attribution required; the only
restriction is reselling or redistributing the assets AS assets, which a
creature inside our own dungeon is not. Licence text read off disk this run at
`_packs/Bestiary_Dungeon_Monsters_Kit/.../License_Standard.txt`, not off a
search snippet. Logged in docs/art/ASSET_SOURCES.md.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G             # noqa: E402

PACK = os.path.join("C:\\", "hd adventure", "_packs",
                    "Bestiary_Dungeon_Monsters_Kit",
                    "Bestiary - Dungeon Monsters Kit[Standard]")
TEXDIR = os.path.join(PACK, "Textures")

# *** THE STRAY ICOSPHERE IS NOT IN THE PACK FILE, AND THIS LANE HAS BEEN
# *** SAYING OTHERWISE IN THREE PLACES SINCE AT LEAST 17 NOV. CORRECTED HERE
# *** 19 NOV 2026 22:5x CT, ON A BYTE SEARCH AND TWO CONTROLS.
# It would have wrecked the first measurement either way: imported raw, the
# puglin reports 1.902 x 2.000 x 2.000, which is a sphere of radius 1 on the
# origin and not the creature. Dropped, the body is 1.468 x 0.611 x 0.931.
# So dropping it is right and stays. What was WRONG was the reason given for
# it - minibossfit.py, e3pogen.py and docs/art/MINIBOSS_FIT.md all say the glb
# "ships" a stray Icosphere, and it does not:
#   1. the string "Icosphere" occurs ZERO times in the bytes of a glb that
#      nonetheless imports one (broodglut.glb, 3,124,424 bytes; its JSON chunk
#      carries 59 nodes, 3 meshes, no such name);
#   2. a RIGGED pack glb gets one (Frog.glb -> Armature, Frog, Icosphere);
#   3. an UNRIGGED glb of our own does not (beadle.glb -> four meshes, clean).
# It is a Blender 5.2 glTF-import artifact that appears for a glb carrying an
# armature. It is therefore NOT in the shipped asset, NOT in Godot, and NOT a
# defect for the game build lane to chase - which is what a lane acting on the
# old wording would have been sent to do. The handling was right and the
# explanation was wrong, which is the same shape as this lane's two earlier
# instrument faults: the action passed, the reason did not.
STRAY = ("Icosphere",)

# key -> spec. Same seven-field shape as minibosses.CANON plus the source, so
# anything that reads one can read the other.
VARIANTS = {
    "broodglut": dict(
        title="Broodglut",
        source=os.path.join("assets", "monsters", "Puglin.glb"),
        regular="puglin",               # bestiary.gd key of the small version
        regular_h=0.90,                 # bestiary.gd `h` for that key, read off the file
        # PASS 2, 19 Nov 22:5x CT, AND IT IS A CHANGE MADE BY LOOKING. Pass 1
        # authored 2.30 and every number in the register was green - 0 blanks,
        # 0 frame clips, 3 of 3 proving views, seen 1.0 everywhere. Then I
        # looked at hero_front.png: at 2.30 against a 2.45 m hero this thing's
        # head sits BELOW the hero's, because the body is a hunch and its
        # height is bulk rather than stature. It read as a wide peer, not as
        # something you have met trouble in. 2.60 is still inside the band the
        # thirty-six occupy (2.00 - 2.75; the Snuffer is 2.60) and it is 2.89x
        # its own regular version, which is the number the directive actually
        # asks about. ONE thing changed in this pass and nothing else.
        height=2.60,                    # authored miniboss height, metres
        palette="T_Puglin_BaseColor_2.png",
        theme="mess",
        aura=(1.00, 0.42, 0.30),        # the rig's warm key, red end
        idea=("IT EATS ITS OWN - while any lesser puglin in the room still "
              "lives it will take one, swallow it, and close its own wounds; "
              "the swarm is its health and the big one is not the target"),
        line="Something in here is eating the little ones.",
        note=("ADJACENCY DECLARED RATHER THAN HIDDEN: miniboss 8, Blisterhand "
              "(ex-Cook), KEEPS THE PACK ALIVE. This is the arrow reversed - "
              "the pack keeps IT alive - so the party's decision is inverted "
              "(kill the adds, not the boss) instead of repeated. If Mr. E "
              "reads it as the same idea twice, the fix is one word in the "
              "idea string and no geometry."),
    ),
}
ORDER = ["broodglut"]


def _drop_stray(objs):
    out, dropped = [], []
    for o in list(objs):
        if o.name.split(".")[0] in STRAY:
            dropped.append(dict(name=o.name,
                                hidden_render=bool(o.hide_render),
                                hidden_view=bool(o.hide_get() if o.name in
                                                 bpy.context.view_layer.objects else False),
                                verts=len(o.data.vertices) if o.type == 'MESH' else 0))
            bpy.data.objects.remove(o, do_unlink=True)
        else:
            out.append(o)
    return out, dropped


def _repalette(spec, maxpx=1024):
    """Swap every BaseColor map for the pack's alternate, and bring all four
    maps down to `maxpx` so the shipped glb is a game asset and not a 7.8 MB
    one. The repo's own precedent is Mr. E's wand (three 1024 maps, 2.38 MB).

    Reads as Non-Color on purpose so sRGB bytes round-trip, which is this
    lane's standing rule for anything measured with numpy."""
    rep = {"swapped": [], "resized": [], "mean_before": None, "mean_after": None}
    src = os.path.join(TEXDIR, spec["palette"])
    assert os.path.isfile(src), "variant palette missing on disk: %s" % src
    new = bpy.data.images.load(src, check_existing=False)
    new.colorspace_settings.name = 'Non-Color'
    rep["mean_after"] = _mean(new)
    if max(new.size) > maxpx:
        new.scale(maxpx, maxpx)
    new.pack()
    for m in bpy.data.materials:
        if not m.node_tree:
            continue
        for n in m.node_tree.nodes:
            if n.type != 'TEX_IMAGE' or n.image is None:
                continue
            if "BaseColor" in n.image.name:
                if rep["mean_before"] is None:
                    n.image.colorspace_settings.name = 'Non-Color'
                    rep["mean_before"] = _mean(n.image)
                rep["swapped"].append("%s/%s: %s -> %s"
                                      % (m.name, n.name, n.image.name, spec["palette"]))
                n.image = new
            elif max(n.image.size) > maxpx:
                n.image.scale(maxpx, maxpx)
                n.image.pack()
                rep["resized"].append(n.image.name)
    # the base colour is sampled through an sRGB view in the end, so put it back
    new.colorspace_settings.name = 'sRGB'
    rep["palette_px"] = list(new.size)
    return rep


def _mean(img):
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)
    m = a[..., 3] > 0.5
    if not m.any():
        return None
    return [round(float(x), 4) for x in a[..., :3][m].mean(axis=0)]


def build_variant(key, repo):
    """Same contract as minibossgen.build_miniboss: returns (objs, info) with
    the creature scaled to its authored height and its feet on z = 0."""
    spec = VARIANTS[key]
    path = os.path.join(repo, spec["source"])
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in before]
    new_objs, dropped = _drop_stray(new_objs)
    pal = _repalette(spec)
    meshes = [o for o in new_objs if o.type == 'MESH']
    rig = next((o for o in new_objs if o.type == 'ARMATURE'), None)
    roots = [o for o in new_objs if o.parent is None]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    native = mx.z - mn.z
    k = spec["height"] / native if native > 1e-6 else 1.0
    for o in roots:
        o.scale = (o.scale.x * k, o.scale.y * k, o.scale.z * k)
        o.location = (o.location.x * k, o.location.y * k, o.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    for o in roots:
        o.location = (o.location.x, o.location.y, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    info = dict(spec)
    info.update(native_h=round(native, 5), scale_k=round(k, 5),
                measured_h=round(mx.z - mn.z, 4),
                span_x=round(mx.x - mn.x, 4), span_y=round(mx.y - mn.y, 4),
                stray_dropped=dropped, palette_report=pal,
                bones=(len(rig.data.bones) if rig else 0),
                meshes=[o.name for o in meshes],
                tris=_tris(meshes),
                aura=spec["aura"])
    return meshes, roots, info


def _tris(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in meshes:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        n += len(me.loop_triangles)
        ev.to_mesh_clear()
    return n


def export_variant(key, repo, roots, meshes):
    """Export at NATIVE scale, not at the authored miniboss height.

    WHY, and it is a measurement and not a preference: `Monster` in
    bestiary.gd normalises every monster body to the entry's `h` from its own
    measured bounds (bestiary.gd ~10), so the glb's authored size is thrown
    away at load. Shipping a pre-scaled mesh would therefore put the number in
    two places that can disagree, and the number that wins is the one in
    bestiary.gd. The scale goes in the WIRING, where the engine reads it; the
    glb carries only what the engine keeps - the geometry and the new skin."""
    for o in roots:
        o.scale = (1.0, 1.0, 1.0)
        o.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    out = os.path.join(repo, "assets", "monsters", "minibosses", "%s.glb" % key)
    for o in bpy.data.objects:
        o.select_set(False)
    for o in roots + meshes:
        try:
            o.select_set(True)
        except Exception:
            pass
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                              use_selection=True, export_apply=False,
                              export_animations=False)
    return out, os.path.getsize(out)


def fit(key, repo, prove_red=False):
    """THE FIT PROOF, AND IT IS NOT A SECOND STANDARD.

    This calls minibossfit's own `import_hero`, `place` and `shoot` rather than
    re-deriving them, so the variant is measured by the same instrument as the
    thirty-six: the real KayKit adventurer at scale 1.0, one fixed ortho frame,
    one fixed ground line, front/side/back, and all three of that file's
    checks - blank, frame-border per edge, and the with/without occlusion test
    that asks the VIEWER'S question instead of rendering a thing alone.

    A second harness would be a second set of numbers to disagree about, and
    this lane has already shipped one instrument that could not see and one
    that could not move. Reuse is the cheaper honesty."""
    import minibossfit as F
    if prove_red:
        F.PROVE_RED = True
    meshes, roots, info = build_variant(key, repo)
    hroots, hmesh, hero = F.import_hero(repo)
    mn, mx, _ = G.world_bounds(meshes)
    F.place(hroots, mn.x - F.GAP - hero["w"] / 2.0 - 0.10,
            mn.y - F.GAP - hero["d"] / 2.0 - 0.10)
    allo = meshes + hmesh
    bpy.context.view_layer.update()
    amn, amx, pts = G.world_bounds(allo)
    outdir = os.path.join(repo, "renders", "art", "variants", key)
    os.makedirs(outdir, exist_ok=True)
    tmpdir = os.path.join(repo, "renders", "art", "variants", "_vis_tmp")
    os.makedirs(tmpdir, exist_ok=True)
    written, eng, vis, edge = F.shoot(
        allo, pts, outdir, (("front", 0.0), ("side", 90.0), ("back", 180.0)),
        info["aura"], creature=meshes, hero_meshes=hmesh, tmpdir=tmpdir)

    errors, blind = [], []
    for vname, c in vis.items():
        for who in ("creature", "hero"):
            if c[who]["alone"] == 0:
                errors.append("%s/%s: the %s renders EMPTY alone - its seen "
                              "fraction would be computed over nothing"
                              % (key, vname, who))
    proving = sum(1 for c in vis.values() if c["proves"])
    if proving < F.MIN_PROVING:
        blind.append("%s: only %d of %d views show BOTH subjects"
                     % (key, proving, len(vis)))
    clipped = {v: e for v, e in edge.items() if any(e.values())}
    blanks = []
    for p in written:
        a = G.read_png(p)
        if int((a[:, :, 3] > F.DIFF_EPS).sum()) == 0:
            blanks.append(os.path.basename(p))

    # THE SILHOUETTE NUMBER THIS CLASS CAN HONESTLY REPORT. Not "does it read
    # as itself with the colour thrown away" - it cannot, it is the same mesh -
    # but HOW MUCH BIGGER the outline is than the regular version's, which is
    # the only part of the difference that survives a silhouette.
    sil = round(info["height"] / max(0.01, info["regular_h"]), 3)
    rec = dict(
        title=info["title"], regular=info["regular"], regular_h=info["regular_h"],
        height=info["height"], scale_vs_regular=sil,
        creature_h=round(mx.z - mn.z, 3), hero_h=hero["h"],
        ratio=round((mx.z - mn.z) / max(0.01, hero["h"]), 2),
        pair_w=round(amx.x - amn.x, 2),
        span_x=info["span_x"], span_y=info["span_y"],
        frame_w=F.FRAME_W, frame_h=round(F.FRAME_H, 3),
        corridor_clear=11.0,
        room_locked=bool(max(info["span_x"], info["span_y"]) > 11.0),
        fits_frame=bool((amx.x - amn.x) <= F.FRAME_W
                        and (amx.z - amn.z) <= F.FRAME_H - F.GROUND_UP),
        engine=eng, views=[os.path.basename(p) for p in written],
        visibility=vis, frame_edge=edge, proving_views=proving,
        blanks=blanks, frame_clips=clipped, errors=errors, blind_views=blind,
        tris=info["tris"], bones=info["bones"], meshes=info["meshes"],
        native_h=info["native_h"], stray_dropped=info["stray_dropped"],
        palette=info["palette"], palette_report=info["palette_report"],
        theme=info["theme"], idea=info["idea"], line=info["line"],
        note=info["note"], prove_red=bool(prove_red),
    )
    rec["ok"] = bool(not errors and not blanks and not clipped and not blind)
    return rec, roots, meshes


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--export", action="store_true")
    ap.add_argument("--fit", action="store_true")
    ap.add_argument("--prove-red", action="store_true")
    ap.add_argument("--ab", action="store_true")
    # THE T-POSE IS WIDER THAN THE THIRTY-SIX'S FRAME, AND THE BORDER CHECK
    # CAUGHT IT RATHER THAN MY EYE. At 2.60 the pair spans 5.96 m against
    # minibossfit's fixed 5.60 m cell, and the front and back views lost 228
    # and 233 px of arm off the left and right edges - a clip, not a blank,
    # which is precisely the fault class that check was built for after
    # System 1's cut glow. The frame is widened for this register and the
    # width is RECORDED in it, because a cell shot at 6.40 m cannot be
    # compared with a thirty-six cell shot at 5.60 m and nobody should have
    # to find that out by eye.
    ap.add_argument("--frame", type=float, default=0.0)
    args = ap.parse_args(argv)
    if args.frame > 0.1:
        import minibossfit as _F
        _F.FRAME_W = args.frame
        _F.FRAME_H = args.frame * _F.CELL_Y / float(_F.CELL_X)
    keys = [k for k in args.only.split(",") if k] or list(ORDER)
    outp = os.path.join(args.repo, "renders", "art", "variants", "_register.json")
    os.makedirs(os.path.dirname(outp), exist_ok=True)
    reg = {}
    if os.path.isfile(outp):
        try:
            with open(outp) as f:
                reg = json.load(f)
        except Exception:
            reg = {}
    reg.setdefault("variants", {})
    for key in keys:
        G.purge()
        if args.ab:
            for lname, light in (("mess", (1.00, 0.68, 0.34)),
                                 ("crypt", (0.70, 0.74, 1.00))):
                G.purge()
                reg.setdefault("ab_palette", {}).setdefault(key, {})[lname] = \
                    ab_palette(key, args.repo, light=light, tag=lname)
            continue
        if args.fit:
            rec, roots, meshes = fit(key, args.repo, prove_red=args.prove_red)
        else:
            meshes, roots, info = build_variant(key, args.repo)
            rec = dict(title=info["title"], native_h=info["native_h"],
                       tris=info["tris"], ok=None)
        if args.export:
            path, size = export_variant(key, args.repo, roots, meshes)
            rec["glb"] = os.path.relpath(path, args.repo).replace("\\", "/")
            rec["glb_bytes"] = size
        if args.prove_red:
            reg.setdefault("red_proof", {})[key] = rec
        else:
            reg["variants"][key] = rec
    reg["verdict"] = ("GREEN" if all(v.get("ok") for v in reg["variants"].values())
                      else "NOT PASSED")
    with open(outp, "w") as f:
        json.dump(reg, f, indent=1)
    print("MV_DONE", outp, reg["verdict"])



# ---------------------------------------------------------------- the A/B
def ab_palette(key, repo, light=(1.00, 0.68, 0.34), tag=""):
    """DOES THE RECOLOUR SURVIVE THE LIGHT IT WILL BE SEEN IN?

    The texture means say the two skins are far apart - olive 0.388/0.393/0.127
    against red 0.437/0.205/0.207. That is a number about a FILE. The question
    a viewer asks is whether a big red puglin reads as a different animal from
    the little ones NEXT TO IT.

    *** WHAT THIS FILE CLAIMED AND COULD NOT DO, CORRECTED 19 NOV 22:5x CT. ***
    The first version of this docstring said the two skins were compared
    "under the theme's own key light". THEY WERE NOT, and the run's own
    numbers are how I know: the mess key (1.00/0.68/0.34) and the crypt key
    (0.70/0.74/1.00) are as far apart as two theme lights get in floorgen, and
    they returned mean_rgb_distance 0.1343 and 0.1339 - the same answer to
    four decimal places. The cause is in lordgen.add_lights: its third
    argument colours the RIM only, from behind; the key is a fixed warm white
    (1.0, 0.97, 0.92) that no caller can reach. So the light argument moved a
    back edge and nothing else, and a theme-light claim built on it would have
    been a sentence with no measurement under it.
    WHAT IS MEASURED AND STANDS: the two skins under the STANDARD FIT RIG -
    same mesh, same camera, same lights, only the map swapped. WHAT IS NOT
    ANSWERED: whether a theme's own key collapses the difference. Answering it
    needs the KEY colour driven, not the aura - a change in lordgen that
    touches every register this lane has shipped, and not a thing to do inside
    a variant's first pass.

    So: the same mesh, the same camera, the same lights, rendered twice - once
    wearing BaseColor_1 and once BaseColor_2 - and the separation measured on
    the PIXELS THAT MOVED, not on the maps. An instrument that renders a thing
    alone answers how big it is; this one answers whether it looks different,
    which is the question.

    GOES RED ON EMPTY: if the two renders share no opaque pixels the separation
    is computed over nothing and the verdict is NO VERDICT, not a pass."""
    import minibossfit as F
    spec = VARIANTS[key]
    lsuf = ("_" + tag) if tag else ""
    rows = {}
    for tag, pal in (("regular", "T_Puglin_BaseColor_1.png"),
                     ("variant", spec["palette"])):
        G.purge()
        sp = dict(spec); sp["palette"] = pal
        saved, VARIANTS[key] = VARIANTS[key], sp
        try:
            meshes, roots, info = build_variant(key, repo)
        finally:
            VARIANTS[key] = saved
        mn, mx, pts = G.world_bounds(meshes)
        outdir = os.path.join(repo, "renders", "art", "variants", key, "_ab")
        os.makedirs(outdir, exist_ok=True)
        # THE THEME'S OWN KEY, not the register's red aura - using the aura
        # would bias the test toward the answer I want.
        written, eng, _, edge = F.shoot(meshes, pts, outdir,
                                        (("%s%s" % (tag, lsuf), 0.0),), tuple(light))
        rows[tag] = dict(png=written[0], edge=edge)
    a = G.read_png(rows["regular"]["png"])
    b = G.read_png(rows["variant"]["png"])
    ma = a[:, :, 3] > F.DIFF_EPS
    mb = b[:, :, 3] > F.DIFF_EPS
    both = ma & mb
    n = int(both.sum())
    rep = dict(pixels_compared=n, light=[round(float(c), 3) for c in light],
               regular_png=os.path.basename(rows["regular"]["png"]),
               variant_png=os.path.basename(rows["variant"]["png"]))
    if n < 1000:
        rep["verdict"] = "NO VERDICT - only %d shared opaque pixels" % n
        rep["ok"] = False
        return rep
    pa = a[:, :, :3][both]
    pb = b[:, :, :3][both]
    rep["mean_regular"] = [round(float(x), 4) for x in pa.mean(axis=0)]
    rep["mean_variant"] = [round(float(x), 4) for x in pb.mean(axis=0)]
    # per-pixel distance, and the one component a warm light cannot fake:
    # green-minus-red. Olive is g > r; the red skin is r > g. A sign flip is
    # the thing a viewer sees across a dim room.
    d = np.sqrt(((pa - pb) ** 2).sum(axis=1))
    gr_a = (pa[:, 1] - pa[:, 0])
    gr_b = (pb[:, 1] - pb[:, 0])
    rep["mean_rgb_distance"] = round(float(d.mean()), 4)
    rep["p10_rgb_distance"] = round(float(np.percentile(d, 10)), 4)
    rep["frac_over_jnd"] = round(float((d > 0.05).mean()), 4)
    rep["green_minus_red_regular"] = round(float(gr_a.mean()), 4)
    rep["green_minus_red_variant"] = round(float(gr_b.mean()), 4)
    rep["gr_shift"] = round(float(gr_b.mean() - gr_a.mean()), 4)
    rep["sign_flipped_frac"] = round(float(((gr_a > 0) & (gr_b < 0)).mean()), 4)
    # *** THE FIRST VERSION OF THIS VERDICT WAS WRONG AND ITS OWN NUMBERS SAID
    # *** SO. It required sign_flipped_frac >= 0.50 - "olive is green-dominant,
    # the red skin is not, so most pixels must flip". The run returned
    # green_minus_red_regular = -0.0102: under the mess theme's warm key the
    # REGULAR puglin is already red-dominant, so there was no sign left to
    # flip and the criterion could never be met by any recolour whatsoever.
    # That is this lane's own recurring fault - a gate that cannot move - and
    # it was built into the gate by an assumption about the art rather than a
    # measurement of it. Replaced with two things that are measured and not
    # assumed: how far the pixels moved, and how many of them moved further
    # than a just-noticeable 0.05. sign_flipped_frac is KEPT in the record as
    # a reading, with no power to pass or fail anything.
    rep["ok"] = bool(rep["mean_rgb_distance"] >= 0.08 and rep["frac_over_jnd"] >= 0.75)
    rep["theme_light_test"] = ("NOT PROVEN - lordgen.add_lights colours the rim "
                               "only; the key is fixed warm white and this "
                               "argument cannot reach it")
    rep["verdict"] = ("SEPARATED UNDER THE FIT RIG" if rep["ok"]
                      else "TOO CLOSE UNDER THE FIT RIG")
    return rep


if __name__ == "__main__":
    main()
