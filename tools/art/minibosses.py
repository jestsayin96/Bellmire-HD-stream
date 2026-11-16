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
