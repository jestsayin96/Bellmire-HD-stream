"""barracksgen - THE BARRACKS, TIERS 1 TO 3. EXTERIOR ONLY.

  blender -b -noaudio -P tools/art/barracksgen.py -- --repo <repo> [--px 1024]
                                                     [--only barracks_t1] [--noglb]

28 Nov 2026, ~12:4x CT. Art lane. The row (plan, TAKE THIS NEXT, ART, the
12:34 block): "THE NEXT TOWN TIER FAMILY ... Content has words for all seven
landmark families (barracks, chapel, hall, inn, market_hall, windmill,
workshop); hall, well and inn have meshes. Take the next family by that list
and ship t1/t2/t3 exterior-only, three tiers rendered side by side."

WHY BARRACKS - MEASURED OFF THE TREE, NOT CHOSEN
------------------------------------------------
`assets/buildings/` listed this run holds tiered families `town_hall_t1/t2/t3`,
`town_inn_t1/t2/t3`, `town_well_t1/t2/t3`, and FOUR single-tier landmarks with
no ladder at all: `lm_barracks`, `lm_chapel`, `lm_windmill`, `lm_workshop`.
`data/lore_lines.json -> town_buildings.landmarks` (read off origin/main, NOT
off W5 - W5's copy of that file is stale and returns an EMPTY landmarks dict,
which would have told me content had written nothing) carries keys in the order
hall, chapel, barracks, windmill, workshop, market_hall, inn. The row's own
list is alphabetical and barracks is its first family without a ladder. So
barracks, and `lm_barracks.glb` stays where it is - see the WIRING note in the
summary, it is NOT superseded by this run.

WHAT CONTENT ALREADY SAYS, AND IT IS THE SPEC
---------------------------------------------
`landmarks.barracks.district = "garrison"`, `tiers[].see`:
  t1 "The Watch Hut"  A low timber hut, a spear rack, a brazier.
  t2 "The Barracks"   A timber barracks with a fenced yard, straw dummies, a flag.
  t3 "The Garrison"   A stone barracks and a gravelled yard, archers on the
                      roof, E3PO's post on the wall.
`tier_levels` = {1: 1, 2: 5, 3: 9}. Mesh names are `town_barracks_t1/t2/t3`, so
`family: "barracks"` in the `/2` layout resolves by construction - the default
for a landmark is its id without `lm_`, and `words` defaults to
`landmarks.barracks`. Criers and plaques are content's; nothing here is a
caption on the mesh.

*** TWO THINGS IN CONTENT'S t3 LINE ARE NOT BUILDING GEOMETRY, AND I DID NOT
*** FAKE THEM. SAID HERE RATHER THAN DISCOVERED IN THE SUMMARY.
  "archers on the roof" - an ARCHER is an NPC, not a landmark mesh. Authoring
      figures into a building .glb would bake three men into a static asset
      that can never look away, never die and never be absent at level 9. What
      the MESH can honestly carry is the PLACE an archer stands: a roof-edge
      hoarding walk, railed, reached by an exterior stair. That is what t3 has.
      The archers themselves are the game build's to spawn, and the walk is
      sized so a 2.453 m KayKit body fits behind the rail.
  "E3PO's post on the wall" - likewise a named NPC's station. t3 carries a
      raised sentry post on the yard wall: a stone stub wall, a platform, a
      rail and a stair up. The post is the mesh; the sentry is not.
NEITHER IS A GATE FAILURE AND BOTH ARE DELIBERATE. If Mr. E wants figures baked
in, that is a one-line decision and a re-run, not a redesign.

*** WEAR IS THE SPEC (Mr. E, art rule 2), AND THIS LADDER IS ABOUT ORDER. ***
A barracks is not an inn: what a viewer buys at level 9 is not comfort, it is
DISCIPLINE. So the wear term here is tidiness as much as material, in order of
what it buys at stream distance:
  1. ROOF   - authored thatch, heavily sagging (t1) vs round tile (t2/t3).
  2. MASS   - 6x4x1 storey -> 6x8x2 -> 6x10x2 + walled yard.
  3. WALL   - plaster with wood corners (t1), plaster both storeys with
              shutters (t2), uneven BRICK both storeys (t3). NOTE this differs
              from the inn on purpose: content's t3 crier is "The Garrison is
              RAISED IN STONE", not "stone below, beam above", so the brick
              goes all the way up and there is no timber upper range.
  4. THE RACK - the piece that makes it a barracks and not a house, and the
              clearest wear in the family. 3 spears at t1 with ONE OUT OF ITS
              SLOT and leaning; 6 square at t2; 8 square plus a bill at t3.
              Content's t1 plaque is "Boots off at the door" - a hut, not a
              garrison - and a rack that is short and untidy says that without
              a word of text.
  5. DRESSING - brazier / + fenced dirt yard, two straw dummies, a flag /
              + gravelled yard with a rock border, three dummies, two flags,
              roof walk, sentry post, a wagon.

*** THIS LADDER IS GATED growth="free", NOT "monotonic", AND HERE IS WHY. ***
t2 and t3 are BOTH two storeys under the same 8.25 m-span tile roof family, so
both ridge at wall_top + 4.89 and the silhouette HEIGHT does not grow from t2
to t3. The progression t2 -> t3 is material, length, yard and dressing. That is
the same call the inn made for the same reason, and `townlib.ladder_gate`
documents that running `monotonic` over a legitimately flat ladder fires on the
GOOD sheet. Declaring "free" means the monotonic gate is NOT carrying this
sheet and MY EYE IS. See the summary for what I saw.

PIVOT CONTRACT - `data/town/README.md`, the `/2` section
-------------------------------------------------------
"All tiers of one family share ONE origin: the footprint centre, on the ground,
street side facing +Z. A tier swap changes the MESH only - never pos, yaw, door
or half." So every tier re-centres on its CORE (walls + roof + chimney, NEVER
the yard, which only extends east) to x=0, y=0, lowest geometry z=0; the door
sits on the centre bay at x=0 in all three tiers BY CONSTRUCTION (every tier is
3 bays wide); and `half` is the LARGEST tier's ROOF extent, which the game
build takes from this run's report. `build()` GATES the re-centre - a drift is
an error, not a recorded number.

SIZED AGAINST THE BODY
----------------------
Hero is the KayKit Knight, idle frame 1, standing 2.453 m to the helmet
(`townlib.HERO_STANDS`). The pack storey is 3.1227 m. Measured this run off the
pack itself rather than assumed: `Balcony_Cross_Straight` is 2.000 x 0.206 x
1.230 with min y -1.1043, i.e. the walk runs OUTWARD in -Y from its line and
the rail tops out 1.23 above it - the same outward convention as the wall
modules, so a balcony placed at a wall line with the wall's own rz lands as a
walk on the outside. 132 triangles against `Balcony_Simple_Straight`'s 1120,
so Cross is the one used. `Prop_WoodenFence_Single` 2.064 x 0.120 x 0.838,
`Prop_ExteriorBorder_Straight1` 2.000 x 0.700 x 0.134 (MI_RockTrim - that is
the gravel border), `Prop_Wagon` 1.951 x 4.024 x 1.529.

WHAT THE GATES CANNOT SEE - SAID BEFORE THE NUMBERS
---------------------------------------------------
  1. BLANK        - opaque px > 0. Cannot see a clipped subject.
  2. BORDER       - zero alpha on the 1-px frame. Cannot see a subject that is
                    merely small.
  3. SUBJECT SEEN - with/without difference through ONE camera. Catches a pass
                    over an empty frame. RED ON EMPTY.
  4. HERO SEEN    - the same difference for the body, separately, plus a height
                    floor, because against a 10 m barracks an area floor would
                    call a working reference absent.
  5. SEE-THROUGH  - transparent pixels INSIDE the silhouette. This family is
                    the one most exposed to it: a ROOF WALK and a RAILED SENTRY
                    POST are open lattices ON PURPOSE, so t3's hole fraction is
                    expected to be the HIGHEST of the three and that is not a
                    defect. The number is comparative, never a pass mark.
                    *** SO THE t3 THRESHOLD IS NOT THE INN'S. *** See the
                    SEE_THROUGH_CAP table below; the per-tier cap is declared
                    with its reason, not loosened quietly until green.
  6. PIVOT        - core centre within 1 mm of origin, base at z=0.
  7. LADDER GATE  - size floor + distinctness + one-scale on the side-by-side
                    sheet. CANNOT say the wear reads, cannot say the three read
                    in the right order, cannot see colour separation.
  8. LABEL        - every caption box carries ink.
  9. RACK SEEN    - new here, and it is the one instrument this file adds. See
                    the note at `rack_gate`.
NONE OF THEM ASKS "IS THIS STILL A BARRACKS". Only looking says that.
"""
import argparse, json, math, os, sys

import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L
import townlib as T
import hallgen as H          # the PROVEN pack layer
import inngen as I           # for the authored props the inn already proved

STOREY, GRID = H.STOREY, H.GRID
place, wall_box, thatch, gable = H.place, H.wall_box, H.thatch, H.gable
banner = H.banner
bench, barrel, paving, fence_run = I.bench, I.barrel, I.paving, I.fence_run

CANON = {
    "barracks_t1": ("The Watch Hut", 1, "Thatch, a short rack, a brazier."),
    "barracks_t2": ("The Barracks",  2, "Two storeys, a fenced yard, dummies, a flag."),
    "barracks_t3": ("The Garrison",  3, "Stone, a gravelled yard, a roof walk, a post."),
}
ORDER = ("barracks_t1", "barracks_t2", "barracks_t3")

# *** THE SEE-THROUGH CAP IS PER TIER AND DECLARED WITH ITS REASON. ***
# The inn ran one cap of 0.18 across all three tiers and that was right for the
# inn, whose tiers are all closed boxes. It is WRONG here and would have been
# wrong in the silent direction - t3's roof walk and sentry rail are open
# lattice BY SPEC ("archers on the roof", "the wall is walked"), so t3 reads
# more see-through than t2 BECAUSE IT IS BETTER, not worse. A single cap would
# either red-flag the best tier or be loosened to 0.30 and stop seeing the open
# gable it exists to catch on t1 and t2. So: t1/t2 keep the inn's 0.18, t3 is
# allowed 0.30 and nothing else is.
SEE_THROUGH_CAP = {"barracks_t1": 0.18, "barracks_t2": 0.18, "barracks_t3": 0.30}

# Authored-colour slots for the procedural pieces ONLY - the pack modules keep
# Quaternius' own materials and nothing here repaints them. These follow the
# inn's hard-won lesson verbatim: albedo near 0.19 renders at luma ~0.25 and
# buys ~0.18 of separation from the MegaKit's plaster at ~0.434. Warm, not grey.
WOOD = {1: (0.172, 0.130, 0.088), 2: (0.222, 0.154, 0.086),
        3: (0.285, 0.198, 0.102)}
SHAFT = {1: (0.150, 0.118, 0.082), 2: (0.196, 0.142, 0.084),
         3: (0.250, 0.180, 0.096)}
STRAW = {1: (0.255, 0.198, 0.088), 2: (0.300, 0.236, 0.104),
         3: (0.330, 0.262, 0.118)}
ROPE = (0.205, 0.172, 0.112)
STONE = {1: (0.152, 0.148, 0.136), 2: (0.172, 0.168, 0.156),
         3: (0.202, 0.198, 0.184)}
IRON = H.IRON
FLAME = H.FLAME
EMBER = (0.70, 0.22, 0.05)


# ------------------------------------------------------- the authored pieces
# Nothing below exists in the MegaKit. Checked by walking all 176 of its glTF
# modules this run: Prop_* is Brick1-4, Chimney, Chimney2, Crate,
# ExteriorBorder x3, MetalFence x2, Support, Vine x6, Wagon, WoodenFence x3.
# There is NO spear, NO rack, NO brazier, NO dummy and NO flag in the pack, so
# the barracks' entire identity as a BARRACKS is authored and the pack carries
# the shell, the fences, the border and the wagon.
def spear_rack(objs, x, y, rz, tier):
    """THE RACK. Content names it at t1 and it is the family's clearest wear.

    n spears and their ORDER is the tier: 3 at t1 with the last one out of its
    slot and leaning 22 degrees, 6 square at t2, 8 square plus a bill at t3.
    Returns the rack's own objects so the RACK SEEN gate can hide exactly these
    and nothing else - a gate that hides "the props" would be measuring the
    brazier too and could not tell which one vanished."""
    n = {1: 3, 2: 6, 3: 8}[tier]
    mine = []
    mw = L.mat_solid("rack_wood_t%d" % tier, WOOD[tier], 0.74, 0.0)
    ms = L.mat_solid("rack_shaft_t%d" % tier, SHAFT[tier], 0.76, 0.0)
    mh = L.mat_solid("rack_iron", IRON, 0.38, 0.70)
    span = 0.30 + 0.215 * n
    for sx in (-1, 1):                              # two posts
        v, f = L.box(0.11, 0.11, 1.34)
        mine.append(L.make("rack_post", L.xform(
            v, loc=(x + sx * span / 2.0 * math.cos(rz),
                    y + sx * span / 2.0 * math.sin(rz), 0.67),
            rot=(0, 0, rz)), f, mw))
    for z in (0.44, 1.18):                          # two rails
        v, f = L.box(span + 0.18, 0.09, 0.09)
        mine.append(L.make("rack_rail", L.xform(
            v, loc=(x, y, z), rot=(0, 0, rz)), f, mw))
    for i in range(n):
        o = -span / 2.0 + span * (i + 0.5) / n
        # ONE spear out of its slot at t1. That is the wear and it is ONE
        # thing, not a scatter - a rack with every spear askew reads as a
        # rubbish heap, not as a watch hut.
        lean = 0.38 if (tier == 1 and i == n - 1) else 0.0
        hgt = 2.08
        v, f = L.cone(0.034, 0.030, hgt, seg=7)
        mine.append(L.make("spear_shaft", L.xform(
            v, loc=(x + o * math.cos(rz), y + o * math.sin(rz), 0.0),
            rot=(lean, 0.0, rz)), f, ms))
        v, f = L.cone(0.052, 0.0, 0.30, seg=7)
        mine.append(L.make("spear_head", L.xform(
            v, loc=(x + o * math.cos(rz) - math.sin(rz) * math.sin(lean) * hgt,
                    y + o * math.sin(rz) + math.cos(rz) * -math.sin(lean) * hgt,
                    hgt * math.cos(lean)),
            rot=(lean, 0.0, rz)), f, mh))
    if tier == 3:                                   # a bill, the sergeant's
        v, f = L.cone(0.040, 0.036, 2.22, seg=7)
        mine.append(L.make("bill_shaft", L.xform(
            v, loc=(x + (span / 2.0 + 0.16) * math.cos(rz),
                    y + (span / 2.0 + 0.16) * math.sin(rz), 0.0),
            rot=(0, 0, rz)), f, ms))
        v, f = L.box(0.07, 0.30, 0.44)
        mine.append(L.make("bill_head", L.xform(
            v, loc=(x + (span / 2.0 + 0.16) * math.cos(rz),
                    y + (span / 2.0 + 0.16) * math.sin(rz), 2.34),
            rot=(0, 0, rz)), f, mh))
    objs.extend(mine)
    return mine


def brazier(objs, x, y, tier):
    """A tripod brazier, coals lit. Content names it at t1 and it STAYS - a
    watch that stands all night keeps its fire at every tier."""
    mi = L.mat_solid("braz_iron", IRON, 0.42, 0.68)
    mc = L.mat_glow("braz_coals", EMBER, 2.6)
    h = 0.74
    for j in range(3):                              # three legs
        th = 2.0 * math.pi * j / 3.0
        v, f = L.cone(0.035, 0.028, h, seg=6)
        objs.append(L.make("braz_leg", L.xform(
            v, loc=(x + 0.17 * math.cos(th), y + 0.17 * math.sin(th), 0.0),
            rot=(-0.20, 0.0, th + math.pi / 2.0)), f, mi))
    v, f = L.cone(0.21, 0.30, 0.26, seg=12)
    objs.append(L.make("braz_bowl", L.xform(v, loc=(x, y, h)), f, mi))
    v, f = L.cone(0.25, 0.14, 0.09, seg=12)
    objs.append(L.make("braz_coals", L.xform(v, loc=(x, y, h + 0.20)), f, mc))


def dummy(objs, x, y, rz, tier):
    """A STRAW DUMMY - a pell. Content names them at t2 and t3.

    A post in the ground, a crossbar for arms, a straw-bound body and a head,
    roped on. The STRAW is the wear slot: t2's is duller and the binding
    sparser than t3's."""
    mw = L.mat_solid("pell_wood_t%d" % tier, WOOD[tier], 0.76, 0.0)
    mstr = L.mat_solid("pell_straw_t%d" % tier, STRAW[tier], 0.86, 0.0)
    mr = L.mat_solid("pell_rope", ROPE, 0.88, 0.0)
    v, f = L.cone(0.075, 0.062, 1.86, seg=8)
    objs.append(L.make("pell_post", L.xform(v, loc=(x, y, 0.0), rot=(0, 0, rz)), f, mw))
    v, f = L.box(1.08, 0.08, 0.08)                  # the crossbar = arms
    objs.append(L.make("pell_arms", L.xform(v, loc=(x, y, 1.34), rot=(0, 0, rz)), f, mw))
    v, f = L.cone(0.20, 0.17, 0.68, seg=9)          # the bound body
    objs.append(L.make("pell_body", L.xform(v, loc=(x, y, 0.86), rot=(0, 0, rz)), f, mstr))
    v, f = L.sphere(0.145, 0.145, 0.155, seg=11, rings=8)
    objs.append(L.make("pell_head", L.xform(v, loc=(x, y, 1.70), rot=(0, 0, rz)), f, mstr))
    for z in ((1.02, 1.42) if tier == 2 else (0.96, 1.20, 1.42)):
        v, f = L.cone(0.195, 0.195, 0.045, seg=10)
        objs.append(L.make("pell_rope", L.xform(v, loc=(x, y, z), rot=(0, 0, rz)), f, mr))


def flagpole(objs, x, y, tier, h=4.6):
    """A flag on a pole. Content names one at t2 and the garrison flies two."""
    mp = L.mat_solid("flag_pole_t%d" % tier, WOOD[tier], 0.62, 0.0)
    v, f = L.cone(0.062, 0.046, h, seg=8)
    objs.append(L.make("flag_pole", L.xform(v, loc=(x, y, 0.0)), f, mp))
    v, f = L.cone(0.072, 0.0, 0.20, seg=8)
    objs.append(L.make("flag_finial", L.xform(v, loc=(x, y, h)), f,
                       L.mat_solid("flag_finial", IRON, 0.40, 0.70)))
    # H.banner hangs the cloth from a bar; the pole carries it on the +X side
    banner(objs, x + 0.46, y, h - 0.34, 0.86, 1.22, 0.0)


ROOF_EAVE_X = 4.1249          # measured: Roof_RoundTiles_6x10 half-span


def roof_walk(objs, eave_z, d_mods, d):
    """THE ROOF WALK - t3's "archers on the roof", as a PLACE not as figures.

    *** PASS 1 PUT THIS WALK WHERE NOTHING COULD SEE IT, AND NO GATE SAID SO.
    Pass 1 placed it at the WALL line, half_w = W/2 + 0.10 = 3.10. The 6x10
    tile roof is 8.2498 wide, so its eave reaches x = +-4.1249 and OVERHANGS
    the wall by 1.02 m. The entire walk sat UNDER that overhang. Every gate
    went green - it is not blank, not clipped, not missing and not a hole in
    the silhouette, and `solidity` even read t3 as the TIDIEST tier at 12.5%
    because the one thing that should have opened it up was hidden. I found it
    by LOOKING at the three-quarter render. That is the fourth time in this
    lane's history that a number and a picture disagreed and the picture was
    right. The rule I keep writing down and keep having to re-learn: ask every
    gate what a PASS looks like when the subject is ABSENT - and "absent"
    includes "present but occluded".
    So the walk now brackets OUTBOARD of the eave, which is also what a real
    hoarding is - a timber gallery corbelled out past the roof edge - and
    `walk_seen` makes its visibility a GATED number rather than a hope.

    `Balcony_Cross_Straight` measured this run: 2.000 x 0.206 x 1.230, min y
    -1.1043, so the walk runs outward in -Y from its line and a 2.453 m body
    clears the 1.23 m rail at the chest. 132 tri against Simple's 1120.

    *** AND PASS 2 MOVED IT OUTBOARD WITH THE ROTATIONS BACKWARDS, SO IT WAS
    STILL UNDER THE EAVE. *** The balcony's deck runs outward in LOCAL -Y.
    Rz(+90) maps -Y to +X and Rz(-90) maps -Y to -X, so the rotations pass 2
    copied from `wall_box` (west = +90, east = -90) pointed BOTH walks INWARD,
    back under the overhang they had just been moved out from. `walk_seen`
    read 1797 px and PASSED, because the rail tops still cleared the roof
    skirt - so the gate I had just built to catch exactly this fault passed a
    walk that was still hidden, and only the picture said otherwise AGAIN. A
    floor gate answers "is any of it visible", never "is it where I put it".
    The rotations are now the mirror of the wall convention, deliberately, and
    `walk_x_m` goes in the report so the next seat can check the number
    against the eave rather than trusting this comment.
    WALK_X is set so the deck's outer edge projects about 0.55 m PAST the
    eave: 1.1043 of deck from a line at ROOF_EAVE_X - 0.55 reaches 4.68
    against the eave's 4.1249. Enough to read as a gallery, little enough that
    `half` grows by half a metre a side and not by a metre and a half."""
    mine = []
    wx = ROOF_EAVE_X - 0.55
    for j in range(d_mods):
        y = -d / 2.0 + GRID / 2.0 + j * GRID
        place("Balcony_Cross_Straight", (-wx, y, eave_z), -math.pi / 2.0, mine)
        place("Balcony_Cross_Straight", (wx, y, eave_z), math.pi / 2.0, mine)
    objs.extend(mine)
    return mine


def sentry_post(objs, x, y):
    """E3PO'S POST, t3 - the station, not the sentry. A stone stub wall, a
    plank platform, a rail and a stair up. Sized so a 2.453 m body standing on
    the platform clears the rail at the waist and is visible over it."""
    ms = L.mat_solid("post_stone", STONE[3], 0.80, 0.0)
    mw = L.mat_solid("post_plank", WOOD[3], 0.74, 0.0)
    v, f = L.box(2.10, 1.10, 1.70)                  # the stub wall
    objs.append(L.make("post_wall", L.xform(v, loc=(x, y, 0.85)), f, ms))
    v, f = L.box(2.30, 1.30, 0.14)                  # the platform
    objs.append(L.make("post_deck", L.xform(v, loc=(x, y, 1.77)), f, mw))
    place("Balcony_Cross_Straight", (x, y - 0.65, 1.84), 0.0, objs)
    place("Stairs_Exterior_Straight", (x, y + 1.30, 0.0), math.pi, objs)


def yard_border(objs, cx, y0, nx, ny):
    """THE GRAVELLED yard, t3. `Prop_ExteriorBorder_Straight1` is MI_RockTrim
    and 2.000 x 0.700 x 0.134 - it is the kit's own gravel edging, so the yard
    is the kit's floor inside a rock border rather than a repainted plane."""
    paving(objs, cx=cx, y0=y0, nx=nx, ny=ny)
    for i in range(nx):
        x = cx + (i - (nx - 1) / 2.0) * GRID
        place("Prop_ExteriorBorder_Straight1", (x, y0 + 1.0, 0.0), 0.0, objs)
        place("Prop_ExteriorBorder_Straight1", (x, y0 - (ny - 1) * GRID - 1.0,
                                                0.0), math.pi, objs)


# -------------------------------------------------------------- the three tiers
def barracks_t1(objs):
    """TIER 1 - THE WATCH HUT. A hut, a short rack, a fire.

    6 x 4 m, ONE storey, thatched and SAGGING HARD (sag 0.26 against the inn's
    0.22 - a watch hut is the poorest thing in the family). THREE bays wide so
    the door sits on the centre bay at x=0 and the pivot's door rule holds in
    every tier by construction rather than by luck. Plaster walls, wood
    corners. Content's plaque is "Boots off at the door" - this is somewhere men
    sleep in their coats, so: NO fence, NO yard, NO dummy, NO flag, NO shutters.
    The ABSENCE is as much the wear as the sagging ridge."""
    def pick(side, i, s):
        if side == 'S' and i == 1:                  # centre of three bays
            return "Wall_Plaster_Door_Flat"
        if side in 'EW' and i == 0:
            return "Wall_Plaster_Window_Thin_Round"
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 2, 1, pick, "Corner_Exterior_Wood")
    roof = thatch(objs, wall_top=STOREY, half_w=W / 2.0, length=D, overhang=0.44,
                  pitch=0.84, sag=0.26, seed="barracks_t1")
    gable(objs, roof)
    place("Prop_Chimney2", (W / 2.0 - 1.0, 0.0, STOREY - 0.2), 0.0, objs)
    core = list(objs)
    # FRONTAGE LAID OUT AGAINST THE DOOR, the inn's lesson taken as given: the
    # centre bay's door spans about -0.7..+0.7, so nothing sits inside +-1.0.
    # 6 m frontage, x -3..+3. Rack left of the door, brazier right of it.
    rack = spear_rack(objs, x=-1.95, y=-D / 2.0 - 0.42, rz=0.0, tier=1)
    brazier(objs, x=1.90, y=-D / 2.0 - 0.80, tier=1)
    return {"footprint_m": [W, D], "storeys": 1,
            "door_xy": [0.0, -D / 2.0], "core": core, "rack": rack}


def barracks_t2(objs):
    """TIER 2 - THE BARRACKS. Beds, a yard, and drill.

    6 x 8 m, TWO storeys of timber (plaster both storeys), shuttered windows,
    round tile roof. Content's line item by item: "a timber barracks" -> two
    storeys of plaster with wood corners; "a fenced yard" -> a wooden fence run
    closing a dirt yard east; "straw dummies" -> TWO pells; "a flag" -> ONE
    pole. The rack doubles to 6 and every spear is square in its slot - that
    single change is the clearest thing the eye can read between t1 and t2.
    Content's plaque: "Drill at second bell"."""
    WIN = "Wall_Plaster_Window_Wide_Round"
    def pick(side, i, s):
        if s == 0 and side == 'S' and i == 1:
            return "Wall_Plaster_Door_Round"
        if side in 'EW' and i in (1, 2):
            return WIN
        if side == 'S' and s == 1 and i in (0, 2):
            return WIN
        return "Wall_Plaster_Straight"
    W, D = wall_box(objs, 3, 4, 2, pick, "Corner_Exterior_Wood")
    for s in range(2):                              # shutters on every window
        z = s * STOREY
        for j in (1, 2):
            y = -D / 2.0 + GRID / 2.0 + j * GRID
            place("WindowShutters_Wide_Round_Open", (-W / 2.0, y, z), math.pi / 2.0, objs)
            place("WindowShutters_Wide_Round_Open", (W / 2.0, y, z), -math.pi / 2.0, objs)
    for i in (0, 2):
        place("WindowShutters_Wide_Round_Open",
              (-W / 2.0 + GRID / 2.0 + i * GRID, -D / 2.0, STOREY), 0.0, objs)
    rz0 = 2 * STOREY
    place("Roof_RoundTiles_6x8", (0.0, 0.0, rz0), 0.0, objs)
    gable(objs, {"eave_x": 4.1249 - 0.25, "eave_z": rz0 - 0.55,
                 "ridge_z": rz0 + 4.60, "length": 9.55}, thick=0.30)
    place("Prop_Chimney", (W / 2.0 - 1.0, D / 2.0 - 1.2, rz0), 0.0, objs)
    core = list(objs)
    rack = spear_rack(objs, x=-2.05, y=-D / 2.0 - 0.44, rz=0.0, tier=2)
    brazier(objs, x=2.05, y=-D / 2.0 - 0.82, tier=2)
    bench(objs, x=1.05, y=-D / 2.0 - 0.52, rz=0.0, tier=2)
    # THE DRILL YARD, east. Dirt, not gravel - the gravel is t3's receipt.
    yx = W / 2.0 + 3.80
    dummy(objs, x=yx - 1.30, y=0.90, rz=0.25, tier=2)
    dummy(objs, x=yx + 1.40, y=-0.60, rz=-0.40, tier=2)
    # PASS 1 put this at yx+2.70 = 9.5 m east of centre with bare dirt between
    # it and the house: on the sheet it read as a stray pole standing in a
    # field, and the see-through gate caught the consequence - t2 at 30.9%
    # holes against t3's 12.5%, because the pole widened the silhouette box
    # over an EMPTY yard. Brought in to the yard's near corner so it belongs to
    # the barracks, and raised to clear the eave the way t3's do.
    flagpole(objs, x=W / 2.0 + 1.30, y=-1.90, tier=2, h=7.2)
    fence_run(objs, W / 2.0 + 0.40, yx + 3.60, -3.40, 3)
    barrel(objs, x=W / 2.0 + 0.95, y=-2.70, rz=0.0, tier=2)
    return {"footprint_m": [W, D], "storeys": 2,
            "door_xy": [0.0, -D / 2.0], "core": core, "rack": rack}


def barracks_t3(objs):
    """TIER 3 - THE GARRISON. Raised in stone, walked, and kept.

    6 x 10 m, TWO storeys. Content's crier is "The Garrison is RAISED IN
    STONE", so `Wall_UnevenBrick_*` ALL THE WAY UP - deliberately unlike the
    inn's "stone below, beam above", because the words are different and the
    words are the spec. Item by item:
      "a stone barracks"        -> uneven brick, both storeys, brick corners.
      "a gravelled yard"        -> `yard_border`: kit floor inside MI_RockTrim
                                   edging, 4x3 bays.
      "archers on the roof"     -> `roof_walk`, a railed hoarding on both eaves
                                   with an exterior stair up. THE ARCHERS ARE
                                   NOT A MESH - see the module docstring.
      "E3PO's post on the wall" -> `sentry_post` on the yard wall. THE SENTRY
                                   IS NOT A MESH either.
    Plus the full dressing: 8 spears and a bill, three dummies, TWO flags, a
    wagon, crates, two chimneys. NOTHING is patched and NOTHING is lashed."""
    # *** PASS 1 PICKED THESE OFF THEIR NAMES AND t3 DID NOT READ AS STONE.
    # `Wall_UnevenBrick_Window_Wide_Round` is named for its window TRIM: the
    # field around the opening renders as PLASTER, near-identical in value to
    # t2's plaster wall. Pass 1 put three on each of the east and west
    # ground-storey runs, so from every angle except dead front the garrison's
    # ground floor was TAN, not grey - against a crier that says "The Garrison
    # is RAISED IN STONE". Same fault class as the hall's
    # `Wall_Plaster_WoodGrid`, picked off the name "timber-framed" and found to
    # be an open lattice. PICK A MODULE OFF WHAT IT LOOKS LIKE, NOT OFF WHAT IT
    # IS CALLED - I had that warning in this very file's header and still did
    # it. Fix: the ground storey is SOLID uneven brick on all four runs bar the
    # door, with a thin round slit for light. A garrison's ground floor has
    # arrow slits, not wide windows. The glazing lives upstairs.
    WINB = "Wall_UnevenBrick_Window_Wide_Round"
    SLIT = "Wall_UnevenBrick_Window_Thin_Round"
    def pick(side, i, s):
        if s == 0:
            if side == 'S' and i == 1:
                return "Wall_UnevenBrick_Door_Round"
            if side in 'EW' and i == 2:
                return SLIT
            return "Wall_UnevenBrick_Straight"
        if side in 'EW' and i in (1, 2, 3):
            return WINB
        if side == 'S' and i in (0, 2):
            return WINB
        return "Wall_UnevenBrick_Straight"
    W, D = wall_box(objs, 3, 5, 2, pick, "Corner_ExteriorWide_Brick")
    for j in (1, 2, 3):                 # shutters on the UPPER range only now
        y = -D / 2.0 + GRID / 2.0 + j * GRID
        place("WindowShutters_Wide_Round_Open", (-W / 2.0, y, STOREY), math.pi / 2.0, objs)
        place("WindowShutters_Wide_Round_Open", (W / 2.0, y, STOREY), -math.pi / 2.0, objs)
    rz0 = 2 * STOREY
    place("Roof_RoundTiles_6x10", (0.0, 0.0, rz0), 0.0, objs)
    gable(objs, {"eave_x": 4.1249 - 0.25, "eave_z": rz0 - 0.55,
                 "ridge_z": rz0 + 4.60, "length": 11.72}, thick=0.30)
    for sy in (-1, 1):
        place("Prop_Chimney", (W / 2.0 - 1.0, sy * (D / 2.0 - 1.4), rz0), 0.0, objs)
    # THE ROOF WALK is part of the BUILDING, so it is inside `core` - the pivot
    # must account for it, and `half` must cover it. The yard is not.
    walk = roof_walk(objs, eave_z=rz0 - 0.30, d_mods=5, d=D)
    # *** THE STAIR IS AN APPENDAGE, NOT CORE, AND PUTTING IT IN CORE MOVED THE
    # DOOR. *** It stands outboard of the roof eave on the +X side only, so
    # including it in `core` dragged the core centre 1.19 m east and the
    # re-centre then shoved the whole garrison west by the same amount - which
    # put the door at x = -1.1886 while t1 and t2 have it at 0. The pivot
    # contract says a tier swap changes the MESH only, "never pos, yaw, door or
    # half", so on upgrade from t2 the door would have JUMPED 1.19 m sideways.
    # The walk stays in core because it is symmetric about x=0 and `half` must
    # cover it; the stair, the yard and the dressing do not.
    core = list(objs)
    place("Stairs_Exterior_Straight", (ROOF_EAVE_X + 1.30, D / 2.0 - 1.0, 0.0),
          -math.pi / 2.0, objs)
    rack = spear_rack(objs, x=-2.10, y=-D / 2.0 - 0.46, rz=0.0, tier=3)
    brazier(objs, x=2.15, y=-D / 2.0 - 0.84, tier=3)
    bench(objs, x=1.10, y=-D / 2.0 - 0.52, rz=0.0, tier=3)
    # PASS 1 flew these at h=5.2, which is UPPER-STOREY height - from the
    # three-quarter view they read as two banners nailed to the wall, not as
    # flags. A garrison's colours are seen over the roof or they are not seen.
    # h=8.4 puts the cloth above the eave (rz0 = 6.245) and clear of the wall
    # behind it; they move out to the building's corners.
    for s in (-1, 1):                               # TWO flags, flanking
        flagpole(objs, x=s * 3.35, y=-D / 2.0 - 1.30, tier=3, h=8.4)
    # THE GRAVELLED YARD, east, with the post on its wall
    yx = W / 2.0 + 4.40
    yard_border(objs, cx=yx, y0=1.60, nx=4, ny=3)
    for dx, dy, dr in ((-2.20, 0.70, 0.18), (0.30, -0.40, -0.30), (2.60, 0.90, 0.46)):
        dummy(objs, x=yx + dx, y=dy, rz=dr, tier=3)
    sentry_post(objs, x=yx + 3.95, y=-2.20)
    place("Prop_Wagon", (yx - 2.80, -3.40, 0.0), 0.12, objs)
    place("Prop_Crate", (yx + 1.40, -3.60, 0.0), 0.35, objs)
    place("Prop_Crate", (yx + 0.80, -4.10, 0.0), 0.05, objs)
    fence_run(objs, W / 2.0 + 0.40, yx + 2.80, -4.70, 4)
    return {"footprint_m": [W, D], "storeys": 2,
            "door_xy": [0.0, -D / 2.0], "core": core, "rack": rack,
            "walk": walk}


BUILDERS = {"barracks_t1": barracks_t1, "barracks_t2": barracks_t2,
            "barracks_t3": barracks_t3}


# ---------------------------------------------------------------------------
# RACK SEEN - the one instrument this file adds.
# ---------------------------------------------------------------------------
# WHY. Every gate inherited from the inn can go GREEN over a barracks whose
# rack is INVISIBLE - swallowed by the wall it leans on, the way the inn's
# board was swallowed by the plaster at 0.034 luma separation and the way the
# 17 Nov head glow reported `head_glow_px: 156` beside "the head has no face at
# all". `solidity` would not see it (a rack against a wall is not a hole),
# `subject_moved_px` would not see it (the building moved plenty), and the
# ladder gate would not see it (the silhouette is the building's). And the rack
# is the ONLY piece that makes this family a barracks rather than a house: if
# it does not read, the item is defeated whatever the sheet looks like.
#
# THE TEST ASKS THE VIEWER'S QUESTION, not a size question. `mask_of` - render
# the rack ALONE - answers how BIG the rack is and says nothing about whether
# it can be SEEN, which is the exact error of 17 Nov. So: render the tier WITH
# the rack and WITHOUT it through ONE camera, with the building, ground and
# hero all in place, and count the pixels that MOVED. The renderer does the
# depth. A rack hidden behind the wall moves nothing and goes RED.
#
# RED ON EMPTY: a tier whose rack list is empty returns -1, not 0, because a
# metric over zero objects reads comfortable and means nothing.
#
# WHAT IT CANNOT SEE, SAID BEFORE THE NUMBERS:
#   - COLOUR. A rack that is visible but the wrong brown passes.
#   - WHETHER IT READS AS A RACK. Eight visible sticks could be a fence.
#   - whether the spears are IN their slots. The t1 lean is geometry I
#     authored, not something this measures.
#   - anything on the back and side views; it is run on the FRONT camera only,
#     because the rack is on the frontage by design.
RACK_FLOOR_PX = 700
RACK_FLOOR_H_PX = 60
# The walk is ten 2 m balcony modules read at a shallow angle, so it is a long
# thin thing: an AREA floor is the right shape of question here and 1200 px is
# about a fifth of what an unoccluded gallery measures. Pass 1's occluded walk
# would have scored at or near zero.
WALK_FLOOR_PX = 1200


def rack_seen(scene, rack, path_with, path_without):
    if not rack:
        return {"px": -1, "h_px": -1, "red_on_empty": True}
    scene.render.filepath = path_with
    bpy.ops.render.render(write_still=True)
    was = [o.hide_render for o in rack]
    for o in rack:
        o.hide_render = True
    scene.render.filepath = path_without
    bpy.ops.render.render(write_still=True)
    for o, w in zip(rack, was):
        o.hide_render = w
    box = T.moved_box(path_with, path_without)
    box["red_on_empty"] = False
    return box


def build(key, px, errs):
    """Build one tier and GATE the pivot contract rather than record it."""
    objs = []
    meta = BUILDERS[key](objs)
    H.trim_materials(px)
    bpy.context.view_layer.update()
    # THE PIVOT IS THE BUILDING'S CENTRE, NOT THE ASSEMBLY'S. The yard only
    # extends east; re-centring on everything would drag the barracks off the
    # spawn point and make it JUMP on upgrade, which is the exact defect a
    # tiered family exists to avoid.
    core = meta.pop("core", None) or objs
    rack = meta.pop("rack", None) or []
    # `walk` is a LIST OF OBJECTS and must leave `meta` before the report is
    # serialised - it is an instrument handle, not a recorded number.
    walk = meta.pop("walk", None) or []
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
        "n_rack_obj": len(rack),
        "n_walk_obj": len(walk),
    })
    if abs(ccx) > 0.001 or abs(ccy) > 0.001:
        errs.append("%s PIVOT DRIFT: core centre (%0.4f, %0.4f) not at origin"
                    % (key, ccx, ccy))
    if abs(base) > 0.001:
        errs.append("%s PIVOT DRIFT: base z %0.4f not on the ground" % (key, base))
    # *** THE DOOR GATE - AND I NEEDED IT, HAVING WRITTEN THE HEADER THAT SAYS
    # WHY. *** This file's docstring charges `hallgen.build` with measuring
    # `core_centre_dx_dy` and `base_dz_m` and never reading them, and then
    # `build()` went and did exactly that with `door_xy_after_recentre`: pass 1
    # printed -0.5262 for t3, pass 2 printed -1.1886, and the verdict was GREEN
    # both times. A tiered family exists so the door does not move; the one
    # number that says whether it moved was sitting unread in my own report.
    # 0.05 m, not 0.001: the wall modules are not centred in Y (min y -0.0924)
    # and t1's door legitimately lands at -0.0122, so an exact gate would fire
    # on a correct tier. 0.05 is four times that residue and forty times under
    # the drift it is here to catch.
    dx_door = round(meta["door_xy_after_recentre"][0], 4)
    if abs(dx_door) > 0.05:
        errs.append("%s DOOR DRIFT: door x %0.4f after re-centre, not on the "
                    "pivot - it would JUMP sideways on a tier swap" % (key, dx_door))
    if not rack:
        errs.append("%s RED ON EMPTY: builder returned no rack objects" % key)
    if key == "barracks_t3" and not walk:
        errs.append("%s RED ON EMPTY: builder returned no roof-walk objects" % key)
    return objs, meta, rack, walk


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
    root = os.path.join(a.repo, "renders", "art", "town", "barracks")
    glbdir = os.path.join(a.repo, "assets", "buildings")
    os.makedirs(root, exist_ok=True)
    os.makedirs(glbdir, exist_ok=True)
    rep = {"when_ct": "28 Nov 2026 12:4x-13:2x CT", "tiers": {}, "errors": [],
           "px": a.px, "maxmb": a.maxmb, "growth": "free",
           "why_free": ("t2 and t3 are both two storeys under the same 8.25 m-span "
                        "tile roof family, so both ridge at wall_top+4.89 and the "
                        "silhouette height does not grow t2->t3. The progression is "
                        "material (plaster->uneven brick ALL THE WAY UP, because "
                        "content's crier is 'raised in stone', not the inn's 'stone "
                        "below, beam above'), length, yard and dressing. The "
                        "monotonic gate is NOT carrying this sheet; my eye is."),
           "see_through_cap": SEE_THROUGH_CAP,
           "not_meshed_on_purpose": [
               "archers on the roof - an archer is an NPC. t3 carries the railed "
               "roof walk they would stand on; the figures are the game build's.",
               "E3PO's post on the wall - likewise. t3 carries the post; the "
               "sentry is not baked into a static landmark .glb.",
               "smoke from the chimneys - VFX, not geometry."]}

    for key in keys:
        G.purge()
        H._PROTO.clear()
        scene, eng = T.scene_setup(a.resx, a.resy)
        objs, meta, rack, walk = build(key, a.px, rep["errors"])
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

        # RACK SEEN, front camera, building+ground+hero all present.
        T.aim_cam(cam, cam_d, pts, center, radius, 0.0, 10.0, a.resx, a.resy)
        rs = rack_seen(scene, rack, os.path.join(outd, "_rack_with.png"),
                       os.path.join(outd, "_rack_without.png"))
        meta["rack_seen_front"] = rs
        if rs.get("red_on_empty"):
            rep["errors"].append("%s RACK SEEN RED ON EMPTY: no rack objects" % key)
        elif rs["px"] < RACK_FLOOR_PX:
            rep["errors"].append(
                "%s RACK NOT SEEN: only %d px moved, floor %d - the piece that "
                "makes this a barracks is invisible" % (key, rs["px"], RACK_FLOOR_PX))
        elif rs["h_px"] < RACK_FLOOR_H_PX:
            rep["errors"].append(
                "%s RACK NOT LEGIBLE: only %d px tall, floor %d"
                % (key, rs["h_px"], RACK_FLOOR_H_PX))
        for junk in ("_rack_with.png", "_rack_without.png"):
            try:
                os.remove(os.path.join(outd, junk))
            except Exception:
                pass

        # *** WALK SEEN - the gate pass 1 did not have and needed. ***
        # Measured on the THREE-QUARTER view, not the front: a gallery along
        # the east and west eaves is edge-on from dead front and would score
        # low for a reason that is geometry, not occlusion. Three-quarter is
        # also the view in which I SAW it was missing, so the instrument is
        # asked the same question my eye was. RED ON EMPTY on an empty list.
        # WHAT IT CANNOT SEE: whether the walk reads as a WALK rather than as
        # a smear along the roofline, and anything about the stair that
        # reaches it. Both are eye questions and I answer them in the summary.
        if walk:
            meta["walk_x_m"] = round(ROOF_EAVE_X - 0.55, 4)
            meta["roof_eave_x_m"] = ROOF_EAVE_X
            T.aim_cam(cam, cam_d, pts, center, radius, 38.0, 14.0, a.resx, a.resy)
            ws = rack_seen(scene, walk, os.path.join(outd, "_walk_with.png"),
                           os.path.join(outd, "_walk_without.png"))
            meta["walk_seen_three_quarter"] = ws
            if ws["px"] < WALK_FLOOR_PX:
                rep["errors"].append(
                    "%s ROOF WALK NOT SEEN: only %d px moved, floor %d - pass 1 "
                    "hid it under the 1.02 m eave overhang and every other gate "
                    "passed it" % (key, ws["px"], WALK_FLOOR_PX))
            for junk in ("_walk_with.png", "_walk_without.png"):
                try:
                    os.remove(os.path.join(outd, junk))
                except Exception:
                    pass
            T.aim_cam(cam, cam_d, pts, center, radius, 0.0, 10.0, a.resx, a.resy)

        # SEE-THROUGH, subject alone through the front camera. Ground and hero
        # hidden - both would sit behind the walls and FILL the holes this is
        # trying to find.
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
        cap = SEE_THROUGH_CAP[key]
        meta["see_through_cap"] = cap
        if sol["red_on_empty"]:
            rep["errors"].append("%s SOLIDITY RED ON EMPTY: silhouette %d px"
                                 % (key, sol["silhouette_px"]))
        elif sol["hole_frac"] > cap:
            rep["errors"].append(
                "%s SEE-THROUGH: %0.1f%% of the front silhouette box is holes, "
                "cap %0.0f%%" % (key, sol["hole_frac"] * 100.0, cap * 100.0))
        meta["views"] = vrep
        rep["tiers"][key] = meta

    # ------------------------------------- THE SHEET: three tiers, ONE camera
    if len(keys) == len(ORDER):
        G.purge()
        H._PROTO.clear()
        RX, RY = 1860, 820
        scene, eng = T.scene_setup(RX, RY)
        placed, racks, spans, x = {}, {}, [], 0.0
        for key in ORDER:
            objs, _m, rack, _w = build(key, a.px, rep["errors"])
            mn, mx, _ = G.world_bounds(objs)
            for o in objs:
                o.location = (o.location.x + (x - mn.x),
                              o.location.y - (mn.y + mx.y) / 2.0,
                              o.location.z - mn.z)
            bpy.context.view_layer.update()
            w = mx.x - mn.x
            placed[key] = objs
            racks[key] = rack
            spans.append((key, x, x + w))
            x += w + 4.0                 # 4.0 m - at less the tiers read as ONE
        hero, _ = T.add_hero(dx=x + 0.8)
        bpy.context.view_layer.update()
        hmn, hmx, _ = G.world_bounds(hero)
        total = hmx.x
        gnd = T.ground_plane(total + 4.0, 34.0, cx=total / 2.0)
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

        # *** THE RACK LADDER - the only number that can honestly say the WEAR
        # reads, and it is only valid HERE. On the per-tier sheets each tier has
        # its own ortho scale, so 3 spears at one scale can move more pixels
        # than 8 at another; comparing them would be the "instrument that cannot
        # move" fault. On THIS sheet all three share one ortho camera and one
        # scale, so a rack that grows 3 -> 6 -> 8+bill MUST move more pixels at
        # each step. If it does not, either a rack is occluded or two tiers got
        # the same rack. WHAT IT CANNOT SEE: whether the growth is LEGIBLE to a
        # viewer, only that it is measurable.
        rack_sheet = {}
        for key in ORDER:
            rw = os.path.join(root, "_rackw_%s.png" % key)
            rn = os.path.join(root, "_rackn_%s.png" % key)
            rack_sheet[key] = rack_seen(scene, racks[key], rw, rn)
            for junk in (rw, rn):
                try:
                    os.remove(junk)
                except Exception:
                    pass
        rpx = [rack_sheet[k].get("px", -1) for k in ORDER]
        if any(v < 0 for v in rpx):
            rep["errors"].append("RACK LADDER RED ON EMPTY: %s"
                                 % dict(zip(ORDER, rpx)))
        elif not all(rpx[i] < rpx[i + 1] for i in range(len(rpx) - 1)):
            rep["errors"].append(
                "RACK LADDER NOT MONOTONIC: 3 -> 6 -> 8+bill spears must move "
                "more pixels at each step under ONE camera, measured %s"
                % dict(zip(ORDER, rpx)))

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
        G.draw_text(buf, "BELLMIRE - THE BARRACKS, TIER 1 TO 3. EXTERIOR ONLY. ONE PIVOT, ONE CAMERA, ONE ORTHO SCALE.",
                    14, 12, scale=2)
        G.draw_text(buf, "HERO = KAYKIT KNIGHT, IDLE FRAME 1, STANDS 2.453 M TO THE HELMET. PACK STOREY 3.1227 M.",
                    14, 34, scale=2)
        G.draw_text(buf, "T2/T3 ARE THE SAME HEIGHT ON PURPOSE - 'RAISED IN STONE' IS A MATERIAL, NOT A THIRD STOREY. THE LADDER GROWS BY STONE, LENGTH AND YARD.",
                    14, 56, scale=2)
        G.draw_text(buf, "THE RACK IS THE WEAR: 3 SPEARS AND ONE OUT OF ITS SLOT / 6 SQUARE / 8 AND A BILL. ARCHERS AND E3PO ARE NOT MESHES - T3 CARRIES THEIR WALK AND POST.",
                    14, 78, scale=2)
        G.draw_text(buf, "RACK/BRAZIER/DUMMY/FLAG/SENTRY-POST AUTHORED - THE MEGAKIT'S 176 MODULES HAVE NONE OF THEM. WALLS/ROOF/FLOOR/FENCE/BALCONY/WAGON/BORDER = MEGAKIT, CC0.",
                    14, 100, scale=2)
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
                        "silhouette": sil, "rack_seen": rack_sheet,
                        "spans": [[s[0], round(s[1], 3), round(s[2], 3)] for s in spans]}
        rep["engine"] = eng

    rep["verdict"] = "GREEN" if not rep["errors"] else "RED"
    with open(os.path.join(root, "_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("BARRACKSGEN " + json.dumps({"verdict": rep["verdict"],
                                       "errors": rep["errors"],
                                       "tiers": {k: v.get("dims_m")
                                                 for k, v in rep["tiers"].items()}}))


if __name__ == "__main__":
    main()
