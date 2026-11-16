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

Raw vertex maths only (no bpy.ops, no bmesh.ops) - see lordlib. Original
geometry: nothing here reads a third-party asset. Quaternius Bestiary / QAL is
forbidden on this project, which is why these are generated and not bought.
"""
import math

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
