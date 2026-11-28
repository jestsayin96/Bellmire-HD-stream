"""hallgen - THE HALL, TIERS 1 TO 3. Built, not designed.

  blender -b -noaudio -P tools/art/hallgen.py -- --repo <repo> [--px 1024]
                                                 [--only hall_t1] [--noglb]

28 Nov 2026, ~02:4x CT. Art lane. The row (plan, TAKE THIS NEXT, ART 02:34):
"BUILD THE HALL TIER LADDER YOU JUST DESIGNED. The design is ticked; the
ladder is not. Three tiers, RENDERED SIDE BY SIDE, and the progression must
read at a glance - that is the hard rule and the design doc is no substitute
for it."

The design is `docs/art/TOWN_HALL_TIERS_DESIGN.md`. **EVERY NUMBER THIS FILE
BUILDS ON WAS RE-MEASURED THIS RUN** by `tools/art/_hallmeasure.py` into
`renders/art/town/_hall_measure.json` - the design doc's own figures are NOT
trusted, because a number in a document is always the suspect. The re-measure
agreed with the design on all 16 modules and on `lm_hall`'s off-centre pivot
(x = +1.9246), which is the defect this file exists to route around.

WHAT CONTENT ALREADY SAYS, AND IT IS THE SPEC
---------------------------------------------
`data/lore_lines.json -> town_buildings.landmarks.hall`, three `see` lines:
  t1 "A timber hall with a THATCH roof, one door, a bench outside."
  t2 "STONE FOOTINGS, a TILED roof, a STAIR to an upper room, a lamp at the door."
  t3 "A STONE HALL WITH A TOWER, BANNERS on the gable, a PAVED COURT and a
      guard at the steps."
`tier_levels` = {1: 1, 2: 5, 3: 9}. Mesh names are `town_hall_t1/t2/t3` so the
art and the text agree by construction, which the row asked for.

*** WEAR IS THE SPEC, NOT A BACKGROUND PRINCIPLE (Mr. E, art rule 2). ***
The texture run exposed the blocker precisely: **the MegaKit ships ONE roof,
`MI_RoundTiles`, and all twelve existing buildings now wear it**, so the only
roof in the town is the prosperous one and a tier-1 Bellmire cannot look poor.
Tier separation therefore comes from, in order of what it buys at stream
distance:
  1. ROOF      - authored thatch (t1) vs round tile (t2/t3). The biggest read.
  2. MASS      - 4x6x1 storey vs 6x8x2 vs 13.8x15.7x3+tower.
  3. WALL      - plaster/timber vs uneven brick below + plaster above vs built.
  4. DRESSING  - paving, railing, banners, a lamp.

*** PLAINNESS IS THE VOICE (art rule 1). *** A moot hall is a room with a
door and a bench, because that is what it is FOR. Nothing theatrical.

THE ONE PIECE THAT CANNOT COME FROM A PACK, AND WHY - CHECKED, ALL 49
---------------------------------------------------------------------
All 49 extracted pack directories were walked for `thatch|straw|reed|hay`: the
only hits are two `hay-bale` meshes in `kenney_graveyard-kit_5.0`, and the
MegaKit's nine materials carry no thatch. **No thatch roof exists on disk to
derive from**, so t1's roof is procedural (bmesh/boxes, the way
`townbuild.py::_shingles` makes the well's courses). That is also exactly
where t1's wear lives: a SAGGING ridge and ragged, patched courses.

PIVOT CONTRACT - THE WHOLE WIRING STORY, AND THE DEFECT IT ROUTES AROUND
------------------------------------------------------------------------
All three tiers share ONE pivot: footprint centre in X/Y, ground at z = 0.
The game build swaps the mesh at a single unmoved spawn point.
`assets/buildings/lm_hall.glb`'s own bounds centre is x = +1.9246, so a ladder
that reused it as-is would make the hall JUMP 1.92 m SIDEWAYS on upgrade. This
file ships t3 as a RE-CENTRED copy under a new name and leaves `lm_hall.glb`
untouched, so whatever already references it keeps working.

SIZED AGAINST THE BODY, MEASURED, NOT AGAINST A MAN
----------------------------------------------------
The KayKit adventurer stands **2.453 m** to the helmet (`Knight_Helmet` z
1.101-2.453). The kit's walls are 3.1227 per storey and its doors top at
2.32-2.36, so **the hero does not clear a kit door by about 10 cm**. Nothing
walks through one today, so nothing is visibly broken; a ~1.15x town-wide
scale would fix it and that is a DECISION, routed up, not taken here. This
ladder is built at the kit's native scale so it matches the other twelve
buildings it will stand beside.

LICENCE: Medieval Village MegaKit [Standard], Quaternius, **CC0 1.0
Universal**, licence read off disk and recorded in `docs/art/ASSET_SOURCES.md`
(~line 703). The modules are used unmodified and placed on the kit's own 2 m
grid; the thatch, the bench, the lamp and the banners are procedurally
generated here and are therefore original. Reproducible from this file alone,
which is the standard the tier-5 spear set.

THE TEXTURE TRADE, carried over from `towntex.py` and stated so it is reversible
-------------------------------------------------------------------------------
The pack's maps are 2048 and total 51.58 MB. Embedding every map in every
tier duplicates them, and the texture run proved every gate stays GREEN over a
28.1 MB file. So: base colour only, downscaled to --px (default 1024), Normal
dropped, and Roughness/Metallic MEASURED off their map's own channel mean and
written in as constants rather than guessed. Pass --px 2048 to reverse it.
A SIZE GATE is new this ladder - see townlib.
"""
import argparse, json, math, os, sys

import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L
import townlib as T

W5 = r"C:\hd adventure\bellmire-art"
PACK = (r"C:\hd adventure\_packs\Medieval_Village_MegaKit"
        r"\Medieval Village MegaKit[Standard]\glTF")

STOREY = 3.1227                 # measured: every Wall_* module's Z extent
GRID = 2.0                      # measured: every Wall_* module's X extent

CANON = {
    "hall_t1": ("The Moot Hall",      1, "Timber, thatched, one door, a bench."),
    "hall_t2": ("The Chief's Hall",   2, "Stone footings, tiled, a stair, a lamp."),
    "hall_t3": ("The Hall of Bellmire", 3, "Stone and tower, banners, a paved court."),
}
ORDER = ("hall_t1", "hall_t2", "hall_t3")

# Authored-colour slots for the procedural pieces only. The pack modules keep
# Quaternius' own materials; nothing here repaints them.
THATCH = (0.47, 0.36, 0.15)       # weathered straw - warmer than my first cut
THATCH2 = (0.36, 0.27, 0.11)      # the shaded course and the ridge roll
BENCH = (0.33, 0.29, 0.22)
IRON = (0.14, 0.14, 0.15)
FLAME = (1.0, 0.72, 0.32)
BANNER = (0.44, 0.12, 0.11)
BANNER_TRIM = (0.62, 0.50, 0.20)

DROP_INPUTS = ("Normal",)
FLATTEN_INPUTS = ("Roughness", "Metallic", "Specular IOR Level")


# --------------------------------------------------------------- the pack side
def _channel_mean(sock):
    """Mean of the EXACT channel feeding this socket, read off the pixels.

    ORM maps pack Occlusion/Roughness/Metallic into R/G/B, so a socket fed
    through a Separate Color node must be averaged over ITS OWN channel - a
    whole-image mean would hand a roughness slot the occlusion average.
    Returns None rather than a made-up number when the chain is not one this
    understands; the caller then leaves the material's own default alone."""
    if not sock.links:
        return None
    node, out = sock.links[0].from_node, sock.links[0].from_socket
    chan = None
    if node.type in ('SEPARATE_COLOR', 'SEPRGB'):
        chan = {'Red': 0, 'Green': 1, 'Blue': 2}.get(out.name)
        if chan is None or not node.inputs[0].is_linked:
            return None
        node = node.inputs[0].links[0].from_node
    if node.type != 'TEX_IMAGE' or node.image is None or not node.image.has_data:
        return None
    w, h = node.image.size
    if not w or not h:
        return None
    vals = list(node.image.pixels)[chan or 0::4]
    return float(sum(vals) / len(vals)) if vals else None


def trim_materials(px):
    """Apply the texture trade to every material now in the file."""
    for m in bpy.data.materials:
        if not m.use_nodes or m.node_tree is None:
            continue
        bsdf = next((x for x in m.node_tree.nodes
                     if x.type == 'BSDF_PRINCIPLED'), None)
        if bsdf is None:
            continue
        for inp in DROP_INPUTS:
            s = bsdf.inputs.get(inp)
            if s is not None and s.is_linked:
                for lk in list(s.links):
                    m.node_tree.links.remove(lk)
        for inp in FLATTEN_INPUTS:
            s = bsdf.inputs.get(inp)
            if s is None or not s.is_linked:
                continue
            val = _channel_mean(s)          # measure BEFORE cutting
            for lk in list(s.links):
                m.node_tree.links.remove(lk)
            if val is not None:
                s.default_value = val
    # prune orphaned nodes so their images are not exported
    for m in bpy.data.materials:
        if not m.use_nodes or m.node_tree is None:
            continue
        nt = m.node_tree
        changed = True
        while changed:
            changed = False
            for n in list(nt.nodes):
                if n.type in ('OUTPUT_MATERIAL', 'BSDF_PRINCIPLED'):
                    continue
                if not any(o.is_linked for o in n.outputs):
                    nt.nodes.remove(n)
                    changed = True
    # *** DEDUPE FIRST, DOWNSCALE SECOND. *** The size gate caught tier 2 at
    # 16.61 MB and the cause was not resolution: each module is a SEPARATE
    # .gltf import, so eight modules sharing `T_Plaster` produce eight
    # independent image datablocks (`T_Plaster`, `T_Plaster.001`, ...) and all
    # eight get embedded. Point every texture node at the canonical image of
    # its base name and the duplicates fall out of the export unreferenced.
    canon = {}
    for img in bpy.data.images:
        if img.name == 'Render Result' or not img.has_data:
            continue
        b = img.name.rsplit(".", 1)
        base = b[0] if (len(b) == 2 and b[1].isdigit() and len(b[1]) == 3) else img.name
        canon.setdefault(base, img)
    for m in bpy.data.materials:
        if not m.use_nodes or m.node_tree is None:
            continue
        for n in m.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image is not None:
                b = n.image.name.rsplit(".", 1)
                base = b[0] if (len(b) == 2 and b[1].isdigit()
                                and len(b[1]) == 3) else n.image.name
                if base in canon:
                    n.image = canon[base]
    for img in bpy.data.images:
        if img.name == 'Render Result' or not img.has_data:
            continue
        w, h = img.size
        if max(w, h) > px:
            img.scale(min(w, px), min(h, px))
        # JPEG for the base colour. Every textured material here is opaque, so
        # nothing needs an alpha channel; the exporter's AUTO mode follows the
        # datablock's own format. Same trade `towntex.py` made, same reason.
        try:
            img.file_format = 'JPEG'
        except Exception:
            pass


def export_glb_jpeg(objs, path, quality=82):
    """Export with the base-colour maps written as JPEG.

    `lordgen.export_glb` leaves `export_image_format` at AUTO, which follows
    each image datablock's own source - and these come out of the pack as PNG,
    so AUTO re-embeds PNG however the datablock's `file_format` is set. That is
    why my first fix changed the tier-2 file by nothing at all: I set a flag
    the exporter was never going to read. `lordgen.export_glb` is NOT changed -
    24 shipped bodies go through it - so the format is forced here instead.

    Returns (ok, note, n_images) so the caller can report what was embedded
    rather than infer it from the file size."""
    for ob in bpy.data.objects:
        try:
            ob.select_set(ob in objs)
        except Exception:
            pass
    try:
        bpy.context.view_layer.objects.active = objs[0]
    except Exception:
        pass
    n_img = len([i for i in bpy.data.images
                 if i.name != 'Render Result' and i.has_data])
    base = dict(filepath=path, export_format='GLB', use_selection=True)
    try:
        bpy.ops.export_scene.gltf(export_image_format='JPEG',
                                  export_jpeg_quality=quality, **base)
        return True, "jpeg q%d" % quality, n_img
    except TypeError as e1:
        ok, note = G.export_glb(objs, path)
        return ok, "FELL BACK TO AUTO (%s): %s" % (e1, note), n_img
    except Exception as e2:
        ok, note = G.export_glb(objs, path)
        return ok, "FELL BACK TO AUTO (%s): %s" % (e2, note), n_img


_PROTO = {}


def proto(mod):
    """Import a pack module ONCE and keep its mesh objects as a prototype.

    Prototypes are hidden from render. Placements are new objects SHARING the
    prototype's mesh data, so N copies of a wall cost one mesh and one set of
    material slots - slots live on the mesh, so a linked copy keeps Quaternius'
    materials without a remap step."""
    if mod in _PROTO:
        return _PROTO[mod]
    p = os.path.join(PACK, mod + ".gltf")
    if not os.path.isfile(p):
        raise SystemExit("MISSING MODULE: %s" % p)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    if not meshes:
        raise SystemExit("MODULE HAS NO MESH: %s" % mod)
    # bake each mesh's own local transform into a stored matrix relative to the
    # module root, so a placement reproduces the module exactly
    recs = []
    for o in meshes:
        recs.append((o.data, o.matrix_world.copy()))
        o.hide_render = True
        o.hide_viewport = True
    _PROTO[mod] = recs
    return recs


def place(mod, loc=(0.0, 0.0, 0.0), rz=0.0, out=None):
    """Drop a module at loc, rotated rz radians about its own Z."""
    from mathutils import Matrix
    recs = proto(mod)
    M = Matrix.Translation(Vector(loc)) @ Matrix.Rotation(rz, 4, 'Z')
    made = []
    for data, mw in recs:
        ob = bpy.data.objects.new("%s_inst" % mod, data)
        bpy.context.collection.objects.link(ob)
        ob.matrix_world = M @ mw
        made.append(ob)
    if out is not None:
        out.extend(made)
    return made


def wall_box(objs, w_mods, d_mods, storeys, picker, corner):
    """Four wall runs on the kit's 2 m grid plus four corners, per storey.

    `picker(side, i, storey)` returns the module name for that bay, which is
    how the wear changes with HEIGHT (uneven brick below, plaster above) rather
    than being painted on uniformly.

    The wall modules are centred in X but NOT in Y (min y -0.0924, max +0.3141),
    so a run's outer face sits ~0.09 outside its line. That asymmetry is left
    alone and absorbed by the final re-centre, because it is under 0.1 m and
    invisible at stream distance - chasing it would move geometry for no
    picture. THE PIVOT IS GUARANTEED BY THE RE-CENTRE, NOT BY THIS FUNCTION."""
    W, D = w_mods * GRID, d_mods * GRID
    for s in range(storeys):
        z = s * STOREY
        for i in range(w_mods):
            x = -W / 2.0 + GRID / 2.0 + i * GRID
            place(picker('S', i, s), (x, -D / 2.0, z), 0.0, objs)
            place(picker('N', i, s), (x, D / 2.0, z), math.pi, objs)
        for j in range(d_mods):
            y = -D / 2.0 + GRID / 2.0 + j * GRID
            place(picker('W', j, s), (-W / 2.0, y, z), math.pi / 2.0, objs)
            place(picker('E', j, s), (W / 2.0, y, z), -math.pi / 2.0, objs)
        for sx in (-1, 1):
            for sy in (-1, 1):
                place(corner, (sx * W / 2.0, sy * D / 2.0, z), 0.0, objs)
    return W, D


# ------------------------------------------------------- the authored pieces
def thatch(objs, wall_top, half_w, length, overhang, pitch, sag, seed):
    """A THATCHED roof, ridge along Y. The one piece no pack on disk can serve.

    `sag` IS THE WEAR TERM and it is the point of tier 1: the ridge line dips
    in the middle, the courses are ragged, and the whole thing reads make-do
    beside tier 2's crisp tile. Built as overlapping courses of boxes, the way
    `townbuild.py::_shingles` builds the well's courses."""
    import random
    rng = random.Random(seed)
    verts, faces = [], []
    mats = []

    def add(vs, fs, slot):
        off = len(verts)
        verts.extend(vs)
        faces.extend([tuple(i + off for i in f) for f in fs])
        mats.extend([slot] * len(fs))

    eave_x = half_w + overhang
    eave_z = wall_top - 0.14
    ridge_z = eave_z + eave_x * pitch
    # FEWER, FATTER, MORE OVERLAPPED COURSES. My first cut used 9 thin courses
    # at 0.17 thick and it rendered as SHINGLES - neat flat rectangles in tidy
    # rows. Thatch is a thick soft mass with a cut edge, so: 6 courses at 0.30,
    # overlapped 1.55, and the eave course fatter still.
    segs = max(6, int(length / 0.55))
    courses = 6
    for si in range(segs):
        y0 = -length / 2.0 + length * si / segs
        y1 = -length / 2.0 + length * (si + 1) / segs
        ym = (y0 + y1) / 2.0
        # the sag: a dip that is deepest at mid-span. THIS is the wear.
        dip = -sag * math.sin(math.pi * (ym + length / 2.0) / length)
        for side in (-1, 1):
            for c in range(courses):
                f0, f1 = c / float(courses), (c + 1) / float(courses)
                x0, x1 = side * eave_x * (1.0 - f0), side * eave_x * (1.0 - f1)
                z0 = eave_z + (ridge_z - eave_z) * f0 + dip * f0
                z1 = eave_z + (ridge_z - eave_z) * f1 + dip * f1
                dx, dz = x1 - x0, z1 - z0
                ln = math.hypot(dx, dz)
                ang = -math.atan2(dz, dx)
                th = 0.30 * (1.0 + rng.uniform(-0.30, 0.30))   # ragged
                if c == 0:
                    th *= 1.45                 # the cut eave edge, thickest
                wob = rng.uniform(-0.05, 0.05)
                slot = 'thatch' if c % 3 else 'thatch2'
                bv, bf = L.box(ln * 1.55, (y1 - y0) * 1.12, th)
                add(L.xform(bv, loc=((x0 + x1) / 2.0, ym,
                                     (z0 + z1) / 2.0 + wob),
                            rot=(rng.uniform(-0.05, 0.05), ang, 0.0)),
                    bf, slot)
        # ridge cap, sagging with the rest
        # A FAT ROLLED RIDGE. My first cut's ridge cap was 0.46 x 0.22 and
        # read as one more shingle course rather than as the roll of straw a
        # thatcher actually binds along the top.
        rv, rf = L.box(0.80, (y1 - y0) * 1.14, 0.46)
        add(L.xform(rv, loc=(0.0, ym, ridge_z + dip + 0.14),
                    rot=(rng.uniform(-0.06, 0.06), 0.0, 0.0)), rf, 'thatch2')

    m1 = L.mat_solid("thatch", THATCH, 0.95, 0.0)
    m2 = L.mat_solid("thatch2", THATCH2, 0.95, 0.0)
    ob = L.make("hall_t1_thatch", verts, faces, m1)
    ob.data.materials.append(m2)
    for i, slot in enumerate(mats):
        if i < len(ob.data.polygons):
            ob.data.polygons[i].material_index = 0 if slot == 'thatch' else 1
    objs.append(ob)
    return {"ridge_z": ridge_z, "eave_x": eave_x, "eave_z": eave_z,
            "pitch": pitch, "length": length}


def gable(objs, roof, thick=0.26):
    """FILL THE GABLE ENDS. The second thing the picture caught and no gate did.

    With the walls fixed, the tier-1 render still showed a dark void under the
    roof at each end: a two-slope roof over a four-wall box leaves the two
    TRIANGLES above the end walls open, and you could see into the roof void.
    Blank, border, subject-moved, hero-seen and even the new see-through test
    all passed it - the see-through test because the hole is at the silhouette
    EDGE, which it reads as background rather than as a hole. That limit is
    written down in `townlib.solidity` and this is the case that proved it.

    The triangle is built ON THE ROOF PLANE (apex at the ridge, base at the
    eave line) rather than on the wall top, because a triangle stopping at the
    wall top leaves a thin wedge gap along the eave - which is the same fault
    one notch smaller."""
    ex, ez, rz, ln = roof["eave_x"], roof["eave_z"], roof["ridge_z"], roof["length"]
    m = L.mat_solid("gable_board", (0.44, 0.36, 0.26), 0.90, 0.0)
    for side in (-1, 1):
        y0 = side * (ln / 2.0) - thick / 2.0
        y1 = side * (ln / 2.0) + thick / 2.0
        v = [Vector((-ex, y0, ez)), Vector((ex, y0, ez)), Vector((0.0, y0, rz)),
             Vector((-ex, y1, ez)), Vector((ex, y1, ez)), Vector((0.0, y1, rz))]
        f = [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)]
        objs.append(L.make("gable", v, f, m))


def bench(objs, x, y, rz):
    """A bench. A plank on two stones, because that is what it is FOR."""
    m = L.mat_solid("bench_wood", BENCH, 0.88, 0.0)
    ms = L.mat_solid("bench_stone", (0.30, 0.29, 0.26), 0.92, 0.0)
    v, f = L.box(2.00, 0.42, 0.13)
    ob = L.make("bench_seat", L.xform(v, loc=(x, y, 0.44), rot=(0, 0, rz)), f, m)
    objs.append(ob)
    for s in (-1, 1):
        v2, f2 = L.box(0.32, 0.38, 0.42)
        dx, dy = math.cos(rz) * s * 0.70, math.sin(rz) * s * 0.70
        objs.append(L.make("bench_leg", L.xform(v2, loc=(x + dx, y + dy, 0.20)), f2, ms))


def lamp(objs, x, y, z0):
    """A lamp at the door - content's tier-2 line, verbatim."""
    mi = L.mat_solid("lamp_iron", IRON, 0.45, 0.65)
    v, f = L.box(0.08, 0.08, 1.05)
    objs.append(L.make("lamp_post", L.xform(v, loc=(x, y, z0 + 0.52)), f, mi))
    v, f = L.box(0.26, 0.26, 0.30)
    objs.append(L.make("lamp_box", L.xform(v, loc=(x, y, z0 + 1.18)), f, mi))
    mg = L.mat_glow("lamp_flame", FLAME, 3.2)
    v, f = L.box(0.15, 0.15, 0.18)
    objs.append(L.make("lamp_flame", L.xform(v, loc=(x, y, z0 + 1.18)), f, mg))


def banner(objs, x, y, z_top, w, h, rz):
    """A banner on the gable - content's tier-3 line. Plain cloth, a bar."""
    mb = L.mat_solid("banner_cloth", BANNER, 0.82, 0.0)
    mt = L.mat_solid("banner_bar", BANNER_TRIM, 0.50, 0.45)
    v, f = L.box(w, 0.05, h)
    objs.append(L.make("banner", L.xform(v, loc=(x, y, z_top - h / 2.0), rot=(0, 0, rz)), f, mb))
    v, f = L.box(w * 1.08, 0.09, 0.11)
    objs.append(L.make("banner_bar", L.xform(v, loc=(x, y, z_top), rot=(0, 0, rz)), f, mt))


# -------------------------------------------------------------- the three tiers
def hall_t1(objs):
    """TIER 1 - THE MOOT HALL. Timber, thatched, one door, a bench outside.

    4 x 6 m, ONE storey. Walls are `Wall_Plaster_WoodGrid` (timber-framed
    plaster), with ONE `Wall_Plaster_Door_Flat` on the south face - content
    says "one door" and it gets exactly one. Corners `Corner_Exterior_Wood`.
    No paving, no stair, no lamp: a tier-1 building is make-do and the ABSENCE
    of dressing is as much the wear as the sagging ridge is."""
    def pick(side, i, s):
        if side == 'S' and i == 0:
            return "Wall_Plaster_Door_Flat"
        # *** NOT `Wall_Plaster_WoodGrid`. *** The design doc chose that module
        # off its NAME and called it "timber-framed"; the first render of this
        # tier showed you could SEE STRAIGHT THROUGH THE HALL, because the
        # module is an open timber LATTICE. Its 248 tris against the straight
        # wall's 86 say the same thing, and I did not read that either until
        # the picture made me. One lattice bay is kept on the north face as a
        # vent - that is what the piece is actually FOR - and every other bay
        # is `Wall_Plaster_Straight`, which is plaster with wood trim: the
        # half-timbered look content's "timber hall" asks for, and solid.
        if side == 'N' and i == 1:
            return "Wall_Plaster_WoodGrid"
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 2, 3, 1, pick, "Corner_Exterior_Wood")
    roof = thatch(objs, wall_top=STOREY, half_w=W / 2.0, length=D, overhang=0.46,
                  pitch=0.86, sag=0.20, seed="hall_t1")
    gable(objs, roof)
    core = list(objs)                      # walls + roof + gable; the BUILDING
    bench(objs, x=W / 2.0 - 0.6, y=-D / 2.0 - 0.55, rz=0.0)
    return {"footprint_m": [W, D], "storeys": 1, "core": core}


def hall_t2(objs):
    """TIER 2 - THE CHIEF'S HALL. Stone footings, tiled, a stair, a lamp.

    6 x 8 m, TWO storeys. The wear changes with HEIGHT, which is what content's
    "stone footings" means: `Wall_UnevenBrick_*` on the ground storey,
    `Wall_Plaster_*` above. Corners are the wide brick ones. Round tile roof
    from the pack. A stair to the upper room and a lamp at the door, both named
    in content's line."""
    def pick(side, i, s):
        if s == 0:
            if side == 'S' and i == 1:
                return "Wall_UnevenBrick_Door_Round"
            if side in 'EW' and i in (1, 2):
                return "Wall_UnevenBrick_Window_Wide_Round"
            return "Wall_UnevenBrick_Straight"
        if side in 'EW' and i in (1, 2):
            return "Wall_Plaster_Window_Wide_Round"
        if side in 'NS' and i == 1:
            return "Wall_Plaster_Window_Wide_Round"
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 4, 2, pick, "Corner_ExteriorWide_Brick")
    # Roof_RoundTiles_6x8 measures 8.2498 x 9.6827 x 5.6722, min z -0.7821, so
    # its origin sits AT the wall top and the skirt laps 0.78 down over it.
    place("Roof_RoundTiles_6x8", (0.0, 0.0, 2 * STOREY), 0.0, objs)
    # *** THE PACK'S ROOF IS OPEN AT BOTH ENDS TOO. *** I fixed tier 1's gable
    # and shipped tier 2 with the identical hole one notch along - the sheet
    # showed a dark void under the red tile at the end. Measured off
    # `_hall_measure.json`, NOT assumed: Roof_RoundTiles_6x8 min
    # [-4.1249, -4.854, -0.7821], dims [8.2498, 9.6827, 5.6722], so the eave
    # line is x +-4.1249 at z -0.7821 and the ridge tops out at +4.8901, both
    # relative to the placement origin at the wall top. The board is set a
    # little INSIDE those numbers so it tucks under the tile instead of
    # poking through it - a gable flush with the roof plane is a coin toss.
    rz0 = 2 * STOREY
    place_roof = {"eave_x": 4.1249 - 0.25, "eave_z": rz0 - 0.55,
                  "ridge_z": rz0 + 4.60, "length": 9.55}
    gable(objs, place_roof, thick=0.30)
    place("Prop_Chimney", (W / 2.0 - 1.0, D / 2.0 - 1.0, 2 * STOREY), 0.0, objs)
    core = list(objs)                      # walls + roof + chimney
    place("Stairs_Exterior_Straight", (0.0, -D / 2.0 - 1.05, 0.0), 0.0, objs)
    lamp(objs, x=1.55, y=-D / 2.0 - 0.30, z0=0.0)
    return {"footprint_m": [W, D], "storeys": 2, "core": core}


def hall_t3(objs):
    """TIER 3 - THE HALL OF BELLMIRE. Stone and tower, banners, a paved court.

    `lm_hall.glb` IS ALREADY a stone hall with a tower - a gabled three-storey
    range, a square stone corner tower with a conical tiled spire and a metal
    finial, stone footings, timber framing, shuttered windows. 13.80 x 15.71 x
    22.41 m, 119,062 tris. **IT IS NOT REBUILT.** It is imported, RE-CENTRED
    (its own centre is x +1.9246, which would make the hall jump 1.92 m
    sideways on upgrade) and dressed with the three things content's line asks
    for that it does not have: banners on the gable, a paved court, a railing.

    ONE THING IN CONTENT'S LINE IS DELIBERATELY NOT BUILT: "a guard at the
    steps". A guard is a CHARACTER, not a building asset; the miniboss roster
    is capped at 70 and a town NPC is not a building. It is called out in the
    summary rather than silently invented."""
    hp = os.path.join(W5, "assets", "buildings", "lm_hall.glb")
    if not os.path.isfile(hp):
        raise SystemExit("MISSING lm_hall.glb at %s" % hp)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=hp)
    new = [o for o in bpy.data.objects if o not in before]
    body = [o for o in new if o.type == 'MESH']
    objs.extend(body)
    core = list(body)                      # the hall itself; the court is yard
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(body)
    W, D = mx.x - mn.x, mx.y - mn.y
    # the paved court, on the kit's own 2 m grid, in front of the south face
    y_front = mn.y
    for i in range(-2, 3):
        for j in range(2):
            place("Floor_Brick", (((mn.x + mx.x) / 2.0) + i * GRID,
                                  y_front - 1.0 - j * GRID, 0.01), 0.0, objs)
    # the railing along the court's outer edge
    for i in (-2, -1, 0, 1, 2):
        place("Prop_MetalFence_Ornament",
              (((mn.x + mx.x) / 2.0) + i * 1.9523, y_front - 3.0 - 1.0, 0.0), 0.0, objs)
    # banners on the gable face, flanking the centre line
    cx = (mn.x + mx.x) / 2.0
    for s in (-1, 1):
        banner(objs, x=cx + s * 2.1, y=y_front - 0.35, z_top=9.6, w=1.15, h=3.4, rz=0.0)
    return {"footprint_m": [round(W, 3), round(D, 3)], "storeys": "3 + tower",
            "source": "lm_hall.glb re-centred, NOT rebuilt", "core": core}


BUILDERS = {"hall_t1": hall_t1, "hall_t2": hall_t2, "hall_t3": hall_t3}


def build(key, px):
    """Build one tier and HONOUR THE PIVOT CONTRACT by re-centring at the end.

    This is the one guarantee the game build depends on, so it is enforced by
    measurement after the fact rather than by hoping every placement was
    right: footprint centre to x=0,y=0 and the lowest geometry to z=0."""
    objs = []
    meta = BUILDERS[key](objs)
    trim_materials(px)
    bpy.context.view_layer.update()
    # *** THE PIVOT IS THE BUILDING'S CENTRE, NOT THE ASSEMBLY'S. *** My first
    # full run re-centred on everything, so tier 3's paved court - which only
    # extends SOUTH - dragged the hall 2 m north of the spawn point and the
    # ladder would have made the hall JUMP on upgrade. That is the exact defect
    # this ladder was created to route around, reintroduced by my own fix for
    # it. Builders hand back `core`: the walls and roof, no yard, no bench.
    core = meta.pop("core", None) or objs
    cmn, cmx, _ = G.world_bounds(core)
    cx, cy = (cmn.x + cmx.x) / 2.0, (cmn.y + cmx.y) / 2.0
    mn, mx, _ = G.world_bounds(objs)
    for o in objs:
        o.location = (o.location.x - cx, o.location.y - cy, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn2, mx2, _ = G.world_bounds(objs)
    cmn2, cmx2, _ = G.world_bounds(core)
    meta.update({
        "core_centre_dx_dy": [round((cmn2.x + cmx2.x) / 2.0, 4),
                              round((cmn2.y + cmx2.y) / 2.0, 4)],
        "core_dims_m": [round(cmx2.x - cmn2.x, 4), round(cmx2.y - cmn2.y, 4),
                        round(cmx2.z - cmn2.z, 4)],
        "dims_m": [round(mx2.x - mn2.x, 4), round(mx2.y - mn2.y, 4),
                   round(mx2.z - mn2.z, 4)],
        "base_dz_m": round(mn2.z, 4),
        "centre_dx_dy": [round((mn2.x + mx2.x) / 2.0, 4),
                         round((mn2.y + mx2.y) / 2.0, 4)],
        "n_obj": len(objs),
        "n_tri": sum(len(o.data.polygons) for o in objs if o.type == 'MESH'),
    })
    return objs, meta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=W5)
    ap.add_argument("--px", type=int, default=1024)
    ap.add_argument("--resx", type=int, default=1280)
    ap.add_argument("--resy", type=int, default=1160)
    ap.add_argument("--only", default="")
    ap.add_argument("--noglb", action="store_true")
    ap.add_argument("--maxmb", type=float, default=9.0)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    keys = [k for k in ORDER if not a.only or k == a.only]
    root = os.path.join(a.repo, "renders", "art", "town", "hall")
    glbdir = os.path.join(a.repo, "assets", "buildings")
    os.makedirs(root, exist_ok=True)
    os.makedirs(glbdir, exist_ok=True)
    rep = {"when_ct": "28 Nov 2026 02:4x-03:0x CT", "tiers": {}, "errors": [],
           "px": a.px, "maxmb": a.maxmb}

    for key in keys:
        G.purge()
        _PROTO.clear()
        scene, eng = T.scene_setup(a.resx, a.resy)
        objs, meta = build(key, a.px)
        if not a.noglb:
            gp = os.path.join(glbdir, "town_%s.glb" % key)
            ok, note, nimg = export_glb_jpeg(objs, gp)
            meta["export_note"] = note
            meta["n_images_in_file"] = nimg
            meta["glb"] = os.path.relpath(gp, a.repo).replace("\\", "/")
            meta["glb_bytes"] = os.path.getsize(gp) if os.path.isfile(gp) else 0
            meta["glb_mb"] = round(meta["glb_bytes"] / 1048576.0, 3)
            if not ok:
                rep["errors"].append("%s EXPORT FAILED: %s" % (key, note))
            # THE SIZE GATE - new this ladder. Every gate the texture run had
            # went green over a 28.1 MB lm_hall; nothing asked "is this sane".
            if meta["glb_mb"] > a.maxmb:
                rep["errors"].append("%s GLB %0.2f MB > %0.2f MB cap"
                                     % (key, meta["glb_mb"], a.maxmb))
            if meta["glb_bytes"] < 2000:
                rep["errors"].append("%s GLB SUSPICIOUSLY SMALL: %d bytes"
                                     % (key, meta["glb_bytes"]))

        mn, mx, _ = G.world_bounds(objs)
        hero, _all = T.add_hero(dx=mx.x + 0.9)
        gnd = T.ground_plane((mx.x - mn.x) * 2.2 + 6.0, (mx.y - mn.y) * 2.2 + 6.0)
        bpy.context.view_layer.update()
        allm = objs + hero + [gnd]
        mn2, mx2, pts = G.world_bounds(allm)
        center = (mn2 + mx2) / 2.0
        radius = max(1.0, (mx2 - mn2).length / 2.0)
        G.add_lights(center, radius, (0.85, 0.88, 0.95))
        cam, cam_d = T.new_ortho_cam(scene)
        outd = os.path.join(root, key)
        os.makedirs(outd, exist_ok=True)
        vrep = {}
        for vname, az, el in T.VIEWS:
            T.aim_cam(cam, cam_d, pts, center, radius, az, el, a.resx, a.resy)
            p = os.path.join(outd, "%s.png" % vname)
            scene.render.filepath = p
            bpy.ops.render.render(write_still=True)
            op, bd = T.alpha_px(p), T.border_px(p)
            for o in objs:
                o.hide_render = True
            pn = os.path.join(outd, "_no_%s.png" % vname)
            scene.render.filepath = pn
            bpy.ops.render.render(write_still=True)
            mv = T.moved_px(p, pn)
            for o in objs:
                o.hide_render = False
            for o in hero:
                o.hide_render = True
            ph = os.path.join(outd, "_nohero_%s.png" % vname)
            scene.render.filepath = ph
            bpy.ops.render.render(write_still=True)
            hb = T.moved_box(p, ph)
            for o in hero:
                o.hide_render = False
            vrep[vname] = {"opaque_px": op, "border_alpha_px": bd,
                           "subject_moved_px": mv, "hero_moved_px": hb["px"],
                           "hero_h_px": hb["h_px"], "hero_w_px": hb["w_px"]}
            if op == 0:
                rep["errors"].append("%s/%s BLANK" % (key, vname))
            if bd > 0:
                rep["errors"].append("%s/%s BORDER %d - clipped" % (key, vname, bd))
            if mv < 1500:
                rep["errors"].append("%s/%s SUBJECT NOT SEEN: %d px moved"
                                     % (key, vname, mv))
            # SCALE-AWARE. Against a 22.4 m hall the 2.453 m hero is correctly
            # tiny, so an absolute area floor calls a working reference absent.
            # The question is whether the eye can READ it, which is a height.
            if hb["px"] < 250:
                rep["errors"].append("%s/%s HERO REFERENCE NOT SEEN: %d px moved"
                                     % (key, vname, hb["px"]))
            elif hb["h_px"] < 34:
                rep["errors"].append(
                    "%s/%s HERO REFERENCE NOT LEGIBLE: only %d px tall"
                    % (key, vname, hb["h_px"]))
            for junk in (pn, ph):
                try:
                    os.remove(junk)
                except Exception:
                    pass
        # SEE-THROUGH TEST, subject alone through the front camera. Ground and
        # hero are hidden because both would sit behind the walls and fill the
        # holes this is trying to find - an instrument whose background hides
        # the fault it looks for is not an instrument.
        T.aim_cam(cam, cam_d, pts, center, radius, 0.0, 10.0, a.resx, a.resy)
        for o in hero:
            o.hide_render = True
        gnd.hide_render = True
        sp = os.path.join(outd, "_solid_front.png")
        scene.render.filepath = sp
        bpy.ops.render.render(write_still=True)
        sol = T.solidity(sp)
        for o in hero:
            o.hide_render = False
        gnd.hide_render = False
        meta["solidity_front"] = sol
        if sol["red_on_empty"]:
            rep["errors"].append("%s SOLIDITY RED ON EMPTY: silhouette %d px"
                                 % (key, sol["silhouette_px"]))
        elif sol["hole_frac"] > 0.18:
            rep["errors"].append(
                "%s SEE-THROUGH: %0.1f%% of the front silhouette box is holes"
                % (key, sol["hole_frac"] * 100.0))
        meta["views"] = vrep
        rep["tiers"][key] = meta

    # ------------------------------------- THE SHEET: three tiers, ONE camera
    if len(keys) == len(ORDER):
        G.purge()
        _PROTO.clear()
        RX, RY = 1860, 820
        scene, eng = T.scene_setup(RX, RY)
        placed, spans, x = {}, [], 0.0
        for key in ORDER:
            objs, _m = build(key, a.px)
            mn, mx, _ = G.world_bounds(objs)
            for o in objs:
                o.location = (o.location.x + (x - mn.x),
                              o.location.y - (mn.y + mx.y) / 2.0,
                              o.location.z - mn.z)
            bpy.context.view_layer.update()
            w = mx.x - mn.x
            placed[key] = objs
            spans.append((key, x, x + w))
            # 4.0 m, not 1.2. At 1.2 the sheet showed tier 1's thatch touching
            # tier 2's wall and tier 2 running into tier 3's tower - three
            # tiers that read as ONE rambling building, which fails the row's
            # own acceptance test however green every number was.
            x += w + 4.0
        hero, _ = T.add_hero(dx=x + 0.8)
        bpy.context.view_layer.update()
        hmn, hmx, _ = G.world_bounds(hero)
        total = hmx.x
        gnd = T.ground_plane(total + 4.0, 26.0, cx=total / 2.0)
        bpy.context.view_layer.update()
        subj = [o for v in placed.values() for o in v]
        allm = subj + hero + [gnd]
        mn2, mx2, pts = G.world_bounds(allm)
        center = (mn2 + mx2) / 2.0
        radius = max(1.0, (mx2 - mn2).length / 2.0)
        G.add_lights(center, radius, (0.85, 0.88, 0.95))
        cam, cam_d = T.new_ortho_cam(scene)
        T.aim_cam(cam, cam_d, pts, center, radius, 24.0, 11.0, RX, RY, pad=1.04)
        sheet = os.path.join(root, "_tiers_side_by_side.png")
        scene.render.filepath = sheet
        bpy.ops.render.render(write_still=True)

        # per-tier silhouette, measured by hiding everything else
        sil = {}
        for key in ORDER:
            for k2, o2 in placed.items():
                for o in o2:
                    o.hide_render = (k2 != key)
            for o in hero:
                o.hide_render = True
            gnd.hide_render = True
            p = os.path.join(root, "_sil_%s.png" % key)
            scene.render.filepath = p
            bpy.ops.render.render(write_still=True)
            arr = G.read_png(p)
            ys, xs = np.where(arr[..., 3] > 0.03)
            sil[key] = {"px": int(len(xs)),
                        "h_px": int(ys.max() - ys.min() + 1) if len(ys) else 0,
                        "w_px": int(xs.max() - xs.min() + 1) if len(xs) else 0}
            try:
                os.remove(p)
            except Exception:
                pass
        for o2 in placed.values():
            for o in o2:
                o.hide_render = False
        for o in hero:
            o.hide_render = False
        gnd.hide_render = False

        sheet_px = T.alpha_px(sheet)
        nos = os.path.join(root, "_sheet_nosubj.png")
        for o in subj:
            o.hide_render = True
        scene.render.filepath = nos
        bpy.ops.render.render(write_still=True)
        sheet_moved = T.moved_px(sheet, nos)
        for o in subj:
            o.hide_render = False
        try:
            os.remove(nos)
        except Exception:
            pass

        from bpy_extras.object_utils import world_to_camera_view as w2c
        buf = G.read_png(sheet)
        h, w = buf.shape[0], buf.shape[1]
        G.draw_text(buf, "BELLMIRE - THE HALL, TIER 1 TO 3. ONE PIVOT, ONE CAMERA, ONE ORTHO SCALE.",
                    14, 12, scale=2)
        G.draw_text(buf, "HERO = KAYKIT KNIGHT, IDLE FRAME 1, STANDS 2.453 M TO THE HELMET - MEASURED THIS RUN.",
                    14, 34, scale=2)
        G.draw_text(buf, "T1 THATCH IS AUTHORED (NO THATCH IN ANY OF 49 PACKS). WALLS/ROOF/COURT = MEGAKIT, CC0.",
                    14, 56, scale=2)
        boxes = []
        for i, (key, x0w, x1w) in enumerate(spans):
            co = w2c(scene, cam, Vector(((x0w + x1w) / 2.0, 0.0, 0.0)))
            px0 = int(co.x * w)
            t = "%s  -  %s" % (CANON[key][0].upper(), CANON[key][2].upper())
            tw = 6 * 2 * len(t)
            xx = max(6, min(w - tw - 6, px0 - tw // 2))
            yy = h - 74 + i * 20            # SEPARATE ROW PER TIER, by construction
            G.draw_text(buf, t, xx, yy, scale=2)
            boxes.append((key, xx, yy, tw, 14))
        lab = {k: int((buf[y:y + bh, xx:xx + bw, 3] > 0.03).sum())
               for k, xx, y, bw, bh in boxes}
        G.write_png(sheet, buf)

        if sheet_px == 0:
            rep["errors"].append("SHEET BLANK")
        if sheet_moved < 4000:
            rep["errors"].append("SHEET SUBJECTS NOT SEEN: %d px" % sheet_moved)
        if T.border_px(sheet) > 0:
            rep["errors"].append("SHEET BORDER %d - clipped" % T.border_px(sheet))
        if not lab:
            rep["errors"].append("RED ON EMPTY: zero labels measured")
        for k, v in lab.items():
            if v == 0:
                rep["errors"].append("LABEL EMPTY: %s" % k)
        # THE LADDER GATE (townlib.ladder_gate), 28 Nov 07:5x CT. It KEEPS the
        # monotonic rule these four lines used to carry - the hall genuinely
        # grows each tier (178 < 343 < 609 px) - and that is why it is passed
        # growth="monotonic" rather than the well's "free". What it ADDS is the
        # two things this gate never had: RED ON EMPTY (a tier that failed to
        # render simply vanished from `sil` and every surviving number read
        # fine) and a SCALE FLOOR, which the well ladder needed because its
        # 06:46 draft framed the sheet three times too far away and printed
        # GREEN. dims_m is this file's OWN Blender-space extent, so index 2 is
        # the Z height unambiguously. Proof: tools/art/_laddergate_validate.py,
        # which replays this hall sheet and three real well sheets.
        rep["errors"].extend(T.ladder_gate(
            sil, list(ORDER),
            {k: (v.get("dims_m") or [0, 0, 0])[2]
             for k, v in rep["tiers"].items()},
            RY, growth="monotonic"))
        rep["sheet"] = {"path": os.path.relpath(sheet, a.repo).replace("\\", "/"),
                        "opaque_px": sheet_px, "subject_moved_px": sheet_moved,
                        "border_alpha_px": T.border_px(sheet), "label_px": lab,
                        "silhouette": sil,
                        "spans": [[s[0], round(s[1], 3), round(s[2], 3)] for s in spans]}
        rep["engine"] = eng

    rep["verdict"] = "GREEN" if not rep["errors"] else "RED"
    with open(os.path.join(root, "_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("HALLGEN " + json.dumps({"verdict": rep["verdict"],
                                   "errors": rep["errors"],
                                   "tiers": {k: v.get("dims_m")
                                             for k, v in rep["tiers"].items()}}))


main()
