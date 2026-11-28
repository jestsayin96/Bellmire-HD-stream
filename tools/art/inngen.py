"""inngen - THE INN, TIERS 1 TO 3. EXTERIOR ONLY.

  blender -b -noaudio -P tools/art/inngen.py -- --repo <repo> [--px 1024]
                                                [--only inn_t1] [--noglb]

28 Nov 2026, ~11:4x CT. Art lane. The row (plan, TAKE THIS NEXT, ART, the
10:58 CT block): "the next town building down the ladder - the smithy, or the
inn EXTERIOR (exterior only, storage mechanic, NO interior rooms, per order 1
item 9)."

WHY THE INN AND NOT THE SMITHY - MEASURED, NOT PREFERRED
--------------------------------------------------------
`data/lore_lines.json -> town_buildings.landmarks` has SEVEN keys and
**`smithy` is not one of them**: hall, chapel, barracks, windmill, workshop,
market_hall, inn. The inn by contrast has a complete three-tier brief in TWO
places - `landmarks.inn.tiers[].see` and the whole `inn_exterior` node content
wrote for C-250 - and the team lead ticked C-250 this morning. A smithy would
have been authored against nothing; the inn has a named reader and a written
spec. That is the whole reason for the choice and it took one grep.

WHAT CONTENT ALREADY SAYS, AND IT IS THE SPEC (both nodes agree)
----------------------------------------------------------------
  t1 "The Ale House"        A low house, a painted board, a bench, a barrel by
                            the door.  (+ "smoke from the chimney")
  t2 "The Inn"              Two storeys of timber, shuttered windows, a stable
                            yard, a lantern on a hook.
  t3 "The Inn of the Bell"  Stone and beam, a carved bell over the door, lamps
                            either side, a stable and a cart-yard, smoke from
                            two chimneys.
`tier_levels` = {1: 1, 2: 5, 3: 9}. Mesh names are `town_inn_t1/t2/t3`, so
`family: "inn"` in the `/2` layout resolves by construction - the default for a
landmark is its id without `lm_`, and `words` defaults to `landmarks.inn`.

EXTERIOR ONLY, AND THE STORAGE MECHANIC IS NOT A MESH. Order 1 item 9 and
content's own `_note` both say exterior and storage, NO interior rooms. So
there is no interior here and none of the three tiers has a floor: what the
storage line buys at tier 3 ("a strongroom with a bar and a ledger") is shown
from OUTSIDE, by the building being stone below, and nothing else. I did not
invent a room to hold it.

*** WEAR IS THE SPEC, NOT A BACKGROUND PRINCIPLE (Mr. E, art rule 2). ***
Same blocker as the hall, re-confirmed this run: the MegaKit ships ONE roof
family, `Roof_*RoundTile*`, and it is the prosperous one. So tier separation
comes from, in order of what it buys at stream distance:
  1. ROOF   - authored thatch, sagging (t1) vs round tile (t2/t3).
  2. MASS   - 6x6x1 storey vs 6x8x2 vs 6x10x2 + yard.
  3. WALL   - plaster (t1), plaster both storeys (t2), uneven BRICK below and
              plaster above (t3) - content's "stone below, beam above".
  4. DRESSING - board, bench, barrel / + shutters, stable, trough, hook
              lantern / + bell, two lamps, two chimneys, paved cart-yard.

*** THE INN GROWS BACKWARD, AND THAT IS A DELIBERATE CHOICE WITH A COST. ***
All three tiers keep a 6 m street frontage (3 bays) and grow in DEPTH, 6 -> 8
-> 10 m. That is how an inn actually grows - it adds a range, a yard and a
stable behind the same front door - and it keeps the door on the centre bay at
x = 0 in every tier, which makes the pivot contract's door rule hold by
construction rather than by luck.
THE COST, SAID PLAINLY: **t2 and t3 are the SAME HEIGHT.** Content's t3 line is
"stone below, beam above" - two storeys, not three - and both wear the same
8.25 m-span tile roof, so both ridge at wall_top + 4.89. The ladder therefore
progresses t2 -> t3 by MATERIAL, LENGTH and DRESSING, not by height, exactly
like the well -> fountain. So this ladder is gated `growth="free"`, NOT
`"monotonic"`, and I say so here because declaring "free" means **the monotonic
gate is not carrying this sheet and my eye is**. See the summary for what I saw.

PIVOT CONTRACT - `data/town/README.md`, the `/2` section, read this run
-----------------------------------------------------------------------
"All tiers of one family share ONE origin: the footprint centre, on the ground,
street side facing +Z. A tier swap changes the MESH only - never pos, yaw, door
or half." So:
  - every tier is re-centred on its CORE (walls + roof, never the yard) to
    x=0, y=0 and its lowest geometry to z=0;
  - `half` is the LARGEST tier's footprint, which the game build must take from
    this run's report - it is the t3 ROOF extent, not the wall box, because a
    plot must not grow into its neighbour on upgrade and the eave is what
    overhangs;
  - the door is the largest tier's door; t1 and t2 stand BACK from it (y =
    -3.0 and -4.0 against t3's -5.0), never past it.
*** AND THE RE-CENTRE IS NOW A GATE, NOT A RECORDED NUMBER. *** `hallgen.build`
measures `core_centre_dx_dy` and `base_dz_m` and writes them into the report,
and NOTHING EVER READS THEM. A ladder whose pivot silently drifted would ship
GREEN with the drift printed in its own report. `build()` below asserts both
and appends a real error. That is the one instrument this file adds.

SIZED AGAINST THE BODY, NOT AGAINST A MAN
-----------------------------------------
The hero is the KayKit Knight, idle frame 1, and it STANDS 2.453 M to the
helmet (`Knight_Helmet` z 1.101-2.453) - extremely chibi. The pack's storey is
3.1227 m, so one storey is taller than the hero and a two-storey inn reads as
properly large beside him. Door openings are the pack's own, so a hero fits
them by the kit's construction, not by my arithmetic.

WHAT THE GATES CANNOT SEE - SAID BEFORE THE NUMBERS
---------------------------------------------------
  1. BLANK        - opaque px > 0. Cannot see a clipped subject.
  2. BORDER       - zero alpha on the 1-px frame. Cannot see a subject that is
                    merely small.
  3. SUBJECT SEEN - with/without difference through ONE camera. This is the one
                    that catches a pass over an empty frame. RED ON EMPTY.
  4. HERO SEEN    - the same difference for the body, separately, plus a height
                    floor, because against a 10 m inn an area floor would call
                    a working reference absent.
  5. SEE-THROUGH  - transparent pixels INSIDE the silhouette. Catches the open
                    gable the hall shipped once. Cannot see a hole at the
                    silhouette EDGE, which is how that one got through.
  6. PIVOT        - new here. Core centre within 1 mm of origin, base at z=0.
  7. LADDER GATE  - size floor + distinctness on the side-by-side sheet. It
                    CANNOT say the wear reads, cannot say the three read in the
                    right order, and cannot see colour separation.
  8. LABEL        - every caption box carries ink. Cannot see captions that
                    overlap; they are on separate rows BY CONSTRUCTION.
NONE OF THEM ASKS "IS THIS STILL AN INN". Only looking says that.
"""
import argparse, json, math, os, sys

import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L
import townlib as T
import hallgen as H          # the PROVEN pack layer - see the guard at its tail

STOREY, GRID = H.STOREY, H.GRID
place, wall_box, thatch, gable = H.place, H.wall_box, H.thatch, H.gable
lamp = H.lamp          # hallgen's `bench` is NOT reused - see `bench()` below

CANON = {
    "inn_t1": ("The Ale House",        1, "Thatch, a board, a bench, a barrel."),
    "inn_t2": ("The Inn",              2, "Two storeys, shutters, a stable, a lantern."),
    "inn_t3": ("The Inn of the Bell",  3, "Stone and beam, a bell, lamps, a cart-yard."),
}
ORDER = ("inn_t1", "inn_t2", "inn_t3")

# Authored-colour slots for the procedural pieces ONLY. The pack modules keep
# Quaternius' own materials; nothing here repaints them. The WEAR is in the
# colour as well as the geometry - never give a whole set one wear.
# *** THESE WERE 0.36-0.52 AND THE PROPS VANISHED INTO THE WALL. ***
# First render, measured off `inn_t1/three_quarter.png` rather than judged:
# barrel luma 0.468, bench 0.470, board 0.514 - against a plaster wall at
# 0.434. A 0.034 separation on the barrel. NOTHING WAS CLIPPED (every patch
# sat at 0.42-0.55), so this was never an exposure fault, which is what my eye
# first called it - "the props render white". They were not white; they were
# the SAME VALUE AS THE WALL, which at stream distance is worse, because a
# board that does not separate from the plaster is not a sign. The board IS
# the piece that says `inn` and not `house`, so this defeats the item.
# Albedo -> render luma ran about 1.3x in that scene, so an albedo near 0.19
# lands at luma ~0.25 and buys ~0.18 of separation from the plaster.
# WEAR STILL RIDES ON TOP: t1 is the darkest and greyest (weathered bare),
# t3 the warmest and richest (oiled timber), and the board stays a shade
# under its own frame at every tier so it reads as a PANEL.
# SECOND PASS ON THESE: the first darkening worked on value (barrel went
# from +0.034 to -0.092 against the wall) but went GREY, and grey reads cold
# and dead beside the MegaKit's warm plaster. Same values, warmer hue.
PAINT = {1: (0.185, 0.132, 0.074),    # a board painted once, long ago
         2: (0.232, 0.155, 0.070),
         3: (0.295, 0.200, 0.088)}
WOOD = {1: (0.180, 0.138, 0.094), 2: (0.228, 0.158, 0.088),
        3: (0.290, 0.202, 0.105)}
STONE = {1: (0.155, 0.150, 0.138), 2: (0.175, 0.170, 0.158),
         3: (0.205, 0.200, 0.186)}
IRON = H.IRON
BRONZE = (0.255, 0.165, 0.058)   # 0.45 rendered pale cream, not bronze
FLAME = H.FLAME
WATER = (0.18, 0.26, 0.28)


# ------------------------------------------------------- the authored pieces
# Nothing below exists in the MegaKit. Checked by listing all 176 of its glTF
# modules this run: there is NO sign, NO board, NO barrel, NO bench, NO
# lantern, NO trough and NO stable in the pack - the only props are
# `Prop_Crate`, `Prop_Chimney`, `Prop_Chimney2` and four fence pieces. So the
# inn's entire identity as an INN is authored, and the pack carries the shell.

def board(objs, x, y, z0, rz, tier, tilt=0.0):
    """THE PAINTED BOARD. The one piece that says `inn` and not `house`.

    A plank on a post at t1, hung from an iron bracket at t2/t3. `tilt` IS THE
    WEAR TERM: t1's board hangs askew because nobody has straightened it."""
    mw = L.mat_solid("board_wood_%d" % tier, WOOD[tier], 0.88, 0.0)
    mp = L.mat_solid("board_paint_%d" % tier, PAINT[tier], 0.74, 0.0)
    mi = L.mat_solid("board_iron_%d" % tier, IRON, 0.45, 0.60)
    if tier == 1:
        v, f = L.box(0.11, 0.11, 2.30)
        objs.append(L.make("board_post", L.xform(v, loc=(x, y, z0 + 1.15)), f, mw))
        v, f = L.box(0.62, 0.07, 0.07)
        objs.append(L.make("board_arm", L.xform(v, loc=(x + 0.28, y, z0 + 2.18)), f, mw))
        bx, bz = x + 0.52, z0 + 1.82
    else:
        # an iron bracket off the wall face
        v, f = L.box(0.07, 0.07, 0.07)
        for k in range(7):
            objs.append(L.make("board_bracket", L.xform(
                v, loc=(x + 0.10 * k, y - 0.08 * k, z0 + 2.60)), f, mi))
        bx, bz = x + 0.62, z0 + 2.02
    # *** THE BOARD USED TO FLOAT. *** At t1 the arm sat at z0+2.18 and the
    # board's top at 1.95 - a 0.23 m gap with NOTHING joining them, so the
    # picture read as a sheet stuck to the air rather than a sign hung off a
    # bracket. No gate can see that; only the crop could. The board is raised
    # to meet its arm and hung on two visible links.
    v, f = L.box(0.90, 0.06, 0.58)
    objs.append(L.make("board", L.xform(v, loc=(bx, y - 0.10, bz),
                                        rot=(0.0, tilt, rz)), f, mp))
    for lx in (-0.30, 0.30):
        v, f = L.box(0.05, 0.05, 0.17)
        objs.append(L.make("board_link", L.xform(
            v, loc=(bx + lx, y - 0.10, bz + 0.37), rot=(0.0, tilt, rz)), f, mi))
    v, f = L.box(0.86, 0.075, 0.05)                 # the frame top and bottom
    for dz in (0.29, -0.29):
        objs.append(L.make("board_edge", L.xform(
            v, loc=(bx, y - 0.10, bz + dz), rot=(0.0, tilt, rz)), f, mw))


def bench(objs, x, y, rz, tier):
    """A bench. A plank on two stones, because that is what it is FOR.

    This is `hallgen.bench` re-authored on the TIER palette. hallgen's own
    bench is a fixed 0.33 grey-brown, which is within 0.04 luma of the pack's
    plaster - the fault this run measured. hallgen is left untouched: the hall
    ladder is shipped and ticked, and re-toning it is not this row."""
    mw = L.mat_solid("bench_wood_%d" % tier, WOOD[tier], 0.88, 0.0)
    ms = L.mat_solid("bench_stone_%d" % tier, STONE[tier], 0.92, 0.0)
    v, f = L.box(2.00, 0.42, 0.13)
    objs.append(L.make("bench_seat", L.xform(v, loc=(x, y, 0.44), rot=(0, 0, rz)), f, mw))
    for s in (-1, 1):
        v2, f2 = L.box(0.32, 0.38, 0.42)
        dx, dy = math.cos(rz) * s * 0.70, math.sin(rz) * s * 0.70
        objs.append(L.make("bench_leg", L.xform(v2, loc=(x + dx, y + dy, 0.20)), f2, ms))


def barrel(objs, x, y, rz, tier, lean=0.0):
    """A BARREL. Staved, hooped, and at t1 it is the best thing the ale house
    owns - content's own crier line says so."""
    # *** THE BARREL FLOATED AND I MIS-DIAGNOSED IT FIRST. *** In the crop I
    # read a dark ring under the barrel as "the bottom hoop plus its shadow".
    # It was neither: `lordlib.cone` is documented "base at z=0" - it is
    # BASE-ANCHORED, not centred like `lordlib.box` - so a body placed at
    # z=0.43 hung 0.43 m in the air and its lowest hoop at 0.14 hung with it.
    # Every gate was GREEN over a floating barrel, because a float is not a
    # blank, a clip or a hole. Cones now place by their BASE.
    mw = L.mat_solid("barrel_wood_%d" % tier, WOOD[tier], 0.86, 0.0)
    mi = L.mat_solid("barrel_iron_%d" % tier, IRON, 0.48, 0.60)
    v, f = L.cone(0.30, 0.30, 0.86, 14)
    objs.append(L.make("barrel", L.xform(v, loc=(x, y, 0.0), rot=(lean, 0.0, rz)), f, mw))
    for zc in (0.13, 0.43, 0.73):                    # hoop CENTRES
        v, f = L.cone(0.315, 0.315, 0.055, 14)
        objs.append(L.make("barrel_hoop", L.xform(
            v, loc=(x, y, zc - 0.0275), rot=(lean, 0.0, rz)), f, mi))


def hook_lantern(objs, x, y, z0, flip=1.0):
    """A LANTERN ON A HOOK - content's tier-2 line, verbatim. Wall-mounted, so
    it is not the tier-3 lamp POST one notch smaller."""
    mi = L.mat_solid("hook_iron", IRON, 0.45, 0.65)
    v, f = L.box(0.055, 0.46, 0.055)
    objs.append(L.make("hook_arm", L.xform(v, loc=(x, y - flip * 0.23, z0 + 2.42)), f, mi))
    v, f = L.box(0.05, 0.05, 0.20)
    objs.append(L.make("hook_drop", L.xform(v, loc=(x, y - flip * 0.44, z0 + 2.32)), f, mi))
    v, f = L.box(0.24, 0.24, 0.30)
    objs.append(L.make("lantern_box", L.xform(v, loc=(x, y - flip * 0.44, z0 + 2.07)), f, mi))
    mg = L.mat_glow("lantern_flame", FLAME, 3.2)
    v, f = L.box(0.14, 0.14, 0.18)
    objs.append(L.make("lantern_flame", L.xform(v, loc=(x, y - flip * 0.44, z0 + 2.07)), f, mg))


def bell(objs, x, y, z0):
    """A CARVED BELL OVER THE DOOR - content's tier-3 line, and the thing the
    whole tier is named for. Bronze, on a timber bracket, WITH A CLAPPER,
    because content's crier line says the bell over it has one."""
    mb = L.mat_solid("bell_bronze", BRONZE, 0.38, 0.70)
    mw = L.mat_solid("bell_bracket", WOOD[3], 0.86, 0.0)
    # the bracket: two timbers out of the wall and a cross beam
    for s in (-1, 1):
        v, f = L.box(0.10, 0.52, 0.10)
        objs.append(L.make("bell_arm", L.xform(v, loc=(x + s * 0.34, y - 0.26, z0 + 0.46)), f, mw))
    v, f = L.box(0.92, 0.11, 0.11)
    objs.append(L.make("bell_beam", L.xform(v, loc=(x, y - 0.50, z0 + 0.46)), f, mw))
    # *** THE BELL WAS UPSIDE DOWN AND IT RENDERED AS A GOBLET. *** On the
    # tier LITERALLY NAMED "The Inn of the Bell". `cone(r1, r2, h)` takes r1
    # as the radius at the BASE and r2 at the top, so `cone(0.11, 0.30, ...)`
    # is narrow at the bottom and wide at the top - a cup. A bell flares
    # DOWNWARD to its mouth: r1 is the big number. Not one gate can see this;
    # the front crop could, immediately.
    yb = y - 0.50
    v, f = L.cone(0.018, 0.018, 0.12, 8)             # the stem up to the beam
    objs.append(L.make("bell_stem", L.xform(v, loc=(x, yb, z0 + 0.30)), f, mb))
    v, f = L.cone(0.30, 0.11, 0.40, 16)              # WIDE AT THE BOTTOM
    objs.append(L.make("bell", L.xform(v, loc=(x, yb, z0 - 0.10)), f, mb))
    v, f = L.cone(0.315, 0.315, 0.05, 16)            # the thickened mouth rim
    objs.append(L.make("bell_lip", L.xform(v, loc=(x, yb, z0 - 0.13)), f, mb))
    v, f = L.cone(0.05, 0.05, 0.14, 8)               # the clapper, below the mouth
    objs.append(L.make("bell_clapper", L.xform(v, loc=(x, yb, z0 - 0.17)), f, mb))


def trough(objs, x, y, rz, tier):
    """A WATER TROUGH for the stable yard. A box with water in it, because
    that is what it is FOR."""
    mw = L.mat_solid("trough_wood_%d" % tier, WOOD[tier], 0.88, 0.0)
    mq = L.mat_solid("trough_water", WATER, 0.22, 0.0)
    for dy, dd in ((-0.34, 0.12), (0.34, 0.12)):
        v, f = L.box(1.90, dd, 0.52)
        objs.append(L.make("trough_side", L.xform(v, loc=(x, y + dy, 0.26), rot=(0, 0, rz)), f, mw))
    for dx in (-0.89, 0.89):
        v, f = L.box(0.12, 0.80, 0.52)
        objs.append(L.make("trough_end", L.xform(v, loc=(x + dx, y, 0.26), rot=(0, 0, rz)), f, mw))
    v, f = L.box(1.76, 0.58, 0.06)
    objs.append(L.make("trough_water", L.xform(v, loc=(x, y, 0.40), rot=(0, 0, rz)), f, mq))


def stable(objs, cx, cy, bays, tier):
    """AN OPEN-FRONTED STABLE - content's t2 "a stable yard" and t3 "a stable".

    Posts, a lean-to roof of planks sloping to the front, and a plank back
    wall. Authored, because the MegaKit has no stable and no stall. The roof
    is PLANKS, not thatch and not tile: a lean-to on a yard outbuilding is
    boards, and giving it the main roof's material would flatten the one read
    that separates the tiers."""
    mw = L.mat_solid("stable_wood_%d" % tier, WOOD[tier], 0.88, 0.0)
    W = bays * 2.20
    back, front = cy + 1.30, cy - 1.30
    zb, zf = 2.70, 2.15                      # the lean-to falls toward the yard
    for i in range(bays + 1):
        x = cx - W / 2.0 + i * 2.20
        v, f = L.box(0.16, 0.16, zb)
        objs.append(L.make("stable_post", L.xform(v, loc=(x, back, zb / 2.0)), f, mw))
        v, f = L.box(0.16, 0.16, zf)
        objs.append(L.make("stable_post", L.xform(v, loc=(x, front, zf / 2.0)), f, mw))
    # the back wall, boarded
    for k in range(5):
        v, f = L.box(W, 0.07, 0.52)
        objs.append(L.make("stable_board", L.xform(v, loc=(cx, back, 0.28 + k * 0.54)), f, mw))
    # the divisions between the stalls, half height
    for i in range(1, bays):
        x = cx - W / 2.0 + i * 2.20
        v, f = L.box(0.08, 2.60, 1.30)
        objs.append(L.make("stable_divide", L.xform(v, loc=(x, cy, 0.65)), f, mw))
    # the lean-to roof: planks along the slope, overhanging the front
    pitch = math.atan2(zb - zf, 2.60)
    for k in range(7):
        yy = back - 0.18 - k * 0.46
        zz = zb - (back - yy) * (zb - zf) / 2.60
        v, f = L.box(W + 0.40, 0.50, 0.07)
        objs.append(L.make("stable_roof", L.xform(
            v, loc=(cx, yy, zz + 0.05), rot=(pitch, 0, 0)), f, mw))
    return W


def paving(objs, cx, y0, nx, ny):
    """THE YARD. The kit's own 2 m floor on its own grid, so the cobble matches
    every other paved thing in the town."""
    for i in range(nx):
        for j in range(ny):
            place("Floor_Brick", (cx + (i - (nx - 1) / 2.0) * GRID,
                                 y0 - j * GRID, 0.01), 0.0, objs)


def fence_run(objs, x0, x1, y, n):
    """A wooden fence on the kit's 2 m grid, closing the yard."""
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        place("Prop_WoodenFence_Single", (x, y, 0.0), 0.0, objs)


# -------------------------------------------------------------- the three tiers
def inn_t1(objs):
    """TIER 1 - THE ALE HOUSE. One room, one barrel, one bench.

    6 x 6 m, ONE storey, thatched and SAGGING. Walls are plaster with wood
    trim; ONE door on the south face, on the CENTRE bay so the pivot's door
    rule holds in every tier. Content's crier: "One room, one barrel, one
    bench. The barrel is the better of the three." So the barrel is the only
    thing here in good order, and the board hangs askew.
    NO shutters, NO stable, NO lamp, NO paving - the ABSENCE of dressing is as
    much the wear as the sagging ridge is."""
    def pick(side, i, s):
        if side == 'S' and i == 1:                  # the centre of three bays
            return "Wall_Plaster_Door_Flat"
        if side == 'N' and i == 1:
            return "Wall_Plaster_WoodGrid"          # a vent, which is what it is FOR
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 3, 1, pick, "Corner_Exterior_Wood")
    roof = thatch(objs, wall_top=STOREY, half_w=W / 2.0, length=D, overhang=0.46,
                  pitch=0.86, sag=0.22, seed="inn_t1")
    gable(objs, roof)
    place("Prop_Chimney2", (W / 2.0 - 1.0, 1.1, STOREY - 0.2), 0.0, objs)
    core = list(objs)                               # walls + roof + chimney
    # *** THE FRONTAGE IS LAID OUT AGAINST THE DOOR, NOT SCATTERED. *** The
    # first pass put the barrel at x=0.72 and the bench at x=1.30: the barrel
    # stood INSIDE THE DOOR OPENING (the centre bay's door spans about
    # -0.7..+0.7) and the bench ran straight through it. Every gate was GREEN
    # over that - a blocked door is not blank, not clipped and not unseen.
    # 6 m frontage, x -3..+3: board at the left post, bench left of the door,
    # barrel right of it, nothing within 0.3 m of the opening.
    board(objs, x=-2.75, y=-D / 2.0 - 0.34, z0=0.0, rz=0.0, tier=1, tilt=0.07)
    bench(objs, x=-1.60, y=-D / 2.0 - 0.52, rz=0.0, tier=1)
    barrel(objs, x=1.30, y=-D / 2.0 - 0.60, rz=0.3, tier=1, lean=0.05)
    return {"footprint_m": [W, D], "storeys": 1,
            "door_xy": [0.0, -D / 2.0], "core": core}


def inn_t2(objs):
    """TIER 2 - THE INN. Rooms upstairs, a yard, and it is KEPT.

    6 x 8 m, TWO storeys of timber, round tile roof, SHUTTERED windows, a
    stable yard and a lantern on a hook - every one of those is in content's
    line. The shutter modules are authored in the SAME local frame as the wall
    modules (both centred in X, both running outward in -Y; measured this run:
    wall min y -0.0924, shutter min y -0.5632), so a shutter placed at its
    window bay's own loc/rz lands on the opening. Measured, not hoped."""
    WIN = "Wall_Plaster_Window_Wide_Round"
    def pick(side, i, s):
        if s == 0 and side == 'S' and i == 1:
            return "Wall_Plaster_Door_Round"
        if side in 'EW' and i in (1, 2):
            return WIN
        if side == 'S' and s == 1:
            return WIN
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 4, 2, pick, "Corner_Exterior_Wood")
    # SHUTTERS, on every window bay, placed at that bay's own transform
    for s in range(2):
        z = s * STOREY
        for j in (1, 2):
            y = -D / 2.0 + GRID / 2.0 + j * GRID
            place("WindowShutters_Wide_Round_Open", (-W / 2.0, y, z), math.pi / 2.0, objs)
            place("WindowShutters_Wide_Round_Open", (W / 2.0, y, z), -math.pi / 2.0, objs)
    for i in (0, 1, 2):
        place("WindowShutters_Wide_Round_Open",
              (-W / 2.0 + GRID / 2.0 + i * GRID, -D / 2.0, STOREY), 0.0, objs)
    # Roof_RoundTiles_6x8: measured min [-4.1249, -4.854, -0.7821], dims
    # [8.2498, 9.6827, 5.6722] - origin sits AT the wall top, skirt laps 0.78
    # down over it, ridge tops out +4.8901.
    rz0 = 2 * STOREY
    place("Roof_RoundTiles_6x8", (0.0, 0.0, rz0), 0.0, objs)
    gable(objs, {"eave_x": 4.1249 - 0.25, "eave_z": rz0 - 0.55,
                 "ridge_z": rz0 + 4.60, "length": 9.55}, thick=0.30)
    place("Prop_Chimney", (W / 2.0 - 1.0, D / 2.0 - 1.2, rz0), 0.0, objs)
    core = list(objs)                               # walls + shutters + roof + chimney
    # same layout rule as t1: the bracket board hung off x=-1.70 put its face
    # at -1.53..-0.63, i.e. over the door opening. Moved clear.
    board(objs, x=-2.60, y=-D / 2.0, z0=0.0, rz=0.0, tier=2)
    hook_lantern(objs, x=2.20, y=-D / 2.0, z0=0.0)
    bench(objs, x=-1.80, y=-D / 2.0 - 0.52, rz=0.0, tier=2)
    barrel(objs, x=1.20, y=-D / 2.0 - 0.58, rz=0.0, tier=2)
    # the stable YARD, east of the inn: a two-bay stable, a trough, a fence
    sx = W / 2.0 + 3.60
    stable(objs, cx=sx, cy=1.10, bays=2, tier=2)
    trough(objs, x=sx, y=-1.85, rz=0.0, tier=2)
    fence_run(objs, W / 2.0 + 0.40, sx + 2.60, -3.20, 3)
    return {"footprint_m": [W, D], "storeys": 2,
            "door_xy": [0.0, -D / 2.0], "core": core}


def inn_t3(objs):
    """TIER 3 - THE INN OF THE BELL. Stone below, beam above, and finished.

    6 x 10 m, TWO storeys. Content's line, item by item:
      "stone below, beam above"  -> `Wall_UnevenBrick_*` on the ground storey,
                                    `Wall_Plaster_*` above. The wear changes
                                    with HEIGHT, not painted on uniformly.
      "a carved bell over the door" -> `bell()`, bronze, with a clapper.
      "lamps either side of the door" -> two `lamp()` posts, flanking.
      "a stable and a cart-yard" -> a THREE-bay stable and a paved yard.
      "smoke from two chimneys" -> TWO `Prop_Chimney`, at both ends of the
                                    ridge. The SMOKE is not a mesh - see the
                                    summary; it is the game build's VFX.
    NOTHING is patched, NOTHING is lashed, and the dressing is complete, which
    is the receipt for what the town paid for."""
    WINB = "Wall_UnevenBrick_Window_Wide_Round"
    WINP = "Wall_Plaster_Window_Wide_Round"
    def pick(side, i, s):
        if s == 0:
            if side == 'S' and i == 1:
                return "Wall_UnevenBrick_Door_Round"
            if side in 'EW' and i in (1, 2, 3):
                return WINB
            return "Wall_UnevenBrick_Straight"
        if side in 'EW' and i in (1, 2, 3):
            return WINP
        if side in 'NS' and i == 1:
            return WINP
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 5, 2, pick, "Corner_ExteriorWide_Brick")
    for j in (1, 2, 3):                             # shutters on the upper range
        y = -D / 2.0 + GRID / 2.0 + j * GRID
        place("WindowShutters_Wide_Round_Open", (-W / 2.0, y, STOREY), math.pi / 2.0, objs)
        place("WindowShutters_Wide_Round_Open", (W / 2.0, y, STOREY), -math.pi / 2.0, objs)
    # Roof_RoundTiles_6x10: measured min [-4.1249, -5.9546, -0.7821], dims
    # [8.2498, 11.8522, 5.6722]. Same 8.25 m span as t2's roof, 2.17 m longer.
    rz0 = 2 * STOREY
    place("Roof_RoundTiles_6x10", (0.0, 0.0, rz0), 0.0, objs)
    gable(objs, {"eave_x": 4.1249 - 0.25, "eave_z": rz0 - 0.55,
                 "ridge_z": rz0 + 4.60, "length": 11.72}, thick=0.30)
    for sy in (-1, 1):                              # TWO chimneys
        place("Prop_Chimney", (W / 2.0 - 1.0, sy * (D / 2.0 - 1.4), rz0), 0.0, objs)
    core = list(objs)                               # walls + shutters + roof + chimneys
    bell(objs, x=0.0, y=-D / 2.0, z0=STOREY - 0.60)
    # lamps pulled in to +-1.20 ("either side of the DOOR" reads better close)
    # and that also clears the bench, which at x=2.40 spans 1.4..3.4 and ran
    # straight THROUGH the old lamp post at 1.50.
    for s in (-1, 1):                               # lamps EITHER SIDE of the door
        lamp(objs, x=s * 1.20, y=-D / 2.0 - 0.34, z0=0.0)
    board(objs, x=-2.30, y=-D / 2.0, z0=0.0, rz=0.0, tier=3)
    bench(objs, x=2.45, y=-D / 2.0 - 0.52, rz=0.0, tier=3)
    barrel(objs, x=-2.70, y=-D / 2.0 - 0.62, rz=0.0, tier=3)
    # the cart-yard, paved on the kit's grid, and a three-bay stable
    sx = W / 2.0 + 4.20
    stable(objs, cx=sx, cy=1.60, bays=3, tier=3)
    trough(objs, x=sx, y=-1.60, rz=0.0, tier=3)
    paving(objs, cx=sx, y0=-0.20, nx=4, ny=3)
    fence_run(objs, W / 2.0 + 0.40, sx + 3.60, -4.40, 4)
    place("Prop_Crate", (sx + 2.60, -2.40, 0.0), 0.4, objs)
    place("Prop_Crate", (sx + 2.20, -3.10, 0.0), 0.1, objs)
    return {"footprint_m": [W, D], "storeys": 2,
            "door_xy": [0.0, -D / 2.0], "core": core}


BUILDERS = {"inn_t1": inn_t1, "inn_t2": inn_t2, "inn_t3": inn_t3}


def build(key, px, errs):
    """Build one tier and GATE the pivot contract rather than record it.

    `hallgen.build` writes `core_centre_dx_dy` and `base_dz_m` into the report
    and nothing ever reads them, so a ladder whose pivot drifted would ship
    GREEN with the drift printed in its own report. Here a drift is an ERROR."""
    objs = []
    meta = BUILDERS[key](objs)
    H.trim_materials(px)
    bpy.context.view_layer.update()
    # THE PIVOT IS THE BUILDING'S CENTRE, NOT THE ASSEMBLY'S. The yard and the
    # stable only extend EAST and SOUTH; re-centring on everything would drag
    # the inn off the spawn point and make it JUMP on upgrade - which is the
    # exact defect a tiered family exists to avoid.
    core = meta.pop("core", None) or objs
    cmn, cmx, _ = G.world_bounds(core)
    cx, cy = (cmn.x + cmx.x) / 2.0, (cmn.y + cmx.y) / 2.0
    mn, _mx, _ = G.world_bounds(objs)
    for o in objs:
        o.location = (o.location.x - cx, o.location.y - cy, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn2, mx2, _ = G.world_bounds(objs)
    cmn2, cmx2, _ = G.world_bounds(core)
    ccx = round((cmn2.x + cmx2.x) / 2.0, 4)
    ccy = round((cmn2.y + cmx2.y) / 2.0, 4)
    base = round(mn2.z, 4)
    meta.update({
        "core_centre_dx_dy": [ccx, ccy],
        "core_dims_m": [round(cmx2.x - cmn2.x, 4), round(cmx2.y - cmn2.y, 4),
                        round(cmx2.z - cmn2.z, 4)],
        "dims_m": [round(mx2.x - mn2.x, 4), round(mx2.y - mn2.y, 4),
                   round(mx2.z - mn2.z, 4)],
        "base_dz_m": base,
        "centre_dx_dy": [round((mn2.x + mx2.x) / 2.0, 4),
                         round((mn2.y + mx2.y) / 2.0, 4)],
        "door_xy_after_recentre": [round(meta["door_xy"][0] - cx, 4),
                                   round(meta["door_xy"][1] - cy, 4)],
        "n_obj": len(objs),
        "n_tri": sum(len(o.data.polygons) for o in objs if o.type == 'MESH'),
    })
    # *** THE PIVOT GATE. *** 1 mm, because the re-centre is exact arithmetic -
    # anything bigger means a builder moved geometry after `core` was taken.
    if abs(ccx) > 0.001 or abs(ccy) > 0.001:
        errs.append("%s PIVOT DRIFT: core centre (%0.4f, %0.4f) not at origin"
                    % (key, ccx, ccy))
    if abs(base) > 0.001:
        errs.append("%s PIVOT DRIFT: base z %0.4f not on the ground" % (key, base))
    return objs, meta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=H.W5)
    ap.add_argument("--px", type=int, default=1024)
    ap.add_argument("--resx", type=int, default=1280)
    ap.add_argument("--resy", type=int, default=1160)
    ap.add_argument("--only", default="")
    ap.add_argument("--noglb", action="store_true")
    ap.add_argument("--maxmb", type=float, default=9.0)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    keys = [k for k in ORDER if not a.only or k == a.only]
    root = os.path.join(a.repo, "renders", "art", "town", "inn")
    glbdir = os.path.join(a.repo, "assets", "buildings")
    os.makedirs(root, exist_ok=True)
    os.makedirs(glbdir, exist_ok=True)
    rep = {"when_ct": "28 Nov 2026 11:4x-12:2x CT", "tiers": {}, "errors": [],
           "px": a.px, "maxmb": a.maxmb, "growth": "free",
           "why_free": ("t2 and t3 are the same height by design - content's t3 "
                        "line is 'stone below, beam above', two storeys, and both "
                        "wear the same 8.25 m-span tile roof. The progression is "
                        "material, length and dressing, so the monotonic gate is "
                        "NOT carrying this sheet.")}

    for key in keys:
        G.purge()
        H._PROTO.clear()
        scene, eng = T.scene_setup(a.resx, a.resy)
        objs, meta = build(key, a.px, rep["errors"])
        if not a.noglb:
            gp = os.path.join(glbdir, "town_%s.glb" % key)
            ok, note, nimg = H.export_glb_jpeg(objs, gp)
            meta["export_note"] = note
            meta["n_images_in_file"] = nimg
            meta["glb"] = os.path.relpath(gp, a.repo).replace("\\", "/")
            meta["glb_bytes"] = os.path.getsize(gp) if os.path.isfile(gp) else 0
            meta["glb_mb"] = round(meta["glb_bytes"] / 1048576.0, 3)
            if not ok:
                rep["errors"].append("%s EXPORT FAILED: %s" % (key, note))
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
        # SEE-THROUGH, subject alone through the front camera. Ground and hero
        # are hidden because both would sit behind the walls and FILL the holes
        # this is trying to find.
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
        H._PROTO.clear()
        RX, RY = 1860, 820
        scene, eng = T.scene_setup(RX, RY)
        placed, spans, x = {}, [], 0.0
        for key in ORDER:
            objs, _m = build(key, a.px, rep["errors"])
            mn, mx, _ = G.world_bounds(objs)
            for o in objs:
                o.location = (o.location.x + (x - mn.x),
                              o.location.y - (mn.y + mx.y) / 2.0,
                              o.location.z - mn.z)
            bpy.context.view_layer.update()
            w = mx.x - mn.x
            placed[key] = objs
            spans.append((key, x, x + w))
            x += w + 4.0                 # 4.0 m - at less the tiers read as ONE
        hero, _ = T.add_hero(dx=x + 0.8)
        bpy.context.view_layer.update()
        hmn, hmx, _ = G.world_bounds(hero)
        total = hmx.x
        gnd = T.ground_plane(total + 4.0, 30.0, cx=total / 2.0)
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
        G.draw_text(buf, "BELLMIRE - THE INN, TIER 1 TO 3. EXTERIOR ONLY. ONE PIVOT, ONE CAMERA, ONE ORTHO SCALE.",
                    14, 12, scale=2)
        G.draw_text(buf, "HERO = KAYKIT KNIGHT, IDLE FRAME 1, STANDS 2.453 M TO THE HELMET. PACK STOREY 3.1227 M.",
                    14, 34, scale=2)
        G.draw_text(buf, "T2/T3 ARE THE SAME HEIGHT ON PURPOSE - 'STONE BELOW, BEAM ABOVE'. THE LADDER GROWS BY MATERIAL, LENGTH AND YARD.",
                    14, 56, scale=2)
        G.draw_text(buf, "BOARD/BENCH/BARREL/LANTERN/BELL/TROUGH/STABLE AUTHORED - THE MEGAKIT'S 176 MODULES HAVE NONE OF THEM. WALLS/ROOF/FLOOR/FENCE = MEGAKIT, CC0.",
                    14, 78, scale=2)
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
        rep["errors"].extend(T.ladder_gate(
            sil, list(ORDER),
            {k: (v.get("dims_m") or [0, 0, 0])[2]
             for k, v in rep["tiers"].items()},
            RY, growth="free"))
        rep["sheet"] = {"path": os.path.relpath(sheet, a.repo).replace("\\", "/"),
                        "opaque_px": sheet_px, "subject_moved_px": sheet_moved,
                        "border_alpha_px": T.border_px(sheet), "label_px": lab,
                        "silhouette": sil,
                        "spans": [[s[0], round(s[1], 3), round(s[2], 3)] for s in spans]}
        rep["engine"] = eng

    rep["verdict"] = "GREEN" if not rep["errors"] else "RED"
    with open(os.path.join(root, "_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("INNGEN " + json.dumps({"verdict": rep["verdict"],
                                  "errors": rep["errors"],
                                  "tiers": {k: v.get("dims_m")
                                            for k, v in rep["tiers"].items()}}))


if __name__ == "__main__":
    main()
