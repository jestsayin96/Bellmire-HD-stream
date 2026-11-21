"""minibossfit - THE SCALE PROOF the fourteen minibosses never had.

  blender -b -noaudio -P tools/art/minibossfit.py -- --repo <repo> [--only k,k] [--sheet]

WHY THIS EXISTS. Mr. E's acceptance test is FIT: "these need to fit the
characters in our game." For gear that means rendering it on a body. For a
creature it means ONE question nobody had asked: how big does it actually read
standing next to a hero?

The answer was never obvious, because the two are scaled by different code:

  HEROES ARE NOT NORMALISED. Townsfolk/HeroBody instantiate the KayKit
  adventurer body and leave it alone - `size_k` is 1.0 and only children shrink
  it (townsfolk.gd ~253). So a viewer's hero is the RAW glb height, which this
  script measures rather than trusts.

  MONSTERS ARE NORMALISED to a real height in metres: bestiary.gd's `h`, and
  Monster scales the body to it from its measured bounds (bestiary.gd ~10).
  The minibosses are not in bestiary.gd at all yet, so whatever `h` the game
  build lane types in IS their in-game size - and this sheet is the argument
  for what to type.

So: each miniboss at its authored CANON height, beside a real KayKit adventurer
glb at scale 1.0, ONE FIXED ORTHO SCALE and ONE FIXED GROUND LINE across all
fourteen cells. Any cell can be compared with any other and with the hero.

TRAPS ANSWERED (the three that have already bitten this lane):
  SCALE/AIM - clip range and camera distance come from the measured evaluated
              world bounds of hero + creature together, never a default.
  BLANKS    - every PNG re-opened and its opaque pixel count asserted.
  MATRICES  - the hero is imported into the active scene and the view layer is
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
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

HERO_GLB = os.path.join("addons", "kaykit_character_pack_adventures",
                        "Characters", "gltf", "Knight.glb")

# ONE frame for all fourteen. 5.60 m wide x 3.83 m tall at 760x520, ground line
# 0.25 m above the bottom edge. The widest pair is the Gaoler (3.72 m of chain
# coil) plus a hero and a gap, so 5.60 m is measured headroom, not a guess.
CELL_X, CELL_Y = 760, 520
FRAME_W = 5.60
FRAME_H = FRAME_W * CELL_Y / float(CELL_X)
GROUND_UP = 0.25
GAP = 0.45                      # clear air between hero and creature footprint

# *** THE FRAME MARGIN, 20 NOV 2026 23:4x CT. THE RATCATCHER FAULT. ***
# `fits_frame` compared the pair's width against FRAME_W with ZERO margin and
# therefore answered TRUE at pair_w 5.59 against a 5.60 m frame - true by a
# centimetre, which at 760 px / 5.60 m is SEVEN TENTHS OF A PIXEL per side.
# The render clipped: ratcatcher front carries 15 px of hero arm on x=0 AND
# 3 px of pole tip on x=759, and the back view mirrors it. BOTH EDGES, not
# one - the pair genuinely spans the whole frame, so no amount of re-centring
# saves it and only a narrower pair does.
# Two changes, and they are separate on purpose:
#   (a) fits_frame now demands MARGIN_X of real air, so the number can SEE the
#       condition the border count was catching behind its back;
#   (b) the hero's HORIZONTAL offset is solved per cell instead of being a
#       fixed 0.45, so a wide creature gets its frame instead of a clip. The
#       DEPTH offset stays at GAP untouched - that one is the occlusion
#       margin, and tightening it to win pixels would buy a border at the
#       price of the two subjects hiding each other in the side view.
# GAP_MIN is the floor: below it hero and creature read as touching, and a
# cell that still will not fit at the floor is a REAL red for a wider frame or
# a narrower creature, not something to be squeezed away silently.
MARGIN_X = 0.12                 # ~16 px of air across the pair at this cell
GAP_MIN = 0.20

# *** THE OCCLUSION TEST, ADDED 17 NOV 2026, 15:40 CT - PORTED FROM weaponfit. ***
# THE DEFECT THIS CLOSES, FOUND BY LOOKING AND NOT BY ANY NUMBER HERE: the
# Reeve's pass 1 side view had a body standing entirely behind another body.
# Both checks in this file passed it, and they could not have done otherwise -
# a FULLY OCCLUDED FRAME IS STILL FULL OF OPAQUE PIXELS INSIDE THE BORDER,
# which is exactly and only what a blank check and a border check measure.
# An instrument that cannot see a thing cannot report it; it reports green.
#
# The answer is the one fault 4 found on the weapon register nine hours ago:
# ask the VIEWER'S question and let the renderer do the depth.
#   A = the hero alone, through this exact camera
#   B = the cell itself, hero + creature
#   C = the creature alone - its full silhouette, the denominator
# creature vis  = pixels that MOVED between A and B, counted only INSIDE C's
#                 own silhouette (bounded on purpose: the raw diff also catches
#                 cast shadow, and a fraction that can exceed 1.0 is a fraction
#                 of nothing I can name)
# creature seen = vis / alone - the share of the creature a viewer can see
# AND THE SAME QUESTION BACK THE OTHER WAY, because this frame has two subjects
# and either can hide the other. The hero-hidden case is not hypothetical: the
# docstring of place() records that exact fault being fixed BY CONSTRUCTION on
# an earlier pass, with nothing measuring whether it stays fixed. It does now.
#   hero vis/seen = moved between C and B, inside A's silhouette.
# A RATIO IS BLIND TO SIZE - 80% of a sliver is a sliver - so a view must clear
# VIS_MIN pixels as well. A view that clears neither PROVES NOTHING, and a cell
# needs MIN_PROVING views that do, or the cell FAILS. alone == 0 is RED.
SEEN_MIN = 0.15
VIS_MIN = 700                   # ~26x26 px on a 760x520 cell (0.18% of it).
                                # weaponfit's 900 scaled by this cell's area.
MIN_PROVING = 2
DIFF_EPS = 0.02
# Set by --prove-red ONLY. It renders the cell with the creature taken out of
# it while still measuring the creature, which is the fault itself in its
# purest form: a frame with no creature in it that is still full of opaque
# pixels inside the border. The blank check and the border check pass it. This
# test must not. See the proof recorded in docs/art/ at 15:51 CT.
PROVE_RED = False


def import_hero(repo):
    """The real body, at scale 1.0 - the size a hero actually IS in game.

    TWO THINGS THAT HAD TO BE MEASURED, NOT ASSUMED:

    1. The glb carries the whole wardrobe - six weapons and shields parked on
       the rig, plus a 1.9 m Icosphere. Measured raw it reports 3.45 m and the
       frame is wrong. Only the character's own `Knight_*` meshes are kept.
       CORRECTED 19 Nov 2026 22:5x CT: the Icosphere is NOT "shipped" by the
       glb and is not hidden in it either - it is a Blender 5.2 glTF-import
       artifact that appears for any glb carrying an armature. Proved on a
       byte search (zero occurrences of the string in a glb that imports one)
       plus two controls, a rigged pack glb and an unrigged one of our own.
       Dropping it stays right; the reason stated here was wrong, and a lane
       acting on it would have gone looking for a sphere in the game.
       See docs/art/MONSTER_VARIANTS.md.
    2. The rest pose is NOT the posed body. The `Idle` action has to be
       assigned WITH ITS SLOT (Blender 4.4+ slotted actions: setting
       `animation_data.action` alone leaves the body in rest) and the scene
       stepped onto a frame before anything is measured.

    And the number this returns is the point of the whole file: gear.gd's
    measured "body top y 1.30" is the TORSO mesh. These are chibi bodies - the
    head runs from 1.2 to 2.3 on its own - so a hero stands 2.45 m, not 1.30.
    """
    path = os.path.join(repo, HERO_GLB)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in before]
    rig = next((o for o in new_objs if o.type == 'ARMATURE'), None)
    act = bpy.data.actions.get("Idle")
    posed = False
    if rig is not None and act is not None:
        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = act
        try:
            rig.animation_data.action_slot = act.slots[0]
            posed = True
        except Exception:
            posed = False
        bpy.context.scene.frame_set(3)
    # the character only: no parked weapons, no shields, no hidden sphere
    meshes = [o for o in new_objs if o.type == 'MESH' and o.name.startswith("Knight")]
    drop = [o for o in new_objs if o.type == 'MESH' and o not in meshes]
    for o in drop:
        bpy.data.objects.remove(o, do_unlink=True)
    new_objs = [o for o in new_objs if o not in drop]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    for o in new_objs:
        if o.parent is None:
            o.location = (o.location.x, o.location.y, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    return new_objs, meshes, dict(h=round(mx.z - mn.z, 3), w=round(mx.x - mn.x, 3),
                                  d=round(mx.y - mn.y, 3), posed=posed,
                                  parts=[o.name for o in meshes])


def place(roots, dx, dy=0.0):
    """THE SIDE VIEW WAS ONE BODY HIDING ANOTHER. The hero used to be offset
    along X only, so at azimuth 90 the camera looked straight down the line of
    the pair and the hero stood in front of the creature - a fit shot in which
    you can see neither of them. Offsetting in Y as well separates them on
    screen in BOTH views: X apart for front and back, Y apart for the side,
    and the two never overlap because they are apart on the other axis each
    time."""
    for o in roots:
        if o.parent is None:
            o.location = (o.location.x + dx, o.location.y + dy, o.location.z)
    bpy.context.view_layer.update()


# =====================================================================
# EVEN LIGHT - THE BACK VIEW HAS NEVER BEEN LIT, AND I MEASURED IT RATHER
# THAN NOTICED IT.
# =====================================================================
# 20 Nov 16:4x CT. `lordgen.add_lights` puts the whole rig in WORLD space and
# never moves it: key SUN from (0.9, -1.0, 0.85) and fill AREA from
# (-1.0, -0.6, 0.35) both sit on -Y, the FRONT, and the only lamp on +Y is the
# rim - whose colour is the creature's own `aura`. The camera orbits; the rig
# does not. So in the back view (az 180) the subjects are lit by ONE COLOURED
# LAMP and nothing else.
#
# THE PROOF IS THE HERO, NOT THE CREATURE, BECAUSE THE HERO IS THE SAME OBJECT
# IN ALL 41 CELLS. Mean RGB of the identical KayKit Knight, measured off the
# shipped renders:
#     beadle  front 108/105/108  ->  back 121/ 76/ 56   (aura 1.00,0.74,0.26)
#     leech   front 109/105/109  ->  back 120/ 53/ 48   (aura 1.00,0.22,0.14)
#     dyer    front 108/105/110  ->  back  75/ 67/ 90   (aura 0.26,0.46,1.00)
# One body, one material, three back views - amber, red and blue, and the hue
# is the CREATURE'S AURA every time. Not one back render in this file shows a
# true value. Every judgement this house has made off a back view - mine, and
# the team lead's "the Beadle reads the same from front and back" - was made
# through a single coloured lamp.
#
# THIS IS TRAP 5 AGAIN: an instrument that cannot SEE is not a pass. The fix
# is to carry the key and fill round with the camera so every view is lit the
# same way relative to the viewer, which is the question a contact sheet is
# asked. The rim travels too, so it stays a rim and does not become a key.
#
# DEFAULT OFF ON PURPOSE. Turning it on changes every pixel of every hero view
# in the tree; that is a 41-body re-render and a separate decision, not
# something to slip in under a Beadle fix. `--evenlight` / MBFIT_EVENLIGHT=1.
EVENLIGHT = os.environ.get("MBFIT_EVENLIGHT", "0") != "0"

_LIGHT_SPECS = (("key",  (0.9, -1.0, 0.85), 'SUN',  2.3, None),
                ("fill", (-1.0, -0.6, 0.35), 'AREA', 1.0, (0.72, 0.80, 1.0)),
                ("rim",  (0.1, 1.0, 0.55), 'AREA', 1.0, "aura"))


def even_lights(center, radius, aura):
    """The same three lamps lordgen makes, but kept as objects so the view
    loop can carry them round with the camera. Returns [(obj, base_dir)]."""
    made = []
    for name, d, kind, e, col in _LIGHT_SPECS:
        li = bpy.data.lights.new("even_" + name, type=kind)
        li.color = aura if col == "aura" else (col or (1.0, 0.97, 0.92))
        if kind == 'SUN':
            li.energy = e
        else:
            li.energy = 1400.0 * (radius / 3.0) ** 2 * (0.85 if name == "rim" else 0.75)
            li.size = radius * 2.2
        ob = bpy.data.objects.new("even_" + name, li)
        bpy.context.collection.objects.link(ob)
        made.append((ob, Vector(d).normalized()))
    return made


def aim_lights(lights, center, radius, az_deg):
    """Spin the rig about Z by the camera's azimuth. At az 0 this reproduces
    lordgen's world-fixed placement EXACTLY, which is what makes the front
    view the control in an A/B: only the back and side can move."""
    a = math.radians(az_deg)
    ca, sa = math.cos(a), math.sin(a)
    for ob, d in lights:
        dv = Vector((d.x * ca - d.y * sa, d.x * sa + d.y * ca, d.z)).normalized()
        ob.location = center + dv * (radius * 4.0)
        ob.rotation_euler = dv.to_track_quat('Z', 'Y').to_euler()


# =====================================================================
# GROUND CONTACT - THE RIG FIX, AND THE MECHANISM I HAD TO MEASURE FIRST
# =====================================================================
# 20 Nov 22:4x CT, instalment 5. THREE INSTALMENTS HAVE NAMED THIS AND NONE
# FIXED IT, because it is not a per-body fault: `shoot` renders with
# `film_transparent = True` and NO FLOOR IN THE SCENE AT ALL, so every subject
# in every cell - 44 bodies, 132 views - stands on nothing. The sluicekeeper,
# the tanner, the greener's feet and frame legs, the dyer's four frame feet and
# its vat: all the same one fault, counted five times.
#
# THE OBVIOUS FIX IS DEAD AND I KILLED IT WITH A RENDER, NOT A RELEASE NOTE.
# `tools/art/_el_ground_probe.py` builds a cube on a plane three ways and reads
# the alpha. Blender 5.2.3 LTS, BLENDER_EEVEE: `Object.is_shadow_catcher`
# EXISTS as an attribute (hasattr is True, so a `hasattr` guard would have
# passed and shipped) and EEVEE DOES NOT HONOUR IT - the catcher render and the
# plain opaque-plane render came back IDENTICAL, 31,488 opaque px / 768 partial
# / mean alpha 0.48500305 on both, against 2,000 opaque with no floor at all.
# A shadow catcher here would have turned the cut-out into a white slab.
#
# SO THE SHADOW IS MEASURED, NOT CAUGHT. Per view, two extra renders of a white
# plane at the ground line: once WITH the subjects, once with the subjects
# hidden. The ratio of the two is the shadow and nothing else - it divides out
# the lamp gradient, the aura colour and the world background, so it works
# under the even-light rig and under the old world-fixed one without knowing
# which is on. The shadow is then composited into the transparent film as dark
# semi-opaque pixels ONLY where the beauty render is empty, so the cut-out
# survives and no subject pixel is touched.
#
# WHAT THIS INSTRUMENT CANNOT SEE, SAID BEFORE IT IS TRUSTED:
#   - It was blind in the antialiased rim where the beauty alpha is partial and
#     the plane render is contaminated by the subject. I PREDICTED THAT RIM
#     BEFORE RENDERING AND THEN WENT AND LOOKED AT IT AT FULL RESOLUTION
#     (`_el_gc_crop.py`, greener front): it is real, it is 1-2 px, and it reads
#     as the boots being pasted onto the shadow rather than standing in it.
#     A caveat nobody checks is an excuse, so it is now CLOSED, not caveated:
#     `dilate_into_rim` carries the shadow one step outward into exactly those
#     partial-alpha pixels and nowhere else. It can only ADD shadow under a
#     silhouette edge; it cannot reach a pixel whose beauty alpha is 1, and it
#     cannot reach open background, where s is already measured.
#   - A shadow can run off the bottom of the frame. That is NOT the clip the
#     border check exists to catch (a floor continues; a severed foot does
#     not), so it is counted SEPARATELY as `shadow_edge` and never fails the
#     view. The edge and visibility rows are computed off the BEAUTY render,
#     before compositing, so neither number moves when this flag is on.
#   - RED ON EMPTY: if the unoccluded plane render has no opaque pixels the
#     view is recorded as an error, not as a clean zero shadow.
#
# *** PASS 2, AND BOTH CHANGES CAME OUT OF THE FIRST A/B RATHER THAN OUT OF MY
# *** HEAD. The first build of this ran on greener and dyer and was GREEN, zero
# *** subject pixels touched, 5-12k new alpha per view - and it was WRONG TWICE.
#   (1) THE SHADOW WAS INVISIBLE. Peak occlusion across all six views was
#       0.2262 / 0.2051 / 0.2346 / 0.2409 / 0.2198 / 0.2345 and the MEAN was
#       0.044-0.080, so after grading the darkest pixel reached alpha 0.12 of
#       255. The cause is not a bug: the display rig's fill and rim are AREA
#       lamps `radius * 2.2` across - metres wide on these bodies - and a lamp
#       that size casts a smear, not a contact. Measuring the shadow off the
#       lamps that light the PICTURE cannot produce one you can see.
#       THE FIX: the floor pass gets its own lamp. Every light in the scene is
#       hidden and a single overhead SUN is switched on for those two renders
#       only. The ratio is then pure occlusion of that one lamp - no lamp
#       gradient to divide out, no aura colour, nothing to grade. Straight down
#       on purpose: a contact shadow directly under the body reads as standing
#       from all three azimuths, and nothing in it changes when the camera
#       orbits. THE DISPLAY RENDER IS NOT TOUCHED BY THIS LAMP - it is off
#       again before the beauty film is written, and the beauty film was
#       already written before the floor pass begins.
#   (2) I ZEROED THE COLOUR OF EVERY TRANSPARENT PIXEL. The `over` divided by
#       alpha everywhere, so a pixel with alpha 0 and no shadow came out
#       RGB 0,0,0 instead of keeping Blender's background colour. Invisible
#       composited over anything alpha-aware - and that is exactly why it is
#       worth saying: my own diff instrument reported 49,825-62,773 moved
#       pixels against 5,353-10,458 of new alpha, and the gap was ALL of it.
#       A number that large with nothing visible behind it is the shape of a
#       fault, and chasing it is what found this. Now the blend touches only
#       pixels the shadow actually reaches.
#
# DEFAULT OFF, like --evenlight: turning it on changes every pixel of every
# cell. `--ground` / MBFIT_GROUND=1.
GROUND = os.environ.get("MBFIT_GROUND", "0") != "0"
GROUND_MAX_A = 0.50          # darkest the contact shadow may ever get
GROUND_RGB = (0.07, 0.07, 0.085)
GROUND_GAMMA = 1.0           # occlusion of a single lamp needs no grading
GROUND_SUN_E = 3.0
GROUND_SUN_ANGLE = 0.10      # radians; softens the rim of the contact
GROUND_STATS = {}            # view -> row; a dict, not a return value, because
                             # creaturefit.py still unpacks shoot() as a pair.


def ground_plane(center, radius):
    """A white lambertian floor at world z = 0 - the same z the camera's aim
    point calls the ground line. Returned hidden; `shoot` shows it only for the
    two measuring renders."""
    me = bpy.data.meshes.new("gc_floor")
    half = radius * 6.0
    cx, cy = center.x, center.y
    me.from_pydata([(cx - half, cy - half, 0.0), (cx + half, cy - half, 0.0),
                    (cx + half, cy + half, 0.0), (cx - half, cy + half, 0.0)],
                   [], [(0, 1, 2, 3)])
    me.update()
    mat = bpy.data.materials.new("gc_floor_mat")
    mat.use_nodes = True
    bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (1.0, 1.0, 1.0, 1.0)
        for k, v in (('Roughness', 1.0), ('Metallic', 0.0), ('Specular IOR Level', 0.0)):
            if k in bsdf.inputs:
                bsdf.inputs[k].default_value = v
    me.materials.append(mat)
    ob = bpy.data.objects.new("gc_floor", me)
    bpy.context.collection.objects.link(ob)
    ob.hide_render = True
    return ob, half


def shadow_sun(center, radius):
    """The lamp the contact shadow is measured by, and the ONLY lamp alight
    during the two floor renders. Straight down, so the shadow is a contact
    and not a projection, and view-independent by construction."""
    li = bpy.data.lights.new("gc_sun", type='SUN')
    li.energy = GROUND_SUN_E
    li.color = (1.0, 1.0, 1.0)
    try:
        li.angle = GROUND_SUN_ANGLE
    except Exception:
        pass
    ob = bpy.data.objects.new("gc_sun", li)
    bpy.context.collection.objects.link(ob)
    ob.location = center + Vector((0.0, 0.0, radius * 6.0))
    ob.rotation_euler = (0.0, 0.0, 0.0)      # SUN points down -Z at identity
    ob.hide_render = True
    return ob


def _luma(a):
    return a[:, :, 0] * 0.2126 + a[:, :, 1] * 0.7152 + a[:, :, 2] * 0.0722


def shadow_from_pair(with_subj, without_subj, beauty):
    """1 - (lit with subjects / lit without them), on the plane only, and only
    where the beauty film is empty. Returns (shadow, row) or (None, row) when
    the control render is empty - which is an error, never a zero."""
    row = {"plane_px": 0, "shadow_px": 0, "mean": 0.0, "max": 0.0, "error": None}
    ctrl = without_subj[:, :, 3] > 0.98
    row["plane_px"] = int(ctrl.sum())
    if row["plane_px"] == 0:
        row["error"] = "control plane render is empty - no floor to measure"
        return None, row
    free = beauty[:, :, 3] <= 0.02
    valid = ctrl & free
    s = np.zeros(beauty.shape[:2], dtype=np.float32)
    lw, lo = _luma(with_subj), _luma(without_subj)
    den = np.maximum(lo, 1e-4)
    s[valid] = np.clip(1.0 - (lw[valid] / den[valid]), 0.0, 1.0)
    if GROUND_GAMMA != 1.0:
        s = s ** GROUND_GAMMA
    lit = s > 0.02
    row["shadow_px"] = int(lit.sum())
    row["mean"] = round(float(s[lit].mean()), 4) if row["shadow_px"] else 0.0
    row["max"] = round(float(s.max()), 4)
    return s, row


def dilate_into_rim(s, beauty, steps=2):
    """Fill the antialiased silhouette rim, where the floor pass is
    contaminated by the subject and s could only ever read 0. Max of the eight
    neighbours, applied ONLY where s is zero and the beauty alpha is partial."""
    a = beauty[:, :, 3]
    rim = (s <= 1e-6) & (a > 0.02) & (a < 0.999)
    if not rim.any():
        return s, 0
    out = s.copy()
    filled = 0
    for _ in range(steps):
        d = out.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                d = np.maximum(d, np.roll(np.roll(out, dy, 0), dx, 1))
        take = rim & (out <= 1e-6) & (d > 1e-6)
        filled += int(take.sum())
        out[take] = d[take]
    return out, filled


def composite_shadow(beauty, s):
    """Straight-alpha `over`: the shadow goes UNDER the beauty film."""
    out = beauty.copy()
    sa = (s * GROUND_MAX_A) * (1.0 - beauty[:, :, 3])
    hit = sa > 1e-4            # *** everything else is left byte-identical ***
    if not hit.any():
        return out
    oa = np.clip(beauty[:, :, 3] + sa, 0.0, 1.0)
    den = np.maximum(oa, 1e-6)
    for i in range(3):
        blended = (beauty[:, :, i] * beauty[:, :, 3] + GROUND_RGB[i] * sa) / den
        out[:, :, i] = np.where(hit, blended, beauty[:, :, i])
    out[:, :, 3] = np.where(hit, oa, beauty[:, :, 3])
    return out


def _shot(path, hide=()):
    """One render with `hide` taken out of it, restored afterwards."""
    for o in hide:
        o.hide_render = True
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hide:
        o.hide_render = False
    return G.read_png(path)


def shoot(objs, pts, outdir, views, aura, creature=(), hero_meshes=(), tmpdir=None):
    """Fixed scale, fixed ground line. Only the horizontal centre moves.

    Also answers, per view, whether each of the two subjects can actually be
    SEEN - see the OCCLUSION TEST note at the top of this file."""
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0

    mn, mx, _ = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    lcent = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rig = even_lights(lcent, radius, aura) if EVENLIGHT else None
    if rig is None:
        G.add_lights(lcent, radius, aura)
    floor, floor_half = ground_plane(lcent, radius) if GROUND else (None, 0.0)
    gsun = shadow_sun(lcent, radius) if GROUND else None
    GROUND_STATS.clear()

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = FRAME_W          # landscape: ortho_scale is the long side
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    written = []
    vis = {}
    edge = {}
    creature = list(creature)
    hero_meshes = list(hero_meshes)
    for vname, az in views:
        if rig is not None:
            aim_lights(rig, lcent, radius, az)
        a, e = math.radians(az), math.radians(6.0)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        # the aim point: horizontally centred on the pair, vertically fixed so
        # the ground sits GROUND_UP above the bottom edge in every single cell
        cx = (mn.x + mx.x) / 2.0 if az < 45.0 else (mn.x + mx.x) / 2.0
        cy = (mn.y + mx.y) / 2.0
        # *** THE "ONE FIXED GROUND LINE" IS ONLY TRUE AT THE AIM POINT'S DEPTH,
        # *** AND IN THE SIDE VIEW THAT IS NOT WHERE THE SUBJECTS ARE. ***
        # Found 18 Nov 18:5x by measuring the renders instead of reading the
        # register: in hero_side.png the hero's lowest row and the creature's
        # differ by 40-58 px on every body I checked, INCLUDING the two ticked
        # this afternoon, and on three of them the creature reached the last
        # row of the image - content at the frame edge, which is a clip nobody
        # could see because this file's checks on the hero views are BLANK
        # ONLY. The cause is geometry, not art: the camera is elevated 6 deg,
        # so an offset in DEPTH becomes an offset in IMAGE HEIGHT. In front and
        # back views the pair separates along X (no effect); in the side view
        # it separates along Y, the camera's depth axis, and the near subject's
        # ground contact drops sin(6 deg) * half-the-depth-span - about 0.26 m
        # on a 5 m pair, which is the whole 0.25 m bottom margin.
        # Lift the aim point by exactly that, so the NEAREST subject's floor
        # still clears the bottom edge. Zero effect where depth span is small.
        # SIGN, MEASURED NOT REASONED: my first attempt ADDED this and the new
        # border check immediately went red on three MORE views - raising the
        # aim point raises what the frame covers, which pushes the subjects
        # DOWN the image. The camera has to look LOWER to lift them clear.
        drop = math.sin(e) * (mx.y - mn.y) / 2.0
        target = Vector((cx, cy, FRAME_H / 2.0 - GROUND_UP - drop))
        dist = radius * 4.0 + 4.0
        cam.location = target + dirv * dist
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
        depth = [(p - cam.location).dot(fwd) for p in pts]
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 8.0 + floor_half * 1.5
        path = os.path.join(outdir, "hero_%s.png" % vname)
        B = _shot(path, hide=creature if PROVE_RED else ())
        written.append(path)
        # *** BORDER CHECK ON THE HERO VIEWS - THEY NEVER HAD ONE. ***
        # minibossgen asserts border alpha; THIS file only ever asked whether
        # the hero views were blank. A clipped render is not a blank one, so a
        # creature with its feet cut off by the frame returned GREEN with
        # `fits_frame: true` beside it - and fits_frame is computed from pair
        # WIDTH, so it was never answering this question at all. Counted here,
        # per edge, and a non-zero count is RED in the register.
        ea = B[:, :, 3] > DIFF_EPS
        edge[vname] = dict(top=int(ea[0].sum()), bottom=int(ea[-1].sum()),
                           left=int(ea[:, 0].sum()), right=int(ea[:, -1].sum()))
        # *** GROUND CONTACT. The edge row above is already taken, off the
        # beauty film, so turning this on cannot move a border count or a
        # visibility score - only the pixels a viewer sees. ***
        if floor is not None:
            td = tmpdir or outdir
            # every display lamp off, the measuring sun on - see (1) in the
            # GROUND CONTACT note. Their previous states are restored exactly.
            lamps = [o for o in scene.objects if o.type == 'LIGHT' and o is not gsun]
            was = [o.hide_render for o in lamps]
            for o in lamps:
                o.hide_render = True
            gsun.hide_render = False
            floor.hide_render = False
            W = _shot(os.path.join(td, "_gcwith_%s.png" % vname))
            O = _shot(os.path.join(td, "_gcfree_%s.png" % vname), hide=objs)
            floor.hide_render = True
            gsun.hide_render = True
            for o, h in zip(lamps, was):
                o.hide_render = h
            sh, grow = shadow_from_pair(W, O, B)
            if sh is None:
                GROUND_STATS[vname] = grow
            else:
                sh, grow["rim_filled_px"] = dilate_into_rim(sh, B)
                B = composite_shadow(B, sh)
                G.write_png(path, B)
                sa = B[:, :, 3] > DIFF_EPS
                grow["shadow_edge"] = dict(top=int(sa[0].sum()) - edge[vname]["top"],
                                           bottom=int(sa[-1].sum()) - edge[vname]["bottom"],
                                           left=int(sa[:, 0].sum()) - edge[vname]["left"],
                                           right=int(sa[:, -1].sum()) - edge[vname]["right"])
                GROUND_STATS[vname] = grow
        if creature and hero_meshes and tmpdir:
            A = _shot(os.path.join(tmpdir, "_heroalone_%s.png" % vname), hide=creature)
            C = _shot(os.path.join(tmpdir, "_crealone_%s.png" % vname), hide=hero_meshes)
            cell = {}
            for who, X, Y in (("creature", A, C), ("hero", C, A)):
                # X is the frame WITHOUT this subject; Y is this subject ALONE.
                changed = np.abs(B - X).max(axis=2) > DIFF_EPS
                mask = Y[:, :, 3] > DIFF_EPS
                alone = int(mask.sum())
                covered = int((changed & mask).sum())
                cell[who] = dict(alone=alone, vis=covered,
                                 delta=int(changed.sum()),
                                 seen=round(covered / float(alone), 4) if alone else 0.0)
            cell["proves"] = bool(
                cell["creature"]["seen"] >= SEEN_MIN and cell["creature"]["vis"] >= VIS_MIN
                and cell["hero"]["seen"] >= SEEN_MIN and cell["hero"]["vis"] >= VIS_MIN)
            vis[vname] = cell
    return written, eng, vis, edge


def sheet(repo, keys, hero, name="_hero_scale", cols=3, tag=""):
    """Fourteen cells, one scale, one ground line, and the hero's head height
    drawn straight across every cell as a dashed rule - so the comparison is in
    the picture and not in a table.

    `tag` MUST BE THE SAME TAG THE VIEWS WERE WRITTEN UNDER. FOUND 20 NOV
    ~17:47 CT ON THE FERRYMAN, THE FIRST BODY EVER RENDERED WITH --evenlight:
    this function read `root/<key>/hero_front.png` with the tag dropped on the
    floor, so `--name ferryman_even --tag _even` wrote a sheet called
    `ferryman_even.png` out of the WORLD-FIXED directory. The two sheets came
    out BYTE-IDENTICAL (md5 cf123ec2...) and that is how it was caught - not by
    a verdict, because no verdict reads the sheet. A picture filed under the
    name of a lighting rig it was not lit by is the same fault family as
    `seen: 1.0` on a body with no face: the label says the instrument looked
    and it did not. Default "" so every existing call and all 41 shipped
    sheets are byte-for-byte unchanged."""
    root = os.path.join(repo, "renders", "art", "minibosses")
    lab = 40
    rows = (len(keys) + cols - 1) // cols
    cw, ch = CELL_X, CELL_Y
    sh = np.zeros((rows * (ch + lab), cols * cw, 4), dtype=np.float32)
    sh[..., 0:3] = np.array((0.055, 0.060, 0.075))
    sh[..., 3] = 1.0
    bad, checked = [], []
    # pixel row of the ground and of the hero's head, inside a cell
    px_per_m = ch / FRAME_H
    ground_row = ch - int(GROUND_UP * px_per_m)
    head_row = ground_row - int(hero["h"] * px_per_m)
    for i, key in enumerate(keys):
        p = os.path.join(root, key + tag, "hero_front.png")
        cx, cy = (i % cols) * cw, (i // cols) * (ch + lab)
        if os.path.isfile(p):
            a = G.read_png(p)
            n = int((a[..., 3] > 0.02).sum())
            checked.append((os.path.relpath(p, repo), n))
            if n < 400:
                bad.append((p, "blank or near-blank: %d opaque px" % n))
            al = a[..., 3:4]
            dst = sh[cy:cy + ch, cx:cx + cw, 0:3]
            sh[cy:cy + ch, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
        else:
            bad.append((p, "missing"))
        # 17 Nov: THE BLANK CHECK ONLY EVER LOOKED AT hero_front. Each key
        # writes THREE views and two of them went into the register unchecked -
        # an instrument that can return a GREEN verdict over renders it never
        # opened. Same fault class as a gate that cannot go red. The other two
        # are now opened and counted here, and a missing one fails the run.
        # AND THE SAME 17:47 TAG FAULT WAS HERE TOO, AND IT IS WORSE HERE:
        # this loop RETURNS `bad`, which the caller turns into a RED. On a
        # tagged run it opened the UNTAGGED side and back, so a tagged pass
        # could have shipped three blank renders while this check went green
        # over three different files that were fine. An instrument pointed at
        # the wrong file is not a weaker instrument, it is no instrument.
        for extra in ("hero_side.png", "hero_back.png"):
            q = os.path.join(root, key + tag, extra)
            if os.path.isfile(q):
                b = G.read_png(q)
                m = int((b[..., 3] > 0.02).sum())
                checked.append((os.path.relpath(q, repo), m))
                if m < 400:
                    bad.append((q, "blank or near-blank: %d opaque px" % m))
            else:
                bad.append((q, "missing"))
        # the two rules: ground, and the hero's head carried across the cell
        sh[cy + ground_row:cy + ground_row + 1, cx:cx + cw, 0:3] = np.array((0.30, 0.32, 0.36))
        for x in range(cx + 4, cx + cw - 4, 14):
            sh[cy + head_row:cy + head_row + 1, x:x + 8, 0:3] = np.array((1.00, 0.86, 0.52))
        t, h = M.CANON[key][0], M.CANON[key][1]
        ratio = h / hero["h"] if hero["h"] > 0.01 else 0.0
        sh[cy + ch:cy + ch + 2, cx:cx + cw, 0:3] = np.array((0.85, 0.80, 0.68)) * 0.35
        G.draw_text(sh, "%s  %.2fM" % (t.upper(), h), cx + 8, cy + ch + 6, 2,
                    (0.85, 0.80, 0.68))
        G.draw_text(sh, "%.2fx THE HERO (%.2fM) - %s THEME"
                    % (ratio, hero["h"], M.CANON[key][4].upper()),
                    cx + 8, cy + ch + 25, 1, (0.46, 0.52, 0.60))
    G.draw_text(sh, "DASHED RULE = THE TOP OF A VIEWERS HERO, %.2f M, KayKit Knight.glb AT SCALE 1.0 "
                    "(townsfolk.gd size_k=1.0). ONE ORTHO SCALE AND ONE GROUND LINE IN ALL CELLS."
                % hero["h"], 10, 10, 1, (1.00, 0.86, 0.52))
    G.write_png(os.path.join(root, "%s.png" % name), sh)
    return bad, checked


def audit_rows(rep, asked):
    """THE TOP-LEVEL VERDICT, DERIVED FROM EVERY ROW IN THE FILE.

    *** THE DEFECT THIS CLOSES - FOUND BY THE TEAM LEAD 20 NOV 2026 22:58 CT
    *** IN WORK THIS LANE SHIPPED, AND REPRODUCED HERE BEFORE IT WAS TOUCHED. ***
    `_fit_report.json` read `ok: true`, `verdict: "GREEN"`, `errors: []`,
    `blind_views: []` AT THE SAME MOMENT its own `pairs.ratcatcher.frame_edge`
    carried `front left 15, right 3`. Both were written by the same program.

    THE MECHANISM, exactly: main() starts a FRESH `rep` with ok True and empty
    error lists, then carries forward ONLY `pairs` and `hero` from the file on
    disk. The verdict was then drawn inside the render loop, which visits only
    the keys named by `--only`. So a one-key run inherits forty-five other
    cells' DATA and none of their VERDICTS, and republishes a clean sheet over
    them. `--only winder` erased a red raised by a ratcatcher run hours
    earlier while leaving the evidence for it sitting in the file.

    This is the lying-instrument class and it is the worst kind: it does not
    fail to see the fault, it SEES the fault, writes it down, and then prints
    GREEN next to it.

    THE FIX IS NOT A BIGGER LOOP. Re-rendering every key on every run would
    cost an hour to answer a question the stored rows already answer. Instead
    the verdict is RE-DERIVED FROM THE ROWS THEMSELVES, every row, every run -
    so a carried cell is judged by exactly the same test as a fresh one, and a
    red can only leave this file when the render that fixes it lands.

    Rows judged from stored data are marked `[carried]` so no reader mistakes
    a re-derivation for a re-measurement. `asked` is recorded, not used as a
    filter: scope is what the run RENDERED, never what it VOUCHES FOR.
    """
    asked = set(asked or ())
    for key in sorted(rep.get("pairs", {})):
        row = rep["pairs"][key] or {}
        mark = "" if key in asked else "[carried] "
        vis = row.get("visibility") or {}
        if not vis:
            rep["errors"].append(
                "%s%s: no occlusion measurement on record - an unmeasured "
                "cell is RED, not green" % (mark, key))
            rep["ok"] = False
        else:
            for vname in sorted(vis):
                c = vis[vname] or {}
                for who in ("creature", "hero"):
                    if (c.get(who) or {}).get("alone", 0) == 0:
                        rep["errors"].append(
                            "%s%s/%s: the %s renders EMPTY alone - its seen "
                            "fraction would be computed over nothing"
                            % (mark, key, vname, who))
                        rep["ok"] = False
            pv = row.get("proving_views")
            if pv is None:
                pv = sum(1 for c in vis.values() if (c or {}).get("proves"))
            if pv < MIN_PROVING:
                rep["blind_views"].append(
                    "%s%s: only %d of %d views show BOTH subjects "
                    "(seen>=%.2f AND vis>=%d px each)"
                    % (mark, key, pv, len(vis), SEEN_MIN, VIS_MIN))
                rep["ok"] = False
        # a view whose content reaches an edge is CUT, and a cut render
        # cannot prove a foot plane, a silhouette or anything else about
        # where the body ends. RED, named edge by edge.
        for vname, e in sorted((row.get("frame_edge") or {}).items()):
            hit = {k2: v2 for k2, v2 in (e or {}).items() if v2 > 0}
            if hit:
                rep["errors"].append(
                    "%s%s/%s: render reaches the frame edge - %s. The body is "
                    "CUT and this view proves nothing about where it ends."
                    % (mark, key, vname,
                       ", ".join("%s %d px" % kv for kv in sorted(hit.items()))))
                rep["ok"] = False
        if "fits_frame" in row and not row["fits_frame"]:
            rep["errors"].append(
                "%s%s: pair %.2f m does not fit the fixed frame with its "
                "margin (%.2f m of %.2f m usable)"
                % (mark, key, row.get("pair_w", -1.0),
                   row.get("pair_w", -1.0), FRAME_W - MARGIN_X))
            rep["ok"] = False
        # A ROW WRITTEN BEFORE THE MARGIN EXISTED CANNOT ANSWER FOR IT.
        # `fits_frame: true` on an old row means "<= 5.60", not "<= 5.48",
        # so it is not evidence either way and says so rather than passing.
        if "air_x" not in row:
            rep["stale_margin"].append(key)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--sheet", action="store_true")
    ap.add_argument("--name", default="_hero_scale")
    ap.add_argument("--cols", type=int, default=3)
    ap.add_argument("--frame", type=float, default=0.0)
    # THE RED PATH. Stands the hero ON the creature instead of beside it, so
    # each hides the other. A gate that has never been seen to fail is not
    # known to be able to. This flag must never be used for a shipped register.
    ap.add_argument("--prove-red", action="store_true")
    # A/B ONLY. --evenlight carries the key/fill/rim round with the camera (see
    # the EVEN LIGHT note above); --tag writes into <key><tag>/ so an A/B can
    # never overwrite a shipped render.
    ap.add_argument("--evenlight", action="store_true")
    # THE RIG FIX. See the GROUND CONTACT note above. Off by default.
    ap.add_argument("--ground", action="store_true")
    ap.add_argument("--tag", default="")
    args = ap.parse_args(argv)
    if args.evenlight:
        globals()["EVENLIGHT"] = True
    if args.ground:
        globals()["GROUND"] = True
    if args.prove_red:
        globals()["PROVE_RED"] = True
    if args.frame > 0.1:
        globals()["FRAME_W"] = args.frame
        globals()["FRAME_H"] = args.frame * CELL_Y / float(CELL_X)
    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_fit_report.json" if args.name == "_hero_scale" else "_fit_%s.json" % args.name.strip("_"))
    rep = {"ok": True, "hero": {}, "pairs": {}, "errors": [], "blind_views": [],
           "stale_margin": [],
           "seen_min": SEEN_MIN, "vis_min": VIS_MIN, "min_proving": MIN_PROVING,
           "frame_w": FRAME_W, "margin_x": MARGIN_X}
    if os.path.isfile(out):
        try:
            with open(out) as f:
                old = json.load(f)
            rep["pairs"] = dict(old.get("pairs", {}))
            rep["hero"] = dict(old.get("hero", {}))
        except Exception:
            pass

    keys = [k for k in args.only.split(",") if k] if args.only else list(M.ORDER)
    if not args.sheet:
        for key in keys:
            G.purge()
            try:
                objs, info = MG.build_miniboss(key)
                hroots, hmesh, hero = import_hero(args.repo)
                rep["hero"] = hero
                mn, mx, _ = G.world_bounds(objs)
                # hero to the creature's left, clear of its footprint.
                # THE HORIZONTAL OFFSET IS SOLVED, NOT FIXED - see MARGIN_X.
                # Moving the hero right by d narrows the pair by exactly d so
                # long as the hero stays the leftmost thing in it, which it
                # does at every gap down to GAP_MIN; the loop re-measures
                # instead of trusting that, and stops the moment it fits.
                # *** place() IS RELATIVE, NOT ABSOLUTE - READ ITS BODY. ***
                # My first version of this loop called it with an absolute
                # target on every attempt and the offsets COMPOUNDED: four
                # passes walked the hero clean out of the frame, pair_w 10.80
                # on ratcatcher and 11.03 on boiler, both cells RED with "the
                # hero renders EMPTY alone" in every view. The new row audit
                # caught it on the first run, which is the only reason this
                # note is here and not a shipped regression. After the first
                # placement the hero is moved by the DIFFERENCE only, and
                # since the offset is (C - gap) that difference is exactly
                # (old gap - new gap).
                gap_x = GAP
                place(hroots, mn.x - gap_x - hero["w"] / 2.0 - 0.10,
                      mn.y - GAP - hero["d"] / 2.0 - 0.10)
                allo = objs + hmesh
                for _attempt in range(3):
                    bpy.context.view_layer.update()
                    amn, amx, pts = G.world_bounds(allo)
                    over = (amx.x - amn.x) - (FRAME_W - MARGIN_X)
                    if over <= 1e-6 or gap_x <= GAP_MIN + 1e-6:
                        break
                    new_gap = max(GAP_MIN, gap_x - over - 0.01)
                    place(hroots, gap_x - new_gap, 0.0)
                    gap_x = new_gap
                outdir = os.path.join(args.repo, "renders", "art", "minibosses", key + args.tag)
                os.makedirs(outdir, exist_ok=True)
                tmpdir = os.path.join(args.repo, "renders", "art", "minibosses", "_vis_tmp")
                os.makedirs(tmpdir, exist_ok=True)
                written, eng, vis, edge = shoot(allo, pts, outdir,
                                          (("front", 0.0), ("side", 90.0), ("back", 180.0)),
                                          info["aura"], creature=objs, hero_meshes=hmesh,
                                          tmpdir=tmpdir)
                rep["pairs"][key] = dict(
                    creature_h=round(mx.z - mn.z, 3), hero_h=hero["h"],
                    ratio=round((mx.z - mn.z) / max(0.01, hero["h"]), 2),
                    pair_w=round(amx.x - amn.x, 2),
                    gap_x=round(gap_x, 3), margin_x=MARGIN_X,
                    air_x=round(FRAME_W - (amx.x - amn.x), 3),
                    fits_frame=bool((amx.x - amn.x) <= FRAME_W - MARGIN_X
                                    and (amx.z - amn.z) <= FRAME_H - GROUND_UP),
                    engine=eng, views=[os.path.basename(p) for p in written],
                    visibility=vis, frame_edge=edge,
                    ground=dict(GROUND_STATS) if GROUND else None,
                    proving_views=sum(1 for c in vis.values() if c["proves"]))
                # *** NO VERDICT IS DRAWN HERE ANY MORE. *** Every per-key
                # judgement now happens in audit_rows() below, over EVERY row
                # in the file rather than only the keys this run rendered.
                # See the note on that function: judging in the loop is what
                # let a `--only` run publish ok:true over a clipped body.
            except Exception:
                import traceback
                rep["ok"] = False
                rep["errors"].append("%s: %s" % (key, traceback.format_exc()[-800:]))

    # *** AN EMPTY MEASUREMENT IS RED. ***
    # _fit_snuffer_register.json shipped as ok:true with hero:{} and pairs:{}
    # and another lane's ticked item (D96) then leaned on it. It was born from
    # a --sheet-only run: that path skips the measurement loop entirely, and
    # nothing here checked that the keys being sheeted had ever been measured.
    # ok used to mean "nothing raised" - it now means "every key asked for has
    # a ratio on record". A register that measures nothing reports RED.
    # A CELL MEASURED BEFORE THIS TEST EXISTED IS NOT EVIDENCE FOR IT. An old
    # entry carries a ratio and no `visibility`, and reading the file alone
    # would make the whole set look proved by a run that only touched one key.
    # *** THE VERDICT IS DRAWN HERE, OVER EVERY ROW IN THE FILE. ***
    # This replaces an `unproved` check that looked only at the keys this run
    # asked for - the same blind spot, one rung smaller. See audit_rows().
    audit_rows(rep, keys)
    # AND THE SAME QUESTION ABOUT THE CELLS NOBODY ASKED FOR THIS RUN. The
    # file accumulates: the first full run after this test shipped found
    # snuffer_chibi and tallyman_chibi sitting in `pairs` with a ratio and no
    # visibility, because neither is in M.ORDER any more, so neither is ever
    # asked for and neither was going to be caught by the loop above. A reader
    # loading this file would have seen ok:true over two cells the occlusion
    # test has never looked at. They are NAMED here rather than silently
    # carried, and a GREEN verdict does not extend to them.
    rep["unproved_cells"] = sorted(k for k, v in rep["pairs"].items()
                                   if "visibility" not in v)
    measured = [k for k in keys if k in rep["pairs"]]
    missing = [k for k in keys if k not in rep["pairs"]]
    rep["measured"] = measured
    rep["asked"] = list(keys)
    if not rep["hero"]:
        rep["ok"] = False
        rep["errors"].append("hero: never measured. An empty hero block is RED, "
                             "not ok - every ratio is a ratio TO the hero.")
    if not rep["pairs"]:
        rep["ok"] = False
        rep["errors"].append("pairs: EMPTY. This register measured NOTHING and "
                             "must not report ok. Re-run without --sheet.")
    if missing:
        rep["ok"] = False
        rep["errors"].append("no ratio on record for: %s (asked for %d, measured %d)"
                             % (",".join(missing), len(keys), len(measured)))

    G.purge()
    try:
        hero = rep["hero"] if rep["hero"] else {"h": 1.0}
        bad, checked = sheet(args.repo, keys, hero, args.name, args.cols, args.tag)
        rep["blank_check"] = {"files": len(checked), "failures": [list(b) for b in bad]}
        if bad:
            rep["ok"] = False
    except Exception:
        import traceback
        rep["ok"] = False
        rep["errors"].append("sheet: %s" % traceback.format_exc()[-800:])

    os.makedirs(os.path.dirname(out), exist_ok=True)
    # *** SAY WHICH KIND OF RED, OR THE VERDICT BECOMES NOISE. ***
    # With every row judged, two retired cells with no occlusion measurement
    # (snuffer_chibi, tallyman_chibi - in `pairs`, not in M.ORDER, never
    # rendered again) hold the whole register RED for ever. That is literally
    # true and practically useless: a reader who learns that RED always means
    # "those two again" has learned to ignore the one number that matters.
    # So the red is CLASSIFIED and the shipped set is reported on its own
    # line. `ok` is NOT weakened - it still covers every row - and the
    # shipped verdict is published beside it, not instead of it.
    shipped = set(M.ORDER)
    red_keys = set()
    for msg in rep["errors"] + rep["blind_views"]:
        head = msg.replace("[carried] ", "").split(":")[0].split("/")[0]
        if head in rep["pairs"]:
            red_keys.add(head)
    rep["red_summary"] = {
        "rows": sorted(red_keys),
        "shipped_red": sorted(red_keys & shipped),
        "retired_red": sorted(red_keys - shipped),
        "ok_shipped": not (red_keys & shipped) and bool(rep["pairs"]) and bool(rep["hero"])}
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    # SAY WHAT THE VERDICT COVERS, IN THE FILE, so no reader has to know the
    # history above to know what `ok` is a statement about.
    rep["verdict_scope"] = ("every row in pairs (%d), re-derived from stored "
                            "measurements; %d of them rendered this run"
                            % (len(rep["pairs"]), len(measured)))
    with open(out, "w") as f:
        json.dump(rep, f, indent=1)
    print("MINIBOSSFIT_REPORT " + json.dumps({
        "verdict": "GREEN" if rep["ok"] else "RED",
        "ok": rep["ok"], "hero": rep["hero"], "errors": rep["errors"][:4],
        "blind_views": rep["blind_views"][:6],
        "proving": {k: v.get("proving_views") for k, v in rep["pairs"].items()},
        "unproved_cells": rep.get("unproved_cells", []),
        "stale_margin": rep.get("stale_margin", []),
        "rows_judged": len(rep["pairs"]), "rendered": len(measured),
        "red_summary": rep.get("red_summary", {}),
        "blank": rep.get("blank_check", {}),
        "ratios": {k: (v["ratio"], v["pair_w"], v["fits_frame"])
                   for k, v in rep["pairs"].items()}}))


if __name__ == "__main__":
    main()
