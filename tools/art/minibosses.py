"""minibosses.py - the art lane's own creatures, built under Mr. E's standing
permission of 15 Nov 17:43: "you can always add mini bosses as well. that dont
have to be lore mentioned".

No canon, no bestiary entry, no lore_lines, no content-lane dependency. The bar
is the one he set and it is the only one: ONE IDEA THAT CHANGES THE FIGHT. Not a
normal monster with more hit points. Each of these four is named for what it
DOES, because that is the whole of its character:

  DRILLMASTER  it SUMMONS      - a muster gong worn on its back. It does not
                                 fight you, it calls the barracks to.
  SCRAPWRIGHT  it ARMOURS ITSELF - knock a plate off and it picks another off
                                 the workshop floor. The shell grows.
  GAOLER       it DRAGS        - a hook on a chain. It takes a hero out of the
                                 file and reels them back to itself.
  SNUFFER      it TAKES THE LIGHT - it puts out the room's lamps one at a time
                                 and carries the last one.

dungeon_hd.gd's set-piece slot already has "miniboss" (weight 15 normally, 35 on
barracks/workshop, gated to floor >= 4). Each of these is tagged with the theme
whose weight it was built for, so the slot can prefer the right one.

SILHOUETTE IS THE ACCEPTANCE TEST, same as D75 and D76: with the colour thrown
away each must read as itself, and none may read as a hero. None of these has a
hero body - the Drillmaster is a disc on legs, the Scrapwright is a lopsided
mound, the Gaoler is a hook with a chain coiled on the floor behind it, and the
Snuffer is a lamp-stand that walks.

WEAR IS A VARIABLE (Mr. E's second art rule). These are not viewer gear, so the
receipt argument does not apply - but they must not all be equally rotten. Each
carries its own `wear`, justified by what the thing IS: a working man keeps his
instrument, so the Drillmaster's gong is the brightest object in this file; the
Scrapwright's plate is freshly torn and still bright on an ancient core; the
Gaoler's iron is greased and old; the Snuffer has been down there longest.

Raw vertex maths only (no bpy.ops, no bmesh.ops) - see lordlib - for the first
fifteen: every one of those is original generated geometry.

TWO LINES OF THIS DOCSTRING WERE STALE AND ARE CORRECTED HERE, 17 Nov 2026:
  1. "nothing here reads a third-party asset" is no longer true, on purpose.
     The Quartermaster (16) loads real spear and shield geometry out of
     `assets/gear/` - the CC0 KayKit dungeon bits this repo already carries and
     that gearmodels.py already uses for D95's named weapons, logged in
     docs/art/ASSET_SOURCES.md. The standing rule is to USE WHAT IS ON DISK
     before generating a new mesh, and a quartermaster handing out the same
     spears the heroes carry is the case where that rule pays twice. It falls
     back to procedural geometry if the file will not load, and the report says
     which it used.
  2. "Quaternius Bestiary / QAL is forbidden" - THAT BAN WAS STRUCK by Mr. E on
     16 Nov 22:45 CT, who produced the actual licence: worldwide, royalty-free,
     perpetual, commercial use permitted, no attribution required, the only
     restriction being resale of the assets AS assets. Nothing in this file
     uses it either way; the line is removed so no future run refuses work on
     the strength of it.
"""
import math
import os

from mathutils import Vector, Matrix

import lordlib as L
from lords import Parts, aim
from creatures import surf, limb, arc, eyes, spikes

TAU = math.pi * 2.0

# key: (title, height(m), tint, aura, theme, idea, wear, feed line)
#   theme - the dungeon_hd.gd theme whose miniboss weight this was built for
#   idea  - the one thing that makes the fight different. The bar, in a phrase.
#   wear  - 0 fresh, 1 derelict. Drives roughness, metal and how far the colour
#           is dulled toward the dark. NEVER the same across the set.
CANON = {
    "drillmaster": ("The Drillmaster", 2.20, (0.86, 0.72, 0.38), (1.00, 0.78, 0.34),
                    "barracks", "IT SUMMONS - it beats the muster and the garrison forms up",
                    0.15, "Someone is beating the muster."),
    "scrapwright": ("The Scrapwright", 2.00, (0.70, 0.74, 0.78), (0.78, 0.86, 1.00),
                    "workshop", "IT ARMOURS ITSELF - every plate knocked off is replaced from the floor",
                    0.30, "It is wearing the workshop."),
    "gaoler":      ("The Gaoler", 2.35, (0.52, 0.50, 0.46), (0.95, 0.58, 0.20),
                    "prison", "IT DRAGS - the hook takes one out of the line and reels them in",
                    0.80, "A chain is paying out in the dark."),
    "snuffer":     ("The Snuffer", 2.60, (0.58, 0.60, 0.66), (1.00, 0.86, 0.52),
                    "shrine", "IT TAKES THE LIGHT - it puts out the lamps one at a time",
                    0.90, "The nearest lamp has gone out."),
}
ORDER = ["drillmaster", "scrapwright", "gaoler", "snuffer"]


# ------------------------------------------------- 1 THE DRILLMASTER: a disc
def drillmaster():
    """IT SUMMONS. The mechanic is worn on his back and you can see it from
    across the room: a muster gong on an iron frame and a mallet already raised.

    PASS 2, after looking at the silhouette sheet. Pass 1 hung the gong flat
    across his spine and the disc ATE HIM - the outline was a balloon on two
    legs with a crumb on top, and you could not tell there was a man there or
    that the disc was a gong. So: the gong moved off to his right and down, he
    stepped forward and turned, and the mallet became a long clear diagonal.
    The read is now MAN, DISC BEHIND HIM, HAMMER UP - which is the fight.

    He is a sergeant, not a champion: no crest, no cape, a kettle helm and a
    dun coat. The gong is the only kept thing on him."""
    P = Parts("drillmaster")
    X = -0.30                                   # the man stands left of centre
    # braced stance, short and wide. Boots are blocks so he reads as planted.
    for s in (-1, 1):
        limb(P, [(X + s * 0.21, 0.06, 0.92), (X + s * 0.27, 0.02, 0.50),
                 (X + s * 0.31, -0.06, 0.09)], 0.105, 0.085)
        P.add(L.box(0.26, 0.42, 0.11), 'dark', loc=(X + s * 0.31, -0.14, 0.055))
    # barrel torso, turned a quarter and leaning out of the disc's outline
    limb(P, [(X, 0.12, 0.86), (X - 0.05, 0.00, 1.18), (X - 0.12, -0.12, 1.44)], 0.26, 0.27)
    P.add(L.box(0.62, 0.30, 0.10), 'dark', loc=(X - 0.02, -0.08, 1.06))      # belt
    for s in (-1, 1):                                                        # shoulders
        P.add(L.sphere(0.17, 0.16, 0.14, 12, 8), 'body', loc=(X - 0.12 + s * 0.29, -0.12, 1.44))
    # head in a kettle helm, clear of the gong's rim on the left
    P.add(L.sphere(0.145, 0.165, 0.165, 14, 9), 'bone', loc=(X - 0.16, -0.16, 1.70))
    P.add(aim(L.cone(0.21, 0.09, 0.17, 14), (X - 0.16, -0.16, 1.73), (0.0, 0.0, 1.0)), 'dark')
    P.add(aim(L.cone(0.29, 0.25, 0.035, 16), (X - 0.16, -0.16, 1.73), (0.0, 0.08, 1.0)), 'dark')
    eyes(P, (X - 0.16, 0.0, 1.70), 0.055, 0.028, -0.26)
    # THE FRAME: a hip yoke swung out to his right, two uprights, one crossbar
    P.add(L.box(0.84, 0.12, 0.08), 'dark', loc=(X + 0.34, 0.24, 0.98), rot=(0.0, -0.12, 0.0))
    for s in (-1, 1):
        limb(P, [(X + 0.34 + s * 0.34, 0.26, 1.00), (X + 0.38 + s * 0.34, 0.28, 1.62),
                 (X + 0.40 + s * 0.32, 0.28, 1.98)], 0.055, 0.042, 'dark')
    P.add(L.box(0.86, 0.09, 0.09), 'dark', loc=(X + 0.40, 0.28, 1.98))
    for s in (-1, 1):   # the two short hanging chains
        limb(P, [(X + 0.40 + s * 0.26, 0.28, 1.96), (X + 0.40 + s * 0.24, 0.22, 1.80)],
             0.028, 0.024, 'dark')
    # THE GONG - 1.40 m across, hung off his right shoulder, tilted as hung
    GX, GZ = X + 0.40, 1.26
    P.raw(aim(L.cone(0.70, 0.70, 0.055, 28), (GX, 0.20, GZ), (0.10, 1.0, -0.12)), 'body')
    P.raw(aim(L.cone(0.74, 0.70, 0.085, 28), (GX, 0.26, GZ), (0.10, 1.0, -0.12)), 'body')
    P.add(L.sphere(0.18, 0.09, 0.18, 16, 10), 'body', loc=(GX - 0.02, 0.15, GZ + 0.01))
    for k in range(3):   # struck rings, so it reads as a gong and not a shield
        r = 0.30 + k * 0.15
        ring = [Vector((GX + r * math.cos(TAU * i / 26.0), 0.17,
                        GZ + r * math.sin(TAU * i / 26.0))) for i in range(27)]
        P.raw(L.tube(ring, 0.016, 6), 'dark')
    # THE MALLET, raised clear above the gong - a long haft and a heavy head
    limb(P, [(X + 0.14, -0.12, 1.42), (X + 0.44, -0.22, 1.60), (X + 0.56, -0.16, 1.80)],
         0.075, 0.055)
    limb(P, [(X + 0.56, -0.14, 1.80), (X + 0.86, 0.04, 2.40)], 0.040, 0.034, 'bone')
    P.raw(aim(L.cone(0.165, 0.165, 0.38, 12), (X + 0.86, 0.04, 2.40), (0.50, 0.30, 1.0)), 'dark')
    P.raw(aim(L.cone(0.175, 0.17, 0.045, 12), (X + 0.86, 0.04, 2.40), (0.50, 0.30, 1.0)), 'bone')
    # left arm down, a plain baton - the parade tool, not a weapon
    limb(P, [(X - 0.40, -0.12, 1.42), (X - 0.52, -0.20, 1.08), (X - 0.54, -0.26, 0.80)],
         0.075, 0.055)
    limb(P, [(X - 0.54, -0.26, 0.78), (X - 0.58, -0.30, 0.34)], 0.028, 0.022, 'bone')
    return P


# ---------------------------------------- 2 THE SCRAPWRIGHT: a lopsided mound
def scrapwright():
    """IT ARMOURS ITSELF. Knock a plate off and it reaches down and takes
    another off the workshop floor. The shell GROWS during the fight.

    PASS 2, after looking at the silhouette sheet. Pass 1 stacked nine flat
    plates in horizontal courses and the outline came out a symmetrical pagoda
    - no mass, no lean, no read. Rebuilt around ONE DOMINANT LUMP biased hard
    to its left, with the plates driven into it as ANGLED SHARDS that break the
    outline instead of lying across it, and the thin neck and bucket head held
    well clear to the right. The read is a LOPSIDED MOUND WITH A HEAD BESIDE
    IT - nothing else in the dungeon has that shape.

    Two spare plates lie on the floor on the side it has been feeding from.
    That is the fight told in the silhouette: there is more where that came
    from."""
    P = Parts("scrapwright")
    # three stubby feet under the skirt, mostly buried by the mass
    for ang in (0.3, 2.4, 4.5):
        x, y = 0.46 * math.cos(ang), 0.46 * math.sin(ang)
        limb(P, [(x, y, 0.36), (x * 1.22, y * 1.22, 0.07)], 0.11, 0.14, 'dark')
        P.add(L.box(0.28, 0.28, 0.08), 'dark', loc=(x * 1.22, y * 1.22, 0.04))
    # THE LUMP - one mass, off-centre left, leaning. Everything hangs on this.
    CX, CY, CZ = -0.26, 0.02, 0.84
    P.add(L.sphere(0.74, 0.62, 0.68, 16, 11), 'dark', loc=(CX, CY, CZ), rot=(0.0, -0.22, 0.0))
    P.add(L.sphere(0.48, 0.44, 0.38, 14, 9), 'dark', loc=(CX - 0.26, CY - 0.08, CZ + 0.46),
          rot=(0.10, -0.40, 0.0))
    # PASS 3: the plates are laid ON the lump, tangent to its surface, not sunk
    # inside it. Pass 2 buried them and the thing came back a smooth boulder -
    # "it armours itself" has to be visible before the fight starts, or the
    # whole idea is a stat. Each plate is aimed along its own outward normal,
    # which is also how a thing that patched itself would actually do it.
    plates = [
        (-0.95, -0.25, 0.35, 1.00, 0.76),
        (-0.70, 0.45, 0.55, 0.86, 0.66),
        (-0.55, -0.50, 0.75, 0.80, 0.62),
        (-0.30, 0.20, 1.00, 0.78, 0.60),
        (0.25, -0.55, 0.45, 0.72, 0.56),
        (0.50, 0.30, 0.35, 0.68, 0.52),
        (0.10, 0.60, 0.80, 0.62, 0.48),
        (0.60, -0.20, 0.70, 0.58, 0.44),
        (-0.20, -0.30, -0.70, 0.66, 0.50),
    ]
    for dx, dy, dz, w, d in plates:
        n = Vector((dx, dy, dz)).normalized()
        at = Vector((CX + n.x * 0.76, CY + n.y * 0.64, CZ + n.z * 0.70))
        P.raw(aim(L.box(w, d, 0.085), at, n), 'body')
        P.raw(aim(L.box(w * 0.80, d * 0.18, 0.05), at + n * 0.065, n), 'dark')
        P.add(L.sphere(0.040, 0.040, 0.040, 7, 5), 'dark',
              loc=(at.x + n.x * 0.09, at.y + n.y * 0.09, at.z + n.z * 0.09))
    for z in (0.40, 0.64, 0.88):                                   # rivets
        P.add(L.sphere(0.05, 0.05, 0.05, 7, 5), 'dark', loc=(-1.12, -0.34, z))
    # a thin crane neck OUT TO THE RIGHT, well clear of the lump
    limb(P, [(0.10, 0.04, 1.16), (0.40, -0.14, 1.48), (0.52, -0.30, 1.74)],
         0.090, 0.065, 'dark')
    # the head: a riveted bucket, blunt, no face but a lamp slit
    P.add(L.box(0.36, 0.40, 0.32), 'bone', loc=(0.54, -0.34, 1.88), rot=(0.22, 0.0, 0.14))
    P.add(aim(L.cone(0.21, 0.18, 0.05, 12), (0.54, -0.34, 2.05), (0.0, 0.18, 1.0)), 'dark')
    P.add(L.box(0.24, 0.05, 0.06), 'glow', loc=(0.54, -0.54, 1.88))
    # THE HOOK ARM - long, forward and down to the floor, reaching for a plate
    limb(P, [(0.42, -0.06, 1.06), (0.94, -0.42, 0.80), (1.26, -0.62, 0.48)],
         0.105, 0.075, 'dark')
    P.raw(L.tube([(1.26, -0.62, 0.48), (1.46, -0.72, 0.30), (1.44, -0.76, 0.12),
                  (1.24, -0.72, 0.09)], [0.070, 0.058, 0.046, 0.030], 7), 'bone')
    # TWO SPARE PLATES, both on the side it feeds from - the ammunition
    P.add(L.box(0.72, 0.54, 0.065), 'body', loc=(1.08, -0.98, 0.035), rot=(0.0, 0.0, 0.55))
    P.add(L.box(0.58, 0.46, 0.065), 'body', loc=(1.36, -0.34, 0.035), rot=(0.05, 0.04, -0.6))
    return P


# -------------------------------------------- 3 THE GAOLER: a hook and a coil
def gaoler():
    """IT DRAGS. A hook on a long chain: it takes one hero out of the file and
    reels them back to itself, which breaks a formation in a way more hit
    points never could.

    PASS 2, after looking at the silhouette sheet. The coil on the floor read
    beautifully - a horizontal ring nothing else in the dungeon has - but THE
    HOOK, which is the whole mechanic, came out a hairline and vanished. So the
    arm is heavier, half a metre longer and swung clear of the body, and the
    hook is now a proper C of iron you can read at pane distance. The stoop is
    deeper too, so the man never reads as an adventurer standing up straight.

    Everything about him is old, greased iron and leather."""
    P = Parts("gaoler")
    # long thin legs, stooped hard forward over them
    for s in (-1, 1):
        limb(P, [(s * 0.15, 0.16, 1.16), (s * 0.20, -0.04, 0.62), (s * 0.23, 0.04, 0.07)],
             0.085, 0.060)
        P.add(L.box(0.22, 0.40, 0.09), 'dark', loc=(s * 0.23, -0.08, 0.045))
    # narrow torso bent well over - years of hauling, never a straight back
    limb(P, [(0.0, 0.24, 1.06), (0.0, 0.02, 1.48), (0.0, -0.26, 1.76)], 0.19, 0.21)
    # the apron: one flat leather panel, hip to shin, so the legs read as thin
    P.raw(L.membrane([(-0.30, -0.26, 1.14), (0.30, -0.26, 1.14),
                      (0.26, -0.34, 0.62), (0.20, -0.30, 0.30),
                      (-0.20, -0.30, 0.30), (-0.26, -0.34, 0.62)], 0.035), 'body')
    for s in (-1, 1):
        P.add(L.sphere(0.14, 0.13, 0.11, 12, 8), 'dark', loc=(s * 0.24, -0.22, 1.76))
    # a hood, bowed low, and a blank iron plate where a face should be
    P.add(L.sphere(0.19, 0.20, 0.19, 14, 9), 'dark', loc=(0.0, -0.38, 1.92))
    P.raw(surf([[Vector((-0.17 + 0.17 * j, -0.50 - 0.03 * abs(j - 1), 2.02 - 0.10 * i))
                 for j in range(3)] for i in range(3)], 0.03), 'bone')
    eyes(P, (0.0, 0.0, 1.96), 0.055, 0.026, -0.54)
    # short left arm, a ring of keys on the belt - plain working kit
    limb(P, [(-0.24, -0.22, 1.72), (-0.36, -0.32, 1.42), (-0.32, -0.34, 1.14)], 0.070, 0.050)
    ring = [Vector((-0.32 + 0.11 * math.cos(TAU * i / 14.0), -0.40,
                    1.02 + 0.11 * math.sin(TAU * i / 14.0))) for i in range(15)]
    P.raw(L.tube(ring, 0.014, 6), 'bone')
    for k in range(3):
        P.add(L.box(0.035, 0.02, 0.17), 'bone', loc=(-0.36 + k * 0.045, -0.41, 0.88))
    # THE LONG ARM - heavier, half a metre further out, swung clear of the body
    limb(P, [(0.24, -0.20, 1.74), (0.72, -0.44, 1.52), (1.22, -0.58, 1.26)], 0.105, 0.075)
    # THE HOOK - a C of iron 0.70 m across. The mechanic, made readable.
    hook = [Vector((1.22 + 0.34 * math.cos(a), -0.60 + 0.07 * math.cos(a), 0.98 + 0.34 * math.sin(a)))
            for a in [1.75 - 4.3 * (i / 10.0) for i in range(11)]]
    P.raw(L.tube(hook, [0.075, 0.072, 0.068, 0.064, 0.060, 0.056,
                        0.050, 0.044, 0.038, 0.028, 0.014], 8), 'bone')
    P.add(L.sphere(0.075, 0.075, 0.075, 9, 6), 'dark', loc=(1.22, -0.58, 1.32))
    # THE CHAIN: a flat spiral on the floor, then a run up to the hook hand
    coil = L.helix(2.6, 0.055, 0.14, 0.92, 0.26, steps=84, phase=0.4)
    coil = [Vector((p.x - 0.86, p.y + 0.52, p.z)) for p in coil]
    P.raw(L.tube(coil, 0.050, 6), 'dark')
    run = arc((-0.86 + 0.26, 0.52, 0.14), (0.26, -0.26, 1.70), 0.24, 9)
    P.raw(L.tube(run, 0.046, 6), 'dark')
    # a few links called out so the coil reads as chain, not as rope
    for i in range(0, len(coil) - 3, 9):
        P.add(L.sphere(0.068, 0.068, 0.032, 8, 6), 'dark',
              loc=(coil[i].x, coil[i].y, coil[i].z + 0.015))
    return P


# ------------------------------------------ 4 THE SNUFFER: a lamp-stand walks
def snuffer():
    """IT TAKES THE LIGHT. Each beat it puts out one of the room's lamps, and
    when the last is gone the party fights in the dark. That is a fight-changer
    with no extra hit points anywhere in it, and it is pure Bellmire - the
    epitaphs are full of men who went down with a lamp.

    Silhouette: a tripod lamp-stand that walks. A thin fluted column, two wide
    cross-arms hung with twelve DEAD candles, and a wide snuffer cone where a
    head belongs. One live candle, in its own grip - the one it has already
    taken - is the only lit thing on it, and the only colour in the outline."""
    P = Parts("snuffer")
    # tripod: three splayed legs on pads. It is furniture, not a man.
    for k in range(3):
        a = 0.52 + TAU * k / 3.0
        x, y = math.cos(a), math.sin(a)
        limb(P, [(0.0, 0.0, 0.70), (x * 0.34, y * 0.34, 0.40), (x * 0.56, y * 0.56, 0.05)],
             0.070, 0.055, 'dark')
        P.add(aim(L.cone(0.14, 0.11, 0.05, 10), (x * 0.56, y * 0.56, 0.02), (0.0, 0.0, 1.0)), 'dark')
        P.add(L.sphere(0.055, 0.055, 0.055, 8, 6), 'dark', loc=(x * 0.34, y * 0.34, 0.40))
    # the column, fluted by four thin ribs so it is not a bare pipe
    limb(P, [(0.0, 0.0, 0.62), (0.0, 0.0, 1.30), (0.0, 0.0, 2.02)], 0.105, 0.075, 'dark')
    for k in range(4):
        a = TAU * k / 4.0
        limb(P, [(0.085 * math.cos(a), 0.085 * math.sin(a), 0.70),
                 (0.065 * math.cos(a), 0.065 * math.sin(a), 1.92)], 0.016, 0.014, 'bone')
    P.add(aim(L.cone(0.22, 0.13, 0.08, 12), (0.0, 0.0, 0.60), (0.0, 0.0, 1.0)), 'dark')
    # TWO CROSS-ARMS, one wide and one narrower above it - a T, then a t
    for z, half, n in ((1.46, 0.74, 4), (1.86, 0.50, 2)):
        bar = [Vector((-half, 0.0, z)), Vector((0.0, 0.0, z + 0.05)), Vector((half, 0.0, z))]
        P.raw(L.tube(bar, 0.042, 7), 'dark')
        for i in range(n):
            u = -1.0 + 2.0 * (i / (n - 1.0))
            x = u * half * 0.92
            # a cup, a dead candle stub, and a frozen drip down one side
            P.add(aim(L.cone(0.085, 0.055, 0.045, 10), (x, 0.0, z - 0.02 + abs(u) * -0.01),
                      (0.0, 0.0, 1.0)), 'dark')
            stub = 0.30 - 0.11 * abs(u) - (0.06 if i % 2 else 0.0)
            P.add(aim(L.cone(0.045, 0.038, stub, 9), (x, 0.0, z + 0.02), (0.0, 0.0, 1.0)), 'bone')
            P.add(aim(L.cone(0.013, 0.0, 0.10, 6), (x + 0.040, 0.0, z + 0.02), (0.14, 0.0, -1.0)), 'bone')
            P.add(L.sphere(0.016, 0.016, 0.016, 6, 4), 'dark', loc=(x, 0.0, z + 0.02 + stub))
    # six more dead candles ringing the column between the arms
    for k in range(6):
        a = TAU * k / 6.0 + 0.3
        x, y = 0.17 * math.cos(a), 0.17 * math.sin(a)
        P.add(aim(L.cone(0.040, 0.034, 0.22 - 0.05 * (k % 3), 8), (x, y, 1.02), (0.0, 0.0, 1.0)), 'bone')
        P.add(L.sphere(0.014, 0.014, 0.014, 6, 4), 'dark',
              loc=(x, y, 1.02 + 0.22 - 0.05 * (k % 3)))
    # THE HEAD: a wide snuffer cone, apex up, on a short neck
    limb(P, [(0.0, 0.0, 1.98), (0.0, -0.03, 2.12)], 0.060, 0.070, 'dark')
    P.raw(aim(L.cone(0.52, 0.02, 0.50, 20), (0.0, -0.03, 2.10), (0.0, 0.0, 1.0)), 'body')
    P.raw(aim(L.cone(0.55, 0.52, 0.055, 20), (0.0, -0.03, 2.10), (0.0, 0.0, 1.0)), 'body')
    P.add(L.sphere(0.055, 0.055, 0.055, 8, 6), 'dark', loc=(0.0, -0.03, 2.60))
    for k in range(5):   # soot streaks: thin dark ribs up the cone
        a = -0.9 + 0.45 * k
        P.raw(L.tube([Vector((0.49 * math.cos(a), -0.03 + 0.49 * math.sin(a), 2.12)),
                      Vector((0.18 * math.cos(a), -0.03 + 0.18 * math.sin(a), 2.40))],
                     0.014, 5), 'dark')
    # the one light it has taken, held out on a small arm at chest height
    limb(P, [(0.06, -0.08, 1.30), (0.34, -0.34, 1.22), (0.46, -0.44, 1.30)], 0.045, 0.035, 'dark')
    P.add(aim(L.cone(0.10, 0.07, 0.05, 10), (0.46, -0.44, 1.30), (0.0, 0.0, 1.0)), 'dark')
    P.add(aim(L.cone(0.045, 0.038, 0.16, 9), (0.46, -0.44, 1.34), (0.0, 0.0, 1.0)), 'bone')
    P.add(L.sphere(0.045, 0.045, 0.075, 9, 7), 'glow', loc=(0.46, -0.44, 1.56))
    return P


BUILDERS = {
    "drillmaster": drillmaster,
    "scrapwright": scrapwright,
    "gaoler": gaoler,
    "snuffer": snuffer,
}


# =====================================================================
# SECOND SET, 16 Nov 2026 - the four themes that had no miniboss of their own.
#
# dungeon_hd.gd rolls the miniboss set piece at weight 15 on crypt(10), keep,
# treasury and mess, and until now the slot had nothing theme-matched to put
# there, so it fell back to Bestiary.pick() returning an ordinary creature with
# 2x hp. That is the exact thing Mr. E's bar forbids. Four more, same bar:
#
#   SEXTON    it WILL NOT STAY DOWN  - he carries his own graves. Each filled
#                                      niche on his back is one rising. Break
#                                      the filled niches or he gets up again.
#   PORTER    it BARS THE WAY        - he drops a barred leaf across the mouth
#                                      of the chamber. No retreat, no help.
#   TALLYMAN  it TAKES AND LEAVES    - it lifts gear off the party, wears it,
#                                      and withdraws. Kill it or the gear goes.
#   COOK      it KEEPS THE PACK ALIVE - the pot heals everything else in the
#                                      room. Spill the pot or nothing dies.
#
# None of these four has a hero body: a grid of graves on legs, a door with a
# man under it, a counting-frame hung with other people's kit, and a yoke with
# a pot on it. WEAR spreads deliberately across the whole eight now -
# tallyman 0.20 (the treasury is kept and rich) through sexton 0.85 (he has
# been down there longer than the keep has stood).
# =====================================================================

CANON.update({
    "sexton":   ("The Sexton", 2.45, (0.50, 0.54, 0.48), (0.72, 1.00, 0.80),
                 "crypt", "IT WILL NOT STAY DOWN - it carries its own graves; empty the lit niches",
                 0.85, "A spade is working somewhere in the dark."),
    "porter":   ("The Porter", 2.30, (0.56, 0.46, 0.32), (0.95, 0.70, 0.34),
                 "keep", "IT BARS THE WAY - it drops a leaf across the door: no retreat, no help",
                 0.45, "A bar has dropped behind you."),
    "tallyman": ("The Tallyman", 2.15, (0.88, 0.76, 0.42), (1.00, 0.88, 0.50),
                 "treasury", "IT TAKES AND LEAVES - it lifts your gear, wears it and withdraws",
                 0.20, "Something is counting what you carry."),
    "cook":     ("The Cook", 2.05, (0.72, 0.52, 0.38), (1.00, 0.62, 0.26),
                 "mess", "IT KEEPS THE PACK ALIVE - the pot heals the room; spill the pot",
                 0.60, "The pot is on."),
})
ORDER = ORDER + ["sexton", "porter", "tallyman", "cook"]


# ------------------------------------ 5 THE SEXTON: a grid of graves on legs
def sexton():
    """IT WILL NOT STAY DOWN. He carries his niches with him - a slab wall of
    twelve pigeonholes on a hod frame on his back. Five are plugged and LIT;
    those are his risings. Seven are open and dark. Break the lit ones and he
    stays where you put him.

    The mechanic is therefore COUNTABLE FROM THE DOORWAY, which is the whole
    point: a viewer can see how many times this thing is going to get back up
    without anybody telling them.

    Silhouette: a tall tilted RECTANGLE OF CELLS carried high, a deep stoop
    under it, and the spade a long diagonal down to the floor on the other
    side. Nothing else in this file is a grid.

    He is a working sexton, not a wraith: a spade, a hod, a leather cowl, and
    the longest wear in the set because the crypt was here first."""
    P = Parts("sexton")
    # feet planted wide and SHORT - everything above him is heavy
    for s in (-1, 1):
        limb(P, [(s * 0.19, 0.10, 0.88), (s * 0.26, -0.02, 0.48),
                 (s * 0.29, -0.08, 0.08)], 0.100, 0.082)
        P.add(L.box(0.25, 0.42, 0.10), 'dark', loc=(s * 0.29, -0.16, 0.05))
    # torso bowed hard FORWARD under the load, shoulders low
    limb(P, [(0.0, 0.14, 0.84), (0.0, -0.04, 1.18), (0.0, -0.30, 1.46)], 0.235, 0.215)
    P.add(L.box(0.56, 0.28, 0.09), 'dark', loc=(0.0, -0.10, 1.04))               # belt
    for s in (-1, 1):
        P.add(L.sphere(0.155, 0.145, 0.125, 12, 8), 'body', loc=(s * 0.27, -0.28, 1.46))
    # a leather cowl bowed low; a blank plate for a face, no skull
    P.add(L.sphere(0.175, 0.185, 0.175, 14, 9), 'dark', loc=(0.0, -0.42, 1.62))
    P.raw(aim(L.cone(0.25, 0.17, 0.07, 14), (0.0, -0.40, 1.70), (0.0, -0.30, 1.0)), 'dark')
    eyes(P, (0.0, 0.0, 1.62), 0.052, 0.024, -0.56)
    # THE HOD FRAME: two uprights off the hips, raked back over his shoulders
    for s in (-1, 1):
        limb(P, [(s * 0.26, 0.16, 0.96), (s * 0.30, 0.26, 1.60),
                 (s * 0.33, 0.34, 2.26)], 0.055, 0.042, 'dark')
    P.add(L.box(0.78, 0.09, 0.09), 'dark', loc=(0.0, 0.22, 1.14))
    # THE NICHE WALL - 4 x 3 cells, tilted back as a carried thing would be.
    # Lit = a plugged grave = one rising left. Dark = already spent.
    # PASS 2, after the silhouette sheet. Pass 1 packed twelve flush cells and
    # they fused into one banded slab - the thing you were supposed to be able
    # to COUNT was invisible, and at a glance it was the Porter's door. So:
    # NINE bigger cells, real air between them, and every lit plug pushed well
    # proud so it breaks the outline. The grid is now holes, not a wall.
    LIT = {(0, 0), (2, 0), (1, 1), (0, 2)}
    cw, chh = 0.40, 0.40
    pitch_x, pitch_z = 0.46, 0.46
    for i in range(3):
        for j in range(3):
            x = (i - 1.0) * pitch_x
            z = 1.24 + j * pitch_z
            y = 0.30 + j * 0.055                       # the rake
            # the cell: a square collar of four thin slabs, hollow in the middle
            for dx, dz, sx, sz in ((0.0, chh * 0.5, cw, 0.075),
                                   (0.0, -chh * 0.5, cw, 0.075),
                                   (cw * 0.5, 0.0, 0.075, chh),
                                   (-cw * 0.5, 0.0, 0.075, chh)):
                P.add(L.box(sx, 0.13, sz), 'bone', loc=(x + dx, y, z + dz),
                      rot=(-0.14, 0.0, 0.0))
            # PASS 3: an EMPTY niche must be a hole you can see daylight
            # through. Pass 2 closed each one with a dark back plate and the
            # nine cells fused into a bigger solid slab than pass 1 had - the
            # outline went backwards. Open cells are now open to the sky, so
            # the silhouette is pigeonholes and the lit plugs are countable.
            if (i, j) in LIT:
                # a plugged grave: the slab stands 0.16 PROUD and it is lit, so
                # the count reads from the doorway and dents the silhouette
                P.add(L.box(cw * 0.90, 0.16, chh * 0.90), 'body',
                      loc=(x, y - 0.17, z), rot=(-0.14, 0.0, 0.0))
                P.add(L.box(cw * 0.62, 0.05, chh * 0.14), 'glow',
                      loc=(x, y - 0.26, z), rot=(-0.14, 0.0, 0.0))
                P.add(L.sphere(0.045, 0.045, 0.045, 8, 6), 'dark',
                      loc=(x, y - 0.27, z + chh * 0.32))
    # frame edges, so the nine cells read as one carried hod
    for z in (1.24 - pitch_z * 0.62, 1.24 + 2.62 * pitch_z):
        P.add(L.box(3 * pitch_x + 0.10, 0.10, 0.075), 'dark',
              loc=(0.0, 0.30 + (0.145 if z > 1.9 else 0.0), z))
    for s in (-1, 1):                       # and two side rails, same reason
        P.add(L.box(0.075, 0.10, 3 * pitch_z + 0.10), 'dark',
              loc=(s * (1.5 * pitch_x + 0.03), 0.37, 1.24 + pitch_z))
    # THE SPADE - a long clean diagonal to the floor, the other way from the
    # grid's lean. Right arm down and back, both hands on the haft.
    limb(P, [(0.27, -0.26, 1.44), (0.46, -0.30, 1.14), (0.58, -0.28, 0.86)], 0.072, 0.054)
    limb(P, [(-0.27, -0.26, 1.44), (-0.10, -0.34, 1.10), (0.20, -0.32, 0.86)], 0.072, 0.054)
    limb(P, [(0.66, -0.26, 1.08), (0.94, -0.30, 0.40)], 0.055, 0.048, 'bone')
    P.raw(aim(L.box(0.40, 0.065, 0.50), (1.04, -0.32, 0.18), (0.36, -0.06, 1.0)), 'bone')
    P.raw(aim(L.cone(0.21, 0.015, 0.15, 4), (1.11, -0.33, 0.00), (0.36, -0.06, 1.0)), 'bone')
    # a fresh spoil heap at his feet on the spade side - there is a hole here
    for k, (dx, dy, r) in enumerate(((1.02, -0.62, 0.30), (1.26, -0.34, 0.22),
                                     (0.86, -0.86, 0.17))):
        P.add(L.sphere(r, r * 0.86, r * 0.42, 10, 7), 'dark', loc=(dx, dy, r * 0.20))
    return P


# -------------------------------------- 6 THE PORTER: a door with a man under
def porter():
    """IT BARS THE WAY. The leaf on his back goes across the chamber mouth and
    the drawbar goes into the brackets. Nobody leaves, nobody arrives. The
    fight does not get harder, it gets CLOSED - and a party built on retreating
    to the stairs has to find another plan.

    Silhouette: THE WIDEST HORIZONTAL IN THE DUNGEON. The drawbar is held
    crosswise and runs well past both shoulders, with the tall banded leaf
    standing behind him. A broad flat cross. The Sexton's grid is a tall tilted
    rectangle carried high with a diagonal spade; this is a long low bar with a
    slab behind - the two do not collide at pane distance.

    He is the keep's porter and the keep is kept: middling wear, the iron
    greased, the oak sound, and nothing decorative on him anywhere."""
    P = Parts("porter")
    # square, planted, no stoop at all - he is a post
    for s in (-1, 1):
        limb(P, [(s * 0.22, 0.04, 0.96), (s * 0.26, 0.00, 0.50),
                 (s * 0.28, -0.04, 0.09)], 0.115, 0.092)
        P.add(L.box(0.28, 0.44, 0.11), 'dark', loc=(s * 0.28, -0.12, 0.055))
    limb(P, [(0.0, 0.04, 0.92), (0.0, -0.02, 1.26), (0.0, -0.10, 1.56)], 0.270, 0.280)
    P.add(L.box(0.66, 0.34, 0.11), 'dark', loc=(0.0, -0.06, 1.12))
    for s in (-1, 1):
        P.add(L.sphere(0.185, 0.175, 0.150, 12, 8), 'body', loc=(s * 0.33, -0.10, 1.56))
    # a closed visor helm, flat-fronted. A door has no face either.
    P.add(L.sphere(0.155, 0.170, 0.175, 14, 9), 'dark', loc=(0.0, -0.16, 1.80))
    P.add(L.box(0.26, 0.05, 0.24), 'bone', loc=(0.0, -0.31, 1.80))
    P.add(L.box(0.20, 0.035, 0.035), 'dark', loc=(0.0, -0.34, 1.84))
    eyes(P, (0.0, 0.0, 1.81), 0.058, 0.022, -0.36)
    P.raw(aim(L.cone(0.24, 0.20, 0.055, 16), (0.0, -0.16, 1.93), (0.0, 0.0, 1.0)), 'dark')
    # THE LEAF - tall, banded oak on a slung strap behind him. Narrower than it
    # is tall on purpose, so the bar owns the width and the leaf owns the height.
    # PASS 2, after the silhouette sheet. Pass 1 put a 1.02 m leaf right behind
    # him and held the bar level with it - from three-quarters the leaf ate the
    # far half of the bar, so the widest horizontal in the dungeon came out a
    # stub, and the remaining read (man under a big slab) was the Sexton's.
    # Fix: the leaf is NARROWER AND TALLER and lifted clear of his knees, and
    # the bar is longer, well forward of the leaf, and raked so both iron shoes
    # stand outside the body from any angle.
    LY = 0.40
    P.add(L.box(0.84, 0.14, 2.12), 'body', loc=(0.0, LY, 1.24), rot=(0.10, 0.0, 0.0))
    for z in (0.52, 1.06, 1.60, 2.16):                      # iron bands across
        P.add(L.box(0.90, 0.07, 0.11), 'dark', loc=(0.0, LY - 0.095, z), rot=(0.10, 0.0, 0.0))
        for s in (-1, 1):                                   # bosses on the bands
            P.add(L.sphere(0.055, 0.045, 0.055, 8, 6), 'dark',
                  loc=(s * 0.30, LY - 0.145, z))
    for s in (-1, 1):                                       # two hinge straps
        P.add(L.box(0.12, 0.08, 1.98), 'dark', loc=(s * 0.37, LY - 0.08, 1.24),
              rot=(0.10, 0.0, 0.0))
    P.add(L.box(0.24, 0.09, 0.09), 'dark', loc=(0.0, LY - 0.17, 2.02))   # pull ring bar
    for s in (-1, 1):                                       # the slung strap
        limb(P, [(s * 0.26, 0.28, 2.00), (s * 0.34, -0.14, 1.52)], 0.040, 0.034, 'dark')
    # THE DRAWBAR - 2.3 m of squared oak, crosswise, both hands under it.
    BZ, BY = 1.30, -0.76
    P.raw(aim(L.box(2.84, 0.19, 0.19), (0.0, BY, BZ), (0.0, 0.0, 1.0),
              scale=(1.0, 1.0, 1.0)), 'bone')
    # rake it: one end high and near, one end low and far, so neither hides
    for s in (-1, 1):
        P.add(L.box(0.80, 0.20, 0.20), 'bone', loc=(s * 1.12, BY + s * 0.16, BZ + s * 0.20),
              rot=(0.0, -s * 0.18, s * 0.11))
        P.add(L.box(0.20, 0.23, 0.23), 'dark', loc=(s * 1.48, BY + s * 0.22, BZ + s * 0.27))
        P.add(aim(L.cone(0.115, 0.08, 0.15, 10), (s * 1.60, BY + s * 0.24, BZ + s * 0.29),
                  (s * 1.0, s * 0.14, s * 0.18)), 'dark')
    for s in (-1, 1):                                       # arms out onto the bar
        limb(P, [(s * 0.32, -0.12, 1.52), (s * 0.46, -0.44, 1.40),
                 (s * 0.52, BY, BZ + s * 0.08)], 0.090, 0.068)
        P.add(L.box(0.17, 0.24, 0.24), 'dark', loc=(s * 0.52, BY, BZ + s * 0.09))
    # the socket brackets he will drive it into, carried on the belt
    for s in (-1, 1):
        P.add(aim(L.cone(0.11, 0.09, 0.20, 10), (s * 0.40, -0.26, 0.96),
                  (0.0, -0.25, -1.0)), 'dark')
    return P


# ----------------------------- 7 THE TALLYMAN: a counting frame, hung with kit
def tallyman():
    """IT TAKES AND LEAVES. Each pass it lifts one carried item off a hero,
    strings it onto its frame, and moves one step nearer the way out. Kill it
    and everything it is wearing drops; let it withdraw and the party paid for
    the floor with their kit. The threat is not damage, it is LOSS, and that
    reorders a fight completely.

    This is also the one in the set where Mr. E's receipt rule bites hardest:
    what it has taken is HANGING ON IT, where the viewer who paid for that
    helm can see it. So the stolen kit is modelled, not implied.

    Silhouette: a narrow upright with a BARRED COUNTING FRAME for a chest and a
    bunch of things dangling off it on cords. Nothing else here dangles.

    WEAR 0.20 - the lowest in the eight. The treasury is kept, this thing is
    kept, and it is the only bright metal object in the file. A level 12
    Bellmire's treasury does not have a rusty tallyman in it."""
    P = Parts("tallyman")
    # thin, long, upright - a clerk's build, not a fighter's
    for s in (-1, 1):
        limb(P, [(s * 0.13, 0.06, 1.02), (s * 0.17, 0.00, 0.54),
                 (s * 0.19, -0.04, 0.07)], 0.072, 0.056)
        P.add(L.box(0.18, 0.34, 0.08), 'dark', loc=(s * 0.19, -0.10, 0.045))
    limb(P, [(0.0, 0.04, 0.98), (0.0, 0.00, 1.32), (0.0, -0.06, 1.70)], 0.150, 0.130)
    # THE STRONGBOX BELLY - a banded box with a coin slot. Where it puts coin.
    P.add(L.box(0.52, 0.34, 0.44), 'body', loc=(0.0, -0.10, 0.96))
    P.add(L.box(0.56, 0.06, 0.07), 'dark', loc=(0.0, -0.28, 1.08))
    P.add(L.box(0.56, 0.06, 0.07), 'dark', loc=(0.0, -0.28, 0.86))
    P.add(L.box(0.20, 0.04, 0.035), 'dark', loc=(0.0, -0.29, 0.98))        # the slot
    P.add(L.box(0.14, 0.03, 0.02), 'glow', loc=(0.0, -0.305, 0.98))
    # THE COUNTING FRAME - four wires across the chest, beads on each. The
    # beads are the tally: what it has already had off you.
    FY, F0 = -0.20, 1.26
    for s in (-1, 1):
        P.add(L.box(0.08, 0.10, 0.62), 'bone', loc=(s * 0.46, FY, F0 + 0.18))
    P.add(L.box(1.00, 0.10, 0.08), 'bone', loc=(0.0, FY, F0 + 0.50))
    P.add(L.box(1.00, 0.10, 0.08), 'bone', loc=(0.0, FY, F0 - 0.14))
    for w, n in ((0.00, 7), (0.17, 5), (0.34, 3), (0.50, 6)):
        z = F0 - 0.06 + w
        P.add(L.box(0.88, 0.035, 0.030), 'dark', loc=(0.0, FY - 0.035, z))
        for k in range(n):
            x = -0.40 + 0.80 * (k / max(1.0, n - 1.0)) * (0.62 if n > 4 else 0.9)
            P.add(L.sphere(0.052, 0.040, 0.052, 9, 6), 'body',
                  loc=(x, FY - 0.035, z))
    # head: a narrow hooded lamp, a visor slit, a quill behind it. No face.
    P.add(L.box(0.26, 0.30, 0.30), 'body', loc=(0.0, -0.10, 1.86))
    P.add(aim(L.cone(0.20, 0.13, 0.09, 12), (0.0, -0.10, 2.02), (0.0, 0.0, 1.0)), 'dark')
    P.add(L.box(0.19, 0.04, 0.045), 'glow', loc=(0.0, -0.26, 1.88))
    limb(P, [(0.10, 0.06, 1.98), (0.26, 0.20, 2.34)], 0.020, 0.008, 'bone')   # the quill
    # LONG THIN ARMS with PINCHING FINGERS - it lifts, it does not hook.
    for s, reach in ((-1, 0.46), (1, 0.34)):
        limb(P, [(s * 0.17, -0.06, 1.66), (s * 0.44, -0.30, 1.52),
                 (s * (0.44 + reach), -0.52, 1.34)], 0.062, 0.040)
        hx = s * (0.44 + reach)
        for f in (-1, 0, 1):
            limb(P, [(hx, -0.54, 1.32), (hx + s * 0.10 + f * 0.035, -0.66 - abs(f) * 0.02, 1.18)],
                 0.020, 0.012, 'bone')
    # WHAT IT HAS TAKEN - on cords off the frame. The receipt, modelled.
    # PASS 2, after the silhouette sheet. Pass 1 hung the kit on short cords
    # inside the body's own width, so every stolen piece fused with the torso
    # and the one thing the viewer is supposed to see - THEIR HELM, ON IT -
    # was not in the outline at all. A spreader bar now carries the lot wide
    # of the body on long cords, below the strongbox, with air around each.
    P.add(L.box(1.86, 0.10, 0.09), 'bone', loc=(0.0, FY - 0.16, F0 + 0.50))
    for s in (-1, 1):                                  # the spreader's stays
        limb(P, [(s * 0.90, FY - 0.16, F0 + 0.50), (s * 0.34, FY - 0.02, F0 + 0.62)],
             0.020, 0.016, 'dark')
        P.add(aim(L.cone(0.055, 0.035, 0.09, 8), (s * 0.92, FY - 0.16, F0 + 0.50),
                  (s * 1.0, 0.0, 0.0)), 'dark')

    def hang(x, drop, kind):
        limb(P, [(x, FY - 0.16, F0 + 0.46), (x, FY - 0.20, F0 + 0.46 - drop)],
             0.014, 0.012, 'dark')
        at = (x, FY - 0.22, F0 + 0.42 - drop)
        if kind == 'helm':
            P.add(L.sphere(0.125, 0.130, 0.120, 12, 8), 'body', loc=at)
            P.add(L.box(0.20, 0.04, 0.05), 'dark', loc=(at[0], at[1] - 0.10, at[2] + 0.01))
        elif kind == 'boot':
            P.add(L.box(0.11, 0.13, 0.22), 'dark', loc=at)
            P.add(L.box(0.12, 0.24, 0.07), 'dark', loc=(at[0], at[1] - 0.05, at[2] - 0.11))
        elif kind == 'satchel':
            P.add(L.box(0.22, 0.12, 0.20), 'dark', loc=at)
            P.add(L.box(0.24, 0.03, 0.07), 'bone', loc=(at[0], at[1] - 0.08, at[2] + 0.05))
        elif kind == 'blade':
            limb(P, [(at[0], at[1], at[2] + 0.12), (at[0] + 0.02, at[1], at[2] - 0.34)],
                 0.034, 0.012, 'bone')
            P.add(L.box(0.14, 0.04, 0.035), 'dark', loc=(at[0], at[1], at[2] + 0.12))
        elif kind == 'ring':
            r = [Vector((at[0] + 0.065 * math.cos(TAU * i / 12.0), at[1],
                         at[2] + 0.065 * math.sin(TAU * i / 12.0))) for i in range(13)]
            P.raw(L.tube(r, 0.014, 6), 'glow')
    hang(-0.86, 0.46, 'helm')
    hang(-0.56, 0.86, 'boot')
    hang(0.00, 1.14, 'satchel')
    hang(0.58, 0.72, 'blade')
    hang(0.88, 0.34, 'ring')
    return P


# ------------------------------------------- 8 THE COOK: a yoke and a big pot
def cook():
    """IT KEEPS THE PACK ALIVE. The pot is the fight. While it is on, every
    other thing in the room comes back up; spill it and the pack dies like any
    pack. A party that goes for the biggest health bar in the room loses, and
    one that goes for the cook wins - which is the only kind of change worth
    building a set piece for.

    Silhouette: a YOKE WITH A POT ON IT. The cauldron is a heavy low mass out
    to one side on chains, the ladle a long diagonal up the other, and the man
    is bent in the middle taking the weight. The drillmaster's gong is a thin
    tall disc high on his shoulder; this is a fat low ball at hip height. They
    do not read alike.

    He is a mess cook and the mess is greasy: wear 0.60, soot on everything,
    but the pot itself is scoured bright inside the rim because a cook keeps
    his pot. Plainness is the voice - this is a man with a pot and a spoon."""
    P = Parts("cook")
    # short bowed legs, taking a load on one side
    for s in (-1, 1):
        limb(P, [(s * 0.20 - 0.06, 0.08, 0.82), (s * 0.25 - 0.06, 0.00, 0.44),
                 (s * 0.28 - 0.06, -0.06, 0.08)], 0.105, 0.085)
        P.add(L.box(0.26, 0.40, 0.10), 'dark', loc=(s * 0.28 - 0.06, -0.14, 0.05))
    # a wide low barrel of a torso, canted AWAY from the pot to counterweight
    limb(P, [(-0.06, 0.10, 0.78), (-0.14, 0.00, 1.10), (-0.26, -0.12, 1.38)], 0.265, 0.250)
    # the apron, one flat panel - plain, and it hides nothing clever
    P.raw(L.membrane([(-0.60, -0.30, 1.16), (0.14, -0.30, 1.16),
                      (0.10, -0.38, 0.62), (0.04, -0.34, 0.26),
                      (-0.54, -0.34, 0.26), (-0.62, -0.38, 0.62)], 0.035), 'bone')
    for s in (-1, 1):
        P.add(L.sphere(0.165, 0.155, 0.135, 12, 8), 'body', loc=(-0.26 + s * 0.30, -0.12, 1.38))
    # head: a cloth cap pulled down, and a blank soot-dark face
    P.add(L.sphere(0.150, 0.165, 0.160, 14, 9), 'bone', loc=(-0.30, -0.18, 1.62))
    P.add(L.sphere(0.175, 0.180, 0.105, 14, 8), 'dark', loc=(-0.30, -0.16, 1.73))
    eyes(P, (-0.30, 0.0, 1.60), 0.054, 0.026, -0.28)
    # THE YOKE across the shoulders, dipping to the loaded side
    yoke = [Vector((-0.96, -0.08, 1.46)), Vector((-0.26, -0.14, 1.56)),
            Vector((0.52, -0.08, 1.42)), Vector((0.96, -0.02, 1.30))]
    P.raw(L.tube(yoke, [0.055, 0.075, 0.070, 0.050], 8), 'bone')
    # THE CAULDRON - 0.95 m across, slung LOW on two chains. The whole fight.
    PX, PZ = 0.86, 0.60
    for s in (-1, 1):
        limb(P, [(0.92 + s * 0.02, -0.02 + s * 0.26, 1.28),
                 (PX + s * 0.01, s * 0.33, PZ + 0.30)], 0.026, 0.022, 'dark')
    # PASS 2, after the colour sheet. The pot was built out of 'body' and came
    # back a WOODEN TUB - a cook with a barrel is a cook with a barrel, and the
    # thing the party has to spill stopped reading as a cauldron. It is black
    # iron now, with the rim scoured bright because a cook keeps his pot, and
    # the heat is a lit surface inside the rim rather than anything sticking up.
    P.add(L.sphere(0.48, 0.48, 0.40, 18, 12), 'dark', loc=(PX, 0.0, PZ))
    P.raw(aim(L.cone(0.47, 0.49, 0.30, 20), (PX, 0.0, PZ + 0.10), (0.0, 0.0, 1.0)), 'dark')
    P.raw(aim(L.cone(0.50, 0.47, 0.085, 20), (PX, 0.0, PZ + 0.32), (0.0, 0.0, 1.0)), 'bone')
    P.add(aim(L.cone(0.415, 0.415, 0.035, 20), (PX, 0.0, PZ + 0.30), (0.0, 0.0, 1.0)), 'glow')
    P.add(L.sphere(0.40, 0.40, 0.085, 18, 8), 'glow', loc=(PX, 0.0, PZ + 0.30))
    for k in range(3):                                   # three stubby pot legs
        a = 0.5 + TAU * k / 3.0
        P.add(aim(L.cone(0.075, 0.055, 0.22, 8),
                  (PX + 0.26 * math.cos(a), 0.26 * math.sin(a), PZ - 0.34),
                  (0.0, 0.0, 1.0)), 'dark')
    # NO MODELLED STEAM. Three thin tapers off the rim read as pale SPIKES on
    # the colour sheet - straw, or bones, anything but steam. Geometry cannot
    # do steam at this silhouette weight, so the heat is the lit pot surface
    # above and the delve's own particles can carry the rest.
    # THE LADLE - long haft up and back over the other shoulder, a deep bowl
    limb(P, [(-0.56, -0.16, 1.36), (-0.74, -0.24, 1.14), (-0.82, -0.26, 0.92)], 0.072, 0.054)
    limb(P, [(-0.74, -0.14, 1.02), (-1.16, 0.06, 2.12)], 0.034, 0.028, 'bone')
    P.add(L.sphere(0.17, 0.17, 0.11, 14, 9), 'body', loc=(-1.22, 0.09, 2.24))
    P.add(aim(L.cone(0.175, 0.16, 0.05, 14), (-1.22, 0.09, 2.29), (0.10, -0.04, 1.0)), 'dark')
    # the mess kit on the yoke's free end: three tin bowls, stacked and strung
    for k in range(3):
        P.add(aim(L.cone(0.115, 0.085, 0.055, 12), (-0.98, -0.04, 1.14 - k * 0.075),
                  (0.0, 0.0, 1.0)), 'bone')
    limb(P, [(-0.96, -0.06, 1.44), (-0.98, -0.04, 1.18)], 0.012, 0.012, 'dark')
    return P


BUILDERS.update({
    "sexton": sexton,
    "porter": porter,
    "tallyman": tallyman,
    "cook": cook,
})


# =====================================================================
# THIRD SET, 16 Nov 2026 - THE SIX BIOME THEMES.
#
# floorgen.gd THEMES has fourteen entries. The first eight minibosses cover the
# eight built, indoor ones (barracks, workshop, prison, shrine, crypt, keep,
# treasury, mess). The other SIX - flooded, grassland, wood, firepit, fogbound,
# confection - are the outdoor and the strange ones, they roll "miniboss" at the
# normal weight 15, and they had NOTHING theme-matched to put in the slot, so it
# fell back to Bestiary.pick() returning an ordinary creature with 2x hp. That
# is precisely the thing Mr. E's bar forbids, and it is the whole reason for
# these six. After them every theme in the game has its own set piece.
#
# Each idea had to be new, not a sixth coat of the eight already built (summon /
# self-armour / drag / snuff / rise / bar the way / steal / heal). These six:
#   SLUICEKEEPER  it RAISES THE WATER - the room floods a step at a time
#   SOWER         it PLANTS THE GROUND - what it broadcasts stands up as thorn
#   SNARER        it HAS ALREADY SET THE ROOM - it drives, it does not chase
#   STOKER        it IS ONLY AS BIG AS THE FIRE - starve the pit and it starves
#   BELLMAN       it RINGS FROM WHERE IT IS NOT - the sound is a lie
#   BOILER        it POURS AND IT SETS - the floor hardens round your feet
#
# SILHOUETTE IS STILL THE ACCEPTANCE TEST, and this set had to clear two
# specific collisions with the first eight: a big disc reads as the Drillmaster's
# gong, and a long horizontal reads as the Porter's drawbar. So the
# Sluicekeeper's wheel is a SPOKED RING you see through, and the Stoker's rake
# goes DOWN to the floor on one side instead of across.
# =====================================================================

CANON.update({
    "sluicekeeper": ("The Sluicekeeper", 2.50, (0.46, 0.54, 0.56), (0.40, 0.80, 1.00),
                     "flooded", "IT RAISES THE WATER - it winds the sluice open a step at a time",
                     0.95, "The water is coming up."),
    "sower":        ("The Sower", 2.25, (0.72, 0.68, 0.44), (0.55, 1.00, 0.42),
                     "grassland", "IT PLANTS THE GROUND AGAINST YOU - what it casts stands up as thorn",
                     0.40, "Something is broadcasting seed."),
    "snarer":       ("The Snarer", 2.30, (0.50, 0.42, 0.32), (0.80, 0.90, 0.40),
                     "wood", "IT HAS ALREADY SET THE ROOM - it drives you onto its own lines",
                     0.55, "The lines were here before you."),
    "stoker":       ("The Stoker", 2.40, (0.44, 0.38, 0.36), (1.00, 0.42, 0.12),
                     "firepit", "IT IS ONLY AS BIG AS THE FIRE - starve the pit and it starves",
                     0.70, "The pit has been fed."),
    "bellman":      ("The Bellman", 2.70, (0.66, 0.68, 0.72), (0.80, 0.92, 1.00),
                     "fogbound", "IT RINGS FROM WHERE IT IS NOT - the sound comes from the wrong place",
                     0.65, "A bell, and not where you thought."),
    "boiler":       ("The Boiler", 2.10, (0.86, 0.60, 0.34), (1.00, 0.78, 0.60),
                     "confection", "IT POURS AND IT SETS - the floor hardens around your feet",
                     0.25, "Something is pouring."),
})
ORDER = ORDER + ["sluicekeeper", "sower", "snarer", "stoker", "bellman", "boiler"]


def _legs(P, x, y=0.0, hip=0.92, stance=0.21, r0=0.105, r1=0.085, boot=(0.26, 0.42, 0.11)):
    """The planted two-leg base the whole set shares. A set piece is seen from
    the doorway and a stance that reads PLANTED is worth more than feet."""
    for s in (-1, 1):
        limb(P, [(x + s * stance, y + 0.06, hip), (x + s * (stance + 0.06), y + 0.02, hip * 0.54),
                 (x + s * (stance + 0.10), y - 0.06, 0.09)], r0, r1)
        P.add(L.box(*boot), 'dark', loc=(x + s * (stance + 0.10), y - 0.14, boot[2] / 2.0))


def _ring(P, c, r, axis='y', slot='dark', rad=0.045, n=26):
    """A closed ring of iron. `axis` is the ring's own axis, so axis='y' stands
    the ring UP facing the camera and axis='z' lays it on the floor."""
    pts = []
    for i in range(n + 1):
        t = TAU * i / n
        if axis == 'y':
            pts.append(Vector((c[0] + r * math.cos(t), c[1], c[2] + r * math.sin(t))))
        elif axis == 'x':
            pts.append(Vector((c[0], c[1] + r * math.cos(t), c[2] + r * math.sin(t))))
        else:
            pts.append(Vector((c[0] + r * math.cos(t), c[1] + r * math.sin(t), c[2])))
    P.raw(L.tube(pts, [rad] * len(pts), 7), slot)


# ------------------------------------------- 9 THE SLUICEKEEPER: a spoked ring
def sluicekeeper():
    """IT RAISES THE WATER. He does not fight for the room, he drowns it: the
    screw gate goes up one notch at a time and the floor the party is standing
    on goes under.

    The read had to clear the DRILLMASTER. A disc at this size IS the muster
    gong, so the handwheel is a SPOKED RING with air through it - six spokes, a
    crank peg standing off the rim, and the screw thread climbing behind it.
    Reads MAN, OPEN WHEEL HIGH ON HIS RIGHT, SCREW, BOARD UNDER THE ARM.

    Wear 0.95, the highest in the whole set and justified: this is the one
    thing down there that is never dry. Nothing on him is kept."""
    P = Parts("sluicekeeper")
    X = -0.42
    _legs(P, X, hip=0.88, stance=0.22)
    limb(P, [(X, 0.10, 0.82), (X - 0.04, 0.00, 1.14), (X - 0.10, -0.10, 1.40)], 0.25, 0.26)
    P.add(L.box(0.58, 0.28, 0.09), 'dark', loc=(X - 0.02, -0.06, 1.02))
    for s in (-1, 1):
        P.add(L.sphere(0.165, 0.155, 0.135, 12, 8), 'body', loc=(X - 0.10 + s * 0.28, -0.10, 1.40))
    # a sodden hood, no face - the one thing a gate-keeper owns is a hood
    P.add(L.sphere(0.145, 0.160, 0.158, 14, 9), 'bone', loc=(X - 0.14, -0.14, 1.64))
    P.raw(aim(L.cone(0.235, 0.075, 0.30, 14), (X - 0.14, -0.12, 1.56), (0.06, -0.10, 1.0)), 'dark')
    eyes(P, (X - 0.14, 0.0, 1.62), 0.050, 0.025, -0.24)
    # THE SLUICE FRAME on his right: two posts, a head beam, the screw between
    FX = X + 1.02
    for s in (-1, 1):
        limb(P, [(FX + s * 0.30, 0.16, 0.02), (FX + s * 0.31, 0.18, 1.20),
                 (FX + s * 0.32, 0.18, 2.06)], 0.065, 0.050, 'bone')
    P.add(L.box(0.78, 0.11, 0.10), 'bone', loc=(FX, 0.18, 2.06))
    # the threaded stem, eight collars so it reads as a SCREW and not a pole
    limb(P, [(FX, 0.16, 0.36), (FX, 0.16, 2.02)], 0.055, 0.048, 'dark')
    for k in range(8):
        P.add(aim(L.cone(0.095, 0.095, 0.022, 10), (FX, 0.16, 0.52 + k * 0.17),
                  (0.0, 0.0, 1.0)), 'dark')
    # THE HANDWHEEL - 1.06 m across, open, standing up facing the room
    WZ = 1.78
    _ring(P, (FX, 0.14, WZ), 0.53, 'y', 'dark', 0.055, 28)
    for k in range(6):
        a = TAU * k / 6.0 + 0.2
        P.raw(aim(L.cone(0.034, 0.030, 0.52, 7), (FX, 0.14, WZ),
                  (math.cos(a), 0.0, math.sin(a))), 'dark')
    P.add(L.sphere(0.105, 0.105, 0.105, 12, 8), 'dark', loc=(FX, 0.14, WZ))
    # the crank peg, standing off the rim toward the room - you can see it turn
    limb(P, [(FX + 0.46, 0.14, WZ + 0.26), (FX + 0.50, -0.20, WZ + 0.28)], 0.040, 0.034, 'body')
    # THE GATE BOARD, drawn up behind the frame, with water light under its lip
    P.raw(L.membrane([(FX - 0.28, 0.30, 0.46), (FX + 0.28, 0.30, 0.46),
                      (FX + 0.28, 0.30, 1.42), (FX - 0.28, 0.30, 1.42)], 0.07), 'bone')
    P.add(L.box(0.60, 0.10, 0.055), 'glow', loc=(FX, 0.30, 0.44))
    # the tide line he carries with him: a shallow lit pool at his feet
    P.add(L.sphere(0.72, 0.52, 0.035, 20, 6), 'glow', loc=(X + 0.18, 0.04, 0.022))
    # his own hand on the stem, and a drag-board tucked under the far arm
    limb(P, [(X + 0.16, -0.12, 1.34), (FX - 0.22, 0.04, 1.44)], 0.072, 0.052)
    P.raw(L.membrane([(X - 0.92, -0.22, 0.86), (X - 0.30, -0.26, 1.04),
                      (X - 0.26, -0.26, 1.24), (X - 0.88, -0.22, 1.06)], 0.05), 'bone')
    limb(P, [(X - 0.34, -0.20, 1.32), (X - 0.60, -0.24, 1.08)], 0.070, 0.050)
    return P


# ------------------------------------------------ 10 THE SOWER: a box and shoots
def sower():
    """IT PLANTS THE GROUND AGAINST YOU. It walks a line and casts, and what it
    casts comes up behind it - thorn that splits the party and takes the open
    field away. The grassland floors are the open ones; this is the thing that
    closes them.

    The mechanic is in the outline twice over: the SEED HOPPER slung across the
    chest (a box, deliberately - a box cannot be mistaken for the gong) and
    THREE SHOOTS ALREADY STANDING behind him, crooked and diverging and at
    three different heights, so the viewer can see it has been working before
    the fight starts. Wear 0.40: a farm tool, used hard and kept."""
    P = Parts("sower")
    X = -0.18
    _legs(P, X, hip=0.90, stance=0.26, boot=(0.28, 0.44, 0.10))
    limb(P, [(X, 0.10, 0.84), (X + 0.02, 0.00, 1.16), (X + 0.04, -0.12, 1.42)], 0.255, 0.255)
    for s in (-1, 1):
        P.add(L.sphere(0.170, 0.160, 0.140, 12, 8), 'body', loc=(X + 0.04 + s * 0.29, -0.12, 1.42))
    # a wide straw hat, because a man in a field wears one and it reads instantly
    P.add(L.sphere(0.145, 0.160, 0.158, 14, 9), 'bone', loc=(X + 0.02, -0.16, 1.66))
    P.raw(aim(L.cone(0.44, 0.17, 0.055, 18), (X + 0.02, -0.16, 1.74), (0.0, 0.10, 1.0)), 'bone')
    P.add(aim(L.cone(0.17, 0.05, 0.14, 14), (X + 0.02, -0.16, 1.76), (0.0, 0.10, 1.0)), 'bone')
    eyes(P, (X + 0.02, 0.0, 1.64), 0.052, 0.026, -0.26)
    # THE HOPPER - a slanted open box across the chest on a broad strap
    P.add(L.box(0.72, 0.34, 0.40), 'bone', loc=(X - 0.14, -0.34, 1.08), rot=(0.0, 0.22, 0.0))
    P.add(L.box(0.66, 0.28, 0.05), 'dark', loc=(X - 0.14, -0.34, 1.29), rot=(0.0, 0.22, 0.0))
    P.add(aim(L.cone(0.27, 0.25, 0.045, 16), (X - 0.14, -0.36, 1.30), (0.22, 0.0, 1.0)), 'glow')
    P.raw(L.membrane([(X + 0.16, -0.24, 1.44), (X + 0.26, -0.18, 1.40),
                      (X - 0.30, -0.44, 0.96), (X - 0.40, -0.48, 1.00)], 0.035), 'dark')
    # THE CAST: the far arm thrown wide and open, low, palm turned out
    limb(P, [(X - 0.25, -0.12, 1.40), (X - 0.72, -0.26, 1.18), (X - 1.06, -0.34, 1.02)],
         0.085, 0.060)
    P.add(L.sphere(0.115, 0.095, 0.075, 10, 7), 'body', loc=(X - 1.12, -0.36, 0.98))
    for k in range(4):   # four seeds already in the air, clear of the hand
        P.add(L.sphere(0.042, 0.042, 0.042, 7, 5), 'glow',
              loc=(X - 1.30 - k * 0.17, -0.40 - k * 0.04, 0.92 - k * 0.14))
    # the near arm steadying the hopper
    limb(P, [(X + 0.33, -0.14, 1.40), (X + 0.30, -0.30, 1.16), (X + 0.14, -0.40, 1.08)],
         0.080, 0.056)
    # THREE SHOOTS ALREADY UP, behind him, crooked, diverging, three heights
    for s, (dx, dy, hh, bend) in enumerate(((0.62, 0.42, 1.74, 0.26),
                                            (1.05, 0.30, 1.18, -0.20),
                                            (0.30, 0.56, 1.46, 0.14))):
        base = (X + dx, dy, 0.0)
        tip = (X + dx + bend, dy + 0.10, hh)
        limb(P, arc(base, tip, 0.0, 6, side=bend * 0.8), 0.075, 0.022, 'bone')
        for k in range(5):      # thorns, alternating, out of the stem's own line
            t = 0.30 + 0.16 * k
            z = hh * t
            sx = X + dx + bend * t + (0.16 if k % 2 else -0.16)
            P.raw(aim(L.cone(0.030, 0.0, 0.17, 6), (X + dx + bend * t, dy + 0.10 * t, z),
                      (sx - (X + dx + bend * t), 0.06, 0.34)), 'bone')
    return P


# -------------------------------------------- 11 THE SNARER: a row of open loops
def snarer():
    """IT HAS ALREADY SET THE ROOM. It does not chase - it stands in its own
    lines and beats you onto them. The fight is about where you are allowed to
    walk, which is the opposite of every other set piece in the file.

    Pass 1 hung five loops off a SPREADER BAR across his shoulders, and on the
    sheet that is THE TALLYMAN - who is two cells away carrying a spreader bar
    with things hanging off it. A mechanic that reads as another miniboss is no
    better than one that reads as nothing. The snares are now rooted where a
    real snare is rooted: THREE BENT SPRINGPOLES standing out of the floor,
    arcing over at three different heights with a noose at each tip. Curves -
    the only curved lines in the fourteen, against a file of bars and discs.
    A long beating-pole takes the low diagonal. Wear 0.55: woodsman's kit."""
    P = Parts("snarer")
    X = 0.0
    _legs(P, X, hip=0.86, stance=0.20, boot=(0.24, 0.40, 0.10))
    # hunched: a man who works bent over, so the torso leans forward and down
    limb(P, [(X, 0.12, 0.80), (X + 0.02, -0.04, 1.08), (X + 0.04, -0.20, 1.30)], 0.235, 0.245)
    for s in (-1, 1):
        P.add(L.sphere(0.160, 0.150, 0.130, 12, 8), 'body', loc=(X + 0.04 + s * 0.27, -0.20, 1.30))
    P.add(L.sphere(0.140, 0.155, 0.150, 14, 9), 'bone', loc=(X + 0.06, -0.30, 1.50))
    P.add(L.sphere(0.165, 0.150, 0.095, 14, 8), 'dark', loc=(X + 0.06, -0.28, 1.60))
    eyes(P, (X + 0.06, 0.0, 1.48), 0.050, 0.025, -0.30)
    # THREE BENT SPRINGPOLES, rooted in the floor, arcing over and inward. Each
    # is a sapling under load: thick at the root, whippy at the tip, and the
    # bend carries past vertical so the tip hangs OVER the walking ground.
    # (root x, root y, apex height, how far the tip reaches inward, noose r)
    for rx, ry, apex, reach, rr in ((-1.34, 0.26, 1.98, 0.62, 0.20),
                                    (1.12, 0.12, 2.32, -0.66, 0.23),
                                    (1.62, -0.40, 1.54, -0.40, 0.17)):
        sgn = 1.0 if reach > 0 else -1.0
        # a smooth quarter-bend: pass 2's five points put a sharp elbow at the
        # apex and the poles read as bent girders. Seven points and a thin
        # whippy taper, because a loaded sapling is a CURVE and curves are the
        # whole reason this shape is not the Tallyman's bar.
        arc = []
        for t in (0.0, 0.22, 0.44, 0.63, 0.79, 0.92, 1.0):
            a = (math.pi / 2.0) * t
            arc.append((X + rx + reach * (1.0 - math.cos(a)),
                        ry - 0.12 * t, apex * math.sin(a)))
        limb(P, arc, 0.052, 0.014, 'bone')
        # the cord straight down off the loaded tip, and the noose on its end
        tipx, tipy, tipz = X + rx + reach, ry - 0.12, apex
        cz = tipz - 0.40 - rr
        limb(P, [(tipx, tipy, tipz), (tipx, tipy, cz + rr)], 0.013, 0.013, 'dark')
        _ring(P, (tipx, tipy, cz), rr, 'y', 'bone', 0.019, 16)
        P.add(L.sphere(0.038, 0.038, 0.038, 8, 6), 'glow', loc=(tipx, tipy, cz + rr))
        # the trigger peg at the root, leaning the way the pole is pulled
        P.raw(aim(L.cone(0.034, 0.020, 0.34, 7), (X + rx - sgn * 0.14, ry + 0.06, 0.0),
                  (sgn * 0.26, 0.0, 1.0)), 'dark')
    # THE BEATING POLE - a long clear diagonal low and to the front
    limb(P, [(X - 0.34, -0.40, 1.22), (X + 0.46, -0.66, 0.78), (X + 1.22, -0.88, 0.22)],
         0.045, 0.030, 'bone')
    limb(P, [(X - 0.22, -0.30, 1.26), (X - 0.36, -0.42, 1.20)], 0.072, 0.052)
    P.add(L.sphere(0.075, 0.065, 0.065, 10, 7), 'dark', loc=(X + 1.26, -0.90, 0.19))
    # two pegs and a coil of cord on the ground beside him - he has been working
    for k in range(2):
        P.raw(aim(L.cone(0.030, 0.018, 0.30, 7), (X - 0.74 + k * 0.22, -0.46, 0.0),
                  (0.10, 0.0, 1.0)), 'bone')
    _ring(P, (X - 0.62, -0.52, 0.055), 0.21, 'z', 'dark', 0.028, 18)
    return P


# ------------------------------------------------ 12 THE STOKER: a lit grate
def stoker():
    """IT IS ONLY AS BIG AS THE FIRE. The pit feeds it and it feeds the pit, so
    the fight is not about the thing, it is about the fuel: starve the pit and
    it comes apart. A grate burns in its chest where the heart would be and the
    stream can see it brighten.

    The read had to clear the PORTER, whose whole silhouette is the widest
    horizontal in the dungeon. So the rake does NOT go across - it goes DOWN,
    a long diagonal into the floor on one side, and the vertical is a flue
    standing off the far shoulder. Reads FIGURE, TALL FLUE, RAKE TO THE FLOOR.
    Wear 0.70: scorched iron. Nothing scorched is also bright."""
    P = Parts("stoker")
    X = -0.10
    _legs(P, X, hip=0.94, stance=0.23, boot=(0.28, 0.46, 0.13))
    # a squat heavy frame, square-shouldered. The chest is a box, not a barrel,
    # because the grate has to be a flat lit face and not a glowing belly.
    limb(P, [(X, 0.10, 0.88), (X - 0.02, 0.02, 1.12), (X - 0.04, -0.06, 1.30)], 0.24, 0.27)
    P.add(L.box(0.62, 0.40, 0.56), 'dark', loc=(X - 0.04, -0.10, 1.26))
    for s in (-1, 1):
        P.add(L.sphere(0.180, 0.165, 0.145, 12, 8), 'body', loc=(X - 0.04 + s * 0.32, -0.08, 1.48))
    # THE GRATE: a lit face set into the chest behind five iron bars
    P.add(L.box(0.46, 0.05, 0.40), 'glow', loc=(X - 0.04, -0.31, 1.26))
    for k in range(5):
        P.add(L.box(0.035, 0.07, 0.42), 'dark', loc=(X - 0.22 + k * 0.09, -0.33, 1.26))
    P.add(L.box(0.56, 0.08, 0.055), 'bone', loc=(X - 0.04, -0.32, 1.48))
    # head low between the shoulders, hidden in its own heat
    P.add(L.sphere(0.135, 0.150, 0.145, 14, 9), 'bone', loc=(X - 0.06, -0.16, 1.68))
    P.add(aim(L.cone(0.205, 0.145, 0.12, 14), (X - 0.06, -0.16, 1.70), (0.0, 0.04, 1.0)), 'dark')
    eyes(P, (X - 0.06, 0.0, 1.66), 0.052, 0.030, -0.22)
    # THE FLUE off the far shoulder: a tall narrow pipe, two bands, a lit mouth
    FX = X - 0.60
    limb(P, [(FX, 0.22, 1.30), (FX - 0.06, 0.24, 2.16)], 0.105, 0.088, 'dark')
    for k in range(2):
        P.add(aim(L.cone(0.135, 0.135, 0.035, 12), (FX - 0.02 * k, 0.23, 1.58 + k * 0.34),
                  (-0.07, 0.0, 1.0)), 'bone')
    P.add(aim(L.cone(0.115, 0.145, 0.10, 12), (FX - 0.06, 0.24, 2.14), (-0.07, 0.0, 1.0)), 'dark')
    P.add(L.sphere(0.115, 0.115, 0.045, 12, 6), 'glow', loc=(FX - 0.07, 0.24, 2.23))
    limb(P, [(FX + 0.14, 0.18, 1.40), (FX + 0.02, 0.22, 1.32)], 0.050, 0.040, 'bone')
    # THE RAKE - 1.9 m of haft running down into the floor on his right
    haft = [Vector((X + 0.36, -0.20, 1.52)), Vector((X + 0.92, -0.42, 0.98)),
            Vector((X + 1.48, -0.64, 0.42)), Vector((X + 1.78, -0.76, 0.12))]
    P.raw(L.tube(haft, [0.046, 0.040, 0.036, 0.034], 8), 'bone')
    P.add(L.box(0.52, 0.10, 0.07), 'dark', loc=(X + 1.80, -0.78, 0.11), rot=(0.0, -0.34, 0.0))
    for k in range(4):                        # four short teeth, biting the floor
        P.raw(aim(L.cone(0.030, 0.0, 0.20, 6), (X + 1.64 + k * 0.14, -0.78, 0.10),
                  (0.42, -0.10, -1.0)), 'dark')
    limb(P, [(X + 0.26, -0.10, 1.46), (X + 0.40, -0.22, 1.50)], 0.074, 0.054)
    # the fuel basket at his heels - the thing the party has to get to
    P.raw(aim(L.cone(0.34, 0.40, 0.42, 14, cap=False), (X - 0.30, 0.52, 0.0),
              (0.0, 0.08, 1.0)), 'bone')
    for k in range(3):
        P.add(L.box(0.10, 0.10, 0.34), 'dark', loc=(X - 0.34 + k * 0.10, 0.54, 0.46),
              rot=(0.0, 0.18 - 0.16 * k, 0.0))
    P.add(L.sphere(0.30, 0.26, 0.05, 14, 6), 'glow', loc=(X - 0.30, 0.52, 0.06))
    return P


# ------------------------------------------- 13 THE BELLMAN: two bells, two heights
def bellman():
    """IT RINGS FROM WHERE IT IS NOT. On a fogbound floor you fight what you can
    hear, and this thing is built to be heard in the wrong place: two bells on
    two long arms at two different heights, and a third on a pole behind it. The
    party swings at a bell. Only one of the three is ever on it.

    Tallest of the fourteen at 2.70 and the thinnest - a narrow shroud and
    nothing inside it to hit. The ASYMMETRY IS THE LIE and so it is the whole
    silhouette: one arm high left, one low right, neither mirroring the other.
    Wear 0.65: river damp, not ruin."""
    P = Parts("bellman")
    X = 0.0
    # no boots and no stance - a shroud reaching the floor. It does not walk
    # like the others and it should not stand like them either.
    P.raw(aim(L.cone(0.52, 0.17, 1.48, 18), (X, 0.0, 0.0), (0.0, 0.0, 1.0)), 'bone')
    P.raw(aim(L.cone(0.56, 0.50, 0.085, 18), (X, 0.0, 0.015), (0.0, 0.0, 1.0)), 'dark')
    limb(P, [(X, -0.02, 1.40), (X - 0.02, -0.06, 1.74), (X - 0.03, -0.10, 1.96)], 0.155, 0.125)
    # a deep hood with nothing in it but two lights
    P.add(L.sphere(0.135, 0.150, 0.165, 14, 9), 'dark', loc=(X - 0.04, -0.12, 2.06))
    P.raw(aim(L.cone(0.245, 0.055, 0.40, 16), (X - 0.04, -0.08, 1.92), (0.04, -0.14, 1.0)), 'bone')
    eyes(P, (X - 0.04, 0.0, 2.04), 0.048, 0.024, -0.22)
    # ARM ONE - high, to its left, bell up and well clear of the hood
    limb(P, [(X - 0.14, -0.06, 1.88), (X - 0.58, -0.16, 2.08), (X - 1.02, -0.22, 2.26)],
         0.065, 0.044)
    BX, BZ = X - 1.10, 2.16
    P.raw(aim(L.cone(0.07, 0.26, 0.34, 16, cap=False), (BX, -0.22, BZ - 0.34), (0.0, 0.0, 1.0)), 'body')
    _ring(P, (BX, -0.22, BZ - 0.345), 0.265, 'z', 'dark', 0.030, 16)
    P.add(L.sphere(0.055, 0.055, 0.075, 8, 6), 'glow', loc=(BX, -0.22, BZ - 0.42))
    limb(P, [(X - 1.04, -0.22, 2.24), (BX, -0.22, BZ)], 0.028, 0.024, 'dark')
    # ARM TWO - LOW, to its right, a smaller bell swinging by the hem. The two
    # arms are deliberately not a pair; a symmetrical pair reads as a posture
    # and this has to read as a TRICK.
    limb(P, [(X + 0.13, -0.08, 1.80), (X + 0.52, -0.22, 1.44), (X + 0.84, -0.30, 1.14)],
         0.062, 0.042)
    CX, CZ = X + 0.90, 1.00
    P.raw(aim(L.cone(0.05, 0.185, 0.25, 14, cap=False), (CX, -0.30, CZ - 0.25), (0.0, 0.0, 1.0)), 'body')
    _ring(P, (CX, -0.30, CZ - 0.255), 0.19, 'z', 'dark', 0.026, 14)
    P.add(L.sphere(0.042, 0.042, 0.058, 8, 6), 'glow', loc=(CX, -0.30, CZ - 0.31))
    limb(P, [(X + 0.86, -0.30, 1.12), (CX, -0.30, CZ)], 0.024, 0.020, 'dark')
    # THE THIRD BELL, on a pole raked back over the far shoulder - the decoy
    limb(P, [(X + 0.26, 0.34, 0.10), (X + 0.10, 0.30, 1.40), (X - 0.10, 0.26, 2.46)],
         0.042, 0.030, 'bone')
    P.add(L.box(0.40, 0.08, 0.06), 'bone', loc=(X - 0.26, 0.26, 2.44), rot=(0.0, 0.10, 0.0))
    DX, DZ = X - 0.44, 2.34
    P.raw(aim(L.cone(0.045, 0.165, 0.23, 14, cap=False), (DX, 0.26, DZ - 0.23), (0.0, 0.0, 1.0)), 'body')
    _ring(P, (DX, 0.26, DZ - 0.235), 0.17, 'z', 'dark', 0.024, 14)
    limb(P, [(DX, 0.26, DZ + 0.08), (DX, 0.26, DZ)], 0.020, 0.018, 'dark')
    return P


# --------------------------------------- 14 THE BOILER: a tilted pan and a pour
def boiler():
    """IT POURS AND IT SETS. The confection floors are the strange sweet ones;
    this is the thing that makes them a trap. It tips the pan, the floor takes
    a skin, and whoever is standing in it is standing in it for good.

    The read had to clear the COOK, who also carries a pot. The Cook's is a deep
    black sphere slung LOW on chains behind him; the Boiler's is a WIDE SHALLOW
    DISH on a trunnion in FRONT of him, ROLLED OFF ITS RIGHT LIP, and the pour
    runs out sideways to the floor in one thick unbroken line clear of the pan. Nothing else in the
    fourteen has a line from a held thing down to the ground - that line is the
    whole creature. Wear 0.25: a sugar man scours his copper or it burns."""
    P = Parts("boiler")
    X = -0.44
    _legs(P, X, hip=0.80, stance=0.24, r0=0.115, r1=0.095, boot=(0.28, 0.44, 0.12))
    # short, wide, braced back against the weight of a full pan
    limb(P, [(X - 0.02, 0.14, 0.74), (X - 0.08, 0.06, 1.02), (X - 0.14, -0.02, 1.26)], 0.265, 0.250)
    P.add(L.box(0.60, 0.30, 0.09), 'dark', loc=(X - 0.05, 0.02, 0.94))
    for s in (-1, 1):
        P.add(L.sphere(0.170, 0.160, 0.140, 12, 8), 'body', loc=(X - 0.14 + s * 0.29, -0.02, 1.26))
    P.add(L.sphere(0.140, 0.155, 0.152, 14, 9), 'bone', loc=(X - 0.16, -0.08, 1.50))
    P.add(L.sphere(0.168, 0.172, 0.100, 14, 8), 'bone', loc=(X - 0.16, -0.06, 1.60))
    eyes(P, (X - 0.16, 0.0, 1.48), 0.052, 0.026, -0.26)
    # the apron, one flat panel, scoured pale
    P.raw(L.membrane([(X - 0.46, -0.28, 1.06), (X + 0.18, -0.28, 1.06),
                      (X + 0.14, -0.34, 0.50), (X - 0.42, -0.34, 0.50)], 0.03), 'bone')
    # THE TRUNNION: two short posts in front of him carrying the pan's pivot
    for s in (-1, 1):
        limb(P, [(X + 1.00, -0.42 + s * 0.34, 0.02), (X + 1.06, -0.40 + s * 0.32, 1.36)],
             0.070, 0.050, 'dark')
    limb(P, [(X + 1.06, -0.74, 1.36), (X + 1.06, -0.08, 1.36)], 0.034, 0.034, 'dark')
    # THE PAN - 1.18 m across, SHALLOW, ROLLED SIDEWAYS over its far lip.
    # Pass 1 tipped it forward, toward the camera, and the pour fell on the
    # pan's own centre line: pan + stream + pool stacked into A ROUND TABLE and
    # the one line that IS the creature was a dot. The roll is about Y now, so
    # the lip is off to his right and the stream crosses open air.
    # Pass 3. A 1.18 m dish is a TABLE TOP at this camera height whatever you
    # tilt it, and anything falling off it lands inside its own footprint, so
    # pan + stream + pool kept stacking into a pedestal table. The pan is now
    # SMALL (0.80 m) and HIGH, and the stream travels 0.9 m sideways before it
    # reaches the floor - a long diagonal nothing else in the fourteen has.
    PX, PY, PZ = X + 1.06, -0.42, 1.42
    P.add(L.sphere(0.40, 0.38, 0.15, 20, 9), 'body', loc=(PX, PY, PZ), rot=(-0.30, 0.52, 0.0))
    P.raw(aim(L.cone(0.41, 0.42, 0.065, 20), (PX + 0.07, PY - 0.04, PZ + 0.11), (0.52, -0.30, 1.0)), 'bone')
    P.add(aim(L.cone(0.31, 0.32, 0.03, 18), (PX + 0.05, PY - 0.03, PZ + 0.09), (0.52, -0.30, 1.0)), 'glow')
    # THE POUR - one thick unbroken line from the lip, well clear of the pan
    pour = [Vector((PX + 0.34, PY - 0.20, PZ - 0.10)), Vector((PX + 0.60, PY - 0.28, 0.86)),
            Vector((PX + 0.80, PY - 0.34, 0.38)), Vector((PX + 0.88, PY - 0.37, 0.03))]
    P.raw(L.tube(pour, [0.125, 0.112, 0.104, 0.118], 10), 'glow')
    P.add(L.sphere(0.44, 0.38, 0.030, 20, 6), 'glow', loc=(PX + 0.94, PY - 0.39, 0.018))
    _ring(P, (PX + 0.94, PY - 0.39, 0.030), 0.45, 'z', 'bone', 0.026, 20)
    # THE SKIMMER - a long haft back over the shoulder, a flat perforated blade
    limb(P, [(X - 0.42, -0.14, 1.20), (X - 0.78, 0.04, 1.62), (X - 1.02, 0.16, 2.02)],
         0.038, 0.030, 'bone')
    P.add(aim(L.cone(0.27, 0.26, 0.05, 16), (X - 1.06, 0.18, 2.06), (-0.22, 0.12, 1.0)), 'body')
    for k in range(6):
        a = TAU * k / 6.0
        P.add(L.sphere(0.052, 0.052, 0.07, 7, 5), 'dark',
              loc=(X - 1.06 + 0.15 * math.cos(a), 0.18 + 0.15 * math.sin(a), 2.07))
    limb(P, [(X - 0.44, -0.04, 1.22), (X - 0.56, -0.06, 1.34)], 0.072, 0.052)
    # the near arm on the pan's tipping handle
    limb(P, [(X + 0.15, -0.10, 1.22), (X + 0.62, -0.22, 1.28)], 0.080, 0.056)
    limb(P, [(X + 0.66, -0.22, 1.28), (X + 0.98, -0.16, 1.34)], 0.034, 0.030, 'dark')
    return P


BUILDERS.update({
    "sluicekeeper": sluicekeeper,
    "sower": sower,
    "snarer": snarer,
    "stoker": stoker,
    "bellman": bellman,
    "boiler": boiler,
})


# ===========================================================================
# THE FIT EXPERIMENT, 16 Nov - DO THE FOURTEEN FIT THE GAME'S OWN CHARACTERS?
#
# Rendered beside a real KayKit adventurer at scale 1.0 for the first time
# (tools/art/minibossfit.py), the whole set failed on two counts at once:
#
#   SCALE.       A hero is 2.45 m - the bodies are CHIBI and the head alone
#                runs 1.2 to 2.3. Authored at 2.00-2.70 m, TEN OF THE FOURTEEN
#                STAND SHORTER THAN THE PARTY. A floor-4 set piece that the
#                heroes look down on is not a set piece.
#   PROPORTION.  The men inside these creatures are seven-head realistic
#                figures with 0.10 m limbs. Beside a chibi knight they read as
#                pipe-cleaner men from a different game.
#
# Scale is one number in bestiary.gd and belongs to the game build lane.
# PROPORTION IS OURS. These two builders are the worked example of the fix on
# one creature - same creature, same props, same idea, rebuilt in the game's
# own register - so the comparison sheet decides it rather than an argument.
#
# Measured off Knight.glb in the idle pose (not guessed):
#   total 2.45 | sole-to-hip 0.52 (21%) | torso 0.36-1.28 | head+helm 1.09-2.45
#   head about 1.09 across, i.e. the head is 55% of the whole height.
# ===========================================================================
CANON.update({
    "drillmaster_chibi": ("The Drillmaster (chibi)", 2.20, (0.86, 0.72, 0.38),
                          (1.00, 0.78, 0.34), "barracks",
                          "IT SUMMONS - rebuilt in the game's own proportions",
                          0.15, "Someone is beating the muster."),
    "drillmaster_tall": ("The Drillmaster (3.60m)", 3.60, (0.86, 0.72, 0.38),
                         (1.00, 0.78, 0.34), "barracks",
                         "IT SUMMONS - same body, the recommended in-game height",
                         0.15, "Someone is beating the muster."),
    "drillmaster_chibi_tall": ("The Drillmaster (chibi, 3.60m)", 3.60, (0.86, 0.72, 0.38),
                               (1.00, 0.78, 0.34), "barracks",
                               "IT SUMMONS - both changes together",
                               0.15, "Someone is beating the muster."),
})


def drillmaster_chibi():
    """The Drillmaster in the game's register: short thick legs, a barrel
    torso, a head the size of the torso, mitts for hands. Nothing about the
    IDEA changes - gong behind him on its frame, mallet up, baton down - only
    the proportions of the man carrying it.

    Authored to the same 2.20 m as the original so the comparison sheet is a
    comparison of ONE thing. The proportions are lifted off the measured
    Knight: legs to 21% of height, head 55%, shoulders 0.80 wide."""
    P = Parts("drillmaster_chibi")
    X = -0.30
    H = 2.20
    HIP = 0.46                                  # 21% of the body's height
    # LEGS - stubs, not limbs. Boots almost as wide as the leg is long.
    for s in (-1, 1):
        limb(P, [(X + s * 0.17, 0.04, HIP), (X + s * 0.19, 0.00, 0.22),
                 (X + s * 0.20, -0.04, 0.10)], 0.145, 0.135)
        P.add(L.box(0.30, 0.40, 0.13), 'dark', loc=(X + s * 0.20, -0.12, 0.065))
    # TORSO - one barrel from hip to shoulder, wider than it is tall
    # FAULT 3 OF THE THREE: head and torso were the SAME pale value with no
    # neck, so the man read as one blank column. The torso takes the mid tone
    # ('body') and the head keeps the pale one ('bone'), and a dark collar
    # sits in the seam between them - the break a chibi head needs to read as
    # a head. Same three values the hero uses: dark legs, mid body, pale face.
    limb(P, [(X, 0.08, HIP - 0.02), (X - 0.04, 0.00, 0.72), (X - 0.08, -0.08, 1.00)],
         0.36, 0.38, 'body')
    P.add(aim(L.cone(0.36, 0.30, 0.11, 18), (X - 0.09, -0.10, 0.94), (0.0, 0.0, 1.0)), 'dark')
    P.add(L.box(0.80, 0.34, 0.13), 'dark', loc=(X - 0.02, -0.06, 0.70))      # belt
    for s in (-1, 1):                                                        # shoulders
        P.add(L.sphere(0.22, 0.21, 0.19, 12, 8), 'body', loc=(X - 0.08 + s * 0.38, -0.08, 1.02))
    # THE HEAD - the whole point. 0.96 across, sitting straight on the shoulders
    # with no neck, topped by the kettle helm. Head top lands at 1.74 of 2.20.
    P.add(L.sphere(0.46, 0.44, 0.40, 18, 12), 'bone', loc=(X - 0.10, -0.12, 1.34))
    # PASS 2 on the head, after looking: the first one read as a MUSHROOM. A
    # 1.24 m brim sitting at mid-head height covered the dome and the face
    # both, so the one thing that says soldier - a kettle helm - said farmer.
    # The dome is taller and narrower and now clears the brim; the brim is
    # 1.08 m and sits high on the skull, where a helmet's does.
    # PASS 3, and this is the first of the three register faults being closed:
    # a cone with a point on it is a FARMER'S HAT whatever you call it. A
    # kettle helm is a BOWL - rounded crown, no apex - with a brim that is
    # widest at its outer edge and droops. So the dome is a squashed sphere
    # and the brim is a cone whose BOTTOM radius is the larger one.
    P.add(aim(L.cone(0.60, 0.44, 0.09, 20), (X - 0.10, -0.12, 1.50), (0.0, 0.05, 1.0)), 'dark')
    P.add(L.sphere(0.45, 0.43, 0.33, 18, 12), 'dark', loc=(X - 0.10, -0.12, 1.54))
    # and the eyes were INSIDE THE SKULL. The head is 0.44 deep and they sat at
    # 0.40, so the face was blank from every angle. Measured, not nudged.
    # FAULT 2 OF THE THREE: pale glowing DISCS read as a mummy, not a man, and
    # nothing else in the game has them - a KayKit face is two dark ovals,
    # taller than they are wide, sunk just under the surface of the skull.
    # Head centre y -0.12, depth radius 0.44, so the face is at y -0.56: the
    # ovals sit at -0.535 and stand 0.015 proud, not floating in front of it.
    for s in (-1, 1):
        P.add(L.sphere(0.058, 0.040, 0.088, 12, 8), 'dark',
              loc=(X - 0.10 + s * 0.150, -0.535, 1.30))
    # ARMS - short, thick, ending in mitts. Right arm up on the mallet.
    limb(P, [(X + 0.26, -0.10, 1.00), (X + 0.52, -0.16, 1.14)], 0.145, 0.120)
    P.add(L.sphere(0.155, 0.150, 0.145, 10, 7), 'body', loc=(X + 0.56, -0.16, 1.16))
    limb(P, [(X - 0.44, -0.10, 1.00), (X - 0.60, -0.16, 0.68)], 0.145, 0.120)
    P.add(L.sphere(0.155, 0.150, 0.145, 10, 7), 'body', loc=(X - 0.62, -0.18, 0.62))
    # THE FRAME AND THE GONG - unchanged in idea, lowered to the new shoulder
    P.add(L.box(0.84, 0.12, 0.08), 'dark', loc=(X + 0.34, 0.26, 0.64), rot=(0.0, -0.12, 0.0))
    for s in (-1, 1):
        limb(P, [(X + 0.34 + s * 0.34, 0.28, 0.66), (X + 0.38 + s * 0.34, 0.30, 1.26),
                 (X + 0.40 + s * 0.32, 0.30, 1.62)], 0.055, 0.042, 'dark')
    P.add(L.box(0.86, 0.09, 0.09), 'dark', loc=(X + 0.40, 0.30, 1.62))
    for s in (-1, 1):
        limb(P, [(X + 0.40 + s * 0.26, 0.30, 1.60), (X + 0.40 + s * 0.24, 0.24, 1.46)],
             0.028, 0.024, 'dark')
    GX, GZ = X + 0.42, 0.96
    P.raw(aim(L.cone(0.70, 0.70, 0.055, 28), (GX, 0.22, GZ), (0.10, 1.0, -0.12)), 'body')
    P.raw(aim(L.cone(0.74, 0.70, 0.085, 28), (GX, 0.28, GZ), (0.10, 1.0, -0.12)), 'body')
    P.add(L.sphere(0.18, 0.09, 0.18, 16, 10), 'body', loc=(GX - 0.02, 0.17, GZ + 0.01))
    for k in range(3):
        r = 0.30 + k * 0.15
        ring = [Vector((GX + r * math.cos(TAU * i / 26.0), 0.19,
                        GZ + r * math.sin(TAU * i / 26.0))) for i in range(27)]
        P.raw(L.tube(ring, 0.016, 6), 'dark')
    # THE MALLET - heavier head, shorter haft, still the clear diagonal
    limb(P, [(X + 0.58, -0.14, 1.18), (X + 0.86, 0.06, 1.78)], 0.052, 0.044, 'bone')
    P.raw(aim(L.cone(0.21, 0.21, 0.44, 12), (X + 0.86, 0.06, 1.78), (0.50, 0.30, 1.0)), 'dark')
    P.raw(aim(L.cone(0.22, 0.215, 0.05, 12), (X + 0.86, 0.06, 1.78), (0.50, 0.30, 1.0)), 'bone')
    # THE BATON down at his left - the parade tool
    limb(P, [(X - 0.62, -0.20, 0.58), (X - 0.66, -0.24, 0.22)], 0.034, 0.026, 'bone')
    return P


BUILDERS.update({
    "drillmaster_chibi": drillmaster_chibi,
    "drillmaster_tall": drillmaster,
    "drillmaster_chibi_tall": drillmaster_chibi,
})

# ===========================================================================
# REGISTER CONVERSION, CREATURE 2 OF 14 - THE STOKER
# The Drillmaster above is the worked example and this follows it exactly:
# legs to 21% of the height, head 55% across, no neck, a dark collar in the
# seam, mitts for hands, and a face of two DARK ovals sunk under the skull.
# Measured off Knight.glb in the idle pose, as that one was.
# NOTHING ABOUT THE IDEA CHANGES - box chest with a lit grate in it, tall
# flue off the far shoulder, rake running down into the floor on the other
# side, fuel basket at the heels. Only the man carrying them is rebuilt.
# Authored to the same 2.40 m as the original so the pair sheet compares ONE
# thing. The height in bestiary.gd is the GAME BUILD lane's number, not mine.
# ===========================================================================
CANON.update({
    "stoker_chibi": ("The Stoker (chibi)", 2.40, (0.44, 0.38, 0.36), (1.00, 0.42, 0.12),
                     "firepit",
                     "IT IS ONLY AS BIG AS THE FIRE - rebuilt in the game's own proportions",
                     0.70, "The pit has been fed."),
})


def stoker_chibi():
    """The Stoker in the game's register. The original was a seven-head man
    with 0.105 m legs standing on a 0.94 m hip - beside a chibi knight he read
    as a pipe-cleaner holding a rake. Same fight, same props, same read
    (FIGURE, TALL FLUE, RAKE TO THE FLOOR), rebuilt on the Knight's measured
    proportions: hip at 21% of height, head 55% across, shoulders 0.86 wide.

    One decision that is NOT just proportion, and it is the Drillmaster's
    fault 2 applied here: the original gave him GLOWING eyes. Pale lit discs
    read as a mummy, and this creature already has the best lit face in the
    set - the grate in its chest. So the eyes go dark and the fire stays where
    the idea put it. There is now exactly one light on the body and it is the
    thing you have to starve."""
    P = Parts("stoker_chibi")
    X = -0.10
    H = 2.40
    HIP = 0.50                                  # 21% of the body's height
    # LEGS - stubs. The boot is nearly as wide as the leg is long.
    # PASS 3, FAULT 4 - THE VALUE BREAK, and it was the limbs, not the head.
    # `limb()` defaults to the 'bone' slot, so every arm and leg came out
    # PALER than the torso: a bone stick-figure wearing a brown box, with the
    # lightest things on the creature at its ankles. A figure reads when the
    # values stack - dark at the ground, mid through the mass, and the single
    # pale thing is the FACE, which is the only part a player has to find.
    # Limbs take the mid tone, boots and mitts the dark, the skull keeps the
    # bone, and nothing below the collar competes with the head any more.
    for s in (-1, 1):
        limb(P, [(X + s * 0.185, 0.04, HIP), (X + s * 0.205, 0.00, 0.24),
                 (X + s * 0.215, -0.04, 0.11)], 0.155, 0.145, 'body')
        P.add(L.box(0.32, 0.44, 0.14), 'dark', loc=(X + s * 0.215, -0.13, 0.07))
    # THE TORSO - still a BOX, not a barrel: the grate has to be a flat lit
    # face and not a glowing belly. That was the original's own reasoning and
    # it survives the conversion; only the box's proportions change.
    P.add(L.box(0.82, 0.48, 0.66), 'body', loc=(X - 0.04, -0.06, 0.86))
    P.add(L.box(0.86, 0.52, 0.14), 'dark', loc=(X - 0.02, -0.06, 0.60))       # belt
    P.add(aim(L.cone(0.40, 0.34, 0.12, 18), (X - 0.05, -0.08, 1.12),
              (0.0, 0.0, 1.0)), 'dark')                                       # collar
    for s in (-1, 1):                                                         # shoulders
        P.add(L.sphere(0.24, 0.23, 0.20, 12, 8), 'body',
              loc=(X - 0.04 + s * 0.42, -0.08, 1.14))
    # THE GRATE - five bars over a lit face, set into the front of the box.
    # PASS 2, FAULT 1: at 0.88 it sat on the WAIST of a chibi torso and read
    # as a lantern being carried, and it buried the belt. A chibi torso is
    # short, so the grate has to be smaller as well as higher or it is the
    # whole front of the creature. Up to 0.98, down to 0.46 x 0.36, which
    # leaves the belt at 0.60 clear below it and the collar clear above.
    P.add(L.box(0.46, 0.06, 0.36), 'glow', loc=(X - 0.04, -0.31, 0.98))
    for k in range(5):
        P.add(L.box(0.036, 0.08, 0.38), 'dark', loc=(X - 0.22 + k * 0.094, -0.33, 0.98))
    P.add(L.box(0.56, 0.09, 0.055), 'bone', loc=(X - 0.04, -0.33, 1.19))
    # THE HEAD - 1.00 across, straight on the shoulders, no neck.
    P.add(L.sphere(0.50, 0.48, 0.44, 18, 12), 'bone', loc=(X - 0.06, -0.12, 1.52))
    # the heat cap: a BOWL, not a cone with a point on it - the Drillmaster's
    # kettle-helm lesson. Rounded crown, no apex, sitting low over the brow.
    P.add(L.sphere(0.49, 0.47, 0.30, 18, 12), 'dark', loc=(X - 0.06, -0.12, 1.70))
    # PASS 3: the bowl alone read as a BOWL CUT OF HAIR from the front - a dark
    # dome resting on a pale skull with no edge between them. This is the
    # register fault the other twelve would have inherited, so it is solved
    # here before any of them are converted. Two parts, and the Drillmaster's
    # mushroom is the thing to avoid: the brim is only 0.08 proud of the skull
    # and sits 0.11 ABOVE the eyes, so it shades the brow without covering the
    # face, and a bone band in the seam gives the cap an edge to end at.
    P.add(aim(L.cone(0.575, 0.545, 0.055, 20), (X - 0.06, -0.14, 1.585),
              (0.0, -0.13, 1.0)), 'dark')
    P.add(aim(L.cone(0.505, 0.500, 0.050, 20), (X - 0.06, -0.12, 1.625),
              (0.0, 0.0, 1.0)), 'bone')
    # EYES, PASS 3. A single dark oval on a pale head is a HOLE, not an eye -
    # it read as blank goggles, which is the Drillmaster's fault 2 arriving
    # here in the opposite direction (his were pale discs, these were dark
    # ones; either way there is no eye INSIDE the eye). The hero's face is the
    # reference and it has three values: a dark socket, a pale eye in it, a
    # dark pupil in that. Built in that order, each standing a little proud of
    # the last, so the pale eye is separated from the pale skull by the socket
    # rather than by a line. head depth radius 0.48 at centre y -0.12, face at
    # -0.60: the stack runs -0.565 -> -0.615 and never floats in front of it.
    for s in (-1, 1):
        ex = X - 0.06 + s * 0.160
        P.add(L.sphere(0.090, 0.046, 0.120, 12, 8), 'dark', loc=(ex, -0.565, 1.47))
        P.add(L.sphere(0.058, 0.040, 0.082, 12, 8), 'bone', loc=(ex, -0.592, 1.47))
        P.add(L.sphere(0.030, 0.026, 0.044, 10, 7), 'dark', loc=(ex + s * 0.006, -0.614, 1.46))
    # ARMS - short, thick, mitts. Right hand on the rake, left at the hip.
    # PASS 3, FAULT 8: both arms were TWO-POINT and left the shoulder level or
    # rising, so each read as a ball on a stick held straight out - a T-pose
    # scarecrow, which is the one shape a chibi figure must not make. Both are
    # THREE-POINT now with a real elbow: the upper arm goes out and down, the
    # forearm comes FORWARD and in. A chibi arm is short enough that the elbow
    # is most of the read, so without it there is no arm, only a spoke.
    limb(P, [(X + 0.36, -0.12, 1.10), (X + 0.54, -0.24, 0.94),
             (X + 0.58, -0.38, 0.80)], 0.155, 0.125, 'body')
    P.add(L.sphere(0.175, 0.170, 0.160, 10, 7), 'dark', loc=(X + 0.60, -0.40, 0.78))
    # PASS 3, FAULT 9: the left mitt sat at x -0.64 and the flue stands at
    # -0.74 with a 0.115 radius - the hand was INSIDE the flue's column in the
    # front silhouette and the two merged into one dark lump. The forearm now
    # comes forward and in to the hip, mitt at -0.44: clear of the flue's
    # near edge, in FRONT of the torso in y, and reading against the body
    # instead of against the chimney.
    limb(P, [(X - 0.38, -0.12, 1.10), (X - 0.46, -0.22, 0.92),
             (X - 0.36, -0.32, 0.74)], 0.155, 0.125, 'body')
    P.add(L.sphere(0.175, 0.170, 0.160, 10, 7), 'dark', loc=(X - 0.34, -0.34, 0.70))
    # THE FLUE off the far shoulder - the tall vertical of the silhouette
    FX = X - 0.64
    limb(P, [(FX, 0.24, 1.08), (FX - 0.06, 0.26, 2.30)], 0.115, 0.095, 'dark')
    for k in range(2):
        P.add(aim(L.cone(0.148, 0.148, 0.038, 12), (FX - 0.02 * k, 0.25, 1.50 + k * 0.38),
                  (-0.05, 0.0, 1.0)), 'bone')
    P.add(aim(L.cone(0.125, 0.158, 0.11, 12), (FX - 0.06, 0.26, 2.28), (-0.05, 0.0, 1.0)), 'dark')
    P.add(L.sphere(0.125, 0.125, 0.048, 12, 6), 'glow', loc=(FX - 0.07, 0.26, 2.37))
    limb(P, [(FX + 0.16, 0.18, 1.18), (FX + 0.02, 0.24, 1.10)], 0.054, 0.044, 'bone')
    # THE RAKE - 1.9 m of haft running down into the floor on his right
    # the haft runs THROUGH the fist and a little past it: a man holding a rake
    # grips it part-way up, and the butt above the hand is what says "held"
    # rather than "attached at the wrist".
    haft = [Vector((X + 0.48, -0.31, 1.15)), Vector((X + 0.60, -0.41, 0.78)),
            Vector((X + 1.06, -0.56, 0.52)), Vector((X + 1.48, -0.70, 0.30)),
            Vector((X + 1.78, -0.80, 0.14))]
    P.raw(L.tube(haft, [0.038, 0.050, 0.046, 0.040, 0.036], 8), 'bone')
    P.add(L.box(0.54, 0.11, 0.075), 'dark', loc=(X + 1.78, -0.80, 0.13), rot=(0.0, -0.34, 0.0))
    for k in range(4):
        P.raw(aim(L.cone(0.032, 0.0, 0.21, 6), (X + 1.62 + k * 0.145, -0.80, 0.11),
                  (0.42, -0.10, -1.0)), 'dark')
    # the fuel basket at his heels - the thing the party has to get to
    P.raw(aim(L.cone(0.36, 0.42, 0.44, 14, cap=False), (X - 0.34, 0.56, 0.0),
              (0.0, 0.08, 1.0)), 'bone')
    for k in range(3):
        P.add(L.box(0.11, 0.11, 0.36), 'dark', loc=(X - 0.38 + k * 0.11, 0.58, 0.48),
              rot=(0.0, 0.18 - 0.16 * k, 0.0))
    P.add(L.sphere(0.32, 0.28, 0.05, 14, 6), 'glow', loc=(X - 0.34, 0.56, 0.06))
    return P


BUILDERS.update({"stoker_chibi": stoker_chibi})


# ===========================================================================
# REGISTER CONVERSION, CREATURE 3 OF 14 - THE GAOLER
# The Drillmaster is the worked example and the Stoker is the second; this
# follows both. Legs to 21% of the height, head 0.42 of the height across,
# NO NECK with a dark collar in the seam, mitts for hands, LIMBS IN THE MID
# TONE (the Stoker's fault 4 - limb() defaults to 'bone' and makes a pale
# stick-figure), and THREE-POINT arms with a real elbow (its fault 8).
#
# NOTHING ABOUT THE IDEA CHANGES - a hook on a chain, the chain coiled flat on
# the floor behind him, keys on the hip, no face. Only the man is rebuilt.
#
# THREE DECISIONS THIS CREATURE FORCED THAT THE FIRST TWO DID NOT:
#
#  1. THE STOOP CANNOT BE PAID FOR IN HEIGHT. The original's whole character
#     is a man bent double over years of hauling, and a bent man is SHORTER.
#     But the pair sheet only means anything if both are authored at the same
#     2.35 m, so the chibi one must still top out at 2.35. The stoop therefore
#     reads as LEAN and as CLOTH: the torso's axis runs forward, the head sits
#     forward of the shoulders, and the hood's mantle falls over them. If Mr. E
#     wants him to stand shorter than the party that is bestiary.gd's `h`, a
#     game build number, and not mine.
#  2. THE HOOD IS THE HEAD, which is the one place this creature is EASIER
#     than the other two. The Stoker's pass-3 register fault was a dark cap on
#     a pale skull reading as a bowl cut; the Gaoler never has a pale skull to
#     put a cap on. The head is dark cloth all through and the single pale
#     thing above the ground is the iron faceplate - exactly the value stack
#     the hero's own face uses, arrived at by the creature's own design.
#  3. THE APRON IS DROPPED, AND THAT IS A REGISTER DECISION. The original's
#     flat leather panel existed for one stated reason: "so the legs read as
#     thin". Chibi legs are thick stubs, so the reason is gone - and any value
#     it could take now either merges with the torso ('body'), merges with the
#     boots ('dark'), or becomes the brightest large shape on the creature
#     ('bone') and competes with the face. The belt keeps the hip read instead.
# ===========================================================================
CANON.update({
    "gaoler_chibi": ("The Gaoler (chibi)", 2.35, (0.52, 0.50, 0.46), (0.95, 0.58, 0.20),
                     "prison",
                     "IT DRAGS - rebuilt in the game's own proportions",
                     0.80, "A chain is paying out in the dark."),
})


def gaoler_chibi():
    """The Gaoler in the game's register. The original was a seven-head man on
    0.085 m legs with a 1.16 m hip, stooped over them - beside a chibi knight
    he read as a pipe-cleaner in an apron. Same fight, same props, same read
    (HOODED FIGURE, HOOK OUT ON ONE SIDE, CHAIN COILED ON THE FLOOR), rebuilt
    on the Knight's measured proportions: hip at 21% of height, head 0.99
    across, shoulders 0.80 wide.

    The hook is the mechanic and a chibi arm is SHORT, which is the real
    problem here: the original bought the hook's reach with a 1.22 m arm and
    that arm no longer exists. The reach is bought back by the shank - the
    hook's own shaft runs THROUGH the fist and past it, so the iron carries
    the silhouette out to 1.66 where the arm only gets to 1.07, and the haft
    above the hand is what says HELD rather than attached at the wrist."""
    P = Parts("gaoler_chibi")
    H = 2.35
    HIP = 0.49                                  # 21% of the body's height
    # LEGS - stubs in the MID tone, boots dark and nearly as wide as the leg
    # is long. Not limb()'s default 'bone': that is the Stoker's fault 4.
    for s in (-1, 1):
        limb(P, [(s * 0.185, 0.08, HIP), (s * 0.205, 0.02, 0.23),
                 (s * 0.215, -0.04, 0.10)], 0.155, 0.145, 'body')
        P.add(L.box(0.32, 0.44, 0.14), 'dark', loc=(s * 0.215, -0.13, 0.07))
    # THE TORSO - one mass hip to shoulder, and its axis LEANS FORWARD: hip at
    # y +0.16, shoulder at y -0.18. That lean is the whole stoop, because the
    # height cannot be spent on it (decision 1 above).
    # PASS 2, FAULT 2 - THE STOOP WAS GONE AND THE STOOP IS THE CHARACTER.
    # Pass 1 leant the torso 0.34 m over an 0.81 m rise and on a chibi that is
    # nothing: he stood bolt upright, which the original's own docstring says
    # he must never do ("never reads as an adventurer standing up straight").
    # A chibi cannot be bent at the waist - there is no waist - so the stoop is
    # bought in four places AT ONCE, which is why this is one change and not
    # four: the torso axis runs further forward and the shoulder drops, the
    # mantle tilts so its BACK rim stands higher than its front (the hump), the
    # head moves out over the toes, and the face sits LOW on the hood instead
    # of centred. The height cannot pay for it - the pair sheet needs both at
    # 2.35 - so the hood's crown and its tail keep the top of the silhouette
    # while everything a player reads as a face goes down and forward.
    limb(P, [(0.0, 0.22, 0.47), (0.0, 0.04, 0.86), (0.0, -0.28, 1.24)],
         0.36, 0.38, 'body')
    P.add(L.box(0.86, 0.46, 0.14), 'dark', loc=(0.0, 0.10, 0.70))            # belt
    P.add(aim(L.cone(0.40, 0.33, 0.12, 18), (0.0, -0.30, 1.26),
              (0.0, -0.34, 1.0)), 'dark')                                    # collar
    # SHOULDERS kept DELIBERATELY SMALL. The Stoker's standing fault list says
    # its shoulder spheres overhang the upper arms; here the sphere is 0.19 and
    # the upper arm 0.165, so the arm leaves the shoulder almost flush.
    for s in (-1, 1):
        P.add(L.sphere(0.19, 0.185, 0.175, 12, 8), 'body',
              loc=(s * 0.40, -0.28, 1.25))
    # THE MANTLE - the hood's cloth continuing down over the shoulders. This is
    # what gives a dark head a base to grow out of instead of balancing on a
    # neck it does not have.
    P.add(aim(L.cone(0.62, 0.34, 0.36, 20, cap=False), (0.0, -0.26, 1.08),
              (0.0, -0.40, 1.0)), 'dark')
    # THE HEAD IS THE HOOD - 0.99 across, sitting forward of the shoulders,
    # and topped by a hood POINT falling backward so nothing can read it as a
    # helmet. Head top plus the point lands at 2.33 of 2.35.
    # PASS 2, FAULT 1 - THE HOOD POINT WAS A WIZARD'S HAT. A cone standing on
    # top of the dome, with a seam across the crown where the two met, is a
    # POINTED HAT whatever the comment calls it - the Drillmaster's kettle-helm
    # mushroom arriving here in a third form. A hood's point does not stand up,
    # it FALLS BACKWARD: the cloth is one piece that bulges back over the skull
    # and tapers away down the spine. So the head is deeper in y than it is
    # wide, and the point is a tapering tail hanging down the back.
    P.add(L.sphere(0.47, 0.54, 0.46, 18, 12), 'dark', loc=(0.0, -0.40, 1.76))
    # PASS 3, FAULT 3 - THE TAIL WAS A RABBIT EAR. A tapering tube leaving the
    # crown and standing back from it is a flat paddle from the side and a dark
    # V from the back: the wizard's hat of pass 1 lying down. Cloth over a head
    # does not project anywhere. It GATHERS AT THE NAPE, which is also where
    # the weight of a hood actually hangs, so the point becomes a bunched mass
    # behind and below the skull - and that mass doubles as the hump this
    # stooped figure wants at the top of its spine.
    P.add(L.sphere(0.34, 0.30, 0.26, 14, 10), 'dark', loc=(0.0, 0.14, 1.66))
    # THE FACEPLATE - a dished plate of iron where a face should be, set INTO
    # the hood (hood front is y -0.81, the plate sits at -0.76) so the cloth
    # overhangs it. The single pale thing above the ground.
    P.add(L.sphere(0.29, 0.060, 0.26, 16, 10), 'bone', loc=(0.0, -0.860, 1.62))
    # the hood's brow edge, 0.04 clear of the plate's top: the Stoker's cap
    # lesson, which is that a dark dome needs an EDGE or it is hair.
    P.add(aim(L.cone(0.50, 0.43, 0.075, 20), (0.0, -0.38, 1.92),
              (0.0, -0.30, 1.0)), 'dark')
    # EYE SLOTS, and they are NOT the three-value eye the Stoker ended with.
    # That stack - dark socket, pale eye, dark pupil - is how you build an EYE.
    # This creature has no eye: it has a plate with two slots cut in it, and
    # the slots are horizontal because that is what a slot in a plate is. Two
    # dark bars standing a little proud of the pale plate, nothing inside them.
    for s in (-1, 1):
        P.add(L.box(0.13, 0.06, 0.045), 'dark', loc=(s * 0.135, -0.930, 1.68))
    # ARMS - three-point with a real elbow: the upper arm out and down, the
    # forearm forward and in. A chibi arm is short enough that the elbow IS
    # the read, and without it the arm is a spoke (the Stoker's fault 8).
    limb(P, [(-0.38, -0.26, 1.20), (-0.52, -0.38, 0.98),
             (-0.46, -0.52, 0.78)], 0.160, 0.130, 'body')
    P.add(L.sphere(0.175, 0.170, 0.160, 10, 7), 'dark', loc=(-0.44, -0.54, 0.73))
    limb(P, [(0.38, -0.26, 1.20), (0.72, -0.36, 1.08),
             (1.00, -0.42, 0.96)], 0.165, 0.135, 'body')
    P.add(L.sphere(0.190, 0.185, 0.175, 10, 7), 'dark', loc=(1.07, -0.44, 0.94))
    # THE SHANK through the fist, carrying the reach the arm lost
    limb(P, [(0.90, -0.36, 0.98), (1.26, -0.52, 0.90)], 0.060, 0.052, 'bone')
    # THE HOOK - a C of iron 0.68 across, heavier than the original's because
    # a chibi silhouette is bolder everywhere else and a hairline would vanish
    # again. The mechanic, kept readable at pane distance.
    hook = [Vector((1.32 + 0.34 * math.cos(a), -0.50 + 0.07 * math.cos(a),
                    0.56 + 0.34 * math.sin(a)))
            for a in [1.75 - 4.3 * (i / 10.0) for i in range(11)]]
    P.raw(L.tube(hook, [0.085, 0.082, 0.078, 0.072, 0.068, 0.062,
                        0.056, 0.050, 0.042, 0.032, 0.016], 8), 'bone')
    P.add(L.sphere(0.085, 0.085, 0.085, 9, 6), 'dark', loc=(1.26, -0.52, 0.93))
    # THE CHAIN: the flat spiral on the floor is the thing nothing else in the
    # dungeon has and it is unchanged in idea, moved back and out so the chibi
    # boots do not stand in it.
    coil = L.helix(2.6, 0.055, 0.14, 0.92, 0.26, steps=84, phase=0.4)
    coil = [Vector((p.x - 0.92, p.y + 0.56, p.z)) for p in coil]
    P.raw(L.tube(coil, 0.055, 6), 'dark')
    for i in range(0, len(coil) - 3, 9):
        P.add(L.sphere(0.072, 0.072, 0.034, 8, 6), 'dark',
              loc=(coil[i].x, coil[i].y, coil[i].z + 0.016))
    # the run from the coil up to the shank, routed OUTSIDE the left boot and
    # then across in FRONT of the figure at knee height - the Stoker's fault 9
    # in general form: never put a limb or a chain inside another object's
    # column in the front silhouette.
    run = [Vector((-0.66, 0.54, 0.14)), Vector((-0.52, -0.18, 0.16)),
           Vector((0.06, -0.60, 0.22)), Vector((0.70, -0.66, 0.50)),
           Vector((1.12, -0.56, 0.84))]
    P.raw(L.tube(run, 0.052, 6), 'dark')
    # THE KEYS on the right hip - plain working kit, and small on purpose so
    # they do not become a second pale thing competing with the face.
    ring = [Vector((0.40 + 0.10 * math.cos(TAU * i / 14.0), -0.34,
                    0.60 + 0.10 * math.sin(TAU * i / 14.0))) for i in range(15)]
    P.raw(L.tube(ring, 0.016, 6), 'bone')
    for k in range(3):
        P.add(L.box(0.035, 0.02, 0.16), 'bone', loc=(0.36 + k * 0.045, -0.35, 0.44))
    return P


BUILDERS.update({"gaoler_chibi": gaoler_chibi})


# ===========================================================================
# REGISTER CONVERSION 4 OF 14 - THE SNUFFER
#
# The first three conversions were MEN: seven-head realistic figures with 0.10 m
# limbs, rebuilt on the Knight's measured proportions. THE SNUFFER IS NOT A MAN.
# It is a lamp-stand that walks, and it would be easy to call it skipped on that
# ground the way the Scrapwright (a machine) and the Bellman (a shroud) are
# skipped - MY OWN SKIP PROPOSAL, recorded 16 Nov, and it stands for those two.
#
# IT IS NOT SKIPPED, AND HERE IS WHY: register is not the same thing as
# man-proportions. Register is HOW MUCH MASS A SHAPE CARRIES AND HOW MANY SHAPES
# THERE ARE. The Scrapwright and the Bellman are already bold masses - a lopsided
# mound and a hanging shroud - so they read beside a chibi knight without being
# touched. THE SNUFFER IS MADE OF WIRE. Measured off its own builder:
#     tripod legs   r 0.070 -> 0.055
#     column        r 0.105 -> 0.075
#     cross-arms    r 0.042 tubes
#     flute ribs    r 0.016, and PALE ('bone')
#     candles       r 0.040 - 0.045, EIGHTEEN of them
# A hero's arm is about 0.29 thick. A 0.042 bar beside it is a hairline, and
# eighteen pale 0.04 spikes are not eighteen candles at pane distance, they are
# FUZZ. So the creature reads as one big dark hat floating on a cloud of lint -
# the same failure as the pipe-cleaner men, arriving in the one form a
# non-humanoid can have it.
#
# TWO THINGS THIS CONVERSION FORCED THAT THE THREE MEN DID NOT:
#
#  1. THE FIX IS COUNT, NOT ONLY THICKNESS. On a man you thicken a limb and the
#     limb is still one limb. Here, thickening eighteen candles to read at pane
#     distance would weld them into a hedge. So eighteen become SIX, each one
#     twice as thick, and the six ring-candles round the column are dropped
#     outright. Fewer, bigger, countable - and the thing a player must count is
#     how many lights are left, so a candle that cannot be counted is a
#     mechanic that cannot be read.
#  2. THE PALE IS A BUDGET AND THE RIBS WERE SPENDING IT. The Stoker's fault 4
#     was limb() defaulting to 'bone' and making a pale stick-figure. The same
#     fault is here in object form: four PALE flute ribs up a dark column, plus
#     eighteen pale candles, so the pale was spread as hairlines over the whole
#     body while the ONE LIT CANDLE - the only colour, the mechanic, the whole
#     point - was a 0.045 stub. The ribs are gone, the pale is concentrated in
#     six fat stubs, and the lit one is the biggest candle on the creature.
#
# NOTHING ABOUT THE IDEA CHANGES: a tripod lamp-stand with a snuffer cone where
# a head belongs, dead candles on two cross-arms, and one live flame held out in
# its own grip. Authored at the same 2.60 m so the pair sheet compares ONE thing.
# ===========================================================================
CANON.update({
    "snuffer_chibi": ("The Snuffer (chibi)", 2.60, (0.58, 0.60, 0.66), (1.00, 0.86, 0.52),
                      "shrine",
                      "IT TAKES THE LIGHT - rebuilt in the game's own register",
                      0.90, "The nearest lamp has gone out."),
})


def snuffer_chibi():
    """The Snuffer in the game's register. Same silhouette read - A LAMP-STAND
    THAT WALKS, WIDE CONE ON TOP, ONE LIT CANDLE OUT TO ONE SIDE - with every
    member thickened into something a chibi knight can stand beside, and the
    candle count cut from eighteen to six so they can be counted."""
    P = Parts("snuffer_chibi")
    # --- THE TRIPOD. Three thick legs on bold pads. It is still furniture, not
    # a man, so there are three of them and they splay - but each is a stub the
    # weight of a chibi leg, not a wire.
    for k in range(3):
        a = 0.52 + TAU * k / 3.0
        x, y = math.cos(a), math.sin(a)
        limb(P, [(x * 0.09, y * 0.09, 0.74), (x * 0.32, y * 0.32, 0.38),
                 (x * 0.47, y * 0.47, 0.11)], 0.138, 0.112, 'body')
        P.add(aim(L.cone(0.215, 0.175, 0.11, 12), (x * 0.47, y * 0.47, 0.0),
                  (0.0, 0.0, 1.0)), 'dark')
    # --- THE COLUMN. One bold mass hip-to-head, 0.26 at the foot. The four pale
    # flute ribs are GONE (see 2 above); two dark collars give the joints the
    # read the ribs were meant to give, as mass instead of as hairlines.
    limb(P, [(0.0, 0.0, 0.58), (0.0, 0.0, 1.24), (0.0, 0.0, 1.92)], 0.26, 0.19, 'body')
    _ring(P, (0.0, 0.0, 0.64), 0.270, axis='z', slot='dark', rad=0.055, n=20)
    _ring(P, (0.0, 0.0, 1.46), 0.225, axis='z', slot='dark', rad=0.050, n=20)
    # --- TWO CROSS-ARMS, a T then a t, both thick enough to read. FOUR candles
    # on the wide arm and TWO on the narrow: six, countable, each a fat stub.
    c = 0
    for z, half, brad, axes in ((1.26, 1.12, 0.098, ('x', 'y')), (1.62, 0.94, 0.086, ('y',))):
        for axis in axes:
            ends = [(-half, 0.0), (half, 0.0)] if axis == 'x' else [(0.0, -half), (0.0, half)]
            bar = [Vector((ends[0][0], ends[0][1], z)), Vector((0.0, 0.0, z + 0.06)),
                   Vector((ends[1][0], ends[1][1], z))]
            P.raw(L.tube(bar, brad, 8), 'body')
            for ex, ey in ends:
                x, y = ex * 0.90, ey * 0.90
                P.add(aim(L.cone(0.165, 0.115, 0.085, 12), (x, y, z - 0.02),
                          (0.0, 0.0, 1.0)), 'dark')                   # the cup
                stub = 0.34 - (0.09 if c % 2 else 0.0) - 0.04 * (c % 3)   # burnt unevenly
                P.add(aim(L.cone(0.090, 0.078, stub, 10), (x, y, z + 0.04),
                          (0.0, 0.0, 1.0)), 'bone')
                P.add(L.sphere(0.040, 0.040, 0.034, 8, 6), 'dark',
                      loc=(x, y, z + 0.04 + stub))                    # dead wick
                c += 1
    # --- THE HEAD: the snuffer cone, apex up, on a short thick neck. A dark RIM
    # round its mouth, which is the Stoker's cap lesson in another slot - a big
    # smooth cone needs an edge or it is a beanie.
    limb(P, [(0.0, 0.0, 1.88), (0.0, -0.04, 2.02)], 0.150, 0.170, 'body')
    P.raw(aim(L.cone(0.74, 0.03, 0.56, 22), (0.0, -0.04, 1.99), (0.0, 0.0, 1.0)), 'body')
    P.raw(aim(L.cone(0.78, 0.74, 0.080, 22), (0.0, -0.04, 1.99), (0.0, 0.0, 1.0)), 'dark')
    P.add(L.sphere(0.075, 0.075, 0.070, 10, 7), 'dark', loc=(0.0, -0.04, 2.53))
    for k in range(5):                     # soot streaks, now ribs not threads
        a = -0.9 + 0.45 * k
        P.raw(L.tube([Vector((0.68 * math.cos(a), -0.04 + 0.68 * math.sin(a), 2.03)),
                      Vector((0.24 * math.cos(a), -0.04 + 0.24 * math.sin(a), 2.42))],
                     0.030, 6), 'dark')
    # --- THE ONE LIGHT IT HAS TAKEN. A chibi arm is SHORT, so the reach comes
    # from the elbow being real rather than from length, and the grip is a mitt
    # the size of the hero's own. This is the biggest candle on the creature and
    # the only colour in the outline - it is the mechanic, so it gets the pale.
    limb(P, [(0.10, -0.12, 1.30), (0.42, -0.40, 1.22),
             (0.58, -0.52, 1.30)], 0.130, 0.105, 'body')
    P.add(L.sphere(0.145, 0.140, 0.130, 10, 7), 'dark', loc=(0.60, -0.54, 1.31))
    P.add(aim(L.cone(0.19, 0.13, 0.085, 12), (0.60, -0.54, 1.38), (0.0, 0.0, 1.0)), 'dark')
    P.add(aim(L.cone(0.095, 0.082, 0.22, 10), (0.60, -0.54, 1.44), (0.0, 0.0, 1.0)), 'bone')
    P.add(L.sphere(0.072, 0.072, 0.110, 10, 8), 'glow', loc=(0.60, -0.54, 1.73))
    return P
# PASS 2, FAULT 1 - I OVERCORRECTED AND PUT THE MASS AT THE BOTTOM. Pass 1 took
# every wire member to a chibi weight at once, so the three splayed legs (0.180,
# out to 0.56) became the heaviest thing on the creature and it read as a CAMERA
# TRIPOD or a three-legged stool walking - bottom-heavy, when a lamp-stand's
# whole read is a heavy light held up on a slim stand. The cone had also stopped
# dominating: at 0.58 it was no wider than the body under it, so the "snuffer
# cone where a head belongs" read went with it. This is ONE read, not three
# changes - WHERE THE MASS SITS - so it is bought in the three places that make
# it: legs thinner (0.138) and drawn in (0.47), cone up to 0.74 and 0.56 tall,
# and the column kept exactly as it was so the change is legible as a ratio.
# Lowering the cone to 1.99 to keep the top at 2.60 also CLOSED A CLIP I found
# in the pass 1 sheet: the upper arm's two candles topped out at 2.22 inside the
# cone's flare. The arms drop to 1.30 / 1.66 and the cone now overhangs them,
# which is the head-over-shoulders read the original had and pass 1 lost.
#
# PASS 3, FAULT 2 - THE CONE ATE THE CANDLES AND THE THING BECAME A MUSHROOM.
# Pass 2 bought the top-heavy read and paid for it with the mechanic: a 0.78 cap
# over 0.70 and 0.46 cross-arms puts EVERY candle inside the cone's overhang, in
# its shade, and the upper two vanish behind it from the front. You cannot count
# them - and by my own argument in note 1 above, a candle that cannot be counted
# is a mechanic that cannot be read. The silhouette had gone with it: a wide cap
# on a fat stubby stem is a TOADSTOOL, not a lamp-stand.
# ONE change closes both, because they are one fact: THE ARMS MUST REACH PAST
# THE RIM. Half-spans 0.70 / 0.46 -> 1.12 / 0.94, so every cup sits outside the
# 0.78 cap with air above it, the six candles are countable from the front, and
# the outline is a CANDELABRA with a snuffer for a head again. Nothing else is
# touched: not the cone, not the legs, not the column.
#
# PASS 4, FAULT 3 - FROM THE SIDE IT WAS A MAN IN A STRAW HAT. Both cross-arms
# ran on X only, so at azimuth 90 every candle collapsed onto the column and the
# candelabra read vanished: what was left was a conical hat over a stumpy body
# with legs, holding a light - which is a FIGURE, and the one thing a miniboss
# may never read as. This fault is INHERITED, not introduced - the original's
# arms are X-only too - but the chibi register makes it worse, because a bolder
# body has more to be mistaken for a torso.
# ONE change, and it costs NO extra candles: the lower tier becomes a CROSS (two
# bars, one candle at each of its four ends) and the upper bar is turned onto Y.
# Still six, still countable, but now every view has a wide pair standing clear
# of the column - front reads off the lower X bar, side off the lower Y bar and
# the upper one together. The count is the mechanic, so the count did not move.


BUILDERS.update({"snuffer_chibi": snuffer_chibi})


# ===========================================================================
# REGISTER CONVERSION 5 OF 14 - THE SEXTON. Fifth of the fourteen rebuilt in
# the game's own register; see the block above drillmaster_chibi for the
# measured Knight proportions and the one above snuffer_chibi for the rule
# that register is MASS AND COUNT, not man-proportions.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/sexton/hero_front.png, hero_side.png):
# A POST OFFICE SORTING RACK WITH A WIRE MAN UNDER IT. Measured off the
# builder, against a hero arm 0.29 thick:
#     legs            0.100 / 0.082
#     torso           0.235 / 0.215   (the ONE bold member it has)
#     hod uprights    0.055 / 0.042
#     cell collars    0.075 slabs, 0.13 deep, NINE cells
#     arms            0.072 / 0.054
#     spade haft      0.055 / 0.048
# Three faults fall straight out of that:
#  1. EVERY MEMBER EXCEPT THE TORSO IS A WIRE, so the man is a pipe-cleaner
#     holding a window frame, and from the SIDE he disappears altogether -
#     a flat board on two threads.
#  2. NINE THIN CELLS ARE A GRID, NOT GRAVES. At pane distance 0.075 collars
#     with 0.40 holes read as glazing bars: it is a window, or a bookcase, and
#     the lit plugs read as ENVELOPES in pigeonholes. The crypt read is gone.
#  3. THE COUNT IS THE MECHANIC AND NINE IS TOO MANY TO COUNT. Four lit among
#     nine is a pattern to be scanned; the Snuffer's lesson applies in its own
#     form - a rising that cannot be counted from the doorway is a mechanic
#     that cannot be read.
#
# SO THE CONVERSION IS THE SNUFFER'S, NOT THE DRILLMASTER'S: it is not enough
# to fatten the man. SIX CELLS, not nine, each one big enough that the hole is
# a NICHE - and the lit count stays FOUR, because four risings is the fight.
# The silhouette read is kept exactly: a tall tilted rectangle of cells carried
# high, a deep stoop under it, the spade a long diagonal to the floor the other
# way. Nothing in this file is a grid and nothing else is, still.
# Authored at the same 2.45 m so the pair sheet compares ONE thing.
# ===========================================================================
CANON.update({
    "sexton_chibi": ("The Sexton (chibi)", 2.45, (0.50, 0.54, 0.48), (0.72, 1.00, 0.80),
                     "crypt",
                     "IT WILL NOT STAY DOWN - rebuilt in the game's own register",
                     0.85, "A spade is working somewhere in the dark."),
})


def sexton_chibi():
    """The Sexton in the game's register. Same read - A WALL OF LIT GRAVES
    CARRIED ON A STOOPED BACK, SPADE DOWN TO THE FLOOR - with every wire member
    taken to a chibi weight and the niches cut from nine to six so the four lit
    ones can be COUNTED from the doorway."""
    P = Parts("sexton_chibi")
    HIP = 0.52                                   # 21% of 2.45, off the Knight
    # --- LEGS. Stubs planted wide, boots almost as wide as the leg is long.
    # Everything above him is heavy and he is braced, not walking.
    for s in (-1, 1):
        limb(P, [(s * 0.21, 0.08, HIP), (s * 0.25, 0.00, 0.26),
                 (s * 0.26, -0.06, 0.11)], 0.150, 0.138)
        P.add(L.box(0.32, 0.44, 0.13), 'dark', loc=(s * 0.26, -0.14, 0.065))
    # --- TORSO. One barrel, bowed hard FORWARD under the load - the stoop is
    # the whole posture and a chibi has no waist to bend at, so the barrel
    # itself leans and the shoulders come down and forward over the toes.
    # PASS 3, FAULT 2 - THE MAN WAS BEHIND HIS OWN LOAD. Pass 2 killed the
    # drawers but left a solid rectangle with a dark blob under it: head,
    # shoulders and hod frame all sat INSIDE the wall's outline, so from the
    # front there was no man carrying anything - there was a cabinet with legs,
    # which is the Porter's read, not the Sexton's. The fix is not to shrink
    # the wall (the wall is the mechanic). IT IS TO DEEPEN THE STOOP until the
    # head comes out from under the load and breaks the outline below it. One
    # read - where the man is relative to what he carries - bought in the spine,
    # the shoulders and the head together, because they are one chain.
    # PASS 4, FAULT 3 - I OVERCORRECTED AND BUILT A QUADRUPED. Pass 3 bought
    # the head out from under the load by laying the spine almost flat: from
    # the SIDE the barrel ran horizontal at shoulder height with the head hung
    # off the front of it and both mitts on the floor, and what stood there was
    # a DOG, not a man under a hod. A miniboss may not read as a hero; it may
    # not read as somebody's wolfhound either. Half the stoop back: the head
    # still clears the wall's bottom edge from the front, and from the side the
    # spine is a diagonal again.
    limb(P, [(0.0, 0.10, HIP - 0.02), (0.0, -0.14, 0.88), (0.0, -0.38, 1.12)],
         0.37, 0.33, 'body')
    P.add(L.box(0.82, 0.36, 0.14), 'dark', loc=(0.0, -0.06, 0.82))            # belt
    for s in (-1, 1):
        P.add(L.sphere(0.225, 0.215, 0.195, 12, 8), 'body', loc=(s * 0.38, -0.36, 1.12))
    # --- THE HEAD. A leather cowl bowed low over a blank plate - he is a
    # working sexton, not a wraith, so there is no skull. Dark cowl, pale
    # plate, the same three-value break the hero's head uses. Hung FORWARD of
    # the shoulders and below them, the way a head hangs off a bowed back.
    # PASS 5, FAULT 4 - THE COWL WAS A SAUCER. A 0.44 brim cone over a dark
    # dome, on a chibi with no neck, is a lampshade from the front and a
    # conical straw hat from the side - the Snuffer's pass-4 fault arriving in
    # the slot where it does most harm, because the head is the one place a
    # viewer looks to tell a man from a thing. A cowl is not a brim: it is
    # cloth drawn BACK over the skull, falling onto the shoulders behind, with
    # a short peak forward over the face. No disc, nothing wider than the head.
    P.add(L.sphere(0.300, 0.300, 0.270, 16, 11), 'bone', loc=(0.0, -0.62, 1.14))
    P.add(L.sphere(0.335, 0.345, 0.300, 16, 11), 'dark', loc=(0.0, -0.50, 1.22))
    P.raw(aim(L.cone(0.265, 0.165, 0.26, 14), (0.0, -0.64, 1.26), (0.0, -0.80, -0.26)), 'dark')
    P.add(L.sphere(0.290, 0.250, 0.175, 14, 9), 'dark', loc=(0.0, -0.26, 1.16))
    for s in (-1, 1):
        P.add(L.sphere(0.052, 0.036, 0.080, 12, 8), 'dark',
              loc=(s * 0.112, -0.895, 1.11))
    # --- THE HOD FRAME. Two uprights off the hips raked back over the
    # shoulders, at a chibi weight: these carry a wall of stone and at 0.055
    # they were string.
    for s in (-1, 1):
        limb(P, [(s * 0.30, 0.18, 0.86), (s * 0.34, 0.30, 1.46),
                 (s * 0.36, 0.40, 2.12)], 0.105, 0.082, 'dark')
    P.add(L.box(0.86, 0.15, 0.15), 'dark', loc=(0.0, 0.24, 0.98))
    # --- THE NICHE WALL. SIX cells, 2 across x 3 up - the tall tilted
    # rectangle, kept - with members three times the original's and holes big
    # enough to be graves. FOUR are plugged and LIT: four risings left, and the
    # plugs stand proud so the count dents the outline from the front.
    LIT = {(0, 0), (1, 1), (0, 2), (1, 2)}
    cw, chh = 0.50, 0.46
    tk = 0.145                                   # was 0.075. A glazing bar -> a slab.
    pitch_x, pitch_z = cw + tk, chh + tk
    for i in range(2):
        for j in range(3):
            x = (i - 0.5) * pitch_x
            z = 1.06 + j * pitch_z
            y = 0.34 + j * 0.060                 # the rake, as a carried thing
            for dx, dz, sx, sz in ((0.0, (chh + tk) * 0.5, cw + tk, tk),
                                   (0.0, -(chh + tk) * 0.5, cw + tk, tk),
                                   ((cw + tk) * 0.5, 0.0, tk, chh),
                                   (-(cw + tk) * 0.5, 0.0, tk, chh)):
                P.add(L.box(sx, 0.26, sz), 'bone', loc=(x + dx, y, z + dz),
                      rot=(-0.14, 0.0, 0.0))
            if (i, j) in LIT:
                # PASS 2, FAULT 1 - IT WAS A CHEST OF DRAWERS. One read, bought
                # in the three places that made it: the plug filled the cell
                # face (a drawer front), a horizontal glow strip across it read
                # as the DRAWER LABEL, and a dark knob in the corner read as
                # the PULL. A grave plug is a rough stone STOPPER driven into a
                # hole: narrower than the mouth it blocks, standing well proud,
                # and the light is what leaks round it - so the glow becomes a
                # RIM in the gap, not a plate on the front, and the knob goes.
                P.add(L.box(cw * 0.60, 0.34, chh * 0.60), 'body',
                      loc=(x, y - 0.30, z), rot=(-0.14, 0.0, 0.0))
                P.add(L.box(cw * 0.70, 0.07, chh * 0.70), 'glow',
                      loc=(x, y - 0.05, z), rot=(-0.14, 0.0, 0.0))
    # frame edges, so the six read as ONE carried hod and not a stack
    for j, z in ((0, 1.06 - pitch_z * 0.56), (3, 1.06 + 2.56 * pitch_z)):
        P.add(L.box(2 * pitch_x + 0.14, 0.18, 0.12), 'dark',
              loc=(0.0, 0.34 + 0.060 * j, z))
    for s in (-1, 1):
        P.add(L.box(0.12, 0.18, 3 * pitch_z + 0.14), 'dark',
              loc=(s * (pitch_x + 0.05), 0.42, 1.06 + pitch_z))
    # --- THE SPADE. A chibi arm is SHORT, so the long diagonal comes from the
    # HAFT, not from the reach: both mitts on it low and forward, the blade on
    # the floor well out to his right. Haft 0.085 - at 0.055 it was a wire and
    # the diagonal, which is half the silhouette, was not there at all.
    limb(P, [(0.38, -0.36, 1.10), (0.52, -0.46, 0.88)], 0.145, 0.120)
    P.add(L.sphere(0.155, 0.150, 0.140, 10, 7), 'body', loc=(0.55, -0.48, 0.85))
    limb(P, [(-0.38, -0.36, 1.10), (-0.10, -0.52, 0.82)], 0.145, 0.120)
    P.add(L.sphere(0.155, 0.150, 0.140, 10, 7), 'body', loc=(-0.06, -0.54, 0.80))
    limb(P, [(-0.12, -0.54, 0.86), (0.96, -0.44, 0.28)], 0.085, 0.072, 'bone')
    P.raw(aim(L.box(0.46, 0.085, 0.56), (1.10, -0.39, 0.10), (0.52, -0.04, 1.0)), 'bone')
    P.raw(aim(L.cone(0.24, 0.018, 0.17, 4), (1.19, -0.39, -0.08), (0.52, -0.04, 1.0)), 'bone')
    # --- the spoil heap. There is a hole here, and it is bolder than three
    # pebbles: two mounds a chibi knight could trip on.
    for dx, dy, r in ((1.12, -0.66, 0.40), (1.40, -0.30, 0.27)):
        P.add(L.sphere(r, r * 0.86, r * 0.44, 10, 7), 'dark', loc=(dx, dy, r * 0.20))
    return P


BUILDERS.update({"sexton_chibi": sexton_chibi})


# ===========================================================================
# REGISTER CONVERSION 6 OF 14 - THE PORTER. Sixth of the fourteen rebuilt in
# the game's own register; see the block above drillmaster_chibi for the
# measured Knight proportions and the one above snuffer_chibi for the rule
# that register is MASS AND COUNT, not man-proportions.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/porter/hero_front|side|back.png):
# A MAN STANDING IN A WARDROBE HOLDING THREE SEPARATE PLANKS. Measured off the
# builder, against a hero arm 0.29 thick and a hero head 1.09 across:
#     legs            0.115 / 0.092
#     arms            0.090 / 0.068
#     torso           0.270 / 0.280   (the ONE bold member again)
#     head            0.155 sphere -> 0.31 across. A FIFTH of the hero's head.
#     drawbar         0.19 square, then BROKEN into five separate boxes
# Four faults fall out of that, and only the first is the usual one:
#  1. EVERY MEMBER EXCEPT THE TORSO IS A WIRE. Third conversion running.
#  2. THE WIDEST HORIZONTAL IN THE DUNGEON IS NOT A HORIZONTAL. The original
#     raked the bar by building it from a centre box plus two offset end boxes
#     plus two detached shoes, each nudged in y and z. On the sheet those read
#     as THREE SEPARATE PLANKS with iron rubble floating off the left end. The
#     rake was meant to stop either end hiding; what it actually did was break
#     the one member the whole creature is named for. A bar is ONE PIECE.
#  3. THE LEAF IS A SENTRY BOX. Square-on behind a man of the same width, it
#     stops being a door he carries and becomes a cabinet he stands in - and
#     from the SIDE the same slab is edge-on, a plank, and the mechanic is
#     gone from that view entirely. The fix is one change: YAW THE LEAF. Turned
#     22 degrees in plan it still reads narrow from the front, so the bar keeps
#     the width, and it shows a broad banded face from the side, where there
#     was nothing.
#  4. THE BACK OF THE LEAF IS BARE - a flat tan slab, every band and boss on
#     the front face only. That is the Gaoler's fault 5 and the Stoker's fault
#     2, and this is the conversion that stops carrying it: the bands wrap.
#
# AND THE CARRIED FAULT, TAKEN HERE BECAUSE 6 OF 14 HAS A HEAD (supervisor,
# 13:58): THE GAOLER'S FACEPLATE READS AS AN ANGRY CARTOON MASK. The Porter had
# the same plate in miniature - a pale `bone` slab on a dark helm with a dark
# slot across it and two glowing eyes behind - and at pane distance it is a toy
# robot. The diagnosis is not brightness, it is COUNT AND VALUE:
#     TWO apertures read as EYES however they are shaped. ONE reads as a SLIT.
#     A PALE plate on a dark head is a FACE. A DARK plate is a DOOR.
# So the Porter's helm is dark iron end to end with ONE unbroken sight slit
# under a brow shelf, and no eyes at all - "a door has no face either" is the
# original's own line and this is it kept. The pale value the three-value stack
# wants does not vanish, it MOVES to the oak: the bar is the pale thing, which
# is also the mechanic, so the brightest member and the dangerous one are the
# same object. Nothing vertical crosses the slit - a helm reinforce down the
# middle would cut it in two and hand the face straight back.
# Authored at the same 2.30 m so the pair sheet compares ONE thing.
# ===========================================================================
CANON.update({
    "porter_chibi": ("The Porter (chibi)", 2.30, (0.56, 0.46, 0.32), (0.95, 0.70, 0.34),
                     "keep",
                     "IT BARS THE WAY - rebuilt in the game's own register",
                     0.45, "A bar has dropped behind you."),
})


def porter_chibi():
    """The Porter in the game's register. Same read - THE WIDEST HORIZONTAL IN
    THE DUNGEON, A TALL BANDED LEAF BEHIND IT - with every wire member taken to
    a chibi weight, the drawbar rebuilt as ONE piece instead of five, the leaf
    yawed so it reads from the side, and the helm turned into a door."""
    P = Parts("porter_chibi")
    HIP = 0.48                                   # 21% of 2.30, off the Knight
    # --- LEGS. Stubs planted square. He is a post and he does not stoop: the
    # Sexton bends under his load, this one stands under his.
    for s in (-1, 1):
        limb(P, [(s * 0.21, 0.04, HIP), (s * 0.25, 0.00, 0.24),
                 (s * 0.26, -0.04, 0.10)], 0.150, 0.138)
        P.add(L.box(0.32, 0.44, 0.13), 'dark', loc=(s * 0.26, -0.12, 0.065))
    # --- TORSO. One upright barrel, wider than it is tall, no lean anywhere.
    limb(P, [(0.0, 0.06, HIP - 0.02), (0.0, 0.02, 0.80), (0.0, -0.02, 1.08)],
         0.38, 0.35, 'body')
    P.add(L.box(0.84, 0.36, 0.14), 'dark', loc=(0.0, 0.00, 0.76))             # belt
    for s in (-1, 1):
        P.add(L.sphere(0.235, 0.225, 0.200, 12, 8), 'body', loc=(s * 0.40, -0.02, 1.08))
    # --- THE HELM, AND IT IS THE CARRIED FAULT BEING CLOSED. Dark iron dome,
    # flat dark front, a brow shelf standing proud of it, and ONE slit. No pale
    # plate, no second aperture, nothing crossing the slit.
    # PASS 4, FAULT 3 - THE ONE SLIT CAME OUT AS TWO EYES, AND I DID NOT DECIDE
    # THAT, THE GEOMETRY DID. The head crop of pass 3 shows two bright
    # rectangles with a dark gap between them: a face, the exact read this
    # conversion exists to kill. Cause, measured rather than guessed: the dome
    # was 0.42 deep in y and bellied out to -0.54, while the plate's front face
    # sat at -0.51 and the slit at -0.52 - so the dome covered the MIDDLE of
    # the slit and left its two ends showing. THE LESSON, and it is general:
    # ONE APERTURE BECOMES TWO WHENEVER ANYTHING ROUND STANDS IN FRONT OF ITS
    # CENTRE. It has to be measured against everything forward of it, not
    # declared. The dome is shallowed to 0.30 so the flat plate is the forward
    # face of the helm, the slit stands 0.04 proud of the plate, and the brow
    # shelf is the only thing in front of it - above it, overhanging, where a
    # brow belongs and where it cannot cut the slit in half.
    P.add(L.sphere(0.400, 0.300, 0.380, 16, 11), 'dark', loc=(0.0, -0.10, 1.42))
    P.add(L.box(0.58, 0.14, 0.56), 'dark', loc=(0.0, -0.46, 1.40))
    P.add(L.box(0.64, 0.11, 0.13), 'dark', loc=(0.0, -0.60, 1.53))            # brow shelf
    P.add(L.box(0.46, 0.05, 0.055), 'glow', loc=(0.0, -0.545, 1.44))          # THE slit
    P.add(L.box(0.09, 0.44, 0.11), 'dark', loc=(0.0, -0.18, 1.78))            # crown comb
    # --- THE LEAF. Yawed 22 degrees in plan: narrow from the front so the bar
    # owns the width, a broad banded face from the side where there was a bare
    # plank, and the bands and bosses WRAP so the back is not a blank slab.
    # PASS 2, FAULT 1 - HE WAS STILL STANDING IN IT. Pass 1 bought the mass and
    # the yaw, and the leaf stopped being edge-on from the side - but a 2.16 m
    # slab anchored at chest height still runs ABOVE the man's helm, so from the
    # front his head is a dark lump inside the door's outline and from the back
    # he is gone altogether. A man does not carry a door over his head. It is
    # slung LOW, standing on its own bottom edge behind his heels, and his helm
    # clears the top of it - which is also the only way the helm gets a
    # silhouette, since this conversion's helm is dark on purpose.
    LX, LY, LZ = 0.0, 0.44, 0.86
    YAW, TIL = 0.38, 0.10

    def LP(lx, ly, lz):
        """A point in the leaf's own frame, tilted then yawed, then anchored."""
        y2 = ly * math.cos(TIL) - lz * math.sin(TIL)
        z2 = ly * math.sin(TIL) + lz * math.cos(TIL)
        return (LX + lx * math.cos(YAW) - y2 * math.sin(YAW),
                LY + lx * math.sin(YAW) + y2 * math.cos(YAW),
                LZ + z2)

    LR = (TIL, 0.0, YAW)
    P.add(L.box(0.92, 0.16, 1.76), 'body', loc=LP(0.0, 0.0, 0.0), rot=LR)
    for lz in (-0.62, -0.16, 0.30, 0.74):
        for ly in (-0.115, 0.115):
            P.add(L.box(1.00, 0.08, 0.13), 'dark', loc=LP(0.0, ly, lz), rot=LR)
            for s in (-1, 1):
                P.add(L.sphere(0.060, 0.050, 0.060, 8, 6), 'dark',
                      loc=LP(s * 0.32, ly * 1.42, lz))
    for s in (-1, 1):                                        # hinge straps, both faces
        for ly in (-0.105, 0.105):
            P.add(L.box(0.13, 0.09, 1.62), 'dark', loc=LP(s * 0.38, ly, 0.0), rot=LR)
    P.add(L.box(0.26, 0.10, 0.10), 'dark', loc=LP(0.0, -0.16, 0.62), rot=LR)  # pull ring bar
    for s in (-1, 1):                                        # the slung strap
        limb(P, [LP(s * 0.26, -0.14, 0.78), (s * 0.36, -0.12, 1.14)], 0.070, 0.058, 'dark')
    # --- THE DRAWBAR. ONE squared member, end to end, raked as a single piece
    # so neither shoe hides and nothing comes apart. 3.3 m of oak and the
    # palest thing on the creature, because it is the mechanic.
    # PASS 3, FAULT 2 - THE BAR CAME APART AT BOTH ENDS AGAIN, and the frame
    # proved it in numbers. Two things, one member: (a) the iron shoe's taper
    # was seated 0.10 OUTSIDE the end of the oak, so on the back sheet there is
    # a dark wedge floating clear of the bar - the original's exact fault
    # rebuilt by accident. The cone now starts ON the end point. (b) dropping
    # the leaf in pass 2 made the HELM the tallest thing, so the normaliser
    # scales the whole creature up by a quarter to reach 2.30 m and a 3.24 m
    # bar came out 4.05 m - the pair burst the fixed frame (6.69 m against
    # 5.60). Authored at 2.48 it lands at 3.10 m and is still, by a long way,
    # the widest horizontal down there.
    # PASS 5, FAULT 4 - THE BAR WAS CARRIED ACROSS HIS OWN FACE. At a mid
    # height of 1.23 with a 0.46 rake, the near end stood above the shoulder
    # and the oak ran under the chin and through the slit's line - so the two
    # loudest things on the creature, the mechanic and the one lit aperture,
    # fought each other at pane distance, and the arms and torso were hidden
    # behind the bar as well. Dropped to chest height and the rake halved: the
    # head keeps the top of the figure to itself, the bar keeps the width, and
    # the two reads stop overlapping. A drawbar is carried at the height of the
    # brackets it goes into, which is where the belt sockets already are.
    # PASS 6, FAULT 5 - FROM THE SIDE THE BAR WAS A POINT. Square across the
    # body it is 2.48 m of oak that the side camera sees end-on: three boxes
    # stacked at the lens, reading as a chimney, and the one member this
    # creature is named for contributes NOTHING to a third of its views. The
    # leaf's yaw fixed the same fault for the door in pass 1; the bar gets the
    # same treatment and for the same reason. 16 degrees in plan costs 4% of
    # the front width - it is still the widest horizontal down there - and buys
    # 0.72 m of visible length from the side, where there was none.
    A = Vector((-1.24, -1.14, 1.12))
    B = Vector((1.24, -0.42, 0.88))
    MIDP, DIR = (A + B) / 2.0, (B - A)
    P.raw(aim(L.box(0.26, 0.26, 2.56), MIDP, DIR), 'bone')
    for t, e in ((0.0, A), (1.0, B)):
        P.raw(aim(L.box(0.31, 0.31, 0.34), A + DIR * (0.94 if t else 0.06), DIR), 'dark')
        P.raw(aim(L.cone(0.155, 0.105, 0.22, 10), e, DIR if t else -DIR), 'dark')
    # --- ARMS. Short, thick, both mitts closed on the bar well forward of the
    # body, each at the height the bar actually is at that x - the original's
    # hands floated because the bar moved and they did not.
    for s in (-1, 1):
        bz = 1.00 - 0.24 * (s * 0.62 / 2.48)
        by = -0.78 + 0.72 * (s * 0.62 / 2.48)
        limb(P, [(s * 0.42, -0.06, 1.06), (s * 0.56, by * 0.52, (1.06 + bz) / 2.0 + 0.02),
                 (s * 0.62, by + 0.06, bz)], 0.150, 0.125)
        P.add(L.sphere(0.165, 0.160, 0.150, 10, 7), 'body', loc=(s * 0.63, by, bz))
        P.add(L.box(0.21, 0.32, 0.32), 'dark', loc=(s * 0.63, by - 0.02, bz))
    # --- the socket brackets he will drive the bar into, carried on the belt
    for s in (-1, 1):
        P.add(aim(L.cone(0.145, 0.115, 0.26, 10), (s * 0.44, -0.30, 0.84),
                  (0.0, -0.25, -1.0)), 'dark')
    return P


BUILDERS.update({"porter_chibi": porter_chibi})


# ===========================================================================
# REGISTER CONVERSION 7 OF 14 - THE TALLYMAN. Same rebuild in the game's own
# register; see the block above drillmaster_chibi for the measured Knight
# proportions and the one above snuffer_chibi for the rule that register is
# MASS AND COUNT, not man-proportions.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/tallyman/hero_front|side|back.png):
# A SURVEYOR'S TRIPOD WITH A WASHING LINE ON IT - and from the back, a clothes
# horse. Measured off the builder, against a hero arm 0.29 thick and a hero
# head 1.09 across:
#     legs            0.072 / 0.056
#     arms            0.062 / 0.040        fingers 0.020 / 0.012
#     quill           0.020 / 0.008        a HAIR at stream distance
#     frame uprights  0.08 boxes           bead wires 0.035
#     hanging cords   0.014                five of them, 0.34-1.14 long
#     torso           0.52 x 0.34 x 0.44   the one bold member, and HIDDEN
#     head            0.26 x 0.30 box      a SIXTH of the hero's head
# Five faults fall out of that, and only the first is the usual one:
#  1. EVERY MEMBER EXCEPT THE TORSO IS A WIRE. Fourth conversion running.
#  2. THE RECEIPT IS UNREADABLE, AND THAT IS THE WORST OF THE FIVE. This is the
#     one creature in the file whose entire job is Mr. E's binding principle -
#     what it has taken is HANGING ON IT, where the viewer who paid for that
#     helm can see it. On the sheet the helm is a grey ball, the boot a dark
#     chip, the satchel a chip, the blade a toothpick and the ring a wire hoop.
#     NOTHING HANGING ON IT READS AS GEAR. The modelling was there; the SIZE
#     and the VALUE BREAK were not.
#  3. THE SPREADER BAR IS A SCAFFOLD. 1.86 m of horizontal bone at shoulder
#     height with five vertical cords dropping off it is a drying rack, and it
#     is what makes the whole creature read as architecture rather than as a
#     man. It was pass 2's fix for the kit fusing with the torso and it worked
#     - it bought visibility by turning him into a frame. Both can be had: the
#     kit hangs off a RING HE WEARS, short and stout, not off a gantry.
#  4. ZERO DEPTH - THE MECHANIC IS GONE AT AZIMUTH 90. Frame, beads, spreader
#     and all five hangers sit in ONE Y PLANE (FY = -0.20, cords at FY-0.16),
#     so from the side the creature is a fencepost with twigs and there is no
#     tally and no loot on it at all. This is the Stoker's fault 6, the
#     Gaoler's 7 and the Porter's 7 - value not separating the members - in its
#     hardest form yet, because here there is nothing TO separate. It is the
#     carried fault and this is the conversion that takes it: the loot is
#     distributed AROUND him in plan, not strung across him in a plane, so
#     every view has three or four pieces and no view has the lot.
#  5. TWENTY-ONE BEADS IS NOT A COUNT. Four rows of 7/5/3/6 at 0.052 radius is
#     a texture, not a tally. The Sexton's lesson in its own form - nine cells
#     cut to six because a rising that cannot be counted from the doorway is a
#     mechanic that cannot be read. SIX beads, one rod, 0.11 radius.
#
# AND ONE RULING APPLIED RATHER THAN A FAULT: THE HUNG RING IS GONE. Mr. E,
# 04:56 - "i understand the rings but gloves can be seen so we dont have to
# make new rings" - a ring is an inventory item a viewer reads in the hub, not
# a silhouette on stream. A 0.065 wire hoop at pane distance was the proof of
# his own point. Its slot goes to a SHIELD, which reads at any distance.
# Authored at the same 2.15 m so the pair sheet compares ONE thing.
# ===========================================================================
CANON.update({
    "tallyman_chibi": ("The Tallyman (chibi)", 2.15, (0.88, 0.76, 0.42), (1.00, 0.88, 0.50),
                       "treasury",
                       "IT TAKES AND LEAVES - rebuilt in the game's own register",
                       0.20, "Something is counting what you carry."),
})


def tallyman_chibi():
    """The Tallyman in the game's register. Same read - A NARROW UPRIGHT WITH A
    COUNTING FRAME FOR A CHEST AND THE THINGS IT HAS TAKEN HANGING OFF IT -
    with every wire member taken to a chibi weight, the strongbox promoted from
    an add-on to the torso itself, twenty-one beads cut to six, and the stolen
    kit taken off the gantry and hung on a ring he WEARS, spread around him in
    plan so it is on him from every side.

    THE VALUE PLAN, and it is the whole of the design: a DARK figure, a MID
    brass strongbox, and the two pale things on the creature are THE COUNT and
    THE LOOT - the two things a viewer has to read. The Porter put the pale
    value on the mechanic; this one does the same and the mechanic is the
    receipt."""
    P = Parts("tallyman_chibi")
    HIP = 0.45                                   # 21% of 2.15, off the Knight

    # --- LEGS. Stubs, planted, slightly apart. A clerk stands and waits.
    for s in (-1, 1):
        limb(P, [(s * 0.19, 0.03, HIP), (s * 0.22, 0.00, 0.22),
                 (s * 0.23, -0.03, 0.09)], 0.145, 0.132, 'dark')
        P.add(L.box(0.29, 0.40, 0.12), 'dark', loc=(s * 0.23, -0.10, 0.06))

    # --- THE TORSO IS THE STRONGBOX. In the original this was a 0.52 box
    # STUCK ON a 0.150 spine and then hidden behind the counting frame, so the
    # one bold member on the creature never appeared in the silhouette. It is
    # now the body: a banded brass chest 0.80 across standing on the legs, with
    # nothing in front of it but the tally rod.
    BZ = 0.92
    P.add(L.box(0.80, 0.46, 0.74), 'body', loc=(0.0, -0.04, BZ))
    # PORTER'S CLOSED LESSON, KEPT: the bands WRAP. The Gaoler's fault 5 and
    # the Stoker's fault 2 were decoration on the front face only; nothing in
    # this file carries that any more.
    for bz in (BZ - 0.26, BZ + 0.26):
        P.add(L.box(0.86, 0.52, 0.10), 'dark', loc=(0.0, -0.04, bz))
    for s in (-1, 1):
        P.add(L.box(0.09, 0.52, 0.80), 'dark', loc=(s * 0.37, -0.04, BZ))
    # the coin slot. ONE aperture, and it is a SLOT - the Porter's rule, and it
    # is on the BELLY where it cannot be read as a face at all.
    P.add(L.box(0.30, 0.05, 0.05), 'dark', loc=(0.0, -0.28, BZ - 0.16))
    P.add(L.box(0.24, 0.04, 0.035), 'glow', loc=(0.0, -0.295, BZ - 0.16))
    for s in (-1, 1):                                            # shoulders
        P.add(L.sphere(0.215, 0.205, 0.185, 12, 8), 'body', loc=(s * 0.40, -0.04, 1.30))

    # --- THE TALLY. One rod across the front of the box, SIX beads at 0.11,
    # four shoved left and two right with a gap between - a count in progress,
    # readable from the doorway. Twenty-one beads on four wires was a texture.
    # PASS 4, FAULT 3 - THE TALLY AND THE LOOT WERE ON THE SAME LINE. Spacing
    # the beads was necessary and not sufficient: at z 1.22 the rod sat level
    # with the shoulders (1.30), the tally ring (1.22) and the hung helm, so
    # four pale beads, two pale shoulder balls and a pale helm made ONE pale
    # band straight across the creature at chest height and nothing in it could
    # be told from anything else. Two mechanics cannot share a horizontal. The
    # rod drops onto the clear brass face of the strongbox between its two
    # wrapping bands, where the only thing behind a bead is the box, and the
    # coin slot drops with it so the two do not simply swap the collision.
    RY, RZ = -0.34, BZ + 0.10
    # PASS 5, FAULT 4 - HALF THE BEADS WERE THREADED ON NOTHING AND A PIPE
    # STUCK OUT OF HIS RIGHT SIDE. lordlib.cone is built along +Z WITH ITS BASE
    # AT THE ORIGIN, not centred, so aiming it along +X from x=0 ran the whole
    # 1.02 m of rod to the RIGHT: the two left beads hung in mid-air with no rod
    # through them and 0.6 m of iron projected clear of the body like a spigot.
    # On the crop it reads as a pipe, which is how it was caught. The Porter's
    # pass-3 note says the same thing from the other side - seat the cone ON
    # the end point - and it is the same primitive making the same fool of me.
    # Base seated at the left end of the row.
    P.add(aim(L.cone(0.040, 0.040, 1.02, 10), (-0.51, RY, RZ), (1.0, 0.0, 0.0)), 'dark')
    for s in (-1, 1):
        P.add(L.box(0.08, 0.13, 0.22), 'dark', loc=(s * 0.46, RY, RZ))
    # PASS 3, FAULT 2 - SIX BEADS CAME OUT AS A BREAD ROLL. I cut twenty-one
    # beads to six to make the count readable and then spaced them 0.14 apart
    # at a radius of 0.11, so adjacent beads OVERLAP and the row fuses into one
    # pale sausage across the chest. The count - the thing this creature is
    # named for - was still unreadable, by my own hand, in the pass written to
    # fix exactly that. THE LESSON IS ARITHMETIC AND IT IS GENERAL: a row of n
    # spheres reads as n only while the gap exceeds twice the radius. It is
    # measurable before rendering and I did not measure it.
    # So FOUR beads at 0.25 apart against a 0.115 radius - 0.02 of clear air
    # between each - shoved to the left of the rod with a bare run of iron to
    # the right. Four is countable from the doorway and the empty rod says what
    # the mechanic is: this is what it has had off you so far, and there is
    # room for more.
    for x in (-0.46, -0.21, 0.04, 0.29):
        P.add(L.sphere(0.115, 0.100, 0.115, 11, 8), 'bone', loc=(x, RY, RZ))

    # --- THE HEAD. A hooded counting lamp, dark end to end, with ONE lit slit
    # under a shade that overhangs it. The Porter's two rules, applied without
    # being walked through them: TWO apertures read as eyes however they are
    # shaped, ONE reads as a slit; a PALE plate on a dark head is a face, a
    # DARK plate is not. Nothing round stands in front of the slit's centre -
    # that is the pass-4 lesson the Porter paid for and it is measured here:
    # the dome bellies to y -0.30 and the plate's face sits at -0.38.
    # PASS 2, FAULT 1 - THE SHADE WAS A FUNNEL AND THE HEAD WAS AN EGG. Pass 1
    # gave the lamp an inverted cone for a hood, 0.30 at the top over a 0.33
    # dome, and from the front it is a MARTINI GLASS, from the side a WINE
    # GLASS, and from the back the pair reads as a PERFUME BOTTLE - the Sexton's
    # pass-5 saucer and the Snuffer's pass-4 lampshade, walked into again in the
    # same slot. The rule those two paid for is absolute: NOTHING ON A HEAD MAY
    # BE WIDER THAN THE HEAD, and nothing round belongs on top of something
    # round. So the lamp goes and the head becomes what this creature's head
    # should always have been - A SECOND STRONGBOX, squared, banded, locked, the
    # same object as its chest in miniature. A tallyman keeps his head the way
    # he keeps his takings. The slit stays single and stays the only aperture,
    # and the only thing in front of it is a peak that overhangs it from above.
    HZ = 1.68
    P.add(L.box(0.52, 0.42, 0.46), 'dark', loc=(0.0, -0.08, HZ))
    P.add(L.box(0.56, 0.46, 0.07), 'dark', loc=(0.0, -0.08, HZ + 0.26))   # the cap band
    P.add(L.box(0.40, 0.045, 0.050), 'glow', loc=(0.0, -0.295, HZ - 0.02))
    P.add(L.box(0.50, 0.14, 0.075), 'dark', loc=(0.0, -0.33, HZ + 0.10))  # the peak
    P.add(L.box(0.10, 0.44, 0.09), 'dark', loc=(0.0, -0.08, HZ + 0.31))   # the hasp
    # the neck: a short collar, so the head's bottom edge is not lost in the
    # shoulders - the Drillmaster's pass-3 fault 3 and it is not re-opened here.
    P.add(aim(L.cone(0.145, 0.165, 0.18, 10), (0.0, -0.06, 1.36), (0.0, 0.0, 1.0)), 'body')

    # --- THE TALLY RING HE WEARS, and this is fault 3 and fault 4 closed in
    # one member. Not a gantry over his head: a stout hoop round his chest at
    # 0.60, the loot hung off it on short thick chains at FIVE AZIMUTHS, so
    # the front sees four pieces, the side sees three in profile and the back
    # sees three - and no view of this creature is ever without its receipt.
    RR, RGZ = 0.60, 1.22
    ring = [Vector((RR * math.sin(TAU * i / 16.0), -0.04 - RR * math.cos(TAU * i / 16.0), RGZ))
            for i in range(17)]
    P.raw(L.tube(ring, 0.050, 7), 'dark')

    def at(az, r, z):
        a = math.radians(az)
        return (r * math.sin(a), -0.04 - r * math.cos(a), z)

    def hang(az, drop, kind):
        """A short stout chain from the ring, and the thing on the end of it.
        THE SIZES ARE THE POINT. The original's helm was a 0.125 sphere - a
        grey pea on a 2.15 m creature. Every piece here is 0.34-0.62 across
        and every piece carries a value break, because a single-value lump at
        pane distance is cargo and not kit."""
        top = at(az, RR, RGZ)
        bot = at(az, RR + 0.04, RGZ - drop)
        limb(P, [top, bot], 0.048, 0.042, 'dark')
        x, y, z = at(az, RR + 0.06, RGZ - drop - 0.16)
        if kind == 'helm':
            # PASS 6, FAULT 5 - THE HELM WAS A MUSHROOM, and it is the piece
            # that matters most: this creature exists so a viewer can see
            # THEIR OWN HELM hanging on it. Pass 1 gave it a 0.46 pale dome
            # with a 0.44 flat dark band directly under it - a disc exactly as
            # wide as the thing above it, which is the shade's fault and the
            # Sexton's saucer for the third time in one session. NOTHING ON A
            # DOME MAY BE AS WIDE AS THE DOME. A helm does not read by being
            # dome-shaped; it reads by having A SIGHT SLOT, A BROW OVER IT AND
            # A NECK UNDER IT, and the original had none of the three. One
            # dark slot, not two - the Porter's rule holds for a helm hanging
            # off a hook exactly as it holds for a head.
            P.add(L.sphere(0.235, 0.225, 0.215, 14, 9), 'bone', loc=(x, y, z))
            P.add(L.box(0.30, 0.06, 0.065), 'dark', loc=(x, y - 0.185, z + 0.01))
            P.add(L.box(0.34, 0.16, 0.055), 'dark', loc=(x, y - 0.145, z + 0.10))
            P.add(aim(L.cone(0.185, 0.235, 0.12, 12), (x, y, z - 0.26),
                      (0.0, 0.0, 1.0)), 'bone')
            P.add(L.box(0.26, 0.26, 0.05), 'dark', loc=(x, y, z - 0.25))
            P.add(L.box(0.07, 0.34, 0.20), 'dark', loc=(x, y, z + 0.17))   # the comb
        elif kind == 'shield':
            P.add(aim(L.cone(0.260, 0.215, 0.085, 14), (x, y, z), (0.30, -1.0, 0.18)), 'bone')
            P.add(aim(L.cone(0.275, 0.275, 0.045, 14), (x, y, z), (0.30, -1.0, 0.18)), 'dark')
            P.add(aim(L.sphere(0.085, 0.085, 0.075, 10, 7), (x, y, z), (0.30, -1.0, 0.18)), 'dark')
        elif kind == 'sword':
            P.raw(aim(L.box(0.115, 0.045, 0.62), (x, y, z - 0.08), (0.14, 0.0, 1.0)), 'bone')
            P.add(L.box(0.34, 0.09, 0.075), 'dark', loc=(x + 0.03, y, z + 0.23))
            P.add(L.box(0.085, 0.085, 0.20), 'dark', loc=(x + 0.035, y, z + 0.34))
            P.add(L.sphere(0.075, 0.075, 0.070, 10, 7), 'bone', loc=(x + 0.04, y, z + 0.45))
        elif kind == 'boot':
            P.add(L.box(0.22, 0.24, 0.34), 'bone', loc=(x, y, z))
            P.add(L.box(0.25, 0.44, 0.11), 'dark', loc=(x, y - 0.08, z - 0.20))   # the sole
            P.add(L.box(0.26, 0.28, 0.08), 'dark', loc=(x, y, z + 0.16))          # the cuff
        elif kind == 'purse':
            P.add(L.sphere(0.200, 0.185, 0.215, 12, 8), 'body', loc=(x, y, z))
            P.add(L.box(0.26, 0.26, 0.07), 'dark', loc=(x, y, z + 0.18))          # drawstring
            P.add(L.sphere(0.065, 0.065, 0.030, 10, 7), 'glow', loc=(x + 0.14, y - 0.10, z - 0.10))

    hang(-58.0, 0.26, 'helm')
    hang(58.0, 0.34, 'shield')
    hang(-120.0, 0.44, 'sword')
    hang(120.0, 0.40, 'boot')
    hang(180.0, 0.30, 'purse')

    # --- ARMS. Short and thick, and they do the two halves of the idea: the
    # near one holds the SLATE it writes the tally on, the far one is the open
    # pinch that lifts. The original's quill was 0.020 thick - a hair - and its
    # three 0.020 fingers were invisible at any distance; a chibi takes the
    # count with a bold slate and TWO thick digits.
    limb(P, [(-0.42, -0.08, 1.24), (-0.52, -0.26, 1.10), (-0.50, -0.42, 1.02)], 0.145, 0.120)
    P.add(L.sphere(0.155, 0.150, 0.140, 10, 7), 'body', loc=(-0.50, -0.44, 1.00))
    P.add(L.box(0.30, 0.055, 0.40), 'dark', loc=(-0.50, -0.50, 1.14))        # the slate
    for i, sz in enumerate((0.30, 0.22, 0.26)):                              # chalk marks
        P.add(L.box(sz, 0.02, 0.035), 'bone', loc=(-0.50, -0.532, 1.26 - i * 0.11))
    limb(P, [(0.42, -0.08, 1.24), (0.58, -0.30, 1.14), (0.62, -0.50, 1.06)], 0.145, 0.120)
    for d in (-1, 1):                                                        # the pinch
        limb(P, [(0.62, -0.52, 1.06 + d * 0.055), (0.70, -0.70, 1.02 + d * 0.085)],
             0.072, 0.052, 'body')
    return P


BUILDERS.update({"tallyman_chibi": tallyman_chibi})


# ===========================================================================
# REGISTER CONVERSION 8 OF 14 - THE COOK.
#
# Same programme as the seven before it: the creature is rebuilt in the game's
# register; see the block above drillmaster_chibi for the measured Knight
# proportions and the one above snuffer_chibi for the rule that register is
# MASS AND COUNT, not man-proportions.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/cook/hero_front|side|back.png):
# A SANDWICH-BOARD MAN STANDING NEXT TO A WASHTUB. From the side it is worse -
# it is a washtub, and the man is gone. Measured off the builder, against a
# hero arm 0.29 thick and a hero head 1.09 across:
#     legs            0.105 / 0.085        boots 0.26 x 0.40 x 0.10
#     arms            0.072 / 0.054        ladle haft 0.034 / 0.028
#     yoke            0.055 - 0.075        pot chains 0.026 / 0.022
#     bowl cord       0.012                A HAIR
#     apron           0.74 x 0.90 FLAT     the biggest member, one value
#     head            0.30 x 0.33          a THIRD of the hero's head
#     cauldron        0.96 across, bottom ON THE GROUND LINE
# Seven faults fall out of that, and only the first is the usual one:
#  1. EVERY MEMBER EXCEPT THE TORSO AND THE POT IS A WIRE. Fifth conversion
#     running; it is the register and it is not news.
#  2. THE POT IS A WOODEN TUB WITH A LID ON, AND THE POT IS THE WHOLE FIGHT.
#     Two causes, both mine. (a) An 18-segment sphere under flat light shows
#     its vertical facets, and vertical facets on a round brown vessel are
#     STAVES - the thing reads as a barrel however black the material says it
#     is. (b) The mouth is WIDER than the belly (rim cone 0.47 -> 0.49 under a
#     0.50 pale flange), which is the proportion of a tub; a cauldron bellies
#     OUT and narrows IN at the rim. And the pale flange with a lit disc under
#     it reads as a LID, so the one thing a party has to spill is sealed.
#  3. THE APRON IS A SANDWICH BOARD. 0.74 x 0.90 of flat pale panel at a
#     single value, hung on the front plane only, is the largest thing on the
#     creature and it says nothing. It also hides the torso, so the man has no
#     body between his boots and his yoke.
#  4. THE POT IS PARKED, NOT SLUNG. Its bottom sits on the ground line and its
#     chains are 0.026 wires that vanish at pane distance, so it reads as a
#     prop standing beside him. The entire idea - a man bent under a weight -
#     needs CLEAR AIR UNDER THE POT and chains you can see, and had neither.
#  5. THE MAN IS GONE AT AZIMUTH 90. The pot sits at x +0.86 with the man at
#     x 0 and everything in one y plane, so from the side the camera looks
#     straight down the line of the pair and the pot eclipses the creature.
#     This is the Stoker's fault 6, the Gaoler's 7, the Porter's 7 and the
#     Tallyman's 1 in a NEW form: not value failing to separate members, but
#     one member physically swallowing the whole figure.
#  6. THE LADLE IS A LOLLIPOP. A 0.034 haft with a 0.17 ball 1.2 m up in clear
#     air above the head is a bubble wand, and from the side it is the only
#     thing visible above the tub.
#  7. THREE MESS BOWLS ON NOTHING. 0.115 cones spaced 0.075 on a 0.012 cord -
#     the Tallyman's arithmetic, failed again before it was ever written down:
#     a row of n reads as n only while the GAP exceeds TWICE the radius. These
#     fuse into one pale sliver, and the cord holding them is invisible.
# AND THE FACE IS INSIDE THE SKULL - eyes() is called at y 0.0 on a head
# centred at y -0.18, so the pupils sit behind 0.16 m of scalp. That is the
# Drillmaster's pass-2 fault verbatim, shipped in a second creature.
#
# THE CARRIED FAULT, AND THIS CONVERSION TAKES IT: the lit mechanic has been a
# FRONT-ONLY FEATURE on every creature in this file - the Tallyman's coin slot,
# the Porter's, the Sexton's niches. A party reads a set piece from whatever
# door it came in by. So the Cook's fire is put UNDER the pot as a glow that is
# radially symmetric: there is no azimuth from which the pot is not visibly ON.
#
# THE VALUE PLAN, and this one had to be measured rather than assumed. At the
# Cook's wear of 0.60 the generator's 'body' lands at luminance 0.372 and its
# 'bone' at 0.441 - a 19% separation, the weakest in the file, which is why the
# original's apron, torso and head all read as one pale mass. SO NOTHING HERE
# LEANS ON BODY-VERSUS-BONE. The figure is 'body', every break on it is 'dark'
# (luminance 0.06), the pot is 'dark', and the two things the viewer must read
# - THE FIRE and THE BROTH - are the only 'glow' on the creature.
# Authored at the same 2.05 m so the pair sheet compares ONE thing.
# ===========================================================================
CANON.update({
    "cook_chibi": ("The Cook (chibi)", 2.05, (0.72, 0.52, 0.38), (1.00, 0.62, 0.26),
                   "mess",
                   "IT KEEPS THE PACK ALIVE - rebuilt in the game's own register",
                   0.60, "The pot is on."),
})


def cook_chibi():
    """The Cook in the game's register. Same read - A SQUAT MAN UNDER A YOKE
    WITH A BLACK POT SLUNG ON ONE END AND HIS KIT ON THE OTHER - with every
    wire member taken to a chibi weight, the cauldron rebuilt so it is a
    cauldron and not a tub, the pot lifted clear of the floor so it is CARRIED,
    the fire moved UNDER it so the mechanic reads from every azimuth, and the
    mess kit given enough mass to be a counterweight instead of three chips.

    The balance is the silhouette: a heavy dark ball low on the right, a keg
    and a stack of bowls low on the left, a bent man in the middle and a ladle
    shouldered up and out. It is a weighing scale with a man under it, and it
    is not the Drillmaster's thin high disc nor the Porter's drawbar."""
    P = Parts("cook_chibi")
    HIP = 0.43                                   # 21% of 2.05, off the Knight

    # --- LEGS. Stubs, planted wide, the loaded side braced out further.
    for s in (-1, 1):
        limb(P, [(s * 0.19, 0.03, HIP), (s * 0.23, 0.00, 0.21),
                 (s * 0.25, -0.03, 0.09)], 0.140, 0.128, 'dark')
        P.add(L.box(0.28, 0.39, 0.12), 'dark', loc=(s * 0.25, -0.10, 0.06))

    # --- TORSO. A wide low barrel of a man, 0.80 across. The original hung a
    # flat panel in front of a 0.265 spine; there was no body behind the apron.
    P.add(L.sphere(0.40, 0.32, 0.38, 18, 12), 'body', loc=(0.0, -0.02, 0.90))
    # PASS 4, AND IT IS A BUILD FAULT, NOT A JUDGEMENT: from the BACK the legs
    # were two stumps under a floating ball. The torso's bottom sits at 0.52
    # and the hips at 0.43, and nothing bridged the 0.09 - the apron hid it
    # from the front and there is no apron behind. A pelvis, and the legs meet
    # the man from every side.
    P.add(L.sphere(0.345, 0.285, 0.165, 16, 10), 'body', loc=(0.0, -0.02, 0.50))
    # shoulders, and the POT SIDE IS LOWER - the lean is in the shoulders, not
    # in a cant on the spine, because a chibi has no waist to bend at.
    P.add(L.sphere(0.205, 0.195, 0.180, 12, 8), 'body', loc=(-0.40, -0.04, 1.22))
    P.add(L.sphere(0.205, 0.195, 0.180, 12, 8), 'body', loc=(0.40, -0.04, 1.14))

    # --- THE APRON. Fault 3. Narrower than the torso so the body reads AROUND
    # it, and broken into three bands by the one slot that actually separates
    # at this wear: a dark waist tie, a dark hem, and two scorch patches,
    # because a mess cook's apron is burnt and Mr. E's second rule says the
    # wear has to be justified by what the thing is.
    # PASS 5 - THE APRON WAS A SIGNBOARD WITH TWO WINDOWS IN IT. A rectangle
    # with a framed edge and two small dark rectangles on it is a notice, and
    # the scorch patches - put there to carry Mr. E's wear rule - were the two
    # windows. Cloth is not a rectangle: it is NARROW AT THE TIE AND WIDE AT
    # THE HEM and its bottom edge is not straight. So the panel becomes a
    # tapered membrane with a kicked hem, the scorch goes (wear is carried by
    # the soot in the material and by the burnt hem band instead), and the tie
    # gets two ENDS hanging, which is the detail that says somebody knotted it.
    P.raw(L.membrane([(-0.21, -0.355, 1.05), (0.21, -0.355, 1.05),
                      (0.31, -0.360, 0.76), (0.33, -0.368, 0.58),
                      (0.12, -0.372, 0.52), (-0.16, -0.370, 0.54),
                      (-0.32, -0.366, 0.60), (-0.30, -0.358, 0.80)], 0.045), 'bone')
    P.add(L.box(0.70, 0.08, 0.09), 'dark', loc=(0.0, -0.345, 1.06))
    for s_ in (-1, 1):
        P.add(L.box(0.055, 0.05, 0.22), 'dark', loc=(s_ * 0.30, -0.345, 0.95))
    P.raw(L.membrane([(-0.30, -0.372, 0.60), (-0.16, -0.376, 0.54),
                      (0.12, -0.378, 0.52), (0.33, -0.374, 0.58),
                      (0.31, -0.374, 0.50), (0.10, -0.380, 0.44),
                      (-0.16, -0.378, 0.46), (-0.29, -0.374, 0.52)], 0.030), 'dark')

    # --- THE HEAD. A cloth cap pulled down over a plain face. The cap is
    # NARROWER than the skull (0.49 against 0.54) - the rule the Sexton's
    # saucer, the Snuffer's lampshade and the Tallyman's martini glass each
    # paid for separately, and nothing round sits on top of something round
    # here either: the cap is a shallow dome set INTO the crown, not perched
    # on it, with a dark band at the join doing the value break.
    HZ = 1.56
    P.add(aim(L.cone(0.135, 0.165, 0.16, 10), (0.0, -0.04, 1.24),
              (0.0, 0.0, 1.0)), 'body')                       # the neck
    P.add(L.box(0.46, 0.44, 0.05), 'dark', loc=(0.0, -0.05, 1.33))   # the collar
    P.add(L.sphere(0.27, 0.25, 0.255, 16, 10), 'body', loc=(0.0, -0.05, HZ))
    P.add(L.sphere(0.245, 0.23, 0.13, 16, 8), 'bone', loc=(0.0, -0.05, 1.70))
    P.add(L.box(0.50, 0.47, 0.055), 'dark', loc=(0.0, -0.05, 1.63))
    # THE EYES ARE ON THE FACE AND NOT IN THE SKULL, and they have pupils.
    # The original called eyes() at y 0.0 on a head centred at y -0.18, so the
    # face was blank from every angle - the Drillmaster's pass-2 fault, found
    # once, written down once, and shipped again here. The skull's front face
    # is at y -0.30; the sclera sits at -0.27 and the pupil at -0.305.
    eyes(P, (0.0, -0.05, 1.57), 0.105, 0.058, -0.22, 'bone')
    eyes(P, (0.0, -0.05, 1.575), 0.105, 0.029, -0.255, 'dark')

    # --- THE YOKE. Fault 5's other half: it is NOT the Porter's drawbar,
    # because it dips hard to the loaded side and carries a weight on each end,
    # which is the shape of a balance and not of a bar. 1.70 long, and stout.
    # PASS 2, AND IT IS THE FAULT THE WHOLE CONVERSION TURNS ON. Pass 1 pulled
    # the pot in from x 0.86 to 0.78 and nudged it 0.12 in y, and AT AZIMUTH 90
    # THE MAN WAS STILL GONE - the pot filled the cell and the creature behind
    # it was a head and a lollipop. Of course it was: the side camera looks
    # down the X axis, so an X offset is DEPTH, not separation, and no amount
    # of it will ever move the pot off the man. THE LESSON IS GENERAL AND IT IS
    # THE TALLYMAN'S, STATED PROPERLY: a load carried on ONE axis is invisible
    # from that axis. The carry goes DIAGONAL IN PLAN - 40 degrees - so the pot
    # is back-right, the kit is front-left and the man stands between them in
    # EVERY view. Front sees a balance; side sees three masses in a row; back
    # sees the balance from behind.
    yoke = [Vector((-0.68, -0.58, 1.34)), Vector((-0.22, -0.20, 1.50)),
            Vector((0.26, 0.20, 1.44)), Vector((0.70, 0.56, 1.24))]
    P.raw(L.tube(yoke, [0.058, 0.082, 0.078, 0.062], 9), 'dark')

    # --- THE CAULDRON. Fault 2 and fault 4. PX is pulled IN from the
    # original's 0.86 and pushed OFF the y axis, so at azimuth 90 the pot no
    # longer stands square in front of the man; and the whole assembly hangs
    # with 0.17 m of clear air under it, which is the only thing that says
    # CARRIED rather than PARKED.
    PX, PY = 0.58, 0.49
    PRX, PRY = -0.643, 0.766                      # the carry axis' perpendicular
    limb(P, [(0.70, 0.56, 1.24), (PX + 0.02, PY + 0.02, 1.34)], 0.054, 0.048, 'dark')
    # the belly: 24 segments, because the facet rhythm at 18 is what made the
    # original read as a staved barrel, and the belly is WIDER than the mouth.
    P.add(L.sphere(0.50, 0.47, 0.34, 24, 14), 'dark', loc=(PX, PY, 0.66))
    P.raw(aim(L.cone(0.470, 0.370, 0.18, 24), (PX, PY, 0.78), (0.0, 0.0, 1.0)), 'dark')
    # PASS 4 - THE BAIL, and it is the one cue that settles tub versus pot. An
    # urn, a crock and a washtub all have a belly and a lip; NONE of them has a
    # HANDLE ARCHING OVER THE MOUTH. Three passes were spent on proportion and
    # facet count trying to argue the thing out of being a barrel, and one arc
    # does it. The chains hang off the bail's crown, which is also how a real
    # one is carried, so the chain run stops being decoration.
    bail = [Vector((PX + PRX * 0.40, PY + PRY * 0.40, 1.08)),
            Vector((PX + PRX * 0.26, PY + PRY * 0.26, 1.24)),
            Vector((PX, PY, 1.34)),
            Vector((PX - PRX * 0.26, PY - PRY * 0.26, 1.24)),
            Vector((PX - PRX * 0.40, PY - PRY * 0.40, 0.96))]
    P.raw(L.tube(bail, 0.060, 9), 'dark')
    # PASS 6 - THE SCOURED RIM WAS EATING THE FIRE. The pale 'bone' lip was put
    # there for Mr. E's wear rule - a cook keeps his pot - and it sat directly
    # against the glow ring. At this aura the 'glow' slot normalises to very
    # near white, so bright-next-to-pale is NO CONTRAST AT ALL and the burning
    # mouth read as a polished one. A lit thing only reads lit against DARK.
    # The bone lip goes; the pot is black iron end to end and the only pale
    # thing on it is the fire. The wear rule is carried instead by the bail and
    # the chain, which are clean iron on a sooted body.
    # PASS 4 - THE FIRE COMES OFF THE FLOOR AND GOES ON THE RIM. Pass 3 fixed
    # the sock by making the fire tapers, and the tapers came back POPCORN - a
    # pale cluster in a cup sitting on the ground beside his boot, with no air
    # under it, so the pot still did not read as hanging and the brightest
    # thing on the creature was a bowl of rice. The brazier was costing eleven
    # parts and buying a fault. IT IS GONE. What says "the pot is on" is the
    # pot's own MOUTH: a glow ring sunk just inside the scoured lip, so from
    # any azimuth, at any elevation this rig will shoot, the near half of it is
    # a bright crescent against black iron. One part, radially symmetric, and
    # it cannot be read as anything but something hot in a pot. And with the
    # firebox gone the pot's bottom sits at 0.44 with CLEAR AIR under it, which
    # is what pass 1's fault 4 asked for and never got.
    # PASS 5 - THE LIT RIM WAS INSIDE THE POT, SO THERE WAS NO LIT RIM. Pass 4
    # sank the glow ring 0.04 BELOW the scoured lip, which is exactly where a
    # pot's contents sit and exactly where a camera at 6 degrees of elevation
    # cannot see them: the lip's own outer edge occludes it from every azimuth
    # at once. The pot came back beautiful and OFF. The ring has to be PROUD -
    # level with the lip and 0.005 wider than it - so what the viewer reads is
    # a black pot with a burning mouth, which is the whole mechanic in one
    # silhouette. The lesson is the disc lesson a third time and it is finally
    # stated as a rule: AT THIS ELEVATION A HORIZONTAL FEATURE ONLY READS IF IT
    # IS THE TOPMOST THING AT ITS OWN RADIUS.
    P.raw(aim(L.cone(0.400, 0.400, 0.060, 24), (PX, PY, 0.935), (0.0, 0.0, 1.0)), 'glow')
    P.add(L.sphere(0.370, 0.370, 0.050, 22, 8), 'glow', loc=(PX, PY, 0.98))
    # THE FIRE, AND IT IS THE CARRIED FAULT TAKEN: a glow directly under the
    # pot, radially symmetric, and the LOWEST thing on the assembly - so there
    # is no azimuth, and no elevation this rig will ever shoot at, from which
    # the pot is not visibly ON. Front-only mechanics stop here.
    # PASS 3 - THE FIRE CAME OUT AS A SOCK WITH TEETH IN IT. Pass 2 built the
    # fire as a flat glow disc with three dark grate bars across it, and at the
    # rig's 6 degrees of elevation a squashed disc is seen EDGE ON: a pale band,
    # with the bars reading as teeth in it. From the side the pot had a mouth.
    # The rule, and it is the shade's and the saucer's in a third costume: A
    # FLAT DISC IS NOT A SHAPE AT THIS ELEVATION - it is a line. Fire is not a
    # disc anyway; fire is TAPERS. So the brazier shrinks to a cup that cannot
    # be mistaken for a foot, and the fire is six glow cones licking UP the
    # belly, which read as flame from every azimuth and read as flame small.


    # --- THE FREE END: A KEG AND A STACK OF BOWLS. Fault 7. Three 0.115 cones
    # on a hair could never balance a 1.00 m cauldron, and they fused anyway.
    # The keg is ALLOWED to read as a barrel because it IS one - and having one
    # honest barrel on the creature is what makes the pot stop being the other.
    KX, KY = -0.64, -0.44
    limb(P, [(-0.66, -0.56, 1.32), (KX, KY, 1.14)], 0.046, 0.042, 'dark')
    P.add(L.sphere(0.26, 0.25, 0.30, 16, 10), 'dark', loc=(KX, KY, 0.86))
    for kz in (0.98, 0.74):
        P.raw(aim(L.cone(0.252, 0.252, 0.045, 16), (KX, KY, kz),
                  (0.0, 0.0, 1.0)), 'bone')
    # the bowls: 0.165 radius, 0.20 apart. THE ARITHMETIC IS DONE BEFORE THE
    # RENDER THIS TIME - a stack reads as a stack rather than as a row, so the
    # test is not the Tallyman's gap-over-twice-the-radius but whether each
    # bowl's own RIM is separated from the one below it. 0.20 of pitch against
    # a 0.055 bowl height and a dark rim ring on each gives 0.09 of clear air
    # under every rim.
    BX, BY = -0.42, -0.74
    limb(P, [(-0.44, -0.40, 1.42), (BX, BY, 0.72)], 0.030, 0.028, 'dark')
    for bz in (1.12, 0.92, 0.72):
        P.raw(aim(L.cone(0.165, 0.125, 0.055, 14), (BX, BY, bz), (0.0, 0.0, 1.0)), 'bone')
        P.raw(aim(L.cone(0.178, 0.178, 0.024, 14), (BX, BY, bz + 0.052),
                  (0.0, 0.0, 1.0)), 'dark')

    # --- ARMS. Short and thick. The near one SHOULDERS THE LADLE and the mitt
    # visibly wraps the haft; the far one is up on the pot chain, steadying it,
    # which is the only pose that explains why the shoulder on that side is
    # 0.08 lower than the other.
    limb(P, [(-0.40, -0.06, 1.16), (-0.54, -0.24, 1.04),
             (-0.58, -0.34, 0.96)], 0.140, 0.118, 'body')
    P.add(L.sphere(0.155, 0.150, 0.140, 10, 7), 'body', loc=(-0.58, -0.36, 0.95))
    # the haft is DARK and the bowl is BONE - the value break the original's
    # all-pale lollipop never had. 0.060 of haft, not 0.034.
    limb(P, [(-0.58, -0.38, 0.95), (-0.76, -0.12, 1.52),
             (-0.86, 0.04, 1.90)], 0.060, 0.050, 'dark')
    P.add(L.box(0.17, 0.17, 0.10), 'body', loc=(-0.60, -0.33, 1.02))    # the grip
    # PASS 5 - THE LADLE WAS A LOLLIPOP THROUGH FOUR PASSES. A flat pale oval
    # on a stick is a lollipop whatever the stick is made of, and thickening
    # the haft in pass 1 only made it a bigger lollipop. A ladle reads by being
    # a CUP: deep, with a dark hollow you can see into and a ferrule where the
    # bowl is socketed onto the haft. The bowl is 0.16 deep now instead of
    # 0.13 flat, the hollow is dark, and the join is a band - three parts and
    # none of them is a disc.
    P.add(L.sphere(0.205, 0.200, 0.165, 14, 9), 'bone', loc=(-0.90, 0.08, 1.95))
    P.add(L.sphere(0.150, 0.145, 0.115, 12, 8), 'dark', loc=(-0.905, 0.075, 2.02))
    P.add(L.box(0.115, 0.115, 0.10), 'dark', loc=(-0.845, 0.035, 1.845))
    limb(P, [(0.40, -0.04, 1.12), (0.54, 0.10, 1.16),
             (0.62, 0.24, 1.20)], 0.140, 0.118, 'body')
    P.add(L.sphere(0.155, 0.150, 0.140, 10, 7), 'body', loc=(0.64, 0.27, 1.22))
    return P


BUILDERS.update({"cook_chibi": cook_chibi})


# ===========================================================================
# REGISTER CONVERSION 9 OF 14 - THE SLUICEKEEPER, 16 Nov
#
# Same read, same props, same idea, rebuilt in the game's own register; see
# the block above drillmaster_chibi for the measured Knight proportions and
# the one above snuffer_chibi for the rule that register is MASS AND COUNT,
# not man-proportions.
#
# THE THREE LESSONS THIS ONE INHERITS AND SPENDS, rather than re-learning:
#   THE COOK'S:   an X offset is DEPTH, not separation. The original stood the
#                 whole sluice frame at x +1.02 with y +0.16 - an X-only
#                 offset - so at azimuth 90 the camera looks straight down the
#                 line of man and machine and the frame stands in front of
#                 him. The machine goes DIAGONAL IN PLAN, about 30 degrees.
#   THE SNUFFER'S AND THE COOK'S: a flat disc is a LINE at this elevation, and
#                 a horizontal feature only reads if it is the TOPMOST thing
#                 at its own radius. The water is the creature's whole
#                 mechanic and it lies on the floor, which is the worst place
#                 a feature can be - so it is given a PROUD RIM that is the
#                 topmost thing at the basin's radius, and the rim is a closed
#                 ring, so there is no azimuth from which the water is not
#                 visibly standing.
#   THE COOK'S AGAIN: a lit thing only reads against DARK, so the basin gets a
#                 dark kerb outside the glow and nothing pale touches the water.
#
# AND ONE OF ITS OWN, WHICH IS THE DISC LESSON APPLIED TO A RING: the handwheel
# is the silhouette and a ring faces ONE WAY. Stood "up facing the room" as the
# original had it, it is a fat ellipse from the front and a VERTICAL LINE from
# the side. So the wheel's plane is turned 40 degrees in plan: it is oblique to
# both cameras and open in both - 77% of its width from the front, 64% from the
# side - and there is no view in which it collapses.
#
# THE VALUE PLAN, MEASURED. At this wear of 0.95 - the highest in the file, and
# justified, because this is the one thing down there that is never dry - the
# generator's `body` lands at luminance 0.299 and its `bone` at 0.342: a 14%
# separation, WEAKER THAN THE COOK'S 19% and the weakest in the file. So
# nothing here leans on body-versus-bone. The man is `body`, every break on him
# is `dark` (luminance 0.060), the machine is `dark`, the gate board is the one
# `bone` object on the creature, and the water is the only `glow`.
#
# THE CARRIED FAULT TAKEN THIS RUN: "the legs read as two dark blocks" - the
# Sexton's fault 9, the Porter's 12, the Tallyman's 10 and the Cook's 6, carried
# four times and never taken. The cause was that shin and boot were both `dark`,
# which is 0.060 against 0.060. Here the shins are `body` and only the boot is
# `dark`, so the leg has a value break in it at the ankle where the real one is.
# ===========================================================================
CANON.update({
    "sluicekeeper_chibi": ("The Sluicekeeper (chibi)", 2.50, (0.46, 0.54, 0.56),
                           (0.40, 0.80, 1.00), "flooded",
                           "IT RAISES THE WATER - rebuilt in the game's own register",
                           0.95, "The water is coming up."),
})


def sluicekeeper_chibi():
    """The Sluicekeeper in the game's register. Same read - A MAN WITH BOTH
    MITTS ON A BIG OPEN WHEEL, A SCREW CLIMBING BEHIND IT, STANDING IN LIT
    WATER - with the wire man taken to a chibi weight, the wheel made bolder
    and turned oblique so it never goes edge-on, the clutter dropped (the
    chest plank and the drag-board bought nothing at cell size) and the water
    rebuilt as a basin with a proud rim instead of a flat puddle.

    The pose IS the mechanic: two hands on one wheel, at two points on it, is
    the only pose that reads as WINDING SOMETHING OPEN. Everything else on the
    creature is the machine he is winding and the water it has already let in."""
    P = Parts("sluicekeeper_chibi")

    # The machine sits DIAGONAL from the man in plan - the Cook's lesson. The
    # man is back-left, the frame front-right, and the basin is centred between
    # them, so front sees man-then-wheel, side sees wheel-then-man, and neither
    # view has one standing inside the other.
    #
    # PASS 5 - THE ARMS CAME BACK AS A PLANK, AND THE CAUSE WAS THE LAYOUT,
    # NOT THE ARMS. Passes 1-4 stood the man back-LEFT of the machine while the
    # wheel's plane runs along U, so the rim nearest him was still 0.85 m away
    # ACROSS the wheel: both arms had to span the whole thing to reach it and
    # they merged into one diagonal bar with a ball on the end - a boom, not a
    # pair of arms. Lengthening or bending them could not have fixed it.
    # THE RULE, AND IT IS NEW: A FIGURE OPERATING A MACHINE MUST STAND IN THE
    # MACHINE'S OWN PLANE. You turn a handwheel from its EDGE, with the rim
    # coming past your hands - not from off to one side of it. So the man moves
    # along +U, which puts him in the wheel's plane, 1.30 m out: the near rim
    # is then 0.70 m from his shoulder, the arms are a chibi's length again,
    # and the plan offset from the frame is (1.00, 0.84) - still a diagonal on
    # BOTH axes, which is the Cook's lesson and is what keeps the man and the
    # machine out of each other in front, side and back alike.
    # He stays on the camera's FAR side of the machine (+y), because the frame
    # is nearer the lens at azimuth 0 and a man standing in front of the wheel
    # would hide the one shape this creature is recognised by.
    # PASS 6 - HE WAS STANDING ON THE WHEEL. At 1.30 m out his own body and his
    # near arm crossed the rim, so the one shape this creature is recognised by
    # was read through a man. 1.62 m puts his shoulder outside the rim and the
    # arms EXTENDED to it, which is also the truer pose: you turn a wheel at
    # arm's length, not with it against your chest.
    FX, FY = 0.62, -0.34
    # PASS 7 pulls that back to 1.45: 1.62 cleared the rim but put the near
    # grip 0.79 m from the shoulder, and an arm that long on a 2.10 m chibi is
    # a boom again. 1.45 is the compromise and it is NAMED rather than hidden -
    # the arms still run about 0.78 m, which is long for this register.
    MX, MY = FX + 0.766 * 1.45, FY + 0.643 * 1.45
    HIP = 0.50                                   # 21% of the man, off the Knight

    # --- LEGS. Stubs, planted wide, braced against standing water. THE SHINS
    # ARE `body` AND ONLY THE BOOT IS `dark`: the carried fault, taken.
    for s in (-1, 1):
        limb(P, [(MX + s * 0.21, MY + 0.03, HIP), (MX + s * 0.24, MY + 0.00, 0.23),
                 (MX + s * 0.26, MY - 0.03, 0.11)], 0.150, 0.136, 'body')
        P.add(L.box(0.30, 0.40, 0.13), 'dark', loc=(MX + s * 0.26, MY - 0.09, 0.065))

    # --- TORSO. A barrel, and a pelvis bridging hips to torso, because the
    # Cook proved that without one the back view is two stumps under a floating
    # ball and no apron exists to hide it.
    P.add(L.sphere(0.345, 0.275, 0.175, 16, 10), 'body', loc=(MX, MY, 0.58))
    P.add(L.sphere(0.420, 0.335, 0.400, 18, 12), 'body', loc=(MX, MY - 0.02, 1.02))
    # the shoulders: the WHEEL SIDE IS RAISED, because his hand is up on the
    # crank. The Cook's loaded shoulder dropped; this one lifts. Same device,
    # opposite sign, and it is the only thing that explains the arms.
    P.add(L.sphere(0.200, 0.190, 0.180, 12, 8), 'body', loc=(MX - 0.36, MY - 0.06, 1.34))
    P.add(L.sphere(0.200, 0.190, 0.180, 12, 8), 'body', loc=(MX + 0.36, MY - 0.04, 1.24))
    # a belt, dark, one band - the only break on the body
    P.add(L.box(0.80, 0.66, 0.085), 'dark', loc=(MX, MY - 0.02, 0.74))

    # --- THE HEAD AND THE HOOD. The one thing a gate-keeper owns is a hood,
    # and it is sodden. NOTHING ROUND SITS ON TOP OF SOMETHING ROUND - the
    # Sexton's saucer, the Snuffer's lampshade, the Tallyman's martini glass
    # and the Cook's cap each paid for that separately - so the hood is a
    # shallow dome set INTO the crown, NARROWER than the skull (0.275 against
    # 0.300), with a dark band at the join doing the value break, and a
    # drawn-back peak so it reads as cloth and not as a helmet.
    HZ = 1.80
    P.add(aim(L.cone(0.145, 0.175, 0.17, 10), (MX, MY - 0.03, 1.42),
              (0.0, 0.0, 1.0)), 'body')                            # the neck
    P.add(L.box(0.50, 0.48, 0.06), 'dark', loc=(MX, MY - 0.04, 1.52))   # the cowl
    P.add(L.sphere(0.300, 0.280, 0.285, 16, 10), 'body', loc=(MX, MY - 0.04, HZ))
    P.add(L.sphere(0.275, 0.260, 0.145, 16, 8), 'dark', loc=(MX, MY - 0.04, 1.95))
    P.add(L.box(0.56, 0.53, 0.055), 'dark', loc=(MX, MY - 0.04, 1.87))
    P.raw(aim(L.cone(0.150, 0.0, 0.34, 10), (MX, MY + 0.10, 1.98),
              (0.0, 0.62, 0.78)), 'dark')                          # the peak, drawn back
    # THE EYES ARE ON THE FACE AND NOT IN THE SKULL. The skull's front face is
    # at y MY-0.34; sclera at -0.30, pupil at -0.335. Called at the head's own
    # y centre, which is the fault the Drillmaster found and the Cook shipped.
    eyes(P, (MX, MY - 0.04, 1.80), 0.108, 0.058, -0.26, 'bone')
    eyes(P, (MX, MY - 0.04, 1.805), 0.108, 0.029, -0.295, 'dark')

    # --- THE SLUICE FRAME. Two stout posts and a head beam, straddling the
    # screw ALONG THE MACHINE'S OWN AXIS, so the frame turns with the wheel and
    # the whole assembly is one oblique object rather than a wheel pasted on a
    # square frame. U is that axis in plan; N is the wheel's normal.
    #
    # PASS 2 - THE MACHINE CAME BACK AS A TANGLE AND IT WAS MY OWN VALUE PLAN
    # THAT DID IT. Pass 1 read the measurement "bone is only 14% off body" and
    # concluded "put the whole creature in body and dark", which threw away the
    # pair that IS strong here: bone against dark is 0.342 against 0.060. With
    # frame, screw, wheel and beam all `dark`, the front view had a dark wheel
    # crossed by dark posts under a dark beam and the handwheel - the entire
    # silhouette of this creature - disappeared into it. The frame and the beam
    # go back to `bone`, the wheel and the screw stay `dark`, and the wheel is
    # then the one dark object standing on a pale frame. THE LESSON, GENERAL: a
    # weak pair somewhere in the palette is not a reason to use ONE value for
    # everything; it is a reason to find which pair IS strong and build on it.
    UX, UY = 0.766, 0.643                        # the machine's axis, 40 deg
    for s in (-1, 1):
        limb(P, [(FX + s * UX * 0.50, FY + s * UY * 0.50, 0.02),
                 (FX + s * UX * 0.52, FY + s * UY * 0.52, 1.20),
                 (FX + s * UX * 0.54, FY + s * UY * 0.54, 2.22)], 0.095, 0.078, 'bone')
    P.raw(L.tube([Vector((FX - UX * 0.60, FY - UY * 0.60, 2.26)),
                  Vector((FX + UX * 0.60, FY + UY * 0.60, 2.26))], [0.105] * 2, 8), 'bone')

    # --- THE SCREW. Six deep collars, not eight thin ones: at cell size a fine
    # thread is a smooth pole, and the Tallyman's and the Cook's stacks both
    # fused because the pitch was not checked against the radius. 0.26 of pitch
    # against a 0.05 collar gives 0.21 of clear stem between every pair.
    limb(P, [(FX, FY, 0.30), (FX, FY, 2.22)], 0.072, 0.062, 'dark')
    for k in range(6):
        P.raw(aim(L.cone(0.135, 0.135, 0.050, 12), (FX, FY, 0.52 + k * 0.26),
                  (0.0, 0.0, 1.0)), 'dark')

    # --- THE HANDWHEEL. 1.20 m across, open, and OBLIQUE: its plane is spanned
    # by U (horizontal, 40 degrees off the X axis) and Z, so it is an open
    # ellipse from the front AND from the side and a line from neither. Four
    # thick spokes rather than six thin ones - the rim gap at the hub is what
    # fuses a wheel into a disc, and 4 spokes of 0.055 on a 0.60 ring leave
    # 0.94 m of air between them at the rim.
    WZ, WR = 1.62, 0.60
    pts = [Vector((FX + WR * math.cos(TAU * i / 30.0) * UX,
                   FY + WR * math.cos(TAU * i / 30.0) * UY,
                   WZ + WR * math.sin(TAU * i / 30.0))) for i in range(31)]
    P.raw(L.tube(pts, [0.095] * len(pts), 8), 'dark')
    for k in range(4):
        a = TAU * k / 4.0 + 0.30
        P.raw(aim(L.cone(0.055, 0.048, WR, 8), (FX, FY, WZ),
                  (math.cos(a) * UX, math.cos(a) * UY, math.sin(a))), 'dark')
    P.add(L.sphere(0.165, 0.165, 0.165, 12, 8), 'dark', loc=(FX, FY, WZ))
    # THE CRANK PEG, standing off the rim toward the room on the wheel's own
    # normal - the one part that says this wheel TURNS rather than hangs.
    NX, NY = 0.643, -0.766                       # the wheel's normal in plan

    def rim(a):
        return Vector((FX + WR * math.cos(a) * UX, FY + WR * math.cos(a) * UY,
                       WZ + WR * math.sin(a)))

    def nearest(sh, lo, hi):
        """The rim point NEAREST this shoulder, scanned rather than guessed.
        Hand placement by arithmetic is how pass 1 ended up with a 1.01 m arm
        on a 2.10 m man; the ring knows where its own nearest point is."""
        best, bd = None, 1e9
        for i in range(61):
            a = lo + (hi - lo) * i / 60.0
            q = rim(a)
            d = (q - Vector(sh)).length
            if d < bd:
                best, bd = a, d
        return best

    # THE CRANK PEG, standing off the rim toward the man on the wheel's own
    # normal - the one part that says this wheel TURNS rather than hangs, and
    # now the thing his upper mitt is actually closed on.
    SH_HI = (MX - 0.36, MY - 0.08, 1.34)
    SH_LO = (MX + 0.36, MY - 0.06, 1.24)
    # PASS 7 - AND THIS WAS A STRAIGHT BUG, NOT A JUDGEMENT. The scan ran over
    # a in [pi-1.30, pi+0.10], which is the rim's FAR side: cos(a)*WR is the
    # coordinate ALONG U, so a near pi is the quadrant pointing AWAY from the
    # man. Both hands were therefore sent across the wheel to the rim behind
    # it, which is why four passes of arm work kept producing one long bar -
    # the nearest-point scan was faithfully finding the nearest point of the
    # wrong half. The upper hand now takes the near-TOP quadrant and the lower
    # hand the near-BOTTOM one, so the arms diverge vertically and read as two.
    CA = nearest(SH_HI, 0.15, 0.95)
    CP = rim(CA)
    limb(P, [(CP.x, CP.y, CP.z), (CP.x + NX * 0.26, CP.y + NY * 0.26, CP.z + 0.02)],
         0.055, 0.048, 'body')

    # --- THE GATE BOARD, drawn up inside the frame with dark air under its
    # lip. It is the ONE pale object on the creature, and it is deliberately
    # NOT touching the water: the Cook's sixth pass proved that pale against
    # glow is no contrast at all, and the lit basin is the mechanic.
    GX, GY = FX - NX * 0.26, FY - NY * 0.26
    P.raw(L.membrane([(GX - UX * 0.44, GY - UY * 0.44, 0.62),
                      (GX + UX * 0.44, GY + UY * 0.44, 0.62),
                      (GX + UX * 0.44, GY + UY * 0.44, 1.46),
                      (GX - UX * 0.44, GY - UY * 0.44, 1.46)], 0.085), 'bone')
    P.raw(L.tube([Vector((GX - UX * 0.46, GY - UY * 0.46, 0.60)),
                  Vector((GX + UX * 0.46, GY + UY * 0.46, 0.60))], [0.070] * 2, 8), 'dark')

    # --- THE WATER. The mechanic, and the only `glow` on the creature. It is
    # RADIALLY SYMMETRIC, so there is no azimuth from which the room is not
    # visibly flooding - the front-only fault the Cook's lit mouth closed for
    # the pot and this closes for the floor.
    #
    # PASS 3 - THE WATER CAME BACK AS A DISPLAY PLINTH. Pass 1 built it as a
    # true circle, flat on the floor at 0.09, with a dark kerb ring outside the
    # bright rim - and a pale disc with a dark bevel around it carrying a
    # figure is a CAKE STAND. Every cue added for legibility was a cue for
    # furniture: the circle said "turned", the kerb said "moulded edge", and
    # sitting ON the floor rather than IN the room said "base". Three things
    # change and they are all the same thing - WATER HAS NO EDGE OF ITS OWN, IT
    # TAKES THE EDGE OF WHAT IT IS IN:
    #   the kerb GOES (it was the plate rim),
    #   the outline becomes IRREGULAR - eight unequal lobes, no two the same,
    #   and the surface RISES to 0.30, which is mid-shin on him and well up the
    #   posts, so it CUTS his legs and the frame instead of carrying them.
    # A plinth is under a thing; water is around it, and the giveaway is that
    # it hides the bottom of whatever it touches. The proud rim stays - that is
    # the elevation rule, and the only reason a horizontal surface reads here
    # at all - but it follows the irregular edge, so it is a lapping line and
    # not a hoop.
    # PASS 6 - AND THE BASIN IS NOW DERIVED, NOT TYPED, AND IT IS AN ELLIPSE.
    # Pass 5 left a 1.06 m circle at a hand-picked centre and the OUTER BOOT
    # CORNER STUCK OUT OF THE WATER at 1.11 m - a small dark block sitting on
    # the surface in the side and back views, exactly the sort of thing a
    # viewer sees before anybody else does. It was found by measuring the dark
    # slot's vertices below the waterline against the lobe radius at their own
    # angle, not by staring at the render.
    # Deriving a CIRCLE from that fixed it and broke the frame instead: man and
    # machine are 1.62 m apart along U, so a circle covering both is 1.8 m of
    # radius and the pair went to 5.77 m against a 5.60 m cell. A puddle is not
    # round anyway - it is the shape of the floor it is lying on, and this
    # floor is a channel. So the basin is an ELLIPSE ON THE MACHINE'S OWN AXIS,
    # with both semi-axes COMPUTED from the things that must not be left dry -
    # his boot corners and the posts' feet - against the SMALLEST lobe. The
    # flood cannot leave a foot dry by construction, and it costs the frame
    # nothing because it is long the way the machine is long.
    lobe = (1.00, 0.88, 1.06, 0.93, 1.12, 0.90, 1.02, 0.86)
    VX, VY = -UY, UX                              # across the machine's axis
    # PASS 8 - THE WATERLINE, AND I HAD THE ELEVATION ARITHMETIC BACKWARDS.
    # Pass 4 raised the surface to 0.30 and the front view came back right, so
    # I called it closed. The BACK view still showed his boots through the
    # water, and the reason is not coverage - it is REACH, and it is the wrong
    # way round from how I first wrote it. An ortho ray at 6 degrees of
    # elevation, aimed at the top of a 0.13 m boot, crosses the z = BZ plane
    # (BZ - 0.13) / tan(6 deg) BEFORE it gets there: at BZ 0.30 that is 1.62 m
    # of water that has to lie between the camera and the boot. From the front
    # the man stands at the far end of the pool and there is nearly that much;
    # from the back he is at the near edge and there is 0.22 m, so the camera
    # looks under the surface and lands on the floor.
    # Widening the pool to 1.6 m of margin was tried and it put the pair at
    # 5.86 m against a 5.60 m cell, so the frame refused it - correctly.
    # THE SURFACE COMES DOWN INSTEAD. At BZ 0.15 the required reach is 0.19 m,
    # which the 0.22 m margin already has, and the flood covers his boots from
    # every azimuth. It is a SHALLOWER flood than pass 4's and that is the
    # honest version of this creature anyway: the line is "the water is coming
    # up", not "the water is up". THE RULE, STATED SO IT IS NOT RE-DERIVED: at
    # this elevation a raised surface hides what stands in it only if it
    # reaches (height - object top) / 0.105 metres toward the camera.
    BZ = 0.15
    BCX, BCY = FX + UX * 0.95, FY + UY * 0.95
    wet = [(FX + s_ * UX * 0.50, FY + s_ * UY * 0.50) for s_ in (-1, 1)]
    for s_ in (-1, 1):
        for ex, ey in ((0.19, 0.11), (0.19, -0.29), (-0.19, 0.11), (-0.19, -0.29)):
            wet.append((MX + s_ * 0.26 + ex, MY - 0.09 + ey))
    BA = BB = 0.0
    for wx, wy in wet:
        du = (wx - BCX) * UX + (wy - BCY) * UY
        dv = (wx - BCX) * VX + (wy - BCY) * VY
        BA, BB = max(BA, abs(du)), max(BB, abs(dv))
    BA = (BA + 0.22) / min(lobe)
    BB = (BB + 0.22) / min(lobe)
    edge = []
    for i in range(41):
        t = TAU * i / 40.0
        f = i / 40.0 * len(lobe)
        k = int(f) % len(lobe)
        k2 = (k + 1) % len(lobe)
        w = lobe[k] + (lobe[k2] - lobe[k]) * (f - int(f))
        du, dv = BA * w * math.cos(t), BB * w * math.sin(t)
        edge.append(Vector((BCX + du * UX + dv * VX, BCY + du * UY + dv * VY, BZ)))
    P.raw(surf([[Vector((BCX + (q.x - BCX) * u, BCY + (q.y - BCY) * u, BZ))
                 for q in edge] for u in (0.0, 0.55, 1.0)], 0.030), 'glow')
    P.raw(L.tube(edge, [0.050] * len(edge), 7), 'glow')
    # PASS 4 - AND IT IS THE ELEVATION RULE BITING FROM THE OTHER SIDE. Pass 3
    # raised the surface to 0.30 and HIS BOOTS WERE STILL VISIBLE UNDER IT: at
    # 6 degrees of elevation a ray that clears the near edge of a raised sheet
    # has dropped only 0.10 by the time it reaches the middle, so the camera
    # looks UNDERNEATH the water and sees the floor it is supposed to have
    # covered. A sheet is not a flood. So the water gets its own SIDE - a skirt
    # from the lapping edge down to the floor - and becomes a VOLUME. It now
    # hides the bottom of everything standing in it, which is the single thing
    # that tells a viewer the floor has gone under, and that is the whole point
    # of this creature.
    for i in range(len(edge) - 1):
        a_, b_ = edge[i], edge[i + 1]
        P.raw(surf([[a_, b_], [Vector((a_.x, a_.y, 0.0)), Vector((b_.x, b_.y, 0.0))]],
                   0.012), 'glow')

    # --- ARMS. Short and thick, and BOTH MITTS ARE ON THE WHEEL at two
    # different points on it: the upper one closed on the crank peg, the lower
    # one on the rim. One hand on a wheel is a man leaning on a wheel; two
    # hands at two points is a man TURNING it, and that is the fight in one
    # silhouette. Each hand goes to the rim point NEAREST ITS OWN SHOULDER
    # (scanned, see `nearest`), so neither arm reaches across the wheel.
    limb(P, [SH_HI, ((SH_HI[0] + CP.x) / 2.0 + NX * 0.16,
                     (SH_HI[1] + CP.y) / 2.0 + NY * 0.16, SH_HI[2] + 0.06),
             (CP.x + NX * 0.22, CP.y + NY * 0.22, CP.z + 0.02)], 0.150, 0.120, 'body')
    P.add(L.sphere(0.165, 0.160, 0.150, 10, 7), 'body',
          loc=(CP.x + NX * 0.22, CP.y + NY * 0.22, CP.z + 0.02))
    LA = nearest(SH_LO, -0.95, -0.15)
    LR = rim(LA)
    limb(P, [SH_LO, ((SH_LO[0] + LR.x) / 2.0 + NX * 0.10,
                     (SH_LO[1] + LR.y) / 2.0 + NY * 0.10, (SH_LO[2] + LR.z) / 2.0 - 0.04),
             (LR.x + NX * 0.10, LR.y + NY * 0.10, LR.z)], 0.145, 0.118, 'body')
    P.add(L.sphere(0.160, 0.155, 0.148, 10, 7), 'body',
          loc=(LR.x + NX * 0.12, LR.y + NY * 0.12, LR.z))
    return P


BUILDERS.update({"sluicekeeper_chibi": sluicekeeper_chibi})


# ===========================================================================
# REGISTER CONVERSION 10 OF 14 - THE SOWER, 17 Nov
#
# Same read, same props, same idea, rebuilt in the game's own register; see
# the block above drillmaster_chibi for the measured Knight proportions and
# the one above snuffer_chibi for the rule that register is MASS AND COUNT,
# not man-proportions.
#
# THE VALUE PLAN, MEASURED FIRST - AND THIS IS THE WEAKEST PAIR IN THE FILE.
# At tint (0.72, 0.68, 0.44) and wear 0.40 the generator's `body` lands at
# luminance 0.498 and its `bone` at 0.549: a 10% separation, against the
# Sluicekeeper's 14% and the Cook's 19%. So bone-against-body carries NOTHING
# here. The pairs that are strong are dark (0.092) against either of them, and
# glow against all three. Hence:
#   the man is `body`, every break on him is `dark`,
#   the hat is the ONE `bone` object, and it only ever reads against the black
#       above his shoulders, never against his own body - with a `dark` band at
#       the join doing the work where the two do touch,
#   the shoots are `dark` stems, and
#   the SEED IS THE ONLY `glow` ON THE CREATURE - in the hopper's mouth, in the
#       air out of his hand, and again as the thorn standing up out of the
#       floor. One lit material, told three times, is the whole mechanic:
#       WHAT HE THROWS IS WHAT COMES UP.
#
# THAT CLOSES THE ORIGINAL'S FIRST TWO FAULTS BY CONSTRUCTION. The old shoots
# were `bone` - "the same pale wood colour as his hat, and they read as loose
# sticks rather than something that grew" - and the old cast was four 0.042
# spheres that vanish at cell size. Dark stems with lit thorns cannot be
# confused with the hat, and the seeds are now 0.095 - 4% of his height.
#
# AND THE THIRD FAULT IS WHY THE HAT IS NOT A CONE. "His wide hat is the
# second wide cone in the file after the Snuffer's." A cone is a cone from
# every azimuth, so posture cannot separate two of them. This hat is a FLAT
# BRIM with a LOW CROWN: at the file's 6 degrees of elevation a flat disc is a
# LINE (the Snuffer's and the Cook's lesson), and that is exactly what is
# wanted here - the Snuffer reads as a triangle on a stalk and the Sower as a
# horizontal bar on a head, which is the one silhouette a straw hat makes.
# The brim is also the topmost thing at its own radius, so the line is never
# crossed by anything, and NOTHING ROUND SITS ON SOMETHING ROUND: the crown is
# a shallow dome NARROWER than the skull (0.255 against 0.300) set into it,
# with the dark band at the join - the Sexton's saucer, the Snuffer's
# lampshade, the Tallyman's martini glass and the Cook's cap, paid for once.
#
# THE CARRIED LEG FAULT, AND THIS IS THE CREATURE IT SHOWS ON. The Sexton's
# fault 9, the Porter's 12, the Tallyman's 10 and the Cook's 6 - "the legs read
# as two dark blocks" - was fixed in the Sluicekeeper's file and INVISIBLE
# there, because pass 8's waterline covered his legs to the ankle. Nothing
# covers these legs. Shins are `body` and only the boot is `dark`, so the leg
# breaks in value at the ankle, where a real one does, in all three views.
# ===========================================================================
CANON.update({
    "sower_chibi": ("The Sower (chibi)", 2.40, (0.72, 0.68, 0.44),
                    (0.55, 1.00, 0.42), "grassland",
                    "IT PLANTS THE GROUND AGAINST YOU - rebuilt in the game's own register",
                    0.40, "Something is broadcasting seed."),
})


def sower_chibi():
    """The Sower in the game's register. Same read - A MAN WITH A HOPPER ON
    HIS CHEST, ONE ARM THROWN WIDE WITH SEED IN THE AIR, AND THORN ALREADY
    STANDING BEHIND HIM - with the wire man taken to a chibi weight, the hat
    rebuilt as a flat brim instead of a second cone, the stems darkened off the
    hat's value and the seed made the only lit thing on the creature.

    THE CAST AND THE THORN ARE ON OPPOSITE SIDES OF HIM, and that is the
    conversion's one new idea: seed leaving his hand on the left, thorn already
    up on the right, so the creature carries its own BEFORE AND AFTER in one
    silhouette. A viewer who sees it once knows what the fight is going to do
    to the floor."""
    P = Parts("sower_chibi")
    MX, MY = 0.0, 0.0
    HIP = 0.50                                   # 21% of the man, off the Knight
    # THE LINE HE WALKS, DIAGONAL IN PLAN (37 degrees). U runs along it - the
    # cast goes out along -U and the thorn stands up along +U - and V is across
    # it, which is where the thorns point. See pass 2 below for why this is not
    # a decoration: on the X axis the whole mechanic disappears from the side.
    UX, UY = 0.800, 0.600
    VX, VY = -0.600, 0.800

    # --- LEGS. Stubs, planted wide, with the lead foot carried forward on the
    # line he walks. THE SHINS ARE `body` AND ONLY THE BOOT IS `dark`.
    for s in (-1, 1):
        fy = -0.14 if s < 0 else 0.12            # the stride, along his line
        limb(P, [(MX + s * 0.21, MY + 0.03, HIP), (MX + s * 0.24, MY + fy * 0.5, 0.23),
                 (MX + s * 0.26, MY + fy, 0.11)], 0.150, 0.136, 'body')
        P.add(L.box(0.30, 0.40, 0.13), 'dark', loc=(MX + s * 0.26, MY + fy - 0.06, 0.065))

    # --- TORSO. A barrel over a pelvis that bridges the hips, because the Cook
    # proved that without one the back view is two stumps under a floating ball.
    P.add(L.sphere(0.345, 0.275, 0.175, 16, 10), 'body', loc=(MX, MY, 0.58))
    P.add(L.sphere(0.420, 0.335, 0.400, 18, 12), 'body', loc=(MX, MY - 0.02, 1.02))
    P.add(L.box(0.80, 0.66, 0.085), 'dark', loc=(MX, MY - 0.02, 0.74))        # belt
    # the CASTING shoulder is the raised one - the Sluicekeeper's device, same
    # sign: the arm that is doing the work explains the whole posture.
    P.add(L.sphere(0.200, 0.190, 0.180, 12, 8), 'body', loc=(MX - 0.36, MY - 0.06, 1.34))
    P.add(L.sphere(0.200, 0.190, 0.180, 12, 8), 'body', loc=(MX + 0.36, MY - 0.04, 1.24))

    # --- HEAD. Neck, skull, eyes on the FACE and not in the skull.
    P.add(aim(L.cone(0.145, 0.175, 0.17, 10), (MX, MY - 0.03, 1.42),
              (0.0, 0.0, 1.0)), 'body')
    P.add(L.sphere(0.300, 0.280, 0.285, 16, 10), 'body', loc=(MX, MY - 0.04, 1.80))
    eyes(P, (MX, MY - 0.04, 1.78), 0.108, 0.058, -0.26, 'bone')
    eyes(P, (MX, MY - 0.04, 1.785), 0.108, 0.029, -0.295, 'dark')

    # --- THE HAT: A FLAT BRIM AND A LOW CROWN, not a cone. 1.12 m across, the
    # topmost thing at its own radius, dipped 7 degrees toward the room so the
    # line is a hat and not a shelf. Straw at wear 0.40 - kept, not new.
    P.raw(aim(L.cone(0.560, 0.200, 0.045, 20), (MX, MY - 0.02, 2.00),
              (0.0, 0.12, 1.0)), 'bone')
    P.add(L.box(0.52, 0.50, 0.055), 'dark', loc=(MX, MY - 0.03, 2.025))   # the join
    P.add(L.sphere(0.255, 0.245, 0.145, 16, 9), 'bone', loc=(MX, MY - 0.03, 2.035))

    # --- THE HOPPER. A BOX, deliberately - a box cannot be mistaken for the
    # Drillmaster's gong or the Tallyman's discs - slung across the chest on a
    # broad strap and tipped toward his casting hand. Its mouth is lit, which
    # is the Cook's lit-mouth lesson: a container only reads as FULL if you can
    # see into it, and what is in this one is the mechanic.
    HX, HY, HZ = MX - 0.16, MY - 0.34, 1.00
    P.add(L.box(0.58, 0.30, 0.38), 'dark', loc=(HX, HY, HZ), rot=(0.0, 0.20, 0.0))
    # PASS 4 - A DARK PROP ON A BLACK FIELD HAS NO SILHOUETTE, AND THE HOPPER
    # IS THE PROP THAT NAMES THIS CREATURE. `dark` is luminance 0.092 and the
    # cell background is 0.045: against his body the box read as the boldest
    # thing on him, and the moment it cleared his body - which is every view
    # but the front - it was gone. One prop visible from one azimuth out of
    # three is the front-only fault the Cook's lit mouth closed for the pot.
    # THE RULE: a dark mass needs a PALE EDGE where it stands against the room,
    # not a different fill - so the hopper keeps its dark body (which is what
    # reads against him) and gains a bone RIM round its mouth, which is what
    # reads against the dark. It is also what a seed hopper has: a lip you run
    # your hand along. The lit seed sits inside the rim.
    P.add(L.box(0.62, 0.34, 0.06), 'bone', loc=(HX - 0.02, HY, HZ + 0.185),
          rot=(0.0, 0.20, 0.0))
    P.raw(aim(L.cone(0.235, 0.215, 0.040, 16), (HX - 0.03, HY - 0.01, HZ + 0.225),
              (0.20, 0.0, 1.0)), 'glow')
    P.raw(L.membrane([(MX + 0.30, MY - 0.16, 1.38), (MX + 0.38, MY - 0.08, 1.34),
                      (HX - 0.18, HY - 0.10, HZ + 0.18), (HX - 0.26, HY - 0.02, HZ + 0.22)],
                     0.045), 'dark')

    # --- THE CAST. The far arm thrown wide and low, palm turned out, and the
    # seed leaving it in a falling arc. Four seeds at 0.095 - the original's
    # 0.042 was a crumb at cell size.
    #
    # PASS 2 - THE SIDE VIEW HAD NO MECHANIC IN IT, AND IT IS THE COOK'S FAULT
    # AGAIN: AN X-ONLY DIRECTION IS DEPTH, NOT SEPARATION. Pass 1 threw the arm
    # and the seed along -X and set the thorns out along +-X, so at azimuth 90
    # the camera looked straight down the line of the cast: the arm
    # foreshortened into a lump on his chest, the four seeds stacked into two
    # dots at his hip, and every thorn on every shoot went edge-on and
    # vanished, leaving three bare poles with a ball on top - candles, not
    # thorn. The front and back views were right and the side view was a
    # different creature. So EVERY DIRECTION ON THIS CREATURE THAT WAS X-ONLY
    # IS NOW DIAGONAL IN PLAN: the cast runs along -U at 37 degrees, the seed
    # falls along it, and the thorns stand out along +-V, across that line.
    # Nothing is now parallel to either camera.
    SH = (MX - 0.36, MY - 0.08, 1.34)
    HAND = (MX - UX * 0.95, MY - UY * 0.95, 1.06)
    limb(P, [SH, (MX - UX * 0.62, MY - UY * 0.62 - 0.06, 1.16), HAND], 0.150, 0.120, 'body')
    P.add(L.sphere(0.165, 0.160, 0.150, 10, 7), 'body', loc=HAND)
    for k in range(4):
        t = k / 3.0
        d = 0.26 + t * 0.62
        P.add(L.sphere(0.095, 0.095, 0.095, 9, 6), 'glow',
              loc=(HAND[0] - UX * d, HAND[1] - UY * d, HAND[2] - 0.04 - t * 0.52))

    # --- THE NEAR ARM steadying the hopper's rim. Short, and it comes FORWARD
    # and in rather than down, because a chibi arm is short enough that the
    # elbow IS the silhouette.
    limb(P, [(MX + 0.36, MY - 0.04, 1.24), (MX + 0.30, MY - 0.30, 1.10),
             (MX + 0.10, MY - 0.44, 1.02)], 0.145, 0.118, 'body')
    P.add(L.sphere(0.160, 0.155, 0.148, 10, 7), 'body', loc=(MX + 0.06, MY - 0.46, 1.01))

    # --- THE THORN ALREADY UP. Three shoots, crooked, diverging, at three
    # heights - and SPREAD IN PLAN, 2 to 66 degrees off his line, so there is
    # no azimuth from which all three stand behind him in one bar. Dark stems
    # (the hat's value is now nowhere near them) with the seed standing in them
    # as lit thorn: three bold thorns a stem, not five fine ones, because
    # register is COUNT as much as mass.
    # PASS 5 - THE THORN WAS GROWING THROUGH HIM. Pass 3's bolder thorns made
    # the near shoot's reach 0.30 m instead of 0.21, and the nearest stem stood
    # 0.95 m out on a man whose shoulder and casting arm already reach 0.56 -
    # so from the front two thorns crossed his arm and the before-and-after
    # read as one tangle. The shoots step 0.25 further out along the line he
    # walks: that is the same distance for all three, so the fan he planted
    # keeps its shape and only the gap between him and it changes.
    for sd, se, hh, bend in ((1.22, 0.08, 1.46, 0.22),
                             (1.05, -0.62, 1.02, -0.16),
                             (1.30, 0.78, 1.22, 0.10)):
        sx, sy = UX * sd + VX * se, UY * sd + VY * se
        base = (MX + sx, MY + sy, 0.0)
        tip = (MX + sx + VX * bend, MY + sy + VY * bend + 0.10, hh)
        limb(P, arc(base, tip, 0.0, 7, side=bend * 0.8), 0.085, 0.030, 'dark')
        # PASS 3 - THE THORNS WERE STILL FLECKS, AND ALTERNATING THEM ALONG ONE
        # AXIS IS THE SAME MISTAKE ONE STEP SMALLER. Pass 2 moved them off X
        # onto V, which made them visible from the side instead of from the
        # front - it did not make them visible from BOTH, because two
        # directions is still a plane, and at azimuth 90 a thorn lying in it is
        # 0.21 m seen at a slant. From two of the three views the shoots read
        # as bare poles with a lit ball on top: lollipops, not thorn.
        # THE RULE, AND IT GENERALISES PAST THIS CREATURE: a feature repeated
        # along a member must be placed ON A HELIX, not alternated on an axis -
        # then every azimuth sees some of it broadside by construction and
        # none sees all of it edge-on. Four thorns a stem at 0.30 (was three at
        # 0.21), each 80 degrees around from the last.
        for k in range(4):
            t = 0.30 + 0.20 * k
            px = MX + sx + VX * bend * t
            py = MY + sy + VY * bend * t + 0.10 * t
            a = 1.40 * k + 0.6
            ox, oy = math.cos(a), math.sin(a)
            P.raw(aim(L.cone(0.075, 0.0, 0.30, 7), (px, py, hh * t),
                      (ox, oy, 0.34)), 'glow')
        P.add(L.sphere(0.075, 0.075, 0.075, 9, 6), 'glow',
              loc=(tip[0], tip[1], tip[2] - 0.02))
    return P


BUILDERS.update({"sower_chibi": sower_chibi})


# ===========================================================================
# REGISTER CONVERSION 11 OF 14 - THE BOILER, 17 Nov
#
# Same read, same props, same idea, rebuilt in the game's own register; see
# the block above drillmaster_chibi for the measured Knight proportions and
# the one above snuffer_chibi for the rule that register is MASS AND COUNT,
# not man-proportions.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/boiler/hero_front|side|back.png):
#   FRONT - a wooden puppet standing beside A PARASOL TABLE. A wide flat disc
#           on two thin posts at head height is a garden table from every
#           azimuth, and the pale apron is a sandwich board (the Cook's fault
#           3, unpaid in this file).
#   SIDE  - THE MAN IS GONE. Pan at x +1.06 with the man at x -0.44 and the
#           whole creature strung along X, so at azimuth 90 the camera looks
#           straight down the line of the pair and the dish eclipses him. What
#           is left is a mushroom with sticks behind it. This is the Cook's
#           fault 5 and the Sower's pass 2, a third time.
#   BACK  - EVERY MEMBER IS THE SAME TAN. body, bone and the pan all land in
#           the same value, so the back view is one pale wooden mannequin with
#           no break anywhere except the boots.
# The one thing that works in all three is THE POUR AND THE POOL. That line
# from a held thing down to the ground is the only one in the fourteen, and
# the conversion is built around keeping it and throwing away what hides it.
#
# THE VALUE PLAN, MEASURED FIRST. At tint (0.86, 0.60, 0.34) and wear 0.25 the
# generator's `body` lands at luminance 0.508 and its `bone` at 0.577: a 14%
# separation - the Sluicekeeper's pair, not the Sower's 10%. That is enough to
# carry ONE pale object against him and no more. So:
#   the man is `body`, every break on him is `dark` (belt, boots, brow rag),
#   the SLEEVE GUARDS are the one pale thing ON him - and they are pale
#       exactly where the mechanic is, on the two hands at the handle,
#   the CRADLE AND THE PAN BODY ARE `dark`, with a `bone` RIM round the pan's
#       mouth, because a dark mass on a black field has no silhouette and
#       needs a PALE EDGE, not a different fill (the Sower's hopper, paid
#       forward), and
#   the GLOW IS THE SUGAR AND NOTHING ELSE: lit in the pan, lit in the fall,
#       lit in the pool. One material, one continuous line, three places.
#
# TWO REGISTER DECISIONS, BOTH DROPS, BOTH SAID OUT LOUD:
#  1. THE APRON IS DROPPED. 0.64 x 0.56 of flat `bone` panel hung on the front
#     plane is the Cook's sandwich board, and cook_chibi is two cells away
#     wearing one. A man who pours boiling sugar wears his armour ON HIS ARMS.
#     The pale moves to heavy sleeve guards from elbow to wrist, which clears
#     the Cook by construction and puts the only pale thing on the man onto
#     the two hands that are doing the work.
#  2. THE SKIMMER IS DROPPED FROM HIS SHOULDER AND STOOD IN THE POOL. A 0.038
#     haft with a 0.27 disc 2.0 m up in clear air is the Cook's lollipop
#     (fault 6) and from the side it was the only thing above the pan. Moved,
#     it stops being a bubble wand and becomes the creature's own evidence: a
#     scraper SET FAST in the floor it poured. Same prop, one site, two faults
#     closed and the mechanic told twice.
#
# THE CONVERSION'S ONE NEW IDEA: THE POOL IS SETTING FROM THE OUTSIDE IN.
# The original poured into a clean lit puddle with a hairline rim, which says
# POURS and does not say AND IT SETS. Here the centre is still `glow` and the
# whole edge is a heavy `bone` CRUST with three broken plates riding it, and a
# `dark` scraper standing seized in it. Liquid at the lip, set on the floor -
# the Sower's before-and-after in one silhouette, applied to a floor instead
# of to a man's two sides.
#
# EVERYTHING IS DIAGONAL IN PLAN (38 degrees): D is the pour line, E is across
# it. On the X axis this creature loses its whole mechanic at azimuth 90 and
# the original proves it. Nothing here is parallel to either camera.
#
# CARRIED FORWARD: shins `body`, boot `dark`, so the leg breaks in value at
# the ankle - proven on the Sower, where nothing covered the legs. Here the
# apron is gone, so nothing covers them either.
# PAYING ONE OF THE SOWER'S OWN FAULTS: its fault 5, "the belt reads as a flat
# plank through him, protruding past the pelvis at three-quarter". The belt on
# this creature is a FLATTENED ELLIPSOID, not the file's standard box - a ring
# at the waist cannot show a corner from any azimuth.
# ===========================================================================
CANON.update({
    "boiler_chibi": ("The Boiler (chibi)", 2.45, (0.86, 0.60, 0.34),
                     (1.00, 0.78, 0.60), "confection",
                     "IT POURS AND IT SETS - rebuilt in the game's own register",
                     0.25, "Something is pouring."),
})


def boiler_chibi():
    """The Boiler in the game's register. Same read - A BRACED MAN ROLLING A
    PAN OFF ITS LIP AND ONE THICK LIT ROPE OF SUGAR RUNNING FROM THAT LIP TO A
    POOL ON THE FLOOR - with the wire man taken to a chibi weight, the parasol
    disc rebuilt as a deep vessel on a squat cradle, the apron and the skimmer
    dropped, and the sugar made the only lit thing on the creature.

    HE LEANS BACK AND BOTH HANDS ARE ON ONE BAR. The Cook stoops under a
    weight; this man is braced AGAINST one, and two arms converging on a
    single handle is a silhouette nothing else in the fourteen makes."""
    P = Parts("boiler_chibi")
    MX, MY = 0.0, 0.0
    HIP = 0.46                                   # squatter than the Sower: braced
    # PASS 6 - THE DIAGONAL WAS AIMED AT THE ONE CAMERA I HAD NOT COUNTED.
    # The Sower's rule says every X-only direction is depth at azimuth 90, so
    # this creature's whole mechanic was put on a diagonal - and the diagonal
    # chosen (51.5 degrees in plan) sat THIRTEEN DEGREES off the file's
    # three-quarter camera at azimuth 38. The hero sheet was clean at 0 and 90
    # and the contact sheet was the original Boiler all over again: a drum on
    # a stand with a man behind it, because at 38 you look straight down the
    # pour. THE RULE, AND IT GENERALISES PAST THIS CREATURE AND PAST THIS
    # FILE: a plan diagonal is not "off-axis", it is a NUMBER, and the number
    # to pick is the one that MAXIMISES THE MINIMUM ANGLE TO EVERY CAMERA THE
    # PIECE WILL BE SHOT FROM. The azimuths here are 0, 38 and 90 (lordgen
    # VIEWS) plus 180 on the fit sheet; 64 degrees is the maximin, and it
    # takes the worst case from 13 degrees to 26 - 0 is 64 off, 38 is 26 off,
    # 90 is 26 off. "Diagonal" by eye is how a run clears two cameras and
    # loses the third without ever being told.
    DX, DY = 0.899, -0.438                       # the pour line, 64 deg in plan
    EX, EY = 0.438, 0.899                        # across it
    D = Vector((DX, DY, 0.0))

    # --- LEGS. Stubs, planted wide and braced along the pour line - the lead
    # foot under the pan, the back foot set behind him taking the weight.
    # SHINS ARE `body` AND ONLY THE BOOT IS `dark` (carried from the Sower).
    bang = math.atan2(DY, DX) + math.pi / 2.0
    for s in (-1, 1):
        st = 0.13 if s > 0 else -0.19            # the brace, along his line
        hx, hy = EX * s * 0.21, EY * s * 0.21
        fx, fy = EX * s * 0.235 + DX * st, EY * s * 0.235 + DY * st
        limb(P, [(MX + hx, MY + hy, HIP),
                 (MX + (hx + fx) * 0.5, MY + (hy + fy) * 0.5, 0.22),
                 (MX + fx, MY + fy, 0.11)], 0.152, 0.137, 'body')
        P.add(L.box(0.31, 0.42, 0.13), 'dark',
              loc=(MX + fx + DX * 0.05, MY + fy + DY * 0.05, 0.065),
              rot=(0.0, 0.0, bang))

    # --- TORSO. Pelvis bridging the hips (without one the back view is two
    # stumps under a floating ball - the Cook proved it), and a barrel LEANING
    # BACK off the pour line.
    P.add(L.sphere(0.350, 0.300, 0.180, 14, 9), 'body', loc=(MX, MY, 0.54))
    P.add(L.sphere(0.435, 0.360, 0.405, 16, 10), 'body',
          loc=(MX - DX * 0.08, MY - DY * 0.08, 1.00))
    # THE BELT IS AN ELLIPSOID, NOT THE FILE'S BOX - see the header. A ring at
    # the waist has no corner to show at three-quarter.
    P.add(L.sphere(0.452, 0.388, 0.058, 14, 6), 'dark',
          loc=(MX - DX * 0.04, MY - DY * 0.04, 0.735))
    # both shoulders come FORWARD onto the bar; the near one drops
    SHA = (MX - EX * 0.34 + DX * 0.02, MY - EY * 0.34 + DY * 0.02, 1.31)
    SHB = (MX + EX * 0.34 + DX * 0.06, MY + EY * 0.34 + DY * 0.06, 1.25)
    for sh in (SHA, SHB):
        P.add(L.sphere(0.200, 0.192, 0.182, 11, 7), 'body', loc=sh)

    # --- HEAD. Neck, skull, and HE IS LOOKING AT THE PAN - the eyes are set
    # forward along D, not along -Y, because the one thing he would be
    # watching is the lip.
    P.add(aim(L.cone(0.145, 0.178, 0.17, 10), (MX - DX * 0.03, MY - DY * 0.03, 1.43),
              (0.0, 0.0, 1.0)), 'body')
    SK = (MX - DX * 0.02, MY - DY * 0.02, 1.82)
    P.add(L.sphere(0.300, 0.288, 0.290, 15, 10), 'body', loc=SK)
    for s in (-1, 1):
        ex, ey = EX * s * 0.108, EY * s * 0.108
        P.add(L.sphere(0.058, 0.058, 0.058, 8, 6), 'bone',
              loc=(SK[0] + ex + DX * 0.262, SK[1] + ey + DY * 0.262, 1.800))
        P.add(L.sphere(0.029, 0.029, 0.029, 8, 6), 'dark',
              loc=(SK[0] + ex + DX * 0.292, SK[1] + ey + DY * 0.292, 1.806))
    # the brow rag - one `dark` band, the only thing on his head. No hat: the
    # file already carries the Snuffer's cone, the Sower's brim and the Cook's
    # cap, and a fourth is a repeat, not a character.
    P.add(L.sphere(0.303, 0.291, 0.072, 12, 6), 'dark',
          loc=(SK[0], SK[1], 1.952))

    # --- THE CRADLE. Two THICK splayed posts and a pivot bar, out along +D.
    # The original's 0.070 posts under a 1.18 m disc are what made the parasol;
    # at chibi weight they read as a stand built to hold something heavy.
    CD = 1.14                                    # how far out along D it stands
    for s in (-1, 1):
        limb(P, [(MX + DX * CD + EX * s * 0.44, MY + DY * CD + EY * s * 0.44, 0.0),
                 (MX + DX * CD + EX * s * 0.33, MY + DY * CD + EY * s * 0.33, 1.03)],
             0.118, 0.096, 'dark')
    limb(P, [(MX + DX * CD - EX * 0.40, MY + DY * CD - EY * 0.40, 1.03),
             (MX + DX * CD + EX * 0.40, MY + DY * CD + EY * 0.40, 1.03)],
         0.060, 0.060, 'dark')

    # --- THE PAN. DEEP, not a dish, and ROLLED HARD off its far lip so the
    # camera sees INTO it at the file's 6 degrees of elevation. A wide shallow
    # disc is a table top whatever you tilt it; depth plus roll is what makes
    # a vessel. `dark` body, `bone` rim, `glow` inside.
    #
    # PASS 2 - THE LIT MOUTH WAS INVISIBLE FROM ALL THREE VIEWS, AND BOTH
    # CAUSES WERE MINE. (a) THE GLOW WAS SUNK INSIDE ITS OWN RIM: an 0.080
    # tall `bone` rim wall at radius 0.47 standing over an 0.34 `glow` disc
    # set 0.028 below its top is a CUP WITH A LID ON at 6 degrees of
    # elevation - the one thing the Cook's lit mouth was supposed to have
    # closed for good. The rim is now 0.055 tall and the lit disc is 0.42
    # across and sits level with its top: the sugar fills the mouth, which is
    # what full means. (b) THE PAN WAS BARELY ROLLED. At 37 degrees off flat
    # the mouth's normal stands 53 degrees above the horizon and a camera at 6
    # sees the disc at a third of its width, so the pan read as a dark drum
    # with a pale lid. The roll is now 53 degrees - the mouth faces the room,
    # not the ceiling - and THAT is what makes a shallow vessel read as one
    # being poured out rather than as a table top.
    #
    # PASS 5 - THE PAN ATE THE MAN AT AZIMUTH 38. The three-quarter view is
    # the file's own acceptance view and it was the worst of the four: with
    # the pan centred 0.98 out and 1.27 up, its 0.93 m lit face sat exactly
    # over his chest, both arms and the whole handle, and what was left was a
    # head above a dinner plate on four legs. It is the Cook's fault 5 and the
    # original Boiler's own side view, moved one azimuth over - ONE MEMBER
    # PHYSICALLY SWALLOWING THE FIGURE - and the fix is the same one that
    # worked there: CLEAR AIR. The pan goes 0.22 further out and 0.09 lower,
    # which also buys back the hands at azimuth 90, where they had been behind
    # it since pass 2 and the man read as standing BEHIND a pan rather than
    # holding one. It costs 0.2 m of footprint and the corridor has 11.
    PC = Vector((MX + DX * 1.20, MY + DY * 1.20, 1.18))
    #
    # PASS 3 - TWO THINGS, AND THE FIRST IS A PLAIN BUG I PUT THERE. (a) THE
    # LIT DISC HAD A DARK HOLE PUNCHED THROUGH ITS MIDDLE. The pan body is an
    # ellipsoid 0.235 deep along N and pass 2 floated the `glow` disc at
    # N*0.186 - INSIDE it - so the dark pole came up through the sugar and the
    # mouth read as a washer. Anything meant to cover a solid must clear that
    # solid's own pole, measured, not guessed: the disc now sits at N*0.248.
    # (b) PASS 2 ROLLED THE PAN SO FAR THAT ITS MOUTH FACED THE ROOM FLAT ON -
    # and the room is where BOTH cameras are. A circle 53 degrees over was a
    # full circle at azimuth 0 AND at azimuth 90: the Snuffer's cone fault in
    # a new form, a shape that cannot be told apart from itself. 45 degrees
    # keeps 71% of the width in both views and reads as a pan TIPPING in
    # neither - which is the thing it actually is.
    N = Vector((DX * 0.70, DY * 0.70, 0.71)).normalized()
    TL = Vector((DX * 0.71, DY * 0.71, -0.70)).normalized()   # down-slope: the lip
    P.raw(aim(L.sphere(0.445, 0.445, 0.235, 18, 10), PC, N), 'dark')
    P.raw(aim(L.cone(0.462, 0.476, 0.070, 20), PC + N * 0.188, N), 'bone')
    P.raw(aim(L.cone(0.418, 0.430, 0.030, 18), PC + N * 0.248, N), 'glow')

    # --- THE HANDLE. One long bar from the pan's near side back to BOTH his
    # hands. This is what explains the roll, and two arms on one bar is the
    # silhouette that clears every other man in the file.
    LIP = PC + N * 0.150 + TL * 0.455
    # PASS 3 - THE ARMS WERE SWALLOWED BY THE BELLY. At z 1.09 and 1.01 the
    # hands sat level with the torso's own widest band, so from every azimuth
    # the two arms, the chest and the pelvis merged into one gourd and the
    # pale sleeve guards - the only `bone` on the man - had nothing to stand
    # against. Hands up to 1.20/1.13 and further out: the arms now leave the
    # silhouette as arms, with air under them.
    HA = Vector((MX + DX * 0.58 - EX * 0.17, MY + DY * 0.58 - EY * 0.17, 1.20))
    HB = Vector((MX + DX * 0.42 + EX * 0.22, MY + DY * 0.42 + EY * 0.22, 1.13))
    # the lever comes off the BACK of the pan at its own height and runs down
    # to the two hands. Pass 1 hung it off the rolled rim, which put it at
    # 1.61 m, straight across his face.
    limb(P, [(PC - D * 0.46 + Vector((0, 0, 0.08))), HA, HB], 0.064, 0.058, 'dark')

    # --- THE ARMS. Short, with the elbow as the silhouette, and the ONE pale
    # thing on the man: heavy sleeve guards from elbow to wrist.
    for sh, hd in ((SHA, HA), (SHB, HB)):
        el = Vector(((sh[0] + hd.x) * 0.5 + DX * 0.06,
                     (sh[1] + hd.y) * 0.5 + DY * 0.06,
                     (sh[2] + hd.z) * 0.5 - 0.09))
        limb(P, [sh, el, hd], 0.150, 0.120, 'body')
        limb(P, [el, (el + hd) * 0.5, hd - (hd - el) * 0.14], 0.172, 0.146, 'bone')
        # PASS 4 - A 13.5% PAIR CANNOT EDGE ITSELF. The `bone` sleeve guard
        # against the `body` arm is the file's weakest usable separation and
        # on a round member under flat light it simply vanished: three passes
        # and the only pale thing on the man had never once read. It does not
        # need a stronger fill, it needs a BOUNDARY - a `dark` cuff at the
        # wrist, where dark against either of them is a 5x pair. The guard is
        # now legible because of what is at its end, not because of what it
        # is made of.
        P.add(L.sphere(0.158, 0.158, 0.062, 10, 6), 'dark',
              loc=(hd.x - (hd.x - el.x) * 0.20, hd.y - (hd.y - el.y) * 0.20,
                   hd.z - (hd.z - el.z) * 0.20))
        P.add(L.sphere(0.165, 0.160, 0.152, 10, 7), 'body', loc=(hd.x, hd.y, hd.z))

    # --- THE POUR. One thick unbroken lit rope off the lip, travelling 0.6 m
    # further out along D before it reaches the floor, so it is a long clear
    # diagonal and never falls inside the pan's own footprint.
    EV = Vector((EX, EY, 0.0))
    pour = [LIP,
            LIP + D * 0.26 + EV * 0.075 + Vector((0, 0, -(LIP.z - 0.74))),
            LIP + D * 0.46 + EV * 0.090 + Vector((0, 0, -(LIP.z - 0.30))),
            LIP + D * 0.56 + EV * 0.060 + Vector((0, 0, -(LIP.z - 0.02)))]
    # PASS 2 - THE POUR WAS A SHEET, NOT A ROPE. 0.150 of radius on a 1.0 m
    # fall is 30% of the drop in width, and a ribbon that wide under flat
    # light shows one face and reads as a SAIL. Narrower, and bowed 0.09
    # across E so it is a curve in plan as well as in elevation - a falling
    # rope of sugar swings, a sail does not.
    P.raw(L.tube(pour, [0.126, 0.114, 0.107, 0.132], 10), 'glow')

    # --- THE POOL, SETTING FROM THE OUTSIDE IN. Lit centre, heavy `bone`
    # crust all round it, three broken plates riding the edge, and the scraper
    # standing seized in it.
    PL = (pour[-1].x + DX * 0.13, pour[-1].y + DY * 0.13)
    P.add(L.sphere(0.495, 0.495, 0.032, 18, 6), 'glow', loc=(PL[0], PL[1], 0.018))
    _ring(P, (PL[0], PL[1], 0.038), 0.515, 'z', 'bone', 0.072, 20)
    for k in range(3):
        a = 1.05 + TAU * k / 3.0
        cx, cy = PL[0] + 0.60 * math.cos(a), PL[1] + 0.60 * math.sin(a)
        P.raw(aim(L.cone(0.185, 0.150, 0.050, 10), (cx, cy, 0.030),
                  (math.cos(a) * 0.42, math.sin(a) * 0.42, 1.0)), 'bone')
    # PASS 2 - THE SEIZED SCRAPER WAS A GALLOWS. Pass 1 leaned a thin haft far
    # over and capped it with a 0.215 DISC, which is the lollipop I had just
    # dropped off his shoulder, put back in the floor: from the back it read
    # as a sign bracket and from the side as a music stand. A DISC ON A STICK
    # IS ALWAYS A LOLLIPOP - a tool is a BOX ON A STICK. The haft now stands
    # nearly upright, thick, and carries a flat rectangular blade whose face
    # turns back toward the room.
    # PASS 3 - and it stands on the OTHER side of the pool. On +E it was
    # directly behind the falling sugar at azimuth 90 and disappeared
    # completely from the side view; on -E it is clear of the pour in all
    # three. Shorter too - 0.90 of upright post beside a 0.50 pool was a
    # signpost, and a seized tool leans.
    # PASS 4 - IT STANDS BEYOND THE POOL NOW, NOT BESIDE IT. On -E it crossed
    # the falling sugar at azimuth 0 and cut the one line that IS this
    # creature in half, and at azimuth 180 it hid behind the same line
    # entirely: a prop that is either in front of the mechanic or behind it
    # is in the wrong place, and the only place clear of a diagonal in all
    # three views is FURTHER ALONG IT.
    SC0 = (PL[0] + DX * 0.66 - EX * 0.26, PL[1] + DY * 0.66 - EY * 0.26, 0.04)
    SC1 = (PL[0] + DX * 0.52 - EX * 0.38, PL[1] + DY * 0.52 - EY * 0.38, 0.74)
    limb(P, [SC0, SC1], 0.084, 0.070, 'dark')
    P.add(L.box(0.34, 0.11, 0.27), 'bone', loc=(SC1[0], SC1[1], SC1[2] + 0.10),
          rot=(0.0, 0.0, bang))
    P.add(L.box(0.30, 0.07, 0.055), 'dark', loc=(SC1[0], SC1[1], SC1[2] - 0.015),
          rot=(0.0, 0.0, bang))
    return P


BUILDERS.update({"boiler_chibi": boiler_chibi})


# ===========================================================================
# REGISTER CONVERSION 12 OF 14 - THE SNARER, 17 Nov. THE LAST ONE.
#
# Same read, same props, same idea, rebuilt in the game's own register; see
# the block above drillmaster_chibi for the measured Knight proportions and
# the one above snuffer_chibi for the rule that register is MASS AND COUNT.
#
# WHAT THE ORIGINAL ACTUALLY READS AS, looked at before anything was changed
# (renders/art/minibosses/snarer/hero_front|side|back.png):
#   FRONT - A PIPE-CLEANER MAN UNDER THREE FISHING RODS. 0.052 poles 2.0 m
#           tall are rods, and a 0.20 ring hanging in clear air off a 0.013
#           cord is a croquet hoop, not a noose. Nothing on the floor.
#   SIDE  - THE MECHANIC IS GONE, AND IT IS THE SOWER'S PASS 2 EXACTLY. The
#           three roots sit at x -1.34 / +1.12 / +1.62 with 0.66 m of total y
#           between them, so at azimuth 90 the poles stack into a bundle of
#           straws and ALL THREE NOOSES GO EDGE-ON AND VANISH - a ring is a
#           PLANE, and a plane seen along itself is a line. What is left is a
#           man inside a tepee of sticks.
#   BACK  - the rings read, and the man is a featureless tan mannequin: every
#           member, both poles and the floor props land in one value.
# The one thing that works in all three is THE BENT POLE ITSELF - the only
# curve in the fourteen - so the conversion keeps the curve and throws away
# everything that hid what hangs off it.
#
# THE VALUE PLAN, MEASURED FIRST. At tint (0.50, 0.42, 0.32) and wear 0.55 the
# generator's `body` lands at luminance 0.339 and its `bone` at 0.404: a 19%
# separation, THE WIDEST PAIR IN THE FILE (the Boiler's was 13.5%, the Sower's
# 10%), and `dark` sits 5.1x below `body`. 19% will carry a whole pale MASS
# against the man, not just one pale edge - so:
#   the POLES are `bone` and they are the silhouette,
#   the man is `body`, every break on him is `dark` (boots, belt, cowl), and
#       he needs no pale object at all - he is the dark middle of a pale cage,
#   the GLOW IS THE SET LINE AND NOTHING ELSE: the coil at his hip, the cord
#       out of it, the three nooses, the three trip lines between them and the
#       three taut cords climbing back to the pole tips. ONE material, ONE
#       continuous network, drawn across the whole footprint.
#
# THREE REGISTER DECISIONS, ALL SAID OUT LOUD:
#  1. THE NOOSES COME OUT OF THE AIR AND ARE SET OPEN ON THE GROUND. A ring
#     standing in the XZ plane is invisible at azimuth 90 and a ring on a
#     string is the Cook's lollipop with a hole in it. A noose LYING OPEN ON
#     THE RUN, held by stakes, under a cord to a bent pole, is also what a
#     spring snare actually is - so the fix and the truth are the same move.
#  2. THE LOOSE PEGS AND THE COIL ON THE FLOOR ARE DROPPED. Two 0.030 cones
#     and a 0.21 ring lying in the dirt were crumbs at cell size and said
#     nothing the snares do not say. The peg becomes each snare's OWN trigger
#     - one prop, three sites - and the coil moves onto his hip, where it is
#     the end of the lit network and ties the man to his own lines.
#  3. NO HAT. The file already carries the Snuffer's cone, the Sower's brim,
#     the Cook's cap and the Boiler's brow rag; a fifth crown is a repeat, not
#     a character. He gets a COWL PUSHED BACK off his head - the silhouette
#     gain is at the shoulders, where nothing else in the fourteen puts one.
#
# THE CONVERSION'S ONE NEW IDEA: THE ROOM IS DRAWN BEFORE THE FIGHT STARTS.
# The original said SNARES; it never said ALREADY SET. Here three lit trip
# lines run stake to stake between the three snares and close a triangle round
# him, a hand's height off the floor, and HE IS STANDING INSIDE IT. A viewer
# who sees this once knows where they are not allowed to walk, which is the
# whole fight - and a line at 0.12 m is a line from every azimuth, where a
# figure painted on the floor would be a smear at 6 degrees of elevation.
#
# THE PLAN LAYOUT IS SOLVED, NOT EYEBALLED, AND IT NAMES ITS OWN TEST.
# The original failed at azimuth 90 because its three snares differ almost
# only in x. So the three sites sit at plan bearings 86 / 198 / 308 at radii
# 1.05 / 0.75 / 1.25, and the roots 0.55 further out on the same bearings -
# the arrangement that MAXIMISES THE MINIMUM PROJECTED GAP between any two
# sites and any two roots over every camera this piece is shot from (azimuths
# 0, 38, 90 and 180). That minimum is 0.70 m. THE TEST, NAMED BEFORE THE RUN:
# three separate snares must be countable in all four views, the side view
# included. If two of them touch anywhere, the layout failed, not the eye.
#
# AND IT PAYS A FAULT OF THE BOILER'S THAT THE BOILER DID NOT KNOW IT HAD.
# Pass 6 there derived the right rule - a plan diagonal is a NUMBER, pick the
# one that maximises the minimum angle to every camera - and then took 64
# degrees, reporting a worst case of 26. 64 IS NOT THE MAXIMIN. A member is
# foreshortened by the camera's DEPTH axis, which lies at azimuth - 90, so the
# bad bearings for azimuths 0 / 38 / 90 / 180 are 90, 128 and 0 modulo 180,
# and the bearing furthest from all three is 45 DEGREES, worst case 45 - not
# 26. The beating pole, and the man's whole axis with it, is on 45.
# ===========================================================================
CANON.update({
    "snarer_chibi": ("The Snarer (chibi)", 2.45, (0.50, 0.42, 0.32),
                     (0.80, 0.90, 0.40), "wood",
                     "IT HAS ALREADY SET THE ROOM - rebuilt in the game's own register",
                     0.55, "The lines were here before you."),
})


def snarer_chibi():
    """The Snarer in the game's register. Same read - A HUNCHED MAN STANDING
    INSIDE HIS OWN LINES WITH THREE LOADED POLES BENT OVER HIM AND A BEATING
    POLE DRIVING DOWN TO THE FLOOR - with the wire man taken to a chibi
    weight, the hanging rings set open on the ground where a snare belongs,
    the loose floor props folded into the snares themselves, and the lit cord
    run right through from his hip to the three pole tips.

    HE IS THE DARK MIDDLE OF A PALE CAGE. 19% is the widest body/bone pair in
    the file, so for once the pale thing can be the whole structure and the
    man can be the hole in it. Nothing else in the fourteen is read that way
    round."""
    P = Parts("snarer_chibi")
    MX, MY = 0.0, 0.0
    HIP = 0.44                                   # lower than the Sower: he works bent
    # HIS AXIS IS THE MAXIMIN DIAGONAL, 45 degrees in plan - see the header for
    # why 45 and not the Boiler's 64. F is where he faces and where the beating
    # pole drives; S is across him.
    FX, FY = -0.7071, -0.7071
    SX, SY = 0.7071, -0.7071
    bang = math.atan2(FY, FX) + math.pi / 2.0

    # --- LEGS. Stubs, planted wide across S with the lead foot carried out
    # along F. SHINS ARE `body` AND ONLY THE BOOT IS `dark` (carried forward
    # from the Sower and the Boiler - the leg breaks in value at the ankle).
    for s in (-1, 1):
        st = 0.14 if s > 0 else -0.16            # the stride, along his line
        hx, hy = SX * s * 0.21, SY * s * 0.21
        fx, fy = SX * s * 0.235 + FX * st, SY * s * 0.235 + FY * st
        limb(P, [(MX + hx, MY + hy, HIP),
                 (MX + (hx + fx) * 0.5, MY + (hy + fy) * 0.5, 0.21),
                 (MX + fx, MY + fy, 0.11)], 0.150, 0.135, 'body')
        P.add(L.box(0.30, 0.41, 0.13), 'dark',
              loc=(MX + fx + FX * 0.05, MY + fy + FY * 0.05, 0.065),
              rot=(0.0, 0.0, bang))

    # --- TORSO. Pelvis bridging the hips (the Cook proved the back view is two
    # stumps under a floating ball without one) and a barrel LEANING FORWARD
    # along F, because this is a man who works bent over.
    # PASS 4 - HE WAS A SEGMENTED ABDOMEN, AND THE CAUSE IS ARITHMETIC, NOT
    # TASTE. The barrel's half-width falls to zero at its own bottom pole, so
    # a barrel 0.395 tall centred at 0.97 ENDS at 0.575 while the pelvis ball
    # topped out at 0.695 - the two met at a PINCH, with the belt disc sitting
    # in the pinch, and from every azimuth that is three stacked segments, not
    # a man. THE RULE: two stacked ellipsoids read as ONE BODY only where they
    # overlap at a width worth seeing - make the upper one reach PAST the
    # lower one's equator. The barrel is now 0.455 tall and dropped to 0.95,
    # so it reaches 0.495 and swallows the pelvis equator at 0.53.
    P.add(L.sphere(0.345, 0.295, 0.185, 14, 9), 'body', loc=(MX, MY, 0.53))
    P.add(L.sphere(0.425, 0.355, 0.455, 16, 10), 'body',
          loc=(MX + FX * 0.10, MY + FY * 0.10, 0.95))
    # THE BELT IS AN ELLIPSOID, NOT THE FILE'S BOX - the Sower's fault 5, paid
    # on the Boiler and kept: a ring at the waist has no corner to show at
    # three-quarter.
    # and the belt is a BAND INSIDE HIS OWN SILHOUETTE, not a flange on it: at
    # z 0.715 the barrel's own half-width is 0.372, so 0.400 of belt stood
    # 0.028 proud all the way round and read as a plate. 0.352 wide and 0.088
    # deep is a strap round a body.
    P.add(L.sphere(0.352, 0.312, 0.088, 14, 6), 'dark',
          loc=(MX + FX * 0.05, MY + FY * 0.05, 0.715))
    # the rear shoulder rides HIGH (the Sluicekeeper's device: the arm doing
    # the work explains the posture) and the lead shoulder drops into the drive
    SHB = (MX - FX * 0.10 + SX * 0.33, MY - FY * 0.10 + SY * 0.33, 1.30)
    SHA = (MX + FX * 0.10 - SX * 0.33, MY + FY * 0.10 - SY * 0.33, 1.19)
    for sh in (SHA, SHB):
        P.add(L.sphere(0.198, 0.190, 0.180, 11, 7), 'body', loc=sh)

    # --- HEAD, carried forward of the shoulders on the hunch, and NO HAT. The
    # cowl is pushed back off it onto the shoulders, which is the one place in
    # the fourteen nothing else puts a mass.
    P.add(aim(L.cone(0.145, 0.178, 0.17, 10), (MX + FX * 0.16, MY + FY * 0.16, 1.36),
              (0.0, 0.0, 1.0)), 'body')
    SK = (MX + FX * 0.21, MY + FY * 0.21, 1.74)
    P.add(L.sphere(0.300, 0.288, 0.290, 15, 10), 'body', loc=SK)
    for s in (-1, 1):
        ex, ey = SX * s * 0.108, SY * s * 0.108
        P.add(L.sphere(0.058, 0.058, 0.058, 8, 6), 'bone',
              loc=(SK[0] + ex + FX * 0.262, SK[1] + ey + FY * 0.262, 1.715))
        P.add(L.sphere(0.029, 0.029, 0.029, 8, 6), 'dark',
              loc=(SK[0] + ex + FX * 0.292, SK[1] + ey + FY * 0.292, 1.721))
    # PASS 3 - FROM THE BACK HE WAS A STACK OF PLATES. Pelvis, belt and cowl
    # were three flat discs at 0.345, 0.445 and 0.395 across, each wider than
    # it was deep and each at its own height, so the back view read as a pile
    # of saucers with a ball on top. THE RULE: widths up a figure must STEP,
    # not alternate - a run of discs that go narrow, wide, narrow is read as
    # separate objects stacked, and a run that narrows all the way up is read
    # as one body. The cowl is now narrower than his own shoulders (0.330
    # against 0.396 of shoulder span) and deeper, so it is a collar round the
    # neck rather than a fourth plate.
    P.add(L.sphere(0.330, 0.310, 0.185, 14, 8), 'dark',          # the cowl, down
          loc=(MX - FX * 0.07, MY - FY * 0.07, 1.335))
    # PASS 2 - THE EMPTY HOOD WAS A SECOND HEAD. A 0.30 x 0.27 x 0.195 dark
    # ellipsoid sitting behind and above the shoulder at 1.455, against a skull
    # of 0.300 at 1.74, is not read as cloth: from the front and the back it is
    # a HUMP THE SIZE OF HIS OWN HEAD on one shoulder, and the eye counts two.
    # A pushed-back hood is a collar with nothing in it, so the collar is now
    # the whole of it - the mass at the shoulders stays and the second skull
    # goes.

    # --- THE THREE SNARES. Bearing, site radius, pole height, noose radius.
    # The bearings and radii are the solved layout from the header - do not
    # nudge them by eye, the 0.70 m worst-case gap is what they are for.
    REACH = 0.55
    # PASS 2 - A SNARE SITTING ON A CAMERA'S DEPTH AXIS LANDS ON THE CREATURE
    # ITSELF, AND NO PLAN LAYOUT CAN AVOID IT. At azimuth 38 - the file's own
    # acceptance view - bearing 308 is exactly 38 - 90, so BOTH the tallest
    # pole's root and its tip projected to x = 0.000 and a 0.105 pale pole ran
    # vertically down through his head, his chest and between his feet. The
    # layout was solved for snare-against-snare and never for snare-against-
    # MAN. It cannot be solved for both: three snares ringed round a figure
    # give 6 points x 4 cameras = 24 projected positions, and the best rotation
    # of this layout still leaves one of them 0.13 m off his centre line (the
    # whole 360 was scanned). SO THE FIX IS NOT IN PLAN, AND THIS IS THE RULE
    # WORTH KEEPING: when a constraint cannot be met in plan, move the member
    # OUT OF PLAN. Two changes, both measured:
    #   (a) rotate the solved layout -6 degrees, to the rotation that MAXIMISES
    #       the minimum distance from the creature's own centre line over all
    #       four cameras - 0.000 m to 0.131 m - while the 0.70 m snare-against-
    #       snare gap the layout was solved for is unchanged by a rotation.
    #   (b) BOW EACH POLE SIDEWAYS 0.30 m at mid-height, across its own
    #       bearing, with the sign chosen per pole to carry it AWAY from the
    #       centre line in the three-quarter view. A loaded sapling bows
    #       sideways as well as over, so this is truth before it is a fix. The
    #       crossing pole's waist goes from 0.171 m off his centre to 0.470,
    #       which is past the 0.45 m half-width of his own shoulders: the pole
    #       now passes BESIDE him and reads as depth instead of bisecting him.
    SNARES = ((80.0, 1.05, 1.95, 0.30), (192.0, 0.75, 1.55, 0.26),
              (302.0, 1.25, 2.15, 0.34))
    sites = []
    for th, rr, ph, nr in SNARES:
        a = math.radians(th)
        ux, uy = math.cos(a), math.sin(a)
        sx, sy = MX + ux * rr, MY + uy * rr
        sites.append((sx, sy, nr))
        # THE POLE: a loaded sapling, THICK at the root and whippy at the tip,
        # rooted REACH further out and arcing inward over its own snare so the
        # tip stands directly above the noose. Seven points on a quarter bend,
        # because a loaded sapling is a CURVE - the only curves in the file.
        rootx, rooty = MX + ux * (rr + REACH), MY + uy * (rr + REACH)
        # the lateral bow and its sign - see pass 2 above. tx,ty is across the
        # pole's own bearing; the sign is whichever carries its waist further
        # from x = 0 in the 38-degree view, computed, not picked.
        tx, ty = -math.sin(a), math.cos(a)
        xm = (rr + 0.707 * REACH) * math.cos(a - math.radians(38.0))
        tp = math.sin(math.radians(38.0) - a)
        # PASS 4 - 0.30 of bow put the crossing pole's waist 0.470 from the
        # centre line against 0.45 of shoulder: it cleared him by 20 mm, which
        # is not clearance, it is a tangent. 0.42 puts it at 0.588 - a clear
        # gap of air between the pole and his arm - and a sapling under enough
        # load to hold a snare bows further than a tenth of its height anyway.
        bow = 0.42 * (1.0 if xm * tp > 0.0 else -1.0)
        arcpts = []
        for t in (0.0, 0.22, 0.44, 0.63, 0.79, 0.92, 1.0):
            b = (math.pi / 2.0) * t
            sw = bow * math.sin(math.pi * t)          # 0 at root, 0 at tip
            arcpts.append((rootx - ux * REACH * (1.0 - math.cos(b)) + tx * sw,
                           rooty - uy * REACH * (1.0 - math.cos(b)) + ty * sw,
                           ph * math.sin(b)))
        limb(P, arcpts, 0.105, 0.032, 'bone')
        # the whipping at the tip, where the cord is tied on. A pale member
        # needs a `dark` BOUNDARY to end on - the Boiler's pass 4, kept.
        P.add(L.sphere(0.072, 0.072, 0.052, 9, 6), 'dark', loc=(sx, sy, ph - 0.015))
        # THE CORD, taut and vertical from tip to trigger. A vertical line is
        # a line from every azimuth there is, and that is what makes the three
        # snares COUNTABLE at azimuth 90, where only two of the three pole
        # arcs ever clear the man.
        # PASS 3 - THE CORD WAS OUTSHOUTING THE THING IT IS TIED TO. At 0.028
        # of radius and emission 3.2 three of them stood up as blown-white
        # STRIP LIGHTS, the boldest objects in every view, with one of them
        # straight down the middle of his chest - and a cord is the least
        # interesting part of a snare. Halved to 0.015: still a continuous lit
        # line from every azimuth, no longer the loudest. The weight of the
        # lit network belongs to the NOOSES AND THE LINES ON THE GROUND, which
        # are the thing a player has to read and not walk into.
        limb(P, [(sx, sy, ph - 0.03), (sx, sy, 0.30)], 0.015, 0.015, 'glow')
        # the trigger peg it is holding down
        P.raw(aim(L.cone(0.052, 0.034, 0.32, 8), (sx, sy, 0.0), (0.0, 0.0, 1.0)), 'dark')
        # THE NOOSE, SET OPEN ON THE RUN a hand above the floor, held by three
        # stakes. The stakes are what keep an on-floor ring from reading as a
        # lit smear at 6 degrees: they are vertical ticks at its own radius.
        # PASS 6 - ON THE DARK CELL THE LIT NET WAS A WHITE SLAB. Everything
        # pale reads on a white fit sheet; the contact sheet is the dark one,
        # and at emission 3.2 the ring at 0.036 and the lines at 0.030 fused
        # with their own stakes into one bright PLATFORM he was standing on -
        # three nooses and three lines, which is the whole mechanic, counted
        # as one puddle. THE RULE: a lit member's radius has to be judged on
        # the DARK field, not the pale one, because emission blooms outward
        # and a pale field hides the bloom. Ring 0.036 -> 0.027 and line
        # 0.030 -> 0.021: the same drawing, drawn with a finer pen.
        _ring(P, (sx, sy, 0.115), nr, 'z', 'glow', 0.027, 18)
        for k in range(3):
            c = TAU * k / 3.0 + a
            P.raw(aim(L.cone(0.042, 0.026, 0.26, 7),
                      (sx + nr * math.cos(c), sy + nr * math.sin(c), 0.0),
                      (0.0, 0.0, 1.0)), 'dark')

    # --- THE LINES THEMSELVES, stake to stake, closing a triangle round him.
    # This is the thing the original never said: ALREADY SET. He is inside it.
    for i in range(3):
        ax, ay, _ = sites[i]
        bx, by, _ = sites[(i + 1) % 3]
        limb(P, [(ax, ay, 0.155), ((ax + bx) * 0.5, (ay + by) * 0.5, 0.100),
                 (bx, by, 0.155)], 0.021, 0.021, 'glow')

    # --- THE BEATING POLE. One long clear diagonal on the 45-degree maximin,
    # butt high behind his shoulder and the striking end driven into the floor
    # ahead of him. `dark` against `bone` poles is a 6x pair, so it crosses the
    # cage and is never lost in it.
    BUTT = (MX - FX * 0.78 + SX * 0.12, MY - FY * 0.78 + SY * 0.12, 1.60)
    H2 = (MX - FX * 0.52 + SX * 0.09, MY - FY * 0.52 + SY * 0.09, 1.45)
    H1 = (MX + FX * 0.62 - SX * 0.02, MY + FY * 0.62 - SY * 0.02, 1.00)
    TIPE = (MX + FX * 1.30 - SX * 0.05, MY + FY * 1.30 - SY * 0.05, 0.11)
    PD = (TIPE[0] - BUTT[0], TIPE[1] - BUTT[1], TIPE[2] - BUTT[2])
    limb(P, [BUTT, H2, H1, TIPE], 0.055, 0.046, 'dark')
    P.add(L.sphere(0.090, 0.090, 0.090, 10, 7), 'dark', loc=BUTT)
    P.add(L.sphere(0.105, 0.105, 0.085, 10, 7), 'dark',
          loc=(TIPE[0], TIPE[1], TIPE[2] - 0.02))

    # --- THE ARMS. TWO HANDS ON THE POLE, FAR APART AND AT TWO HEIGHTS - a
    # long diagonal of two arms, which is deliberately NOT the Boiler's pair
    # converging on one handle two cells away. Short upper arms, the elbow as
    # the silhouette, hands well clear of the barrel (the Boiler's pass 3:
    # a chibi arm that stays near the torso is swallowed by it).
    for sh, hd in ((SHB, H2), (SHA, H1)):
        el = ((sh[0] + hd[0]) * 0.5 + FX * 0.05, (sh[1] + hd[1]) * 0.5 + FY * 0.05,
              (sh[2] + hd[2]) * 0.5 - 0.07)
        limb(P, [sh, el, hd], 0.148, 0.118, 'body')
        P.add(L.sphere(0.150, 0.150, 0.058, 10, 6), 'dark',   # the wrist boundary
              loc=(hd[0] - (hd[0] - el[0]) * 0.20, hd[1] - (hd[1] - el[1]) * 0.20,
                   hd[2] - (hd[2] - el[2]) * 0.20))
        # PASS 5 - PAYING A FAULT THE WHOLE FILE CARRIES UNPAID. The Boiler's
        # own fault 10 is "his mitts do not read as gripping - they are balls
        # on the ends of tubes", and every chibi in the file has the same ball.
        # A fist round a shaft is not a sphere, it is a SHORT CYLINDER WHOSE
        # AXIS IS THE SHAFT'S - so the hand is aimed along the beating pole,
        # and from every azimuth you see a band wrapped across the staff
        # instead of a bead threaded on it. It costs nothing and it is the
        # difference between holding the pole and touching it.
        P.raw(aim(L.cone(0.168, 0.168, 0.175, 10), (hd[0], hd[1], hd[2]), PD), 'body')

    # --- THE SPARE STAKES ON HIS BACK. Three short pale stakes under a dark
    # strap, tips clearing the far shoulder. This pays a fault the Sluicekeeper
    # (2), the Sower (4) and the Boiler (8) all carried unpaid: THE BACK IS A
    # FEATURELESS BARREL AND BOTH ARMS DISAPPEAR ROUND THE FRONT. It is also
    # the only thing on him that says HE IS NOT FINISHED - there are more
    # snares to set than the three already standing - and it costs one small
    # mass seen from a view where he currently has nothing at all.
    BK = (MX - FX * 0.30, MY - FY * 0.30, 1.06)
    for k in (-1, 0, 1):
        ox, oy = SX * k * 0.085, SY * k * 0.085
        limb(P, [(BK[0] + ox - FX * 0.04, BK[1] + oy - FY * 0.04, 0.70),
                 (BK[0] + ox, BK[1] + oy, 1.52)], 0.042, 0.030, 'bone')
    P.raw(L.tube([Vector((BK[0] - SX * 0.30, BK[1] - SY * 0.30, 1.14)),
                  Vector((BK[0], BK[1], 1.08)),
                  Vector((BK[0] + SX * 0.30, BK[1] + SY * 0.30, 1.14))],
                 [0.046, 0.046, 0.046], 7), 'dark')

    # --- THE COIL AT HIS HIP, and the lit tail that runs out of it to the
    # nearest trigger. This is the end of the network: the man is physically
    # tied to his own lines, which is the sentence the whole creature is.
    CO = (MX - SX * 0.42 + FX * 0.04, MY - SY * 0.42 + FY * 0.04, 0.70)
    P.add(L.sphere(0.200, 0.195, 0.080, 12, 7), 'bone', loc=CO)
    _ring(P, (CO[0], CO[1], CO[2]), 0.145, 'z', 'glow', 0.030, 14)
    nx, ny, _ = sites[1]
    limb(P, [(CO[0], CO[1], CO[2] - 0.05),
             ((CO[0] + nx) * 0.5, (CO[1] + ny) * 0.5, 0.34),
             (nx, ny, 0.28)], 0.027, 0.027, 'glow')
    return P


BUILDERS.update({"snarer_chibi": snarer_chibi})


# =====================================================================
# FIFTEENTH, 17 Nov 2026 - THE JOINTER. Invented outright under Mr. E's
# standing permission of 15 Nov 17:43, and taken this hour because the team
# lead's 04:58 row says the art lane is dry and is the one lane the freeze
# lets invent.
#
# WHY A SECOND WORKSHOP MINIBOSS AND NOT A FIFTEENTH THEME. Measured off
# dungeon_hd.gd:737-743 this run, not remembered: the set-piece roll gives
# "miniboss" weight 15 on a normal floor, 10 on shrine and crypt, and 35 ON
# BARRACKS AND WORKSHOP. Those two themes fire the slot more than twice as
# often as any other and each has exactly ONE creature - so the floor type
# most likely to show a viewer a miniboss is the floor type that shows them
# the same one every time. Fourteen themes already have a body (floorgen.gd
# THEMES, counted this run: 14 keys, 14 minibosses). The gap is not a missing
# theme, it is a missing SECOND on the heaviest theme.
#
#   JOINTER  it COMES APART AND BOTH HALVES KEEP WORKING - one pin holds two
#            half-bodies together. Drive the pin out, or break it down, and
#            there are two of it, each with its own leg, its own lamp and its
#            own tool. Neither half is a weaker copy; each is half the thing.
#
# NOT A NORMAL MONSTER WITH MORE HIT POINTS, and the idea is visible BEFORE
# the fight starts (the Scrapwright lesson): the gap down the middle is real
# air you can see through, the pin stands proud a third of a metre either
# side, and the two halves already have two lamps at two different heights.
# A hero body cannot read like that - it has one head and its legs meet.
#
# WEAR 0.35: a workshop thing in daily use. The pin and the clamp screw are
# bright worked steel - a joiner keeps the one part that has to slide - on
# timber gone dark with grease. Unused value in the set (0.15 .. 0.95).
# =====================================================================

CANON.update({
    "jointer": ("The Jointer", 2.25, (0.60, 0.44, 0.28), (1.00, 0.92, 0.72),
                "workshop",
                "IT COMES APART AND BOTH HALVES KEEP WORKING - drive the pin or break it and there are two",
                0.35, "It is pinned together."),
})
ORDER = ORDER + ["jointer"]


# --------------------------- 15 THE JOINTER: two half-bodies and one pin
def jointer():
    """IT COMES APART. Two sawn half-bodies lashed and pinned on one iron
    draw-pin. Each half carries one leg, one lamp and one tool, so when the
    pin goes the room has two of it and neither is a cripple.

    Silhouette intent - SPLIT COLUMN, PIN THROUGH IT, TWO FEET WIDE APART:
      - real air down the middle, opening into a V as it rises (the halves
        lean away from each other), so the gap is in the outline and not just
        in the colour;
      - one long bright pin across the chest standing 0.30 m proud each side,
        the single clearest horizontal in the file;
      - ONE leg per half on its own trestle block, braced outward - a hero's
        legs meet under one torso and these do not;
      - THREE arms, not two: a mallet hanging low off the near half, a saw
        raised on the far half, and a SPARE arm hung on the far hip. An odd
        arm count is the cheapest way to stop a thing reading as a man;
      - two lamps at two different heights and no head between them.

    Front is -Y here, same as the other fourteen."""
    P = Parts("jointer")
    GLOW_SEAM_Z = (0.96, 1.82)

    # ---- the two halves. A is the near/left half (mallet), B the far/right
    # (clamp). They lean apart so the seam opens upward.
    # PASS 3: xc is the TOP of the half, held apart from xt (the leg), so the
    # halves lean away from each other and the seam opens into a V as it
    # rises. Pass 2's seam was open but almost parallel, and a parallel slot
    # reads as a shadow line; a V reads as two things coming apart.
    for s, (xl, xt, hip, top, rr, xc) in ((-1, (0.24, 0.34, 0.90, 1.92, 0.205, 0.46)),
                                          (+1, (0.21, 0.29, 0.90, 1.74, 0.190, 0.40))):
        X0, X1, XC = s * xl, s * xt, s * xc
        # ONE heavy post leg per half, on a trestle block
        limb(P, [(X1, 0.00, hip), (X1 + s * 0.06, -0.02, 0.46),
                 (X1 + s * 0.10, -0.05, 0.11)], 0.130, 0.108, 'body')
        P.add(L.box(0.40, 0.56, 0.16), 'dark', loc=(X1 + s * 0.10, -0.10, 0.08))
        # the outward brace - this is furniture, and it says so
        limb(P, [(X1 + s * 0.04, 0.01, 0.80), (X1 + s * 0.30, 0.02, 0.18)],
             0.058, 0.046, 'dark')
        P.add(L.box(0.20, 0.26, 0.09), 'dark', loc=(X1 + s * 0.32, 0.02, 0.05))
        # sawn torso: a tube for mass with a squared plank face over it, so it
        # reads as cut timber and not as a limb
        limb(P, [(X0, 0.00, hip - 0.04), (X0 + s * 0.05, -0.02, (hip + top) * 0.5),
                 (XC, -0.04, top - 0.06)], rr, rr * 0.84, 'body')
        P.add(L.box(rr * 1.50, rr * 1.12, top - hip - 0.14), 'body',
              loc=((X0 + XC) * 0.5, -0.03, (hip + top) * 0.5),
              rot=(0.0, -s * 0.10, 0.0))
        # two iron straps round the half - a joined thing is a banded thing
        for z in (hip + 0.18, top - 0.30):
            t = (z - hip) / max(0.01, top - hip)
            P.add(L.box(rr * 1.62, rr * 1.24, 0.055), 'dark',
                  loc=(X0 + (XC - X0) * t, -0.03, z))
        # cap block and THE LAMP. No head, no neck: a lamp set in the cap.
        P.add(L.box(rr * 1.66, rr * 1.46, 0.14), 'dark', loc=(XC, -0.04, top))
        eyes(P, (XC, 0.0, top - 0.02), rr * 0.36, 0.034, -0.16)
        # hip socket the spare arm hangs on, both sides for symmetry of wear
        P.add(L.sphere(0.085, 0.080, 0.070, 10, 7), 'dark', loc=(X0 + s * 0.08, 0.13, 1.00))

    # ---- THE PIN. The mechanic, and the one long horizontal in the file.
    # It passes through both halves and stands 0.30 m proud at each end.
    limb(P, [(-0.95, -0.02, 1.40), (0.0, -0.03, 1.42), (0.95, -0.02, 1.44)],
         0.052, 0.052, 'bone')
    for s in (-1, 1):
        P.raw(aim(L.cone(0.105, 0.105, 0.065, 12), (s * 0.95, -0.02, 1.40 + s * 0.02),
                  (s * 1.0, 0.0, 0.02)), 'bone')
        # the mortise plate where the pin enters the timber
        P.add(L.box(0.085, 0.27, 0.27), 'dark', loc=(s * 0.14, -0.03, 1.42))
    # the cotter through the far end - it is held, and it can be driven out
    P.raw(aim(L.cone(0.030, 0.026, 0.26, 9), (0.78, -0.02, 1.44), (0.0, 0.16, 1.0)), 'bone')

    # ---- THE SEAM. Real air between the halves, with a thin lit line in it
    # so the join reads at pane distance without filling the gap in.
    limb(P, [(0.0, 0.10, GLOW_SEAM_Z[0]), (-0.01, 0.07, 1.26),
             (-0.015, 0.05, 1.38)], 0.017, 0.012, 'glow')
    limb(P, [(-0.015, 0.05, 1.47), (-0.02, 0.06, GLOW_SEAM_Z[1] - 0.14)],
         0.013, 0.009, 'glow')
    # PASS 2, AND THE PICTURE IS WHY. Pass 1 lashed the two halves with two
    # rope turns that ran straight across the seam, and on the render they
    # read as flat SHELVES that closed the gap - the Scrapwright fault, the
    # idea invisible before the fight. Each half now carries its own turn,
    # wrapped round itself and stopping short of the seam, so the air down the
    # middle stays air. Measured: tools/art/_j_gap.py open_frac.
    for s in (-1, 1):
        for z, r in ((1.18, 0.30), (1.66, 0.33)):
            P.raw(L.tube([Vector((s * 0.12, -0.16, z)),
                          Vector((s * (0.12 + r), -0.10, z + 0.02)),
                          Vector((s * (0.12 + r * 0.9), 0.10, z - 0.01)),
                          Vector((s * 0.14, 0.14, z - 0.02))],
                         [0.030, 0.034, 0.032, 0.028], 7), 'bone')

    # ---- ARM 1: the mallet, hanging low off the near half. A long diagonal.
    limb(P, [(-0.46, -0.06, 1.72), (-0.70, -0.18, 1.40), (-0.73, -0.26, 1.08)],
         0.078, 0.056, 'body')
    limb(P, [(-0.73, -0.26, 1.06), (-0.80, -0.30, 0.54)], 0.036, 0.030, 'bone')
    P.raw(aim(L.cone(0.145, 0.145, 0.32, 12), (-0.82, -0.30, 0.44), (0.10, 0.10, 1.0)), 'dark')
    P.raw(aim(L.cone(0.152, 0.148, 0.045, 12), (-0.82, -0.30, 0.44), (0.10, 0.10, 1.0)), 'bone')

    # ---- ARM 2: PASS 4, AND THE CLAMP IS GONE BECAUSE I LOOKED AT IT. On the
    # pass-1 render the clamp read as a bracket and its jaws read as a second
    # pin cap - two of the three objects on the right-hand side were pretending
    # to be the pin. A SAW is the plainest joiner's tool there is, it is a long
    # clear plate nothing else in the file has, and it says the same sentence:
    # the far half still works.
    limb(P, [(0.44, -0.05, 1.56), (0.70, -0.18, 1.66), (0.82, -0.26, 1.74)],
         0.072, 0.052, 'body')
    P.add(L.box(0.13, 0.17, 0.26), 'dark', loc=(0.86, -0.28, 1.80), rot=(0.0, 0.34, 0.0))
    # PASS 5: the blade is pulled in off the frame edge, and THE TEETH ARE ON
    # IT. At pass 4 they were a row of free cones standing clear of the blade -
    # from the front they read as fins beside a plate, not as a saw. They are
    # now bedded along the blade's own lower edge with their bases inside it.
    BL_ = (0.97, -0.28, 1.92)
    TILT = 0.40
    P.add(L.box(0.030, 0.19, 0.86), 'bone', loc=BL_, rot=(0.0, TILT, 0.0))
    P.add(L.box(0.036, 0.055, 0.88), 'dark', loc=(BL_[0] - 0.055, BL_[1] + 0.085, BL_[2]),
          rot=(0.0, TILT, 0.0))
    ux, uz = math.sin(TILT), math.cos(TILT)        # along the blade
    ex, ez = math.cos(TILT), -math.sin(TILT)       # out of its toothed edge
    for k in range(10):
        t = (k / 9.0) - 0.5
        bx = BL_[0] + ux * 0.86 * t + ex * 0.055
        bz = BL_[2] + uz * 0.86 * t + ez * 0.055
        P.raw(aim(L.cone(0.034, 0.0, 0.072, 5), (bx, BL_[1], bz), (ex, -0.10, ez)), 'bone')

    # ---- ARM 3: THE SPARE, pinned at the near half's hip. Three arms is the
    # cheapest way to stop a silhouette reading as a man, and a joiner with a
    # spare arm on a hook is exactly what this creature IS.
    # PASS 4: it hung behind the near half at pass 1 and was a dark smear on a
    # dark leg - a third arm nobody could count. It now hangs OUTBOARD of the
    # far half's hip, under the saw, against clear background.
    # PASS 5: at pass 4 it hung with clear air between it and the body and read
    # as a dropped club. The peg is now modelled - a bone stub driven out of
    # the far half's hip - and the arm hangs ON it, touching, so the eye can
    # follow hip -> peg -> arm.
    PEG = (0.40, 0.04, 1.16)
    P.raw(L.tube([Vector(PEG), Vector((0.62, 0.06, 1.14))], 0.035, 8), 'bone')
    P.add(L.sphere(0.062, 0.058, 0.052, 10, 7), 'dark', loc=(0.62, 0.06, 1.14))
    limb(P, [(0.62, 0.06, 1.13), (0.67, 0.08, 0.92), (0.71, 0.10, 0.70)],
         0.064, 0.047, 'body')
    P.add(L.sphere(0.075, 0.068, 0.062, 10, 7), 'dark', loc=(0.72, 0.10, 0.66))

    # ---- PASS 6, AND THE SILHOUETTE SHEET IS WHY. The sheet - which IS the
    # acceptance test - frames every creature at the three_quarter view, 38
    # degrees (lordgen.VIEWS). This creature's one idea lives in a plane that
    # at 38 degrees is foreshortened to two-thirds and one half starts hiding
    # the other, so the busiest cell on the sheet was also the one where the
    # seam read least. The whole body is yawed 20 degrees so the split plane
    # turns INTO the sheet's view; the front view loses a little of the gap
    # and keeps most of it, which is the trade I would make again.
    YAW = math.radians(20.0)
    ca, sa = math.cos(YAW), math.sin(YAW)
    P.items = [([Vector((v.x * ca - v.y * sa, v.x * sa + v.y * ca, v.z)) for v in verts],
                faces, slot) for verts, faces, slot in P.items]
    return P


BUILDERS.update({"jointer": jointer})


# =====================================================================
# 16 THE QUARTERMASTER - the SECOND BARRACKS set piece, 17 Nov 2026.
#
# MEASURED, NOT REMEMBERED, before a vertex was written: floorgen.gd THEMES
# carries fourteen themes; the miniboss roll in dungeon_hd.gd is weight 35 on
# BARRACKS and WORKSHOP and 10-15 everywhere else. Workshop got its second body
# last hour (the Jointer). BARRACKS STILL HAS EXACTLY ONE - the Drillmaster -
# so the floor type most likely to show a viewer a set piece is still the floor
# type that shows them the same one every time. This closes that.
#
#   QUARTERMASTER  it ARMS THE ROOM - it does not fight you and it does not
#                  call anyone in. It hands out what is already here: every
#                  ordinary creature on the floor takes a spear or a shield
#                  off its sheaf and fights better until the sheaf is empty.
#                  Empty the sheaf or kill the issuer; leave it alone and the
#                  trash in the room stops being trash.
#
# NOT A SIXTEENTH COAT OF AN IDEA ALREADY BUILT. Checked against all fifteen:
# the Drillmaster SUMMONS bodies that were not there; the Tallyman TAKES YOUR
# gear and leaves; the Scrapwright armours ITSELF; the Cook heals the room.
# This one UPGRADES WHAT IS ALREADY STANDING and arms nothing of its own.
#
# THE IDEA IS VISIBLE BEFORE THE FIGHT STARTS (the Scrapwright lesson): the
# sheaf is a wide splayed FAN OF STRAIGHT SHAFTS over a low body, and one arm
# is already out with a spear offered on the diagonal. You can see it is
# handing something over from the doorway.
#
# SILHOUETTE COLLISIONS CHECKED AND AVOIDED, the same two the third set had to
# clear plus two more:
#   - a big disc reads as the Drillmaster's gong    -> no disc at all.
#   - a long horizontal reads as the Porter's bar   -> the offered spear is a
#     DIAGONAL across the body, never level.
#   - the Snarer owns the only CURVES in the file   -> every shaft here is dead
#     straight, and dense: a sheaf against his three thin bent saplings.
#   - the Tallyman owns a spreader bar with things hung off it -> nothing hangs;
#     the sheaf is ROOTED in a back quiver and splays UP.
#
# WEAR 0.50 - the one unused value left in the set (used: .15 .20 .25 .30 .35
# .40 .45 .55 .60 .65 .70 .80 .85 .90 .95). Right for a barracks store in daily
# use: the issued steel is kept bright, the canvas and timber are not.
# =====================================================================

CANON.update({
    "quartermaster": ("The Quartermaster", 2.35, (0.64, 0.58, 0.46), (0.92, 0.84, 0.46),
                      "barracks",
                      "IT ARMS THE ROOM - everything else in here takes a weapon off its sheaf",
                      0.50, "Something is handing out arms."),
})
ORDER = ORDER + ["quartermaster"]


_PACK_CACHE = {}


def _gear_mesh(stem):
    """REAL GEOMETRY OFF A PACK ALREADY IN THE REPO, not another procedural
    cone. `assets/gear/` is the CC0 KayKit dungeon-bits set that gearmodels.py
    already uses for D95's named weapons and that ASSET_SOURCES.md already
    logs - so the spears this thing hands out are the same spears the heroes
    carry, which is the point of a quartermaster.

    Returns (verts, faces) normalised to UNIT LENGTH about the grip, shaft
    along +Z, or None when the file or the importer refuses. A missing pack
    must never take a body out of the sheet - the caller falls back to
    procedural geometry and says so in the report.
    """
    if stem in _PACK_CACHE:
        return _PACK_CACHE[stem]
    out = None
    try:
        import bpy  # only available inside Blender; the caller handles None
        root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            os.pardir, os.pardir))
        path = os.path.join(root, "assets", "gear", stem + ".gltf")
        if os.path.isfile(path):
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=path)
            new = [o for o in bpy.data.objects if o not in before]
            # PASS 1 CAME BACK AT 12,470 FACES against a set that runs 842-2623,
            # because eight pack spears and three pack shields carry their own
            # tessellation. A collapse decimate on the IMPORT keeps the real
            # silhouette and pays the set's budget. The modifier is applied by
            # the evaluated depsgraph below, not baked into the pack file.
            for ob in [o for o in new if o.type == 'MESH']:
                if len(ob.data.polygons) > 120:
                    m = ob.modifiers.new("dec", 'DECIMATE')
                    m.decimate_type = 'COLLAPSE'
                    m.ratio = max(0.18, 120.0 / len(ob.data.polygons))
            verts, faces = [], []
            dg = bpy.context.evaluated_depsgraph_get()
            for ob in [o for o in new if o.type == 'MESH']:
                obe = ob.evaluated_get(dg)
                me = obe.to_mesh()
                mw = obe.matrix_world
                off = len(verts)
                verts.extend([mw @ v.co for v in me.vertices])
                for p in me.polygons:
                    faces.append(tuple(i + off for i in p.vertices))
                obe.to_mesh_clear()
            for ob in new:
                try:
                    bpy.data.objects.remove(ob, do_unlink=True)
                except Exception:
                    pass
            if verts and faces:
                zs = [v.z for v in verts]
                span = max(zs) - min(zs)
                if span > 1e-6:
                    k = 1.0 / span
                    out = ([Vector((v.x * k, v.y * k, v.z * k)) for v in verts], faces)
    except Exception:
        out = None
    _PACK_CACHE[stem] = out
    return out


def _lay(P, vf, slot, butt, direction, length):
    """Carry a unit-length pack part to `butt`, pointed down `direction`, at
    `length` metres. Z-up in, arbitrary axis out."""
    from mathutils import Matrix
    d = Vector(direction)
    if d.length < 1e-6:
        d = Vector((0.0, 0.0, 1.0))
    d.normalize()
    rot = Vector((0.0, 0.0, 1.0)).rotation_difference(d).to_matrix().to_4x4()
    M = Matrix.Translation(Vector(butt)) @ rot @ Matrix.Diagonal(
        Vector((length, length, length)).to_4d())
    v, f = vf
    P.raw(([M @ Vector(x) for x in v], f), slot)


def _spear_proc(length):
    """The fallback shaft, used only if the pack will not load. Said out loud
    in the report rather than silently substituted."""
    v, f = L.cone(0.018, 0.014, 0.80, 7)
    verts = [Vector(x) for x in v]
    faces = list(f)
    hv, hf = L.cone(0.055, 0.0, 0.20, 7)
    off = len(verts)
    verts.extend([Vector((p[0], p[1], p[2] + 0.80)) for p in hv])
    faces.extend([tuple(i + off for i in ff) for ff in hf])
    zs = [v.z for v in verts]
    k = 1.0 / max(1e-6, (max(zs) - min(zs)))
    return ([Vector((p.x * k, p.y * k, p.z * k)) for p in verts], faces), False


# --------------------- 16 THE QUARTERMASTER: a sheaf, and one arm already out
def quartermaster():
    """IT ARMS THE ROOM. A walking issue-rack: a low braced body under a wide
    splayed SHEAF of spears, with one long arm already out on the diagonal
    offering one of them butt-first. Nothing it carries is for itself.

    Silhouette intent - WIDE SHEAF ABOVE, LOW BRACED BODY BELOW, ONE ARM OUT:
      - the sheaf is the whole upper outline and it is DENSE AND STRAIGHT:
        six real spear shafts rooted in one back quiver, splaying up and back
        so the fan is in the outline and not in the colour;
      - the body is DELIBERATELY SHORT AND WIDE under it - a trestle, not a
        man. Shoulders at 1.42 on a 2.35 m thing, so two thirds of the height
        above the shoulder is cargo;
      - ONE ARM OUT, a straight diagonal across and forward with a seventh
        spear offered BUTT FIRST. Never level: level is the Porter's bar;
      - no head. A low issue-slate where a head would be, with the lit tally
        brand beside it - a hero body has a head and this does not;
      - three shields stacked leaning on the near leg, on the ground, so the
        store reads as a store even with the sheaf behind it.

    Front is -Y here, same as the other fifteen."""
    P = Parts("quartermaster")
    X = 0.0
    SPEAR = _gear_mesh("spear_A")
    SHIELD = _gear_mesh("shield_A")
    used_pack = SPEAR is not None
    if SPEAR is None:
        SPEAR, _ = _spear_proc(1.0)

    # ---- the base. Wide, braced, planted: this thing stands still and issues.
    _legs(P, X, hip=0.86, stance=0.27, r0=0.120, r1=0.095, boot=(0.30, 0.46, 0.12))
    # a cross-brace between the legs - furniture again, and it says so
    P.add(L.box(0.62, 0.17, 0.09), 'dark', loc=(X, 0.02, 0.42))

    # ---- the body: short, wide, square. A counter with legs.
    limb(P, [(X, 0.04, 0.80), (X, 0.00, 1.10), (X, -0.04, 1.42)], 0.255, 0.230, 'body')
    P.add(L.box(0.74, 0.40, 0.50), 'body', loc=(X, -0.02, 1.18))
    # two iron straps - a thing that carries load is a banded thing
    for z in (1.00, 1.34):
        P.add(L.box(0.80, 0.46, 0.055), 'dark', loc=(X, -0.02, z))
    # the issue slate where a head would be, canted toward the doorway
    # PASS 2: pass 1's slate plus two wide-set eyes read as a LETTERBOX FACE -
    # a robot head, i.e. exactly the hero-body read the brief forbids. It is now
    # a wide shuttered HATCH with a brim over it and the light down in the slot,
    # eyes close-set and low: a counter window, not a face.
    P.add(L.box(0.62, 0.11, 0.26), 'dark', loc=(X, -0.20, 1.52), rot=(0.22, 0.0, 0.0))
    P.add(L.box(0.70, 0.30, 0.09), 'dark', loc=(X, -0.14, 1.66), rot=(0.14, 0.0, 0.0))
    eyes(P, (X, 0.0, 1.47), 0.050, 0.026, -0.26)
    # PASS 2: the tally brand was a lollipop floating free beside the head. It
    # now grows OUT OF THE QUIVER at the back and leans, so it is rooted in
    # something and reads as a brand stuck in the stores.
    limb(P, [(X - 0.30, 0.40, 1.22), (X - 0.40, 0.26, 1.74)], 0.026, 0.019, 'bone')
    P.add(L.sphere(0.055, 0.055, 0.066, 10, 7), 'glow', loc=(X - 0.41, 0.24, 1.78))

    # ---- THE SHEAF. Six real spears rooted in one back quiver, splaying up
    # and back. The quiver is a solid block so the roots are not six holes.
    P.add(L.box(0.56, 0.30, 0.34), 'dark', loc=(X, 0.30, 1.30), rot=(-0.20, 0.0, 0.0))
    #    (x of the butt, how far out the tip goes, how far back, length)
    # PASS 2: rooted at z 1.00 instead of 1.16 and 0.12 further back, with the
    # shafts 0.18-0.22 longer. Pass 1's heads were most of each spear and the
    # fan read as a FEATHER CROWN springing from the head rather than as spears
    # standing in a quiver. The tips land at the same heights, so the body does
    # not lose scale to the normalisation.
    for bx, out_x, back_y, ln in ((-0.20, -1.06, 0.92, 1.90),
                                  (-0.12, -0.62, 1.00, 2.06),
                                  (-0.05, -0.22, 0.86, 1.82),
                                  (0.05, 0.26, 1.02, 2.00),
                                  (0.12, 0.70, 0.88, 1.88),
                                  (0.20, 1.12, 0.78, 1.74)):
        butt = (X + bx, 0.46, 1.00)
        _lay(P, SPEAR, 'bone', butt, (out_x, back_y - 0.34, 2.05), ln)

    # ---- THE OFFERED SPEAR and the arm that holds it. The mechanic, and the
    # one long diagonal in the file that is neither level nor curved.
    # PASS 2: PASS 1 PUT THE OFFERED SPEAR BEHIND THE LEGS. On the three-quarter
    # it read as a shaft leaning against the back of the near thigh, which is
    # the opposite of offering it - the one thing the whole body is for. The arm
    # now reaches FORWARD AND OUT and the hand closes ON the shaft at its
    # midpoint, measured: butt (0.30,-1.05,0.30) down (1.00,-0.25,1.15), unit
    # (0.647,-0.162,0.744), so the midpoint of a 2.00 m shaft is
    # (0.947,-1.212,1.044) and that is exactly where the hand is put.
    # PASS 3, AND IT IS A VIEW FAULT, NOT A SHAPE FAULT. Pass 2's offering arm
    # was on +X, which is the FAR side of the three_quarter camera - so the one
    # thing this body is for was hidden behind its own torso in the cell that
    # goes on the contact sheet. Arm and spear mirrored to -X (the near side),
    # and the ground store swapped to +X to keep them apart.
    limb(P, [(X - 0.30, -0.10, 1.34), (X - 0.62, -0.60, 1.20),
             (X - 0.95, -1.15, 1.05)], 0.090, 0.068, 'body')
    _lay(P, SPEAR, 'bone', (X - 0.30, -1.05, 0.30), (-1.00, -0.25, 1.15), 2.00)
    # A HAND, NOT A BALL. The Porter's planks end in flat caps and read
    # unfinished at the tips; pass 1 repeated that with a plain sphere. A fist
    # with a thumb block over the shaft reads as GRIP at pane distance.
    for hx, hy, hz, th in ((X - 0.95, -1.21, 1.04, -0.10), (X + 0.62, -0.36, 0.70, 0.09)):
        P.add(L.sphere(0.090, 0.086, 0.082, 10, 7), 'dark', loc=(hx, hy, hz))
        P.add(L.box(0.055, 0.14, 0.055), 'dark', loc=(hx + th, hy + 0.02, hz + 0.05))
    # the issue mark: a short lit band at the grip of the one being handed over
    limb(P, [(X - 0.86, -1.18, 0.96), (X - 1.02, -1.24, 1.14)], 0.028, 0.028, 'glow')

    # ---- the other arm, down and in, resting on the stacked shields
    limb(P, [(X + 0.30, -0.08, 1.32), (X + 0.52, -0.22, 1.00),
             (X + 0.60, -0.34, 0.74)], 0.088, 0.066, 'body')

    # ---- THE STORE ON THE GROUND. Three shields leaning on the near leg, so
    # the thing reads as a store from the front where the sheaf foreshortens.
    # PASS 2: 0.78 m made each shield TALLER THAN THE TORSO and the stack read
    # as a dropped kite lying across the floor, the loudest wrong thing in the
    # sheet. 0.52 m is a shield a man carries, and they now STAND against the
    # near leg leaning only slightly, so the stack reads as stores propped up.
    for i, (sx, sy) in enumerate(((0.72, -0.34), (0.82, -0.24), (0.92, -0.14))):
        if SHIELD is not None:
            _lay(P, SHIELD, 'bone', (X + sx, sy, 0.02), (0.20, -0.06, 1.0), 0.60)
        else:
            P.add(L.box(0.40, 0.09, 0.56), 'bone', loc=(X + sx, sy, 0.28),
                  rot=(0.0, -0.20, 0.0))
    # PASS 2: the two spare shafts ran THROUGH the shield stack and out the far
    # side. They now lie on open floor forward of it, clear of every other part.
    # PASS 3: pass 2 moved these only 0.28 m and they STILL ran through the
    # shield faces and out the far side. Measured this time: the shields stand
    # at y -0.34 .. -0.14, so the shafts go to y -1.24 .. -1.10, a clear 0.76 m
    # of floor in front of the nearest shield face and nothing between.
    for k in range(2):
        _lay(P, SPEAR, 'dark', (X + 1.62, -1.24 + k * 0.14, 0.05 + k * 0.045),
             (-1.0, 0.10, 0.04), 1.44)

    P.used_pack = used_pack
    return P


BUILDERS.update({"quartermaster": quartermaster})


# =====================================================================
# 17 THE LOADER - the SECOND MESS-HALL set piece, 17 Nov 2026.
#
# MEASURED, NOT REMEMBERED, before a vertex was written:
#   - dungeon_hd.gd:737-743 - the miniboss roll is 35 on BARRACKS and WORKSHOP,
#     15 on prison and on every unlisted theme, and 10 on shrine and crypt.
#     Barracks and workshop both got a second body in the last two hours
#     (the Jointer, the Quartermaster), so the 35s are served. TEN themes tie
#     at 15 with exactly ONE body each; MESS is one of them.
#   - floorgen.gd THEMES - the mess hall's own clusters are "feast", "feast",
#     "kegs", "shelf_stock". It is the one 15-weight floor that is already
#     FULL OF CRATES AND KEGS, so a creature built out of the room's own
#     stores belongs there and needs no new prop to explain itself. Its one
#     body, the Cook, HEALS the room - nothing of this mechanic.
#
#   THE LOADER     it WEIGHS YOU DOWN - it does not take anything off you and
#                  it does not call anyone in. It puts a load ON you. A hero
#                  it reaches is carrying something, and carries it until they
#                  spend the time to drop it. Nothing is stolen, nothing dies
#                  faster - the whole party just gets slower while it works.
#
# NOT A SEVENTEENTH COAT OF AN IDEA ALREADY BUILT. Checked against all sixteen,
# and the two it could have collided with are named: the TALLYMAN takes gear
# OFF a hero and withdraws with it; the QUARTERMASTER hands weapons to the
# other monsters. This one gives something to the HEROES and it is a penalty,
# not a theft and not a buff. ENCUMBRANCE IS A MECHANIC CLASS NOTHING IN THIS
# FILE USES: sixteen bodies summon, armour, drag, darken, revive, bar, steal,
# heal, flood, plant, trap, depend on fuel, misdirect, set the floor, split and
# arm the room - not one of them touches what a hero can CARRY.
#
# THE IDEA IS VISIBLE FROM THE DOORWAY (the Scrapwright lesson): the thing is a
# STACK OF CRATES WITH LEGS, bent double under its own load, and one more crate
# is already swinging out on a boom at hip height - the next one is yours.
#
# SILHOUETTE COLLISIONS CHECKED AND AVOIDED:
#   - a lopsided pile reads as the SCRAPWRIGHT  -> the Scrapwright is a rounded
#     organic mound of torn plates. This is a DEAD-SQUARE REGULAR COLUMN of
#     six like boxes - the only right-angled stack in the file.
#   - a long level bar reads as the PORTER's leaf, and things hung off a level
#     bar read as the TALLYMAN -> the boom is a DIAGONAL, dropping 0.44 m over
#     0.84 m, and ONE load hangs off it. Everything else is stacked, not hung.
#   - a big disc reads as the DRILLMASTER's gong -> nothing round and large.
#   - a splayed fan of straight shafts reads as the QUARTERMASTER -> the column
#     is solid and opaque; there is no fan anywhere on it.
#
# USE WHAT IS ON DISK BEFORE GENERATING A MESH (Mr. E, 16 Nov 04:46): the
# crates, the keg and the sack are REAL GEOMETRY out of the KayKit Dungeon Pack
# (CC0) already sitting in _packs/, decimated on import and baked into the
# exported .glb. Procedural boxes are the fallback and the report says which
# was used. Logged in docs/art/ASSET_SOURCES.md.
#
# WEAR 0.75 - the one value left unused in the set's .15-.95 ladder, and the
# right one for a stores hand in daily use: the canvas and the timber are
# worn through, the iron banding is kept because the load would spill without.
# =====================================================================

CANON.update({
    "loader": ("The Loader", 2.65, (0.58, 0.52, 0.42), (0.86, 0.94, 0.58),
               "mess",
               "IT WEIGHS YOU DOWN - it loads you, and you fight slower until you drop it",
               0.75, "Something is putting a load on you."),
})
ORDER = ORDER + ["loader"]

# the KayKit Dungeon Pack (CC0) bits this body stands on, by file stem
_DUNGEON_GLB = ("kaykit_dungeon_pack_CC0", "Models", "gltf")


def _dungeon_mesh(stem, max_faces=90):
    """Real pack geometry, normalised into the UNIT CUBE (0..1 on every axis,
    min corner at the origin) so the caller can place it by metres.

    Looked for in the repo's own assets/gear first, then in the pack tree at
    `<repo parent>/_packs/kaykit_dungeon_pack_CC0/Models/gltf/`. Returns None
    when neither answers, and the caller falls back to a plain box and SAYS SO
    in the report - a silent substitution is the same fault class as a lying
    gate.
    """
    ck = ("dung", stem, max_faces)
    if ck in _PACK_CACHE:
        return _PACK_CACHE[ck]
    out = None
    try:
        import bpy
        root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            os.pardir, os.pardir))
        cands = [os.path.join(root, "assets", "gear", stem + ".gltf"),
                 os.path.join(os.path.dirname(root), "_packs", *_DUNGEON_GLB,
                              stem + ".gltf.glb")]
        path = next((p for p in cands if os.path.isfile(p)), None)
        if path:
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=path)
            new = [o for o in bpy.data.objects if o not in before]
            for ob in [o for o in new if o.type == 'MESH']:
                if len(ob.data.polygons) > max_faces:
                    m = ob.modifiers.new("dec", 'DECIMATE')
                    m.decimate_type = 'COLLAPSE'
                    m.ratio = max(0.10, float(max_faces) / len(ob.data.polygons))
            verts, faces = [], []
            dg = bpy.context.evaluated_depsgraph_get()
            for ob in [o for o in new if o.type == 'MESH']:
                obe = ob.evaluated_get(dg)
                me = obe.to_mesh()
                mw = obe.matrix_world
                off = len(verts)
                verts.extend([mw @ v.co for v in me.vertices])
                for p in me.polygons:
                    faces.append(tuple(i + off for i in p.vertices))
                obe.to_mesh_clear()
            for ob in new:
                try:
                    bpy.data.objects.remove(ob, do_unlink=True)
                except Exception:
                    pass
            if verts and faces:
                mn = [min(v[i] for v in verts) for i in range(3)]
                mx = [max(v[i] for v in verts) for i in range(3)]
                ex = [max(1e-6, mx[i] - mn[i]) for i in range(3)]
                out = ([Vector(((v[0] - mn[0]) / ex[0], (v[1] - mn[1]) / ex[1],
                                (v[2] - mn[2]) / ex[2])) for v in verts], faces)
    except Exception:
        out = None
    _PACK_CACHE[ck] = out
    return out


def _unit_box():
    """The fallback: lordlib's box carried into the same 0..1 unit cube."""
    v, f = L.box(1.0, 1.0, 1.0)
    return ([Vector((x[0] + 0.5, x[1] + 0.5, x[2] + 0.5)) for x in v], f)


def _crate(P, vf, slot, cx, cy, cz, sx, sy, sz, yaw=0.0):
    """Place a unit-cube pack part as a real box: centred on (cx, cy), BASE at
    cz, `sx/sy/sz` metres, spun `yaw` radians about its own centre."""
    v, f = vf
    ca, sa = math.cos(yaw), math.sin(yaw)
    out = []
    for p in v:
        x = (p.x - 0.5) * sx
        y = (p.y - 0.5) * sy
        out.append(Vector((cx + x * ca - y * sa, cy + x * sa + y * ca, cz + p.z * sz)))
    P.raw((out, f), slot)


# ------------------- 17 THE LOADER: a stack of crates with legs, and one more
def loader():
    """IT WEIGHS YOU DOWN. A stores hand bent double under a column of crates,
    with one more already swung out on a boom at the height of your chest.

    Silhouette intent - SQUARE COLUMN ABOVE, BENT BODY UNDER IT, ONE LOAD OUT:
      - the column is SIX LIKE BOXES stacked dead square, stepping a little
        left and right as a real stack settles, the top one overhanging. It is
        the whole upper outline and it is solid: no fan, no disc, no curve;
      - the body underneath is SHORT, WIDE AND PITCHED FORWARD about 50
        degrees, so the back is a near-level platform the column stands on and
        the thing reads BENT, not standing. A hero stands upright; this does
        not;
      - NO HEAD. A hooded shoulder hump with the eyes low and deep under its
        brim, where a man carrying a load would have his face;
      - ONE BOOM out on the near side, falling on the diagonal, with a single
        crate hanging off its end on a short chain at hip height - the one
        that is about to be yours;
      - a keg and a sack already dumped on the floor on the far side, so the
        store reads as a store from the front where the column foreshortens.

    Front is -Y here, same as the sixteen before it."""
    P = Parts("loader")
    # PASS 2, AND THE PICTURE IS WHY. Pass 1 built all six stacked crates from
    # the pack mesh decimated to 90 faces, because six pack crates at usable
    # fidelity would have blown the set's face budget on their own. On the
    # render every one of them came back as an OPEN CRUMPLED TRAY - the decimate
    # ate the lids and the box corners, so the column read as a tiered drying
    # rack and the keg on the floor read as a spiked ball. A pack mesh is only
    # worth loading where its detail can be AFFORDED, so: the stack is built as
    # closed banded boxes (dead square, which is the silhouette intent anyway),
    # and the pack geometry is spent where it is actually looked at - THE ONE
    # CRATE BEING HANDED OVER, the keg and the sack - at 300/160/140 faces.
    CRATE = _dungeon_mesh("crate", 300)
    KEG = _dungeon_mesh("barrelDark", 160)
    SACK = _dungeon_mesh("lootSackA", 140)
    used_pack = CRATE is not None
    if CRATE is None:
        CRATE = _unit_box()
    if KEG is None:
        KEG = _unit_box()
    if SACK is None:
        SACK = _unit_box()

    # ---- the base: short, wide, planted. This thing carries, it does not run.
    _legs(P, 0.0, hip=0.72, stance=0.30, r0=0.125, r1=0.100, boot=(0.34, 0.50, 0.13))
    P.add(L.box(0.66, 0.18, 0.09), 'dark', loc=(0.0, 0.04, 0.36))      # cross-brace

    # ---- THE BENT BODY. The spine pitches forward to -Y: hips at +0.10,
    # shoulders out at -0.34, so the back lies back and up as a platform.
    limb(P, [(0.0, 0.10, 0.66), (0.0, -0.10, 1.02), (0.0, -0.34, 1.22)], 0.270, 0.230, 'body')
    P.add(L.box(0.78, 0.44, 0.46), 'body', loc=(0.0, -0.16, 1.00), rot=(-0.42, 0.0, 0.0))
    for z, y in ((0.86, -0.06), (1.16, -0.26)):                        # two iron straps
        P.add(L.box(0.84, 0.50, 0.055), 'dark', loc=(0.0, y, z), rot=(-0.42, 0.0, 0.0))
    # the hooded hump where a head would be, and the eyes down under its brim
    P.add(L.sphere(0.22, 0.24, 0.17, 12, 8), 'body', loc=(0.0, -0.36, 1.30))
    P.add(L.box(0.46, 0.30, 0.07), 'dark', loc=(0.0, -0.44, 1.36), rot=(0.30, 0.0, 0.0))
    eyes(P, (0.0, -0.30, 1.22), 0.048, 0.025, -0.24)

    # ---- THE BACK FRAME the column stands on. Two uprights off the hips and
    # one crossbar, so the stack is CARRIED and not balanced on a shoulder.
    # PASS 5, AND IT IS THE SIDE VIEW THAT SAYS SO. At pass 4 the column sat
    # at y +0.15 while the body leaned forward to -0.34, so from the side there
    # was OPEN AIR between the creature's back and the bottom crate and the
    # whole load read as a stack balanced on a thin pole standing behind a
    # crouching thing. The load must be ON the body: the frame is thicker and
    # stands further forward, the shelf comes forward with it, and a pad block
    # bridges the shoulders to the lowest crate so the two actually touch.
    for s in (-1, 1):
        limb(P, [(s * 0.26, 0.12, 0.70), (s * 0.28, 0.14, 1.14), (s * 0.26, 0.12, 1.40)],
             0.075, 0.062, 'dark')
    P.add(L.box(0.68, 0.16, 0.08), 'dark', loc=(0.0, 0.13, 1.36))
    P.add(L.box(0.78, 0.52, 0.07), 'dark', loc=(0.0, 0.06, 1.42))      # the shelf
    # the pad the load rests on, from the shoulders back to the shelf
    P.add(L.box(0.62, 0.40, 0.10), 'body', loc=(0.0, -0.16, 1.40), rot=(-0.22, 0.0, 0.0))

    # ---- THE COLUMN. PASS 3, AND AGAIN THE PICTURE IS WHY. Pass 2's boxes
    # were 0.80 of their own width tall and each carried a lid plate, so on the
    # render the column read as a STACK OF TRAYS - flat lipped things, a
    # wedding cake, not cargo. A crate is CUBIC and it has no lip. Four cubic
    # boxes with two iron bands each and nothing on top, stepping a little as a
    # real stack settles. The body shrinks under the normalisation when the
    # load gets taller, which is the right way round for this creature.
    #      (base z, side, x offset, y offset, yaw)
    for bz, sd, dx, dy, yw in ((1.42, 0.50, -0.03, 0.04, 0.05),
                               (1.92, 0.45, 0.06, 0.07, -0.10),
                               (2.37, 0.40, -0.05, 0.03, 0.13),
                               (2.77, 0.35, 0.08, 0.06, -0.07)):
        P.add(L.box(sd, sd * 0.94, sd), 'body' if int(bz * 100) % 2 else 'bone',
              loc=(dx, dy, bz + sd / 2.0), rot=(0.0, 0.0, yw))
        for t in (0.26, 0.74):                                   # two iron bands
            P.add(L.box(sd * 1.04, sd * 0.97, 0.038), 'dark',
                  loc=(dx, dy, bz + sd * t), rot=(0.0, 0.0, yw))
    # PASS 4, AND IT IS TWO PARTS THAT EXISTED AND DID NOTHING. On the pass-3
    # render NEITHER the lashing rope NOR the signal lamp could be seen in any
    # view: both sat at y +0.15..+0.18, which is INSIDE the column's own
    # footprint, so the crates ate them. A part the camera cannot see is not a
    # part. Both are now carried on the FRONT faces at y -0.16, where the one
    # thing standing in front of them is air.
    # the rope: one turn up the front of the stack and over its shoulder
    P.raw(L.tube([Vector((-0.28, -0.24, 1.58)), Vector((-0.06, -0.26, 1.88)),
                  Vector((0.10, -0.20, 2.14)), Vector((0.22, -0.10, 2.40))],
                 [0.030, 0.034, 0.030, 0.026], 7), 'dark')
    # the signal lamp, socketed on the shelf's own near edge and standing clear
    # of the bottom crate (side 0.50 at x -0.03, so its face is at x -0.28)
    P.add(L.box(0.11, 0.11, 0.13), 'dark', loc=(-0.46, -0.26, 1.46))
    P.add(L.sphere(0.060, 0.060, 0.068, 10, 7), 'glow', loc=(-0.46, -0.26, 1.57))

    # ---- THE BOOM, ON THE NEAR (-X) SIDE, where the three_quarter camera can
    # see it. A diagonal: 0.84 m across, 0.44 m down. Never level.
    limb(P, [(-0.30, -0.14, 1.26), (-0.70, -0.40, 1.04), (-1.14, -0.62, 0.82)],
         0.085, 0.060, 'body')
    P.add(L.sphere(0.092, 0.088, 0.084, 10, 7), 'dark', loc=(-1.14, -0.62, 0.82))
    # the chain, and THE CRATE THAT IS ABOUT TO BE YOURS, hanging off its end.
    # This one is REAL PACK GEOMETRY - it is the mechanic and it is the thing
    # the eye lands on.
    limb(P, [(-1.14, -0.62, 0.80), (-1.16, -0.62, 0.62)], 0.022, 0.022, 'bone')
    _crate(P, CRATE, 'bone', -1.16, -0.62, 0.26, 0.46, 0.42, 0.36, 0.22)
    # PASS 2: the lit issue band ran 0.44 m and stood out past both sides of
    # that crate - at pane distance it read as a white plank skewered through
    # it. It is now a short mark on the near face only.
    limb(P, [(-1.26, -0.84, 0.40), (-1.06, -0.84, 0.40)], 0.018, 0.018, 'glow')

    # ---- THE STORE ON THE FLOOR, far (+X) side, clear of the boom.
    # PASS 2: pass 1 put a keg, a sack AND a third crate inside 0.40 m of each
    # other and they read as one spiked lump. Two objects, set apart.
    _crate(P, KEG, 'bone', 0.82, -0.10, 0.0, 0.40, 0.40, 0.52)
    _crate(P, SACK, 'dark', 1.18, -0.52, 0.0, 0.44, 0.40, 0.34, 0.5)

    P.used_pack = used_pack
    return P


BUILDERS.update({"loader": loader})


# =========================================================== 18 THE HURDLEMAN
# Chosen by MEASURING the set, not by remembering it (17 Nov 08:40 CT):
#   - SEVENTEEN ideas exist. Parsed out of CANON above, not recalled: summon,
#     self-armour, drag-a-hero, douse the lamps, will-not-stay-down, bar the
#     door, steal gear, heal the pack, raise the water, plant the ground,
#     pre-set the room, scale with the fire, ring from elsewhere, set the
#     floor, come apart in two, arm the room, weigh you down.
#     NOT ONE OF THEM DIVIDES THE PARTY. That is this one.
#   - THEME COVERAGE, counted off the game's own files (floorgen.gd THEMES +
#     BIOMES = 14 themes; dungeon_hd.gd:737-743 for the weights): barracks 2,
#     workshop 2, mess 2, every other theme 1. Grassland sits at weight 15 with
#     one body (the Sower) and its clusters are overgrowth/stores/collapse -
#     a sunken meadow is the one room where a hurdle explains itself without a
#     word of lore, because a hurdle is what you pen a meadow with.
#   - WEAR: the .15-.95 ladder is FULL - seventeen creatures, seventeen steps
#     of 0.05, I checked every one. This body takes 1.00 and extends the top of
#     the ladder rather than repeating a step. It is honest for the thing it
#     is: split grey hurdles that have stood out in a wet meadow for years.
#   - Height 2.55 was free (2.00-2.70 in use, 2.55 the gap).
CANON.update({
    "hurdleman": ("The Hurdleman", 2.55, (0.58, 0.60, 0.50), (0.72, 0.90, 0.68),
                  "grassland",
                  "IT CUTS THE ROOM IN TWO - it plants a hurdle through your line and you "
                  "fight it two and two",
                  1.00, "A hurdle just went down between you."),
})
ORDER = ORDER + ["hurdleman"]


def _hurdle(P, ox, oy, yaw, w=1.46, h=1.78, tilt=0.0, bars=7):
    """ONE HURDLE, STANDING, PLANTED. Built in its own local frame (x across,
    z up) and carried out to (ox, oy) through a yaw, because the whole point of
    this part is that it is NOT square to the camera in any view.

    THIS IS THE ONLY OPEN LATTICE IN THE SET. Every other miniboss is solid
    mass - a disc, a mound, a column, a sheaf. A thing you can see the room
    through is a silhouette nobody else has, and it is also exactly what the
    mechanic looks like: a line across the floor that a hero cannot cross.
    """
    c, s = math.cos(yaw), math.sin(yaw)

    def place(vf, lx, lz, slot, lroll=0.0):
        P.add(vf, slot, loc=(ox + lx * c, oy + lx * s, lz), rot=(0.0, tilt + lroll, yaw))

    half = w / 2.0
    for sgn in (-1, 1):                                   # the two driven posts
        place(L.box(0.105, 0.115, h), sgn * half, h / 2.0, 'bone')
        place(L.box(0.26, 0.26, 0.055), sgn * half, 0.028, 'dark')   # turf heaped at the foot
    inner = half - 0.17
    for i in range(bars):                                 # the vertical bars
        lx = -inner + 2.0 * inner * i / float(bars - 1)
        place(L.box(0.052, 0.062, h * 0.88), lx, h * 0.47, 'bone')
    for t in (0.17, 0.55, 0.93):                          # three rails, through-woven
        place(L.box(w + 0.13, 0.072, 0.082), 0.0, h * t, 'body')
    for sgn in (-1, 1):                                   # withy lashings at the corners
        for t in (0.17, 0.93):
            P.add(L.sphere(0.052, 0.052, 0.046, 8, 6), 'dark',
                  loc=(ox + sgn * half * c, oy + sgn * half * s + 0.06, h * t))


def _spare_panel(P, cx, cy, cz, yaw, pitch, w=0.86, h=1.22, bars=5):
    """A SPARE HURDLE RIDING ON THE BACK, and it is an OPEN LATTICE like the one
    already standing - which is the whole correction of pass 4.

    Pass 3 carried the spares as thin SOLID slabs with three slats laid on the
    face. On the render they came back as one grey billboard behind the body:
    the biggest mass in the silhouette, reading as a door or a shield - the
    exact OPPOSITE of what a hurdle is, which is a thing you can see through.
    It also ate the man's outline, because a solid field behind a grey body
    leaves the body nothing to read against. Built open, the fan says `more
    fences` at a glance and the body reads through the gaps.
    """
    cw, sw = math.cos(yaw), math.sin(yaw)
    sp = math.sin(pitch)

    def place(vf, u, v, slot):
        P.add(vf, slot, loc=(cx + u * cw + v * sp * sw,
                             cy + u * sw - v * sp * cw,
                             cz + v * math.cos(pitch)), rot=(pitch, 0.0, yaw))

    half = w / 2.0
    for sgn in (-1, 1):
        place(L.box(0.075, 0.062, h), sgn * half, 0.0, 'bone')
    inner = half - 0.12
    for i in range(bars):
        place(L.box(0.044, 0.050, h * 0.86), -inner + 2.0 * inner * i / float(bars - 1),
              0.0, 'bone')
    for t in (-0.34, 0.34):
        place(L.box(w + 0.09, 0.056, 0.066), 0.0, t * h, 'body')


def hurdleman():
    """IT CUTS THE ROOM IN TWO. It does not bar the door - the Porter does that,
    and being shut in is not the same fight as being cut in half. This one puts
    a hurdle THROUGH the middle of your line: the front rank and whoever was
    behind them are now two fights, and the healer is on the wrong side of it
    until somebody breaks a panel down.

    Silhouette intent - A MAN, A FAN OF FLAT PANELS ON HIS BACK, AND ONE
    HURDLE ALREADY UP:
      - the HURDLE is the read and it stands apart from him on his right,
        yawed 34 degrees so it is never edge-on and never square in any of the
        three views. It is an OPEN GRID - the only one in eighteen creatures;
      - the SPARES ride flat and fanned across his back - WIDE AND THIN, which
        is the opposite outline to the Loader's square column of cubes, and
        deliberately so, because they are the nearest two in this set;
      - he is LEAN AND LONG-ARMED, not a barrel, and he is swinging a beetle
        down and to the right on a long clean diagonal into the hurdle's foot.
        The diagonal says the hurdle is going in NOW;
      - no helm and no visor: a head woven out of withies, the same stuff as
        the hurdles, with the eyes deep inside the weave.

    Front is -Y, the same as the seventeen before it."""
    P = Parts("hurdleman")
    # 17 Nov: PART SPANS, so each fault can be measured ON ITS OWN and not by
    # eye. tools/art/_hurdle_probe.py renders one group at a time off these
    # index ranges - a metric computed over a group that is EMPTY reports RED.
    # Purely a record of where each section starts and ends in P.items; it
    # changes no geometry.
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = -0.46                                   # the man stands left of centre
    _i_man = len(P.items)

    # ---- planted, and leaning into the swing rather than standing to attention
    _legs(P, MX, hip=0.84, stance=0.25, r0=0.098, r1=0.080, boot=(0.27, 0.44, 0.11))
    P.add(L.box(0.52, 0.16, 0.08), 'dark', loc=(MX, 0.03, 0.40))

    # ---- LEAN torso, carried over to the right and forward into the work
    limb(P, [(MX, 0.08, 0.78), (MX + 0.10, -0.02, 1.14), (MX + 0.24, -0.12, 1.48)],
         0.205, 0.165, 'body')
    P.add(L.box(0.30, 0.34, 0.10), 'dark', loc=(MX + 0.08, 0.00, 1.06))      # belt
    SL = (MX - 0.02, -0.12, 1.48)
    SR = (MX + 0.50, -0.12, 1.46)
    # PASS 6, FROM THE BACK VIEW AND NOWHERE ELSE. The shoulders were pale
    # 'body' spheres at 0.145, and from behind the left one sat just below and
    # beside the withy head at almost the same tone - so the creature read
    # TWO-HEADED. Smaller, and in the dark slot: a shoulder, not a skull.
    for sh in (SL, SR):
        P.add(L.sphere(0.112, 0.105, 0.098, 10, 7), 'dark', loc=sh)

    # ---- THE WITHY HEAD. No face, no brim. The Loader's hooded brim came back
    # reading as a visor and I named it; this is the other answer - the head is
    # made of the same woven rod as the hurdles, so the creature and its work
    # are one material.
    _span("man_lower", _i_man)
    _i_head = len(P.items)
    HD = (MX + 0.30, -0.16, 1.76)
    limb(P, [(MX + 0.26, -0.13, 1.52), HD], 0.070, 0.058, 'bone')
    P.add(L.sphere(0.175, 0.170, 0.160, 12, 8), 'bone', loc=HD)
    # PASS 7, FAULT 4 OF THE EIGHT, AND IT IS THE ONE I SAID I HAD NOT SOLVED.
    # Written at the time: "the withy head still reads as a helmet with a visor
    # band at pair scale - the crossing rings plus two lit eyes." The cause was
    # in the loop, not in the idea: the three rings ran y, x AND Z, and a ring
    # on the Z axis is a HORIZONTAL HOOP ROUND THE HEAD. One dark band across a
    # pale skull at eye height IS a visor, whatever it is made of, and two lit
    # dots sitting on it finish the helmet. Measured: a band score of 0.5618 -
    # the worst row of the weave covering 56 points more of its row than the
    # median row does.
    # A BASKET IS WOVEN THE OTHER WAY. Every hoop is now a MERIDIAN - a vertical
    # ring through the crown, stepped round in yaw - so the dark runs top to
    # bottom like the rods of a hurdle and the head is made of the same stuff as
    # the fences, which was always the intent. One slack binding hoop stays, but
    # it is dropped to the NECK, below the skull, where a withy head would be
    # tied off and where it cannot be read as a brow.
    for _k in range(5):
        _yw = math.pi * _k / 5.0
        _c, _s2 = math.cos(_yw), math.sin(_yw)
        _pts = []
        for _i in range(17):
            _t = TAU * _i / 16.0
            _rr = 0.170 * math.cos(_t)
            _pts.append(Vector((HD[0] + _rr * _c, HD[1] + _rr * _s2,
                                HD[2] + 0.163 * math.sin(_t))))
        P.raw(L.tube(_pts, [0.016] * len(_pts), 6), 'dark')
    _ring(P, (HD[0], HD[1], HD[2] - 0.158), 0.088, axis='z', slot='dark',
          rad=0.019, n=12)
    # AND THE EYES COME OFF THE BROW LINE. Two dots side by side at the widest
    # part of a head are a visor's eye slot no matter what is round them, so
    # they drop into the weave below the equator, draw closer together and
    # shrink - a light INSIDE the basket, which is what the written intent
    # ("the eyes deep inside the weave") said in the first place.
    # *** PASS 11, REGRESSION 2 OF THE TWO, AND THE INSTRUMENT WAS LYING TO ME
    # *** UNTIL THIS RUN. *** I wrote at pass 10 that "the head now has no face
    # at all" and recorded 156 px of glow beside it, and both were true at once,
    # which should have been the tell. The probe renders a group ALONE, so it
    # measured two spheres that were INSIDE THE SKULL: the bone head's surface
    # at this height is 0.152 forward and the eyes sat at 0.110 - forty
    # millimetres behind their own face. Occlusion-aware, the honest number for
    # what I shipped is head_glow_visible_px = 0. Not dim. NONE.
    # So the eyes come OUT to the weave line rather than deeper into it. They
    # stay BELOW the equator and stay CLOSE together, because that is what kept
    # the visor read away (band score 0.5618 -> 0.1379 and it must not come
    # back) - what changes is that they now break the surface and can be seen.
    eyes(P, (HD[0], HD[1], HD[2] - 0.072), 0.044, 0.027, -0.168)

    _span("head", _i_head)
    _i_tool = len(P.items)

    # ---- THE BEETLE, two-handed, on a long diagonal down to the hurdle's foot.
    # It is the one clean straight line on the creature and it points AT the
    # mechanic, which is how the Drillmaster's mallet was made to work.
    # PASS 5, AND IT IS ONE FAULT IN TWO VIEWS. The head was a 10-sided CONE,
    # i.e. a cylinder, and at y -0.82 it sat inside the standing hurdle's own
    # plane. In both renders it read as a BARREL LYING ON THE FLOOR beside the
    # fence, with the haft lost behind the lattice - a loose prop, not a tool
    # in two hands. A beetle head is a squared BLOCK, and it has to be in front
    # of the hurdle where the haft can be seen reaching it.
    HAFT = [(MX + 0.44, -0.26, 1.38), (MX + 0.80, -0.56, 0.88), (MX + 1.00, -1.04, 0.46)]
    limb(P, HAFT, 0.046, 0.040, 'bone')
    BD = (0.29, -0.76, -0.58)
    P.raw(aim(L.box(0.21, 0.21, 0.40), (MX + 1.06, -1.20, 0.34), BD), 'dark')
    for b in (-0.12, 0.12):                                  # two iron bands on the head
        P.raw(aim(L.box(0.235, 0.235, 0.040),
                  (MX + 1.06 + b * BD[0], -1.20 + b * BD[1], 0.34 + b * BD[2]),
                  BD), 'bone')
    limb(P, [SL, (MX + 0.16, -0.30, 1.32), (MX + 0.52, -0.28, 1.30)], 0.082, 0.058, 'body')
    limb(P, [SR, (MX + 0.68, -0.42, 1.18), (MX + 0.82, -0.58, 0.90)], 0.082, 0.058, 'body')

    _span("tool_arms", _i_tool)
    _i_hurdle = len(P.items)

    # ---- THE HURDLE ALREADY UP. Off to his right and forward, yawed 34
    # degrees and a little out of plumb, as a panel driven in by hand is.
    # PASS 2, AND THE HARNESS IS WHY - it went RED on its own author. Pass 1
    # measured 4.89 m of footprint, the widest of the eighteen by 1.2 m
    # (the Gaoler's chain coil is 3.72), and the hero+creature pair blew the
    # fixed 5.60 m fit frame at 6.75. The composition was spread, not the
    # idea: the hurdle stood off at arm's length, the spare fan reached a
    # half-metre past the body's left, and the stakes lay further out again.
    # Everything comes in; nothing is removed.
    # PASS 3: 3.78 m and pair 5.64 against a 5.60 frame - a 40 mm miss is
    # still a miss, and the left edge turned out to be the SPARE FAN, not
    # the stakes I had trimmed. Measured, not guessed, and the fan came in
    # with it. 1.10 m of clear floor still separates the man from his
    # hurdle, which is the whole read.
    # PASS 4 PART B, AND THE SIDE VIEW IS WHY. At pass 3 the hurdle stood at
    # y -0.10, the same depth as the body, so from 90 degrees it ECLIPSED THE
    # MAN ENTIRELY - lattice, a withy head over the top, and no creature. A
    # 34 degree yaw does not help there: 34 off the front camera is 56 off
    # the side one, i.e. nearly face-on to it. So the hurdle goes FORWARD, a
    # metre clear of the body, and the yaw opens to 41 degrees. It now stands
    # BETWEEN the camera and the creature in the side view, which is not a
    # compromise - it is the mechanic drawn: the fence is between you and it.
    # PASS 7, FAULT 3 OF THE EIGHT. Written at the time: "in the creature's own
    # three-quarter framing the standing hurdle covers the body from the chest
    # down - a strong image, and it is the mechanic, but it is A HURDLE WITH A
    # MAN BEHIND IT, not a man with a hurdle." Measured off isolated renders
    # through one camera: 46.6% of the man's own pixels sat behind the hurdle,
    # and 53.1% of everything below his chest line.
    # THE LEVER IS HEIGHT, NOT PLACE. Moving it would undo pass 4 part B, which
    # put the hurdle a metre forward so the SIDE view has a creature in it. A
    # real sheep hurdle is waist-to-chest high on a man anyway - 1.78 m was
    # a door. 1.40 m clears his belt and leaves the whole torso, the arms, the
    # swing and the head standing above it, and the fence still crosses the
    # floor in front of him, which is the whole mechanic.
    _hurdle(P, ox=0.46, oy=-0.92, yaw=0.72, w=1.18, h=1.40, tilt=0.05)

    _span("hurdle", _i_hurdle)
    _i_spares = len(P.items)

    # ---- THE SPARES ON HIS BACK: three flat panels, fanned. WIDE AND THIN is
    # the whole instruction - the Loader is a square column and these must not
    # be mistaken for it from across a room.
    # PASS 7, FAULT 1 OF THE EIGHT I WROTE DOWN, AND IT IS A BACK-VIEW FAULT.
    # Written at the time: "from the back the three spares read as a loose
    # jumble of sticks, not as panels carried in a fan - the posts splay and
    # cross at odd angles". Measured, that was a 13.63 degree spread between
    # the three panels' own screen axes and every panel two-thirds buried
    # behind another (overlap 0.67 / 0.59 / 0.60).
    # THREE THINGS MAKE A CARRIED BUNDLE READ AS ONE: the panels sit at the
    # SAME height, they step by the SAME angle, and SOMETHING TIES THEM. They
    # had none of the three - different heights, an uneven yaw step and
    # nothing holding them - so each post ended somewhere of its own and the
    # fan came back as kindling. Even step, one height, and a strap.
    # AND THE STEP HAD TO BE WIDER THAN MY FIRST TRY, WHICH THE NUMBER CAUGHT
    # AND MY EYE WOULD NOT HAVE: the even yaw step alone took the splay from
    # 13.63 to 9.92 degrees but drove the MIDDLE panel's overlap UP from 0.59
    # to 0.76 - sandwiched between its neighbours, i.e. three panels showing
    # two. A 0.20 m lateral step levelled all three at 0.387.
    #
    # *** AND THEN THE PICTURE VETOED THE NUMBER, WHICH IS THE WHOLE REASON
    # *** THE RULE IS LOOK AT IT. At 0.20 m the back view was right and the
    # FRONT and THREE-QUARTER were worse than what I started with: the fan
    # reached out past both his shoulders and read as a SECOND FENCE standing
    # beside him - a man penned between two hurdles instead of a man carrying
    # spares. Every number I had was still improving. So the lateral step comes
    # back to 0.12 m and the separation moves into DEPTH, where it costs the
    # front view nothing, and the panels lie back harder (pitch 0.26 -> 0.38)
    # so their tops stay under his shoulders instead of rising past his ears.
    # *** AND THE PITCH CHANGE WAS A MISTAKE AND THE NUMBER CAUGHT IT. *** Lying
    # them back to 0.38 took the splay to 24.34 degrees - WORSE THAN THE 13.63
    # I started from, and worse in the exact way the fault describes. Pitch and
    # yaw are not independent on screen: tipping a yawed panel back rotates its
    # projected long axis, so the flatter lie re-created the splay the even yaw
    # step had just removed. Pitch goes back to 0.26 and ONLY the lateral step
    # and the depth step carry the fix. I would not have seen this by eye.
    # The overlap number goes back up and I am not going to pretend otherwise:
    # it is a BACK-VIEW measure, and the fault it was built for - "the posts
    # splay and cross at odd angles" - is fixed by the even yaw step, which
    # this keeps.
    # AND THE TOPS COME DOWN BY TRANSLATION, WHICH IS THE LEVER THE PITCH
    # SHOULD HAVE BEEN. At dz 1.00 the panels topped out at 1.61 against a head
    # at 1.76, so in the three-quarter view they stood up round his skull and
    # the whole thing read as A MAN IN A PEN - fence in front, fan behind, him
    # in the middle - which is the opposite of a man who BUILDS the pen. Moving
    # them down is a pure translation: it cannot rotate a projected axis, so the
    # splay fix is untouched, and the tops now sit at his shoulder.
    # PASS 11b, AND IT IS THE SECOND LEVER, MEASURED ON ITS OWN. Shrinking the
    # panels uncovered the man (0.4209 -> 0.3310) and cost overlap: the three
    # buried each other harder (0.531/0.769/0.540 -> 0.613/0.844/0.613), i.e.
    # three panels showing as two. The 0.20 m lateral step the PICTURE vetoed at
    # pass 7 was vetoed because the fan reached past both shoulders - at 0.86 m
    # panels. At 0.67 m the fan has 0.19 m of width back to spend, so the step
    # goes to 0.15 and the bundle is still narrower than it was before I touched
    # it. If the picture vetoes it again the number does not get to win.
    for _pi, (yw, dx, dy, dz) in enumerate(((-0.16, -0.33, 0.24, 0.84),
                                            (0.00, -0.18, 0.40, 0.84),
                                            (0.16, -0.03, 0.56, 0.84))):
        _i_p = len(P.items)
        # PASS 11, REGRESSION 1 OF THE TWO I NAMED AS MADE WORSE. Written at the
        # time: "from the back the man is still mostly behind his own gear, and
        # this pass made it slightly worse - 0.3944 hidden before, 0.4209 now."
        # I looked at the pair render before touching a dial and the number is
        # KINDER THAN THE PICTURE: from behind there is no creature in the frame
        # at all, only a head and two shoulder knobs over a wall of fence.
        # THE LEVER IS PANEL SIZE, and it is one lever - a uniform scale on the
        # panel, not a new placement. At w 0.86 the fan is 1.10 m across against
        # SHOULDERS THAT MEASURE 0.52 - he was carrying a bundle more than twice
        # his own width, which is why he disappeared behind it and why the front
        # view read as a man penned between two fences. Spares are SPARES: they
        # are carried, so they are smaller than the one already standing (1.18 m
        # wide), and at 0.78 of their old size they still weave five bars.
        _spare_panel(P, MX + dx, dy, dz, yw, 0.26, w=0.86 * 0.78, h=1.22 * 0.78)
        _span("spare%d" % _pi, _i_p)
    # THE STRAP. Two bands of dark withy across the whole fan and one over the
    # right shoulder - the thing that says CARRIED rather than LEANING. It is
    # also the only part of the fan that crosses the panels on purpose, so the
    # crossings the eye does see now mean something.
    for _t, _r in ((0.30, 0.052), (-0.26, 0.046)):
        limb(P, [(MX - 0.42, 0.20, 0.84 + _t), (MX - 0.18, 0.38, 0.84 + _t),
                 (MX + 0.02, 0.58, 0.84 + _t)], _r, _r * 0.86, 'dark')
    limb(P, [(MX + 0.30, 0.16, 1.40), (MX + 0.26, 0.32, 1.10),
             (MX + 0.02, 0.54, 0.86)], 0.050, 0.042, 'dark')

    _span("spares", _i_spares)
    _i_floor = len(P.items)

    # ---- AND THERE IS MORE WHERE THAT CAME FROM, which is the Scrapwright's
    # trick and the right one: the floor says the fight is not over after one
    # panel. A bundle of sharpened stakes and a coil of withy binding.
    for i, (sx, sy) in enumerate(((-1.00, -0.44), (-0.92, -0.56), (-0.96, -0.30))):
        limb(P, [(sx, sy, 0.07 + i * 0.045), (sx + 0.62, sy + 0.16, 0.07 + i * 0.045)],
             0.040, 0.026, 'bone')
    _ring(P, (0.30, -0.66, 0.045), 0.21, axis='z', slot='dark', rad=0.038, n=14)
    _ring(P, (0.30, -0.66, 0.105), 0.17, axis='z', slot='dark', rad=0.034, n=14)

    _span("floor", _i_floor)
    P.used_pack = False
    return P


BUILDERS.update({"hurdleman": hurdleman})


# ============================================================ 19 THE TANNER
# WHY THIS ONE, MEASURED OFF minibosses.py AND OFF THE GAME - NOT REMEMBERED.
#   - EIGHTEEN IDEAS EXIST AND NOT ONE OF THEM CLOSES A DOOR ON A WEAPON.
#     Parsed out of CANON, not recalled: summon, self-armour, drag a hero out,
#     douse the lamps, will-not-stay-down, bar the door, steal gear, heal the
#     pack, raise the water, plant the ground, pre-set the room, scale with the
#     fire, ring from elsewhere, set the floor, come apart in two, arm the
#     room, weigh you down, cut the room in two. ADAPTIVE RESISTANCE - the same
#     blow stops working - is a mechanic class the set does not have.
#     IT IS NOT THE SCRAPWRIGHT. The Scrapwright replaces what you knocked off
#     and the fight is unchanged: hit it again, harder. The Tanner never heals
#     a point; it takes one of your answers away and leaves the rest. The party
#     that brought one weapon is in trouble and the party that brought three
#     is not, which is a DECISION, not a damage sponge.
#   - THEME: `flooded`, measured off dungeon_hd.gd:737-743. The miniboss roll
#     is 35 on barracks and workshop, 10 on shrine and crypt, 15 on prison and
#     every unlisted theme - and `flooded` is unlisted, so it rolls at 15 with
#     exactly ONE body behind it (the Sluicekeeper). Every miniboss a flooded
#     floor has ever shown is the same creature. Same reasoning the Loader used
#     for the mess hall. A tan-pit is standing water that nobody wants to be
#     near, so the room explains the trade without a word of lore.
#   - WEAR 0.10, AND IT EXTENDS THE BOTTOM OF THE LADDER. I checked all
#     eighteen: 0.15 to 1.00 in steps of 0.05 is FULL (the Hurdleman took 1.00
#     to extend the top). 0.10 is the honest value rather than a repeat,
#     because FRESHNESS IS THIS CREATURE'S MECHANIC. It is the one thing down
#     there that is never allowed to get old - it is wearing skins it dressed
#     this hour. Mr. E's rule 2: condition is the receipt, and here the receipt
#     reads "newly covered".
#   - HEIGHT 2.75 likewise extends a full ladder (2.00-2.70 in 0.05s, all
#     taken). It is the FRAME that is 2.75 and not the man: he is stooped over
#     a beam at chest height and reads SHORTER than the Bellman he is taller
#     than, which is the point of measuring the body rather than the creature.
CANON.update({
    "tanner": ("The Tanner", 2.75, (0.78, 0.72, 0.56), (1.00, 0.95, 0.72),
               "flooded",
               "IT WILL NOT TAKE THE SAME BLOW TWICE - what hurts it once it pegs a fresh "
               "hide over; change your answer or stop hurting it",
               0.10, "It is pegging up a fresh hide."),
})
ORDER = ORDER + ["tanner"]


def _hide(P, cx, cy, cz, yaw, w=0.46, h=0.62, bow=0.10, slot='bone', laced=True):
    """ONE SKIN STRETCHED IN A BAY - NOT HUNG OFF A RAIL.

    *** PASS 2, AND THIS IS THE FAULT THAT KILLED PASS 1. *** Pass 1 hung three
    tapered panels UNDER the rails with rigid triangular leg-flaps at the top
    corners. On the render they came back as three PAPER SACKS, or buckets, or
    lampshades - a hard funnel outline, hanging, swinging free - and with a
    post-and-lintel frame behind them the whole creature read as a GIBBET WITH
    THREE BAGS ON IT. Gothic flourish is exactly what Bellmire's register does
    not want, and it was not even the right trade: a tenter does not hang a
    skin, it STRETCHES one, edge to edge, until the bay is full and the hide is
    drum-tight. So this is built the way the thing actually works - nearly the
    full width of the bay, pegged on all four edges, laced to the uprights, and
    bowed TOWARD the viewer so the light reads it as a taut surface. The taper
    is now slight and the bottom edge is ragged, which is what says SKIN
    instead of CANVAS.
    """
    c, s = math.cos(yaw), math.sin(yaw)

    def world(u, v, n):
        return (cx + u * c + n * s, cy + u * s - n * c, cz + v)

    rows = (0.47, 0.50, 0.49, 0.45, 0.38)        # taut, barely tapered
    ragged = (0.0, 0.0, 0.0, 0.0, -0.055)        # the untrimmed tail edge
    ny, nx = len(rows), 5
    grid = []
    for i, hw in enumerate(rows):
        v = h * (0.5 - i / float(ny - 1))
        row = []
        for j in range(nx):
            t = j / (nx - 1.0)
            u = (-1.0 + 2.0 * t) * hw * w * 2.0
            n = bow * math.sin(math.pi * t) * math.sin(math.pi * (0.18 + 0.82 * i / (ny - 1.0)))
            row.append(Vector(world(u, v + ragged[i] * math.sin(math.pi * t * 2.0), n)))
        grid.append(row)
    P.raw(surf(grid, 0.020), slot)
    for sgn in (-1, 1):                           # pegs at the four corners
        for vt in (0.50, -0.50):
            P.add(L.sphere(0.032, 0.032, 0.028, 7, 5), 'dark',
                  loc=world(sgn * w * 0.98, h * vt, bow * 0.25))
        if laced:                                 # the lacing out to the upright
            for vt in (0.26, -0.26):
                limb(P, [world(sgn * w * 0.96, h * vt, 0.0),
                         world(sgn * w * 1.26, h * vt, -0.02)], 0.013, 0.013, 'dark', ring=5)


def _tenter(P, ox, oy, yaw, w=1.04, h=2.75):
    """THE TENTER FRAME, AND THE TOP RAIL IS GONE ON PURPOSE.

    PASS 1 PUT A LINTEL ACROSS THE TOP OF TWO POSTS, which is the outline of a
    gallows and nothing else - the three hanging panels did the rest. Here the
    uprights run PAST the top rail as bare poles and there is no crossbar at
    the crown, so the silhouette tops out in two separate points instead of one
    closed gate. Three bays, and only two of them carry a skin: the empty bay
    is daylight through the middle of the creature (the Hurdleman's argument
    for an open lattice) and it is also the mechanic standing there in the
    geometry - one answer still open.
    """
    c, s = math.cos(yaw), math.sin(yaw)

    def place(vf, lx, lz, slot):
        P.add(vf, slot, loc=(ox + lx * c, oy + lx * s, lz), rot=(0.0, 0.0, yaw))

    half = w / 2.0
    for sgn in (-1, 1):
        place(L.box(0.110, 0.120, h), sgn * half, h / 2.0, 'body')
        place(L.box(0.30, 0.30, 0.060), sgn * half, 0.030, 'dark')
    for t in (0.17, 0.44, 0.71):                 # three rails, no crown rail
        place(L.box(w + 0.14, 0.074, 0.070), 0.0, h * t, 'body')
    # one raking brace, on the far side only, so the frame leans into the room
    limb(P, [(ox + half * c, oy + half * s, h * 0.70),
             (ox + (half + 0.52) * c, oy + (half + 0.52) * s + 0.34, 0.04)],
         0.050, 0.038, 'body')


def tanner():
    """IT WILL NOT TAKE THE SAME BLOW TWICE. Hit it with fire and the next fire
    does less; hit it with a blade and the blade stops biting. It does not heal
    and it does not grow - it CLOSES DOORS. The party that brought one answer
    runs out of answers; the party that brought three does not. That is the
    fight, and it is a decision rather than a longer health bar.

    Silhouette intent - A RACK WITH TWO BAYS FILLED AND ONE OPEN, A LOW BEAM,
    AND A MAN BENT OVER IT:
      - the RACK is the read, right of him and yawed 31 degrees so it is
        edge-on in no view. Skins STRETCHED across the bays, not hung off them,
        and no crown rail - two bare poles at the top, not a gate;
      - the BEAM is the second mass and it is LOW AND HORIZONTAL, which no
        other creature in this set has. PASS 1 MADE IT ENORMOUS and it ate the
        man: 0.175 m of radius and 1.46 m of log laid across his chest read as
        a cannon on a cradle with a torso stuck behind it. It is now 0.112 and
        1.04, set at hip height and off to his left, so the MAN is the mass in
        the middle and the beam is the thing he is working on;
      - he is STOOPED - head below shoulder height, both hands down and IN on a
        two-handled knife. No hero stands like that, and the stoop is what
        keeps a biped out of hero territory;
      - a heavy APRON chest to shin - invisible in pass 1 behind the beam, and
        the whole front of him now that the beam is out of the way.

    Front is -Y, the same as the eighteen before it.
    """
    P = Parts("tanner")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = -0.40
    _i_frame = len(P.items)

    # PASS 5, ONE NUMBER, AND THE SIDE VIEW IS WHY. At 31 degrees the rack is
    # 31 off square to the front camera and 59 off to the side one, and the
    # side shot came back with the two skins squeezed into narrow strips - the
    # rack, which is the whole read, nearly disappears in one of the three
    # views the register demands. 45 is the only yaw that treats front and
    # side the SAME: 45 off square in both, so no view ever gets the thin edge
    # and none gets the flat face either.
    FY = 45.0 * math.pi / 180.0
    FX, FYc = 0.86, 0.22
    _tenter(P, FX, FYc, FY, w=1.04, h=2.75)
    # TWO bays filled, the TOP one left open. Top-open matters: an empty bay at
    # eye height is daylight where a solid field would otherwise be, and the
    # two filled bays sit low where they overlap the man's own height and read
    # against him rather than above him.
    # PASS 3: bow 0.105/0.095 came back as two matched PILLOWS - identical
    # bolsters stacked in a ladder. A tenter pulls a skin FLAT; the bulge was
    # me over-selling the curve. Halved, and the two bays are now different
    # sizes, because two identical rectangles stacked read as furniture.
    _hide(P, FX, FYc, 2.75 * 0.580, FY + 0.00, w=0.44, h=0.62, bow=0.052)
    _hide(P, FX, FYc, 2.75 * 0.300, FY + 0.00, w=0.37, h=0.56, bow=0.044)
    _span("rack", _i_frame)
    _i_beam = len(P.items)

    # ---- THE BEAM, small and low, on a single short trestle. Pass 1 gave it
    # two long splayed legs and the left one read as a loose plank leaning in
    # mid-air with nothing under it.
    # PASS 3, TWO FAULTS IN ONE PART. (a) At 0.74 the beam crossed him at the
    # hip and the whole creature read as A MAN SEATED ON A STOOL HUGGING A
    # PLANK - not a stoop, a sit. A beam is worked at waist-to-chest height, so
    # it goes UP to 0.96 and he leans OVER it. (b) The legs splayed outward and
    # the left one came back as a LOOSE POST STANDING IN MID-AIR beside him,
    # with daylight between it and the log it was supposed to hold. They are
    # now short and VERTICAL, directly under the two ends, where a trestle is.
    # PASS 4, ONE CHANGE ONLY, AND IT IS THE LAST THING OBVIOUSLY WRONG IN THE
    # PICTURE. The beam's LEFT end was buried behind the man's apron, so from
    # the front and the three-quarter all you saw of that half was its trestle
    # leg: A PALE POST STANDING BY ITSELF WITH DAYLIGHT ROUND IT, holding up
    # nothing. Pass 3 made the legs vertical, which was right, and did not fix
    # this, which is a different fault - the LOG was in the wrong place, not
    # the leg. Shifted 0.30 m to his right and shortened 1.06 -> 0.94 so BOTH
    # ends stand clear of the body and each leg is visibly under its own end.
    BC = (MX + 0.04, -0.54, 0.96)
    BD = (1.0, 0.10, -0.05)
    P.raw(aim(L.cone(0.108, 0.094, 0.94, 12), BC, BD), 'body')
    for t in (-0.42, 0.42):
        ex, ey = BC[0] + t * 1.0 * BD[0], BC[1] + t * BD[1]
        ez = BC[2] + t * BD[2]
        limb(P, [(ex, ey, ez - 0.07), (ex, ey - 0.02, 0.04)], 0.052, 0.044, 'body')
    _span("beam", _i_beam)
    _i_man = len(P.items)

    _legs(P, MX, hip=0.84, stance=0.23, r0=0.100, r1=0.082, boot=(0.27, 0.44, 0.11))
    # PASS 3: the back ran 0.46 m forward over 0.54 m of rise and read as
    # UPRIGHT once the beam was in front of it. It now runs 0.62 forward over
    # 0.48 of rise, with the shoulders AHEAD of the hips rather than above
    # them - a back that is visibly a curve from every side.
    limb(P, [(MX, 0.16, 0.78), (MX + 0.05, -0.12, 1.06), (MX + 0.12, -0.46, 1.26)],
         0.205, 0.166, 'body')
    SL = (MX - 0.18, -0.46, 1.250)
    SR = (MX + 0.40, -0.44, 1.232)
    # PASS 2: the shoulders were 0.110 spheres and on the render they were the
    # two darkest, roundest things on the body - they read as KNOBS on the ends
    # of two raised stubs. Smaller, and tucked inboard of the arm line.
    for sh in (SL, SR):
        P.add(L.sphere(0.086, 0.082, 0.076, 9, 6), 'dark', loc=sh)

    _span("man_lower", _i_man)
    _i_head = len(P.items)

    HD = (MX + 0.17, -0.70, 1.37)
    limb(P, [(MX + 0.12, -0.49, 1.27), HD], 0.072, 0.060, 'body')
    P.add(L.sphere(0.168, 0.172, 0.158, 12, 8), 'bone', loc=HD)
    # the crop of hair sits ABOVE the equator, where a visor cannot be - no
    # horizontal dark band anywhere on this face (the Hurdleman's two passes).
    P.add(L.sphere(0.170, 0.150, 0.082, 12, 6), 'dark', loc=(HD[0], HD[1] + 0.028, HD[2] + 0.098))
    # eyes BREAK the bone surface (0.158 forward at this height), pass 11's
    # finding applied before the fact: a light inside its own skull measures
    # bright and renders as nothing.
    eyes(P, (HD[0], HD[1], HD[2] - 0.040), 0.050, 0.029, -0.150)
    _span("head", _i_head)
    _i_work = len(P.items)

    ap = []
    for i in range(5):
        v = i / 4.0
        z = 1.12 - 0.72 * v
        hw = 0.27 + 0.08 * v
        yb = -0.42 - 0.13 * v - 0.055 * math.sin(math.pi * v)
        ap.append([Vector((MX + 0.06 + u * hw, yb, z)) for u in (-1.0, -0.5, 0.0, 0.5, 1.0)])
    P.raw(surf(ap, 0.026), 'dark')

    # ---- BOTH ARMS DOWN AND IN. Pass 1 ran them down and OUT to grips 0.78 m
    # apart, and with the shoulder knobs on the outside the pair read as raised
    # forelimbs. The grips come in to 0.52 m and drop to 0.86, below the elbow,
    # so the forearms slope DOWNWARD toward the middle - the line of a man
    # bearing down on a knife.
    # PASS 3, AND THIS IS THE FAULT I FAILED TO FIX AT PASS 2. Twice now the
    # arms have come back as RAISED STUBS in the front view, and the cause was
    # never the height - the grips were already 0.46 m below the shoulders. It
    # is that the forearms ran TOWARD THE CAMERA (y -0.34 to -0.70) and a limb
    # pointing at the lens is foreshortened to nothing: all the front view ever
    # showed was the upper arm splaying outward from a dark shoulder knob, and
    # an inverted V peaking at the shoulders is a raised arm whatever the
    # numbers say. The Hurdleman's beetle works because its diagonal lies IN
    # THE PLANE OF THE VIEW. So the hands now sit at nearly the shoulders' own
    # depth and the arms fall almost straight DOWN the picture to the beam.
    GL = (MX - 0.22, -0.56, 1.02)
    GR = (MX + 0.28, -0.54, 1.02)
    limb(P, [SL, (MX - 0.21, -0.52, 1.14), GL], 0.080, 0.056, 'body')
    limb(P, [SR, (MX + 0.35, -0.50, 1.14), GR], 0.080, 0.056, 'body')

    # ---- THE FLESHING KNIFE. Pass 1 made it a thin TUBE and it came back as a
    # bent wire floating in front of the beam. A knife is a FLAT TAPERED PLATE,
    # so it is built as one - a bowed strip with width, which catches the light
    # down its length and reads as an edge.
    kb = arc(GL, GR, 0.040, 7)
    kb = [Vector((p.x, p.y - 0.085, p.z - 0.040)) for p in kb]
    kgrid = [[Vector((p.x, p.y, p.z + dz)) for p in kb] for dz in (0.052, -0.052)]
    P.raw(surf(kgrid, 0.026), 'bone')
    for g in (GL, GR):
        P.add(L.cone(0.040, 0.036, 0.155, 8), 'dark',
              loc=(g[0], g[1] - 0.085, g[2] - 0.040), rot=(math.pi / 2.0, 0.0, 0.0))

    # ---- THE NEXT SKIN, over his left shoulder, same shape as the two on the
    # rack so the man and his rack are obviously the same trade at a glance.
    _hide(P, MX - 0.26, -0.34, 1.06, 0.40, w=0.15, h=0.38, bow=0.060, laced=False)
    _span("work", _i_work)
    return P


BUILDERS.update({"tanner": tanner})


# ============================================================ 20 THE REEVE
# WHY THIS ONE, MEASURED OFF minibosses.py, dungeon_hd.gd AND delve.gd - NOT
# REMEMBERED. Every claim below was re-derived this run.
#   - NINETEEN IDEAS EXIST AND NOT ONE OF THEM TOUCHES WHAT THE FLOOR PAYS.
#     Parsed out of CANON rather than recalled: summon, self-armour, drag a
#     hero out, douse the lamps, will-not-stay-down, bar the door, steal worn
#     gear, heal the pack, raise the water, plant the ground, pre-set the room,
#     scale with the fire, ring from elsewhere, set the floor, come apart in
#     two, arm the room, weigh you down, cut the room in two, adaptive
#     resistance. Every one of them is about the FIGHT. None is about the TAKE.
#     THE REWARD IS A REAL RESOURCE IN THE CODE, not an invention of mine:
#     delve.gd:34 carries `haul` = {ore, stone, gear, potion} and _loot() at
#     :2014 adds gold at :2038 and ore/stone at :2066-7. So a creature that
#     stands between the party and that dictionary is attacking something the
#     game already has, with no new system behind it.
#   - IT IS NOT THE TALLYMAN, AND THAT IS THE ONE IT HAD TO BE CHECKED
#     AGAINST. The Tallyman lifts gear OFF A HERO, wears it, and WITHDRAWS -
#     it is theft from a body and it leaves. The Reeve never touches a hero and
#     never leaves: it is chained to its own box by construction, and what it
#     takes is the FLOOR'S take, which nobody is carrying yet. One is a
#     pickpocket, the other is a toll. The pressure is different too: the
#     Tallyman makes you chase, the Reeve makes you HURRY.
#   - THEME `keep`, measured off dungeon_hd.gd:737-743 - the miniboss roll is
#     35 on barracks and workshop, 10 on shrine and crypt, 15 on prison and
#     every unlisted theme. `keep` is unlisted, so it rolls at 15 with exactly
#     ONE body behind it (the Porter), the same single-body case the Loader
#     and the Tanner were built for. And floorgen.gd:183 makes the room argue
#     for it without a word of lore: the inner keep is the only theme with
#     BLUE BANNERS, `feast` and `shelf_stock` clusters and decorated pillars -
#     the lord's own hall is where a share is rendered.
#   - HEIGHT 1.95 EXTENDS THE BOTTOM OF A FULL LADDER. All nineteen checked by
#     parsing CANON: 2.00 to 2.75 in steps of 0.05 is FULL (the Tanner took
#     2.75 to extend the top). 1.95 is honest rather than a repeat, and it is
#     the right number: THE BOX IS THE CREATURE and the man beside it is small
#     on purpose. At 0.80x a hero this is the smallest thing in the set.
#   - WEAR 0.05 EXTENDS THE BOTTOM TOO, and for a different reason than the
#     Tanner's 0.10, which is the only other value down there. The Tanner is
#     fresh because of a PROCESS - it re-covers itself hourly. The Reeve is
#     fresh because NOTHING IT OWNS IS EVER USED: a strongbox that is only
#     filled, never opened and never fought with has no scars on it. Mr. E's
#     rule 2 - condition is the receipt - and this receipt reads UNTOUCHED.
CANON.update({
    "reeve": ("The Reeve", 1.95, (0.74, 0.70, 0.58), (1.00, 0.84, 0.40),
              "keep",
              "IT TAKES THE HAUL - while it stands the floor pays its box and not you; "
              "break the box or walk out of here with nothing",
              0.05, "It is here for the lord's share."),
})
ORDER = ORDER + ["reeve"]


def _strongbox(P, bx, by, w=1.26, d=0.78, hbody=0.74, foot=0.22):
    """THE BOX. A WIDE LOW BANDED CHEST ON IRON FEET - the one shape in this
    set that is HORIZONTAL and solid.

    CHECKED AGAINST THE LOADER BEFORE A VERTEX WAS WRITTEN, because that is
    the one body in the set that also carries boxes. The Loader's load is a
    STEPPED VERTICAL TOWER of six crates hanging off a boom - height-dominant,
    and the fault list on it says the iron bands vanish at hero scale. This is
    the opposite shape on purpose: one chest, wider than it is tall, planted on
    the floor, with bands heavy enough to survive the pair framing. A tower of
    crates and a strongbox read as different objects at pane distance, which
    is the only test that matters.
    """
    z0 = foot
    cz = z0 + hbody / 2.0
    for sx in (-1, 1):
        for sy in (-1, 1):
            P.add(L.box(0.15, 0.15, foot), 'dark',
                  loc=(bx + sx * (w / 2.0 - 0.10), by + sy * (d / 2.0 - 0.10), foot / 2.0))
    P.add(L.box(w, d, hbody), 'body', loc=(bx, by, cz))
    # the lid overhangs, which is what makes it a chest and not a crate
    P.add(L.box(w + 0.08, d + 0.08, 0.12), 'body', loc=(bx, by, z0 + hbody + 0.06))
    # THREE VERTICAL BANDS AND TWO STRAPS - heavy, because the Loader's lesson
    # is that a band thinner than this is one pixel on the pair shot.
    for t in (-0.36, 0.0, 0.36):
        P.add(L.box(0.095, d + 0.03, hbody + 0.02), 'dark', loc=(bx + t * w, by, cz))
    for t in (0.26, 0.74):
        P.add(L.box(w + 0.03, d + 0.03, 0.075), 'dark', loc=(bx, by, z0 + hbody * t))
    # the lock plate on the near face, and it is BONE so it is the second
    # brightest thing after the throat - a locked box is the whole promise
    P.add(L.box(0.30, 0.07, 0.34), 'bone', loc=(bx, by - d / 2.0 - 0.02, z0 + hbody * 0.62))
    P.add(L.sphere(0.052, 0.040, 0.052, 9, 6), 'dark',
          loc=(bx, by - d / 2.0 - 0.055, z0 + hbody * 0.62))
    # hasp: a staple over the lid seam, so the lid reads as a lid
    P.add(L.box(0.13, 0.05, 0.26), 'dark', loc=(bx, by - d / 2.0 - 0.02, z0 + hbody + 0.02))
    return z0 + hbody + 0.12


def _hopper(P, hx, hy, z_top, z_bot, mouth=0.33, throat=0.115):
    """THE MOUTH THE TAKE GOES INTO - and it is SQUARE, of plank and iron.

    The one thing in the set that is nothing but an opening. Deliberately NOT
    round: the Cook has a pot and the Boiler has a vat, and a round funnel at
    this size would read as a third kettle. Four flat faces, a heavy square
    rim, and a lit throat inside it so the opening is not a black hole in the
    silhouette - an opening nobody can see is not an opening.
    """
    ring = []
    for i in range(9):
        t = TAU * i / 8.0
        # a square ring, not a circle: push the unit circle out to the square
        c, s = math.cos(t), math.sin(t)
        k = 1.0 / max(abs(c), abs(s), 1e-6)
        ring.append((c * k, s * k))
    rows = []
    for v, r in ((0.0, mouth), (0.55, mouth * 0.55 + throat * 0.45), (1.0, throat)):
        z = z_top + (z_bot - z_top) * v
        rows.append([Vector((hx + ux * r, hy + uy * r, z)) for ux, uy in ring])
    P.raw(surf(rows, 0.030), 'body')
    # the rim: four bars round the mouth
    for ax in (0, 1):
        for sgn in (-1, 1):
            if ax == 0:
                P.add(L.box(0.075, mouth * 2.1, 0.075), 'dark',
                      loc=(hx + sgn * mouth, hy, z_top))
            else:
                P.add(L.box(mouth * 2.1, 0.075, 0.075), 'dark',
                      loc=(hx, hy + sgn * mouth, z_top))
    # *** PASS 4, ONE PART. THE LIT THROAT, AND PASS 3's VERSION WAS A LUMP OF
    # *** DOUGH. *** A solid glow cone 0.49 m across filled the mouth edge to
    # edge, and with the view transform on it came back as a CREAM-COLOURED
    # MASS sitting in the funnel - the creature read as a hopper full of
    # batter, which is the Boiler's trade and not this one. Light reads as
    # light when it is a thin SOURCE against a dark interior, not when it is a
    # solid the size of the opening. So: a lit ring just inside the rim, and a
    # small plug far down the throat. What the camera gets is a dark square
    # hole with its edge alight and something burning at the bottom of it.
    lit = []
    for i in range(25):
        t = TAU * i / 24.0
        c2, s2 = math.cos(t), math.sin(t)
        k2 = 1.0 / max(abs(c2), abs(s2), 1e-6)
        lit.append(Vector((hx + c2 * k2 * mouth * 0.80, hy + s2 * k2 * mouth * 0.80,
                           z_top - 0.055)))
    P.raw(L.tube(lit, [0.028] * len(lit), 6), 'glow')
    P.add(L.cone(throat * 1.05, throat * 0.70, 0.07, 9), 'glow',
          loc=(hx, hy, z_bot + 0.16))
    # the neck down into the lid
    P.add(L.box(throat * 2.3, throat * 2.3, 0.14), 'dark', loc=(hx, hy, z_bot - 0.05))


def reeve():
    """IT TAKES THE HAUL. It does not hit hard and it does not call anybody: it
    stands over a strongbox chained to the floor and everything this floor
    would have paid you goes into it while it is alive. Break the box and you
    get the lot. Leave it standing and you walk out of a cleared floor with
    nothing to show for it. The fight is a SHOT CLOCK ON YOUR WAGES, which is
    a pressure no other body in this set applies.

    Silhouette intent - A WIDE LOW CHEST, A SQUARE MOUTH ABOVE IT, AND A SMALL
    MAN WITH HIS HAND OUT:
      - the BOX is the mass and it is HORIZONTAL - the first wide-not-tall
        silhouette in the set. It is planted, chained to a floor spike, and
        bigger than the man beside it;
      - the HOPPER tops the whole creature, so the silhouette ends in a SQUARE
        OPENING rather than a head. Nothing else here tops out in a rectangle;
      - the MAN is SHORT and reads as an officer, not a fighter: flat cap, long
        coat, one hand flat on the lid (ownership) and one held out palm-up
        (the taking). Both arms run ACROSS the picture, in the plane of the
        front camera - the Tanner's pass-3 finding, applied first time: a
        forearm pointing at the lens foreshortens to nothing;
      - the SPILL at the foot of the box and the lumps on the lip say which
        way the stuff is travelling, which is the only part of the mechanic a
        still picture can carry.

    Front is -Y, the same as the nineteen before it.
    """
    P = Parts("reeve")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX, BX, BY = -0.64, 0.48, 0.04
    _i_box = len(P.items)
    lid_z = _strongbox(P, BX, BY)
    _span("box", _i_box)

    _i_hop = len(P.items)
    # the hopper sits toward the man's end of the lid so it never covers the
    # lock plate, and its mouth is the top of the creature
    _hopper(P, BX - 0.26, BY + 0.02, 1.58, lid_z)
    # three lumps of the floor's own take on the lip and in the throat
    for dx, dy, dz, r in ((-0.20, -0.14, 1.60, 0.062), (0.06, -0.19, 1.57, 0.052),
                          (-0.04, 0.12, 1.55, 0.044)):
        P.add(L.sphere(r, r * 0.86, r * 0.74, 7, 5), 'bone',
              loc=(BX - 0.26 + dx, BY + dy, dz))
    _span("hopper", _i_hop)

    _i_chain = len(P.items)
    # ---- CHAINED TO THE FLOOR. This is the line that separates it from the
    # Tallyman in one glance: that one withdraws with what it took, this one
    # cannot leave the box and the box cannot leave the room.
    _ring(P, (BX + 0.70, BY + 0.10, 0.52), 0.11, axis='x', slot='dark', rad=0.030, n=12)
    ch = arc((BX + 0.78, BY + 0.10, 0.50), (BX + 0.96, BY + 0.42, 0.10), -0.13, 7)
    P.raw(L.tube(ch, [0.034] * len(ch), 7), 'dark')
    P.add(L.cone(0.070, 0.0, 0.34, 8), 'dark', loc=(BX + 0.96, BY + 0.42, 0.17),
          rot=(math.pi, 0.0, 0.0))
    _span("chain", _i_chain)

    _i_spill = len(P.items)
    # ---- THE SPILL. A short drift of lumps at the near foot of the box,
    # heavier toward the room, so the floor reads as paying INTO it.
    for i, (sx, sy, r) in enumerate(((-0.46, -0.62, 0.070), (-0.26, -0.70, 0.058),
                                     (-0.08, -0.60, 0.050), (0.14, -0.72, 0.044),
                                     (0.34, -0.62, 0.038))):
        P.add(L.sphere(r, r * 0.88, r * 0.66, 7, 5), 'bone',
              loc=(BX + sx, BY + sy, r * 0.60))
    _span("spill", _i_spill)

    _i_man = len(P.items)
    # *** PASS 2, AND IT IS ONE CHANGE: THE MAN STANDS FORWARD OF THE BOX. ***
    # Pass 1 put him beside the box in X only (man -0.64, box +0.48) and the
    # SIDE CAMERA LOOKS ALONG X - so at azimuth 90 the box stood in front of
    # him and HE WAS NOT IN THE PICTURE AT ALL. One of the three views the
    # register demands showed a chest and a spike and no creature. The blank
    # check cannot see this: the frame is full of opaque pixels, they are just
    # all box. Same fault class as the Tanner's pass 5 and as minibossfit's own
    # hero offset, which separates the pair in BOTH axes for exactly this
    # reason. He now stands a clear 0.37 m forward of the box's near face, so
    # front and back separate him in X and the side view separates him in Y.
    MY = -0.72
    # *** PASS 5, ONE THING: THE MAN'S MASS. *** On the hero pair shot at
    # 5.60 m of frame the box held up - bands, lock, feet all read - and the
    # MAN CAME BACK A STICK FIGURE beside a KayKit adventurer. Those bodies are
    # chibi and chunky (measured here: 2.45 m tall, 1.32 m across the
    # shoulders); a 0.086 m shin next to that is a wire. Nothing moves in this
    # pass and nothing is added - the same skeleton at honest thickness, so if
    # the read improves it is mass that did it and not a new part.
    _legs(P, MX, y=MY, hip=0.72, stance=0.185, r0=0.118, r1=0.094,
          boot=(0.27, 0.40, 0.12))
    limb(P, [(MX, MY + 0.08, 0.66), (MX, MY + 0.00, 0.92), (MX, MY - 0.05, 1.14)],
         0.215, 0.172, 'body')
    # THE LONG COAT. It is what makes a short upright biped read as an OFFICER
    # rather than a small hero: a clean unbroken skirt to the shin with no
    # belt-and-buckle fighting kit on it.
    coat = []
    for i in range(5):
        v = i / 4.0
        z = 1.06 - 0.62 * v
        hw = 0.235 + 0.105 * v
        yb = MY + 0.015 - 0.030 * v
        coat.append([Vector((MX + u * hw, yb - 0.085 * math.sin(math.pi * v) - 0.10,
                             z)) for u in (-1.0, -0.5, 0.0, 0.5, 1.0)])
    P.raw(surf(coat, 0.028), 'dark')
    for sh in ((MX - 0.235, MY - 0.04, 1.145), (MX + 0.235, MY - 0.04, 1.145)):
        P.add(L.sphere(0.098, 0.092, 0.084, 9, 6), 'dark', loc=sh)
    _span("man", _i_man)

    _i_head = len(P.items)
    HD = (MX, MY - 0.07, 1.315)
    limb(P, [(MX, MY - 0.04, 1.16), HD], 0.086, 0.072, 'body')
    P.add(L.sphere(0.172, 0.176, 0.166, 12, 8), 'bone', loc=HD)
    # THE FLAT CAP, and it sits ABOVE THE EQUATOR. Three bodies in this set
    # have come back reading as A VISORED FACE because a dark horizontal band
    # crossed the middle of the head; this one keeps the band on top of the
    # skull where a cap is, and nothing crosses the face.
    P.add(L.cone(0.232, 0.210, 0.056, 12), 'dark', loc=(HD[0], HD[1] + 0.008, HD[2] + 0.132))
    P.add(L.cone(0.150, 0.166, 0.082, 12), 'dark', loc=(HD[0], HD[1] + 0.008, HD[2] + 0.086))
    # eyes BREAK the bone surface (0.156 forward at this height) - the pass-11
    # finding: a light inside its own skull measures bright and renders black.
    eyes(P, (HD[0], HD[1], HD[2] - 0.014), 0.054, 0.031, -0.188)
    _span("head", _i_head)

    _i_arms = len(P.items)
    # ---- BOTH ARMS ACROSS THE PICTURE. The right hand lies FLAT ON THE NEAR
    # CORNER OF THE LID - the two masses touch, so the man and the box are
    # obviously one creature and not a man standing near furniture. The left is
    # the taking hand. Pass 2 moved the lid hand to the lid's near corner so
    # that the reach is mostly ACROSS the front camera even with the man now
    # standing forward of the box.
    SR = (MX + 0.235, MY - 0.05, 1.145)
    SL = (MX - 0.235, MY - 0.05, 1.145)
    HR = (BX - 0.62, BY - 0.34, lid_z + 0.07)
    HL = (MX - 0.52, MY - 0.17, 0.985)
    limb(P, [SR, (MX + 0.44, MY - 0.12, 1.08), HR], 0.096, 0.070, 'body')
    limb(P, [SL, (MX - 0.44, MY - 0.12, 1.055), HL], 0.096, 0.070, 'body')
    # *** PASS 3, ONE PART, AND IT IS THE PART THE WHOLE MECHANIC RESTS ON. ***
    # Pass 2's hands were flat plates whose BROAD FACE POINTED AT THE CEILING,
    # so the front camera - which looks along -Y - only ever saw their 0.05 m
    # edge. The taking hand came back as A BLADE held out at arm's length and
    # on the side view the two of them lined up into ONE LONG PLANK running
    # from his chest to the far side of the box: a creature built around an
    # open palm read as a man with a cleaver. The palm is now TIPPED UP TO
    # FACE THE ROOM (1.18 rad, not 0.34) and it has fingers, which is what
    # makes a small pale shape read as a hand rather than a tool. The lid hand
    # loses its plate entirely - a hand resting on a lid is a knuckled lump,
    # not a board - because its plate was half of that plank.
    P.add(L.sphere(0.102, 0.094, 0.062, 9, 6), 'bone', loc=HR)
    for fx in (-0.055, 0.0, 0.055):
        P.add(L.cone(0.021, 0.017, 0.085, 6), 'bone',
              loc=(HR[0] + fx, HR[1] - 0.085, HR[2] - 0.012),
              rot=(math.pi / 2.0, 0.0, 0.0))
    P.add(L.box(0.180, 0.060, 0.200), 'bone', loc=HL, rot=(-1.18, 0.0, 0.0))
    for fx in (-0.052, 0.0, 0.052):
        P.add(L.cone(0.020, 0.016, 0.080, 6), 'bone',
              loc=(HL[0] + fx, HL[1] - 0.030, HL[2] + 0.115), rot=(-0.30, 0.0, 0.0))
    # the thumb, off the inboard edge, square to the fingers
    P.add(L.cone(0.022, 0.018, 0.075, 6), 'bone',
          loc=(HL[0] + 0.085, HL[1] - 0.028, HL[2] + 0.030), rot=(0.0, 1.30, 0.0))
    # ---- THE SEAL on a short chain at the belt: the thing that makes a taking
    # lawful, and the only ornament on the whole body.
    sc = [(MX + 0.10, MY - 0.145, 1.00), (MX + 0.12, MY - 0.175, 0.92),
          (MX + 0.12, MY - 0.185, 0.86)]
    limb(P, sc, 0.016, 0.014, 'dark', ring=6)
    P.add(L.cone(0.070, 0.070, 0.028, 10), 'bone', loc=(MX + 0.12, MY - 0.188, 0.835),
          rot=(math.pi / 2.0, 0.0, 0.0))
    _span("arms", _i_arms)

    P.used_pack = False
    return P


BUILDERS.update({"reeve": reeve})


# ------------------- 21 THE TAPSTER: a tun stood on end, a rail of other
# people's flasks, and a man with his jack out.
#
# MEASURED, NOT RECALLED - the whole of this entry's justification was parsed
# out of CANON and grepped out of scripts/ this run, 17 Nov 2026 16:4x CT:
#   - TWENTY IDEAS EXIST AND NOT ONE OF THEM TOUCHES WHAT THE PARTY DRINKS.
#     Parsed, not remembered: summon, self-armour, drag a hero out, douse the
#     lamps, will-not-stay-down, bar the door, steal worn gear, heal its own
#     pack, raise the water, plant the ground, pre-set the room, scale with the
#     fire, ring from elsewhere, set the floor, come apart in two, arm the
#     room, weigh you down, cut the room in two, adaptive resistance, take the
#     haul. Every one is about the FIGHT, the ROOM or the TAKE. None is about
#     the SATCHEL.
#   - THE RESOURCE IS REAL AND IT IS WIRED THREE DEEP, which is the Reeve's
#     standard and the reason that one worked: roster.gd:1108 brew_count,
#     :1113 add_brew, :1125 brews_line; delve.gd:3273 `roster.add_brew(h, key,
#     -1)` is the actual swallow; and - the part that makes this a FIGHT change
#     rather than a tax - delve.gd:1287 `if frac < FLEE_AT and not
#     _has_heal_brew(h)` means a hero with nothing left to drink TURNS AND
#     RUNS. So a creature that empties the satchel does not out-damage you, it
#     BREAKS YOUR LINE. Nothing else in the twenty makes the party withdraw.
#   - IT IS NOT THE COOK AND IT IS NOT THE TALLYMAN, and those are the two it
#     had to be checked against. The COOK heals EVERYTHING ELSE IN THE ROOM -
#     its pot is a buff on the pack, and the counter is to spill the pot. The
#     Tapster never heals anything of its own: it DENIES YOUR OWN HEALING, and
#     the counter is to spend nothing until it is down. One adds hit points to
#     the enemy, the other subtracts the only thing you brought. The TALLYMAN
#     lifts WORN GEAR off a hero and WITHDRAWS with it - theft off a body, and
#     it leaves. The Tapster takes a CONSUMABLE at the moment of use and never
#     leaves its tun. A pickpocket, a toll and a landlord are three different
#     creatures.
#   - IT IS NOT THE SNUFFER EITHER, and that is the near miss worth writing
#     down. Bellmire's word "flask" means LAMP OIL in half the code
#     (delve.gd:28, :80, :159, roster.gd:564) and a creature that drank the OIL
#     would be the Snuffer's own mechanic - IT TAKES THE LIGHT - with a barrel
#     in front of it. So this one takes BREWS, which are a separate dictionary
#     with a separate reader, and the oil is left alone.
#   - THEME `firepit`, measured off dungeon_hd.gd's miniboss weights: the roll
#     is 35 on barracks and workshop, 10 on shrine and crypt, 15 on everything
#     unlisted - and `firepit` is unlisted with exactly ONE body behind it (the
#     Stoker), the same single-body case the Loader, the Tanner and the Reeve
#     were built for. `mess` is where a tapster would stand in life, and it was
#     REJECTED ON PURPOSE: the Cook is already in `mess`, and putting a
#     healing-denier in the one room that already holds a healing-giver is how
#     a new body gets read as a re-skin of an old one. The pit is where ale is
#     mulled; that is close enough to true and it keeps clear water.
#   - HEIGHT 2.80 EXTENDS THE TOP OF A FULL LADDER. All twenty parsed: 1.95 to
#     2.75 in steps of 0.05 is FULL with no gap (the Reeve took 1.95 to extend
#     the bottom, the Tanner 2.75 to extend the top). 2.80 is honest rather
#     than a repeat, and it is the right number because THE TUN IS THE
#     CREATURE and it stands on end - this is the first thing in the set whose
#     mass is a tall upright cylinder.
#   - WEAR 0.22, AND THE 0.05 LADDER IS NOW FULL SO THIS ONE SITS BETWEEN TWO
#     RUNGS ON PURPOSE. Parsed: 0.05 to 1.00 in 0.05 steps, all twenty
#     occupied. 0.22 falls between the Tallyman's 0.20 and the Boiler's 0.25
#     and the reason is the trade: a tapster SCOURS HIS TUN because sour wood
#     is a ruined cellar, but nothing ever replaces the hoops, so the staves
#     are pale and clean and the iron on them is old. Mr. E's rule 2 -
#     condition is the receipt - and this receipt reads KEPT, NOT NEW.
#   - IT USES WHAT IS ALREADY ON DISK (rule 3). assets/props/ is the CC0
#     Quaternius Fantasy Props MegaKit, 309 files, licence beside it at
#     assets/props/LICENSE_FantasyPropsMegaKit_CC0.txt - Barrel for the tun,
#     SmallBottle for the hung flasks and Mug for the jack. It was NOT in
#     docs/art/ASSET_SOURCES.md before this run; it is now. Falls back to
#     procedural geometry and SAYS SO in the report.
CANON.update({
    "tapster": ("The Tapster", 2.80, (0.72, 0.64, 0.46), (0.52, 1.00, 0.72),
                "firepit",
                "IT DRINKS WHAT YOU BROUGHT - every brew raised in this room goes into its "
                "tun and not into the hero; run it dry or your line breaks and walks out",
                0.22, "Something in here is drinking."),
})
ORDER = ORDER + ["tapster"]


def _prop_mesh(stem, max_faces=110, keep_slots=None):
    """Real pack geometry out of assets/props - the CC0 Fantasy Props MegaKit
    this repo already carries - normalised into the UNIT CUBE (0..1 on every
    axis, min corner at the origin) so the caller places it in metres.

    Same shape and the same honesty as _dungeon_mesh: returns None when the
    file or the importer refuses, the caller falls back to procedural geometry,
    and the report records which it got. A silent substitution is the same
    fault class as a lying gate.
    """
    ck = ("prop", stem, max_faces)
    if ck in _PACK_CACHE:
        return _PACK_CACHE[ck]
    out = None
    try:
        import bpy
        root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            os.pardir, os.pardir))
        path = os.path.join(root, "assets", "props", stem + ".gltf")
        if os.path.isfile(path):
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=path)
            new = [o for o in bpy.data.objects if o not in before]
            for ob in [o for o in new if o.type == 'MESH']:
                if len(ob.data.polygons) > max_faces:
                    m = ob.modifiers.new("dec", 'DECIMATE')
                    m.decimate_type = 'COLLAPSE'
                    m.ratio = max(0.10, float(max_faces) / len(ob.data.polygons))
            verts, faces = [], []
            dg = bpy.context.evaluated_depsgraph_get()
            for ob in [o for o in new if o.type == 'MESH']:
                obe = ob.evaluated_get(dg)
                me = obe.to_mesh()
                mw = obe.matrix_world
                off = len(verts)
                verts.extend([mw @ v.co for v in me.vertices])
                for p in me.polygons:
                    # *** keep_slots: TAKE ONE MATERIAL OUT OF A PACK MODEL. ***
                    # Added 17 Nov for the Tapster and for a measured reason,
                    # not a preference - see the cask note in tapster().
                    if keep_slots is not None and p.material_index not in keep_slots:
                        continue
                    faces.append(tuple(i + off for i in p.vertices))
                obe.to_mesh_clear()
            for ob in new:
                try:
                    bpy.data.objects.remove(ob, do_unlink=True)
                except Exception:
                    pass
            if verts and faces:
                # bounds come from the vertices the KEPT faces actually use -
                # dropping a slot and then normalising against every vertex in
                # the file would place the part by geometry that is not there.
                used = sorted({i for f in faces for i in f})
                remap = {i: k for k, i in enumerate(used)}
                verts = [verts[i] for i in used]
                faces = [tuple(remap[i] for i in f) for f in faces]
                mn = [min(v[i] for v in verts) for i in range(3)]
                mx = [max(v[i] for v in verts) for i in range(3)]
                ex = [max(1e-6, mx[i] - mn[i]) for i in range(3)]
                out = ([Vector(((v[0] - mn[0]) / ex[0], (v[1] - mn[1]) / ex[1],
                                (v[2] - mn[2]) / ex[2])) for v in verts], faces)
    except Exception:
        out = None
    _PACK_CACHE[ck] = out
    return out


def _unit_cyl(seg=14):
    """The fallback for a barrel: a plain cylinder carried into the unit cube."""
    v, f = L.cone(0.5, 0.5, 1.0, seg)
    return ([Vector((p[0] + 0.5, p[1] + 0.5, p[2] + 0.5)) for p in v], f)


def _place_unit(P, vf, slot, cx, cy, cz, sx, sy, sz, yaw=0.0, flip=False):
    """Place a unit-cube part centred on (cx, cy) with its BASE at cz, sized
    sx/sy/sz metres, spun yaw about its own centre. `flip` turns it upside
    down, which is how a flask hangs mouth-downward off a rail."""
    v, f = vf
    ca, sa = math.cos(yaw), math.sin(yaw)
    out = []
    for p in v:
        x = (p.x - 0.5) * sx
        y = (p.y - 0.5) * sy
        z = (1.0 - p.z) if flip else p.z
        out.append(Vector((cx + x * ca - y * sa, cy + x * sa + y * ca, cz + z * sz)))
    P.raw((out, f), slot)


def tapster():
    """IT DRINKS WHAT YOU BROUGHT. It does not hit hard, it does not call
    anybody and it does not take a thing off your back: it stands over a tun
    with its tap open, and every brew a hero raises in this room goes down that
    tun instead of down the hero. The counter is to spend NOTHING and kill it
    dry. Leave it standing and the satchel empties, and delve.gd's own flee
    rule does the rest - a hero under the flee line with no heal brew turns and
    walks out of the floor. THE FIGHT IS A SIEGE OF YOUR OWN SUPPLY, which is a
    pressure no other body in this set applies: this one does not kill the
    party, it BREAKS THE LINE.

    Silhouette intent - A TALL UPRIGHT TUN, A RAIL OF HANGING FLASKS ACROSS
    THE TOP, AND A MAN WITH HIS JACK HELD OUT:
      - the TUN is the mass and it is VERTICAL AND ROUND - the first tall
        upright cylinder in the set. Checked against the two bodies that also
        carry a vessel: the COOK's is a fat black ball slung LOW on chains at
        hip height and the BOILER's is a small SHALLOW dish held HIGH on a
        trunnion with a pour running sideways off it. A hooped cask stood on
        its end, as tall as the man and twice his width, is neither;
      - the RAIL tops the whole creature, so the silhouette ends in A ROW OF
        HANGING VESSELS rather than a head. The Reeve ends in a square mouth,
        the Drillmaster in a disc, the Stoker in a flue - nothing in the set
        ends in a row of pendants. These are OTHER PEOPLE'S FLASKS, hung
        mouth-down and empty, and they are the only part of the mechanic a
        still picture can carry: the thing has done this before;
      - the MAN stands a clear 0.36 m FORWARD of the tun's near face. This is
        the Reeve's pass-2 fault applied FIRST TIME and not discovered again:
        side-on, azimuth 90 looks along X, so X separation does nothing and the
        bigger mass eats the smaller one whole. Front and back separate him in
        X, the side view separates him in Y;
      - BOTH ARMS RUN ACROSS THE PICTURE - the Tanner's pass-3 and the Reeve's
        pass-3 finding, applied first time. His right hand is ON THE TAP, so
        the two masses touch and the man and the tun are obviously one creature
        and not a man standing near furniture. His left holds the jack out,
        palm tipped up to the room: GIVE IT HERE;
      - the DRIP under the tap, the puddle at its foot and the one flask on the
        rail still half full are the only lit things on the body, and they are
        thin SOURCES against dark - the Reeve's pass-4 lesson, where a solid
        glow the size of the opening came back as a lump of dough.

    Front is -Y, the same as the twenty before it.
    """
    P = Parts("tapster")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX, MY = -0.66, -0.80
    TX, TY = 0.52, 0.06
    TUN_R, TUN_H = 0.50, 1.46

    # *** PASS 2 AND PASS 3, AND PASS 2 WAS ONLY HALF RIGHT - RECORDED THAT WAY
    # *** ON PURPOSE. ***
    # PASS 2 asked what these three models actually cost, read off the .gltf
    # accessors rather than guessed: Barrel 824 tris in two primitives
    # (392 + 432), SmallBottle 130, Mug 268. A 110-face cap was putting a 0.26
    # collapse ratio through all three. Loading them whole FIXED THE BOTTLE AND
    # THE MUG - pass 1's flasks were grey slabs and its jack had no handle, and
    # both are the real objects now.
    # IT DID NOT FIX THE CASK, AND THE PICTURE SAID SO WHILE THE REPORT STAYED
    # GREEN. The staves still came back as TORN SHARDS WITH HOLES BETWEEN THEM.
    # PASS 3 PROBED THE FILE INSTEAD OF GUESSING TWICE and got the CAUSE WRONG,
    # corrected here 17 Nov 19:00 CT - see docs/art/PROPS_SLOT_AUDIT.md. It read
    # the two slots' overall MAX radii (0.343 wood, 0.346 metal), called the
    # 3 mm between two numbers taken at different heights "one millimetre of
    # clearance", and blamed Z-FIGHTING. Measured properly the slots do not
    # touch (no triangle intersection, 2.245 mm nearest surface distance, and
    # perpendicular where they are closest), and the whole 824-face Barrel
    # renders CLEAN with both slots. THE SHARDS WERE THE 110-FACE CAP - a
    # decimate ratio of 0.1335 on a model made of 240 loose parts. Dropping
    # slot 1 worked only because 392 faces then fell under the 440 cap this
    # same change raised it to. The cap was the cause and the cap was the cure.
    # So slot 1 is dropped and the cask is taken alone. This body draws its own
    # four hoops below at 0.044 m - heavier than the pack's and standing clear
    # of the staves - so nothing is lost by it.
    # NEITHER CHECK IN THIS LANE CAN SEE EITHER FAULT: a shredded barrel is
    # still opaque inside its border, and so is a slab that should be a bottle.
    # Both were found by LOOKING, which is the only instrument that had them.
    barrel = _prop_mesh("Barrel", max_faces=440, keep_slots={0})
    bottle = _prop_mesh("SmallBottle", max_faces=140)
    mug = _prop_mesh("Mug", max_faces=280)
    P.used_pack = bool(barrel)
    P.pack_parts = {"Barrel": bool(barrel), "SmallBottle": bool(bottle), "Mug": bool(mug)}

    # ---- THE TUN, STOOD ON END.
    _i_tun = len(P.items)
    _place_unit(P, barrel or _unit_cyl(), 'body', TX, TY, 0.0,
                TUN_R * 2.0, TUN_R * 2.0, TUN_H)
    # FOUR HEAVY HOOPS. The Loader's lesson, twice confirmed: a band thinner
    # than this is one pixel on the pair shot, and a decimated pack barrel has
    # lost its own. These are what make a cylinder read as a CASK.
    # PASS 2 PAYS FOR THE WHOLE CASK HERE AND NOWHERE ELSE: four 20-gon hoops
    # at ring=7 cost ~1120 faces, more than the cask itself. At 14 and 5 they
    # cost ~560 and NOTHING ABOUT THEM CHANGES ON SCREEN - same radius, same
    # 0.044 thickness, a coarser circle on a body that is flat-shaded anyway.
    # Measured separately from the cask fix in the same pass, as the standing
    # rule requires when two changes share one render.
    for t in (0.10, 0.36, 0.64, 0.92):
        _ring(P, (TX, TY, TUN_H * t), TUN_R * 1.015, axis='z', slot='dark',
              rad=0.044, n=14)
    # the head of the cask, and a bung off-centre in it
    P.add(L.cone(TUN_R * 0.96, TUN_R * 0.92, 0.06, 18), 'body', loc=(TX, TY, TUN_H + 0.03))
    P.add(L.cone(0.082, 0.072, 0.075, 10), 'dark', loc=(TX - 0.17, TY + 0.13, TUN_H + 0.09))
    _span("tun", _i_tun)

    # ---- THE TAP, AND PASS 4 IS ONE CHANGE: IT COMES OUT OF THE FLANK, NOT
    # ---- OUT OF THE FACE.
    # Passes 1-3 put the spout on the cask's NEAR face pointing -Y, straight at
    # the front camera, and it FORESHORTENED TO NOTHING: a 0.26 m spout was
    # four pixels of end-on cone lost against the staves behind it, and the
    # right hand read as a palm laid flat on a barrel. That is the Tanner's
    # pass-3 finding and the Reeve's pass-3 finding - a part aimed at the lens
    # is not in the picture - quoted in this very docstring and then violated
    # in the one place it mattered most. THE TAP IS THE ONLY ORGAN THE MECHANIC
    # HAS. A viewer who cannot see an open tap is looking at a man standing
    # near a barrel.
    # It now runs out of the -X flank, ACROSS the front camera and toward the
    # man, at full length: spout, handle standing up off it, a thin stream and
    # a puddle on the floor under it. The side camera loses it behind the cask
    # and that is named in the fault list rather than hidden - a tap can only
    # face one way, and it faces the way the front view reads.
    _i_tap = len(P.items)
    TAPZ = 0.52
    TAPX = TX - TUN_R + 0.02
    # the spout, horizontal, pointing -X out of the staves
    P.add(L.cone(0.060, 0.044, 0.30, 10), 'dark', loc=(TAPX - 0.15, TY, TAPZ),
          rot=(0.0, math.pi / 2.0, 0.0))
    # the boss where it enters the cask, so it reads as DRIVEN IN, not stuck on
    P.add(L.cone(0.092, 0.078, 0.07, 10), 'dark', loc=(TAPX + 0.02, TY, TAPZ),
          rot=(0.0, math.pi / 2.0, 0.0))
    # THE HANDLE, standing straight up off the spout - the one part that says
    # OPEN. It is vertical, so no camera can lose it to foreshortening.
    P.add(L.box(0.048, 0.048, 0.21), 'dark', loc=(TAPX - 0.19, TY, TAPZ + 0.13))
    P.add(L.box(0.15, 0.050, 0.050), 'dark', loc=(TAPX - 0.19, TY, TAPZ + 0.235))
    # THE RUN. A thin source against dark, never a solid - the Reeve's pass-4
    # lesson, where a glow the width of the opening came back as a lump of
    # dough. Four beads down and a puddle at the foot.
    for k, (dz, r) in enumerate(((-0.06, 0.028), (-0.18, 0.025),
                                 (-0.30, 0.022), (-0.41, 0.019))):
        P.add(L.sphere(r, r, r * 1.55, 7, 5), 'glow',
              loc=(TAPX - 0.30, TY, TAPZ + dz))
    P.add(L.cone(0.24, 0.19, 0.018, 12), 'glow', loc=(TAPX - 0.30, TY, 0.013))
    _span("tap", _i_tap)

    # ---- THE RAIL AND THE HUNG FLASKS. The top of the creature.
    _i_rail = len(P.items)
    RAILZ = TUN_H + 0.74
    for s in (-1, 1):
        limb(P, [(TX + s * (TUN_R - 0.07), TY + 0.16, TUN_H - 0.04),
                 (TX + s * (TUN_R + 0.02), TY + 0.10, RAILZ)], 0.062, 0.048, 'dark')
    rail = [(TX - TUN_R - 0.10, TY + 0.10, RAILZ), (TX + TUN_R + 0.10, TY + 0.10, RAILZ)]
    limb(P, rail, 0.040, 0.040, 'dark', ring=7)
    # five flasks, mouth-down, empty - EXCEPT ONE, which is still going down.
    for i, (fx, hang, sz, lit) in enumerate((
            (-0.46, 0.17, 0.30, False), (-0.21, 0.23, 0.26, False),
            (0.02, 0.15, 0.33, True), (0.26, 0.21, 0.27, False),
            (0.49, 0.16, 0.30, False))):
        hx = TX + fx
        # the cord it hangs by, so it reads HUNG and not floating
        limb(P, [(hx, TY + 0.10, RAILZ - 0.02), (hx, TY + 0.07, RAILZ - hang)],
             0.013, 0.011, 'dark', ring=5)
        _place_unit(P, bottle or _unit_cyl(10), 'bone', hx, TY + 0.07,
                    RAILZ - hang - sz, 0.145, 0.145, sz, flip=True)
        if lit:
            P.add(L.sphere(0.052, 0.052, 0.036, 9, 6), 'glow',
                  loc=(hx, TY + 0.07, RAILZ - hang - sz * 0.30))
    _span("rail", _i_rail)

    # ---- THE MAN. Short, aproned, and reading as a LANDLORD, not a fighter.
    _i_man = len(P.items)
    # mass at honest thickness from the start: the Reeve's pass-5 lesson is
    # that a KayKit adventurer is chibi and chunky (2.45 m, 1.32 m across) and
    # a thin shin beside it is a wire, not a leg.
    _legs(P, MX, y=MY, hip=0.74, stance=0.19, r0=0.120, r1=0.096,
          boot=(0.28, 0.41, 0.12))
    limb(P, [(MX, MY + 0.08, 0.68), (MX, MY + 0.00, 0.95), (MX, MY - 0.05, 1.18)],
         0.225, 0.178, 'body')
    # *** PASS 5, ONE THING: THE APRON STOPS BEING A SANDWICH BOARD. ***
    # Passes 1-4 hung a flat 0.47 m plate from chest to shin, square at the top
    # and 0.03 m proud of the body. At pane distance the man read as A FIGURE
    # CARRYING A SIGN: the plate was wider than his own torso, so no chest, no
    # shoulder line and no neck survived it, and both arms appeared to spring
    # from the board's corners rather than from a body. It is now NARROWER THAN
    # HIM (0.33 against a 0.45 torso), so the body shows down both sides, it is
    # BIBBED - cut back at the top to a strap width, which is what an apron
    # does and a board does not - and it is BOWED round him rather than flat,
    # using the same curved sweep the twelve creatures use. Nothing else moves
    # in this pass.
    apron = []
    for i in range(5):
        v = i / 4.0
        z = 1.14 - 0.74 * v
        # bib at the top, full skirt below: half-width grows fast off the strap
        hw = 0.075 + 0.090 * min(1.0, v / 0.34) + 0.075 * v
        yb = MY - 0.205 - 0.030 * v
        row = []
        for u in (-1.0, -0.5, 0.0, 0.5, 1.0):
            # bowed: the middle stands proud, the edges wrap back onto the body
            row.append(Vector((MX + u * hw, yb + 0.055 * (u * u), z)))
        apron.append(row)
    P.raw(surf(apron, 0.026), 'bone')
    # the neck strap, over the shoulders, so the bib is obviously tied on
    for s_ in (-1, 1):
        limb(P, [(MX + s_ * 0.075, MY - 0.205, 1.14),
                 (MX + s_ * 0.150, MY - 0.090, 1.235),
                 (MX + s_ * 0.150, MY + 0.060, 1.175)], 0.017, 0.015, 'dark', ring=5)
    # the apron string, across the back of the coat
    limb(P, [(MX - 0.24, MY + 0.10, 1.03), (MX + 0.24, MY + 0.10, 1.03)],
         0.018, 0.018, 'dark', ring=5)
    for sh in ((MX - 0.240, MY - 0.04, 1.185), (MX + 0.240, MY - 0.04, 1.185)):
        P.add(L.sphere(0.100, 0.094, 0.086, 9, 6), 'dark', loc=sh)
    _span("man", _i_man)

    _i_head = len(P.items)
    HD = (MX, MY - 0.07, 1.360)
    limb(P, [(MX, MY - 0.04, 1.20), HD], 0.088, 0.074, 'body')
    P.add(L.sphere(0.174, 0.178, 0.168, 12, 8), 'bone', loc=HD)
    # THE SCALP BAND SITS ABOVE THE EQUATOR. Three bodies in this set came
    # back reading as A VISORED FACE because a dark horizontal band crossed
    # the middle of the head. Nothing crosses the face here.
    P.add(L.cone(0.168, 0.182, 0.070, 12), 'dark',
          loc=(HD[0], HD[1] + 0.008, HD[2] + 0.126))
    # eyes BREAK the bone surface (0.158 forward at this radius) - the pass-11
    # finding: a light inside its own skull measures bright and renders black.
    eyes(P, (HD[0], HD[1], HD[2] - 0.012), 0.055, 0.031, -0.190)
    _span("head", _i_head)

    # ---- BOTH ARMS ACROSS THE PICTURE.
    _i_arms = len(P.items)
    SR = (MX + 0.240, MY - 0.05, 1.185)
    SL = (MX - 0.240, MY - 0.05, 1.185)
    # RIGHT HAND ON THE TAP HANDLE. The two masses touch, so the man and the
    # tun are obviously one creature - and pass 4 moves the grip off the cask's
    # belly and onto the thing the mechanic runs through.
    HR = (TAPX - 0.19, TY - 0.06, TAPZ + 0.21)
    limb(P, [SR, (MX + 0.46, MY + 0.16, 0.96), HR], 0.098, 0.072, 'body')
    P.add(L.sphere(0.104, 0.096, 0.064, 9, 6), 'bone', loc=HR)
    for fx in (-0.056, 0.0, 0.056):
        P.add(L.cone(0.021, 0.017, 0.082, 6), 'bone',
              loc=(HR[0] + fx, HR[1] - 0.080, HR[2] - 0.014),
              rot=(math.pi / 2.0, 0.0, 0.0))
    # LEFT HAND HOLDS THE JACK OUT, palm tipped up to the room. The Reeve's
    # pass-3 lesson: a flat hand whose broad face points at the ceiling is a
    # BLADE to a camera looking along -Y, so the palm is tipped 1.18 rad and it
    # has fingers, which is what makes a small pale shape read as a hand.
    HL = (MX - 0.54, MY - 0.19, 1.000)
    limb(P, [SL, (MX - 0.46, MY - 0.13, 1.070), HL], 0.098, 0.072, 'body')
    P.add(L.box(0.176, 0.058, 0.196), 'bone', loc=HL, rot=(-1.18, 0.0, 0.0))
    for fx in (-0.052, 0.0, 0.052):
        P.add(L.cone(0.020, 0.016, 0.078, 6), 'bone',
              loc=(HL[0] + fx, HL[1] - 0.028, HL[2] + 0.112), rot=(-0.30, 0.0, 0.0))
    P.add(L.cone(0.022, 0.018, 0.074, 6), 'bone',
          loc=(HL[0] + 0.082, HL[1] - 0.026, HL[2] + 0.028), rot=(0.0, 1.30, 0.0))
    # THE JACK in that hand - a real pack mug, and a lit measure in it.
    _place_unit(P, mug or _unit_cyl(10), 'bone', HL[0] - 0.02, HL[1] - 0.09,
                HL[2] + 0.12, 0.185, 0.185, 0.215)
    P.add(L.cone(0.070, 0.066, 0.020, 10), 'glow',
          loc=(HL[0] - 0.02, HL[1] - 0.09, HL[2] + 0.300))
    _span("arms", _i_arms)

    # ---- THE SLATE on a nail at the tun's flank: what you owe. One ornament,
    # and it is the lawful-looking part, the way the Reeve's seal was.
    _i_slate = len(P.items)
    P.add(L.box(0.26, 0.030, 0.33), 'dark', loc=(TX + TUN_R - 0.06, TY - 0.44, 0.96),
          rot=(0.0, 0.0, -0.46))
    for i in range(4):
        P.add(L.box(0.017, 0.012, 0.115), 'bone',
              loc=(TX + TUN_R - 0.12 + i * 0.038, TY - 0.458, 0.97),
              rot=(0.0, 0.10 * (i - 1.5), -0.46))
    _span("slate", _i_slate)

    return P


BUILDERS.update({"tapster": tapster})


# ---------------------------------------------- 22 THE PRESSMAN: a yoke of irons
#
# PRISON, and the theme argument is measured off dungeon_hd.gd:737-743 the same
# way the Tanner's and the Loader's were: the miniboss roll is 35 on barracks
# and workshop, 10 on shrine and crypt, and 15 on prison and every unlisted
# theme. PRISON HAS EXACTLY ONE BODY BEHIND IT - the Gaoler - so every miniboss
# a prison floor has ever shown is the same creature.
CANON.update({
    "pressman": ("The Pressman", 2.85, (0.62, 0.60, 0.56), (0.96, 0.74, 0.30),
                 "prison",
                 "IT PRESSES YOUR FALLEN - a hero that goes down in this room is "
                 "collared and stood back up on ITS side; get them up, or break the "
                 "yoke, before the collar shuts",
                 0.88, "Irons just came off the yoke."),
})
ORDER = ORDER + ["pressman"]


def _open_ring(P, c, r, slot='dark', rad=0.034, n=16, gap=0.30, axis='y',
               phase=0.0, tilt=0.0, yaw=0.0):
    """A collar that is NOT closed: an arc of iron with a visible gap, which is
    the whole of what this creature is about. `gap` is the fraction of the
    circle left out, and the opening is turned by `phase`.

    It is drawn as an arc and not as a torus with a hole punched in it because
    the gap has to survive at stream distance: an open collar silhouettes as a
    C and a closed one as an O, and that is the difference between 'empty' and
    'occupied' at a glance.
    """
    pts = []
    sweep = TAU * (1.0 - gap)
    cy, sy = math.cos(yaw), math.sin(yaw)
    for i in range(n + 1):
        t = phase + sweep * i / n
        ct, st = math.cos(t), math.sin(t)
        if axis == 'y':
            # the ring lies in a VERTICAL plane turned by `yaw` about Z. At
            # yaw 0 it faces the front camera and is EDGE-ON from the side -
            # which is pass 1's fault, found by looking at side.png: four
            # collars became four sticks. Turned 40-55 degrees a ring is an
            # ellipse from both cameras and reads as a ring from both.
            pts.append(Vector((c[0] + r * ct * cy, c[1] + r * ct * sy + r * st * math.sin(tilt),
                               c[2] + r * st * math.cos(tilt))))
        else:
            pts.append(Vector((c[0] + r * ct * math.cos(tilt), c[1] + r * st,
                               c[2] + r * ct * math.sin(tilt))))
    P.raw(L.tube(pts, [rad] * len(pts), 5), slot)


def pressman():
    """IT PRESSES YOUR FALLEN. It does not kill the party and it does not call
    anyone in from outside: it waits for one of you to go down, puts a collar on
    them where they lie, and stands them up facing the other way. Every hero it
    takes is a hero the rest have to fight, so the fight gets harder at exactly
    the rate you are losing it. The counter is a decision and not a damage race
    - get the downed hero up before the collar shuts, or break the yoke the
    irons hang on and it has nothing left to take.

    WHY IT IS NOT ONE OF THE TWENTY-ONE, checked against CANON by parsing the
    file rather than by remembering it. The set summons, armours itself, drags,
    darkens, will not stay down, bars the door, steals gear, heals the pack,
    raises water, plants the ground, pre-sets the room, scales with the fire,
    rings from elsewhere, sets the floor, comes apart in two, arms the room,
    weighs you down, cuts the room in two, refuses the same blow twice, takes
    the haul and drinks what you brought. NOT ONE OF THEM CHANGES WHO IS ON
    WHICH SIDE. The three near neighbours, named rather than waved at:
      - the DRILLMASTER summons, but what arrives is ITS garrison. Reinforcement
        from outside the fight. This one's reinforcement is YOUR OWN LINE, which
        means killing it is the only way to get them back;
      - the GAOLER drags a STANDING hero across the floor to itself - a position
        change, and the hero is still yours. This one takes a hero who has
        already fallen, and the loss is not position, it is the roster;
      - the SEXTON will not stay DOWN itself. That is its own body. This is
        yours.

    SILHOUETTE INTENT - A MAN UNDER A LONG BAR, AND FOUR EMPTY COLLARS HANGING
    OFF IT:
      - the mass is ABOVE THE HEAD, so the outline is a T with holes in the
        crossbar. Nothing in the set ends that way: the Drillmaster's disc is
        off to one side and solid, the Tapster ends in a row of SOLID pendant
        flasks, the Hurdleman's panel is a filled rectangle, the Quartermaster's
        sheaf bristles. Four open rings read as NEGATIVE SPACE, and negative
        space is the one thing a still picture can say about a mechanic that has
        not happened yet: those are empty, and they are your size;
      - THE COLLARS ARE STAGGERED IN Y, 0.14 m apart, and that is the Reeve's
        pass-2 fault applied first time rather than found again. Side-on the
        camera looks along X, so four rings all hung at the same depth collapse
        into ONE ring and the crossbar becomes a stick. Staggered, the side view
        still counts four;
      - ONE COLLAR IS SHUT AND IT IS ON THE FLOOR, with its chain running back
        to the man's heel. It is the only closed O on the body, it is the only
        lit thing on the body, and it gives the side and back views a long
        horizontal at ground level where everything else is up at head height;
      - BOTH ARMS RUN ACROSS THE PICTURE IN X - the Tanner's pass-3 and the
        Reeve's pass-3 finding. His near hand holds an open collar out to the
        room at chest height (GIVE ME YOUR WRIST); his far hand is up on the
        yoke bar, which ties the man and the bar into one creature instead of a
        man standing under furniture;
      - WEAR 0.88 is the second-highest in the set after the Sluicekeeper's 0.95
        and the Snuffer's 0.90, and it is the irons that justify it, not the
        coat: this is the oldest fixed kit on the floor and it has never once
        been out of service. Mr. E's rule 2 - condition is the receipt, and this
        receipt reads USED, CONSTANTLY, BY SOMEBODY ELSE.

    Front is -Y, the same as the twenty-one before it. Static: no anims entry.
    """
    P = Parts("pressman")
    P.spans = {}
    P.used_pack = False

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = -0.08                       # the man, a little left of centre
    HIP, SH, HEAD = 0.94, 1.52, 1.80
    BAR_Z, BAR_HALF = 2.12, 0.86     # the yoke: above the head, 1.72 m across

    # ---- THE MAN. Planted, stooped a little under the weight of the bar.
    _i_man = len(P.items)
    _legs(P, MX, y=0.0, hip=HIP, stance=0.20)
    limb(P, [(MX, 0.10, HIP - 0.06), (MX - 0.02, 0.02, 1.22), (MX - 0.05, -0.06, SH)],
         0.235, 0.255)
    P.add(L.box(0.56, 0.30, 0.095), 'dark', loc=(MX - 0.01, -0.02, 1.08))     # belt
    # the coat: a short flare off the belt so he is a working man and not armour
    # PASS 2, FAULT 1: pass 1's coat was a 0.40 m cone 0.46 m long and it read
    # as A WOODEN TUB ROUND HIS HIPS from both cameras - wider than his
    # shoulders and stopping above the knee. Narrower than the shoulders and
    # down past the knee is a coat.
    # PASS 3: narrowing it did not stop it reading as a VESSEL - a straight
    # 0.74 m tube with a flat bottom hung between two legs is a churn, and the
    # side view showed the near SHIN COMING THROUGH ITS FRONT PANEL at the
    # knee, which is a clip and not a style. A short skirted coat to mid-thigh
    # clears the knee by construction and stops the tub read at the same time:
    # the legs are then OUTSIDE the outline where they belong.
    # PASS 5, THIRD GO AT THE SAME ELEMENT AND THE FIRST ONE THAT ASKS WHY
    # RATHER THAN HOW BIG. Passes 1-3 made the coat narrower and then shorter
    # and it still read as a TUB AT HIS HIPS on the pair shot, because the
    # fault was never the size: a cone that TAPERS INWARD with a flat bottom is
    # the shape of a vessel, and cloth does the opposite - it hangs and FLARES.
    # Flared, falling to mid-shin and sitting under a belt, it is a coat.
    P.add(aim(L.cone(0.270, 0.355, 0.62, 12), (MX - 0.01, -0.02, 1.06), (0.0, 0.0, -1.0)),
          'body')
    for s in (-1, 1):
        P.add(L.sphere(0.165, 0.155, 0.135, 12, 8), 'body', loc=(MX - 0.05 + s * 0.28, -0.06, SH))
    # head, low flat cap, face kept clear of the bar above it
    P.add(L.sphere(0.152, 0.168, 0.172, 14, 9), 'bone', loc=(MX - 0.06, -0.19, HEAD))
    P.add(aim(L.cone(0.225, 0.215, 0.055, 14), (MX - 0.06, -0.19, HEAD + 0.14), (0.0, 0.0, 1.0)),
          'dark')
    eyes(P, (MX - 0.06, -0.09, HEAD - 0.01), 0.056, 0.028, -0.26)
    _span("man", _i_man)

    # ---- THE YOKE. A harness over the shoulders, two short uprights, one bar.
    _i_yoke = len(P.items)
    P.add(L.box(0.86, 0.19, 0.085), 'dark', loc=(MX - 0.05, 0.03, SH + 0.13))   # shoulder pad
    for s in (-1, 1):
        # PASS 2, FAULT 2: at s*0.26 and y -0.04 these two posts stood either
        # side of the face and one crossed the chin - the head read as a man
        # looking out through bars, which is the WRONG creature's idea.
        # Outboard to 0.40 and back to y +0.17, behind the head entirely.
        limb(P, [(MX - 0.05 + s * 0.40, 0.14, SH + 0.10),
                 (MX - 0.04 + s * 0.38, 0.17, BAR_Z - 0.06)], 0.062, 0.050, 'dark')
    P.add(L.box(BAR_HALF * 2.0, 0.115, 0.115), 'dark', loc=(MX, 0.06, BAR_Z))
    for s in (-1, 1):                                        # squared ends, as forged
        P.add(L.box(0.085, 0.165, 0.165), 'dark', loc=(MX + s * BAR_HALF, 0.06, BAR_Z))
    _span("yoke", _i_yoke)

    # ---- FOUR EMPTY COLLARS. The mechanic, and the only part of it a still
    # picture can carry. Staggered in Y so the SIDE view still counts four.
    _i_coll = len(P.items)
    # (dx, dy, drop, yaw). PASS 2: every ring is turned 38-58 degrees off the
    # front plane. dy also widened to +/-0.20 - in pass 1 the two left collars
    # sat behind the raised arm and the head and could not be counted at all.
    HANG = ((-0.76, 0.20, 0.30, 0.95), (-0.34, 0.22, 0.40, -0.72),
            (0.26, 0.18, 0.28, 0.68), (0.70, -0.14, 0.38, -1.00))
    for dx, dy, drop, yw in HANG:
        x, y = MX + dx, 0.06 + dy
        # the link it hangs by - short, so the collar stays up near the bar
        limb(P, [(x, y, BAR_Z - 0.06), (x, y, BAR_Z - 0.06 - drop + 0.21)],
             0.026, 0.024, 'dark')
        _open_ring(P, (x, y, BAR_Z - 0.06 - drop), 0.205, 'dark', rad=0.036,
                   n=16, gap=0.28, axis='y', phase=1.35, yaw=yw)
    _span("collars", _i_coll)

    # ---- THE ONE THAT IS SHUT, on the floor, with its chain run back to him.
    # Closed O against four open Cs, lit from inside, and the only thing on this
    # body below knee height.
    _i_taken = len(P.items)
    # PASS 2, FAULT 5: laid FLAT with a filled lit disc inside it, this read as
    # A FRYING PAN - the chain was its handle and the glow was its contents. On
    # edge against his heel it is a collar, and the light is now a thin ring
    # inside the iron rather than a solid plate of dough (the Reeve's pass-4
    # lesson, which I had taken and then undone).
    # PASS 4, AND THE SAME FAULT SURVIVED TWO FIXES IN TWO DIFFERENT COSTUMES.
    # Flat with a lit plate in it, it was a frying pan. Stood on edge at the
    # end of a chain it became A WHEEL ON A STICK - from the side, a scooter.
    # Both times the fault was the same one: A RING AT THE END OF A LINE IS A
    # TOOL, whatever plane it is in. So the iron goes DOWN at the heel, laid
    # over on the floor and tucked half behind the boot, and the chain runs to
    # it along the ground instead of out from the body. It is now the only
    # thing in the picture lying down, which is what it is meant to say.
    TK = (MX + 0.50, 0.30, 0.055)
    _open_ring(P, TK, 0.175, 'dark', rad=0.038, n=18, gap=0.0, axis='z',
               phase=0.0, tilt=0.26)
    _open_ring(P, TK, 0.138, 'glow', rad=0.012, n=18, gap=0.0, axis='z',
               phase=0.0, tilt=0.26)
    # PASS 3: one straight taut diagonal into a ring is a RACKET, from both
    # cameras. Chain has no tension in it when the other end is on the floor -
    # so it falls to the ground first and lies along it, which also gives the
    # side and back views the long low horizontal they were short of.
    link = [Vector((MX + 0.30, 0.10, 0.96)), Vector((MX + 0.46, 0.16, 0.60)),
            Vector((MX + 0.56, 0.22, 0.26)), Vector((MX + 0.60, 0.26, 0.08)),
            Vector((TK[0] + 0.14, TK[1] + 0.02, TK[2] + 0.01))]
    P.raw(L.tube(link, [0.030] * 5, 5), 'dark')
    _span("taken", _i_taken)

    # ---- THE ARMS, BOTH ACROSS THE PICTURE IN X.
    _i_arms = len(P.items)
    # PASS 2, FAULT 3, AND IT IS THE ONE THAT WOULD HAVE EMBARRASSED THE SET.
    # Pass 1 ran this arm STRAIGHT UP to the bar, and with a long loaded bar
    # overhead and both ends squared off the whole creature read as A MAN
    # PRESSING A BARBELL. For a thing called the Pressman that is not a near
    # miss, it is the picture naming itself wrong. The arm comes down and takes
    # the CHAIN of the one it has already collared, which says the same thing
    # about man-and-yoke being one creature and says the mechanic as well.
    limb(P, [(MX - 0.30, -0.08, SH - 0.04), (MX - 0.42, -0.14, 1.26),
             (MX - 0.30, -0.10, 1.00)], 0.088, 0.070)
    P.add(L.sphere(0.090, 0.085, 0.080, 10, 7), 'bone', loc=(MX - 0.28, -0.10, 0.96))
    hang = [Vector((MX - 0.27, -0.10, 0.94)), Vector((MX - 0.18, -0.04, 0.66)),
            Vector((MX + 0.04, 0.04, 0.46)), Vector((MX + 0.30, 0.10, 0.96))]
    P.raw(L.tube(hang, [0.028] * 4, 5), 'dark')
    # near arm out to the room, holding an open collar at chest height
    limb(P, [(MX + 0.23, -0.08, SH - 0.04), (MX + 0.50, -0.20, 1.34),
             (MX + 0.72, -0.26, 1.26)], 0.088, 0.070)
    P.add(L.sphere(0.092, 0.086, 0.082, 10, 7), 'bone', loc=(MX + 0.75, -0.27, 1.25))
    _open_ring(P, (MX + 0.92, -0.30, 1.22), 0.195, 'dark', rad=0.034, n=16,
               gap=0.30, axis='y', phase=0.35, tilt=0.42)
    _span("arms", _i_arms)

    # ---- THE LIST. One ornament, and it is the lawful-looking part the way the
    # Reeve's seal and the Tapster's slate were: a tally board at the belt with
    # four struck lines on it. Four names, four collars.
    _i_list = len(P.items)
    # PASS 2, FAULT 6: at x-0.30 the board was INSIDE the coat's outline and
    # one sliver of it showed. Outboard and forward, on the hip, clear of both.
    P.add(L.box(0.22, 0.028, 0.30), 'bone', loc=(MX - 0.44, -0.26, 1.00),
          rot=(0.0, 0.0, 0.22))
    for i in range(4):
        P.add(L.box(0.016, 0.012, 0.115), 'dark',
              loc=(MX - 0.50 + i * 0.040, -0.276, 1.01), rot=(0.0, 0.09 * (i - 1.5), 0.22))
    _span("list", _i_list)

    return P


BUILDERS.update({"pressman": pressman})


# ------------------------------- 23 THE STRICKLER: a beam, a measure and a line
CANON.update({
    "strickler": ("The Strickler", 2.55, (0.70, 0.66, 0.52), (0.86, 0.92, 1.00),
                  "treasury",
                  "IT STRIKES YOU LEVEL - while it stands, your best hero is scraped "
                  "down to the measure of your worst; your strongest is no answer, so "
                  "lift the lowest or break the beam",
                  0.12, "Something in here is taking the heap off."),
})
ORDER = ORDER + ["strickler"]


def _gltf_counts(stem):
    """Read the PRIMITIVE and TRIANGLE counts straight off the .gltf's JSON,
    before anything is imported.

    THIS EXISTS BECAUSE OF A FAULT I REPORTED AGAINST MYSELF. The Barrel in
    the Tapster's pass 2 tore into shards and I blamed the MODEL - two
    material slots at a coincident radius. The 17:42 audit (94 files, 44
    multi-slot objects, 52 measurable pairs, docs/art/PROPS_SLOT_AUDIT.md)
    found ZERO coincident pairs within 1 mm, the Barrel included, and three
    renders of the same file settled the cause: OUR OWN FIXED CAP of 110 faces,
    which on an 824-triangle cask is a collapse ratio of 0.1335 across a
    two-primitive mesh. The cap was the cause and the cap is the cure.

    So the cap is now read off the model. Returns (prims, tris, per_prim_min).
    """
    import json
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                        os.pardir, os.pardir))
    path = os.path.join(root, "assets", "props", stem + ".gltf")
    if not os.path.isfile(path):
        return (0, 0, 0)
    try:
        with open(path, encoding="utf-8") as fh:
            d = json.load(fh)
    except Exception:
        return (0, 0, 0)
    acc = d.get("accessors", [])
    prims, tris, smallest = 0, 0, None
    for me in d.get("meshes", []):
        for pr in me.get("primitives", []):
            prims += 1
            ix = pr.get("indices")
            n = (acc[ix]["count"] // 3) if (ix is not None and ix < len(acc)) else 0
            tris += n
            smallest = n if smallest is None else min(smallest, n)
    return (prims, tris, smallest or 0)


# A primitive collapsed below this many triangles stops being the shape it was
# modelled as. It is the floor the Barrel went through at 110/824.
PRIM_FLOOR = 72


def _prop_mesh_m(stem, placed_m, keep_slots=None, px_per_m=900.0):
    """_prop_mesh, with the cap DERIVED FROM THE MODEL AND ITS PLACED SIZE
    instead of a constant.

    `placed_m` is the largest dimension this part will actually occupy in the
    finished creature. A fist-sized weight bag gets a fist-sized budget; a
    cask the size of a man does not get the same 110 faces as the bag. And the
    budget is REFUSED outright when it would drive any single primitive below
    PRIM_FLOOR - in that case the model ships at full density, because 730
    honest triangles cost less than one torn one.

    It is a SEPARATE function and not an edit to _prop_mesh on purpose: the
    Tapster shipped through _prop_mesh and its mesh must not move under it
    while I am changing the rule. One thing at a time.
    """
    prims, tris, per_prim = _gltf_counts(stem)
    budget = int(max(96.0, placed_m * px_per_m))
    cap = tris                                    # the model's own density
    if tris and budget < tris:
        ratio = float(budget) / float(tris)
        if per_prim and per_prim * ratio >= PRIM_FLOOR:
            cap = budget
    _PROP_CAPS[stem] = {"prims": prims, "tris": tris, "smallest_prim": per_prim,
                        "placed_m": round(placed_m, 3), "budget": budget,
                        "cap_used": cap, "decimated": bool(cap < tris)}
    return _prop_mesh(stem, max_faces=cap, keep_slots=keep_slots)


_PROP_CAPS = {}


def strickler():
    """IT STRIKES YOU LEVEL. A strickle is the straight-edged stick a market
    officer draws across the rim of a grain measure to scrape the heap off, so
    that a bushel sold is a bushel and not a bushel and a handful. This one
    does it to a party. While it stands, the best hero in the room is struck
    down to the measure of the worst - so the fight is not won by your strongest
    swinging harder, it is won by getting your weakest off the floor, or by
    breaking the beam he measures against.

    WHY IT IS NOT ONE OF THE TWENTY-TWO, checked by PARSING CANON rather than
    by remembering it (36 entries, 22 distinct bodies). The set summons,
    re-plates itself, drags, douses the lamps, rises from its own graves, bars
    the door, steals gear, heals the room, floods it, sows thorns, pre-sets
    traps, scales with the fire, throws its voice, sets the floor, splits in
    two, arms the other monsters, loads you down, cuts the party in half,
    learns the blow you used, takes the haul, drinks the brews, and collars
    your fallen. NOT ONE OF THEM TOUCHES THE HEROES RELATIVE TO EACH OTHER.
    The Loader weighs EVERYONE down; this one flattens the DIFFERENCE between
    them, which inverts who in the party matters and is a decision rather than
    a damage race.

    THE SIDE VIEW IS THE POINT OF THIS ONE, AND IT IS THE LEAD'S NOTE ON THE
    PRESSMAN TAKEN AS A BRIEF. The Pressman's trade reads from the front (a
    1.72 m yoke across the picture, four collars hanging) and collapses to a
    narrow post from the side. A horizontal element can only be read from the
    camera it is NOT pointing at, so one horizontal can never carry both views.
    This creature therefore carries TWO, AT RIGHT ANGLES:

      THE STRICKLE  a 1.48 m straight-edge along model X, laid across the rim
                    of the measure and held in both hands. Reads from the
                    FRONT; foreshortens to a stub from the side.
      THE BEAM      a 2.00 m balance beam along model Y, on one standard
                    behind the shoulders, a shallow pan hanging fore and the
                    weights hanging aft. Reads from the SIDE; foreshortens to
                    a stub from the front.

    Each covers the other's blind camera BY CONSTRUCTION, and that claim is
    MEASURED, not asserted - tools/art/_trade_read.py renders the creature with
    and without each group through one camera and counts the pixels that MOVED,
    the same viewer's question that caught the Reeve's head glow. The numbers,
    and the two older creatures measured the same way for a baseline, are in
    docs/art/MINIBOSSES.md.

    WEAR 0.12, the second-lowest in the file after the Reeve's 0.05, and the
    tool justifies it: a strickle that is not straight does not measure, and an
    officer whose beam is out of true is an officer nobody obeys. Mr. E's rule
    2 - condition is the receipt, and this receipt reads KEPT TRUE ON PURPOSE.
    The coat under it is working cloth and is pulled toward the dark; the iron
    of the beam is the brightest thing on the body.

    THE PACK GEOMETRY HERE IS THE BARREL LESSON APPLIED. The measure and the
    weights are real CC0 Fantasy Props MegaKit meshes, and every one of them
    goes through _prop_mesh_m, which reads the primitive and triangle counts off
    the .gltf FIRST and caps by the model and its placed size. Bucket_Wooden_1
    is 976 triangles over 2 primitives; Pouch_Large is 730 over 2. The chosen
    cap per model is in the gen report, so a future run can see which were
    decimated and which shipped whole.

    FRAMES, because the lead has asked three times: every number in this
    builder is in BLENDER'S WORLD FRAME as it is written into the .glb - front
    is model -Y, the strickle lies along model X, the beam along model Y, up is
    +Z. That is NOT the engine's slot frame and nothing here should be pasted
    into a Godot rotation without converting it.

    Static: a `model` path and no `anims` entry.
    """
    P = Parts("strickler")
    P.spans = {}
    P.used_pack = False
    P.pack_caps = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = 0.0
    HIP, SH, HEAD = 0.92, 1.50, 1.78
    # PASS 2, FAULT 1 OF 6, AND THE ONE THAT MATTERED FROM THE FRONT. The
    # standard stood at x = MX, directly behind the man - so from the front
    # camera the beam, the pivot and the fore pan all stacked ON HIS HEAD and
    # the pan's three cords drew a triangle across his face. There was no face
    # in the front view at all. Offset in X costs the SIDE view nothing (it is
    # the side camera's depth axis) and clears the head completely.
    PX = 0.47                              # the balance, off his shoulder in X
    POST_Y, POST_TOP = 0.40, 2.20          # the standard, behind the shoulders
    BEAM_Z = 2.10
    BEAM_F, BEAM_A = -0.96, 1.00           # fore and aft ends of the beam
    STR_Z, STR_HALF = 1.12, 0.74           # the strickle: 1.48 m along X
    MEAS = (MX - 0.02, -0.32, 0.68)        # the measure's base centre
    # PASS 2, FAULT 4: at 0.34 m tall the bucket's own hoops squashed into
    # THREE STACKED BOWLS from the side. A bushel is wide and shallow, not
    # flattened - 0.40 keeps the hoops reading as hoops and puts the rim
    # exactly under the strickle.
    # PASS 3, SAME ELEMENT, AND 0.40 WAS STILL A SQUASH. From both cameras it
    # was a stack of tubs, because the fault was never the height alone: a
    # banded vessel squashed along its bands turns every band into a separate
    # rim. Carried at its own proportions it is one vessel with hoops on it,
    # and the rim lands exactly under the strickle either way.
    MEAS_S = (0.50, 0.50, 0.44)

    # ---- THE MAN. Planted, leaning back a little under the beam behind him.
    _i_man = len(P.items)
    _legs(P, MX, y=0.06, hip=HIP, stance=0.21)
    limb(P, [(MX, 0.12, HIP - 0.06), (MX, 0.06, 1.20), (MX - 0.02, 0.00, SH)], 0.230, 0.250)
    P.add(L.box(0.54, 0.30, 0.090), 'dark', loc=(MX, 0.04, 1.06))             # belt
    # a flared coat to mid-shin: the Pressman's pass-5 lesson taken as read,
    # not re-learned. Cloth hangs and FLARES; a vessel tapers inward.
    P.add(aim(L.cone(0.265, 0.350, 0.62, 12), (MX, 0.04, 1.04), (0.0, 0.0, -1.0)), 'body')
    for s in (-1, 1):
        P.add(L.sphere(0.162, 0.152, 0.132, 12, 8), 'body', loc=(MX - 0.02 + s * 0.27, 0.00, SH))
    P.add(L.sphere(0.150, 0.166, 0.170, 14, 9), 'bone', loc=(MX - 0.02, -0.18, HEAD))
    # the officer's flat cap, brim level - a level brim over a level beam
    P.add(aim(L.cone(0.232, 0.222, 0.050, 14), (MX - 0.02, -0.18, HEAD + 0.145),
              (0.0, 0.0, 1.0)), 'dark')
    eyes(P, (MX - 0.02, -0.08, HEAD - 0.01), 0.055, 0.028, -0.26)
    _span("man", _i_man)

    # ---- THE STANDARD AND THE BEAM. The SIDE reader, and the whole argument
    # for this creature's shape. One upright, one long horizontal in Y.
    _i_beam = len(P.items)
    BX = MX - 0.02 + PX
    limb(P, [(BX, POST_Y, 0.10), (BX, POST_Y + 0.02, 1.20),
             (BX, POST_Y, POST_TOP)], 0.090, 0.068, 'dark')
    P.add(L.box(0.30, 0.30, 0.085), 'dark', loc=(BX, POST_Y, 0.055))          # the foot plate
    # the beam itself, dead level: a balance IN balance is what the thing is for
    P.add(L.box(0.115, (BEAM_A - BEAM_F), 0.105), 'dark',
          loc=(BX, (BEAM_F + BEAM_A) / 2.0, BEAM_Z))
    P.add(L.box(0.175, 0.175, 0.175), 'dark', loc=(BX, POST_Y, BEAM_Z))       # the pivot box
    for yy in (BEAM_F, BEAM_A):                       # squared ends, as forged
        P.add(L.box(0.155, 0.085, 0.155), 'dark', loc=(BX, yy, BEAM_Z))
    # PASS 2, FAULT 2, AND IT IS THE PRESSMAN'S OWN PASS-1 LESSON ARRIVING IN
    # REVERSE. In the side view the balance stood on its own foot behind the
    # man and touched him nowhere: the picture read as A MAN STANDING NEXT TO
    # A SET OF SCALES, two objects, not one creature. The same fault the
    # Pressman had when its arm went straight up to the bar. So the standard
    # is now BRACED TO HIM - a strut from the shoulder and an iron collar at
    # the belt - and the beam is his to carry.
    limb(P, [(MX + 0.20, 0.02, SH - 0.02), (BX - 0.03, POST_Y - 0.06, SH + 0.22)],
         0.052, 0.044, 'dark')
    limb(P, [(MX + 0.16, 0.06, 1.06), (BX - 0.04, POST_Y - 0.04, 1.02)], 0.044, 0.038, 'dark')
    P.add(L.box(0.085, 0.175, 0.175), 'dark', loc=(BX - 0.02, POST_Y - 0.02, 1.02))
    _span("beam", _i_beam)

    # ---- THE PAN, hanging FORE. Shallow, empty, and level with the weights.
    _i_pan = len(P.items)
    PAN_Z = 1.52
    for a in (0.0, TAU / 3.0, 2.0 * TAU / 3.0):
        limb(P, [(BX + 0.30 * math.cos(a), BEAM_F + 0.30 * math.sin(a), PAN_Z + 0.04),
                 (BX, BEAM_F, BEAM_Z - 0.07)], 0.019, 0.017, 'dark')
    P.add(aim(L.cone(0.345, 0.300, 0.075, 20), (BX, BEAM_F, PAN_Z), (0.0, 0.0, 1.0)),
          'dark')
    _span("pan", _i_pan)

    # ---- THE WEIGHTS, hanging AFT. Real pack geometry, capped by the model.
    _i_wt = len(P.items)
    WT_Z = 1.54
    for a in (0.0, TAU / 3.0, 2.0 * TAU / 3.0):
        limb(P, [(BX + 0.24 * math.cos(a), BEAM_A + 0.24 * math.sin(a), WT_Z + 0.16),
                 (BX, BEAM_A, BEAM_Z - 0.07)], 0.019, 0.017, 'dark')
    P.add(aim(L.cone(0.280, 0.250, 0.055, 18), (BX, BEAM_A, WT_Z), (0.0, 0.0, 1.0)),
          'dark')
    pouch = _prop_mesh_m("Pouch_Large", 0.26)
    if pouch is not None:
        P.used_pack = True
        _place_unit(P, pouch, 'body', BX - 0.11, BEAM_A - 0.07, WT_Z + 0.05, 0.26, 0.26, 0.22,
                    yaw=0.4)
        _place_unit(P, pouch, 'body', BX + 0.12, BEAM_A + 0.08, WT_Z + 0.05, 0.24, 0.24, 0.20,
                    yaw=-0.9)
        _place_unit(P, pouch, 'body', BX + 0.01, BEAM_A + 0.01, WT_Z + 0.24, 0.22, 0.22, 0.19,
                    yaw=2.1)
    else:
        for dx, dy, dz, r in ((-0.12, -0.06, 0.06, 0.115), (0.10, 0.07, 0.06, 0.105),
                              (0.00, 0.00, 0.24, 0.100)):
            P.add(L.sphere(r, r, r * 0.82, 10, 7), 'body',
                  loc=(BX + dx, BEAM_A + dy, WT_Z + dz))
    _span("weights", _i_wt)

    # ---- THE MEASURE AND THE HEAP. The FRONT reader, half of it: a wide
    # shallow vessel at the belly on a strap, with the heap still standing on
    # one side of the rim - the handful that is about to be struck off.
    _i_meas = len(P.items)
    bucket = _prop_mesh_m("Bucket_Wooden_1", 0.58)
    if bucket is not None:
        P.used_pack = True
        _place_unit(P, bucket, 'body', MEAS[0], MEAS[1], MEAS[2], *MEAS_S)
    else:
        P.add(aim(L.cone(0.290, 0.250, MEAS_S[2], 20), (MEAS[0], MEAS[1], MEAS[2]),
                  (0.0, 0.0, 1.0)), 'body')
    # PASS 3: the mouth. A vessel being struck level has to read as OPEN, and
    # a closed-looking tub with a bar over it is a bench, not a measure. One
    # dark disc set just inside the rim is the whole cue and it costs 20 faces.
    P.add(aim(L.cone(0.218, 0.218, 0.014, 20), (MEAS[0], MEAS[1], MEAS[2] + MEAS_S[2] - 0.055),
              (0.0, 0.0, 1.0)), 'dark')
    for s in (-1, 1):                                   # the strap over the shoulders
        limb(P, [(MX - 0.02 + s * 0.22, -0.02, SH + 0.02),
                 (MEAS[0] + s * 0.24, MEAS[1] + 0.12, MEAS[2] + MEAS_S[2] * 0.70)],
             0.026, 0.024, 'dark')
    # the heap: a low mound standing proud of the rim on the far side only.
    # PASS 2, FAULT 3: at 0.175 x 0.150 x 0.105 this was HEAD-SIZED, and from
    # the side the picture had two round heads in it - one of them a pile of
    # grain. A heap is a handful above a rim, not a dome: a third of the width
    # and under half the height, pushed out to the far rim.
    P.add(L.sphere(0.105, 0.092, 0.044, 12, 8), 'bone',
          loc=(MEAS[0] + 0.16, MEAS[1] + 0.02, MEAS[2] + MEAS_S[2] - 0.010))
    _span("measure", _i_meas)

    # ---- THE STRICKLE. The other half of the FRONT reader: one straight edge
    # across the whole picture in X, with the true line lit along its underside.
    _i_str = len(P.items)
    P.add(L.box(STR_HALF * 2.0, 0.062, 0.088), 'bone', loc=(MX - 0.02, MEAS[1] - 0.02, STR_Z))
    P.add(L.box(STR_HALF * 2.0 - 0.06, 0.020, 0.016), 'glow',
          loc=(MX - 0.02, MEAS[1] - 0.052, STR_Z - 0.048))
    for s in (-1, 1):                                   # turned grips at both ends
        P.add(L.box(0.075, 0.105, 0.125), 'dark',
              loc=(MX - 0.02 + s * (STR_HALF - 0.03), MEAS[1] - 0.02, STR_Z))
    _span("strickle", _i_str)

    # ---- THE ARMS. Both forward and down onto the ends of the strickle, which
    # is what makes man and bar one creature rather than a man holding a prop.
    _i_arms = len(P.items)
    for s in (-1, 1):
        limb(P, [(MX - 0.02 + s * 0.26, -0.02, SH - 0.05),
                 (MX - 0.02 + s * 0.52, -0.16, 1.34),
                 (MX - 0.02 + s * (STR_HALF - 0.05), MEAS[1] - 0.04, STR_Z + 0.07)],
             0.086, 0.068)
    _span("arms", _i_arms)

    # ---- THE SEAL. One ornament, the lawful-looking part, as the Reeve's seal
    # and the Pressman's tally board were: a stamped disc on a cord at the hip,
    # the mark an officer strikes into a measure he has passed.
    _i_seal = len(P.items)
    limb(P, [(MX - 0.30, -0.06, 1.06), (MX - 0.37, -0.16, 0.92)], 0.014, 0.013, 'dark')
    P.add(aim(L.cone(0.098, 0.098, 0.030, 14), (MX - 0.37, -0.17, 0.86), (0.0, 0.0, 1.0)), 'bone')
    P.add(aim(L.cone(0.052, 0.052, 0.040, 12), (MX - 0.37, -0.19, 0.87), (0.0, -1.0, 0.0)), 'dark')
    _span("seal", _i_seal)

    P.pack_caps = dict(_PROP_CAPS)
    return P


BUILDERS.update({"strickler": strickler})


# ===========================================================================
# 24. THE DYER - 17 Nov 2026, art lane.
#
# THE LEAD'S 18:58 NOTE, TAKEN AS THE BRIEF: "the strickler is the most MUTED
# thing in the twenty-three ... if a twenty-fourth can carry its trade in
# COLOUR as well as silhouette, that is worth more to me than a twenty-fifth."
#
# I MEASURED THE CLAIM OFF THE PICTURES BEFORE AGREEING WITH IT, because the
# tint table is not the register's colour and this lane has shipped a number
# that answered a different question than the sentence beside it. Over the 23
# distinct bodies' own front.png, HSV saturation of every opaque pixel with
# value > 0.10, chroma-weighted hue:
#   median satMean 0.087 | max 0.207 (the DRILLMASTER, the first one ever made)
#   the STRICKLER is 0.052 - RANK 1 OF 23, the least saturated. He is right,
#   and he is right by the measurement and not by impression.
#   hue bands: 0-60 deg 14 bodies | 60-110 2 | 110-190 ZERO | 190-260 7 |
#   260-360 ZERO. HALF THE WHEEL IS EMPTY ACROSS TWENTY-THREE BODIES.
# AND THE TINT TABLE DISAGREES WITH THE PICTURES, WHICH IS THE REAL FINDING:
# CANON gives the Tallyman HSV sat 0.66 and the render reads 0.136. Anyone who
# judges this register's colour off CANON is judging the wrong number.
#
# *** THE STRUCTURAL CAUSE, AND IT IS A DEFECT IN MY OWN SHIPPED GENERATOR. ***
# minibossgen.build_miniboss derives ALL FOUR materials from ONE tint: body is
# the tint mixed with the aura, dark is 0.16 x body, bone is the tint pushed
# toward white, glow is the aura normalised. SO EVERY BODY IN THIS FILE IS
# MONOCHROME BY CONSTRUCTION. No builder in 23 could have had two hues on it
# even if it wanted them. That is why the register drifted grey, and it is not
# a taste problem - it is a pipeline problem with my name on it. OVERRIDE below
# lets a key declare its own per-slot materials. It is EMPTY for all 23
# existing keys, so their output is unchanged, and the four-mesh cap is
# untouched: four slots, four materials, four meshes.
# ===========================================================================

# key -> {slot: (rgb, rough, metal)} for a solid, or {slot: (rgb, strength)}
# for 'glow'. A slot absent here keeps the tint-derived material.
# EMPTY FOR EVERY ONE OF THE FIRST TWENTY-THREE - checked, not assumed, by the
# assertion in minibossgen.
OVERRIDE = {
    "dyer": {
        # woad. The big areas: two of the three sheets, the apron's lining,
        # the wash down the vat, one skein, one floor splash.
        'body': ((0.055, 0.205, 0.600), 0.54, 0.00),
        # madder. The accent: the middle sheet, his arms to the elbow, the
        # paddle shaft, one skein, one splash.
        'bone': ((0.620, 0.105, 0.080), 0.58, 0.00),
        # wet timber and iron - the frame, the vat staves, the man himself.
        # NOT derived from the body colour, or the frame would read blue.
        'dark': ((0.070, 0.062, 0.056), 0.82, 0.03),
        # weld. The open vat, hot, lit from the fire under it. The one thing
        # in a dye-house that genuinely gives off light, so emissive is the
        # honest material and not a cheat to get a third hue.
        # PASS 3, CHANGE A, judged on its own: at strength 2.30 the weld came
        # back CREAM. An emissive that clips to white is not a third hue, it is
        # a white hole, and the whole argument for this body is three hues.
        'glow': ((1.000, 0.690, 0.075), 1.05),
    },
}


VCOL_SLOTS = {}          # key -> set of slots whose material is vertex-driven


def merge_objs(key, items, mats, suffix=None, vcols=None):
    """THE ONE MERGE. minibossgen, _metal_read, _trade_read and _colour_read all
    called a private copy of this, four identical functions in four files, and a
    colour measured through a different merge than the one that ships is a
    number about nothing - the same reason apply_overrides is shared. Added
    18 Nov when vertex colours gave the four copies something to disagree about.

    Built part-by-part a miniboss runs to 60-200 objects; merged by material it
    is at most four meshes, which is the bar the lords and the creatures hold.

    WITH NO VERTEX COLOURS ANYWHERE THIS IS THE OLD CODE PATH EXACTLY, down to
    make() being called with vcol=None, so the 24 shipped bodies are byte-
    identical by construction and not by hope. Proven anyway: see
    renders/art/minibosses/_vcol_regression.json.

    An item in a vertex-driven slot that declares NO colours is painted the
    slot's own declared rgb, so geometry that merely shares the slot renders
    exactly as it did before the slot went vertex-driven.
    """
    vcols = vcols or {}
    vslots = VCOL_SLOTS.get(key, set())
    groups, painted = {}, {}
    for i, item in enumerate(items):
        verts, faces, slot = item
        gv, gf, gc = groups.setdefault(slot, ([], [], []))
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(idx + off for idx in f) for f in faces])
        if slot in vslots:
            c = vcols.get(id(item))
            if c is None:
                # geometry that merely SHARES a vertex-driven slot and declares
                # no colours of its own: painted the slot's declared rgb, which
                # is what it rendered as before the slot went vertex-driven.
                fill = SLOT_RGB.get((key, slot), (1.0, 1.0, 1.0))
                c = [fill] * len(verts)
            else:
                painted[slot] = painted.get(slot, 0) + 1
                if len(c) != len(verts):
                    raise ValueError("%s item %d: %d vertex colours for %d verts"
                                     % (key, i, len(c), len(verts)))
            gc.extend(c)
    out = []
    for slot in ('body', 'dark', 'bone', 'glow'):
        if slot not in groups:
            continue
        gv, gf, gc = groups[slot]
        nm = "%s_%s" % (key, slot) if suffix is None else "%s_%s_%s" % (key, slot, suffix)
        ob = L.make(nm, gv, gf, mats.get(slot, mats['body']),
                    vcol=(gc if slot in vslots else None))
        # HOW MANY ITEMS ACTUALLY CARRIED DECLARED COLOURS, recorded on the
        # object so a caller can ASSERT it. The failure this guards is quiet:
        # a vcols dict keyed wrongly paints every item the fill colour, the
        # render comes back looking like the old body, and the honest reading
        # of that picture is "the change did nothing" when the truth is "the
        # change was never applied". A number that can be asserted turns that
        # into a red line instead of a wrong conclusion.
        ob["vcol_items"] = painted.get(slot, 0)
        out.append(ob)
    return out


SLOT_RGB = {}            # (key, slot) -> the slot's declared rgb, for the fill


def apply_overrides(key, mats):
    """Replace tint-derived materials with a key's declared ones. Called by
    minibossgen, _trade_read and _colour_read so all three agree - a colour
    measured through a different material table than the one that ships is a
    number about nothing."""
    ov = OVERRIDE.get(key)
    if not ov:
        return mats
    for slot, spec in ov.items():
        if slot == 'glow':
            rgb, strength = spec
            mats[slot] = L.mat_glow(key + "_glow_ov", tuple(rgb), strength)
        else:
            rgb, rough, metal = spec[0], spec[1], spec[2]
            # an optional FOURTH element is the dielectric specular level. A
            # three-element row is untouched and renders exactly as it always
            # has, so no other body in the register moves.
            sp = spec[3] if len(spec) > 3 else None
            # an optional FIFTH element, True, means THE COLOUR COMES OFF THE
            # MESH: the slot's material reads the vertex colour and the rgb above
            # becomes the FILL for any geometry in the slot that declares none,
            # so such geometry renders exactly as it did. Added 18 Nov for the
            # Greener's copper leaves; nothing else in the register sets it.
            SLOT_RGB[(key, slot)] = tuple(rgb)
            if len(spec) > 4 and spec[4]:
                VCOL_SLOTS.setdefault(key, set()).add(slot)
                mats[slot] = L.mat_vattr(key + "_" + slot + "_ov", rough, metal, sp)
            else:
                VCOL_SLOTS.get(key, set()).discard(slot)
                mats[slot] = L.mat_solid(key + "_" + slot + "_ov", tuple(rgb), rough,
                                         metal, sp)
    return mats


CANON.update({
    "dyer": ("The Dyer", 2.60, (0.16, 0.32, 0.72), (0.26, 0.46, 1.00),
             "workshop",
             "IT MARKS ONE OF YOU AND HUNTS ONLY THE MARK - it slings the vat, "
             "and while the stain is wet it will walk past everyone else to reach "
             "the one wearing it; the stain can be passed hero to hero, so the "
             "party chooses who carries it and for how long",
             0.30, "Something back there just marked one of you."),
})
ORDER = ORDER + ["dyer"]


def _rz(x, y, a):
    """Rotate a local point about Z. The whole tenter frame is turned so that
    NEITHER camera sees the sheets edge-on - see the docstring."""
    ca, sa = math.cos(a), math.sin(a)
    return (x * ca - y * sa, x * sa + y * ca)


def _cloth(P, slot, x0, x1, ztop, zbot, ybase, phase, a, nx=7, nz=6,
           bow=0.26, thick=0.035):
    """A hanging sheet as a thickened quad grid with a real billow in Y.

    NOT a flat membrane, and the reason is the Pressman fault stated plainly:
    a flat panel in one plane is a LINE from the camera that plane points at.
    Each row's Y is bowed by sin across the width and the bow GROWS downward,
    because a wet sheet hangs heavy and swings out at the hem. That gives the
    side camera a surface to see instead of an edge."""
    V, F = [], []
    for iz in range(nz + 1):
        tz = iz / float(nz)
        z = ztop + (zbot - ztop) * tz
        for ix in range(nx + 1):
            tx = ix / float(nx)
            x = x0 + (x1 - x0) * tx
            y = ybase + bow * (0.30 + 0.70 * tz) * math.sin(math.pi * tx + phase)
            rx, ry = _rz(x, y, a)
            V.append(Vector((rx, ry, z)))
    k = nx + 1
    base = len(V)
    # back face: pushed along the sheet's own local normal, approximated by Y
    for iz in range(nz + 1):
        for ix in range(nx + 1):
            v = V[iz * k + ix]
            nxv, nyv = _rz(0.0, 1.0, a)
            V.append(Vector((v.x + nxv * thick, v.y + nyv * thick, v.z)))
    for iz in range(nz):
        for ix in range(nx):
            a0 = iz * k + ix
            F.append((a0, a0 + 1, a0 + k + 1, a0 + k))
            b0 = base + a0
            F.append((b0 + k, b0 + k + 1, b0 + 1, b0))
    for ix in range(nx):            # hem and head edges, closed
        t0 = ix
        F.append((t0, base + t0, base + t0 + 1, t0 + 1))
        b0 = nz * k + ix
        F.append((b0 + 1, base + b0 + 1, base + b0, b0))
    for iz in range(nz):            # the two selvedges
        l0 = iz * k
        F.append((l0 + k, base + l0 + k, base + l0, l0))
        r0 = iz * k + nx
        F.append((r0, base + r0, base + r0 + k, r0 + k))
    P.raw((V, F), slot)


def dyer():
    """IT MARKS ONE OF YOU AND HUNTS ONLY THE MARK.

    A dyer stands at a vat and puts colour into cloth. This one puts it into a
    hero. While the stain is wet it will walk past the tank, past the healer
    and past whoever is hitting it hardest to reach the one wearing the mark -
    and the stain can be HANDED ON by touch. So the party is not choosing how
    to kill it, it is choosing who carries the mark, and for how long, and who
    is standing close enough to take it next.

    WHY IT IS NOT ONE OF THE TWENTY-THREE, checked by PARSING CANON rather than
    by remembering it - 38 entries, 23 distinct bodies. The set summons, re-
    plates itself, drags one out of the line, douses the lamps, rises from its
    graves, bars the door, steals gear, heals the room, floods it, sows thorns,
    pre-sets traps, scales with the fire, throws its voice, sets the floor,
    splits in two, arms the other monsters, loads you down, cuts the party in
    half, learns the blow you used, takes the haul, drinks the brews, collars
    your fallen, and strikes the party level. TWO OF THEM TOUCH TARGETING AND
    NEITHER OF THEM IS THIS. The Gaoler takes a choice away - it hooks who IT
    picks. The Hurdleman divides the room by geometry. This one hands the
    choice TO the party and then makes them keep choosing, which is the only
    mechanic in the file the players themselves operate.

    *** AND THE COLOUR IS THE TRADE, WHICH IS THE WHOLE POINT OF THE BODY. ***
    The lead asked for a body that carries its trade in colour as well as in
    silhouette. A dyer is the one working man in a town whose JOB is colour -
    so nothing here is decorated. Woad is blue, madder is red, weld is yellow;
    they are on the frame because that is what a dye-house hangs out to dry,
    they are on his arms because that is what the work does to a man to the
    elbow, and the vat glows because an open vat of hot dye over a fire does.
    If this creature were grey it would be a man standing next to a trade
    instead of wearing it - the rule the Tanner observation produced.
    THREE HUES ON ONE BODY IS NEW IN THIS FILE and it needed the OVERRIDE hook
    above, because the generator derived all four materials from one tint.
    FOUR MESHES STILL - body, bone, dark, glow. The cap is not touched.

    THE READ: A MAN AT A VAT UNDER THREE HANGING SHEETS. Nothing in the other
    twenty-three has a broad hanging plane in it at all.

    THE FRAME IS TURNED 28 DEGREES ABOUT Z ON PURPOSE, and that is the
    Strickler's right-angle lesson applied to a different problem. The
    Strickler needed two horizontals at right angles because one horizontal can
    only be read from the camera it is not pointing at. A SHEET HAS THE SAME
    FAULT AND WORSE - a flat plane is a LINE from one side. Rather than hang
    six sheets, the frame is rotated so neither the front nor the side camera
    is normal or tangent to it, and each sheet is BOWED in Y with the bow
    growing toward the hem. Measured per view by _trade_read.py, not asserted.

    WEAR 0.30, and it is SPLIT, which the register has not done before. The
    frame, the vat staves and the man are worked and wet - that is what 0.30
    buys through the roughness and metal terms. THE CLOTH IS NOT WORN AT ALL:
    the sheets, the apron and the skeins take their colour from OVERRIDE and so
    skip the dulling entirely. That is Mr. E's second rule read as he wrote it -
    a dyer's goods are the one thing in his yard that must look NEW, because
    they are what he is selling. Condition is the receipt, and here the receipt
    and the man disagree, which is true of every tradesman who ever lived.

    THE THREE SKEINS AT HIS BELT AND THE THREE SPLASHES ON THE FLOOR are the
    fight told in the silhouette, the way the Scrapwright's two spare plates
    are: the thing he throws, and the evidence that he has thrown it before.

    FRAMES, because the lead has asked four times: every number in this builder
    is in BLENDER'S WORLD FRAME as written into the .glb - front is model -Y,
    up is +Z, the crossbar lies along the frame's own rotated X. That is NOT
    the engine's slot frame; nothing here should be pasted into a Godot
    rotation without converting it.

    Static: a `model` path and no `anims` entry.
    """
    P = Parts("dyer")
    P.spans = {}
    P.used_pack = False
    P.pack_caps = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    A = math.radians(28.0)          # the frame's turn

    # ------------------------------------------------- THE TENTER FRAME
    i0 = len(P.items)
    for s in (-1, 1):
        bx, by = _rz(s * 1.12, 0.46, A)
        limb(P, [(bx, by, 0.05), (bx, by, 1.30), (bx * 0.97, by, 2.52)],
             0.085, 0.062, 'dark')
        P.add(L.box(0.34, 0.34, 0.10), 'dark', loc=(bx, by, 0.05))
        # PASS 4 CHANGE F raked the braces backward; PASS 5 CHANGE J goes
        # further and takes the NEAR one out altogether. Backward or forward,
        # a brace on the man's side draws a long black diagonal straight across
        # the one part of the picture the eye has to read, and it fought the
        # paddle for the same line. One brace on the far post and a low sill
        # between the feet still say BUILT, and the asymmetry is the
        # Drillmaster's lesson: a frame does not have to be symmetrical to
        # read as a frame, and a symmetrical one reads as wallpaper.
        if s > 0:
            gx, gy = _rz(s * 1.46, 1.16, A)
            limb(P, [(bx, by, 1.74), (gx, gy, 0.06)], 0.050, 0.040, 'dark')
    cl, cr = _rz(-1.12, 0.46, A), _rz(1.12, 0.46, A)
    P.raw(L.tube([(cl[0], cl[1], 2.50), (0.0, _rz(0.0, 0.46, A)[1], 2.56),
                  (cr[0], cr[1], 2.50)], 0.070, 8), 'dark')
    sl, sr = _rz(-1.12, 0.52, A), _rz(1.12, 0.52, A)
    P.raw(L.tube([(sl[0], sl[1], 0.26), (sr[0], sr[1], 0.26)], 0.048, 6), 'dark')
    for u in (-0.72, -0.02, 0.70):   # tenter hooks the cloth hangs from
        hx, hy = _rz(u, 0.46, A)
        P.add(L.box(0.055, 0.055, 0.14), 'dark', loc=(hx, hy, 2.44))
    _span("frame", i0)

    # ------------------------------------------------- THE THREE SHEETS
    # Hem heights deliberately unequal - a straight hem across three sheets
    # would read as one banner, and a dye-house hangs what is ready.
    i0 = len(P.items)
    _cloth(P, 'body', -1.04, -0.42, 2.44, 0.98, 0.46, 0.00, A, bow=0.28)
    _cloth(P, 'bone', -0.34, 0.32, 2.44, 1.28, 0.42, 1.05, A, bow=0.24)
    _cloth(P, 'body', 0.40, 1.04, 2.44, 0.70, 0.49, 2.10, A, bow=0.30)
    _span("sheets", i0)

    # ------------------------------------------------- THE VAT
    i0 = len(P.items)
    # PASS 3, CHANGE B: the vat moved right and forward and came down from
    # 0.60 to 0.52 radius. At 0.60 it was a black drum across the bottom third
    # and the man was inside its outline - a cask, which is the Tapster's
    # silhouette, not a dye vat with a man working it.
    # PASS 5, CHANGE K: down again, 0.52 -> 0.45 and 0.74 -> 0.66. The side
    # picture showed it standing in front of the man to MID-CHEST - the
    # creature's whole lower half was a black drum with a head above it.
    VX, VY, VR, VH = 0.30, -0.46, 0.45, 0.66
    for j in range(16):             # staves
        th = TAU * j / 16.0
        sx, sy = VX + VR * math.cos(th), VY + VR * math.sin(th)
        P.add(L.box(0.20, 0.09, VH), 'dark', loc=(sx, sy, VH * 0.5),
              rot=(0.0, 0.0, th + math.pi * 0.5))
    for z in (0.13, 0.55):          # hoops
        ring = [Vector((VX + (VR + 0.035) * math.cos(TAU * i / 26.0),
                        VY + (VR + 0.035) * math.sin(TAU * i / 26.0), z))
                for i in range(27)]
        P.raw(L.tube(ring, 0.035, 6), 'dark')
    # *** PASS 2. THE VAT IS THE ONLY EMISSIVE THING ON THE BODY AND PASS 1
    # COULD NOT SEE IT - I HAD CAPPED MY OWN VAT. A 0.555 x 0.075 'dark' cone
    # sat as a LID over a 'glow' disc at z 0.760, and at the 2 degree camera
    # pitch these views use, a flat surface sunk inside a 0.80 m rim is not
    # visible from ANY eye-level camera even without the lid. The render said
    # ok:true, 0 blanks, 0 clips - because a hidden thing is not a blank one.
    # That is this lane's own trap 5, written in my prompt, committed again.
    # THE FIX IS ALSO THE TRUER THING: a working vat BRIMS. The dye stands
    # proud of the rim and goes over the side, so the weld is seen from eye
    # level because it is where it would actually be, not because the camera
    # was moved to find it.
    P.add(aim(L.cone(0.435, 0.405, 0.066, 26), (VX, VY, 0.660), (0.0, 0.0, 1.0)), 'glow')
    P.add(aim(L.cone(0.390, 0.225, 0.056, 24), (VX, VY, 0.693), (0.0, 0.0, 1.0)), 'glow')
    rim = [Vector((VX + (VR + 0.030) * math.cos(TAU * i / 26.0),
                   VY + (VR + 0.030) * math.sin(TAU * i / 26.0), 0.648))
           for i in range(27)]
    P.raw(L.tube(rim, 0.040, 6), 'dark')              # a ring, NOT a disc
    # three runs of weld going over the lip, and the older woad wash beside
    # them - the vat has held more than one colour, which is what a vat does
    for u, slot, z0 in ((-0.26, 'glow', 0.66), (0.08, 'glow', 0.66),
                        (-0.06, 'body', 0.60), (0.22, 'body', 0.60)):
        wx = VX + u
        P.raw(L.tube([(wx, VY - VR - 0.01, z0), (wx, VY - VR - 0.04, 0.40),
                      (wx + 0.03, VY - VR - 0.03, 0.06)],
                     [0.060, 0.046, 0.032], 6), slot)
    _span("vat", i0)

    # THE PADDLE'S LINE, DEFINED ONCE AND BEFORE ANYTHING THAT TOUCHES IT.
    # Butt high and behind his left shoulder, blade down in the vat. The hands
    # and the shaft both read off this, so they cannot disagree - see change G.
    # PASS 5, CHANGE H - A REGRESSION I PUT IN MYSELF AT PASS 4 AND THE SIDE
    # PICTURE CAUGHT IT. Rewriting the shaft as two fixed points, I gave it
    # 1.86 m of X travel and SIX CENTIMETRES of Y - so from the side camera the
    # one long diagonal on this creature was a vertical post, which is the
    # exact Pressman fault the Strickler was built to answer. The butt moves
    # 0.78 m forward: the shaft now travels in all three axes, so the front
    # camera gets its diagonal out of X and the side camera gets one out of Y.
    _PB = Vector((-1.62, -1.30, 2.06))
    _PE = Vector((VX - 0.02, VY - 0.08, 0.52))

    def _PADDLE(t):
        v = _PB + (_PE - _PB) * t
        return (v.x, v.y, v.z)

    # ------------------------------------------------- THE MAN
    i0 = len(P.items)
    # PASS 3, CHANGE C, AND IT IS THE ONE THE PICTURE DEMANDED. In pass 1 and
    # 2 the man stood INSIDE the sheets' outline at MX -0.74, MY -0.26: a dark
    # figure against dark-ish cloth, with a 0.155 shoulder sphere low enough
    # and big enough that the thing read as TWO HEADS. He is now pulled left
    # and well FORWARD of the frame, so his whole silhouette falls against the
    # background, and the shoulders are cut to 0.115 so there is one head on
    # this creature.
    # PASS 6, CHANGE L, AND IT IS A FAULT ONLY THE SIDE CAMERA COULD SHOW.
    # At MY -0.72 he stood 0.26 m in front of the vat, which is nothing in the
    # side view's screen axis - the drum covered him to the chest and his
    # apron, belt, skeins and legs were all behind it. He steps 0.40 m
    # forward. The front view barely changes; the side view gets a whole man.
    MX, MY = -1.06, -1.12
    HIP, SH, HEAD = 0.90, 1.46, 1.78
    for s in (-1, 1):
        limb(P, [(MX + s * 0.17, MY + 0.04, HIP), (MX + s * 0.21, MY - 0.04, 0.48),
                 (MX + s * 0.23, MY - 0.12, 0.08)], 0.100, 0.082, 'dark')
        P.add(L.box(0.26, 0.40, 0.11), 'dark', loc=(MX + s * 0.23, MY - 0.20, 0.055))
    # torso leaning out toward the vat, so he is WORKING and not posing
    limb(P, [(MX, MY + 0.08, 0.84), (MX + 0.06, MY - 0.02, 1.16),
             (MX + 0.14, MY - 0.12, SH)], 0.235, 0.245, 'dark')
    for s in (-1, 1):
        P.add(L.sphere(0.115, 0.108, 0.098, 11, 8), 'dark',
              loc=(MX + 0.14 + s * 0.255, MY - 0.12, SH + 0.03))
    P.add(L.sphere(0.135, 0.150, 0.150, 14, 9), 'dark', loc=(MX + 0.16, MY - 0.16, HEAD))
    # a flat cap, not a helm. He is a tradesman.
    P.add(aim(L.cone(0.215, 0.195, 0.035, 14), (MX + 0.16, MY - 0.18, HEAD + 0.145),
              (0.0, -0.14, 1.0)), 'dark')
    P.add(aim(L.cone(0.145, 0.120, 0.075, 14), (MX + 0.16, MY - 0.17, HEAD + 0.115),
              (0.0, -0.10, 1.0)), 'dark')
    # *** PASS 7. THE EYES WERE FLOATING 0.23 m IN FRONT OF HIS FACE AND THE
    # FRONT CAMERA HID IT BY PROJECTION. *** I passed the head's own forward
    # offset in `loc` AND passed `fwd` on top of it, so the two glow spheres
    # sat at y -1.66 against a face whose front surface is at y -1.43. From
    # the front they land on the face and look perfect. From the side they are
    # a gold dot hanging in clear air, and that is what the picture showed.
    # NEITHER EXISTING CHECK COULD SEE IT: a detached piece is not a blank
    # frame and it is not a clipped border, so ok:true, 0 blanks, 0 clips was
    # a true report of the wrong things. _colour_read now counts DETACHED
    # SILHOUETTE COMPONENTS, which is the check that would have caught it.
    eyes(P, (MX + 0.16, MY - 0.16, HEAD), 0.052, 0.026, -0.135)
    # ARMS. Upper arm is the man; FROM THE ELBOW DOWN HE IS THE DYE - that is
    # what the work does, and it is the cheapest true thing on the body.
    #
    # PASS 4, CHANGE G, AND IT IS A FLOAT I SHIPPED INTO THE PASS 3 PICTURE.
    # In pass 3 the paddle started in CLEAR AIR 0.38 m to the right of his head
    # and ran down into the vat while both his arms hung at his sides. He was
    # not holding it. A creature whose whole trade is the thing in its hands
    # cannot have the thing float. The shaft line is now defined FIRST, by two
    # fixed end points, and BOTH HANDS ARE PLACED ON IT by parameter - so the
    # grip cannot drift when the shaft moves again.
    for s, t in ((-1, 0.215), (1, 0.425)):
        hx, hy, hz = _PADDLE(t)
        sx = MX + 0.14 + s * 0.255
        P.raw(L.tube([(sx, MY - 0.12, SH + 0.01),
                      ((sx + hx) * 0.5, (MY - 0.12 + hy) * 0.5 - 0.06,
                       (SH + hz) * 0.5 + 0.02)], [0.090, 0.072], 8), 'dark')
        P.raw(L.tube([((sx + hx) * 0.5, (MY - 0.12 + hy) * 0.5 - 0.06,
                       (SH + hz) * 0.5 + 0.02), (hx, hy, hz)], [0.072, 0.054], 8), 'bone')
        P.add(L.sphere(0.074, 0.068, 0.064, 9, 7), 'bone', loc=(hx, hy, hz))
    # THE APRON - woad lining, bowed forward off the chest to the knee
    _cloth(P, 'body', MX - 0.27, MX + 0.29, 1.34, 0.50, MY - 0.30, 0.0, 0.0,
           nx=5, nz=5, bow=0.17, thick=0.030)
    _span("man", i0)

    # ------------------------------------------------- THE PADDLE
    # One long clear diagonal, upper-left to lower-right, and it travels in Y
    # as well as X so the SIDE camera gets a diagonal too and not a post.
    i0 = len(P.items)
    # PASS 3, CHANGE D: in passes 1 and 2 the shaft ran from behind his left
    # shoulder STRAIGHT ACROSS HIS FACE. It now starts clear to his right at
    # MX+0.52 - 0.38 m off a 0.135 m head - and still travels 0.86 m in Y, so
    # the side camera keeps its diagonal.
    b = _PADDLE(0.0)
    e = _PADDLE(1.0)
    P.raw(L.tube([b, _PADDLE(0.5), e], [0.040, 0.048, 0.046], 8), 'bone')
    P.add(L.sphere(0.058, 0.058, 0.050, 9, 6), 'bone', loc=b)      # the butt knob
    P.add(L.box(0.27, 0.12, 0.38), 'bone', loc=(e[0] + 0.02, e[1] + 0.02, e[2] - 0.12),
          rot=(0.16, -0.20, 0.0))
    _span("paddle", i0)

    # ------------------------------------------------- THE SKEINS IT THROWS
    i0 = len(P.items)
    # PASS 3, CHANGE E: the three skeins were clustered at shoulder height and
    # were half of what made the upper body unreadable. They hang at the HIP
    # now, spread in X, below the apron's hem line.
    # PASS 5, CHANGE I: in passes 3 and 4 the three skeins hung OUTSIDE his
    # body on cords that began in open air - from the side they were three
    # beads floating beside a man. There is a belt now and they hang off it,
    # across his front where the apron's woad is behind them.
    P.add(L.box(0.50, 0.30, 0.085), 'dark', loc=(MX + 0.08, MY - 0.14, 1.07))
    P.add(L.box(0.13, 0.09, 0.115), 'bone', loc=(MX + 0.02, MY - 0.30, 1.07))
    for (sx, sy, sz, r, slot) in ((MX - 0.17, MY - 0.33, 0.83, 0.108, 'body'),
                                  (MX + 0.05, MY - 0.36, 0.74, 0.096, 'bone'),
                                  (MX + 0.26, MY - 0.31, 0.86, 0.090, 'glow')):
        limb(P, [(sx, sy - 0.02, 1.05), (sx, sy, sz + r)], 0.018, 0.016, 'dark')
        P.add(L.sphere(r, r * 0.92, r * 0.88, 11, 8), slot, loc=(sx, sy, sz))
    _span("skeins", i0)

    # ------------------------------------------------- WHAT IT HAS ALREADY MARKED
    i0 = len(P.items)
    for (fx, fy, r, slot) in ((0.52, -1.16, 0.27, 'body'),
                              (-1.34, -0.74, 0.21, 'bone'),
                              (1.02, -0.30, 0.17, 'glow')):
        P.add(aim(L.cone(r, r * 0.96, 0.022, 20), (fx, fy, 0.014), (0.0, 0.0, 1.0)), slot)
    _span("splashes", i0)

    return P


BUILDERS.update({"dyer": dyer})


# ===========================================================================
# *** 25 THE GREENER, 17 Nov 2026. THE TRADE IS ON THE BODY, NOT ON THE
# *** FURNITURE AROUND IT - the team lead's 20:14 ask, in his words: "If a
# *** twenty-fifth can put the trade ON THE BODY rather than on the furniture
# *** around it, that is worth more to me than a twenty-fifth with better
# *** props." His own picture of the Dyer is the evidence: the frame and the
# *** tun carried that trade and the man beside them read as an armature.
# ===========================================================================
# AND IT ALSO ANSWERS A MEASURED GAP, WHICH IS WHY THIS TRADE AND NOT A
# PRETTIER ONE. _colour_read's own hue histogram over the register: 0-60 deg
# 14 bodies | 60-110 2 | 110-190 ZERO | 190-260 7 | 260-360 ZERO. The Dyer
# filled 190-260 with woad. NOTHING IN THIS FILE IS GREEN. A beekeeper was the
# first candidate and was dropped for exactly that reason - honey amber is the
# 0-60 band where fourteen bodies already sit, so it would have been a new body
# in an old colour. Verdigris is the one working-class trade whose PRODUCT is
# green: copper hung over vinegar, scraped off as pigment, and a man who has
# done it for twenty years is green to the elbow.
OVERRIDE_ALLOWED = {"dyer", "greener"}

OVERRIDE.update({
    "greener": {
        # verdigris. The product, and it is on HIM: the crust up both forearms,
        # the scabs across the chest and shoulders, the bloom on the crocks,
        # and the two weapons on the floor it has already eaten.
        'body': ((0.075, 0.470, 0.355), 0.62, 0.00),
        # BRIGHT NEW COPPER. The leaves on his back are the one thing in the
        # yard that is fresh - they are the stock he bought this week, and
        # Mr. E's second rule read as he wrote it: the goods must not look
        # second-hand even when the man does.
        # PASS 2, CHANGE E: at (0.735, 0.355, 0.135) rough 0.34 metal 0.62 the
        # leaves came back BROWN - a metal that dark under these two suns
        # reads as timber, and a stack of timber is not stock, it is a fence.
        # Brighter and less metallic so the diffuse term carries the hue.
        # PASS 4, CHANGE J: still read as PLYWOOD at (0.905, 0.470, 0.205)
        # rough 0.30. A hammered copper leaf is bright and it is SPECULAR -
        # the brown came from a diffuse-dominant surface, not from the hue.
        # Rough down and the hue carried further toward new copper.
        # PASS 5: one more step toward new copper, measured separately from
        # change K by _colour_read's band shares and not by impression.
        # PASS 6, AND IT IS NOT A FOURTH GO AT THE SAME THREE DIALS. Passes E,
        # J and 5 all pushed hue/rough/metal and all three came back timber.
        # tools/art/_metal_read.py measured WHY, against the CC0 KayKit dungeon
        # weapons as an outside bar: what makes a surface read as polished metal
        # here is a HIGHLIGHT THAT RUNS TO WHITE, and the four artist metals
        # measure 0.305-0.574 on that while these leaves measured 0.174 front /
        # 0.080 side - BELOW the matte-oak control at 0.209/0.133. Their bright
        # end was more pigmented than a plank's, which is "painted timber" said
        # as a number.
        # AND THE DIAL THE LANE KEPT REACHING FOR WAS BACKWARDS. In Principled a
        # METALLIC lobe is tinted by the base colour - a metal reflects its own
        # colour - so at metal 0.52 the highlight was half-orange and could never
        # run white, and the harder the lane pushed metallic the worse it got. A
        # near-black world (0.045,0.05,0.065) leaves a mirror nothing to reflect,
        # so the physically-correct copper control measured DARKER AND FLATTER
        # THAN OAK. Metallic is not a dial that buys a metal look in this rig; it
        # is one that spends it.
        # So: metallic DOWN to a lacquered-copper dielectric, the specular level
        # UP to 0.86 (white by construction), and roughness up off 0.13 so the
        # sun's ~0.5 deg disc makes a sheen with area instead of a glint smaller
        # than a pixel. Hue is NOT touched - it was never the fault.
        # PASS 7, measured separately from pass 6 and it is the SAME mechanism
        # taken one step further, not a new idea. Pass 6 moved the front read
        # from BELOW the oak control to above it (0.174 -> 0.230 against oak
        # 0.209) and left the side flat (0.080 -> 0.131 against oak 0.133). The
        # cause of the weakness is AREA: a SUN lamp is a ~0.5 degree disc, so at
        # roughness 0.26 the dielectric lobe is a glint a few pixels across on a
        # gently bowed sheet, and on the side view it mostly misses the leaves
        # altogether. A highlight that lands on nothing is not a highlight.
        # Roughness up spreads that lobe into a satin sheen with area - which is
        # also how the KayKit reference metals read, as broad painted highlight
        # bands rather than points. Hue still untouched across both passes.
        # PASS 9. The specular change of passes 6-7 is re-applied ON TOP OF the
        # pass-8 form, and re-applied only because the form change gives a real
        # reason to re-test it rather than a hope: on the flush panel every
        # sheet presented one angle, so one lobe either landed or did not; with
        # air between five sheets at five angles there are five chances for a
        # white sheen to catch an edge. MEASURED SEPARATELY ANYWAY - form alone
        # scored -0.132/-0.082/-0.172 (material unchanged, correctly), material
        # alone scored +0.158/+0.040/+0.008 on the old form.
        # PASS 10: the row gains a FIFTH element. The colour now comes off the
        # MESH (see _leaf / _leaf_vcol), and the rgb below is the FILL for the
        # one other piece of 'bone' geometry on this body - the scraper's
        # collar - which is painted exactly this and so renders unchanged.
        'bone': ((1.000, 0.520, 0.235), 0.44, 0.06, 0.92, True),
        # the man, his apron, the crock staves, the scraper's iron. NOT
        # derived from the body colour or the whole figure would read green
        # and the crust would stop being a mark on him.
        'dark': ((0.062, 0.058, 0.052), 0.84, 0.03),
        # the charcoal bed under the crocks. A vinegar house is WARMED - that
        # is the only honest emissive on this body, and it is kept small and
        # low so the green stays the creature's colour and the ember stays a
        # reason for the green to be visible at all.
        # PASS 3, CHANGE F, judged on its own: at (1.000, 0.455, 0.105)
        # strength 1.15 the charcoal bed came back BEIGE - it read as spilt
        # SAND around the crocks, which is worse than invisible because a
        # viewer names it wrongly instead of not at all. Deeper red and hotter.
        # Not pushed past 2.0: the Dyer's weld clipped to CREAM at 2.30 and a
        # white hole is not a hue either.
        # PASS 5: back to 1.45 now that the coals have a dark pan round them.
        # Strength was never the problem - see change K.
        'glow': ((1.000, 0.265, 0.035), 1.45),
    },
})

CANON.update({
    "greener": ("The Greener", 2.50, (0.12, 0.54, 0.40), (0.20, 0.92, 0.64),
                "workshop",
                "IT GREENS YOUR IRON - every blow landed on it leaves the "
                "weapon a little more eaten, and a bitten weapon bites less; "
                "a hero can stop and scrape it clean, which costs them the "
                "time they would have spent swinging, so the party is not "
                "choosing how to kill it but how long each of them can afford "
                "to keep hitting it",
                0.55, "Your edge came back green."),
})
ORDER = ORDER + ["greener"]


def _crust(P, pts, r0, r1, n=9, slot='body', seed=0.0):
    """A verdigris crust ALONG a limb: flattened nodules sitting proud of the
    member they grow on, not a recolour of it.

    This is the whole argument of the body, so it is geometry and not paint:
    the Dyer's arms were a TUBE in a second material, which reads as a sleeve.
    A crust has to break the silhouette or a viewer at stream distance cannot
    tell it from a coloured sleeve - so each nodule is an ellipsoid pushed out
    past the limb radius, and the sizes run unequal along the run because
    corrosion does.
    """
    for i in range(n):
        t = i / float(n - 1)
        a, b = Vector(pts[0]), Vector(pts[-1])
        if len(pts) > 2 and t > 0.5:
            a, b = Vector(pts[1]), Vector(pts[-1])
            t = (t - 0.5) * 2.0
        elif len(pts) > 2:
            b = Vector(pts[1])
            t = t * 2.0
        c = a + (b - a) * t
        rr = r0 + (r1 - r0) * t
        w = rr * (0.62 + 0.52 * abs(math.sin(i * 2.399 + seed)))
        th = i * 1.771 + seed
        # PASS 9: 0.72 -> 0.52. _colour_read counted a 435 px DETACHED
        # COMPONENT in the side view at mid-height, and the arithmetic says
        # why: at offset 0.72 x rr a nodule sits 0.09 m off the limb axis
        # while the SMALLEST nodules on the run are only 0.078 m across, so
        # the thin end of each run could clear the member it is supposed to be
        # growing on. A crust that floats is not a crust. This is the check
        # that caught the Dyer's eyes hanging in front of its face, doing the
        # same job again.
        off = Vector((math.cos(th), math.sin(th), 0.0)) * (rr * 0.52)
        P.add(L.sphere(w, w * 0.78, w * 0.54, 9, 6), slot,
              loc=(c.x + off.x, c.y + off.y, c.z), rot=(0.0, 0.0, th))


# ---------------------------------------------------------------- THE BAKED SHEEN
# The two SUN lamps the register renders under, as lordgen.render_views and
# _metal_read._rig build them: rotation_euler (55 deg, 0, ang), energy e. A sun
# emits along its own -Z, so the vector TO the light is -(Rz(ang) Rx(55) (0,0,-1)).
# DERIVED HERE FROM THOSE THREE NUMBERS rather than written down as a direction,
# so if the rig's lights ever move this follows them instead of lying.
_SUNS = ((55.0, 40.0, 3.4), (55.0, -120.0, 1.5))


def _sun_dirs():
    out = []
    for el, az, e in _SUNS:
        t, a = math.radians(el), math.radians(az)
        # Rx(t) @ (0,0,-1) = (0, sin t, -cos t); then Rz(a).
        y, z = math.sin(t), -math.cos(t)
        d = Vector((-y * math.sin(a), y * math.cos(a), z))      # travel
        out.append(((-d).normalized(), e))                      # toward the light
    return out


# COPPER_BODY is today's shipped leaf colour to three places, unchanged on
# purpose: the body of the sheet must not move, or this becomes a fourth go at
# the hue dial wearing a new hat. Only the two ENDS are new - a deep saturated
# shadow and a warm near-white sheen - which is the ramp the CC0 KayKit
# reference metals carry baked into their textures.
COPPER_BODY = (1.000, 0.520, 0.235)
COPPER_DEEP = (0.300, 0.125, 0.052)
# *** CHANGED 18 Nov 00:5x CT, ON THE _sheen_ab TABLE. WAS (1.000, 0.880, 0.820). ***
# The old value was a DIELECTRIC's highlight - authored saturation 0.180, very
# nearly a chalk wash - and SHEEN_MAX drives 86% of the way from the leaf body's
# 0.765 saturation to it. But copper is a CONDUCTOR: its highlight carries the
# light's colour times its OWN reflectance, not the light's colour alone. A
# dielectric's highlight runs to white; a metal's runs to its own tint. Painting
# a conductor with a dielectric's highlight is the same class of error as the
# metallic dial - a number borrowed from the wrong physics - and it is what made
# the side view read as a cream-painted board.
# THE NEW VALUE IS NOT A TASTE STEP AND HAS NO NUMBER OF MINE IN IT: it is
# _metal_read.CTRL['copper'], (0.955, 0.637, 0.538) - the measured reflectance
# of Cu this repo already uses as its physics control - normalised so its
# brightest channel is 1.0. Authored saturation 0.437.
# MEASURED, three views, against the unpainted shipped material and a matte oak,
# in renders/art/minibosses/_sheen_ab.json: side body_sat 0.3091 -> 0.4308,
# cream_share 0.4206 -> 0.2920, and hilite_desat 0.3086 -> 0.2783 which is still
# ABOVE both controls (oak 0.1603, unpainted 0.2173) - so the band still does the
# job it was baked for. Nothing regressed in any view.
COPPER_SHEEN = (1.000, 0.6670, 0.5634)
# how much of the sheen is allowed at full strength. Keeps the band off pure
# white: a copper highlight is warm, and a chalk-white streak is a different lie.
SHEEN_MAX = 0.86
# *** THE FIRST VERSION OF THIS RAMP WAS WRONG IN A WAY WORTH KEEPING ON THE
# *** RECORD, BECAUSE IT IS THE SAME MISTAKE CLASS AS THE METALLIC DIAL. ***
# It drove BOTH ends off `lit` - the surface's response to the two suns - so
# where a sheet faced away from the light the baked colour went dark. But THE
# RENDERER ALREADY DOES THAT: it shades every face by n.L itself. Baking a
# second shadow on top is double-counting, and it measured exactly like one -
# the back view's leaves went from median luminance 0.366 to 0.285 and its
# score barely moved (0.035 -> 0.086), because from behind you see the faces
# that are turned away from the main sun and I had darkened them twice. A rack
# of new stock going DARKER is also Mr. E's second rule broken: the goods must
# not read second-hand.
# SO THE RULE THIS RAMP NOW FOLLOWS: BAKE ONLY WHAT THE RENDERER CANNOT.
# The renderer can shade by the light angle, so the shadow end is driven by
# GEOMETRY ALONE - the foot of a sheet standing in a rack and the long edges
# where its neighbours overlap it, both of which are occlusion the two suns
# know nothing about. What the renderer cannot do here is a near-white
# highlight with AREA, because a half-degree sun in a near-black world gives a
# dielectric lobe no area to spread into - so that, and only that, is what the
# sheen band carries.
#
# AND THE BAND IS DRIVEN BY THE NEAREST SUN, NOT BY THE ENERGY-WEIGHTED SUM.
# Weighted by energy, the 1.5-energy fill sun can never drive a band, so the
# BACK of every sheet - which is most of what the back camera sees - could
# never carry one. max over suns of (n . L) asks "how squarely does this face
# its own best light", which both sides of a sheet can answer, and it is still
# a specular placement rather than my taste.
# calibrated against what this rack achieves on that drive: a near-vertical
# sheet's best possible (n . L) is the length of a sun's horizontal part,
# sqrt(0.5265^2 + 0.6275^2) = 0.819, the same for both suns because they share
# an elevation. Measured over all 300 leaf vertices: see _sheen_drive_dist in
# the run log. LO/HI sit near the top of that so the band lands on the sheets
# that face a sun and leaves the rest alone - a sheen on all five at once reads
# as paint, a sheen on two or three of five is what a rack of stock looks like.
SHEEN_LO, SHEEN_HI = 0.58, 0.80
# THE BOWED SHEET'S TESSELLATION. SEE _leaf. WAS 4,5 UNTIL 18 Nov 01:0x CT.
# THE PICTURE FOUND THIS, NOT A NUMBER. With the band's colour fixed, a 4x crop
# of the side view still showed a HARD-EDGED STRIPE: a sheen with square corners
# is not a sheen, it is a drip of paint, and no hue fixes that. The cause is
# arithmetic - vertex colours are interpolated across faces, so on a 4x5 grid the
# whole falloff has to be carried by FIVE COLUMNS. `_smooth` was being sampled
# too coarsely to be seen; the ramp's maths was never the problem.
# 8,10 AND NOT MORE, BECAUSE THE METRIC SATURATES THERE AND THAT IS THE EVIDENCE
# THE CAUSE WAS SAMPLING: side body_sat 0.4308 (4x5) -> 0.4930 (8x10) -> 0.4926
# (14x18), i.e. 14x18 buys nothing for 2850 verts against 990.
# THE SILHOUETTE DOES NOT MOVE AND THAT IS ASSERTED, NOT ASSUMED: every vertex
# still lies on the same analytic bowed surface, and the body's world bounds are
# identical across all three arms to 1e-6 (renders/art/minibosses/_sheen_grid_ab.json).
LEAF_NX, LEAF_NZ = 8, 10
# the geometric occlusion end. SHADE_FLOOR is how far toward COPPER_DEEP the
# most-occluded point goes; it is deliberately shallow, because this is contact
# shadow between stacked sheets and not a lighting term.
SHADE_FLOOR = 0.42


def _smooth(x, lo, hi):
    if hi <= lo:
        return 0.0 if x < lo else 1.0
    t = min(1.0, max(0.0, (x - lo) / (hi - lo)))
    return t * t * (3.0 - 2.0 * t)


def _leaf_vcol(nx, nz, w, h, thick, yaw, pitch):
    """ONE RGB PER VERTEX for a bowed leaf, in the same order _leaf builds them:
    the whole front grid, then the whole back grid.

    THE BAND IS PLACED BY THE RIG'S LIGHTS, NOT BY ME. For each vertex the
    analytic surface normal of the bowed sheet is rotated the way the leaf is
    rotated and taken against the two suns; the sheen rides where the sheet
    FACES the dominant sun, which is where a texture artist paints it and where
    a real sheet throws it. That is why this takes yaw and pitch: the five
    leaves are fanned, so each one's band lands somewhere different, which is
    the whole reason the rack reads as five sheets and not one painted board.

    It is baked for the LIGHT and not for a camera, deliberately. A band baked
    for the front camera would be wrong in the side and back views, and the
    register demands all three.
    """
    suns = _sun_dirs()
    rot = (Matrix.Rotation(yaw, 4, 'Z') @ Matrix.Rotation(pitch, 4, 'X')).to_3x3()
    out = []
    for side in (0, 1):          # 0 = front sheet, 1 = the +thick copy
        for iz in range(nz + 1):
            tz = iz / float(nz)
            for ix in range(nx + 1):
                tx = ix / float(nx)
                # the sheet is Y = 0.085 sin(pi tx)(0.45 + 0.55 tz); its two
                # tangents give the normal without a mesh lookup.
                dtx = Vector((w, 0.085 * math.pi * math.cos(math.pi * tx)
                              * (0.45 + 0.55 * tz), 0.0))
                dtz = Vector((0.0, 0.085 * math.sin(math.pi * tx) * 0.55, h))
                n = dtx.cross(dtz)
                if n.length < 1e-9:
                    n = Vector((0.0, -1.0, 0.0))
                n.normalize()
                if (n.y > 0.0) != (side == 1):
                    n = -n                      # front faces -Y, back faces +Y
                n = (rot @ n).normalized()
                # how squarely this face meets its OWN best sun. Energy is
                # deliberately not in it - see the note above SHEEN_LO.
                drive = max(max(0.0, n.dot(Ld)) for Ld, _e in suns)
                band = _smooth(drive, SHEEN_LO, SHEEN_HI)
                # OCCLUSION, GEOMETRY ONLY. The foot of a sheet standing in a
                # rack is shadowed by its neighbours, and so are its two long
                # edges where the next sheet overlaps it. Neither is something
                # the two suns can know, which is why these are baked and the
                # light-angle shading is left to the renderer.
                foot = 0.30 + 0.70 * min(1.0, tz / 0.42)
                edge = 0.55 + 0.45 * math.sin(math.pi * min(1.0, max(0.0, tx)))
                occ = min(1.0, foot * edge)
                a = SHADE_FLOOR + (1.0 - SHADE_FLOOR) * occ
                c = [COPPER_DEEP[k] + (COPPER_BODY[k] - COPPER_DEEP[k]) * a
                     for k in range(3)]
                f = band * SHEEN_MAX
                out.append(tuple(c[k] + (COPPER_SHEEN[k] - c[k]) * f
                                 for k in range(3)))
    return out


def _leaf(P, cx, cy, cz, yaw, pitch, w=0.52, h=0.68, slot='bone', thick=0.016):
    """One hammered copper sheet, bowed. Flat planes vanish edge-on - the
    Pressman fault, and the Dyer's answer was a bow in the hanging axis. These
    are bowed in their own normal and FANNED in yaw for the same reason.

    PASS 10, 18 Nov, AND IT IS THE CHANGE METAL_READ.md NAMED AS CANDIDATE 1.
    Nine passes said the material cannot get there with dials: a near-black
    world gives a mirror nothing to reflect and a half-degree sun gives a
    dielectric lobe no area, so the highlight that names a surface as metal
    cannot be produced by a BSDF here at all. The reference metals do not
    produce it either - they CARRY it, painted into the texture. So the sheen is
    BAKED INTO THE MESH as a vertex-colour ramp, which is local to this one body
    and re-lights nothing: the alternative, giving the rig something to reflect,
    moves all 25 bodies and every colour number the register has measured, and
    that is a team-lead call, not mine.
    """
    V, F = [], []
    # THE LEAF'S GRID, LIFTED TO A MODULE CONSTANT 18 Nov SO IT CAN BE SWEPT.
    # The DEFAULT IS THE SHIPPED 4,5 EXACTLY, so every body built without
    # touching it is byte-identical to yesterday's. It is a constant and not an
    # argument because the sweep that needs it patches the module, and an
    # argument would have had to be threaded through five call sites in
    # greener() where a typo would silently re-tessellate one leaf of five.
    nx, nz = LEAF_NX, LEAF_NZ
    for iz in range(nz + 1):
        tz = iz / float(nz)
        for ix in range(nx + 1):
            tx = ix / float(nx)
            lx = (tx - 0.5) * w
            lz = (tz - 0.5) * h
            ly = 0.085 * math.sin(math.pi * tx) * (0.45 + 0.55 * tz)
            V.append((lx, ly, lz))
    k = nx + 1
    base = len(V)
    V = V + [(x, y + thick, z) for (x, y, z) in V]
    for iz in range(nz):
        for ix in range(nx):
            a0 = iz * k + ix
            F.append((a0, a0 + 1, a0 + k + 1, a0 + k))
            b0 = base + a0
            F.append((b0 + k, b0 + k + 1, b0 + 1, b0))
    for ix in range(nx):
        F.append((ix, base + ix, base + ix + 1, ix + 1))
        b0 = nz * k + ix
        F.append((b0 + 1, base + b0 + 1, base + b0, b0))
    for iz in range(nz):
        l0 = iz * k
        F.append((l0 + k, base + l0 + k, base + l0, l0))
        r0 = iz * k + nx
        F.append((r0, base + r0, base + r0 + k, r0 + k))
    vc = _leaf_vcol(nx, nz, w, h, thick, yaw, pitch)
    assert len(vc) == len(V), "leaf vcol %d vs %d verts" % (len(vc), len(V))
    P.add(([Vector(v) for v in V], F), slot, loc=(cx, cy, cz),
          rot=(pitch, 0.0, yaw), vcol=vc)


def _crock(P, cx, cy, r, h, bloom=True):
    """A vinegar crock: staves, two hoops, and the green bloom on its shoulder
    where the copper hangs. The bloom is 'body' - the same material as the
    crust on him, because it is the same stuff."""
    for j in range(12):
        th = TAU * j / 12.0
        sx, sy = cx + r * math.cos(th), cy + r * math.sin(th)
        P.add(L.box(0.17, 0.085, h), 'dark', loc=(sx, sy, h * 0.5),
              rot=(0.0, 0.0, th + math.pi * 0.5))
    for z in (h * 0.22, h * 0.82):
        ring = [Vector((cx + (r + 0.028) * math.cos(TAU * i / 20.0),
                        cy + (r + 0.028) * math.sin(TAU * i / 20.0), z))
                for i in range(21)]
        P.raw(L.tube(ring, 0.030, 6), 'dark')
    if bloom:
        for j in range(7):
            th = TAU * j / 7.0 + 0.4
            bx, by = cx + r * 0.92 * math.cos(th), cy + r * 0.92 * math.sin(th)
            P.add(L.sphere(0.072, 0.062, 0.040, 9, 6), 'body',
                  loc=(bx, by, h * 0.96))


def greener():
    """IT GREENS YOUR IRON.

    A greener hangs copper over vinegar and scrapes the green off it. This one
    does it to your weapons. Every blow landed on it leaves the edge a little
    more eaten and a bitten weapon bites less; a hero can stop and scrape,
    which costs them the swings they would have taken. So the party is not
    choosing how to kill it - each of them is choosing how long they can
    afford to keep hitting it, and the scraping is a cost they pay themselves.

    WHY IT IS NOT ONE OF THE TWENTY-FOUR, and this was checked by PARSING
    CANON in this file rather than by remembering it - 38 entries, 24 distinct
    bodies. The set summons, re-plates itself, drags one out of the line,
    douses the lamps, rises from its graves, bars the door, steals gear, heals
    the room, floods it, sows thorns, pre-sets traps, scales with the fire,
    throws its voice, sets the floor, splits in two, arms the other monsters,
    loads you down, cuts the party in half, learns the blow you used, takes the
    haul, drinks the brews, collars your fallen, strikes the party level, and
    marks one hero and hunts the mark. NOTHING IN THAT LIST TOUCHES THE
    WEAPON ITSELF, which is the one object a viewer has actually paid points
    for, and that is the whole reason this one is worth building.
    TWO ADJACENCIES NAMED RATHER THAN DENIED: the Tanner also answers your
    blows, but it changes ITSELF - it pegs a fresh hide against the damage you
    repeated, and your sword is untouched when you walk out. The Scrapwright
    also degrades a thing over the fight, but the thing it degrades is its own
    shell. This one is the only one whose arithmetic happens on the hero's
    side of the fight, and the only one a hero can undo by spending time.

    *** THE TRADE IS ON THE BODY. THAT IS THE ROW AND IT IS THE WHOLE BUILD. ***
    The lead's read of the Dyer was that the frame and the tun carried the
    trade and the man beside them read as a dark armature. So this body has
    almost no furniture: TWO low crocks and a charcoal bed on the ground, and
    everything else that says GREENER is growing on him. The crust runs up
    both forearms and across the chest and shoulders as nodules that stand
    PROUD of the member - geometry, not a second material on a smooth tube,
    because a coloured tube reads as a sleeve at stream distance. The copper
    leaves ride on his own back. The scraper is in his hands, placed off one
    defined line so the grip cannot drift. The two weapons he has already
    eaten lie at his feet.

    *** AND THE COLOUR FILLS A MEASURED HOLE, WHICH IS WHY THIS TRADE. ***
    _colour_read over the register: 110-190 degrees held by ZERO bodies before
    this one. Verdigris is 110-190 by construction. The bright copper on his
    back is the complement and is the SECOND band, so the body holds two hues
    the way the Dyer does, and it holds them for the same reason - the product
    and the stock are different things and a yard shows both.

    WEAR 0.55 AND IT IS SPLIT AGAIN: the man, his apron, the crock staves and
    the scraper's iron are eaten and old; the copper LEAVES are new, bright
    and barely rough, because they are the stock he bought this week. The
    crust takes its colour from OVERRIDE and skips the dulling, because a
    corrosion bloom is not a worn thing - it is this week's growth.

    FRAMES: every number here is in BLENDER'S WORLD FRAME as written into the
    .glb - front is model -Y, up is +Z. That is NOT the engine's slot frame;
    nothing here converts to a Godot rotation.

    FOUR MESHES, four slots, four materials. The cap is untouched.

    Static: a `model` path and no `anims` entry.
    """
    P = Parts("greener")
    P.spans = {}
    P.used_pack = False
    P.pack_caps = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX, MY = -0.10, -0.30
    HIP, SH, HEAD = 0.96, 1.56, 1.90

    # THE SCRAPER'S LINE, DEFINED FIRST so both hands read off it and cannot
    # drift when the shaft moves - the Dyer's change G, kept as a standing
    # habit. It travels in X AND Y AND Z: the front camera gets a diagonal out
    # of X, the side camera gets one out of Y. A shaft that only travels in X
    # is a vertical post from the side, which is the Pressman fault.
    _SB = Vector((MX - 1.18, MY - 1.02, 2.26))
    _SE = Vector((MX + 0.86, MY + 0.52, 0.42))

    def _SCRAPE(t):
        v = _SB + (_SE - _SB) * t
        return (v.x, v.y, v.z)

    # ------------------------------------------------- THE MAN
    i0 = len(P.items)
    for s in (-1, 1):
        limb(P, [(MX + s * 0.18, MY + 0.04, HIP), (MX + s * 0.22, MY - 0.06, 0.50),
                 (MX + s * 0.24, MY - 0.14, 0.09)], 0.102, 0.084, 'dark')
        P.add(L.box(0.26, 0.40, 0.11), 'dark', loc=(MX + s * 0.24, MY - 0.22, 0.058))
    # leaning forward over the work, not posing
    limb(P, [(MX, MY + 0.10, 0.88), (MX + 0.04, MY - 0.02, 1.22),
             (MX + 0.10, MY - 0.14, SH)], 0.238, 0.246, 'dark')
    for s in (-1, 1):
        P.add(L.sphere(0.118, 0.110, 0.100, 11, 8), 'dark',
              loc=(MX + 0.10 + s * 0.258, MY - 0.14, SH + 0.03))
    P.add(L.sphere(0.136, 0.152, 0.152, 14, 9), 'dark', loc=(MX + 0.12, MY - 0.18, HEAD))
    # a flat cap. A tradesman, not a helm - and the Dyer's eye lesson applied:
    # the head's own forward offset is in `loc`, so `fwd` here is the ONLY
    # forward term. Passing both put the Dyer's eyes 0.23 m off his face.
    P.add(aim(L.cone(0.212, 0.192, 0.034, 14), (MX + 0.12, MY - 0.20, HEAD + 0.148),
              (0.0, -0.14, 1.0)), 'dark')
    eyes(P, (MX + 0.12, MY - 0.18, HEAD), 0.052, 0.026, -0.136)
    # THE ARMS. Upper arm is the man; the FOREARM is where the trade lives, so
    # the member stays 'dark' and the crust grows on it below.
    for s, t in ((-1, 0.285), (1, 0.525)):
        hx, hy, hz = _SCRAPE(t)
        sx = MX + 0.10 + s * 0.258
        mid = ((sx + hx) * 0.5, (MY - 0.14 + hy) * 0.5 - 0.05, (SH + hz) * 0.5 + 0.03)
        P.raw(L.tube([(sx, MY - 0.14, SH + 0.01), mid], [0.092, 0.074], 8), 'dark')
        P.raw(L.tube([mid, (hx, hy, hz)], [0.074, 0.056], 8), 'dark')
        P.add(L.sphere(0.076, 0.070, 0.066, 9, 7), 'dark', loc=(hx, hy, hz))
    # the apron - leather, eaten, and NOT green. The green is on the skin.
    # PASS 2, CHANGE C: at 0.52 x 0.84 the apron was the largest single mass
    # on the figure and it covered the chest crust, the belt line and both
    # thighs - a black slab where the trade was supposed to be. Cut to
    # 0.40 x 0.60 and raised, so it still says LEATHER AND WORK and the green
    # on him is no longer behind it.
    P.add(L.box(0.40, 0.09, 0.60), 'dark', loc=(MX + 0.04, MY - 0.30, 1.00),
          rot=(0.10, 0.0, 0.0))
    _span("man", i0)

    # ------------------------------------------------- THE CRUST: THE TRADE
    i0 = len(P.items)
    for s, t in ((-1, 0.285), (1, 0.525)):
        hx, hy, hz = _SCRAPE(t)
        sx = MX + 0.10 + s * 0.258
        mid = (((sx + hx) * 0.5), ((MY - 0.14 + hy) * 0.5 - 0.05), ((SH + hz) * 0.5 + 0.03))
        # PASS 8: nodules up from 0.086/0.062 over 7 to 0.125/0.095 over 11,
        # and the upper arm takes it too. A crust that reads at 4% of the
        # silhouette is a detail; the row asked for the trade to be ON him.
        _crust(P, [mid, (hx, hy, hz)], 0.125, 0.095, n=11, seed=1.7 * s)
        sx2 = MX + 0.10 + s * 0.258
        _crust(P, [(sx2, MY - 0.14, SH + 0.01), mid], 0.120, 0.100, n=7,
               seed=0.9 * s)
    # across the chest and the shoulders, where a man carries wet plates
    # PASS 8: more of them and bigger, and they come down onto the thigh -
    # a man who carries wet plates has it wherever the plates touch him.
    for (cx, cy, cz, r) in ((MX - 0.19, MY - 0.27, 1.32, 0.136),
                            (MX + 0.05, MY - 0.31, 1.42, 0.148),
                            (MX + 0.26, MY - 0.25, 1.26, 0.126),
                            (MX - 0.11, MY - 0.29, 1.13, 0.120),
                            (MX + 0.15, MY - 0.30, 1.36, 0.110),
                            (MX - 0.02, MY - 0.28, 1.19, 0.104),
                            (MX + 0.32, MY - 0.16, SH + 0.02, 0.130),
                            (MX - 0.16, MY - 0.14, SH + 0.04, 0.122),
                            (MX + 0.08, MY - 0.22, SH + 0.08, 0.098),
                            (MX - 0.25, MY - 0.22, 0.86, 0.112),
                            (MX + 0.27, MY - 0.24, 0.80, 0.104),
                            (MX - 0.20, MY - 0.24, 0.72, 0.092)):
        P.add(L.sphere(r, r * 0.74, r * 0.52, 9, 6), 'body', loc=(cx, cy, cz))
    # PASS 3, CHANGE H: from the side and the back the chest crust is behind
    # his own arm and apron, so the trade was carried by two forearm runs
    # alone in those views. A man who carries wet plates on his back has it
    # on his shoulder blades, which is both true and the view that needed it.
    for (bx, bz, r) in ((-0.20, 1.38, 0.124), (0.14, 1.30, 0.116),
                        (-0.04, 1.50, 0.104), (0.22, 1.12, 0.094),
                        (-0.26, 1.16, 0.088)):
        P.add(L.sphere(r, r * 0.72, r * 0.50, 9, 6), 'body',
              loc=(MX + bx, MY + 0.06, bz))
    # and up the jaw - a greener's face takes it too
    for (jx, jz, r) in ((-0.075, HEAD - 0.10, 0.068), (0.095, HEAD - 0.12, 0.062),
                        (0.00, HEAD - 0.17, 0.056)):
        P.add(L.sphere(r, r * 0.80, r * 0.62, 8, 6), 'body',
              loc=(MX + 0.12 + jx, MY - 0.285, jz))
    _span("crust", i0)

    # ------------------------------------------------- THE STOCK ON HIS BACK
    i0 = len(P.items)
    # a rack of five hammered leaves, fanned so no two are edge-on at once
    # PASS 2, CHANGE D: at z 1.34 the rack sat BEHIND the torso and read as a
    # brown fence panel with its top edge below his shoulders - it neither
    # broke the silhouette nor looked like metal. It rides higher and the fan
    # is widened, so the top corners of the leaves clear the shoulder line and
    # the stack is read as a stack from both cameras.
    # PASS 3, CHANGE G, AND IT IS A FLOAT THE SIDE CAMERA FOUND. At MY + 0.32
    # the rack stood in CLEAR AIR behind his back - a stack of plates carried
    # by nobody, which is the Dyer's pass-3 paddle fault wearing a different
    # shape. It comes in to MY + 0.17 so it rides ON him, and it slides to his
    # LEFT: at centre it stood directly behind his head in the front view and
    # made a brown backdrop for the one small dark thing a viewer has to read.
    # PASS 4: the fan was symmetrical about the camera's own axis, so the
    # middle leaves faced the front camera flat-on and the stack read as ONE
    # board. The fan is swung round and each leaf gets its own pitch, so no
    # two leaves present the same angle to either camera and the stack is read
    # as a stack - the Drillmaster's lesson, that a symmetrical thing reads as
    # wallpaper.
    # PASS 8, AND IT IS THE FIRST PASS ON THIS FAULT THAT IS NOT ABOUT THE
    # MATERIAL. Three goes at hue/rough/metal (E, J, 5) and two more at the
    # specular lobe all failed, and the A/B render is why I stopped: the best
    # the material could do was trade a stained plank for raw cardboard.
    # LOOKING AT THE TWO SHEETS SIDE BY SIDE NAMED THE REAL CAUSE, which no
    # number had: at w 0.46 on a 0.095 pitch these five leaves OVERLAP BY
    # ABOUT 80%. They do not read as five sheets, they read as ONE SOLID
    # PANEL whose only internal detail is the seams between them - and a flat
    # rectangle with evenly spaced vertical grooves is a crate side. That is
    # what a viewer was naming. It was never the colour.
    # Pass 4 already tried to break this with YAW, and yaw cannot help when
    # the sheets are flush: it rotates boards that still have no air between
    # them. So the pitch goes out to 0.175 - each leaf now shows a strip of
    # itself and a gap of shadow beside it - the widths and heights VARY per
    # leaf, and the tops are staggered in Z so the rack's top edge is ragged
    # rather than one straight board line. Narrower sheets with air between
    # them read as stock leaning in a rack; a flush stack reads as a pallet.
    for i, (yaw, wi, hi, dz) in enumerate(
            ((-0.86, 0.34, 0.76, 0.00), (-0.52, 0.29, 0.62, 0.09),
             (-0.20, 0.36, 0.82, -0.05), (0.14, 0.28, 0.58, 0.12),
             (0.48, 0.33, 0.70, 0.02))):
        _leaf(P, MX - 0.26 + (i - 2) * 0.175, MY + 0.17 + abs(i - 2) * 0.034,
              1.55 + dz, yaw, 0.10 + 0.07 * ((i % 3) - 1), w=wi, h=hi)
    # the strap that holds them on him
    P.raw(L.tube([(MX - 0.34, MY + 0.10, SH + 0.02), (MX + 0.06, MY - 0.26, 1.22),
                  (MX + 0.28, MY + 0.10, SH - 0.02)], [0.030, 0.034, 0.030], 7), 'dark')
    _span("plates", i0)

    # ------------------------------------------------- THE CROCKS AND THE BED
    i0 = len(P.items)
    # PASS 2, CHANGE A, AND IT IS THE DYER'S CHANGE K MADE AGAIN BY ME. At
    # r 0.40 / h 0.58 the two crocks were a BLACK DRUM across the bottom third
    # of both pictures - from the side the man stood behind a wall of staves
    # with his legs gone, which is the exact silhouette the Dyer's vat had to
    # be cut twice to escape, and the exact silhouette the Tapster already
    # owns. They come down to 0.24 and 0.19 radius and go BACK, so they are a
    # working man's crocks at his heel and not the thing you name him by.
    # PASS 6: shifted clear of the fire basket that change L puts at
    # (MX+1.14, MY+0.52) - two solids in one place is a modelling fault, not
    # a yard.
    # PASS 7: the second crock goes. Change L's fire basket put a THIRD
    # object in the yard and the footprint went 3.19 -> 3.66 m, which is the
    # row's own fault creeping back in - the lead asked for the trade on the
    # BODY, and a yard that grows is furniture competing with the man again.
    # One crock with the copper hanging over it says the trade; two said it
    # twice.
    # *** PASS 8, AND THE INSTRUMENT OVERTURNED MY OWN PICTURE. ***
    # _trade_read on pass 7: crust 0.0439 of the front silhouette, plates
    # 0.1518, crocks 0.1129, brazier 0.1809. THE YARD WAS CARRYING 44% AND THE
    # TRADE ON THE MAN WAS CARRYING FOUR PER CENT - which is precisely the
    # fault the lead asked this body to fix, measured on my own build while I
    # was looking at the picture and calling it fixed. And minibossfit went
    # RED at the same time: pair_w 5.61 against a 5.60 m frame.
    # One cause, two reports. THE CROCK GOES ALTOGETHER. A greener with a fire
    # and copper over it is a greener; the crock was the third way of saying
    # the same sentence, and it cost 1.13 m of footprint to say it.
    pass
    _span("crocks", i0)

    i0 = len(P.items)
    # the charcoal bed under them: an ember field, low and small. The only
    # emissive on this body, and it is there because a vinegar house is warmed.
    # *** PASS 2, CHANGE B. I CAPPED MY OWN EMISSIVE AGAIN. *** Pass 1 put the
    # ember discs UNDER the crocks at r 0.30 and 0.25 against crock radii of
    # 0.40 and 0.33 - so the only light on this body was inside a ring of
    # staves and no eye-level camera could see one pixel of it. The render
    # said ok:true, 0 blanks, 0 clips, because a HIDDEN thing is not a blank
    # one. That is this lane's trap 5, written in my own prompt, committed for
    # the second time in two bodies.
    # THE FIX IS ALSO THE TRUER THING, same as the Dyer's brimming vat: a
    # charcoal bed is WIDER than the crock standing on it, and what you see
    # of it is the ring of ember GROUND around the foot. So the bed is drawn
    # proud of the crock, not under it, and three more coals lie in clear
    # floor between him and the crocks where nothing can hide them.
    # PASS 4, CHANGE I. The wide disc was the wrong SHAPE for an emissive and
    # change F could not save it: a flat 0.40 m plate of unshaded orange on
    # the floor plane reads as a PEACH PUDDLE, and a hotter colour only made
    # the puddle brighter. A charcoal bed is not a pool of light, it is a ring
    # of burning lumps round the crock's foot - so it is drawn as lumps, which
    # catch the two suns and shade like objects instead of flooding flat.
    # *** PASS 6, CHANGE L. I HAVE NOW HIDDEN MY OWN FIRE THREE TIMES IN ONE
    # *** BODY AND THE PATTERN IS THE FINDING, NOT THE PIXELS.
    # Pass 2 put the bed UNDER the crocks (invisible). Pass 3 made it hotter
    # and wider (a peach puddle). Pass 4 made it lumps on open floor (peaches).
    # Pass 5 gave it a dark pan - and the pan's own rim, at this 2 degree
    # camera pitch, closed over the coals exactly the way the Dyer's cone lid
    # closed over its vat. THE THING I KEPT GETTING WRONG IS NOT COLOUR,
    # STRENGTH, SIZE OR CONTRAST: IT IS HEIGHT. An eye-level camera cannot see
    # INTO anything lying on the floor plane, so no floor-level emissive in
    # this register can ever be seen, however it is dressed.
    # SO THE FIRE COMES OFF THE FLOOR, and it is truer there too: a vinegar
    # house is WARMED, and a warming fire lives in a basket on legs at hip
    # height, not in a dish on the ground. The coals are heaped PROUD of the
    # rim, so what the camera sees is the heap and not the inside of a bowl.
    BX, BY, BZ = MX + 0.92, MY + 0.44, 0.78      # PASS 8: in, off the frame edge
    for j in range(3):                      # three legs, splayed
        th = TAU * j / 3.0 + 0.5
        limb(P, [(BX + 0.26 * math.cos(th), BY + 0.26 * math.sin(th), 0.03),
                 (BX + 0.10 * math.cos(th), BY + 0.10 * math.sin(th), BZ - 0.06)],
             0.040, 0.032, 'dark')
    for j in range(14):                     # the basket's staves
        th = TAU * j / 14.0
        P.add(L.box(0.055, 0.045, 0.24), 'dark',
              loc=(BX + 0.30 * math.cos(th), BY + 0.30 * math.sin(th), BZ + 0.06),
              rot=(0.0, 0.0, th))
    ring = [Vector((BX + 0.315 * math.cos(TAU * i / 22.0),
                    BY + 0.315 * math.sin(TAU * i / 22.0), BZ + 0.17))
            for i in range(23)]
    P.raw(L.tube(ring, 0.034, 6), 'dark')
    for (ux, uy, uz, rr) in ((0.00, 0.00, 0.26, 0.105), (-0.17, 0.08, 0.20, 0.082),
                             (0.16, -0.06, 0.21, 0.088), (0.04, 0.17, 0.19, 0.074),
                             (-0.06, -0.17, 0.20, 0.078), (0.19, 0.14, 0.17, 0.066),
                             (-0.19, -0.05, 0.18, 0.070)):
        P.add(L.sphere(rr, rr * 0.94, rr * 0.80, 9, 7), 'glow',
              loc=(BX + ux, BY + uy, BZ + uz))

    _span("brazier", i0)

    # ------------------------------------------------- THE SCRAPER
    i0 = len(P.items)
    b, e = _SCRAPE(0.0), _SCRAPE(1.0)
    P.raw(L.tube([b, _SCRAPE(0.5), e], [0.038, 0.046, 0.044], 8), 'dark')
    P.add(L.sphere(0.056, 0.056, 0.048, 9, 6), 'dark', loc=b)
    # the blade: copper, so it does not corrode in his own hand
    P.add(L.box(0.30, 0.10, 0.22), 'bone', loc=(e[0] + 0.03, e[1] + 0.04, e[2] - 0.10),
          rot=(0.18, -0.22, 0.0))
    # a curl of scraped green coming off the blade
    for i in range(3):
        P.add(L.sphere(0.056 - i * 0.010, 0.046, 0.030), 'body',
              loc=(e[0] + 0.10 + i * 0.07, e[1] + 0.10 + i * 0.05, e[2] - 0.20 - i * 0.07))
    _span("scraper", i0)

    # ------------------------------------------------- WHAT IT HAS ALREADY EATEN
    i0 = len(P.items)
    # a sword and an axe head on the floor, gone green. The Scrapwright's two
    # spare plates and the Dyer's three splashes - the evidence it has done
    # this before, told in the silhouette and not in a stat.
    P.raw(L.tube([(MX - 1.02, MY - 0.44, 0.045), (MX - 0.46, MY - 0.64, 0.045)],
                 [0.034, 0.026], 6), 'dark')
    P.add(L.box(0.13, 0.10, 0.06), 'dark', loc=(MX - 1.09, MY - 0.42, 0.048))
    for i in range(4):
        P.add(L.sphere(0.052, 0.040, 0.030, 8, 6), 'body',
              loc=(MX - 0.94 + i * 0.14, MY - 0.49 - i * 0.050, 0.072))
    P.add(aim(L.cone(0.19, 0.055, 0.055, 12), (MX + 0.44, MY - 1.02, 0.040),
              (0.0, 0.0, 1.0)), 'dark')
    for i in range(3):
        P.add(L.sphere(0.058, 0.046, 0.032, 8, 6), 'body',
              loc=(MX + 0.36 + i * 0.10, MY - 1.06 + i * 0.05, 0.070))
    _span("taken", i0)

    return P


BUILDERS.update({"greener": greener})


# ===========================================================================
# 26. THE MOULDER - *IT TAKES YOUR SHAPE*
# ===========================================================================
# WHY THIS IDEA AND NOT A TWENTY-SIXTH COAT OF AN OLD ONE - PARSED, NOT
# REMEMBERED. CANON carries 25 idea strings. I read all 25 out of the file and
# grepped the register's own doc: "reflect", "returns the blow", "takes your
# shape", "copy" - ZERO hits. The mechanic CLASSES already spent are:
#   summoning (drillmaster: the garrison | quartermaster: arms the room)
#   self-defence (scrapwright re-plates | tanner adapts | sexton re-rises)
#   positioning (porter bars | hurdleman splits the room | snarer pre-sets it |
#               boiler sets the floor | sluicekeeper floods it | sower thorns it)
#   your gear (tallyman takes it | greener eats it | loader weighs it |
#               reeve takes the haul | tapster drinks your brews)
#   perception (snuffer dark | bellman misdirection)
#   scaling (stoker fire-bound | strickler levels your best down)
#   targeting (dyer marks one | gaoler drags one)
#   the fallen (pressman stands them up on its side)
#   itself (jointer comes apart)
#   the room's health (cook heals it)
# NOTHING IN THE SET MAKES THE PARTY FIGHT ITSELF, and that is the one empty
# class: the threat is AUTHORED BY THE PLAYERS. It is NOT the Drillmaster or the
# Quartermaster - those call or arm the room's OWN monsters, and the party has
# no say in what turns up. Here the party decides what it is fighting the
# moment it decides who swings first. It is not the Jointer either: the Jointer
# halves ITSELF, and neither half is anybody's hero.
#
# THE TRADE IS PLAIN AND IT IS REAL WORK: a sand-caster. A founder rams a bed,
# presses a pattern into it, pours, and what comes out is the pattern again in
# metal. The creature does that to a HERO. Bellmire's register is working-class
# stoicism and nothing here is theatrical: a box of sand, a rammer, a crucible
# on a shank, a pour, and the thing standing up in the box.
#
# WEAR IS A VARIABLE AND THIS ONE IS DERIVED, NOT CHOSEN. The man is old
# (0.80 - burnt leather, soot, iron handled daily); the mould furniture is
# REMADE FOR EVERY CAST, so it is almost new (0.10), and Mr. E's second rule
# says the goods must not read second-hand. The CANON scalar below is the
# SURFACE-AREA-WEIGHTED MEAN of those two, measured off the merged mesh by
# tools/art/_moulder_wear.py - see docs/art/MINIBOSSES.md. It is not a taste
# number and I did not pick it.
OVERRIDE_ALLOWED = set(OVERRIDE_ALLOWED) | {"moulder"}

OVERRIDE.update({
    "moulder": {
        # THE MAN. Burnt leather and soot - the darkest body in the register on
        # purpose, because every silhouette problem this lane has shipped was a
        # dark creature against its own dark furniture (the Greener's head
        # vanishing from the side is the live one). Here the man is DARK and
        # the thing behind him is PALE, so his outline is carried by contrast
        # and not by a rim light I would have to invent.
        'body': ((0.072, 0.056, 0.046), 0.88, 0.02),
        # THE CAST, AND THE CASTINGS ALREADY HUNG UP. The one bright thing on
        # the body, and it is the thing the party is about to be hit by.
        # THE GREENER'S MEASURED LESSON IS APPLIED HERE RATHER THAN
        # REDISCOVERED: in this rig metallic is a dial that SPENDS a metal look
        # (a metallic lobe is tinted by base colour and can never run white,
        # and a near-black world leaves a mirror nothing to reflect). So this
        # is a lacquered DIELECTRIC - metal low, specular level 0.86, roughness
        # off the floor so the sun's ~0.5 deg disc makes a sheen with AREA
        # instead of a glint smaller than a pixel. _metal_read is the judge.
        'bone': ((0.780, 0.762, 0.720), 0.30, 0.06, 0.86),
        # THE SAND AND THE FLASK. The slot is named 'dark' and the colour is
        # PALE, which looks wrong in a diff and is the whole point: rammed
        # foundry sand is grey-buff, it is new every cast, and it is the
        # background the man has to read against.
        'dark': ((0.262, 0.238, 0.206), 0.92, 0.00),
        # THE POUR. The only honest emissive here - metal at pouring heat.
        # Kept at 1.6: the Dyer's weld clipped to CREAM at 2.30 and a white
        # hole is not a hue, and the Greener settled at 1.45 for the same
        # reason. A pour is hotter than a charcoal bed, so one step above it.
        # PASS 2, AND IT IS THE A/B's NUMBER, NOT MY TASTE.
        # tools/art/_moulder_glow_ab.py swept strength against hue and measured
        # the pour's own pixels (the with/without diff, source stratum only).
        # SATURATION IS MONOTONE IN STRENGTH AND THE LOSS IS LARGE:
        #   1.60 (0.425,0.105) -> sat 0.349   KEPT 39% of the authored 0.895
        #   1.45 (0.265,0.035) -> sat 0.510   kept 53%
        #   1.30 (0.210,0.025) -> sat 0.577   kept 59%
        #   1.10 (0.180,0.020) -> sat 0.648   kept 66%
        #   0.80 (0.120,0.012) -> sat 0.792   kept 80%
        # which is the Dyer's cream weld and the Greener's beige coals said as
        # a curve: an emissive pushed up the view transform's shoulder BUYS
        # BRIGHTNESS BY SPENDING COLOUR, and white is where every hue ends.
        # 0.80 is taken. I LOOKED AT THE 1.10 AND THE 0.80 RENDERS BEFORE
        # CHOOSING and the picture agrees with the number: at 1.60 a viewer
        # names the pour as a pale stick, at 0.80 as something hot.
        # THE GUARD I WROTE WAS THE WRONG GUARD AND I AM RECORDING THAT RATHER
        # THAN THE NUMBER IT GAVE: `share_in_frame_top1pct` asks whether the
        # pour is the brightest thing by LUMINANCE, and luminance is weighted
        # 0.72 toward green, so a deep red-orange scores near zero against pale
        # sand however hot it looks. It fell 0.92 -> 0.00 between 1.60 and 1.45
        # while `val` went UP, 0.851 -> 0.861. A guard that moves opposite to
        # the quantity it is guarding is not a guard; had I obeyed it I would
        # have shipped the tan. Both numbers stay in the report, with this
        # sentence beside them.
        # THE HONEST LIMIT: at 0.80 the stream reads as FLAT ORANGE, not as
        # metal with a white-hot core. One emissive material cannot carry both,
        # and a second is a change I am not making in the same pass as five
        # others.
        'glow': ((1.000, 0.120, 0.012), 0.80),
    },
})

CANON.update({
    "moulder": ("The Moulder", 2.90, (0.62, 0.58, 0.52), (1.00, 0.56, 0.20),
                "firepit",
                "IT TAKES YOUR SHAPE - it presses one of your heroes into its "
                "sand bed and pours, and what stands up out of the box fights "
                "with that hero's reach and that hero's swing; the party is "
                "not choosing how to kill it but which of them it is allowed "
                "to read, so the hero who leads is the hero they will have to "
                "fight, and the mould can be broken before the metal sets",
                0.26, "It took a copy of one of you."),
})
ORDER = ORDER + ["moulder"]


def moulder():
    """IT TAKES YOUR SHAPE. A stooped founder at the front, a box of sand
    behind him, and a hero-shaped casting standing up out of the box.

    SILHOUETTE INTENT - TWO HEADS AT TWO HEIGHTS, AND ONE OF THEM IS YOURS:
      - the outline carries a HERO SHAPE in it. Nothing else in the register
        does, and that single fact is the idea readable at stream distance:
        a viewer sees what the fight is about before a line fires;
      - the man is LOW and stooped at the front (-Y), the flask is TALL behind
        him (+Y), so the two are separated IN DEPTH. The side view is the
        camera this creature is built for - the Reeve shipped a side view with
        one body behind another and both checks in minibossfit passed it, so
        depth separation here is by construction and the occlusion test is the
        instrument that keeps it;
      - the cast is CUT OFF at the sand line: legs still buried, a sprue stub
        where an arm has not run, a parting seam up the middle. A finished
        statue would read as a statue. An unfinished one reads as a thing
        being made;
      - five small castings hung on the flask's near board - it has done this
        before, said in the silhouette and not in a stat;
      - an ODD arm count on the man (rammer down, crucible out, no third) and
        a head small enough that the cast's head is the one you look at.

    Front is -Y, same as the other twenty-five."""
    P = Parts("moulder")
    # Section spans, the same record every body since the Hurdleman keeps, so
    # _metal_read / _trade_read / _colour_read can measure ONE part of this
    # body without rebuilding it by hand. It changes no geometry.
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    # the two anchors everything hangs off. MX/MY: the flask. HX/HY: the man.
    FX, FY = 0.26, 0.46
    HX, HY = -0.46, -0.52
    # PASS 5, ONE NUMBER, AND THE SIDE RENDER IS THE WHOLE REASON. At pass 4
    # the bed stood at 1.34 and the cast cleared it by only 0.32 - its
    # shoulders and nothing else. A chibi head is as DEEP as it is wide (the
    # measured hero: 1.14 across, 1.017 front to back), so from the side, with
    # no shoulder line showing under it, the cast read as A GIANT PALE EGG and
    # the hero shape - the entire idea - disappeared in one of the three views.
    # NOTE WHAT DID NOT CATCH THIS: the occlusion test passed all three views,
    # because it asks whether the hero can see the creature and the creature
    # the hero, not whether one PART of the creature has eaten another. The
    # picture caught it; no number in this lane could have.
    # The flask drops 0.28 so the chest and shoulders clear the bed. The cast
    # does not move, so it is still exactly the hero's measured 2.45 m.
    BOX_DROP = 0.28
    SAND_Z = 1.34 - BOX_DROP           # the top of the rammed bed

    # ------------------------------------------------- THE FLASK (box of sand)
    i0 = len(P.items)
    # the stand it sits on - trestle, not a plinth. Furniture that says so.
    for sx in (-1, 1):
        for sy in (-1, 1):
            limb(P, [(FX + sx * 0.52, FY + sy * 0.26, 0.00),
                     (FX + sx * 0.44, FY + sy * 0.22, 0.52 - BOX_DROP)], 0.062, 0.052, 'dark')
    P.add(L.box(1.22, 0.70, 0.075), 'dark', loc=(FX, FY, 0.56 - BOX_DROP))
    # the box itself: four boards and the bed inside. Open at the top.
    for sx in (-1, 1):
        P.add(L.box(0.060, 0.68, 0.74), 'dark', loc=(FX + sx * 0.58, FY, 0.97 - BOX_DROP))
    for sy in (-1, 1):
        P.add(L.box(1.20, 0.058, 0.74), 'dark', loc=(FX, FY + sy * 0.34, 0.97 - BOX_DROP))
    # the bed: rammed sand, proud of the boards and uneven because it is sand
    P.add(L.box(1.14, 0.62, 0.70), 'dark', loc=(FX, FY, 0.96 - BOX_DROP))
    for i in range(7):
        t = (i / 6.0) - 0.5
        P.add(L.sphere(0.150, 0.115, 0.055, 9, 6), 'dark',
              loc=(FX + t * 0.92, FY - 0.03 + 0.10 * math.sin(i * 1.7),
                   SAND_Z - 0.03 + 0.012 * math.cos(i * 2.3)))
    # the iron bands and the cope pins - a flask is a BANDED thing, and the
    # pins are what lets the two halves come apart, which is how it is broken
    for sy in (-1, 1):
        P.add(L.box(1.26, 0.050, 0.060), 'body', loc=(FX, FY + sy * 0.355, 1.20 - BOX_DROP))
        P.add(L.box(1.26, 0.050, 0.060), 'body', loc=(FX, FY + sy * 0.355, 0.74 - BOX_DROP))
    for sx in (-1, 1):
        limb(P, [(FX + sx * 0.60, FY - 0.30, 0.66 - BOX_DROP),
                 (FX + sx * 0.60, FY - 0.30, 1.46 - BOX_DROP)],
             0.030, 0.026, 'body')
    _span("flask", i0)

    # ------------------------------------------------- THE CAST - YOUR HERO
    # *** PASS 3, AND ONLY THE ON-BODY RENDER COULD HAVE FOUND THIS. ***
    # Pass 2 put the cast beside a real posed KayKit adventurer in
    # _moulder_register.png and the whole idea fell over in one glance: THE
    # HERO IS A CHIBI AND MY CAST WAS NOT. The hero is a big-headed, short-
    # limbed body; the cast was a slim realistic figure. A creature whose one
    # idea is IT TAKES YOUR SHAPE had taken a shape that is not yours, and
    # neither the blank check, the border check nor the occlusion test can see
    # that - every one of them passed pass 2. Fit is the acceptance test and
    # this is what it is for.
    #
    # THE PROPORTIONS BELOW ARE MEASURED OFF THE BODY, NOT CHOSEN.
    # tools/art/_moulder_chibi_probe.py imports Knight.glb through
    # minibossfit.import_hero (posed, scale 1.0, h 2.45 m) and reports:
    #     head block (Head + Helmet)  z 1.095 - 2.450   1.355 = 55.3% of h
    #     body                        z 0.360 - 1.277   0.917 = 37.4%
    #     arms                        z 0.548 - 1.251
    #     legs                        z 0.000 - 0.521   0.521 = 21.3%
    #     widest head 1.14, body 0.811, body+arms 1.32
    # Every z below is that table mapped through z = FEET + (z_hero/2.45)*HC,
    # and every width is the table's width times HC/2.45. So the cast is the
    # hero's own proportions at the hero's own ratios, and nothing here is my
    # taste about what a hero looks like.
    i0 = len(P.items)
    CX, CY = FX - 0.04, FY - 0.02
    # PASS 4, ONE NUMBER, AND THE REGISTER SHEET IS WHY. At pass 3 the cast
    # was 1.92 m of chibi and its head broke the dashed hero rule on
    # _moulder_register.png: the copy was TALLER THAN THE HERO IT COPIES, which
    # is the one thing a copy must not be. HC is now the hero's own measured
    # height, 2.45 m, so the thing in the box is the size of the thing it was
    # read from and the claim is checkable against the dashed rule rather than
    # asserted. Its feet sit at 0.45 - buried, which is why it still rides
    # higher than the hero on the sheet: it is standing in a box of sand, not
    # on the floor. FEET + HC = 2.90 = the creature's whole height, so THE
    # IDEA sets the height of this body and the blade no longer does.
    FEET, HC = 0.45, 2.45
    K = HC / 2.45

    def _z(zh):
        return FEET + (zh / 2.45) * HC

    HEAD_C = (_z(1.095) + _z(2.450)) * 0.5
    # the torso: buried to the sand line, square-shouldered, CHUNKY. Built as a
    # box over a tube so it keeps a shoulder line instead of tapering away.
    limb(P, [(CX, CY + 0.01, _z(0.36)), (CX, CY + 0.005, _z(0.95)),
             (CX - 0.01, CY, _z(1.277))], 0.811 * K * 0.46, 0.811 * K * 0.40, 'bone')
    P.add(L.box(0.811 * K * 0.86, 0.749 * K * 0.80, _z(1.277) - _z(0.50)), 'bone',
          loc=(CX, CY + 0.005, (_z(1.277) + _z(0.50)) * 0.5))
    # shoulders carried out to the measured arm span (1.32 across, both arms)
    limb(P, [(CX - 1.32 * K * 0.40, CY, _z(1.20)), (CX + 1.32 * K * 0.40, CY, _z(1.21))],
         0.606 * K * 0.30, 0.606 * K * 0.30, 'bone')
    # THE HEAD. 55% of the body, and it is the whole argument: at register
    # distance this is the thing a viewer recognises as one of their own.
    P.add(L.sphere(1.14 * K * 0.47, 1.017 * K * 0.46, 1.355 * K * 0.46, 15, 10),
          'bone', loc=(CX, CY - 0.01, HEAD_C))
    # the brow band - a cast head has no face, and a blank ball has no front.
    # This gives it one without giving it features it should not have.
    P.add(L.box(1.14 * K * 0.80, 1.017 * K * 0.30, 1.355 * K * 0.11), 'body',
          loc=(CX, CY - 1.017 * K * 0.34, HEAD_C + 1.355 * K * 0.04))
    # ARM ONE: run, raised, holding a blade. The reach is the hero's reach, so
    # it has to be IN the outline - but CHUNKY and SHORT now, like the pack's
    # own weapons, not the long slim plank of passes 1-2.
    # PASS 7, AND IT IS THE HEADLINE FAULT OF THE SIDE VIEW. A chibi head is
    # 55% of the body and as deep as it is wide, so from the side - where both
    # arms are hidden behind the torso, because arms spread along X and X is
    # the axis that camera looks down - the cast read as A GIANT PALE EGG with
    # a slab under it. The arm comes FORWARD 0.30 in Y as well as out in X, so
    # the elbow and the blade break the ovoid's outline from the side while
    # the front view is unchanged (the man is at x -0.46, the blade at +0.9;
    # they do not meet in either frame). This does not cure the side read, and
    # the fault list says so.
    FWD = 0.30
    limb(P, [(CX + 1.32 * K * 0.38, CY + 0.01, _z(1.19)),
             (CX + 1.32 * K * 0.50, CY - 0.04 - FWD * 0.6, _z(1.33)),
             (CX + 1.32 * K * 0.54, CY - 0.07 - FWD, _z(1.52))],
         0.606 * K * 0.26, 0.606 * K * 0.20, 'bone')
    GX = CX + 1.32 * K * 0.54
    GZ = _z(1.52)
    P.add(L.box(0.090, 0.090, 0.11), 'body', loc=(GX, CY - 0.07 - FWD, GZ))
    P.add(L.box(0.19, 0.060, 0.62), 'bone',
          loc=(GX + 0.11, CY - 0.075 - FWD, GZ + 0.36), rot=(0.0, 0.30, 0.0))
    # ARM TWO: THE METAL DID NOT RUN. A sprue stub and nothing past the elbow -
    # the half-made story, told on the side the crucible does not cover.
    limb(P, [(CX - 1.32 * K * 0.38, CY + 0.01, _z(1.19)),
             (CX - 1.32 * K * 0.52, CY - 0.02, _z(1.03))],
         0.606 * K * 0.25, 0.606 * K * 0.16, 'bone')
    P.add(L.sphere(0.070, 0.064, 0.050, 9, 7), 'bone',
          loc=(CX - 1.32 * K * 0.55, CY - 0.03, _z(1.00)))
    # the parting seams, on the SIDES where a cope-and-drag flask splits - see
    # pass 2. Re-sat on the new silhouette rather than left where they were.
    for sx in (-1, 1):
        limb(P, [(CX + sx * 0.811 * K * 0.44, CY + 0.01, SAND_Z - 0.06),
                 (CX + sx * 0.811 * K * 0.46, CY + 0.01, _z(1.21)),
                 (CX + sx * 1.14 * K * 0.44, CY + 0.00, HEAD_C - 0.06)],
             0.020, 0.015, 'glow')
    # still hot where it has just left the sand
    for i in range(4):
        P.add(L.sphere(0.030, 0.022, 0.016, 8, 6), 'glow',
              loc=(CX - 0.14 + i * 0.095, CY - 0.20, SAND_Z + 0.02 + 0.03 * (i % 2)))
    _span("cast", i0)

    # ------------------------------------------------- THE MAN
    i0 = len(P.items)
    # stooped over the bed: hips low, spine forward into -Y, head LOW and well
    # clear of the cast's head so the two never read as one mass.
    limb(P, [(HX - 0.14, HY + 0.04, 0.00), (HX - 0.17, HY - 0.02, 0.42),
             (HX - 0.12, HY + 0.02, 0.86)], 0.126, 0.105, 'body')
    limb(P, [(HX + 0.16, HY + 0.06, 0.00), (HX + 0.20, HY - 0.04, 0.44),
             (HX + 0.13, HY + 0.03, 0.88)], 0.126, 0.105, 'body')
    for sx in (-1, 1):
        P.add(L.box(0.30, 0.34, 0.095), 'body', loc=(HX + sx * 0.15, HY - 0.08, 0.048))
    limb(P, [(HX, HY + 0.02, 0.88), (HX + 0.02, HY - 0.14, 1.26),
             (HX + 0.04, HY - 0.30, 1.52)], 0.205, 0.150, 'body')
    # the apron: a slab on the front, and the one straight edge on him
    P.add(L.box(0.42, 0.075, 0.74), 'body', loc=(HX + 0.02, HY - 0.26, 1.12),
          rot=(0.22, 0.0, 0.0))
    # the head, and the eyes are the only light ON him
    P.add(L.sphere(0.165, 0.185, 0.175, 13, 9), 'body', loc=(HX + 0.05, HY - 0.38, 1.64))
    P.add(L.box(0.33, 0.30, 0.055), 'body', loc=(HX + 0.05, HY - 0.40, 1.76))
    # PASS 2, FORM CHANGE 3. At pass 1 these were r 0.030 on a 2.90 m body -
    # about ten pixels at register framing - and on both renders the man had no
    # face at all. That is the Greener's fault repeated ("the head all but lost
    # against the body") and the Pressman's before it, and the register has now
    # shipped it three times. Bigger, set at the head's front surface, with a
    # dark brow over them so the eye reads a face and not two dots.
    P.add(L.box(0.30, 0.10, 0.060), 'dark', loc=(HX + 0.05, HY - 0.49, 1.70))
    eyes(P, (HX + 0.05, 0.0, 1.62), 0.070, 0.048, HY - 0.50)
    # ARM ONE: down into the bed with the rammer. The long diagonal.
    limb(P, [(HX + 0.19, HY - 0.26, 1.42), (HX + 0.46, HY - 0.16, 1.22),
             (HX + 0.62, HY + 0.04, 1.08)], 0.082, 0.062, 'body')
    limb(P, [(HX + 0.64, HY + 0.06, 1.06), (HX + 0.78, HY + 0.30, SAND_Z - 0.02)],
         0.034, 0.030, 'body')
    P.raw(aim(L.cone(0.105, 0.105, 0.22, 11), (HX + 0.80, HY + 0.34, SAND_Z - 0.06),
              (0.16, 0.30, 1.0)), 'dark')
    # ARM TWO: out and up with the crucible on its shank, and THE POUR.
    # PASS 6, AND IT IS THE SIDE RENDER AGAIN. At pass 5 the crucible sat at
    # z 2.02 - the same height as the cast's head, whose centre is 2.22 - and
    # from the side the shank ran INTO the head and the crucible read as a pot
    # stuck to the side of it. Two objects at the same height on the same
    # screen line become one object, however far apart they are in X, and the
    # side camera looks along X so X is exactly the axis it cannot use.
    # The arm comes DOWN and the crucible now tips over the bed's near corner
    # at 1.50, below the head and in front of the torso. The pour gets shorter
    # and more vertical, which is also what a pour looks like.
    limb(P, [(HX - 0.20, HY - 0.22, 1.40), (HX - 0.46, HY - 0.26, 1.42),
             (HX - 0.60, HY - 0.24, 1.48)], 0.082, 0.060, 'body')
    SHK = [(HX - 0.60, HY - 0.24, 1.46), (HX - 0.16, HY + 0.18, 1.48),
           (HX + 0.22, HY + 0.62, 1.50)]
    limb(P, SHK, 0.030, 0.026, 'body')
    CRU = (HX + 0.27, HY + 0.73, 1.50)
    P.raw(aim(L.cone(0.165, 0.120, 0.30, 12), CRU, (0.10, 0.34, 1.0)), 'dark')
    P.raw(aim(L.cone(0.150, 0.150, 0.045, 12), (CRU[0] + 0.02, CRU[1] + 0.05, CRU[2] + 0.15),
              (0.10, 0.34, 1.0)), 'glow')
    # the stream: crucible mouth -> the pour cup on the flask's top board.
    POUR = [(CRU[0] + 0.04, CRU[1] + 0.08, CRU[2] + 0.11),
            (CRU[0] + 0.02, CRU[1] + 0.12, SAND_Z + 0.22),
            (FX - 0.44, FY - 0.14, SAND_Z + 0.06)]
    P.raw(L.tube([Vector(p) for p in POUR], [0.034, 0.028, 0.022], 7), 'glow')
    P.add(L.sphere(0.090, 0.082, 0.030, 10, 7), 'dark', loc=(FX - 0.44, FY - 0.14, SAND_Z))
    P.add(L.sphere(0.055, 0.050, 0.018, 9, 6), 'glow', loc=(FX - 0.44, FY - 0.14, SAND_Z + 0.03))
    _span("man", i0)

    # ------------------------------------------------- IT HAS DONE THIS BEFORE
    i0 = len(P.items)
    # five finished castings hung on the near board, smallest to largest, and a
    # spill of sand and sprue at the foot of the stand.
    # PASS 2, FORM CHANGE 4 (cosmetic, and recorded as cosmetic). At pass 1
    # these sat flush on the board and read as KEYHOLES cut in it - bright
    # slots, not objects. Stood off the board on real pegs so they hang.
    for i in range(5):
        h = 0.085 + i * 0.016
        x = FX - 0.40 + i * 0.20
        P.raw(L.tube([Vector((x, FY - 0.36, 1.00 - BOX_DROP)),
                     Vector((x, FY - 0.46, 1.00 - BOX_DROP))],
                     [0.016, 0.014], 6), 'body')
        P.add(L.box(0.055, 0.042, h), 'bone',
              loc=(x, FY - 0.47, 0.95 - BOX_DROP - h * 0.5 + 0.015 * (i % 2)))
    for i in range(6):
        P.add(L.sphere(0.105, 0.085, 0.034, 9, 6), 'dark',
              loc=(FX - 0.50 + i * 0.22, FY - 0.52 - 0.06 * (i % 3), 0.026))
    # PASS 2, FORM CHANGE 5 (cosmetic). One long pale stick on the floor read
    # as a SPOON on both renders. Two short broken sprues instead - what is
    # actually left when a casting is knocked off its runner.
    for a, b in (((FX + 0.58, FY - 0.70, 0.034), (FX + 0.74, FY - 0.64, 0.034)),
                 ((FX + 0.84, FY - 0.58, 0.034), (FX + 0.96, FY - 0.47, 0.034))):
        P.raw(L.tube([Vector(a), Vector(b)], [0.026, 0.021], 6), 'bone')
    _span("already", i0)

    return P


BUILDERS.update({"moulder": moulder})


# ======================================================================= 27 THE
# ======================================================================= RATCATCHER
#
# IT IS PAID BY THE TAIL. Everything ELSE that dies in this room goes into the
# cage on its hip, and it is stronger for every bay it fills. The party is not
# choosing how to hurt it; it is choosing whether to clear the room at all.
# Leave the lesser things alive and you fight the whole floor at once. Kill
# them and you hand this one the fight.
#
# WHY IT IS NOT ONE OF THE TWENTY-SIX - CHECKED BY PARSING `CANON`, NOT BY
# MEMORY. Two bodies are its real neighbours and both were read before a vertex
# was written:
#   THE SCRAPWRIGHT (workshop, 2.00) also GROWS - but off the room's loose
#   plate, on its own schedule, with no dial the party's hand is on. This one
#   grows ONLY when the party swings, and it can be starved completely by a
#   party that leaves the trash standing. The growth is the same word and the
#   opposite decision.
#   THE PRESSMAN (prison, 2.85) also USES THE DEAD - but your FALLEN HEROES,
#   so it punishes losing. This one eats your KILLS, so it punishes winning
#   fast. Nothing else in the register takes the party's own successes as its
#   feed.
# CRYPT was chosen because it is one of the five themes still carrying a single
# miniboss (confection, crypt, fogbound, shrine, wood - counted off CANON this
# run, not remembered). The crypt's wired primary is the SEXTON, whose idea is
# IT WILL NOT STAY DOWN: its own risings, its own graves. This one never rises
# and never dies twice. They share a room and share no mechanic.
#
# WEAR IS A VARIABLE, AND THIS NUMBER IS A STATED CHOICE, NOT A MEASUREMENT.
# The Moulder's 0.26 was the surface-area-weighted mean of two populations,
# measured by tools/art/_moulder_wear.py. I did NOT run that here and I am not
# going to imply I did. Three populations, argued:
#   the man's leather and the greased iron pole - OLD, handled daily, 0.85
#   the willow cage - RELASHED AS IT ROTS, so the youngest thing on the body,
#   0.45; and a cage that is this creature's receipt must not read as refuse
#   the tally bundles - today's, 0.10
# 0.68 is taken, toward the man-and-iron end because they carry most of the
# mass and all of the silhouette's lower half.
OVERRIDE_ALLOWED = set(OVERRIDE_ALLOWED) | {"ratcatcher"}

OVERRIDE.update({
    "ratcatcher": {
        # THE MAN AND THE IRON. The Moulder's measured lesson, applied and not
        # rediscovered: put the DARK body against the PALE furniture so the
        # outline is carried by contrast instead of by a rim light I would
        # have to invent. The Greener's head vanishing from the side is the
        # live fault that argument comes from.
        'body': ((0.078, 0.062, 0.050), 0.86, 0.02),
        # THE WILLOW. Buff, dry, pale - and it is the BIGGEST object on the
        # body, so the cage is what a viewer's eye lands on first. That is on
        # purpose: the cage is the idea.
        'bone': ((0.690, 0.588, 0.414), 0.78, 0.00),
        # THE TALLY. Near-black against buff willow is the whole of the count's
        # legibility, and it is the one thing in this body I will not soften.
        # NOTE WHAT ELSE IS IN THIS SLOT AND WHAT IS NOT: the cage's own frame
        # is 'bone', not 'dark', so dark pixels inside the cage region ARE the
        # count and the instrument below can measure them without separating
        # ironwork from occupants first.
        'dark': ((0.038, 0.034, 0.030), 0.70, 0.05),
        # THE LAMP. A tallow flame, and the strength is the Moulder's measured
        # curve taken as read rather than re-swept: an emissive pushed up the
        # view transform's shoulder BUYS BRIGHTNESS BY SPENDING COLOUR, and
        # white is where every hue ends. The Dyer clipped to cream at 2.30,
        # the Greener settled 1.45, the Moulder 0.80. A hand lamp is cooler
        # than a pour, so one step below it. 0.70.
        'glow': ((1.000, 0.560, 0.140), 0.70),
    },
})

CANON.update({
    "ratcatcher": ("The Ratcatcher", 2.62, (0.70, 0.60, 0.42), (1.00, 0.62, 0.22),
                   "crypt",
                   "IT IS PAID BY THE TAIL - everything else that dies in this "
                   "room goes into the cage on its hip and it is stronger for "
                   "every bay it fills, so the party is not choosing how to "
                   "kill it but whether to clear the room at all; leave the "
                   "lesser things standing and you fight the whole floor at "
                   "once, clear them and you hand this one the fight, and the "
                   "bays already filled can be cut open to give them back",
                   0.68, "It is paid by the tail."),
})
ORDER = ORDER + ["ratcatcher"]


def ratcatcher():
    """IT IS PAID BY THE TAIL. A stooped man with a long tongs-pole, and a
    gridded willow cage slung on his near hip with FIVE OF ITS TWELVE BAYS
    FULL.

    SILHOUETTE INTENT - A GRID YOU CAN COUNT, AND IT IS HALF EMPTY:
      - the CAGE is a 3 x 4 LATTICE OF OPEN BAYS. Nothing else in the register
        is a gridded box, and nothing else in it is COUNTABLE as a number
        rather than as a pile. A viewer reads "five of twelve" from the
        doorway, and the SEVEN EMPTY BAYS are half the idea: there is room for
        more, and the party decides whether it gets it;
      - THE THREE THINGS ARE SIDE BY SIDE ACROSS THE PICTURE, NOT STACKED IN
        DEPTH. Cage on the near-left, man centre, pole and tongs sweeping
        right. The Reeve shipped a side view with one body behind another and
        both of minibossfit's checks passed it; the Moulder had to drop its
        flask 0.28 because a chibi head is as deep as it is wide and ate the
        cast. Depth separation is a thing this lane keeps getting wrong, so
        this body does not ask for any: all three elements are separated in X,
        which every camera in the register can see;
      - a FILLED BAY SAGS AND AN EMPTY HOOK RIDES HIGH, so the cage's bottom
        edge is a ragged line and the ragged part IS the count. That is the
        only thing carrying the tally in the side view, where a row across X
        foreshortens into one object;
      - the MAN is stooped and his head is SMALL - the Moulder's lesson: make
        the head you do not want looked at smaller than the thing you do;
      - ONE BUNDLE IS IN THE TONGS, caught, not yet filed. A still picture
        cannot show a mechanic working, but it can show which way the stuff is
        travelling, which is what the Reeve's spill did;
      - BOTH ARMS RUN ACROSS THE PICTURE PLANE - the Tanner's pass-3 finding,
        applied first time: a forearm pointing at the lens foreshortens to
        nothing.

    Front is -Y, the same as the twenty-six before it."""
    P = Parts("ratcatcher")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    # ---- the three anchors, and they are separated in X on purpose (above)
    CX, CY = -0.78, 0.06          # the cage
    MX = 0.34                     # the man
    CW, CD = 0.92, 0.62           # cage width (x) and depth (y)
    CZ0, CZ1 = 0.55, 1.95         # cage bottom and top
    NCOL, NROW = 3, 4
    FRONT_Y = CY - CD / 2.0
    BACK_Y = CY + CD / 2.0
    colw = CW / NCOL
    rowh = (CZ1 - CZ0) / NROW

    # ------------------------------------------------------------- THE MAN
    # *** PASS 3, AND IT IS THE WHOLE OF THE MAN. THE FIT RENDER IS THE ONLY
    # *** REASON IT HAPPENED. *** Passes 1-2 built him at REAL human
    # proportion - thin limbs, long shins, a head 14% of his own height - and
    # the three views on their own never showed anything wrong with him,
    # because there was nothing in frame to compare him to. Put him beside a
    # posed KayKit Knight in minibossfit and he reads as a stick figure next
    # to a toy: the hero is a CHIBI, head about 40% of its height, and the
    # ratio 1.07 the register reports is a HEIGHT ratio that cannot see this
    # at all. It is the Moulder's pass-5 finding exactly - "the hero is a
    # chibi and my cast was not" - and shipping it again a day later would be
    # this lane losing something it had already learned.
    # So: head to ~29% of his own height, limbs roughly 55% thicker, shins
    # shortened, shoulders widened. He stays the SECOND thing you look at -
    # the cage is 0.92 m across against his 0.49 m head - so the silhouette
    # argument from pass 1 survives, which is the trade I was worried about
    # and the fit sheet says it holds.
    i0 = len(P.items)
    for s in (-1, 1):
        limb(P, [(MX + 0.19 * s, 0.03, 0.03),
                 (MX + 0.21 * s, -0.02, 0.33),
                 (MX + 0.17 * s, -0.07, 0.62)], 0.160, 0.128, 'body')
        # boots in 'dark' - the one place the man meets the floor, and a dark
        # foot against a dark floor is a thing this lane has shipped before.
        # Kept dark anyway: the floor under a crypt miniboss is the game
        # build's to light, and a pale boot would read as a bandage.
        P.add(L.box(0.34, 0.46, 0.17), 'dark',
              loc=(MX + 0.19 * s, -0.13, 0.085))
    P.add(L.box(0.58, 0.40, 0.26), 'body', loc=(MX, -0.06, 0.70))
    # the stoop: the torso leans 0.24 forward over 0.46 of rise. A man who
    # carries a loaded cage on one hip does not stand up straight, and the lean
    # is what tells the two halves of the silhouette apart at stream distance.
    limb(P, [(MX, -0.06, 0.68), (MX - 0.02, -0.17, 0.92),
             (MX - 0.04, -0.26, 1.14)], 0.340, 0.280, 'body')
    P.add(L.box(0.76, 0.32, 0.19), 'body', loc=(MX - 0.04, -0.26, 1.16))
    # THE HEAD, and it is now the chibi's size, not a man's.
    P.add(L.sphere(0.245, 0.255, 0.238, 13, 9), 'body',
          loc=(MX - 0.05, -0.33, 1.33))
    P.add(L.box(0.52, 0.46, 0.07), 'dark', loc=(MX - 0.05, -0.35, 1.475))
    eyes(P, (MX - 0.05, -0.33, 1.345), 0.098, 0.044, -0.195)
    # ARMS, both across the plane. Far arm high on the pole, near arm low -
    # two different heights so the pair reads as a grip and not as a bar.
    limb(P, [(MX + 0.34, -0.25, 1.12), (MX + 0.12, -0.34, 0.95),
             (MX - 0.12, -0.40, 0.82)], 0.130, 0.098, 'body')
    limb(P, [(MX - 0.34, -0.25, 1.10), (MX - 0.02, -0.41, 0.84),
             (MX + 0.18, -0.48, 0.58)], 0.130, 0.098, 'body')
    _span("man", i0)

    # ------------------------------------------- THE YOKE AND THE SHOULDER BAR
    i0 = len(P.items)
    # the cage does not float: a bar off the near shoulder and two straps down
    # to the cage's top corners. Willow bar, iron straps.
    P.raw(L.tube([Vector((MX - 0.26, -0.24, 1.22)),
                  Vector((CX + 0.34, -0.18, 1.98)),
                  Vector((CX - 0.30, -0.14, 2.06))],
                 [0.052, 0.046, 0.042], 7), 'bone')
    for sx in (-1, 1):
        P.raw(L.tube([Vector((CX + sx * (CW / 2.0 - 0.06), -0.16, 2.02)),
                      Vector((CX + sx * (CW / 2.0 - 0.03), CY, CZ1 + 0.02))],
                     [0.030, 0.026], 6), 'dark')
    _span("yoke", i0)

    # --------------------------------------------------------- THE CAGE FRAME
    # A 3 x 4 lattice. Open bays, open top - you watch it fill. Members are
    # 'bone' so that every DARK pixel inside the cage's box is an occupant,
    # which is what makes the instrument below able to count.
    i0 = len(P.items)
    for c in range(NCOL + 1):
        x = CX - CW / 2.0 + c * colw
        P.add(L.box(0.046, 0.052, CZ1 - CZ0 + 0.05), 'bone',
              loc=(x, FRONT_Y, (CZ0 + CZ1) / 2.0))
        if c in (0, NCOL):                      # corner posts run full depth
            P.add(L.box(0.052, CD, 0.052), 'bone', loc=(x, CY, CZ0))
            P.add(L.box(0.052, CD, 0.052), 'bone', loc=(x, CY, CZ1))
            P.add(L.box(0.046, 0.052, CZ1 - CZ0 + 0.05), 'bone',
                  loc=(x, BACK_Y, (CZ0 + CZ1) / 2.0))
    for r in range(NROW + 1):
        z = CZ0 + r * rowh
        P.add(L.box(CW + 0.05, 0.052, 0.046), 'bone', loc=(CX, FRONT_Y, z))
        if r in (0, 2, NROW):
            P.add(L.box(CW + 0.05, 0.052, 0.046), 'bone', loc=(CX, BACK_Y, z))
    # the floor of the basket - a woven pan, so the bottom row has something to
    # sit on and the cage does not read as an empty frame hanging in air
    for j in range(5):
        y = CY - CD / 2.0 + CD * j / 4.0
        P.add(L.box(CW, 0.040, 0.034), 'bone', loc=(CX, y, CZ0 + 0.02))
    _span("cage", i0)

    # ------------------------------------- THE TALLY: TWELVE BAYS, FIVE FILLED
    # FILLED FROM THE BOTTOM, which is how a basket fills and is also the only
    # arrangement a viewer can read as a FRACTION rather than as a scatter.
    # Row 0 (bottom) all three, row 1 two of three, rows 2 and 3 empty.
    FILLED = [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1)]
    i0 = len(P.items)
    for (r, c) in FILLED:
        bx = CX - CW / 2.0 + (c + 0.5) * colw
        bz = CZ0 + (r + 0.5) * rowh
        # A FILLED BAY SAGS. 0.055 down on the willow, which is what makes the
        # cage's bottom edge ragged and is the only thing carrying the count in
        # the side view. The sag is also why the bundle bulges THROUGH the
        # front plane rather than sitting politely inside it.
        bz -= 0.055
        # PASS 2, ONE NUMBER, AND IT IS THE INSTRUMENT'S, NOT MY TASTE.
        # Pass 1 sat all five occupants in ONE plane at y = CY - 0.07, and
        # _rat_tally measured what that costs: front 5 components of ~2,000 px
        # each (the count reads), SIDE 1 of 2,692 and 1 of 833 - five bundles
        # collapsing into two masses, because a row laid across X projects onto
        # itself in a side camera. The catch was visible there and UNCOUNTABLE,
        # which for a creature whose whole idea is a fraction is most of the
        # idea gone in one of three views.
        # A basket is DEEP. Staggering the columns across the cage's 0.62 m of
        # depth is what a loaded basket actually looks like and it is the only
        # thing a side camera can separate them by. 0.24 m of column pitch
        # against a 0.236 m bundle diameter - deliberately just over touching,
        # measured rather than chosen, and the rows are offset half a step so
        # the two rows do not stack either. The FRONT view cannot move: this
        # is an orthographic +Y camera and nothing's x or z changes.
        byy = CY + (c - 1) * 0.24 + (r - 0.5) * 0.12
        P.add(L.sphere(0.112, 0.118, 0.096, 11, 7), 'dark',
              loc=(bx, byy, bz))
        # AND THE TAIL OUT THROUGH THE FRAME. The creature is paid by the tail;
        # a tail hanging out of a bay is the plainest possible way to say so,
        # and it gives each occupant its own outline instead of five identical
        # lumps.
        P.raw(L.tube(arc((bx, byy - 0.09, bz - 0.02),
                         (bx + (0.13 if c != NCOL - 1 else -0.13),
                          byy - 0.30, bz - 0.17), 0.03, 6),
                     L.lerp_list(0.021, 0.011, 6), 5), 'dark')
    _span("occupants", i0)

    i0 = len(P.items)
    # the willow under a FILLED bay bows with it - a loaded basket is not
    # square, and this is the geometry saying the load is real. NOT in the
    # `occupants` span on purpose: that span is what the with/without
    # instrument deletes, and a 'bone' member inside it would be counted as
    # tally pixels that moved. An instrument that measures its own scaffolding
    # is the fault class this lane keeps finding in its own gates.
    for c in range(NCOL):
        bx = CX - CW / 2.0 + (c + 0.5) * colw
        P.add(L.box(colw * 0.86, 0.046, 0.034), 'bone',
              loc=(bx, FRONT_Y, CZ0 - 0.022))
    # the SEVEN EMPTY BAYS get a hook each, riding HIGH on the member above.
    # An empty bay with nothing in it at all is a hole; an empty bay with an
    # unused hook is a VACANCY, and the difference is the whole second half of
    # the idea.
    for r in range(NROW):
        for c in range(NCOL):
            if (r, c) in FILLED:
                continue
            bx = CX - CW / 2.0 + (c + 0.5) * colw
            ztop = CZ0 + (r + 1) * rowh
            P.raw(L.tube(arc((bx, FRONT_Y - 0.01, ztop - 0.02),
                             (bx + 0.045, FRONT_Y - 0.03, ztop - 0.115),
                             -0.02, 5), L.lerp_list(0.016, 0.013, 5), 5), 'dark')
    _span("vacancy", i0)

    # ------------------------------------------------- THE POLE AND THE TONGS
    i0 = len(P.items)
    TX, TZ = MX + 0.96, 0.30                    # where the jaws close
    limb(P, [(MX - 0.22, -0.39, 0.90), (MX + 0.36, -0.47, 0.62),
             (TX, -0.56, TZ)], 0.048, 0.038, 'dark')
    # two jaws, bowed apart, closed on something
    for s in (-1, 1):
        P.raw(L.tube(arc((TX - 0.04, -0.56, TZ + 0.01),
                         (TX + 0.30, -0.60, TZ - 0.17),
                         0.0, 6, side=s * 0.105),
                     L.lerp_list(0.028, 0.019, 6), 6), 'dark')
    # THE ONE IN THE TONGS. Caught, not yet filed - the direction of travel.
    P.add(L.sphere(0.090, 0.096, 0.078, 10, 7), 'dark',
          loc=(TX + 0.20, -0.585, TZ - 0.10))
    P.raw(L.tube(arc((TX + 0.26, -0.60, TZ - 0.13),
                     (TX + 0.42, -0.64, TZ - 0.27), 0.02, 6),
                 L.lerp_list(0.019, 0.010, 6), 5), 'dark')
    # a short iron butt at the near end so the pole reads as a tool with two
    # ends and not as a stick
    P.add(L.cone(0.058, 0.042, 0.11, 8), 'dark',
          loc=(MX - 0.26, -0.38, 0.93))
    _span("pole", i0)

    # ------------------------------------------------------------- THE LAMP
    # The ONE lit thing, and it is hung so that what it lights is THE TALLY.
    # The Moulder's measured limit is stated rather than re-measured: one
    # emissive cannot be both a hot core and a coloured flame, and the
    # Pressman's glow ring could not be seen at all because it sat inside its
    # own housing. So the source is OUTSIDE the hood, below it, facing the
    # bays, and it is small - light reads as light when it is a thin source
    # against a dark interior.
    i0 = len(P.items)
    LX, LY, LZ = CX + 0.08, -0.34, 1.88
    P.raw(L.tube([Vector((CX + 0.26, -0.20, 2.02)), Vector((LX, LY, LZ + 0.13))],
                 [0.020, 0.017], 6), 'dark')
    P.add(L.cone(0.105, 0.030, 0.10, 10), 'dark', loc=(LX, LY, LZ + 0.08))
    P.add(L.sphere(0.052, 0.052, 0.058, 10, 7), 'glow', loc=(LX, LY, LZ))
    # four iron uprights round the flame - a lamp, not a floating bead
    for i in range(4):
        a = TAU * i / 4.0 + math.pi / 4.0
        P.add(L.box(0.016, 0.016, 0.13), 'dark',
              loc=(LX + math.cos(a) * 0.075, LY + math.sin(a) * 0.075, LZ))
    P.add(L.cone(0.075, 0.095, 0.035, 10), 'dark', loc=(LX, LY, LZ - 0.075))
    _span("lamp", i0)

    return P


BUILDERS.update({"ratcatcher": ratcatcher})


# ======================================================================= 28
# THE DROVER - wood, the second one. 2026-11-18, the art lane.
#
# WHAT I CHECKED FOR FIRST, MEASURED THIS RUN AND NOT REMEMBERED:
#   I parsed CANON out of this file and listed every mechanic phrase in it -
#   41 strings, 27 distinct bodies, and the register's occupied classes are:
#   summon, self-armour, drag-a-hero, douse the lamps, will-not-stay-down,
#   bar the door, take-and-wear, heal-the-pack, raise the water, plant thorn,
#   pre-set the room, fire-scaled, mislocated sound, pour-and-set, come apart
#   in two, arm the room, encumber, bisect the room, adaptive resistance,
#   take the haul, drink the brews, press the fallen, strike you level, mark
#   one and hunt only it, green your iron, take your shape, paid by the tail.
#   NOTHING IN THE REGISTER SHARES HARM WITH THE PARTY. That is this one.
#   I also counted bodies per theme off the same parse: wood carries ONE
#   (the Snarer) and is one of the four thinnest themes alongside fogbound,
#   shrine and confection. The Snarer's idea is IT HAS ALREADY SET THE ROOM -
#   lines laid before you arrived. This one lays nothing and sets nothing;
#   it joins itself to you. Same room, no shared mechanic.
#
# AND I CHECKED THE PACKS BEFORE WRITING A VERTEX. There is no yoke, no ox-bow
# and no chain coil in the forty packs - I grepped the directory for yoke /
# ox / bow / chain / collar / coil (the run log is in the summary). The two
# things that DO exist and that I am not rebuilding are a man's body shape and
# a staff, and this file's own `limb` and `tube` already serve both better than
# an import would, because the stoop has to be authored to the load.
#
# WEAR IS A VARIABLE AND THIS NUMBER IS AN ARGUED CHOICE, NOT A MEASUREMENT.
# I did not run _moulder_wear.py here and will not imply I did. Four
# populations:
#   the ash beam - handled every day of a working life, smooth and old, 0.85
#   the chain and the two collars - greased iron, older than the man, 0.90
#   the leather - daily, 0.80
#   the goad - cut this week, and it is the only young thing on the body, 0.15
# 0.74 is taken, toward the beam-and-iron end because they carry the mass and
# the whole upper silhouette. 0.74 is free in the register (0.70 and 0.75 are
# taken; nothing shares a value).
OVERRIDE_ALLOWED = set(OVERRIDE_ALLOWED) | {"drover"}

OVERRIDE.update({
    "drover": {
        # THE MAN IS DARK AND THE FURNITURE IS PALE. The Moulder measured this
        # and the Ratcatcher applied it: contrast carries the outline, so I do
        # not have to invent a rim light. The Greener's head vanishing from the
        # side is the live fault the argument comes from.
        'body': ((0.070, 0.058, 0.048), 0.88, 0.02),
        # THE ASH. The beam is the biggest object on the body and the first
        # thing an eye lands on, which is on purpose: the beam IS the idea.
        # Ash kept warm rather than grey - a working yoke is oiled by hands.
        'bone': ((0.722, 0.612, 0.408), 0.80, 0.00),
        # THE IRON. Near-black, and this slot holds ONLY the mechanic - the two
        # bows, the collar, the chain, the coil, the goad's point and the boots.
        # So a dark pixel anywhere above the man's knee IS the mechanic, and an
        # instrument can measure the chain without separating it from ironmongery
        # that is not the chain. The boots are the one exception and they live
        # below z 0.2, which is why the span below is measured, not the slot.
        'dark': ((0.034, 0.031, 0.029), 0.72, 0.05),
        # NO LAMP, AND THAT IS A DECISION - BUT NOT "NO GLOW", WHICH IS WHAT
        # THIS COMMENT SAID BEFORE I CHECKED MY OWN CALL. A drover carries no
        # lamp: rule 1 is plainness, and the register already has a
        # lamp-carrier (the Snuffer), a pour (the Moulder) and a hand lamp (the
        # Ratcatcher). Inventing light for a man who drives beasts down a wood
        # road would be the flourish the register bans. So there is no flame,
        # no hood and no pour on this body. THE ONE EMISSIVE IS THE PAIR OF
        # EYE PINPOINTS, because creatures.eyes() defaults to slot='glow' and
        # every man in this register has them. Total emissive area is two
        # spheres of r 0.042. Named exactly, because "no glow" would have been
        # a false sentence sitting next to a call that makes glow.
    },
})

CANON.update({
    "drover": ("The Drover", 2.44, (0.72, 0.61, 0.41), (0.86, 0.78, 0.62),
               "wood",
               "IT YOKES ONE OF YOU - it closes a bow of its own yoke on a "
               "hero and after that the harm you do it travels the chain: "
               "while the collar holds, every blow landed on the Drover is "
               "paid half by the one wearing it, so the party is not choosing "
               "how hard to hit but whether to hit at all; cut the chain and "
               "the yoke comes free to take the next, and the second bow "
               "hangs open to tell you it can",
               0.74, "It yokes one of you."),
})
ORDER = ORDER + ["drover"]


def _chainlink(P, pts, n, slot='dark', r=0.072, rad=0.020, flat=False,
               lie=False):
    """A chain, as INTERLOCKING RINGS on a path.

    *** PASS 2, AND THE PICTURE IS THE ONLY REASON IT HAPPENED. *** Pass 1
    drew the chain as separate alternating BOXES spaced evenly along the run.
    The front render shows exactly what that is: a scatter of loose cubes
    climbing through empty air, and the coil a pile of gravel on the floor.
    Not a chain - debris. And the creature's whole idea is that harm TRAVELS
    the chain, so a chain that does not read as one connected thing is the
    mechanic gone, not a finish problem.
    The fault was spacing, not shape: links that do not touch are not a chain,
    they are a dotted line. Rings now sit at 1.10 * r, i.e. OVERLAPPING, and
    consecutive rings are turned 90 degrees to each other so the run reads as
    links passing through links. That is also what makes it read as CUTTABLE,
    which is the party's way out of the mechanic and therefore worth the
    faces."""
    nseg = len(pts) - 1
    # step along the polyline by arc length so a long slack span does not get
    # sparser links than a tight one - a chain has ONE link size everywhere.
    for i in range(n):
        t = i / float(max(1, n - 1))
        seg = t * nseg
        k = min(nseg - 1, int(seg))
        f = seg - k
        a, b = pts[k], pts[k + 1]
        c = (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f,
             a[2] + (b[2] - a[2]) * f)
        if lie:
            # lying on the floor: every link flat, seen from above
            _open_ring(P, c, r, slot=slot, rad=rad, n=8, gap=0.02,
                       axis='z', tilt=0.0)
        elif flat:
            # lying on the floor: alternate a flat ring and an upright one
            _open_ring(P, c, r, slot=slot, rad=rad, n=8, gap=0.02,
                       axis='z', tilt=0.0 if i % 2 else math.pi / 2.0)
        else:
            _open_ring(P, c, r, slot=slot, rad=rad, n=8, gap=0.02,
                       axis='y', yaw=0.0 if i % 2 else math.pi / 2.0)


def drover():
    """IT YOKES ONE OF YOU. A stooped man under an ash ox-yoke with TWO BOWS
    hanging from it: the near one SHUT, with a collar and a chain running off
    the body to a coil of slack on the floor, and the far one HANGING OPEN.

    SILHOUETTE INTENT - A PAIR, AND ONE OF THEM IS ALREADY TAKEN:
      - the YOKE BEAM is a long pale bar across the top of the body. Nothing
        else in the register is a HORIZONTAL BAR at head height - the Hurdleman
        plants a vertical hurdle, the Reeve carries a box, the Ratcatcher a
        gridded cage - so this body is told apart from all twenty-seven at the
        outline, before any detail resolves;
      - TWO BOWS, ONE SHUT AND ONE OPEN. The count is two, which is the
        smallest countable fraction there is and the easiest to read from a
        doorway: one of us is in it, and there is a place for another. The
        Ratcatcher's five-of-twelve needed a staggered basket to stay countable
        in three views; two needs nothing but to be apart in X;
      - THE CHAIN LEAVES THE BODY. It runs from the shut collar down and OUT
        to a coil on the floor, clear of the man's own outline in X, because a
        dark chain crossing a dark torso is a line that does not exist at pane
        distance. It is links, not a tube, so it reads as something that can be
        cut - and cutting it is the party's out;
      - THE COIL IS THE SLACK, and slack is a threat: there is more chain than
        is being used, so the thing is not at the end of its reach;
      - THE GOAD is the only young thing on the body and the only pale thing
        below the beam, and it sweeps the other way from the chain so the lower
        half of the picture has one object on each side of the man;
      - the MAN is stooped and his head is SMALL - the Moulder's lesson, taken
        as read: make the head you do not want looked at smaller than the thing
        you do. He is built at CHIBI proportion, not human: head ~29% of his
        own height, limbs thick, shins short. The Ratcatcher shipped a real
        human at pass 2 and read as a stick figure beside a KayKit hero, and
        only the fit render caught it. I am not paying for that twice.
      - BOTH ARMS RUN ACROSS THE PICTURE PLANE - the Tanner's pass-3 finding.

    AND ONE THING DELIBERATELY AGAINST THE RATCATCHER'S RULE, NAMED HERE SO
    THE RENDER CAN JUDGE IT RATHER THAN MY TASTE. That body separated all three
    of its elements in X because a side camera cannot see depth separation. A
    BEAM ACROSS X IS EXACTLY THE SHAPE THAT RULE CANNOT SAVE: in a side view it
    foreshortens to a stub and the two bows project onto one another, which
    would be the whole mechanic gone in one of three views. So the beam is
    CAMBERED FORWARD and the two bows hang at DIFFERENT Y - the near one
    forward of the shoulder, the far one behind it - which is also what a real
    ox-yoke does. The side view is the one I expect to be worst and it is the
    first thing I will look at.

    Front is -Y, the same as the twenty-seven before it."""
    P = Parts("drover")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = 0.08                      # the man
    BZ = 1.52                      # the beam's underside at the shoulders
    BHW = 0.95                     # beam half-width in x
    # *** PASS 4, AND IT IS THE SAME FAULT AS PASS 3 WITH A DIFFERENT
    # *** OCCLUDER. *** Pass 3 dropped the bows clear of the beam and they
    # still both rendered as C's, because at x -0.60 / +0.62 they hang
    # straight through the MAN: his torso is 0.82 across at the shoulders and
    # his arms reach further, so the inboard arc of each ring was eaten by his
    # own silhouette. Moving them to +/-0.84 - just inboard of the beam's ends
    # at 0.95 - puts the WHOLE circle of each ring against background in the
    # front and three-quarter cameras. That is the only way an O and a C can
    # be told apart, and telling them apart IS the creature.
    # I have now spent two passes learning one thing: THE COUNT MUST HANG IN
    # CLEAR AIR. Writing it down because the Ratcatcher's cage learned the
    # same lesson about depth and this lane keeps paying for it twice.
    # *** PASS 6, AND IT IS THE FAULT I PREDICTED IN THIS DOCSTRING BEFORE
    # *** PASS 1 RENDERED. *** hero_side.png: only ONE bow is visible. The
    # other is directly behind the man, so the side camera shows one C and the
    # count - the whole creature - is gone in that view. 0.30 of authored Y
    # between them was not depth separation, it was a rounding error.
    # They now sit 0.80 apart in Y (1.2 m once the body is scaled): the taken
    # one well FORWARD of his chest, the empty one well BEHIND his back. The
    # front and three-quarter cameras are orthographic along Y and the rings'
    # x and z do not move, so NOTHING those two views read can change - only
    # the depth order, and the rings do not overlap the man in x any more.
    # This is also what a real ox-yoke does: the bows straddle the neck fore
    # and aft, they do not hang in one plane.
    SHUT_X, SHUT_Y = -0.84, -0.46  # the taken bow: well forward of the chest
    OPEN_X, OPEN_Y = 0.84, 0.34    # the empty bow: well behind the back
    # *** PASS 5. MINIBOSSFIT WENT RED ON THIS CREATURE AND IT WAS RIGHT. ***
    # Pass 4 measured 4.26 m of footprint and the hero+creature pair came to
    # 6.12 m, which does not fit the harness's fixed cell frame - the widest
    # body in the whole register before this one is the Gaoler at 3.72. The
    # error was "drover: pair does not fit the fixed frame".
    # I COULD HAVE WIDENED THE FRAME. I did not, and I want that on the record:
    # the frame is shared by twenty-six bodies that all fit it, so a frame
    # changed to admit mine would be an instrument edited to pass its author's
    # work - the exact fault class this lane keeps catching in its own gates.
    # The creature is what was wrong. And the two widest things on it are the
    # two LEAST load-bearing: the coil's sprawl and the goad's reach. The
    # hanging chain already says there is slack; the coil does not have to say
    # it across another metre of floor. Coil pulled in 0.28 and tightened 0.07,
    # goad shortened 0.12 to just inside the beam's own end - so the BEAM is
    # now what sets the width, which is correct, because the beam is the idea.
    COIL_X, COIL_Y = -0.90, -0.30  # the slack on the floor

    # ------------------------------------------------------------- THE MAN
    i0 = len(P.items)
    for s in (-1, 1):
        limb(P, [(MX + 0.185 * s, 0.03, 0.03),
                 (MX + 0.205 * s, -0.02, 0.32),
                 (MX + 0.165 * s, -0.06, 0.60)], 0.158, 0.126, 'body')
        P.add(L.box(0.33, 0.45, 0.17), 'dark',
              loc=(MX + 0.185 * s, -0.12, 0.085))
    P.add(L.box(0.57, 0.39, 0.26), 'body', loc=(MX, -0.05, 0.68))
    # THE STOOP, and here it is load-bearing in the literal sense: a man under
    # a yoke beam is bent UNDER it, not leaning out from it, so the lean is
    # smaller than the Ratcatcher's and the shoulders sit square to the beam.
    # 0.14 forward over 0.44 of rise.
    limb(P, [(MX, -0.05, 0.66), (MX - 0.01, -0.12, 0.90),
             (MX - 0.02, -0.19, 1.10)], 0.345, 0.300, 'body')
    # the shoulders - wide, and they are the thing the beam rests on, so they
    # are a plate rather than a taper
    P.add(L.box(0.82, 0.34, 0.20), 'body', loc=(MX - 0.02, -0.19, 1.13))
    # a leather pad between shoulder and beam. Plainness: a yoke chafes, so a
    # working man puts a folded hide under it. It also stops the beam reading
    # as if it floats.
    P.add(L.box(0.52, 0.30, 0.09), 'body', loc=(MX - 0.02, -0.14, 1.255))
    # THE HEAD, chibi-sized, and it sits FORWARD of the beam so the beam does
    # not cut it in the front view.
    P.add(L.sphere(0.235, 0.245, 0.228, 13, 9), 'body',
          loc=(MX - 0.03, -0.30, 1.40))
    P.add(L.box(0.50, 0.44, 0.07), 'dark', loc=(MX - 0.03, -0.32, 1.535))
    # eyes() DEFAULTS TO slot='glow' - I read the signature in creatures.py
    # rather than assume, because my own palette comment below claims what is
    # and is not emissive on this body and a default would have made it a lie.
    # The two pinpoints stay (every man in this register has them); the comment
    # is the thing that got corrected.
    eyes(P, (MX - 0.03, -0.30, 1.415), 0.094, 0.042, -0.190)
    # ARMS, both across the plane, at two different heights so the pair reads
    # as two grips and not as a bar. FAR arm up on the beam (he steadies it),
    # NEAR arm down and out to the goad.
    limb(P, [(MX + 0.36, -0.20, 1.16), (MX + 0.56, -0.16, 1.34),
             (MX + 0.74, -0.13, 1.44)], 0.128, 0.098, 'body')
    limb(P, [(MX - 0.36, -0.22, 1.12), (MX - 0.14, -0.34, 0.92),
             (MX + 0.16, -0.42, 0.74)], 0.128, 0.098, 'body')
    _span("man", i0)

    # ------------------------------------------------------------ THE BEAM
    # Cambered forward: the ends come toward the viewer, which is both what an
    # ox-yoke looks like and the only reason a side camera sees an ARC here
    # instead of a stub. 'bone' - the pale mass, the first thing seen.
    i0 = len(P.items)
    P.raw(L.tube([Vector((MX - BHW, -0.02, BZ - 0.04)),
                  Vector((MX - BHW * 0.52, -0.14, BZ + 0.01)),
                  Vector((MX, -0.17, BZ + 0.02)),
                  Vector((MX + BHW * 0.52, -0.12, BZ + 0.01)),
                  Vector((MX + BHW, 0.01, BZ - 0.04))],
                 [0.072, 0.086, 0.092, 0.086, 0.072], 9), 'bone')
    # the two end knobs, so the beam has ends and does not read as cut off by
    # the frame. THE BORDER CHECK CANNOT SEE A BEAM THAT IS TOO LONG - it can
    # only see alpha at the edge - so the knobs are also how I will know by eye
    # whether the camera has the whole beam.
    for sx, yy in ((-1, -0.02), (1, 0.01)):
        P.add(L.sphere(0.098, 0.090, 0.086, 10, 7), 'bone',
              loc=(MX + sx * (BHW + 0.03), yy, BZ - 0.045))
    # the bed strap: iron over the beam, down onto the shoulder pad, one each
    # side of the neck. The beam is TIED ON.
    for sx in (-1, 1):
        P.raw(L.tube([Vector((MX + sx * 0.20, -0.17, BZ + 0.08)),
                      Vector((MX + sx * 0.23, -0.14, 1.30)),
                      Vector((MX + sx * 0.21, -0.11, 1.22))],
                     [0.026, 0.024, 0.022], 6), 'dark')
    _span("beam", i0)

    # ------------------------------------------------- THE TWO BOWS: 1 OF 2
    # The SHUT one is a closed ring - the collar is on and there is no way out
    # of it but the chain. The OPEN one is a U with a visible GAP at the
    # bottom, and the gap is the whole of the second half of the idea: there is
    # a place for another of you. A closed ring and an open U differ at the
    # outline, which is the only place a viewer is reading.
    i0 = len(P.items)
    # --- SHUT: full ring, 0.30 radius, hanging under the beam at SHUT_X
    # *** PASS 3, AND IT IS THE WHOLE IDEA, FOUND BY LOOKING AT front.png. ***
    # Passes 1-2 hung both bows DIRECTLY UNDER THE BEAM at BZ - 0.36, and the
    # beam - 0.09 thick and cambered forward over them - COVERED THE TOP ARC OF
    # BOTH. A shut bow is an O and an open one is a C: that is the entire
    # count, and an occluder across the top turns an O into a C too. Both
    # rendered as C's. The creature's one idea is "one of two is taken" and a
    # viewer could not have read it from any of the three cameras.
    # The fix is clear air, not a bigger ring: the bows drop to BZ - 0.62 and
    # hang on visible straps, so the whole circle of each is against
    # background. Nothing else moved.
    # yaw 0.78: _open_ring's OWN docstring says a yaw-0 ring is edge-on from
    # the side and the Pressman shipped four collars that became four sticks
    # there. I read that before rendering rather than discovering it again.
    for _sx, _sy in ((SHUT_X, SHUT_Y), (OPEN_X, OPEN_Y)):
        P.raw(L.tube([Vector((MX + _sx, _sy, BZ - 0.02)),
                      Vector((MX + _sx, _sy, BZ - 0.30))],
                     [0.026, 0.024], 6), 'dark')
    _open_ring(P, (MX + SHUT_X, SHUT_Y, BZ - 0.62), 0.30, slot='dark',
               rad=0.038, n=18, gap=0.015, axis='y', yaw=0.78)
    # the collar itself: a heavier band at the bottom of the shut bow, which is
    # where a neck would be. Thicker than the bow so the EYE lands on the thing
    # that is doing the holding.
    # PASS 3b: the collar used to sit INSIDE the bow and the two rings read as
    # one knot rather than as a bow with something in it. It now hangs CLEAR
    # BELOW the bow's bottom arc, joined by a link, so the outline is
    # ring-over-ring - which is what "this one is wearing it" looks like.
    _open_ring(P, (MX + SHUT_X, SHUT_Y, BZ - 1.03), 0.150, slot='dark',
               rad=0.054, n=14, gap=0.015, axis='y', yaw=0.78)
    _span("bow_shut", i0)

    i0 = len(P.items)
    # --- OPEN: the same bow with a 0.34 gap at the bottom. Nothing in it.
    # the gap is turned to phase 4.2 rad so the opening faces DOWN-AND-OUT,
    # i.e. the C opens away from the beam. A gap at the top is hidden by the
    # beam it hangs from and the count would read two-shut.
    _open_ring(P, (MX + OPEN_X, OPEN_Y, BZ - 0.62), 0.30, slot='dark',
               rad=0.038, n=18, gap=0.34, axis='y', yaw=0.78, phase=4.20)
    _span("bow_open", i0)

    # ------------------------------------------------------------ THE CHAIN
    # Out of the collar, down and AWAY from the body in x, to the coil. Three
    # points so it has a hanging curve rather than a straight run, and it
    # crosses no part of the man at any of the three cameras: the man's
    # outline ends near x = MX - 0.50 and the chain's first link is at
    # MX - 0.60 and only goes further out.
    i0 = len(P.items)
    _chainlink(P, [(MX + SHUT_X, SHUT_Y, BZ - 1.17),
                   (MX + SHUT_X - 0.22, SHUT_Y - 0.09, 0.86),
                   (MX + COIL_X + 0.26, COIL_Y + 0.04, 0.30),
                   (MX + COIL_X + 0.08, COIL_Y, 0.10)], 34)
    _span("chain", i0)

    # ------------------------------------------------------------- THE COIL
    # Flat spiral on the floor. Low, wide and unmistakably SLACK. It is also
    # the only thing in the body below the man's knee on that side, so it does
    # not fight anything for the bottom-left of the frame.
    i0 = len(P.items)
    for turn in range(3):
        r = 0.33 - turn * 0.088
        pts = []
        for i in range(19):
            a = TAU * i / 18.0 + turn * 0.7
            pts.append((MX + COIL_X + math.cos(a) * r,
                        COIL_Y + math.sin(a) * r * 0.74,
                        0.055 + turn * 0.045))
        # PASS 3c: pass 2's coil alternated a FLAT ring with an UPRIGHT one,
        # the same trick that makes the hanging run read as links - and on the
        # floor it read as a bed of spiked cartwheels, because an upright ring
        # seen from above is a spoke. A coil of chain lying down is seen from
        # ABOVE in every one of these cameras, so it is flat rings only, and
        # the links read by overlapping their neighbours instead.
        _chainlink(P, pts, 22, flat=False, lie=True)
    _span("coil", i0)

    # ------------------------------------------------------------- THE GOAD
    # Pale shaft, iron point, sweeping down and right out of the near hand.
    # The one young thing on the body, and the only pale object below the beam.
    i0 = len(P.items)
    GX, GZ = MX + 1.00, 0.16
    P.raw(L.tube([Vector((MX - 0.06, -0.40, 0.98)),
                  Vector((MX + 0.52, -0.47, 0.58)),
                  Vector((GX, -0.52, GZ))],
                 [0.046, 0.040, 0.032], 7), 'bone')
    # THE POINT IS ON THE SHAFT, which it was not: side.png shows the pass-1
    # cone hanging in clear air below the ferrule. A rotation about Y swung it
    # off the shaft's own line. The shaft's last leg runs (0.52,-0.47,0.58) ->
    # (GX,-0.52,GZ), so the point is placed ALONG that direction and rotated to
    # match it rather than by a number I liked the look of.
    P.add(L.cone(0.034, 0.004, 0.17, 8), 'dark',
          loc=(GX + 0.016, -0.523, GZ - 0.095), rot=(0.0, 0.28, 0.0))
    # an iron ferrule where point meets shaft, so the goad has a joint and does
    # not read as one tapering stick
    P.add(L.cone(0.042, 0.038, 0.055, 8), 'dark', loc=(GX, -0.52, GZ - 0.01))
    _span("goad", i0)

    return P


BUILDERS.update({"drover": drover})


# =====================================================================
# 29. THE PAVISER - keep, the second one. IT KEEPS ITS FACE TO YOU.
# =====================================================================
# WEAR 0.78, AND IT IS A COMPOSITE, NOT A MOOD. The 0.05 ladder from 0.15 to
# 1.00 is FULL - I measured it off CANON this run rather than remembering it,
# all 26 distinct values occupied - so this takes a gap between steps the way
# the Drover took 0.74 and the Ratcatcher 0.68. The parts, each justified:
#   the board           it is the thing every blow lands on. Split, limewash
#                       gone grey, bolt stubs still in it.          0.90
#   the hinge post and  greased daily, because a hinge that seizes is a dead
#   its two collars     paviser.                                    0.45
#   the prop            cut to replace the last one that snapped.   0.20
#   the man             the whole point of his job is that he is not hit. 0.35
# 0.78 is taken, well toward the board, because the board is 60% of the
# silhouette and the first and last thing an eye lands on. 0.75 (loader) and
# 0.80 (gaoler) are taken; 0.78 is free and nothing shares it.
OVERRIDE_ALLOWED = set(OVERRIDE_ALLOWED) | {"paviser"}

OVERRIDE.update({
    "paviser": {
        # THE MAN IS DARK AND THE BOARD IS PALE - the Moulder's measured
        # contrast rule, applied for the fourth body running. Here it is not
        # only a legibility trick, it IS the creature: the front view must read
        # as a PALE BOARD with a dark head over it, and the back view as a DARK
        # MAN with the pale board's edge beyond him. Two different creatures
        # from two sides is the mechanic drawn.
        'body': ((0.062, 0.064, 0.070), 0.85, 0.06),
        # THE BOARD AND THE PROP. Limewash gone grey - a pavise was whitened so
        # the men behind the line could see each other, and this one has stood
        # in a keep long enough for that to be a memory of white rather than
        # white. Warm-neutral, not blue: it must not read as stone.
        'bone': ((0.738, 0.712, 0.636), 0.86, 0.00),
        # THE IRON, and this slot again holds ONLY the mechanic plus the boots:
        # the hinge post, its two collars, the two bands, the centre rib, the
        # bolt stubs and the prop's shoe. A dark mark on the pale field IS
        # either the hinge or a hit, which is the whole story of the body.
        'dark': ((0.036, 0.034, 0.032), 0.70, 0.06),
        # NO LAMP AND NO FLAME. Rule 1 is plainness and a man behind a board
        # carries neither. The ONLY emissive is the pair of eye pinpoints that
        # every man in this register has, because creatures.eyes() defaults to
        # slot='glow' - I read the signature rather than assume it, which is
        # the correction the Drover's palette comment had to make.
    },
})

CANON.update({
    "paviser": ("The Paviser", 2.68, (0.74, 0.71, 0.63), (0.82, 0.84, 0.88),
                "keep",
                "IT KEEPS ITS FACE TO YOU - it carries a pavise on a hinge "
                "post and swings it onto whoever is hurting it most, and a "
                "blow into the board does nothing at all; so the party cannot "
                "win this by standing still and hitting harder - one of you "
                "has to get round the post while another holds its attention, "
                "and the moment you two swap sides the board swings back",
                0.78, "A board came round to face you."),
})
ORDER = ORDER + ["paviser"]


def paviser():
    """IT KEEPS ITS FACE TO YOU. A man behind a curved limewashed pavise hung
    on a hinge post at its inboard edge, with a prop leg braced back to the
    floor behind him.

    THE IDEA, AND WHY IT IS NOT A 29TH COAT OF ONE OF THE TWENTY-EIGHT.
    I parsed the ideas out of CANON this run rather than recalling them. The
    classes present are: summon, self-armour, drag a hero out, douse the lamps,
    will-not-stay-down, bar the door, steal gear, heal the pack, raise the
    water, plant the ground, pre-set the room, scale with the fire, ring from
    elsewhere, set the floor, come apart in two, arm the room, weigh you down,
    cut the party in two, adapt to the damage type, take the haul, drink your
    stores, use your fallen, mark one of you, trade on the body, copy your
    shape, be paid by the tail, yoke one of you.
    NOT ONE OF THEM IS POSITIONAL. Every one is answered by deciding WHAT to
    do; this one is answered only by deciding WHERE TO STAND. That is a
    mechanic class the set does not have, and it is the reason this body is
    worth four meshes.

    IT IS NOT THE PORTER AND IT IS NOT THE HURDLEMAN, and the difference is
    not a quibble:
      - the PORTER drops a leaf across the chamber MOUTH. It is a wall, it does
        not move, and what it takes from you is retreat.
      - the HURDLEMAN plants a panel through the middle of YOUR LINE. Also
        static, and what it takes from you is each other.
      - this one's board is ON THE CREATURE AND IT TRACKS. Nothing is taken
        from you. What changes is that the creature now has a front and a back,
        and your damage depends on which one you are standing at.

    THE SOLID BILLBOARD IS A FREE SILHOUETTE AND THE HURDLEMAN IS WHY. Its pass
    3 found that its spare panels "read as one solid grey billboard - the
    biggest mass in the silhouette, reading as a door or a shield", and it
    rebuilt them as open lattices because a hurdle is not solid. So that
    outline was vacated by the one body that could not use it. A pavise IS a
    door-sized shield, so the read the Hurdleman had to throw away is the exact
    read this body needs, and no two bodies end up sharing it.

    SILHOUETTE INTENT - A FRONT AND A BACK THAT ARE NOT THE SAME CREATURE:
      - FROM THE FRONT: a tall PALE SOLID BOARD with an arched top, a dark
        centre rib, two dark bands and a scatter of dark bolt stubs, and a dark
        head over the top edge with a far shoulder and arm showing past the
        right side. No other body in the register is a solid pale slab.
      - FROM THE BACK: the board is gone and you are looking at a MAN, with the
        hinge post and its two collars on his left and the prop leg running
        away from him to the floor. That is the party's answer drawn: get here.
      - FROM THE SIDE the board is nearly edge-on, which is the view that has
        killed three bodies in this file. Two things answer it rather than one,
        and I have separated them on purpose: the board is deeply CAMBERED
        (0.20 of authored depth over a 0.46 half-width), so edge-on it is an
        ARC with real width and not a stick; and the MAN IS OFFSET 0.14 TOWARD
        the side camera, so he stands in front of his own board there instead
        of behind it.

    Front is -Y, the same as the twenty-eight before it."""
    P = Parts("paviser")
    P.spans = {}

    def _span(name, i0):
        P.spans[name] = (i0, len(P.items))

    MX = 0.14                      # the man, pushed toward the side camera
    # PASS 4: BX -0.10 -> -0.18. The man had gone. Pass 3's taller, narrower
    # board was the right board and it swallowed its own creature: front.png
    # showed a board, a fist and ONE EYE. 0.08 further out puts his right
    # shoulder, arm and the whole helm back against background without moving
    # the board's own outline a millimetre in the side or back cameras.
    BX, BY = -0.18, -0.56          # the board's centre, forward of the chest
    BYAW = 0.34                    # the board is turned - he is bringing it round
    # *** PASS 3 MOVED ALL FOUR OF THESE AND THEY ARE ONE CHANGE, NOT FOUR:
    # *** THE BOARD STOPPED BEING A BARREL. *** Pass 2's shell was solid, which
    # was the fix it was for, and front.png then read as A CASK ON END - 0.92
    # across by 1.18 tall, an arched top, a deep belly and two iron hoops is a
    # barrel in any language, and it is a worse answer than pass 1's fence
    # because a barrel is a PROP and a fence at least had an edge to it.
    # Every number below moves toward TALL AND FLAT, which is what a pavise is:
    #   HALF  0.46 -> 0.40   narrower
    #   ZB    0.22 -> 0.14   it reaches the floor, the way a standing shield does
    #   ZT    1.40 -> 1.46   and up to his chin, leaving the helm clear by 0.15
    #   CAMB  0.20 -> 0.12   a curve, not a belly
    #   ARCH  0.10 -> 0.04   a top edge that is nearly straight
    # 1.32 tall by 0.80 wide is 1.65:1. Pass 2 was 1.28:1, which is a cask.
    HALF = 0.40                    # board half-width in its own u
    # PASS 5: 0.12 -> 0.075. Still a cask after pass 4, and the belly is half
    # the reason. 0.075 over a 0.40 half-width is a shield's curve; 0.12 was a
    # stave's. The side view was re-checked after this and the board is still
    # an ARC there, not a stick - which was the whole job the camber was given.
    CAMB = 0.075                   # how far the centre of the face bulges forward
    # PASS 4: ZT 1.46 -> 1.34. At 1.46 the top edge crossed his FACE and took
    # one of the two eyes with it. The head over the top edge is half of what
    # tells a viewer there is a man here at all, so the board now stops at the
    # chin and the whole head and helm stand clear above it - which is also
    # what a pavise is for: it covers the body, you look over it.
    ZB, ZT = 0.14, 1.34            # board bottom, and its top at the centre
    ARCH = 0.04                    # how much lower the top edge is at the ends
    cb, sb = math.cos(BYAW), math.sin(BYAW)

    def W(u, dy, z):
        """board-local (across, behind-the-face, height) -> world.

        EVERY PART OF THE BOARD GOES THROUGH THIS. The Drover's pass 4 and
        pass 6 were both the same fault - a number typed in world space for a
        thing that lives in a turned frame - and the only fix that holds is to
        stop typing world numbers at all."""
        return (BX + u * cb - dy * sb, BY + u * sb + dy * cb, z)

    def face_dy(u):
        """the cambered front face at u. Negative is toward the viewer."""
        return -CAMB * (1.0 - (u / HALF) ** 2)

    # ------------------------------------------------------------- THE MAN
    i0 = len(P.items)
    for s in (-1, 1):
        limb(P, [(MX + 0.185 * s, 0.03, 0.03),
                 (MX + 0.205 * s, -0.02, 0.32),
                 (MX + 0.165 * s, -0.06, 0.60)], 0.158, 0.126, 'body')
        P.add(L.box(0.33, 0.45, 0.17), 'dark',
              loc=(MX + 0.185 * s, -0.12, 0.085))
    P.add(L.box(0.57, 0.39, 0.26), 'body', loc=(MX, -0.05, 0.68))
    # THE LEAN, and here it is the job: a man holding a board against a push
    # leans INTO it. 0.19 forward over 0.44 of rise - more than the Drover's
    # 0.14, because the Drover was carrying a weight down and this one is
    # pushing a weight away.
    limb(P, [(MX, -0.05, 0.66), (MX - 0.01, -0.14, 0.90),
             (MX - 0.02, -0.24, 1.10)], 0.345, 0.300, 'body')
    P.add(L.box(0.80, 0.34, 0.20), 'body', loc=(MX - 0.02, -0.24, 1.13))
    P.add(L.sphere(0.235, 0.245, 0.228, 13, 9), 'body',
          loc=(MX - 0.02, -0.30, 1.38))
    # the helm: a flat brim, the same shape every man in this register wears,
    # and it is what clears the board's top edge in the front view.
    P.add(L.box(0.50, 0.44, 0.07), 'dark', loc=(MX - 0.02, -0.32, 1.515))
    eyes(P, (MX - 0.02, -0.30, 1.395), 0.094, 0.042, -0.190)
    # TWO ARMS ONTO THE BACK OF THE BOARD AT TWO DIFFERENT HEIGHTS - one low
    # and one high, which is how a thing on a hinge is actually swung, and
    # which stops the pair reading as a single bar the way the Drover's did.
    limb(P, [(MX - 0.36, -0.26, 1.12), (MX - 0.44, -0.38, 0.99),
             (MX - 0.44, -0.50, 0.88)], 0.128, 0.098, 'body')
    limb(P, [(MX + 0.36, -0.26, 1.10), (MX + 0.42, -0.38, 1.22),
             (MX + 0.36, -0.50, 1.30)], 0.128, 0.098, 'body')
    _span("man", i0)

    # ----------------------------------------------------------- THE BOARD
    # NINE VERTICAL PLANKS ON AN ARC, not one slab. A pavise is planked, and
    # the seams are also the only thing that will tell a viewer at stream
    # distance that this pale mass is BOARD and not stone or a door.
    # The top is ARCHED - 0.10 lower at the edges than at the centre - for the
    # same reason the Hurdleman squared its beetle head: a dead-flat top edge
    # at this size reads as architecture, not as a thing a man is holding.
    # *** PASS 2, AND THE PICTURE IS THE WHOLE REASON. *** Pass 1 built the
    # board as NINE SEPARATE PLANK BOXES on the arc. front.png: the arched tops
    # opened notches between them and it read as a PALISADE - a fence, the one
    # thing a shield must not be. side.png was worse and it was the failure the
    # docstring claimed the camber had answered: nine boxes spread over 0.20 of
    # depth, seen edge-on, came apart into SIX DETACHED PALE STICKS. The camber
    # did not save the side view, it supplied the spread that destroyed it.
    # So the board is now ONE CLOSED CURVED SHELL - a single swept solid with
    # a continuous front face, a continuous back and real ends. A pavise is
    # solid; nothing else is honest. The seams are drawn ON it below rather
    # than cut THROUGH it, so the planking survives in the face and never
    # touches the outline.
    i0 = len(P.items)
    NC = 13
    TH = 0.062
    verts, faces = [], []
    for i in range(NC):
        u = -HALF + (2.0 * HALF) * i / float(NC - 1)
        zt = ZT - ARCH * (u / HALF) ** 2
        fy = face_dy(u)
        for dy, z in ((fy, ZB), (fy, zt), (fy + TH, zt), (fy + TH, ZB)):
            verts.append(Vector(W(u, dy, z)))
    def q(a, b, c, d):
        faces.append([a, b, c, d])
    for i in range(NC - 1):
        a, b = i * 4, (i + 1) * 4
        q(a + 0, b + 0, b + 1, a + 1)          # front
        q(b + 3, a + 3, a + 2, b + 2)          # back
        q(a + 1, b + 1, b + 2, a + 2)          # top
        q(b + 0, a + 0, a + 3, b + 3)          # bottom
    q(0, 1, 2, 3)                              # the two ends
    e = (NC - 1) * 4
    q(e + 3, e + 2, e + 1, e + 0)
    P.raw((verts, faces), 'bone')
    _span("board", i0)

    # THE SEAMS, drawn on the face. Four shallow dark lines where the planks
    # would meet. They buy back the "this is boarded timber" read that the
    # single shell gave up, and because they are ON the face and inboard of the
    # ends they cannot reach the silhouette from any of the three cameras -
    # which is the exact property the nine plank boxes did not have.
    i0 = len(P.items)
    for u in (-0.14, 0.14):
        zt = ZT - ARCH * (u / HALF) ** 2
        x, y, _ = W(u, face_dy(u) - 0.010, 0.0)
        P.add(L.box(0.011, 0.020, zt - ZB - 0.05), 'dark',
              loc=(x, y, ZB + (zt - ZB) * 0.5),
              rot=(0.0, 0.0, BYAW - (u / HALF) * 0.36))
    _span("seams", i0)

    # ------------------------------------------- THE RIB, BANDS AND STRIKES
    # THE CENTRE RIB. A real pavise has a vertical gutter down the middle; this
    # is its outside. Dark, so the pale field has a spine and the front view
    # has a vertical to read against the two horizontals.
    # *** PASS 3 DELETED THE CENTRE RIB AND THE DELETION IS THE FIX. ***
    # Pass 1 put a dark tube down the middle of the face "so the pale field has
    # a spine". front.png: it came out the SAME WEIGHT AND THE SAME COLOUR AS
    # THE HINGE POST, so the front view had two identical dark verticals and
    # the board sat in a frame between them - a GATE, which is precisely the
    # read my own docstring said this body must not have, and I had written the
    # thing that caused it. With the rib gone the hinge post is the ONLY dark
    # vertical on the body, which is correct: the post is the mechanic and
    # nothing else should compete with it for that shape.
    i0 = len(P.items)
    # TWO IRON BANDS across the face, following the camber. These are what
    # holds nine planks together, and they are also the two horizontals that
    # stop the board reading as a blank.
    # *** PASS 5: THEY ARE STRAPS NOW, NOT HOOPS, AND THAT IS THE BARREL. ***
    # Passes 2-4 ran each band the FULL width and round onto the ends, so the
    # dark line met the pale outline on both sides and closed behind it. That
    # is a hoop, a hoop is a cask, and no amount of changing the board's
    # proportions was ever going to beat two hoops. They now stop at |u| 0.30
    # with their ends against the pale field, 0.10 inboard of the outline, so
    # they read as iron laid ON a board - which is what they are - and the
    # outline of the board is unbroken pale from top to bottom.
    STRAP = 0.30
    for zb in (0.40, 1.15):
        pts = []
        for t in range(7):
            u = -STRAP + 2.0 * STRAP * t / 6.0
            x, y, _ = W(u, face_dy(u) - 0.020, zb)
            pts.append(Vector((x, y, zb)))
        P.raw(L.tube(pts, [0.028] * 7, 6), 'dark')
    _span("bands", i0)

    # THE STRIKES - EIGHT BOLT STUBS STILL IN THE FACE, AND THEY ARE THE
    # RECEIPT. Mr. E's rule 2: wear is a variable and it must be EARNED by what
    # the thing is for. This board's entire purpose is to be hit, so the hits
    # are on it and they are COUNTABLE from the doorway, the way the Sexton's
    # four lit niches and the Drover's two bows are. Scattered, not patterned:
    # a pattern would read as decoration, which is the flourish the register
    # bans.
    i0 = len(P.items)
    # PASS 3: EIGHT BECAME SIX, 0.135 LONG BECAME 0.075, AND NONE IS OUTSIDE
    # |u| 0.28. side.png is why, and it is fault class 2 from my own prompt -
    # an element that reaches the outline in a view I was not thinking about.
    # Edge-on, eight 0.135 stubs became a ROW OF HORIZONTAL SPINES down the
    # left silhouette and the creature read as a spiked post. The border check
    # cannot see this: the stubs are not clipped and the frame is not blank, so
    # it is green while the body is a different animal. Six is also countable
    # at a glance where eight is not, which is the reason the Sexton has four
    # niches and the Drover two bows.
    STRIKES = ((-0.26, 0.58), (-0.11, 1.08), (0.04, 0.34),
               (0.17, 0.82), (0.26, 1.24), (-0.20, 0.92))
    for u, z in STRIKES:
        x, y, _ = W(u, face_dy(u) - 0.016, z)
        P.add(L.cone(0.026, 0.009, 0.055, 6), 'dark',
              loc=(x, y, z), rot=(math.pi / 2.0, 0.0, 0.0))
    # THREE SPLITS, one of them long. Thin dark slots let into the face.
    for u, z0, h in ((-0.22, 0.62, 0.62), (0.10, 0.30, 0.46), (0.29, 0.86, 0.40)):
        x, y, _ = W(u, face_dy(u) - 0.012, 0.0)
        P.add(L.box(0.013, 0.026, h), 'dark',
              loc=(x, y, z0 + h * 0.5), rot=(0.0, 0.0, BYAW - (u / HALF) * 0.36))
    _span("strikes", i0)

    # ------------------------------------------------------- THE HINGE POST
    # IT HANGS ON ONE EDGE, NOT ON ITS CENTRE, AND THAT IS THE WHOLE REASON THE
    # IDEA IS VISIBLE BEFORE THE FIGHT STARTS. A board on a centre spindle is a
    # board. A board on a POST AT ITS EDGE, with two collars and a prop, is a
    # thing that obviously SWINGS - a viewer who has ever opened a gate knows
    # it at a glance, and no one has to be told.
    # It also solves a geometry problem honestly rather than by fudging: a
    # centre post would have had to pass through the man's chest.
    i0 = len(P.items)
    PU, PDY = -0.56, 0.07
    px, py, _ = W(PU, PDY, 0.0)
    P.raw(L.tube([Vector((px, py, 0.0)), Vector((px, py, 0.76)),
                  Vector((px, py, 1.50))], [0.086, 0.078, 0.070], 9), 'dark')
    # the two collars, and the two short straps out to the board. Closed rings
    # in the HORIZONTAL plane (axis 'z'): a hinge band wraps the post, it does
    # not hang off it, so this is not the Drover's bow and must not look like
    # one.
    for zc in (0.40, 1.20):
        _open_ring(P, (px, py, zc), 0.135, slot='dark', rad=0.036, n=14,
                   gap=0.0, axis='z')
        sx, sy, _ = W(PU + 0.24, face_dy(PU + 0.24) + 0.03, zc)
        P.raw(L.tube([Vector((px, py, zc)), Vector((sx, sy, zc))],
                     [0.034, 0.028], 6), 'dark')
    _span("post", i0)

    # ------------------------------ THE BACK OF THE BOARD IS STILL BLANK,
    # AND PASS 6 TRIED TO FIX IT AND IS REVERTED HERE RATHER THAN SHIPPED.
    # hero_back.png carries half this creature's idea - the board is gone and
    # you are looking at the man, which is the party's answer drawn - and the
    # board's back is a dead pale rectangle. Pass 6 put two iron battens across
    # it, which is how a boarded pavise is actually braced. hero_back.png after
    # that change: THE MAN OCCLUDES THE WHOLE BACK OF THE BOARD, so all that
    # appeared were the two batten ENDS poking out past his torso, reading as
    # two loose pegs. That is worse than the blank it replaced.
    # THE CAUSE IS NOT THE BOARD, IT IS THE MAN, and that is why the revert is
    # the honest move rather than a third placement: anything put on the back
    # of this board is behind him by construction, so the back view will stay
    # thin until the MAN'S back carries something. That is pass 7's item and it
    # is carried in docs/art/MINIBOSSES.md as a live fault, not as a done job.
    # I am writing the failed attempt down instead of deleting it so the next
    # run does not spend a pass rediscovering that the board's back is hidden.

    # --------------------------------------------------------- THE PROP LEG
    # Back and out to the floor behind him. PALE, because it is the one young
    # thing on the body - a prop is what snaps and gets replaced - and because
    # the back view needs a second pale object once the board has gone.
    # It is taken well OUTBOARD in u so it crosses nothing: the man spans
    # roughly x -0.26..0.54 and every point of this leg is left of x -0.6.
    i0 = len(P.items)
    f = W(PU - 0.26, 1.35, 0.0)
    P.raw(L.tube([Vector(W(PU, PDY + 0.02, 1.42)),
                  Vector(W(PU - 0.14, 0.70, 0.74)),
                  Vector((f[0], f[1], 0.06))],
                 [0.058, 0.050, 0.044], 7), 'bone')
    # the iron shoe. A prop with no shoe skids, and a cone on the ground also
    # tells the eye where the floor is in a render with no floor in it.
    P.add(L.cone(0.070, 0.038, 0.10, 8), 'dark', loc=(f[0], f[1], 0.05))
    _span("prop", i0)

    return P


BUILDERS.update({"paviser": paviser})
