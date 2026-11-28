"""townbuild - TOWN BUILDING ASSETS FOR THE PROGRESSION TIERS.

  blender -b -noaudio -P tools/art/townbuild.py -- --repo <repo> [--only well_t1]

28 Nov 2026, 00:5x CT. Art lane. The row (plan, TAKE THIS NEXT, ART :34):
the tier-1/2/3 variants of ONE building - the town square's well -> fountain,
named in Systems 15-17 - proven to fit the way gear is proven.

*** WEAR IS THE SPEC, NOT A BACKGROUND PRINCIPLE (Mr. E, art rule 2). ***
A tier-1 Bellmire is patched and make-do; a tier-3 is cut stone and fresh
timber. Condition is the RECEIPT for what the town paid for. So every
difference between these three is a CONDITION difference driven by `tier`,
authored off one shared footprint - not three unrelated props.

*** PLAINNESS IS THE VOICE (art rule 1). *** No gothic flourish. A well is a
hole with a lip, two posts and a bucket, because that is what it is FOR.
Read the epitaphs in data/lore_lines.json: "Measured the grain. Counted the
flasks. Kept the door."

WHY ALL THREE ARE AUTHORED AND NOT DERIVED FROM A PACK - MEASURED, THEN LOOKED
AT, AND THE PICTURE IS WHY (`_townwell_probe.py`, sheet
`renders/art/town/_probe/_kenney_fountain_candidates.png`):
  - `assets/` holds NO well and NO fountain mesh. Three icon PNGs carry the
    word `wellhead`; that is all. Measured, not remembered.
  - Wells exist in `low-poly_RPG_item_collection_3` and
    `modular_village_collection` and BOTH ARE IMPORT-GATED on licence. I walked
    the second folder myself this run: 147 files, ZERO text files of any kind,
    so there is no README carrying terms either. Gated stays gated.
  - The one CLEARED town-square candidate is Kenney Fantasy Town Kit 2.0
    (CC0 1.0, licence read off disk 24 Nov, ASSET_SOURCES line 803). Its ten
    `fountain-*` pieces measure 2.00 x 2.00 x **0.28** m (`fountain-round`) and
    at best 2.00 x 2.00 x **0.48** m (`-detail`). *** THEY ARE FLOOR TILES FOR A
    2 M GRID, NOT A TOWN-SQUARE FOUNTAIN. *** Against the 1.80 m bar in that
    sheet they are ankle to knee height. A fountain the stream cannot see cannot
    carry "the town levelled up", which is the entire point of the item
    (sup-nov27-2304). REJECTED ON READ, NOT ON LICENCE - the pack is cleared and
    stays available for roads, walls and stalls.

PIVOT CONTRACT, AND IT IS THE WHOLE WIRING STORY: all three tiers share ONE
pivot - the centre of the footprint, at ground level, z = 0, base_dz_m = 0.0.
The game build swaps the mesh at a single unmoved spawn point.

*** SIZED AGAINST THE BODY I MEASURED, NOT AGAINST A MAN. ***
`_townhero_measure.py` on `Knight.glb` this run. The AABB over all 16 meshes
reads 1.94 x 3.09 x 3.45 with min_z -1.0 and IT IS A LIE - it spans the hidden
equipment variants, not the body. The BONES are the body, and they agree with
the numbers already in `scripts/gear.gd` to two decimals:

    foot.l z 0.1452 | hips 0.3916 | spine 0.5836 | chest 0.9586 | head 1.2274

*** AND THE FIGURE IS NOT 1.30 TALL - I GOT THAT WRONG FIRST AND THE MESH
*** NAMES CORRECTED ME. *** gear.gd's "body top 1.30" is the TORSO: the mesh
`Knight_Body` measures z 0.363-1.279, which is where 1.30 comes from. Above it
sit `Knight_Head` (z 1.202-2.301) and `Knight_Helmet` (z 1.101-**2.453**). So
the adventurer STANDS 2.45 WITH THE HELMET and is extremely chibi - the head is
nearly as tall as the body. The 2.45 figure in `_d96fix_sheet.py` was right all
along and my own first reading of it was the suspect.

WHICH NUMBER SIZES WHAT, AND WHY THE WELL DID NOT CHANGE AGAIN:
  - INTERACTION heights come off the BONES, which the head does not touch:
    hips 0.3916 sets the coping a man leans on; hands at z 0.73 must reach it.
    Those are unaffected by the correction, so 0.42 / 0.52 stand.
  - SILHOUETTE comes off the whole 2.45 figure, and that is why the tier-2
    roof ridge is at 2.08 - a well-house that reads at the figure's own height.
An earlier draft used 0.76 for the tier-2 coping off a remembered "1.8 m hero".
On this body that is above the torso top and the well would have read as a
water tank. Measured, not remembered, twice, and it changed the model once.
"""
import math, random

import lordlib as L
from lords import Parts, aim

TAU = math.pi * 2.0

# ---------------------------------------------------------------- the palette
# Slots are shared across tiers so the three read as one family. The WEAR lives
# in the colour as well as in the geometry: tier 1 stone is grey-brown and
# desaturated, tier 3 stone is pale cut ashlar. Never give a whole set one wear.
PAL = {
    1: {'stone': (0.33, 0.31, 0.27), 'stone2': (0.28, 0.26, 0.23),
        'wood':  (0.40, 0.37, 0.31), 'iron': (0.20, 0.19, 0.18),
        'rope':  (0.52, 0.46, 0.33), 'water': (0.16, 0.22, 0.22),
        'trim':  (0.30, 0.27, 0.22)},
    2: {'stone': (0.46, 0.44, 0.40), 'stone2': (0.40, 0.38, 0.35),
        'wood':  (0.44, 0.31, 0.17), 'iron': (0.13, 0.13, 0.14),
        'rope':  (0.40, 0.33, 0.24), 'water': (0.18, 0.28, 0.30),
        'trim':  (0.33, 0.21, 0.12)},
    3: {'stone': (0.68, 0.66, 0.60), 'stone2': (0.60, 0.58, 0.53),
        'wood':  (0.55, 0.40, 0.22), 'iron': (0.45, 0.32, 0.13),   # bronze
        'rope':  (0.44, 0.36, 0.26), 'water': (0.26, 0.47, 0.52),
        'trim':  (0.52, 0.37, 0.15)},
}

# Mouth: R_IN 0.34 clears the 0.17-radius bucket with room to swing.
R_OUT, R_IN = 0.52, 0.34
# Coping: hips are at 0.3916, so a lip a man can LEAN ON sits just over it.
# Tier 2 gains the cap course, which is why it is the taller of the two.
COPING = {1: 0.42, 2: 0.52}
HEAD_Z = 1.2274                   # measured head bone - nothing may hang below it
BODY_TOP = 1.30


def _ring(P, n, r_out, r_in, z0, z1, slot, rng, jitter, missing=()):
    """A course of dry-laid or coursed stones. `jitter` IS THE WEAR TERM."""
    for i in range(n):
        if i in missing:
            continue
        th = TAU * i / n
        jr = rng.uniform(-jitter, jitter)
        jz = rng.uniform(-jitter * 1.6, jitter * 1.6)
        jy = rng.uniform(-jitter * 2.2, jitter * 2.2)
        rm = (r_out + r_in) / 2.0 + jr
        thick = (r_out - r_in) * (1.0 + rng.uniform(-jitter, jitter) * 2.0)
        wide = TAU * rm / n * 0.92
        h = (z1 - z0) * (1.0 + rng.uniform(-jitter, jitter) * 1.8)
        P.add(L.box(thick, wide, h), slot,
              loc=(rm * math.cos(th), rm * math.sin(th), z0 + h / 2.0 + jz),
              rot=(0.0, 0.0, th + jy))


def _bucket(P, cx, cy, cz, tilt, hoops, rng, slot='wood', hoop_slip=False):
    P.add(L.cone(0.17, 0.20, 0.26, 12), slot, loc=(cx, cy, cz), rot=(tilt, 0.0, 0.0))
    for k in range(hoops):
        z = cz + 0.05 + k * 0.15
        r = 0.175 + k * 0.018
        off = 0.035 if (hoop_slip and k == hoops - 1) else 0.0
        P.add(L.cone(r + 0.012, r + 0.012, 0.022, 12), 'iron',
              loc=(cx + off, cy, z), rot=(tilt, 0.0, 0.0))


def _shingles(P, rng, peak_z, half_w, length, slot, pitch):
    """Two slopes of overlapping shingle rows. Tier 2 only - a KEPT roof."""
    rows = 7
    for side in (-1, 1):
        for i in range(rows):
            t = i / float(rows - 1)
            y = side * half_w * (1.0 - t)
            z = peak_z - (1.0 - t) * 0.0 - t * 0.0
            # walk down the slope from the ridge
            yy = side * half_w * t
            zz = peak_z - abs(yy) * pitch
            P.add(L.box(length, half_w / rows * 1.35, 0.045), slot,
                  loc=(0.0, yy, zz - 0.02), rot=(side * -math.atan(pitch), 0.0, 0.0))


# ------------------------------------------------------------------ the tiers
def well_t1():
    """TIER 1 - THE HOLE WITH A LIP. Patched and make-do.

    Dry-laid, two stones gone from the course, posts crooked and barked, the
    crossbeam a branch lashed with rope because there is no iron, the lid two
    warped planks that do not meet. Nothing here was bought."""
    P = Parts("well_t1")
    rng = P.rng
    # *** JITTER WAS 0.16 AND IT DESTROYED THE ITEM. *** At 0.16 the height
    # term (jitter * 1.8) swings a 0.42 course between 0.13 and 0.71 and the
    # ring reads as a HEAP OF RUBBLE, not as a dry-laid well with two stones
    # gone - with the poles and the hanging bucket over it the whole thing read
    # as a gibbet. I saw that on the first side-by-side sheet; every gate was
    # GREEN over it, because no gate I have asks "is this still a well". 0.065
    # keeps the course visibly hand-laid and keeps the mouth legible, which is
    # the difference between make-do and derelict.
    _ring(P, 14, R_OUT, R_IN, 0.0, COPING[1], 'stone', rng, jitter=0.065,
          missing=(3, 9))
    # the shaft lining, just visible down the mouth
    P.add(L.cone(R_IN, R_IN, 0.26, 14, cap=False), 'stone2', loc=(0, 0, -0.26))
    # two crooked poles, barked, one leaning. Tops clear the head bone (1.2274)
    # so a man can stand at the well without the beam in his face.
    for s, lean, top in ((-1, 0.10, 1.46), (1, -0.04, 1.39)):
        P.add(L.cone(0.052, 0.042, top, 9), 'wood',
              loc=(0.0, s * (R_OUT - 0.05), 0.0), rot=(s * lean, 0.03, 0.0))
    # a branch for a crossbeam: it SAGS, and it is lashed, not pinned
    pts = [(0.0, -R_OUT + 0.03, 1.40), (0.0, -0.16, 1.355), (0.0, 0.17, 1.335),
           (0.0, R_OUT - 0.04, 1.375)]
    P.raw(L.tube(pts, [0.044, 0.040, 0.038, 0.042], 8), 'wood')
    for yy in (-R_OUT + 0.05, R_OUT - 0.06):
        for k in range(3):
            P.add(L.cone(0.058, 0.058, 0.014, 10), 'rope',
                  loc=(0.0, yy, 1.355 + k * 0.019), rot=(1.5708, 0.0, 0.0))
    # a frayed rope and a tired bucket, hung clear of the coping
    P.add(L.cone(0.009, 0.007, 0.44, 6), 'rope', loc=(0.0, 0.0, 0.90))
    _bucket(P, 0.0, 0.0, 0.70, 0.06, 1, rng, hoop_slip=True)
    # a half lid of two warped planks that do not meet
    for i, (yy, tw) in enumerate(((-0.22, 0.20), (-0.01, 0.17))):
        P.add(L.box(0.98, tw, 0.030), 'wood',
              loc=(0.0, yy, COPING[1] + 0.018 + i * 0.004),
              rot=(rng.uniform(-0.05, 0.05), rng.uniform(-0.03, 0.03), 0.04))
    # loose spoil: the stones that fell out of the course, left where they fell
    for i in range(5):
        th = rng.uniform(0, TAU)
        d = rng.uniform(0.70, 1.05)
        P.add(L.box(rng.uniform(0.11, 0.18), rng.uniform(0.09, 0.15), 0.075), 'stone2',
              loc=(d * math.cos(th), d * math.sin(th), 0.038), rot=(0, 0, rng.uniform(0, TAU)))
    return P


def well_t2():
    """TIER 2 - THE WELL KEPT. Coursed, capped, roofed, and worked by a winch.

    The town has spent on it: the course is level and capped, the posts are
    squared and strapped with iron, there is a windlass instead of a hand over
    hand rope, and a shingled roof keeps the rain out of the water."""
    P = Parts("well_t2")
    rng = P.rng
    _ring(P, 16, R_OUT, R_IN, 0.0, COPING[2] - 0.08, 'stone', rng, jitter=0.035)
    # the cap course: flat, even, and the tell that somebody dressed this stone
    P.add(L.cone(R_OUT + 0.04, R_OUT + 0.04, 0.08, 24), 'stone2',
          loc=(0, 0, COPING[2] - 0.08))
    P.add(L.cone(R_IN - 0.015, R_IN - 0.015, 0.10, 20, cap=False),
          'stone2', loc=(0, 0, COPING[2] - 0.09))
    P.add(L.cone(R_IN, R_IN, 0.30, 16, cap=False), 'stone2', loc=(0, 0, -0.30))
    # squared posts, plumb, iron-strapped
    for s in (-1, 1):
        P.add(L.box(0.10, 0.10, 1.62), 'wood', loc=(0.0, s * (R_OUT - 0.01), 0.81))
        for z in (0.46, 1.10):
            P.add(L.box(0.122, 0.122, 0.05), 'iron', loc=(0.0, s * (R_OUT - 0.01), z))
    # the windlass: a drum, an axle, a cranked handle, iron pins. The axle sits
    # at 1.12, below the head bone at 1.2274, so the crank is at working height.
    P.add(aim(L.cone(0.082, 0.082, 0.84, 12), (0.0, -0.42, 1.12), (0.0, 1.0, 0.0)), 'wood')
    P.add(aim(L.cone(0.022, 0.022, 1.10, 8), (0.0, -0.55, 1.12), (0.0, 1.0, 0.0)), 'iron')
    P.add(aim(L.cone(0.026, 0.026, 0.13, 8), (0.0, 0.55, 1.12), (0.0, 1.0, 0.0)), 'iron')
    P.add(aim(L.cone(0.022, 0.022, 0.17, 8), (0.0, 0.66, 1.12), (0.0, 0.0, 1.0)), 'iron')
    P.add(aim(L.cone(0.024, 0.024, 0.10, 8), (0.05, 0.66, 1.27), (1.0, 0.0, 0.0)), 'wood')
    # rope wound ON the drum, and a sound bucket hanging off it
    for k in range(5):
        P.add(aim(L.cone(0.092, 0.092, 0.028, 10), (0.0, -0.16 + k * 0.065, 1.12),
                  (0.0, 1.0, 0.0)), 'rope')
    P.add(L.cone(0.010, 0.010, 0.30, 6), 'rope', loc=(0.0, 0.07, 0.83))
    _bucket(P, 0.0, 0.07, 0.65, 0.0, 2, rng)
    # ridge and a shingled gable that actually sheds. Ridge 2.08; the eave over
    # the coping edge lands at 2.08 - 0.70*0.62 = 1.65, clear of BODY_TOP 1.30.
    P.add(L.box(1.22, 0.07, 0.07), 'trim', loc=(0.0, 0.0, 2.08))
    _shingles(P, rng, 2.06, 0.70, 1.18, 'trim', pitch=0.62)
    for s in (-1, 1):   # barge boards, so the roof has an EDGE from the side
        P.add(L.box(0.055, 1.46, 0.08), 'wood', loc=(s * 0.59, 0.0, 1.85),
              rot=(0.0, 0.0, 0.0))
    # a cobble apron: the square has been paved round it
    for i in range(20):
        th = TAU * i / 20 + 0.08
        P.add(L.box(0.24, 0.17, 0.055), 'stone2',
              loc=(0.92 * math.cos(th), 0.92 * math.sin(th), 0.027), rot=(0, 0, th))
    return P


def well_t3():
    """TIER 3 - THE FOUNTAIN. Cut stone, bronze, and running water.

    The shaft is capped and piped; what the square has now is a basin a man can
    sit on, a carved column, four bronze spouts and water. Nothing is patched,
    nothing is lashed, and the stone is DRESSED - jitter is zero, because a
    fountain that wobbles reads as a wall somebody stacked."""
    P = Parts("well_t3")
    rng = P.rng
    # two kerb steps - the footprint grows, which is half of how a tier reads
    P.add(L.cone(1.26, 1.23, 0.10, 32), 'stone2', loc=(0, 0, 0.0))
    P.add(L.cone(1.10, 1.08, 0.11, 32), 'stone2', loc=(0, 0, 0.10))
    # the basin wall: dressed ashlar, NO jitter. Cap at 0.43 is just over the
    # hip bone at 0.3916 - a rim the town can SIT on, which is what it is for.
    _ring(P, 24, 0.94, 0.78, 0.21, 0.43, 'stone', rng, jitter=0.0)
    P.add(L.cone(0.975, 0.975, 0.065, 32), 'stone', loc=(0, 0, 0.43))   # moulded cap
    P.add(L.cone(0.78, 0.78, 0.22, 28, cap=True), 'stone2', loc=(0, 0, 0.21))
    # water: a disc below the cap, so the rim reads as holding it
    P.add(L.cone(0.775, 0.775, 0.012, 30), 'water', loc=(0, 0, 0.385))
    # the centre: pedestal, column, upper bowl, finial
    P.add(L.cone(0.33, 0.30, 0.16, 8), 'stone', loc=(0, 0, 0.385))
    P.add(L.cone(0.285, 0.245, 0.075, 8), 'stone2', loc=(0, 0, 0.545))
    P.add(L.cone(0.150, 0.132, 0.56, 12), 'stone', loc=(0, 0, 0.62))
    for k in range(3):                                   # carved bands
        P.add(L.cone(0.162 - k * 0.009, 0.162 - k * 0.009, 0.033, 12), 'stone2',
              loc=(0, 0, 0.74 + k * 0.185))
    P.add(L.cone(0.37, 0.40, 0.12, 16), 'stone', loc=(0, 0, 1.18))     # upper bowl
    P.add(L.cone(0.355, 0.355, 0.014, 16), 'water', loc=(0, 0, 1.265))
    P.add(L.cone(0.10, 0.085, 0.19, 10), 'stone', loc=(0, 0, 1.30))
    P.add(L.cone(0.072, 0.0, 0.15, 10), 'iron', loc=(0, 0, 1.49))      # bronze finial
    # four bronze spouts, and the water they throw
    for i in range(4):
        th = TAU * i / 4 + math.pi / 4.0
        c, s = math.cos(th), math.sin(th)
        P.add(aim(L.cone(0.032, 0.024, 0.21, 8), (0.12 * c, 0.12 * s, 1.09),
                  (c, s, -0.22)), 'iron')
        arc = [(0.33 * c, 0.33 * s, 1.05), (0.50 * c, 0.50 * s, 0.87),
               (0.60 * c, 0.60 * s, 0.58), (0.63 * c, 0.63 * s, 0.39)]
        P.raw(L.tube(arc, [0.022, 0.019, 0.017, 0.015], 7), 'water')
    return P


ORDER = ("well_t1", "well_t2", "well_t3")
BUILDERS = {"well_t1": well_t1, "well_t2": well_t2, "well_t3": well_t3}
CANON = {
    "well_t1": ("The Well",     1, "Dry-laid, two stones gone, a branch for a beam."),
    "well_t2": ("The Well Kept", 2, "Coursed and capped, strapped, winched, roofed."),
    "well_t3": ("The Fountain",  3, "Dressed ashlar, bronze spouts, running water."),
}
