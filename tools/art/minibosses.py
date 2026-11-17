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

from mathutils import Vector

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
