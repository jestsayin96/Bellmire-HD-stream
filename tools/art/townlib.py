"""townlib - the town harness helpers, shared by the tier-ladder generators.

WHY THIS FILE EXISTS AND WHAT IT DELIBERATELY DOES NOT DO
---------------------------------------------------------
`townbuildgen.py` (the well ladder) carries these helpers inline and it is
GREEN and shipped. The Hall ladder needs the same gates, so the honest choices
were (a) import them out of `townbuildgen`, which is impossible because that
module calls `main()` at import time, (b) refactor `townbuildgen` to import
from here, or (c) lift them into a sibling and leave the green harness alone.

**(c), deliberately.** A refactor of a shipped green harness to save ~120 lines
of duplication is a risk with no render behind it, on a two-week deadline. The
duplication is stated here so the next seat knows both copies exist and that
`townbuildgen.py` is the ORIGINAL - if these two ever disagree, that one is
right and this one is the suspect.

THE GATES AND WHAT EACH CANNOT SEE - carried over verbatim in intent:
  1. BLANK        - opaque pixels > 0. Cannot see a CLIPPED subject.
  2. BORDER       - zero alpha on the 1-px frame. Cannot see a subject that is
                    merely small.
  3. SUBJECT SEEN - render with and without, count the pixels that MOVED. This
                    is the one that catches an empty frame carrying a PASS, the
                    way the tier-5 spear's side-on gate did on 27 Nov. RED ON
                    EMPTY: below the floor is RED, because a metric over zero
                    pixels reads green and means nothing.
  4. HERO SEEN    - the same difference for the body, measured SEPARATELY. A
                    sheet whose scale reference failed to render is worse than
                    one with no reference, because the eye trusts it.
  5. SIZE         - the committed .glb's bytes. New this ladder: every gate the
                    texture run had went GREEN over a 28.1 MB `lm_hall`, so
                    "is this sane to commit" was a question nothing asked.
NONE OF THEM CAN SAY THE PROGRESSION READS. Only looking says that.
"""
import math, os

import bpy, numpy as np
from mathutils import Vector

import lordgen as G
import lordlib as L

W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures",
                    "Characters", "gltf", "Knight.glb")
VIEWS = (("front", 0.0, 10.0), ("three_quarter", 38.0, 14.0),
         ("side", 90.0, 10.0), ("back", 180.0, 10.0))

# *** THE 16 MESHES IN Knight.glb ARE NOT ONE BODY. *** Eight are the figure;
# the rest are loose equipment variants (swords, four shields, an Icosphere
# spanning z -1.0..+1.0) stacked in the same file. Keeping them made the first
# well sheet frame a sword hanging in the air and squeezed the three wells to
# 15% of frame width - and `hero_moved_px` read 20-37k and PASSED, ON THE WRONG
# OBJECT. A with/without difference proves something moved, never that it was
# the thing you named. WHITELIST BY EXACT NAME, NEVER BY SUBSTRING.
BODY = {"Knight_Body", "Knight_Head", "Knight_Helmet", "Knight_ArmLeft",
        "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight", "Knight_Cape"}
HERO_STANDS = 2.453      # helmet top, measured; the figure, not the AABB


def add_hero(dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=HERO)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    arm = next((o for o in new if o.type == 'ARMATURE'), None)
    if arm is not None and "Idle" in bpy.data.actions:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)
    keep = []
    for o in meshes:
        if o.name.split(".")[0] in BODY:
            keep.append(o)
        else:
            o.hide_render = True
    if not keep:
        keep = meshes
    # Move the ARMATURE only - the meshes are parented to it, so moving both
    # displaced every child twice, which was the other half of the bad sheet.
    for o in [o for o in new if o.parent is None]:
        o.location = (o.location.x + dx, o.location.y, o.location.z)
    bpy.context.view_layer.update()
    return keep, list(new)


def ground_plane(sx, sy, cx=0.0, mat=None):
    if mat is None:
        mat = L.mat_solid("gnd", (0.21, 0.20, 0.18), 0.95, 0.0)
    v, f = L.box(sx, sy, 0.12)
    ob = L.make("ground", v, f, mat)
    ob.location = (cx, 0.0, -0.06)
    return ob


def alpha_px(p):
    return int((G.read_png(p)[..., 3] > 0.03).sum())


def moved_px(p1, p2):
    a, b = G.read_png(p1), G.read_png(p2)
    return int((np.abs(a - b).max(axis=2) > 0.02).sum())


def moved_box(p1, p2):
    """The moved pixels AND the box they occupy.

    A bare moved-pixel count is not scale-aware, and the Hall ladder is where
    that bit: against a 22.4 m tier-3 hall the 2.453 m hero moves only ~650 px
    at 900x820 and the old floor of 1500 called it ABSENT. It is not absent -
    it is correctly tiny, because the building really is nine times its height.
    The question a scale reference has to answer is "can the eye read it", and
    that is a HEIGHT in pixels, not an area. So both are reported and the gate
    asks for a legible height as well as a non-trivial area."""
    a, b = G.read_png(p1), G.read_png(p2)
    m = np.abs(a - b).max(axis=2) > 0.02
    n = int(m.sum())
    if n == 0:
        return {"px": 0, "h_px": 0, "w_px": 0}
    ys, xs = np.where(m)
    return {"px": n, "h_px": int(ys.max() - ys.min() + 1),
            "w_px": int(xs.max() - xs.min() + 1)}


def border_px(p):
    a = G.read_png(p)
    e = np.concatenate([a[0, :, 3], a[-1, :, 3], a[:, 0, 3], a[:, -1, 3]])
    return int((e > 0.03).sum())


def aim_cam(cam, cam_d, pts, center, radius, az, el, resx, resy, pad=1.08):
    """Frame from the MEASURED point cloud. TRAP 1: clip_start/clip_end come
    off the measured depth span, never off defaults - a default clip_end of 100
    renders an empty transparent image AND REPORTS SUCCESS."""
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                math.sin(e))).normalized()
    cam.location = center + d * (radius * 4.0 + 2.0)
    cam.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    m3 = cam.matrix_world.to_3x3()
    right = (m3 @ Vector((1, 0, 0))).normalized()
    up = (m3 @ Vector((0, 1, 0))).normalized()
    fwd = (m3 @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    cam_d.ortho_scale = max(wide, tall * (resx / float(resy))) * pad
    dep = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(dep) - radius * 0.5)
    cam_d.clip_end = max(dep) + radius * 2.0 + 5.0


def scene_setup(resx, resy):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.055, 0.06, 0.075, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    return scene, eng


def new_ortho_cam(scene):
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    return cam, cam_d


def solidity(path):
    """SEE-THROUGH TEST: transparent pixels INSIDE the subject's own silhouette.

    Added 28 Nov 02:5x CT after looking at the first Hall tier-1 render, which
    every existing gate passed and which YOU COULD SEE STRAIGHT THROUGH. The
    design doc had picked `Wall_Plaster_WoodGrid` off its NAME ("timber-framed")
    and the module is an OPEN TIMBER LATTICE. Blank, border, subject-moved and
    hero-seen are all blind to it: a lattice is not blank, not clipped, not
    missing and not small - it is just not a wall.

    Scanline fill: for each row, count transparent pixels strictly between the
    leftmost and rightmost opaque pixel. Doors and windows count too, so this
    is a COMPARATIVE number, not a pass mark - the honest use is before/after
    on the same subject and camera.

    WHAT IT CANNOT SEE: a wall that is solid but the WRONG material; a hole in
    the roof that no scanline crosses between two opaque pixels (an opening at
    the very silhouette edge reads as background, not as a hole); and anything
    about colour. RED ON EMPTY: a silhouette under 1000 px returns -1 rather
    than a comfortable zero, because a metric over no subject reads perfect.
    """
    a = G.read_png(path)
    op = a[..., 3] > 0.03
    if int(op.sum()) < 1000:
        return {"silhouette_px": int(op.sum()), "hole_px": -1,
                "hole_frac": -1.0, "red_on_empty": True}
    holes = 0
    for row in op:
        idx = np.flatnonzero(row)
        if idx.size < 2:
            continue
        holes += int((~row[idx[0]:idx[-1] + 1]).sum())
    sil = int(op.sum())
    return {"silhouette_px": sil, "hole_px": holes,
            "hole_frac": round(holes / float(sil + holes), 4),
            "red_on_empty": False}
