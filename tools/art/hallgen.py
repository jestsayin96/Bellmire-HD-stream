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
# *** THESE ARE LINEAR, NOT sRGB, AND THAT HAS BITTEN ONCE ALREADY. ***
# `mat_solid` writes straight into the Principled Base Color socket, which is
# LINEAR. A value picked as though it were an sRGB swatch therefore renders
# about two stops light: the gable board sat at (0.44, 0.36, 0.26) and reached
# the screen as sRGB 177,162,139 - the "flat untextured white" triangle the
# game build saw on stream. The thatch and bench values below were tuned by
# eye against a render, so they are left exactly as they are; only the banner,
# which nobody had ever looked at close up, is restated as a true deep red.
BANNER = (0.1500, 0.0120, 0.0100)       # = sRGB 0.42, 0.10, 0.09
BANNER_TRIM = (0.3400, 0.2100, 0.0330)  # = sRGB 0.62, 0.50, 0.20

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


def _count_glb_images(path):
    """Count the images actually embedded in a written .glb, from its own bytes.

    Reads the GLB container's JSON chunk and returns len(json["images"]). This
    is the viewer's question - what is IN the file - rather than what Blender's
    in-memory datablock flags imply. Returns -1 if the file cannot be read or
    parsed at all, which is distinguishable from a true 0 so a caller can never
    mistake "I could not look" for "there is nothing there"."""
    import struct as _struct, json as _json
    try:
        with open(path, "rb") as fh:
            hdr = fh.read(12)
            if len(hdr) < 12 or hdr[:4] != b"glTF":
                return -1
            clen, ctype = _struct.unpack("<II", fh.read(8))
            if ctype != 0x4E4F534A:          # 'JSON'
                return -1
            doc = _json.loads(fh.read(clen).decode("utf-8"))
        return len(doc.get("images", []))
    except Exception:
        return -1


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
    # WAS: len([i for i in bpy.data.images if ... and i.has_data]) - and that
    # counted ZERO for hall, inn AND barracks, every time. `has_data` is only
    # True once Blender has paged an image's pixels into memory; the pack's
    # maps are read straight off disk BY THE EXPORTER, so the datablock flag is
    # still False when we ask. The field whose whole purpose was to report what
    # was embedded rather than infer it was itself an inference, and a wrong
    # one that read GREEN (0 = "nothing odd here") while the truth was 5/5/6.
    # Found 28 Nov 13:4x CT by diffing this field against the written GLB's own
    # header. The count is now taken FROM THE FILE WE ACTUALLY WROTE, after the
    # write - the only place the real answer exists.
    base = dict(filepath=path, export_format='GLB', use_selection=True)
    try:
        bpy.ops.export_scene.gltf(export_image_format='JPEG',
                                  export_jpeg_quality=quality, **base)
        n_img = _count_glb_images(path)
        note = "jpeg q%d" % quality
        if n_img == 0:
            note += " - WARNING ZERO IMAGES EMBEDDED (untextured export?)"
        return True, note, n_img
    except TypeError as e1:
        ok, note = G.export_glb(objs, path)
        return ok, "FELL BACK TO AUTO (%s): %s" % (e1, note), _count_glb_images(path)
    except Exception as e2:
        ok, note = G.export_glb(objs, path)
        return ok, "FELL BACK TO AUTO (%s): %s" % (e2, note), _count_glb_images(path)


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


UV_PER_M = 0.48031   # MEASURED, not chosen: uv_area/world_area off
                     # `Wall_Plaster_Straight` in both shipped tiers
                     # (renders/art/town/_probe_uv.json) = one texture tile per
                     # 2.082 m, which IS the kit's 2 m grid.


def pack_mat(prefix, fallback_rgb, rough=0.90, metal=0.0):
    """The PACK material already in the file, by name prefix.

    The gable wore a flat solid colour on every tier shipped so far because
    nothing ever handed it one of the kit's. Reusing the datablock the wall
    modules already imported embeds NO new image - the dedupe pass in
    trim_materials collapses it with the walls' own copy."""
    cands = sorted((m for m in bpy.data.materials if m.name.startswith(prefix)),
                   key=lambda m: m.name)
    if cands:
        return cands[0]
    return L.mat_solid(prefix.lower() + "_fallback", fallback_rgb, rough, metal)


def uv_world_project(ob, scale=UV_PER_M):
    """Box-project WORLD coordinates into UVs at the pack's own density.

    *** THIS IS THE HALF OF THE GABLE FIX THAT IS EASY TO MISS. *** The gable
    meshes shipped with NO UV LAYER AT ALL - measured, `uv_area` 0.0 on both
    tiers - so simply assigning them a textured material would have sampled a
    single texel and left them exactly as flat as the solid colour they
    replaced. A material swap without this is a change that looks like a fix
    and is not one."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active
    mw = ob.matrix_world
    rot = mw.to_3x3()
    for p in me.polygons:
        n = rot @ p.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for li in p.loop_indices:
            w = mw @ me.vertices[me.loops[li].vertex_index].co
            if ax == 0:
                u, v = w.y, w.z
            elif ax == 1:
                u, v = w.x, w.z
            else:
                u, v = w.x, w.y
            uv.data[li].uv = (u * scale, v * scale)


def _plank(objs, mat, sx, sy, sz, loc, ry=0.0):
    v, f = L.box(sx, sy, sz)
    ob = L.make("gable_timber", L.xform(v, loc=loc, rot=(0.0, ry, 0.0)), f, mat)
    uv_world_project(ob)
    objs.append(ob)
    return ob


def gable_frame(objs, ex, ez, rz, fy, mat, full):
    """Plain timber framing on the gable face - a tie, a king post, and on the
    prosperous tier the two barge boards and a pair of struts.

    WEAR IS THE VARIABLE (art rule 2): tier 1 gets the tie and the post only,
    because a moot hall is make-do; tier 2 gets the full frame. PLAINNESS IS
    THE VOICE (art rule 1): straight boards, no carving, no device - the
    pack's own gable on `lm_hall` is framed exactly this way and it is the
    reference I matched by eye."""
    ex_f, ez_f, rz_f = ex - 0.10, ez + 0.10, rz - 0.16
    th = 0.09
    tie_z = ez_f + 0.15
    _plank(objs, mat, 2.0 * ex_f, th, 0.30, (0.0, fy, tie_z))
    post_h = max(0.2, rz_f - (tie_z + 0.15))
    _plank(objs, mat, 0.24, th, post_h, (0.0, fy, tie_z + 0.15 + post_h / 2.0))
    if not full:
        return
    run = math.hypot(ex_f, rz_f - ez_f)
    theta = math.atan2(rz_f - ez_f, ex_f)
    for side in (-1, 1):
        # ry = +side*theta, NOT -side*theta. Rotation about Y sends (1,0,0) to
        # (cos a, 0, -sin a), so the board whose centre is at -ex/2 and whose
        # far end must reach the ridge needs a = -theta. I shipped the sign
        # inverted on the first pass and the render showed four timbers
        # crossing the slope and stabbing a metre out past the tile - no
        # number caught it, the picture did.
        _plank(objs, mat, run, th, 0.26,
               (side * ex_f / 2.0, fy, (ez_f + rz_f) / 2.0), ry=side * theta)
    for side in (-1, 1):
        _plank(objs, mat, 0.20, th, post_h * 0.62,
               (side * ex_f * 0.46, fy, tie_z + 0.15 + post_h * 0.31))


def gable(objs, roof, thick=0.26, frame="full"):
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
    m = pack_mat("MI_Plaster", (0.26, 0.23, 0.18))
    mw = pack_mat("MI_WoodTrim", (0.09, 0.055, 0.032))
    for side in (-1, 1):
        y0 = side * (ln / 2.0) - thick / 2.0
        y1 = side * (ln / 2.0) + thick / 2.0
        v = [Vector((-ex, y0, ez)), Vector((ex, y0, ez)), Vector((0.0, y0, rz)),
             Vector((-ex, y1, ez)), Vector((ex, y1, ez)), Vector((0.0, y1, rz))]
        f = [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)]
        ob = L.make("gable", v, f, m)
        uv_world_project(ob)
        objs.append(ob)
        gable_frame(objs, ex, ez, rz, side * (ln / 2.0 + thick / 2.0 + 0.025),
                    mw, full=(frame == "full"))


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
    gable(objs, roof, frame="simple")
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


def _body_tris(body):
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for o in body:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        mw = o.matrix_world
        vs = [mw @ v.co for v in me.vertices]
        me.calc_loop_triangles()
        for t in me.loop_triangles:
            out.append(tuple(vs[i] for i in t.vertices))
        oe.to_mesh_clear()
    return out


def free_ground_rect(body, mn, mx, cell=0.25, zlo=0.02, zhi=1.60, margin=0.0):
    """The largest EMPTY ground rectangle inside the body's own footprint.

    *** THE INSTRUMENT THAT CAME FIRST WAS WRONG AND I THREW IT AWAY. *** My
    first pass sampled VERTICES onto the grid, and a flat wall panel has
    vertices only at its corners, so it reported wide empty bands straight
    through solid walls. This rasterises TRIANGLE BOUNDING BOXES, which
    over-marks rather than under-marks - and over-marking is the safe
    direction when the question is "where may I build".
    IT MUST ALSO GO RED ON EMPTY: a run that finds no free ground at all
    returns a zero rectangle and the caller's assert fires, rather than
    quietly laying nothing and passing.
    `margin` is 0 ON PURPOSE. The rasterisation already over-marks by one
    cell on every side, so the rectangle is inset from real geometry by up to
    0.25 m before anything else is subtracted; adding a second margin on top
    of that cost a whole 2 m tile column and shrank the court to four tiles.
    The measured exterior rectangle on `lm_hall` is 4.00 x 10.00 m."""
    import numpy as np
    nx = max(1, int((mx.x - mn.x) / cell))
    ny = max(1, int((mx.y - mn.y) / cell))
    occ = np.zeros((ny, nx), dtype=bool)
    for tri in _body_tris(body):
        zs = [p.z for p in tri]
        if max(zs) < zlo or min(zs) > zhi:
            continue
        c0 = max(0, int((min(p.x for p in tri) - mn.x) / cell) - 1)
        c1 = min(nx - 1, int((max(p.x for p in tri) - mn.x) / cell) + 1)
        r0 = max(0, int((min(p.y for p in tri) - mn.y) / cell) - 1)
        r1 = min(ny - 1, int((max(p.y for p in tri) - mn.y) / cell) + 1)
        occ[r0:r1 + 1, c0:c1 + 1] = True
    # *** AND NOW THROW AWAY THE INSIDE OF THE BUILDING. ***
    # The first version of this routine returned the largest free rectangle
    # full stop, and on `lm_hall` that is the NAVE INTERIOR - 6.0 x 12.0 m,
    # bigger than any yard outside - so the run laid eighteen paving tiles
    # INSIDE THE HALL and both my overhang gate and my tile-count gate called
    # it GREEN. A court nobody can see is the subject being absent while the
    # gate reads pass, which is the one failure mode this lane is told to go
    # looking for. Only ground reachable from OUTSIDE is ground: flood-fill
    # the free cells from the border and treat anything enclosed as solid.
    from collections import deque
    reach = np.zeros_like(occ)
    dq = deque()
    for c in range(nx):
        for r in (0, ny - 1):
            if not occ[r, c] and not reach[r, c]:
                reach[r, c] = True
                dq.append((r, c))
    for r in range(ny):
        for c in (0, nx - 1):
            if not occ[r, c] and not reach[r, c]:
                reach[r, c] = True
                dq.append((r, c))
    while dq:
        r, c = dq.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            r2, c2 = r + dr, c + dc
            if 0 <= r2 < ny and 0 <= c2 < nx and not occ[r2, c2] and not reach[r2, c2]:
                reach[r2, c2] = True
                dq.append((r2, c2))
    occ = occ | ~reach
    # largest all-free axis-aligned rectangle, histogram method
    best = (0, 0, 0, 0, 0)
    h = np.zeros(nx, dtype=int)
    for r in range(ny):
        h = np.where(occ[r], 0, h + 1)
        stack = []
        for c in range(nx + 1):
            cur = h[c] if c < nx else 0
            start = c
            while stack and stack[-1][1] >= cur:
                st, ht = stack.pop()
                area = ht * (c - st)
                if area > best[0]:
                    best = (area, st, r - ht + 1, c - 1, r)
                start = st
            stack.append((start, cur))
    area, c0, r0, c1, r1 = best
    if area <= 0:
        return (0.0, 0.0, 0.0, 0.0)
    x0 = mn.x + c0 * cell + margin
    y0 = mn.y + r0 * cell + margin
    x1 = mn.x + (c1 + 1) * cell - margin
    y1 = mn.y + (r1 + 1) * cell - margin
    return (x0, y0, x1, y1)


def gable_panel(body):
    """The gable, taken from the pack's OWN named infill panel.

    *** THREE HEURISTICS IN A ROW GOT THIS WRONG AND THE PANEL WAS SITTING
    *** THERE NAMED THE WHOLE TIME. ***
    Binning x over a tall band mixed a full-width storey with the narrowing
    triangle and put the centre at x +1.60; binning over the banner band
    picked the TOWER, which is the widest thing at that height, and put it at
    +3.87; and measuring the wall plane at the eave rather than at the banners
    buried them inside the wall. `lm_hall.glb` carries `Roof_Front_Brick8` -
    two objects, the south and north gable infills - and measuring it answers
    all of it at once: x -4.256..4.256, so the centre is EXACTLY 0.0; z
    9.237..14.683, so the triangle is 5.446 m tall; and the half-width at any
    height is that centre width scaled by how far up the triangle you are.
    When a part has a name, measure the part."""
    sel = [o for o in body
           if o.type == 'MESH' and o.name.split('.')[0].startswith("Roof_Front")]
    if not sel:
        return None
    pts = [o.matrix_world @ v.co for o in sel for v in o.data.vertices]
    x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
    z0, z1 = min(p.z for p in pts), max(p.z for p in pts)
    return (x0 + x1) / 2.0, (x1 - x0) / 2.0, z0, z1


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

    # *** THE COURT MOVES INSIDE THE PLOT. THIS IS A DEFECT FIX IN MY OWN
    # *** SHIPPED WORK, 28 Nov. ***
    # What shipped: the court was laid in front of the south face and the
    # railing 4 m beyond it, which made tier 3 measure 19.784 m deep against a
    # plot that allows 15.70 - a 4.078 m overhang, and the iron railing landed
    # ACROSS THE ROAD. `TOWN_TIER_FIT_SPEC.md` section 2 predicted it from the
    # numbers and the game build then saw it on stream.
    # Why it cannot simply be made shallower: the hall body is 13.801 x 15.706
    # and the plot allows 13.80 x 15.70, so there is NO ground at all in front
    # of the south door. Anything laid there overhangs by construction.
    # So the court goes where there IS free ground inside the plot, and the
    # free ground is MEASURED, not chosen - `free_ground_rect` rasterises every
    # triangle of the body between z 0.02 and 1.60 and returns the largest
    # empty rectangle. On `lm_hall` that is the open strip EAST of the nave and
    # NORTH of the tower. Widening the plot instead is explicitly forbidden by
    # the spec: that pushes an art defect into content's authored town.
    fx0, fy0, fx1, fy1 = free_ground_rect(body, mn, mx)
    tile = GRID
    ncx = int((fx1 - fx0) // tile)
    ncy = int((fy1 - fy0) // tile)
    cx0 = fx0 + ((fx1 - fx0) - ncx * tile) / 2.0
    cy0 = fy0 + ((fy1 - fy0) - ncy * tile) / 2.0
    court = []
    for i in range(ncx):
        for j in range(ncy):
            place("Floor_Brick", (cx0 + (i + 0.5) * tile,
                                  cy0 + (j + 0.5) * tile, 0.01), 0.0, court)
    # the railing along the court's OUTER (east) edge, inside the plot
    rail_x = cx0 + ncx * tile - 0.25
    span = ncy * tile
    nrail = max(1, int(span // 1.9523))
    r0 = cy0 + (span - nrail * 1.9523) / 2.0
    for i in range(nrail):
        place("Prop_MetalFence_Ornament",
              (rail_x, r0 + (i + 0.5) * 1.9523, 0.0), math.pi / 2.0, court)
    objs.extend(court)

    # banners on the gable face. The shipped pair hung off the ASSEMBLY centre
    # (x +1.92), which put one of them over the tower junction, and 0.35 m
    # PROUD OF THE BOUNDING BOX - a second overhang nobody had counted. Both
    # numbers are now measured off the gable itself.
    gp = gable_panel(body)
    if gp is None:
        raise SystemExit("hall_t3: no Roof_Front* gable panel in lm_hall.glb - "
                         "the banners have nothing measured to hang on")
    gcx, ghalf, gz0, gz1 = gp
    bw, bh, frac = 0.80, 2.40, 0.69
    z_top = gz0 + frac * (gz1 - gz0)
    avail = ghalf * (1.0 - frac)            # half-width of the triangle there
    bx = min(1.30, max(0.55, avail - bw / 2.0 - 0.10))
    # y: the bar is 0.09 deep, so centring it 0.045 inside the body's own
    # southern limit puts its outer face EXACTLY on that limit and adds not
    # one millimetre to the footprint - which is the whole point of this run.
    # It still stands proud of the gable panel, because the roof laps 0.035
    # past the panel and the banner only has to clear the panel.
    by = mn.y + 0.045
    for sgn in (-1, 1):
        banner(objs, x=gcx + sgn * bx, y=by, z_top=z_top, w=bw, h=bh, rz=0.0)
    return {"footprint_m": [round(W, 3), round(D, 3)], "storeys": "3 + tower",
            "source": "lm_hall.glb re-centred, NOT rebuilt",
            "court_rect_m": [round(v, 3) for v in (cx0, cy0,
                                                   cx0 + ncx * tile,
                                                   cy0 + ncy * tile)],
            "court_tiles": ncx * ncy,
            "gable_panel": [round(gcx, 3), round(ghalf, 3), round(gz0, 3),
                            round(gz1, 3)],
            "banner_xz": [round(bx, 3), round(z_top, 3), round(by, 3)],
            "core": core}


BUILDERS = {"hall_t1": hall_t1, "hall_t2": hall_t2, "hall_t3": hall_t3}


def plot_budget(landmark):
    """The plot the town actually authored, read off `data/town/bellmire.json`.

    Not a constant in this file and not a number remembered from the spec:
    the budget is content's data and it is the thing a tier must fit inside.
    `half` is a half-extent, so the budget is twice it."""
    p = os.path.join(W5, "data", "town", "bellmire.json")
    d = json.load(open(p, encoding="utf-8"))
    for b in d.get("buildings", []):
        if b.get("landmark") == landmark or b.get("shape") == landmark:
            h = b["half"]
            return round(2.0 * h[0], 4), round(2.0 * h[1], 4)
    raise SystemExit("plot_budget: no plot for %s in %s" % (landmark, p))


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

    # *** THE GATE THAT WOULD HAVE CAUGHT THE 4.08 m OVERHANG, AND DID NOT
    # *** EXIST WHEN I SHIPPED IT. ***
    # The plot IS the body's footprint (spec section 1b: the plots were
    # authored to the pack buildings' exact footprints, agreeing to 6 mm), so
    # the budget needs no second source: NO DRESSING MAY PROJECT BEYOND THE
    # BODY. Tier 3 shipped 4.078 m past it and every existing check passed.
    # AND IT GOES RED ON EMPTY. Ask what a PASS looks like with the subject
    # absent: drop the court and the railing altogether and the overhang test
    # passes perfectly. So the court is counted too, and zero is a failure.
    bw, bh = plot_budget("lm_hall")
    fx, fy = round(mx2.x - mn2.x, 4), round(mx2.y - mn2.y, 4)
    meta["plot_budget_m"] = [bw, bh]
    meta["footprint_vs_plot_m"] = [round(fx - bw, 4), round(fy - bh, 4)]
    bad = []
    if fx > bw + 0.01 or fy > bh + 0.01:
        bad.append("footprint %.3f x %.3f EXCEEDS plot %.2f x %.2f"
                   % (fx, fy, bw, bh))
    if key == "hall_t3" and meta.get("court_tiles", 0) < 6:
        bad.append("tier 3 has %d court tiles - content's line says a PAVED "
                   "COURT and an empty plot would pass the overhang test"
                   % meta.get("court_tiles", 0))
    meta["fit_gate"] = "GREEN" if not bad else "RED"
    meta["fit_gate_faults"] = bad
    if bad:
        raise SystemExit("FIT GATE RED for %s: %s" % (key, "; ".join(bad)))
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


# GUARDED 28 Nov 11:4x CT by the art lane so `inngen.py` can import this
# module's PROVEN pack layer (proto/place/wall_box/thatch/gable/bench/lamp)
# instead of duplicating 250 lines of it. Blender runs a `-P` script with
# __name__ == '__main__' - verified this run by running a one-line script
# through `blender -b -P`, which printed NAME_IS='__main__'. So invoking this
# file as a script is UNCHANGED; importing it no longer renders a hall.
if __name__ == "__main__":
    main()
