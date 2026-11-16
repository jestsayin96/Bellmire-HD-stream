"""showcase - D95/D94: named gear that looks like itself, worn on a real body.

Mr. E, 16 Nov 00:55: every item must look like ITSELF. 00:59: ten characters,
different equipment and accessories, four views, "people are not going to waste
money on slop."

WHAT THIS IS. The 86 named weapons, 33 named armour pieces and 254 accessories
in data/items.json were dead data - gear.gd renders a worn accessory from the
SLOT alone, so all 55 rings are one gold torus, and a hero cannot hold
"Ironmonger's Blade", only "fine steel". This module builds a PIECE PER ITEM
from the item's own fields:

    family / cut / slot   picks the silhouette        (blade, axe, robe, boots)
    the item's NAME       overrides the silhouette    (a Guard Helm is a helm)
    tier                  picks the material ladder   (plain steel -> scarforged)
    tier + cost           drive WEAR, the receipt     (rags worn, scarforged new)
    the stat it adds      picks the gem colour        (ac steel, saves violet,
                          hp red, speed green, hit amber, dmg orange)
    the item's own KEY    moves PROPORTION and COUNT  (band width, brim width,
                          hem length, limb curve, how many stones)

D94's proof sheet caught the gap in that list: with only the first five lines,
two items landing on the same name-variant and the same cost quartile landed on
the same OBJECT - five named pairs of them, two tier-5 bows among them. The
last line closes it. Variant still decides the KIND, which is the part a viewer
can name; the key decides the proportions inside it, which is what a
bounds-framed shot can actually see.

The last three derivations are D73's, reused on purpose, so THE ICON IN THE HUB
AND THE THING ON THE HERO MATCH. icons.variant_for and icons.STAT_GEM are
imported rather than copied for exactly that reason.

GEOMETRY IS MEASURED ONTO THE BODY, NOT GUESSED. Every shell (cuirass, jerkin,
robe, cloak, amulet) is built from radii sampled off the real posed body with a
BVH ray cast, offset outward by a stated clearance. That is why the fit report
can be honest: a piece that hugs a measured surface cannot float, and cannot
sink into the chest from the side while looking right from the front.

WEAR IS A VARIABLE, NOT A STYLE (Mr. E, 15 Nov 17:50). Wear rides the tier and
is nudged per character so no two of the ten share a value.

CC0: all geometry is original vertex maths through lordlib. The KayKit
adventurer bodies (CC0, already in the repo) are read for measurement and for
the renders and are never re-exported.
"""
import math
from mathutils import Vector

import lordlib as L
import icons as IC

# Dial and sig LIVE IN icons.py - the lower layer - so the hub icon takes the
# same per-item dials as the worn piece. One copy, not two (D94).
Dial = IC.Dial
sig = IC.sig

TAU = math.pi * 2.0

TIER_NAME = ["rags", "plain steel", "fine steel", "runed", "dragontooth", "scarforged"]
ARM_NAME = ["rags", "leather", "chainmail", "plate", "warded plate", "scarwoven mail"]
RARITY = ["starting", "common", "uncommon", "rare", "very rare", "legendary"]

# THE RECEIPT. A viewer who spent months of points must not get something that
# reads like the starting gambeson. The ladder is value AND hue, not polish:
# brown-iron -> grey steel -> bright steel+brass -> blued steel+rune -> ivory
# dragontooth -> scarforged white with a lit seam.
TIER_METAL = [(0.20, 0.17, 0.14), (0.30, 0.29, 0.28), (0.60, 0.63, 0.68),
              (0.26, 0.31, 0.44), (0.88, 0.84, 0.70), (0.95, 0.95, 0.97)]
TIER_TRIM = [(0.17, 0.14, 0.11), (0.26, 0.22, 0.17), (0.80, 0.63, 0.24),
             (0.45, 0.62, 0.95), (0.62, 0.38, 0.16), (0.92, 0.28, 0.46)]
TIER_GLOW = [None, None, None, (0.42, 0.68, 1.00), (1.00, 0.68, 0.26), (1.00, 0.34, 0.52)]
TIER_CLOTH = [(0.34, 0.31, 0.26), (0.40, 0.36, 0.30), (0.30, 0.33, 0.42),
              (0.26, 0.28, 0.40), (0.42, 0.26, 0.22), (0.56, 0.50, 0.56)]


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def worn(c, w):
    """Wear takes the SHINE off, not the identity. Pass 3 mixed every worn
    surface toward one grey-brown, so a leather jerkin, an iron hauberk and a
    wool robe arrived at the same mud and the ten read as one costume. Wear now
    desaturates and dulls toward the colour's OWN grey, so a brown stays brown."""
    g = (c[0] + c[1] + c[2]) / 3.0
    return mix(c, (g * 0.94, g * 0.92, g * 0.88), max(0.0, min(1.0, w)) * 0.55)


def wear_for(tier, nudge=0.0):
    """A level-1 town's gambeson is make-do; a scarforged hauberk is a receipt
    for months of points and must read NEW. Nudged so no two of the ten match."""
    base = (0.92, 0.86, 0.64, 0.40, 0.18, 0.05)[tier]
    return max(0.0, min(1.0, base + nudge))


def materials(tier, wear, gem=(0.70, 0.70, 0.74), cloth=None, tag="", metal=None):
    """metal=None takes the TIER's metal (equipment). An accessory passes its
    OWN metal, from its cost quartile, so two rings are not one ring."""
    w = max(0.0, min(1.0, wear))
    metal = worn(metal or TIER_METAL[tier], w)
    trim = worn(TIER_TRIM[tier], w)
    cl = worn(cloth or TIER_CLOTH[tier], w)
    m = {
        'metal': L.mat_solid("sc_metal" + tag, metal, 0.24 + 0.56 * w, 0.52 - 0.30 * w),
        'trim': L.mat_solid("sc_trim" + tag, trim, 0.28 + 0.48 * w, 0.48 - 0.28 * w),
        'cloth': L.mat_solid("sc_cloth" + tag, cl, 0.74 + 0.16 * w, 0.02),
        'leather': L.mat_solid("sc_leather" + tag, worn((0.23, 0.14, 0.085), w), 0.76, 0.03),
        'haft': L.mat_solid("sc_haft" + tag, worn((0.31, 0.21, 0.12), w), 0.80, 0.02),
        'dark': L.mat_solid("sc_dark" + tag, worn((0.11, 0.095, 0.09), w), 0.70, 0.10),
        'gem': L.mat_solid("sc_gem" + tag, gem, 0.18, 0.30),
    }
    g = TIER_GLOW[tier]
    m['glow'] = (L.mat_glow("sc_glow" + tag, g, 3.2 - 1.6 * w) if g
                 else L.mat_solid("sc_noglow" + tag, trim, 0.4, 0.8))
    return m


# ===================================== THE ITEM'S OWN KEY REACHES THE GEOMETRY
# D94's proof sheet caught five pairs of named items rendering as ONE object:
# Gatehouse Whistle = Brewster's Charm, Hurdler's = Osier-cutter's Cloak,
# Baker's = Millhand's Mitts, Straw Hat = Miller's Cap, Scarbow = Seamstring.
# The cause was the same every time: the derivation was NAME-VARIANT x COST
# QUARTILE, and two items that land on the same variant and the same quartile
# land on the same object. Two Mitts are both "mitt"; two tier-5 bows are both
# a tier-5 bow.
#
# Variant and quartile still decide the KIND of thing - that is the part a
# viewer can name, and it must stay - but WITHIN a kind the item's own key now
# moves PROPORTION and COUNT. Proportion and count are what survives the proof
# sheet's strip 1, which frames the item to its OWN measured bounds: a
# uniformly bigger ring is the same picture, a ring with a wider band and three
# stones instead of one is not. Deterministic - same key, same object, forever.
class Dial(object):
    """Twelve independent dials off one item key."""
    __slots__ = ("h", "d")

    def __init__(self, h):
        self.h = h
        self.d, x = [], h | 1
        for _ in range(12):
            x = (x * 1103515245 + 12345) & 0x7FFFFFFF
            self.d.append(x)

    def u(self, i, lo=0.0, hi=1.0):
        """A float in [lo, hi) off dial i."""
        return lo + (hi - lo) * (self.d[i % 12] / 2147483648.0)

    def n(self, i, lo, hi):
        """An integer in [lo, hi] off dial i."""
        return lo + self.d[i % 12] % max(1, hi - lo + 1)

    def one(self, i, seq):
        return seq[self.d[i % 12] % len(seq)]

    def bit(self, i, p=0.5):
        return self.u(i) < p


class Part(object):
    """Geometry destined for one bone, authored in the rig's REST world space."""

    def __init__(self, name, bone, item=None, slot=None, touches=True):
        self.name = name
        self.bone = bone
        self.item = item
        self.slot = slot
        self.touches = touches
        self.items = []

    def add(self, vf, mat, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
        v, f = vf
        self.items.append((L.xform(v, loc, rot, scale), f, mat))
        return self

    def raw(self, vf, mat):
        v, f = vf
        self.items.append(([Vector(x) for x in v], f, mat))
        return self


def aim(vf, loc, direction, scale=(1, 1, 1)):
    from mathutils import Matrix
    v, f = vf
    q = Vector(direction).normalized().to_track_quat('Z', 'Y')
    m = (Matrix.Translation(Vector(loc)) @ q.to_matrix().to_4x4()
         @ Matrix.Diagonal(Vector(scale).to_4d()))
    return [m @ Vector(x) for x in v], f


# ============================================================== WEAPONS (hand)
def _grip(p, z0, z1, r=0.030, pommel=0, wraps=0):
    """The grip and its pommel. The pommel is the one part of a hilt that sits
    against the hand at every angle, so it is per-item: ball, cap, wheel, slab."""
    p.raw(L.tube([Vector((0, 0, z0)), Vector((0, 0, z1))], r, 9), 'leather')
    if pommel == 0:
        p.add(L.sphere(r * 1.5, r * 1.5, r * 0.9, 10, 7), 'trim', loc=(0, 0, z0 - 0.02))
    elif pommel == 1:
        p.raw(aim(L.cone(r * 1.9, r * 1.1, 0.032, 12), (0, 0, z0 - 0.036), (0, 0, 1)), 'trim')
    elif pommel == 2:      # a wheel reads as a ring against the hand
        rr = r * 1.75
        ring = [Vector((rr * math.cos(TAU * k / 14.0), 0.0,
                        z0 - 0.020 + rr * math.sin(TAU * k / 14.0))) for k in range(15)]
        p.raw(L.tube(ring, r * 0.50, 6, caps=False), 'trim')
    else:
        p.add(L.box(r * 2.7, r * 2.1, 0.026), 'trim', loc=(0, 0, z0 - 0.024))
    for k in range(wraps):
        z = z0 + (z1 - z0) * (0.26 + 0.48 * (k / float(max(1, wraps))))
        p.raw(L.tube([Vector((0, 0, z - 0.009)), Vector((0, 0, z + 0.009))], r * 1.20, 9), 'dark')


def weapon(name, family, tier, hint="", key=None):
    """Held about the grip at the origin, pointing +Z. One of six families; the
    NAME splits a family where the name says something (an arbalest is not a
    bow, a wand is not a staff, a mace is not a staff, hand wraps are not a
    staff at all); and the item's own KEY moves proportion and count inside
    whatever it ends up being, so two tier-5 bows are not one bow."""
    hay = (name + " " + hint).lower()
    D = sig(key if key is not None else name, name)
    p = Part("Weapon", "handslot.r", item=name, slot="weapon", touches=False)
    t = max(0, min(5, tier))
    # A held weapon is carried, not swung through the owner. The driver moves
    # this to the POSED hand without the shoulder's rotation (pass 1 put every
    # blade horizontally through its owner's chest), so it is authored upright
    # and leaned out from the body here, about the grip.

    # THE NAME OVERRIDES THE FAMILY where the data and the name disagree. The
    # proof sheet's fit report caught "Parish Iron Mace" (family arcane)
    # rendering as a staff, and the three pairs of hand wraps and the knuckles
    # (family open) rendering as 1.3 m quarterstaves standing below the feet.
    blunt = any(k in hay for k in ("mace", "club", "cudgel", "hammer", "maul",
                                  "flail", "morningstar", "mallet"))
    fist = any(k in hay for k in ("wrap", "knuckle", "cestus", "gauntlet", "fist"))
    if fist:
        family = 'fist'
    elif blunt and family in ('arcane', 'open', 'blade'):
        family = 'blunt'
    elif family == 'open':
        family = 'staff'

    if family == 'blade':
        dag = any(k in hay for k in ("dagger", "knife", "dirk", "stiletto"))
        blen = (0.30 if dag else 0.60 + 0.085 * t) * D.u(0, 0.88, 1.13)
        half = (0.080 if dag else 0.150 + 0.022 * t) * D.u(1, 0.70, 1.30)
        _grip(p, -0.11, 0.13, pommel=D.n(2, 0, 3), wraps=D.n(3, 0, 3))
        guard = D.n(4, 0, 2)
        if guard == 0:          # a straight bar
            p.raw(L.tube([Vector((-half, 0, 0.15)), Vector((half, 0, 0.15))],
                         [0.022, 0.030, 0.022] if t >= 2 else 0.024, 8), 'metal')
        elif guard == 1:        # swept down toward the hand
            for s in (-1, 1):
                p.raw(L.tube([Vector((0, 0, 0.155)), Vector((half * 0.72 * s, 0, 0.140)),
                              Vector((half * s, 0, 0.088))], [0.027, 0.022, 0.016], 8), 'metal')
        else:                   # a ring guard, read as a hole at the hand
            rr = half * 0.80
            ring = [Vector((rr * math.cos(TAU * k / 16.0), 0.0,
                            0.150 + rr * math.sin(TAU * k / 16.0))) for k in range(17)]
            p.raw(L.tube(ring, 0.017, 6, caps=False), 'metal')
            p.raw(L.tube([Vector((-rr, 0, 0.150)), Vector((rr, 0, 0.150))], 0.020, 7), 'metal')
        if t >= 2 and guard == 0:
            for s in (-1, 1):
                p.raw(aim(L.cone(0.026, 0.012, 0.085, 7), (half * s, 0, 0.155),
                          (s * 0.5, 0, 1)), 'metal')
        w0 = (0.075 + 0.006 * t) * D.u(5, 0.78, 1.28)
        w1 = w0 * D.u(6, 0.22, 0.78)            # taper: parallel, leaf or needle
        prof = D.u(7, 1.05, 2.30)
        edge, back = [], []
        n = 9
        for i in range(n):
            u = i / (n - 1.0)
            z = 0.17 + blen * u
            ww = w0 + (w1 - w0) * (u ** prof)
            edge.append(Vector((ww, 0, z)))
            back.append(Vector((-ww, 0, z)))
        edge.append(Vector((0.0, 0, 0.17 + blen + blen * D.u(8, 0.07, 0.22))))
        p.raw(L.membrane(edge + back[::-1], 0.030 + 0.004 * t), 'metal')
        if t >= 3:
            p.raw(L.tube([Vector((0, -0.017, 0.26)), Vector((0, -0.017, 0.17 + blen * 0.86))],
                         0.012, 6), 'glow')
        if t >= 4:
            p.add(L.sphere(0.034, 0.026, 0.044, 10, 7), 'gem', loc=(0, -0.030, 0.19))
        if t >= 5:
            zz = [0.22 + 0.11 * k for k in range(6)]
            p.raw(L.tube([Vector(((0.018 if k % 2 else -0.018), -0.020, z))
                          for k, z in enumerate(zz)], 0.009, 5), 'glow')

    elif family == 'axe':
        great = any(k in hay for k in ("greataxe", "maul", "splitter", "cleaver", "wallbreaker"))
        hl = ((1.26 if great else 0.86) + 0.05 * t) * D.u(0, 0.90, 1.12)
        p.raw(L.tube([Vector((0, 0, -0.22)), Vector((0, 0, hl * 0.6)), Vector((0, 0, hl))],
                     [0.034, 0.030, 0.027], 9), 'haft')
        for zz in (-0.12, 0.06):
            p.raw(L.tube([Vector((0, 0, zz - 0.045)), Vector((0, 0, zz + 0.045))], 0.040, 9), 'leather')
        ztop = hl
        reach = (0.230 + 0.04 * t) * D.u(1, 0.76, 1.26)      # how far the head stands out
        drop = D.u(2, 0.20, 0.42)                            # how deep the beard hangs
        rise = D.u(3, 0.02, 0.14)                            # how high the horn climbs
        beard = [Vector((0.030, 0, ztop - drop)), Vector((reach * 0.72, 0, ztop - drop * 1.10)),
                 Vector((reach, 0, ztop - drop * 0.40)), Vector((reach * 0.76, 0, ztop + rise)),
                 Vector((0.030, 0, ztop + rise * 0.6))]
        p.raw(L.membrane(beard, 0.040 + 0.006 * t), 'metal')
        p.raw(L.tube([Vector((0, 0, ztop - drop - 0.04)), Vector((0, 0, ztop + rise + 0.02))],
                     0.044, 9), 'metal')
        for k in range(D.n(4, 0, 2)):            # langets down the haft
            p.add(L.box(0.016, 0.052, 0.085), 'metal', loc=(0, 0, ztop - drop - 0.10 - 0.11 * k))
        if t >= 3:
            p.raw(aim(L.cone(0.050, 0.0, 0.14 + 0.12 * D.u(5), 7),
                      (-0.030, 0, ztop - 0.10), (-1, 0, 0.15)), 'metal')
            p.add(L.sphere(0.034, 0.014, 0.034, 10, 7), 'glow',
                  loc=(reach * 0.56, -0.028, ztop - drop * 0.45))
        if t >= 4 or D.bit(6, 0.30):             # the double head
            mirror = [Vector((-q.x, q.y, q.z)) for q in beard]
            p.raw(L.membrane(mirror, 0.040), 'metal')
        if t >= 5:
            p.raw(aim(L.cone(0.038, 0.0, 0.26, 7), (0, 0, ztop + rise + 0.03), (0, 0, 1)), 'glow')

    elif family == 'blunt':
        # A MACE IS NOT A STAFF. Short shaft, all the mass at the top, and the
        # head is the item's own: flanges, a faceted block, a knotted ball or a
        # spiked ball. Plain, like a thing for hitting with.
        hl = (0.56 + 0.04 * t) * D.u(0, 0.90, 1.14)
        _grip(p, -0.14, 0.10, r=0.031, pommel=D.n(1, 0, 3), wraps=D.n(2, 1, 3))
        p.raw(L.tube([Vector((0, 0, 0.08)), Vector((0, 0, hl))], [0.026, 0.023], 9), 'haft')
        head = D.n(3, 0, 3)
        hz = hl + 0.055
        rr = 0.058 * D.u(4, 0.86, 1.26)
        if head == 0:                 # flanged
            flan = D.n(5, 4, 7)
            p.raw(aim(L.cone(0.040, 0.034, 0.145, 10), (0, 0, hl - 0.045), (0, 0, 1)), 'metal')
            for k in range(flan):
                a = TAU * k / flan
                quad = [Vector((0.028 * math.cos(a), 0.028 * math.sin(a), hl - 0.035)),
                        Vector((rr * 1.45 * math.cos(a), rr * 1.45 * math.sin(a), hl + 0.010)),
                        Vector((rr * 1.45 * math.cos(a), rr * 1.45 * math.sin(a), hl + 0.062)),
                        Vector((0.028 * math.cos(a), 0.028 * math.sin(a), hl + 0.085))]
                p.raw(L.membrane(quad, 0.019), 'metal')
        elif head == 1:               # a squared hammer block
            p.add(L.box(rr * 1.5, rr * 2.5, rr * 1.7), 'metal', loc=(0, 0, hz - 0.02))
            p.raw(aim(L.cone(rr * 0.62, rr * 0.34, rr * 1.1, 8),
                      (0, -rr * 1.25, hz - 0.02), (0, -1, 0)), 'metal')
        elif head == 2:               # a knotted club
            for k in range(D.n(6, 3, 5)):
                u = k / float(max(1, D.n(6, 3, 5) - 1))
                p.add(L.sphere(rr * (1.0 - 0.18 * u), rr * (0.92 - 0.14 * u), rr * 0.62, 10, 7),
                      'haft', loc=(0, 0, hl - 0.02 + 0.072 * k))
        else:                         # a spiked ball
            p.add(L.sphere(rr, rr, rr, 12, 9), 'metal', loc=(0, 0, hz))
            for k in range(D.n(7, 5, 9)):
                a = TAU * k / max(1, D.n(7, 5, 9))
                e = 0.5 - 1.0 * ((k % 3) / 3.0)
                d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
                p.raw(aim(L.cone(0.015, 0.0, 0.055, 6),
                          (d.x * rr * 0.9, d.y * rr * 0.9, hz + d.z * rr * 0.9), d), 'metal')
        if t >= 3:
            p.raw(L.tube([Vector((0, 0, hl - 0.10)), Vector((0, 0, hl - 0.055))], 0.030, 9), 'glow')
        if t >= 5:
            p.add(L.sphere(0.022, 0.022, 0.022, 10, 7), 'glow', loc=(0, 0, hz + rr * 1.1))

    elif family == 'fist':
        # HAND WRAPS ARE NOT A QUARTERSTAFF. The fit report had Cold-White
        # Wraps standing 0.065 m below the feet because this family fell
        # through to the staff. It is a small piece at the hand: cloth round
        # the knuckles, and knuckles get a bar.
        knuck = "knuckle" in hay or "cestus" in hay
        rw = 0.052 * D.u(0, 0.90, 1.16)
        turns = D.n(1, 3, 6)
        for k in range(turns):
            z = -0.055 + 0.112 * (k / float(max(1, turns - 1)))
            tw = 0.013 * D.u(2, 0.80, 1.35)
            ring = [Vector((rw * math.cos(TAU * j / 12.0) * 1.05,
                            rw * math.sin(TAU * j / 12.0) * 0.76, z + 0.006 * math.sin(TAU * j / 12.0)))
                    for j in range(13)]
            p.raw(L.tube(ring, tw, 6, caps=False), 'cloth')
        p.add(L.sphere(rw * 1.08, rw * 0.80, 0.030, 12, 8), 'cloth', loc=(0, 0, 0.068))
        if knuck:
            for k in range(4):
                p.add(L.box(0.018, 0.016, 0.020), 'metal',
                      loc=(-0.030 + 0.020 * k, -rw * 0.62, 0.070))
        for k in range(D.n(3, 0, 2)):      # a tail of loose cloth
            p.raw(L.tube([Vector((rw * 0.9, -0.010 * k, -0.050)),
                          Vector((rw * 1.5, -0.030 - 0.02 * k, -0.120 - 0.03 * k))],
                         [0.012, 0.007], 6), 'cloth')
        if t >= 3:
            p.raw(L.tube([Vector((-rw, -rw * 0.5, 0.030)), Vector((rw, -rw * 0.5, 0.030))],
                         0.008, 6), 'glow')
        if t >= 4:
            p.add(L.sphere(0.018, 0.012, 0.018, 10, 7), 'gem', loc=(0, -rw * 0.72, 0.012))

    elif family == 'arcane':
        wand = any(k in hay for k in ("wand", "rod"))
        hl = ((0.52 if wand else 1.58) + 0.03 * t) * D.u(0, 0.90, 1.10)
        p.raw(L.tube([Vector((0, 0, -0.18)), Vector((0, 0, hl * 0.5)), Vector((0, 0, hl))],
                     [0.028, 0.025, 0.021] if wand else [0.032, 0.028, 0.024], 9), 'haft')
        if not wand:
            p.raw(L.tube([Vector((0, 0, 0.0)), Vector((0, 0, 0.09))], 0.038, 9), 'leather')
        arms = D.n(1, 2, 4)
        curl = D.u(2, 0.035, 0.085)
        for k in range(arms):
            a = (TAU * k / arms) if arms > 2 else (math.pi * k)
            cx, cy = math.cos(a), math.sin(a)
            p.raw(L.tube([Vector((0, 0, hl - 0.10)),
                          Vector((curl * cx, curl * cy, hl + 0.02)),
                          Vector((curl * 0.55 * cx, curl * 0.55 * cy, hl + 0.14))],
                         [0.021, 0.017, 0.012], 7), 'metal')
        orb = (0.054 + 0.006 * t) * D.u(3, 0.72, 1.34)
        p.add(L.sphere(orb, orb * 0.90, orb * 1.14, 12, 9),
              'glow' if t >= 3 else 'gem', loc=(0, 0, hl + 0.055))
        for k in range(D.n(4, 0, 3) if t >= 3 else 0):
            r = 0.072 - 0.012 * k
            zz = hl - 0.30 - 0.16 * k
            ring = [Vector((r * math.cos(TAU * i / 14.0), r * math.sin(TAU * i / 14.0), zz))
                    for i in range(15)]
            p.raw(L.tube(ring, 0.011, 6, caps=False), 'glow')
        if t >= 4:
            for k in range(D.n(5, 1, 3)):
                p.add(L.sphere(0.020, 0.018, 0.026, 8, 6), 'gem',
                      loc=(0, -0.032, hl - 0.62 - 0.10 * k))

    elif family == 'ranged':
        bow = ("bow" in hay or "string" in hay or "thrum" in hay) and "crossbow" not in hay
        # THE TOP OF THE LADDER MUST LOOK LIKE IT. The proof sheet caught both
        # tier-5 bows coming back plain brown wood, visually below a tier-3
        # sword, because wear rode the tier for blades and never reached this
        # family. Condition is the receipt: a legendary bow is a metal-backed
        # limb with a lit string, not a stick.
        limb = 'haft' if t <= 2 else 'metal'
        strg = 'cloth' if t <= 4 else 'glow'
        if bow:
            form = D.n(0, 0, 2)                  # longbow, recurve, flatbow
            span = (0.78 + 0.05 * t) * D.u(1, 0.86, 1.16) * (1.12 if form == 0 else 0.92)
            belly = D.u(2, 0.035, 0.085)         # how far the limb bows away
            lr = [0.028, 0.022, 0.015]
            if form == 2:
                lr = [0.036, 0.030, 0.018]       # a flatbow is a wide limb
            for s in (-1, 1):
                if form == 1:                    # recurve: the tip turns back
                    pts = [Vector((0, 0.0, 0.0)), Vector((0, -belly, span * 0.50 * s)),
                           Vector((0, -belly * 0.3, span * 0.82 * s)),
                           Vector((0, belly * 1.5, span * s))]
                    p.raw(L.tube(pts, [lr[0], lr[1], lr[2], lr[2] * 0.8], 8), limb)
                else:
                    p.raw(L.tube([Vector((0, 0.0, 0.0)), Vector((0, -belly, span * 0.52 * s)),
                                  Vector((0, belly * 1.4, span * s))], lr, 8), limb)
            p.raw(L.tube([Vector((0, belly * 1.4, span)), Vector((0, belly * 1.4, -span))],
                         0.007, 5), strg)
            p.raw(L.tube([Vector((0, 0, -0.10)), Vector((0, 0, 0.10))], 0.034, 9), 'leather')
            for k in range(D.n(3, 0, 3)):        # serving wraps up the riser
                z = 0.12 + 0.055 * k
                for sgn in (-1, 1):
                    p.raw(L.tube([Vector((0, -0.006, sgn * z - 0.010)),
                                  Vector((0, -0.006, sgn * z + 0.010))], 0.030, 8), 'dark')
            if D.bit(4, 0.45):                   # a quiver of arrows at the riser
                for k in range(D.n(5, 3, 5)):
                    p.raw(L.tube([Vector((0.028 + 0.012 * k, 0.036, -span * 0.25)),
                                  Vector((0.028 + 0.012 * k, 0.036, span * 0.40))],
                                 0.005, 5), 'haft')
            if t >= 3:
                p.add(L.sphere(0.030, 0.016, 0.030, 10, 7), 'glow', loc=(0, -0.034, 0.0))
            if t >= 4:
                for s in (-1, 1):
                    p.add(L.sphere(0.024, 0.020, 0.034, 8, 6), 'gem',
                          loc=(0, 0.02, span * 0.70 * s))
            if t >= 5:                           # the lit seam up both limbs
                for s in (-1, 1):
                    p.raw(L.tube([Vector((0, -belly * 0.4, span * 0.14 * s)),
                                  Vector((0, -belly * 0.9, span * 0.56 * s)),
                                  Vector((0, belly * 0.6, span * 0.94 * s))],
                                 [0.008, 0.007, 0.005], 5), 'glow')
        else:
            stock = (0.70 + 0.03 * t) * D.u(0, 0.86, 1.16)
            prod = (0.30 + 0.02 * t) * D.u(1, 0.82, 1.22)
            sweep = D.u(2, 0.34, 0.52)
            p.add(L.box(0.060, stock, 0.055), 'haft', loc=(0, -0.10, 0.06))
            p.add(L.box(0.055, 0.17, 0.11), 'haft', loc=(0, 0.17, -0.02))
            p.raw(L.tube([Vector((-prod, -sweep - 0.06, 0.09)), Vector((0, -sweep - 0.12, 0.09)),
                          Vector((prod, -sweep - 0.06, 0.09))], [0.017, 0.022, 0.017], 7), limb)
            p.raw(L.tube([Vector((-prod * 0.93, -sweep - 0.05, 0.09)),
                          Vector((0, -0.16, 0.09)),
                          Vector((prod * 0.93, -sweep - 0.05, 0.09))], 0.006, 5), strg)
            p.add(L.box(0.040, 0.10, 0.045), 'metal', loc=(0, 0.02, 0.10))
            p.raw(aim(L.cone(0.022, 0.016, 0.085, 7), (0, 0.07, 0.00), (0, 0.3, -1)), 'metal')
            if D.bit(3, 0.5):      # a stirrup at the nose
                rr = 0.060
                ring = [Vector((rr * math.cos(TAU * k / 12.0), -stock * 0.52 + 0.02,
                                0.03 + rr * math.sin(TAU * k / 12.0))) for k in range(13)]
                p.raw(L.tube(ring, 0.011, 6, caps=False), 'metal')
            for k in range(D.n(4, 0, 3)):        # bolts in the stock
                p.raw(L.tube([Vector((-0.018 + 0.018 * k, -0.34, 0.098)),
                              Vector((-0.018 + 0.018 * k, 0.06, 0.098))], 0.004, 5), 'haft')
            if t >= 3:
                p.add(L.sphere(0.026, 0.026, 0.020, 10, 7), 'glow', loc=(0, -0.02, 0.115))
            if t >= 4:
                p.add(L.box(0.030, 0.16, 0.030), 'gem', loc=(0, -0.34, 0.115))
            if t >= 5:
                p.raw(L.tube([Vector((0, -stock * 0.46, 0.092)), Vector((0, 0.10, 0.092))],
                             0.006, 5), 'glow')

    else:
        # a quarterstaff: two ferrules and a plain shaft, per-item in length,
        # ferrule count and where the grip sits
        lo = -(0.56 + 0.06 * D.u(0))
        hi = 0.66 + 0.14 * D.u(1)
        p.raw(L.tube([Vector((0, 0, lo)), Vector((0, 0, hi))], [0.028, 0.028], 9), 'haft')
        for k in range(D.n(2, 2, 4)):
            zz = lo + 0.06 + (hi - lo - 0.12) * (k / float(max(1, D.n(2, 2, 4) - 1)))
            p.raw(L.tube([Vector((0, 0, zz - 0.05)), Vector((0, 0, zz + 0.05))], 0.036, 9),
                  'metal' if k % 2 == 0 else 'leather')
        if t >= 3:
            p.raw(L.tube([Vector((0, -0.020, lo + 0.20)), Vector((0, -0.020, hi - 0.20))],
                         0.008, 5), 'glow')
        if t >= 5:
            p.add(L.sphere(0.034, 0.030, 0.042, 10, 7), 'glow', loc=(0, 0, hi + 0.03))
    lean = -0.17
    from mathutils import Matrix
    R = Matrix.Rotation(lean, 4, 'Y')
    p.items = [([R @ v for v in verts], f, m) for verts, f, m in p.items]
    return p


# =========================================================== ARMOUR (the body)
def _shell(p, S, z0, z1, rings, clear, mat, arc=TAU, arc0=0.0, bulge=1.0, prof=None):
    """A band of membrane panels standing `clear` off the MEASURED body.
    `prof` is [(u, factor)] up the height, so a cuirass can have a waist."""
    def fac(u):
        if not prof:
            return 1.0
        for i in range(len(prof) - 1):
            u0, f0 = prof[i]
            u1, f1 = prof[i + 1]
            if u0 <= u <= u1:
                k = (u - u0) / max(1e-6, u1 - u0)
                return f0 + (f1 - f0) * k
        return prof[-1][1]
    n = 16
    for i in range(rings - 1):
        ua, ub = i / (rings - 1.0), (i + 1) / (rings - 1.0)
        za, zb = z0 + (z1 - z0) * ua, z0 + (z1 - z0) * ub
        for k in range(n):
            a0 = arc0 + arc * k / float(n) - 0.012
            a1 = arc0 + arc * (k + 1) / float(n) + 0.012
            quad = []
            for z, a, u in ((za, a0, ua), (za, a1, ua), (zb, a1, ub), (zb, a0, ub)):
                r = (S.r(z, a) + clear) * bulge * fac(u)
                quad.append(Vector((r * math.cos(a), r * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.022), mat)


def r_clear(S, z, a, clear):
    """Radius that clears EVERYTHING at this height, legs included. The torso
    sampler ignores arms and legs on purpose (a ray at shoulder height that hit
    a hanging arm would make the cuirass a barrel), so a skirt or a cloak, which
    hangs past the legs, asks the whole-body sampler as well."""
    r = S.r(z, a)
    full = getattr(S, "full", None)
    if full is not None:
        r = max(r, full.r(z, a))
    return r + clear


def _band(p, S, z, clear, rad, mat, arc=TAU, arc0=0.0):
    pts = []
    n = 22
    for k in range(n + 1):
        a = arc0 + arc * k / float(n)
        r = S.r(z, a) + clear
        pts.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    p.raw(L.tube(pts, rad, 7, caps=False), mat)


def armour(name, cut, tier, S, anchors):
    """Three cuts so a caster and a heavy are not the same man in two colours."""
    parts = []
    t = tier
    sh = anchors['upperarm.l'].z
    hip = anchors['hips'].z
    chest = anchors['chest'].z
    ankle = anchors['foot.l'].z

    if cut == 'heavy':
        p = Part("Armour_Cuirass", "chest", item=name, slot="armour")
        # it has a WAIST: pulled in at the belt, out at the chest, or it reads
        # as a board hung round the neck (which is exactly what pass 1 did)
        waist = [(0.0, 0.96), (0.42, 0.92), (0.72, 1.05), (1.0, 1.02)]
        _shell(p, S, hip + 0.02, sh + 0.045, 6, 0.030 + 0.004 * t, 'metal', prof=waist)
        _band(p, S, sh + 0.040, 0.030 + 0.003 * t, 0.015, 'trim')
        _band(p, S, hip + 0.03, 0.026 + 0.003 * t, 0.015, 'trim')
        ridge = []                       # the breast ridge - a centre line
        for k in range(7):
            u = k / 6.0
            z = hip + 0.10 + (sh - hip - 0.04) * u
            r = S.r(z, -math.pi * 0.5) + 0.046 + 0.004 * t
            ridge.append(Vector((0, -r, z)))
        p.raw(L.tube(ridge, [0.013, 0.018, 0.020, 0.018, 0.014, 0.011, 0.008], 7, caps=False), 'metal')
        if t >= 3:
            _band(p, S, hip + 0.16, 0.040, 0.013, 'glow')
        if t >= 4:
            for row in range(3):
                z = hip + 0.22 + 0.13 * row
                for k in range(10):
                    a = TAU * k / 10.0 + 0.15 * row
                    r = S.r(z, a) + 0.046
                    p.add(L.box(0.070, 0.022, 0.048), 'trim',
                          loc=(r * math.cos(a), r * math.sin(a), z),
                          rot=(0, 0, a + math.pi * 0.5))
        parts.append(p)
        for side in ('l', 'r'):
            a = anchors['upperarm.' + side]
            sgn = 1.0 if side == 'l' else -1.0
            q = Part("Armour_Pauldron" + side.upper(), "upperarm." + side, item=name, slot="armour")
            for k in range(2 + (t >= 3)):
                rr = 0.175 - 0.026 * k
                v, f = L.sphere(rr * 1.05, rr * 1.20, rr * 0.62, 14, 8)
                vv = [Vector((x.x, x.y, max(x.z, -rr * 0.10))) for x in v]
                q.add((vv, f), 'metal', loc=(a.x + sgn * (0.020 + 0.062 * k), a.y, a.z - 0.010 - 0.080 * k))
            if t >= 2:
                q.add(L.sphere(0.034, 0.030, 0.022, 10, 7), 'trim', loc=(a.x + sgn * 0.02, a.y - 0.14, a.z + 0.05))
            if t >= 5:
                q.add(L.sphere(0.030, 0.026, 0.030, 10, 7), 'glow', loc=(a.x + sgn * 0.10, a.y, a.z + 0.01))
            parts.append(q)
        tas = Part("Armour_Tassets", "hips", item=name, slot="armour")
        for s in (-1, 1):
            for k in range(2):
                a = (0.42 + 0.46 * k) * math.pi * (-s) - math.pi * 0.5
                r = S.r(hip - 0.02, a) + 0.034
                top = Vector((r * math.cos(a), r * math.sin(a), hip + 0.02))
                bot = Vector((r * 1.06 * math.cos(a), r * 1.06 * math.sin(a), hip - 0.30))
                wide = Vector((-math.sin(a), math.cos(a), 0)) * 0.085
                tas.raw(L.membrane([top - wide, top + wide, bot + wide * 1.15, bot - wide * 1.15], 0.026), 'metal')
        parts.append(tas)

    elif cut == 'light':
        p = Part("Armour_Jerkin", "chest", item=name, slot="armour")
        _shell(p, S, hip + 0.09, sh + 0.025, 5, 0.022 + 0.003 * t, 'leather',
               arc=TAU * 0.86, arc0=math.pi * 0.60,
               prof=[(0.0, 0.97), (0.55, 0.94), (1.0, 1.04)])
        for k in range(5):          # the lacing down the open front
            z = hip + 0.18 + 0.11 * k
            r = S.r(z, -math.pi * 0.5) + 0.030
            p.raw(L.tube([Vector((-0.055, -r, z)), Vector((0.055, -r, z - 0.030))],
                         0.010, 5), 'trim')
        _band(p, S, hip + 0.12, 0.026, 0.020, 'trim')
        _band(p, S, sh + 0.025, 0.024, 0.013, 'leather')
        nstud = 1 + 2 * (t >= 2) + 2 * (t >= 4)
        for k in range(nstud + 1):
            a = math.pi * 0.62 + (TAU * 0.76) * k / max(1.0, nstud)
            for z in (chest - 0.02, chest + 0.12):
                r = S.r(z, a) + 0.034
                p.add(L.sphere(0.021, 0.021, 0.021, 7, 5), 'metal',
                      loc=(r * math.cos(a), r * math.sin(a), z))
        strap = []
        for k in range(9):
            u = k / 8.0
            z = hip + 0.10 + (sh + 0.06 - hip - 0.10) * u
            a = -math.pi * 0.5 + 0.9 * u
            r = S.r(z, a) + 0.030
            strap.append(Vector((r * math.cos(a), r * math.sin(a), z)))
        p.raw(L.tube(strap, 0.028, 6, caps=False), 'trim')
        if t >= 3:
            p.raw(L.tube(strap, 0.011, 5, caps=False), 'glow')
        parts.append(p)

    else:  # robe
        p = Part("Armour_Robe", "chest", item=name, slot="armour")
        _shell(p, S, hip + 0.04, sh + 0.030, 4, 0.026, 'cloth')
        rings, n = 7, 18
        z0, z1 = hip + 0.06, ankle + 0.035
        for i in range(rings - 1):
            za = z0 + (z1 - z0) * i / (rings - 1.0)
            zb = z0 + (z1 - z0) * (i + 1) / (rings - 1.0)
            fa = 1.0 + 0.30 * ((z0 - za) / max(0.01, z0 - z1)) ** 1.4
            fb = 1.0 + 0.30 * ((z0 - zb) / max(0.01, z0 - z1)) ** 1.4
            for k in range(n):
                a0, a1 = TAU * k / n, TAU * (k + 1) / n
                quad = []
                for z, a, f in ((za, a0, fa), (za, a1, fa), (zb, a1, fb), (zb, a0, fb)):
                    fold = 1.0 + 0.045 * math.cos(6.0 * a)   # folds, not a cone
                    r = max((S.r(z0, a) + 0.030) * f, r_clear(S, z, a, 0.034)) * fold
                    quad.append(Vector((r * math.cos(a), r * math.sin(a), z)))
                p.raw(L.membrane(quad, 0.020), 'cloth')
        _band(p, S, hip + 0.14, 0.032, 0.022, 'trim')
        if t >= 3:
            hemr = (S.r(z1, 0.0) + 0.030) * 1.55
            hem = [Vector((hemr * math.cos(TAU * k / 26.0), hemr * math.sin(TAU * k / 26.0), z1))
                   for k in range(27)]
            p.raw(L.tube(hem, 0.014, 6, caps=False), 'glow')
        for side in ('l', 'r'):
            a = anchors['upperarm.' + side]
            sgn = 1.0 if side == 'l' else -1.0
            q = Part("Armour_Sleeve" + side.upper(), "upperarm." + side, item=name, slot="armour")
            q.raw(aim(L.cone(0.095, 0.145, 0.30, 12), (a.x + sgn * 0.22, a.y, a.z), (sgn, 0, 0)), 'cloth')
            if t >= 4:
                q.add(L.sphere(0.026, 0.024, 0.026, 8, 6), 'gem', loc=(a.x + sgn * 0.08, a.y - 0.07, a.z + 0.03))
            parts.append(q)
        parts.append(p)
    return parts


# ========================================================= ACCESSORIES (worn)
def acc_ring(name, key, cost, ctx, anchors, S):
    v = ctx['variant']
    D = sig(key, name)
    h = anchors['hand.l']
    x = h.x + 0.052
    p = Part("Acc_Ring", "hand.l", item=name, slot="ring")
    rr = 0.052 * D.u(0, 0.92, 1.10)
    band = (0.012 + 0.005 * ctx['orn']) * D.u(1, 0.70, 1.55)
    oval = D.u(2, 0.82, 1.18)              # a bounds-framed shot sees the RATIO
    wires = D.n(3, 1, 3)
    pts = [Vector((x, rr * math.cos(TAU * k / 18.0),
                   h.z + rr * oval * math.sin(TAU * k / 18.0))) for k in range(19)]
    if v == 2:
        freq = D.n(4, 3, 6)
        for s in (-1, 1):
            tw = [Vector((x + s * 0.008 * math.sin(TAU * freq * k / 18.0),
                          rr * math.cos(TAU * k / 18.0),
                          h.z + rr * oval * math.sin(TAU * k / 18.0))) for k in range(19)]
            p.raw(L.tube(tw, band * 0.62, 6), 'metal')
    else:
        for w in range(wires):
            dx = (w - (wires - 1) * 0.5) * band * 1.25
            p.raw(L.tube([Vector((pt.x + dx, pt.y, pt.z)) for pt in pts],
                         band / max(1.0, wires * 0.72), 8), 'metal')
    top = Vector((x, 0.0, h.z + rr * oval + 0.012))
    if v == 1:
        bw, bh = 0.030 * D.u(5, 0.72, 1.32), 0.034 * D.u(6, 0.72, 1.32)
        p.add(L.box(bw, bh, 0.012), 'metal', loc=(top.x, top.y, top.z))
        p.add(L.box(bw * 0.56, bh * 0.58, 0.010), 'dark', loc=(top.x - 0.008, top.y, top.z))
    elif v == 3:
        st = 0.019 * D.u(5, 0.72, 1.34)
        p.add(L.sphere(st, st * 0.90, st * 0.78, 10, 7), 'gem', loc=(top.x, top.y, top.z + 0.004))
        for k in range(D.n(6, 2, 6)):
            a = TAU * k / max(1, D.n(6, 2, 6)) + 0.7
            p.add(L.sphere(0.006, 0.006, 0.006, 6, 5), 'metal',
                  loc=(top.x, top.y + 0.013 * math.cos(a), top.z + 0.013 * math.sin(a) - 0.004))
    elif v == 4:
        for dx in (-0.006, 0.006):
            p.raw(L.tube([Vector((pt.x + dx, pt.y, pt.z)) for pt in pts], band * 0.40, 6), 'dark')
        for k in range(D.n(5, 0, 4)):      # cut notches round the band
            a = TAU * k / max(1, D.n(5, 0, 4))
            p.add(L.box(0.009, 0.007, 0.007), 'dark',
                  loc=(x, rr * math.cos(a) * 0.96, h.z + rr * oval * math.sin(a) * 0.96))
    else:
        st = 0.013 * D.u(5, 0.70, 1.45)
        p.add(L.sphere(st, st * 0.92, st * 0.85, 10, 7), 'gem', loc=(top.x, top.y, top.z))
    for k in range(D.n(7, 0, 2)):          # shoulder stones beside the setting
        for s in (-1, 1):
            p.add(L.sphere(0.0055, 0.0055, 0.0055, 6, 5), 'gem',
                  loc=(x, s * (0.016 + 0.009 * k), h.z + rr * oval * 0.86))
    return [p]


def acc_gloves(name, key, cost, ctx, anchors, S):
    """D94: GLOVES MUST READ ON A BODY. Mr. E, 16 Nov 04:56: "gloves can be
    seen". The dials come from icons.glove_form - THE SAME CALL THE HUB ICON
    MAKES - so the glove in the satchel is the glove on the hand.

    Everything is measured off this body, not guessed:
      forearm   lowerarm -> wrist          (0.26 on the KayKit adventurer)
      hand      wrist -> fingertip         (0.258)
      fist      ray cast out of the hand   (~0.15 across)
    The cuff runs UP THE FOREARM towards the elbow, the lip flares past the
    arm, and the knuckle plate stands off the back of the fist. All three ride
    COST. The shell is never smaller than the hand under it - that was the
    whole fault: 0.085 of glove on 0.15 of fist.
    """
    v, orn = ctx['variant'], ctx['orn']
    D = sig(key, name)
    F = IC.glove_form(v, orn, D)
    out = []
    for side in ('l', 'r'):
        sgn = 1.0 if side == 'l' else -1.0
        w = anchors['wrist.' + side]
        hd = anchors['hand.' + side]
        lo = anchors.get('lowerarm.' + side, w)
        # MEASURED, not assumed. The arm lies along +-X in rest, so the
        # forearm is the span from the elbow bone to the wrist bone.
        forearm = max(0.12, abs(w.x - lo.x))
        handlen = max(0.12, abs(hd.x - w.x) * 2.0)
        # THE RADII COME FROM THE BONES, NOT FROM A MESH SCAN. Scanning the
        # arm mesh for a radius returned 0.154 at the wrist on a body whose
        # whole fist is 0.15 across, and that number is what turned the first
        # pass of these gloves into dinner plates. Bone spacing is exact and
        # scales with any body: on the KayKit adventurer handlen is 0.1477 and
        # the fist measures 0.15 across (x0.50) and the forearm 0.11 (x0.38).
        fist = handlen * 1.00                      # across, = 2 x 0.50
        ar = handlen * 0.38                        # forearm RADIUS
        p = Part("Acc_Glove" + side.upper(), "hand." + side, item=name, slot="gloves")
        cuff = forearm * F['cuff']                 # up the forearm: 0.04 -> 0.24
        mouth = ar * F['flare']                    # the lip, CLEAR of the arm
        hw = fist * 0.5 * F['shell']               # ALWAYS > the fist
        # 1. THE CUFF - the readable mass. IT STAYS ON THE HAND BONE. Moving
        #    it to lowerarm.<side> was tried and is wrong: merge_parts carries
        #    each part rigidly on its own bone, so the cuff and the hand shell
        #    pulled apart in the idle pose and the sheet showed a bucket
        #    floating beside a box. One bone, one glove.
        #    The cuff BASE starts inside the hand shell, not at the wrist
        #    bone: based at the bone it left a 0.028 m hole between cuff and
        #    shell and the sheet showed a tub floating over a box.
        #    WHAT CHANGED AT MR. E'S 10:24 RULING: the silhouette no longer
        #    comes from the BELL MOUTH alone. Flare and shell are UNTOUCHED -
        #    a wider mouth was tried and looked like dinner plates. It comes
        #    from REACH up the forearm (a vambrace is a forearm piece, a wrap
        #    is a wrist piece), from LAMES breaking that reach up, and from a
        #    COP at the elbow end. Length along the arm costs no girth.
        base = (w.x + sgn * handlen * 0.30, w.y, w.z)
        axis = (-sgn, 0, 0)
        if F['stepped']:
            # a straight sleeve with ONE shoulder in it - a different outline
            # from the bell, which is the point: same price, different glove.
            mid = mouth * 0.62 + hw * 0.38
            p.raw(aim(L.cone(hw * 0.99, mid, cuff * 0.55 + handlen * 0.30, 14),
                      base, axis), 'metal' if F['metal'] else 'leather')
            p.raw(aim(L.cone(mid * 1.04, mouth, cuff * 0.45, 14),
                      (w.x - sgn * cuff * 0.55, w.y, w.z), axis),
                  'metal' if F['metal'] else 'leather')
        else:
            p.raw(aim(L.cone(hw * 0.99, mouth, cuff + handlen * 0.30, 14),
                      base, axis), 'metal' if F['metal'] else 'leather')
        if F['lip']:                               # a hard flared rim
            lipx = w.x - sgn * cuff
            ring = [Vector((lipx, mouth * 1.02 * math.cos(TAU * k / 16.0),
                            w.z + mouth * 1.02 * math.sin(TAU * k / 16.0)))
                    for k in range(17)]
            p.raw(L.tube(ring, mouth * 0.13, 7, caps=False),
                  'metal' if F['metal'] else 'dark')
        # 1b. LAMES - the segmentation. These are what tell two vambraces of
        #     the same price apart: a 3-lame and a 6-lame are two outlines.
        #     They used to be "straps counted off the plate count", which is
        #     why every cheap glove wore exactly one.
        for k in range(F['lames']):
            f = (k + 0.7) / (F['lames'] + 0.4)
            sx = w.x - sgn * (cuff * f)
            rr = hw * 0.96 + (mouth - hw * 0.96) * f
            ring = [Vector((sx, rr * 1.025 * math.cos(TAU * j / 14.0),
                            w.z + rr * 1.025 * math.sin(TAU * j / 14.0)))
                    for j in range(15)]
            p.raw(L.tube(ring, max(0.004, rr * (0.075 if F['metal'] else 0.095)), 6,
                         caps=False), 'metal' if F['metal'] else 'dark')
        # 1c. THE COP at the elbow end - a long reach without it reads as a
        #     tube; with it the piece reads as a FOREARM piece.
        if F['cop']:
            cx = w.x - sgn * cuff * 0.98
            p.raw(aim(L.cone(mouth * 1.0, mouth * 1.16, cuff * 0.16, 14),
                      (cx, w.y, w.z), axis),
                  'metal' if F['metal'] else 'leather')
        # 2. THE HAND SHELL - wider than the hand it covers
        p.add(L.box(handlen * 0.62, hw * 1.42, hw * 1.26), 'cloth',
              loc=(hd.x + sgn * handlen * 0.12, hd.y, hd.z))
        if F['fingers'] == 0:                      # a mitt: one pocket
            p.raw(aim(L.cone(hw * 0.86, hw * 0.56, handlen * 0.46,
                             12), (hd.x + sgn * handlen * 0.34, hd.y, hd.z),
                      (sgn, 0, 0)), 'cloth')
        else:
            for k in range(4):
                dy = -hw * 0.52 + hw * 0.35 * k
                p.raw(L.tube([Vector((hd.x + sgn * handlen * 0.26, hd.y + dy, hd.z + hw * 0.08)),
                              Vector((hd.x + sgn * handlen * (0.44 if v != 4 else 0.34),
                                      hd.y + dy, hd.z + hw * 0.04))],
                             [hw * 0.20, hw * 0.16], 6), 'cloth')
            # FPLATE - how far the plating runs down the fingers
            for k in range(4):
                dy = -hw * 0.52 + hw * 0.35 * k
                for q in range(F['fplate']):
                    p.add(L.box(handlen * 0.075, hw * 0.26, hw * 0.12),
                          'metal' if F['metal'] else 'dark',
                          loc=(hd.x + sgn * (handlen * (0.27 + 0.085 * q)),
                               hd.y + dy, hd.z + hw * 0.22))
        # the thumb, so a glove reads as a glove from the side
        p.raw(L.tube([Vector((hd.x + sgn * handlen * 0.08, hd.y - hw * 0.62, hd.z)),
                      Vector((hd.x + sgn * handlen * 0.30, hd.y - hw * 0.80, hd.z - hw * 0.10))],
                     [hw * 0.24, hw * 0.17], 7), 'cloth')
        # 3. THE KNUCKLE TREATMENT - not just a height now. The kind comes off
        #    the item's key inside what the cut allows, so the studded glove
        #    and the wrap that were identical at stream size are a spiked
        #    knuckle and a studded one.
        kn = hw * F['knuck'] * 0.55
        kind = F['knuck_kind']
        kz = hd.z + hw * 0.66
        mat = 'metal' if F['metal'] else 'dark'
        if kind == 'ridge' and kn > 0.008:
            for k in range(max(1, F['plates'])):
                p.add(L.box(handlen * 0.13, hw * 1.34, max(0.010, kn * 0.52)), mat,
                      loc=(hd.x + sgn * (handlen * 0.06 + handlen * 0.15 * k),
                           hd.y, kz + kn * 0.46))
            p.add(L.box(handlen * 0.40, hw * 0.30, max(0.012, kn * 1.05)), mat,
                  loc=(hd.x + sgn * handlen * 0.16, hd.y, kz + kn * 0.80))
        elif kind == 'dome':
            r = max(0.010, kn * 1.30 + hw * 0.22)
            p.add(L.sphere(r * 1.15, r * 1.30, r, 12, 8), mat,
                  loc=(hd.x + sgn * handlen * 0.14, hd.y, kz + r * 0.30))
        elif kind == 'spikes':
            for k in range(max(2, min(4, 1 + F['plates'] // 2))):
                dy = -hw * 0.46 + (hw * 0.92 / max(1, max(2, min(4, 1 + F['plates'] // 2)) - 1)) * k
                p.raw(aim(L.cone(max(0.006, hw * 0.17), 0.0,
                                 max(0.018, kn * 1.5 + hw * 0.30), 7),
                          (hd.x + sgn * handlen * 0.16, hd.y + dy, kz), (0, 0, 1)), mat)
            p.add(L.box(handlen * 0.34, hw * 1.20, max(0.010, kn * 0.40)), mat,
                  loc=(hd.x + sgn * handlen * 0.16, hd.y, kz + kn * 0.10))
        elif kind == 'studs':
            for k in range(4):
                for q in range(2):
                    p.add(L.sphere(hw * 0.15, hw * 0.15, hw * 0.15, 7, 6), 'metal',
                          loc=(hd.x + sgn * handlen * (0.10 + 0.14 * q),
                               hd.y - hw * 0.46 + hw * 0.31 * k, kz + hw * 0.10))
        if F['metal'] and kind in ('ridge', 'spikes'):
            p.add(L.sphere(max(0.006, kn * 0.46), max(0.006, kn * 0.40),
                           max(0.005, kn * 0.34), 10, 7), 'gem',
                  loc=(hd.x + sgn * handlen * 0.04, hd.y, kz + kn * 0.92 + hw * 0.06))
        elif kind == 'none' and orn > 0.45:
            p.add(L.sphere(hw * 0.20, hw * 0.17, hw * 0.15, 10, 7), 'gem',
                  loc=(hd.x + sgn * handlen * 0.10, hd.y, kz + hw * 0.06))
        if v == 2:                                 # studs down the fingers
            for k in range(4):
                p.add(L.sphere(hw * 0.11, hw * 0.11, hw * 0.11, 6, 5), 'metal',
                      loc=(hd.x + sgn * handlen * 0.38,
                           hd.y - hw * 0.52 + hw * 0.35 * k, hd.z + hw * 0.22))
        # 4. THE WRAP'S LOOSE END. A wrap is wound cloth and it has a tie; it
        #    is the one cut whose reach cannot separate it from the studded
        #    glove, so it takes the one direction nothing else occupies -
        #    clear of the arm, soft, hanging.
        if F['tail'] > 0.0:
            tl = cuff * F['tail'] + handlen * 0.20
            tx = w.x - sgn * cuff * 0.80
            p.raw(L.tube([Vector((tx, w.y - mouth * 0.30, w.z - mouth * 0.60)),
                          Vector((tx + sgn * tl * 0.22, w.y - mouth * 0.52,
                                  w.z - mouth * 0.60 - tl * 0.70)),
                          Vector((tx + sgn * tl * 0.10, w.y - mouth * 0.34,
                                  w.z - mouth * 0.60 - tl))],
                         [mouth * 0.26, mouth * 0.20, mouth * 0.11], 7), 'cloth')
        out.append(p)
    return out


def acc_boots(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    D = sig(key, name)
    out = []
    shaft = (0.10, 0.22, 0.40, 0.28, 0.16)[v] * D.u(0, 0.78, 1.28)
    cuffk = D.u(1, 0.82, 1.32)
    toe = D.n(2, 0, 2)
    for side in ('l', 'r'):
        f = anchors['foot.' + side]
        tz = anchors['toes.' + side]
        p = Part("Acc_Boot" + side.upper(), "foot." + side, item=name, slot="boots")
        sole_z = 0.012
        p.add(L.box(0.125, 0.300, 0.028), 'dark', loc=(f.x, tz.y + 0.055, sole_z))
        p.add(L.box(0.115, 0.115, 0.055), 'dark', loc=(f.x, f.y + 0.010, sole_z + 0.040))
        p.add(L.box(0.112, 0.250, 0.085), 'cloth', loc=(f.x, tz.y + 0.065, sole_z + 0.070))
        if v == 4 or toe == 1:
            p.raw(aim(L.cone(0.042, 0.0, 0.11 * D.u(3, 0.80, 1.45), 8),
                      (f.x, tz.y - 0.085, sole_z + 0.055), (0, -1, 0.25)), 'cloth')
        elif toe == 2:
            p.add(L.box(0.100, 0.075, 0.050), 'metal', loc=(f.x, tz.y - 0.030, sole_z + 0.055))
        else:
            p.raw(aim(L.cone(0.052, 0.040, 0.055, 10), (f.x, tz.y - 0.045, sole_z + 0.060),
                      (0, -0.8, 0.6)), 'cloth')
        p.raw(L.tube([Vector((f.x, f.y + 0.012, sole_z + 0.085)),
                      Vector((f.x, f.y + 0.014, sole_z + 0.085 + shaft))], [0.070, 0.062], 10), 'cloth')
        if v == 3:
            for k in range(D.n(4, 4, 7)):
                a = TAU * k / max(1, D.n(4, 4, 7))
                p.add(L.sphere(0.030, 0.030, 0.026, 8, 6), 'dark',
                      loc=(f.x + 0.060 * math.cos(a), f.y + 0.012 + 0.060 * math.sin(a),
                           sole_z + 0.085 + shaft))
        else:
            p.raw(aim(L.cone(0.076 * cuffk, 0.070, 0.030 * cuffk,
                             12), (f.x, f.y + 0.012, sole_z + 0.075 + shaft), (0, 0, 1)), 'dark')
        if v == 2 or orn > 0.5:
            for k in range(1 + int(2 * orn)):
                z = sole_z + 0.12 + (shaft - 0.05) * (k / max(1.0, 1 + 2 * orn))
                p.add(L.box(0.150, 0.040, 0.020), 'metal', loc=(f.x, f.y + 0.010, z))
                p.add(L.sphere(0.018, 0.014, 0.014, 8, 6), 'gem', loc=(f.x, f.y - 0.055, z))
        out.append(p)
    return out


def acc_amulet(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    D = sig(key, name)
    neck = anchors['head'].z - 0.030
    chest = anchors['chest'].z
    p = Part("Acc_Amulet", "chest", item=name, slot="amulet")
    beads = D.n(0, 9, 17)
    droop = D.u(1, 0.010, 0.030)
    cord = D.bit(2, 0.35)                  # a cord, not a chain of beads
    if cord:
        arc = []
        for k in range(beads):
            a = math.pi * (-0.5) + math.pi * (-0.46 + 0.92 * k / float(beads - 1))
            r = S.r(neck, a) + 0.016
            arc.append(Vector((r * math.cos(a), r * math.sin(a),
                               neck - droop * 1.6 * math.cos(math.pi * (k - (beads - 1) * 0.5)
                                                             / float(beads)))))
        p.raw(L.tube(arc, 0.007, 6), 'leather')
    else:
        for k in range(beads):
            a = math.pi * (-0.5) + math.pi * (-0.46 + 0.92 * k / float(beads - 1))
            r = S.r(neck, a) + 0.016
            bs = 0.014 * D.u(3, 0.72, 1.35)
            p.add(L.sphere(bs, bs, bs * 0.86, 6, 5),
                  'metal', loc=(r * math.cos(a), r * math.sin(a),
                                neck - droop * math.cos(math.pi * (k - (beads - 1) * 0.5)
                                                        / float(beads))))
    front = S.r(chest + 0.07, -math.pi * 0.5) + 0.038
    py = -front
    drop = D.u(4, 0.055, 0.140)            # how far the pendant hangs
    p.raw(L.tube([Vector((0, py + 0.004, neck - 0.030)),
                  Vector((0, py, chest + 0.095 - drop + 0.085))], 0.009, 6), 'metal')
    z = chest + 0.065 - (drop - 0.085)
    tall = D.u(5, 0.70, 1.40)              # the pendant's own ratio
    wide = D.u(6, 0.70, 1.40)
    if v == 0:
        p.add(L.sphere(0.034 * wide, 0.020, 0.044 * tall, 12, 9), 'gem', loc=(0, py, z))
    elif v == 1:
        p.raw(aim(L.cone(0.046 * wide, 0.044 * wide, 0.014, 16), (0, py + 0.008, z), (0, -1, 0)), 'metal')
        p.add(L.sphere(0.018 * wide, 0.010, 0.018 * tall, 10, 7), 'gem', loc=(0, py - 0.008, z))
    elif v == 2:
        cr = 0.044 * wide
        for k in range(D.n(7, 7, 13)):
            a = math.pi * (0.16 + 0.68 * k / float(max(1, D.n(7, 7, 13) - 1))) + math.pi * 0.5
            p.add(L.sphere(0.012, 0.009, 0.012, 7, 5), 'metal',
                  loc=(cr * math.cos(a), py, z + cr * tall * math.sin(a)))
    elif v == 3:
        p.raw(aim(L.cone(0.021 * wide, 0.016, 0.062 * tall, 12), (0, py, z - 0.034 * tall),
                  (0, 0, 1)), 'gem')
        p.add(L.box(0.019 * wide, 0.019, 0.013), 'metal', loc=(0, py, z + 0.034 * tall))
    else:
        p.add(L.box(0.050 * wide, 0.016, 0.058 * tall), 'metal', loc=(0, py, z))
        p.add(L.box(0.028 * wide, 0.010, 0.032 * tall), 'gem', loc=(0, py - 0.010, z))
    for k in range(D.n(8, 0, 3)):          # charms strung beside the pendant
        s = 1 if k % 2 else -1
        p.add(L.sphere(0.009, 0.007, 0.012, 8, 6), 'metal',
              loc=(s * (0.038 + 0.014 * (k // 2)), py + 0.004, neck - 0.055 - 0.010 * k))
    if orn > 0.5:
        for s in (-1, 1):
            p.add(L.sphere(0.010, 0.008, 0.010, 8, 6), 'gem',
                  loc=(0.050 * s, py + 0.004, z + 0.038))
    return [p]


def acc_cloak(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    D = sig(key, name)
    sh = anchors['upperarm.l'].z + 0.055
    hem = sh - (0.52, 0.26, 0.78, 0.48, 0.56)[v] * D.u(0, 0.80, 1.22)
    p = Part("Acc_Cloak", "chest", item=name, slot="cloak")
    n = D.n(1, 9, 13)
    sweep = TAU * D.u(2, 0.60, 0.84)       # how far round the shoulders it goes
    a_0 = math.pi * 0.14
    flare = D.u(3, 1.14, 1.46)
    jags = D.n(4, 1, 3)
    for k in range(n - 1):
        a0 = a_0 + sweep * k / (n - 1.0)
        a1 = a_0 + sweep * (k + 1) / (n - 1.0)
        quad = []
        for a, z, f in ((a0, sh, 1.0), (a1, sh, 1.0), (a1, hem, flare), (a0, hem, flare)):
            jag = (0.06 * D.u(5, 0.6, 1.6) if (v == 4 and k % (jags + 1) and z == hem) else 0.0)
            # hangs from the measured shoulder AND clears whatever the body is
            # doing at the hem's own height - hips and legs included
            r = max((S.r(min(z, sh), a) + 0.040) * f, r_clear(S, z, a, 0.042))
            quad.append(Vector((r * math.cos(a), r * math.sin(a), z - jag)))
        p.raw(L.membrane(quad, 0.022), 'cloth')
    collar = D.n(6, 0, 2) if v not in (0, 3) else (0 if v == 0 else 1)
    if v == 0:                             # a hood, thrown back
        hr = S.r(anchors['head'].z + 0.10, math.pi * 0.5) + 0.075
        hs = D.u(7, 0.84, 1.20)
        p.add(L.sphere(0.145 * hs, 0.125 * hs, 0.115 * hs * D.u(8, 0.84, 1.24), 14, 10), 'cloth',
              loc=(0, hr * 0.62, anchors['head'].z + 0.10))
    elif collar == 1:                      # a roll of fur or wool at the neck
        for k in range(D.n(8, 5, 9)):
            a = a_0 + 0.06 + (sweep - 0.12) * k / float(max(1, D.n(8, 5, 9) - 1))
            r = S.r(sh - 0.02, a) + 0.055
            rs = 0.048 * D.u(9, 0.74, 1.30)
            p.add(L.sphere(rs, rs * 0.92, rs * 0.84, 9, 7), 'dark',
                  loc=(r * math.cos(a), r * math.sin(a), sh - 0.01))
    elif collar == 2:                      # a standing collar behind the neck
        for k in range(6):
            b0 = math.pi * 0.62 + math.pi * 0.76 * k / 6.0
            b1 = math.pi * 0.62 + math.pi * 0.76 * (k + 1) / 6.0
            quad = []
            for a, z in ((b0, sh), (b1, sh), (b1, sh + 0.13 * D.u(9, 0.7, 1.4)),
                         (b0, sh + 0.13 * D.u(9, 0.7, 1.4))):
                r = S.r(min(z, sh), a) + 0.050
                quad.append(Vector((r * math.cos(a), r * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.020), 'cloth')
    fr = S.r(sh - 0.03, -math.pi * 0.5) + 0.034
    cl = D.n(10, 0, 2)
    if cl == 0:
        p.raw(L.tube([Vector((-0.085, -fr, sh - 0.025)), Vector((0.085, -fr, sh - 0.025))],
                     0.016, 7), 'metal')
        p.add(L.sphere(0.028, 0.020, 0.028, 11, 8), 'gem', loc=(0, -fr - 0.012, sh - 0.025))
    elif cl == 1:
        for s in (-1, 1):
            p.add(L.sphere(0.024, 0.016, 0.024, 10, 7), 'metal',
                  loc=(0.062 * s, -fr - 0.008, sh - 0.025))
        p.raw(L.tube([Vector((-0.062, -fr - 0.004, sh - 0.025)),
                      Vector((0.062, -fr - 0.004, sh - 0.025))], 0.007, 6), 'dark')
    else:
        p.raw(aim(L.cone(0.040, 0.034, 0.014, 14), (0, -fr - 0.010, sh - 0.025), (0, -1, 0)), 'metal')
        p.add(L.sphere(0.016, 0.010, 0.016, 10, 7), 'gem', loc=(0, -fr - 0.020, sh - 0.025))
    if orn > 0.55:
        for k in range(3):
            p.add(L.sphere(0.012, 0.010, 0.012, 7, 5), 'metal',
                  loc=(-0.055 + 0.055 * k, -fr - 0.006, sh - 0.075))
    return [p]


def acc_helm(name, key, cost, ctx, anchors, S, headbox=None):
    """A helm, a circlet, a hood, a cap, a straw hat, a cone, a visor or a veil
    - from the item's NAME, as D73's hats do, and then from the item's own KEY.

    The proof sheet caught Straw Hat and Miller's Cap rendering as ONE object,
    and the cause was in here: variants 0 (wide brim), 1 (cap), 2 (cone) and 7
    (veil) all fell through to the war-helm branch, so four of the eight kinds
    of hat in the data had no geometry of their own. They do now."""
    v, orn = ctx['variant'], ctx['orn']
    D = sig(key, name)
    # headbox = (centre_z, radius) MEASURED off the body's own head mesh. The
    # head bone is at the NECK on this rig, which is why pass 2's helm was
    # buried in the chest.
    if headbox:
        cz, rr = headbox
    else:
        cz, rr = anchors['head'].z + 0.30, 0.30
    p = Part("Acc_Helm", "head", item=name, slot="hat")

    if v == 0 or v == 1 or v == 2:
        # SOFT HATS. A brim and a crown, and those two numbers are the whole
        # difference between a straw hat, a miller's cap and a conical hat -
        # which is exactly the pair the sheet caught, so they are per-item.
        brim = (1.70 if v == 0 else 1.06 if v == 1 else 1.22) * D.u(0, 0.88, 1.14)
        crown = (0.42 if v == 0 else 0.56 if v == 1 else 1.55) * D.u(1, 0.86, 1.18)
        droop = (0.055 if v == 0 else 0.012 if v == 1 else 0.030) * D.u(2, 0.6, 1.5)
        # LOOKED AT THE SHEET: at cz+0.030 the straw hat's brim cut straight
        # across the eyes. A hat sits ON the skull, so the band rides the
        # crown and the brim clears the brow.
        base = cz + 0.030 + rr * 0.26
        seg = 20
        for k in range(seg):
            a0, a1 = TAU * k / seg, TAU * (k + 1) / seg
            quad = []
            for a, rf, z in ((a0, 1.00, base), (a1, 1.00, base),
                             (a1, brim, base - droop), (a0, brim, base - droop)):
                quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.016 if v == 0 else 0.020), 'cloth')
        if v == 2:      # a cone
            p.raw(aim(L.cone(rr * 1.00, rr * 0.06, rr * crown, 18), (0, 0, base), (0, 0, 1)), 'cloth')
            p.add(L.sphere(0.022, 0.022, 0.030, 8, 6), 'dark', loc=(0, 0, base + rr * crown))
        else:           # a soft dome, flattened per item
            dv, df = L.sphere(rr * 1.02, rr * 1.02, rr * crown, 16, 11)
            dome = [Vector((q.x, q.y, max(q.z, 0.0))) for q in dv]
            p.add((dome, df), 'cloth', loc=(0, 0, base - 0.004))
        band = [Vector((rr * 1.03 * math.cos(TAU * k / 20.0), rr * 1.03 * math.sin(TAU * k / 20.0),
                        base + 0.018)) for k in range(21)]
        p.raw(L.tube(band, 0.016 * D.u(3, 0.7, 1.5), 7, caps=False), 'dark')
        for k in range(D.n(4, 0, 2)):   # a sprig, a feather, a pinned fold
            p.raw(L.tube([Vector((rr * 0.80, -rr * 0.50, base + 0.030)),
                          Vector((rr * 1.10 + 0.05 * k, -rr * 0.70, base + 0.090 + 0.05 * k))],
                         [0.010, 0.004], 6), 'trim')
        if orn > 0.5:
            p.add(L.sphere(0.016, 0.012, 0.016, 8, 6), 'gem', loc=(0, -rr * 1.00, base + 0.022))
        return [p]

    if v == 7:
        # A VEIL. Cloth off the crown, hanging past the jaw, open at the front.
        base = cz + 0.050
        hang = (0.30 + 0.16 * D.u(0)) * 1.0
        p.add(L.sphere(rr * 1.04, rr * 1.04, rr * 0.34 * D.u(1, 0.8, 1.3), 16, 9),
              'cloth', loc=(0, 0, base))
        m = D.n(2, 10, 14)
        for k in range(m):
            a0 = math.pi * (0.10 + 0.80 * k / float(m))
            a1 = math.pi * (0.10 + 0.80 * (k + 1) / float(m))
            quad = []
            for a, z, rf in ((a0, base, 1.03), (a1, base, 1.03),
                             (a1, base - hang, 1.12), (a0, base - hang, 1.12)):
                quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.014), 'cloth')
        for s in (-1, 1):   # two panels down the front, leaving the face open
            for k in range(3):
                a0 = s * math.pi * (0.92 + 0.05 * k)
                a1 = s * math.pi * (0.92 + 0.05 * (k + 1))
                quad = []
                for a, z, rf in ((a0, base, 1.03), (a1, base, 1.03),
                                 (a1, base - hang * 0.72, 1.10), (a0, base - hang * 0.72, 1.10)):
                    quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
                p.raw(L.membrane(quad, 0.014), 'cloth')
        circ = [Vector((rr * 1.05 * math.cos(TAU * k / 18.0), rr * 1.05 * math.sin(TAU * k / 18.0),
                        base - 0.010)) for k in range(19)]
        p.raw(L.tube(circ, 0.013 * D.u(3, 0.7, 1.5), 7, caps=False), 'dark')
        return [p]

    if v == 3:
        rf = 1.04 * D.u(0, 0.97, 1.10)
        pts = D.n(1, 3, 7)
        ring = [Vector((rr * rf * math.cos(TAU * k / 20.0), rr * rf * math.sin(TAU * k / 20.0),
                        cz + 0.10)) for k in range(21)]
        p.raw(L.tube(ring, 0.020 + 0.008 * orn, 7, caps=False), 'metal')
        for k in range(pts):
            a = TAU * k / pts
            p.raw(aim(L.cone(0.020, 0.0, (0.055 + 0.045 * orn) * D.u(2, 0.7, 1.6), 6),
                      (rr * rf * math.cos(a), rr * rf * math.sin(a), cz + 0.10), (0, 0, 1)), 'metal')
        p.add(L.sphere(0.026, 0.020, 0.026, 10, 7), 'gem', loc=(0, -rr * rf, cz + 0.12))
        return [p]

    if v == 4:
        # A HOOD LEAVES THE FACE, for the same reason a helm does. LOOKED AT
        # THE SHEET: the old closed sphere swallowed the man whole - the
        # Pieman's Hood was a grey egg with no face in it. It is a crown and a
        # cowl now, open at the front, with two panels framing the face.
        hs = D.u(0, 0.92, 1.14)
        crown = rr * 1.06 * D.u(1, 0.88, 1.22)
        base = cz + 0.045
        dv, df = L.sphere(rr * 1.12 * hs, rr * 1.14 * hs, crown, 16, 11)
        cap = [Vector((q.x, q.y, max(q.z, 0.0))) for q in dv]
        p.add((cap, df), 'cloth', loc=(0, 0.02, base))
        # LOOKED AGAIN: a cowl down to the chest read as flat plates sliced
        # through the man. It stops just past the jaw, where a hood stops.
        hang = rr * (0.72 + 0.30 * D.u(2))
        m = 12
        for k in range(m):                # the cowl: the back, down past the jaw
            a0 = math.pi * (0.10 + 0.80 * k / float(m))
            a1 = math.pi * (0.10 + 0.80 * (k + 1) / float(m))
            quad = []
            for a, z, rf in ((a0, base, 1.10), (a1, base, 1.10),
                             (a1, base - hang, 1.16), (a0, base - hang, 1.16)):
                quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.020), 'cloth')
        for s2 in (-1, 1):                # two panels at the cheeks
            for k in range(3):
                a0 = s2 * math.pi * (0.90 + 0.055 * k)
                a1 = s2 * math.pi * (0.90 + 0.055 * (k + 1))
                quad = []
                for a, z, rf in ((a0, base, 1.10), (a1, base, 1.10),
                                 (a1, base - hang * 0.70, 1.14),
                                 (a0, base - hang * 0.70, 1.14)):
                    quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
                p.raw(L.membrane(quad, 0.020), 'cloth')
        for k in range(D.n(3, 0, 2)):     # a roll of cloth at the hood's edge
            rf = 1.12 + 0.05 * k
            circ = [Vector((rr * rf * math.cos(math.pi * (0.10 + 0.80 * i / 14.0)),
                            rr * rf * math.sin(math.pi * (0.10 + 0.80 * i / 14.0)),
                            base - hang + 0.012)) for i in range(15)]
            p.raw(L.tube(circ, 0.016, 6, caps=False), 'dark')
        return [p]

    if v == 6:
        p.raw(aim(L.cone(rr * 0.92 * D.u(0, 0.9, 1.1), rr * 0.76, 0.035, 18),
                  (0, -rr * 0.86, cz), (0, -1, 0.10)), 'metal')
        for s2 in (-1, 1):
            for k in range(D.n(1, 1, 3)):
                p.add(L.box(0.060, 0.022, 0.028), 'dark',
                      loc=(0.070 * s2, -rr * 0.96, cz + 0.055 - 0.040 * k))
        return [p]

    # A HELM LEAVES THE FACE. Pass 3 built a closed sphere the size of the
    # skull and it swallowed the man - on this body the head is half the
    # figure, so the helm is a skullcap that stops above the eyes, with a
    # neck guard behind and a nasal down the front. Per item: how high the
    # cap stands, how far the neck guard reaches, and the crest.
    brow = cz + 0.045
    ch = D.u(0, 0.94, 1.16)
    gl = D.u(1, 0.76, 1.22)
    dv, df = L.sphere(rr * 1.06, rr * 1.08, rr * 1.02 * ch, 18, 12)
    cap = [Vector((q.x, q.y, max(q.z, 0.0))) for q in dv]
    p.add((cap, df), 'metal', loc=(0, 0, brow))
    band = [Vector((rr * 1.07 * math.cos(TAU * k / 24.0),
                    rr * 1.09 * math.sin(TAU * k / 24.0), brow)) for k in range(25)]
    p.raw(L.tube(band, 0.022 * D.u(2, 0.8, 1.4), 7, caps=False), 'trim')
    n = 12
    for k in range(n):
        a0 = math.pi * (0.06 + 0.88 * k / float(n))
        a1 = math.pi * (0.06 + 0.88 * (k + 1) / float(n))
        quad = []
        for a, z, rf in ((a0, brow, 1.07), (a1, brow, 1.07),
                         (a1, brow - (0.30 + 0.045) * gl, 1.00),
                         (a0, brow - (0.30 + 0.045) * gl, 1.00)):
            quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
        p.raw(L.membrane(quad, 0.024), 'metal')
    if D.bit(3, 0.75):                     # the nasal
        p.add(L.box(0.055, 0.045, 0.19 * D.u(4, 0.70, 1.25)), 'metal',
              loc=(0, -rr * 1.02, brow - 0.075))
    for s2 in (-1, 1):                     # cheek plates, clear of the eyes
        p.raw(aim(L.cone(0.085 * D.u(5, 0.80, 1.25), 0.060, 0.030, 10),
                  (rr * 0.92 * s2, -rr * 0.34, brow - 0.105), (s2, -0.25, 0)), 'metal')
    if orn > 0.40 or v == 5:
        prof = []
        m = 11
        crest = (0.075 + 0.055 * orn) * D.u(6, 0.70, 1.45)
        for i in range(m):
            u = i / (m - 1.0)
            y = -rr * 0.92 + rr * 1.84 * u
            zb = brow + math.sqrt(max(0.0, 1.0 - (u * 2 - 1) ** 2)) * rr * 0.92 * ch
            prof.append((y, zb, zb + crest))
        top = [Vector((0, y, zt)) for y, zb, zt in prof]
        bot = [Vector((0, y, zb)) for y, zb, zt in prof]
        p.raw(L.membrane(top + bot[::-1], 0.028), 'trim')
    return [p]


ACC_BUILDERS = {'ring': acc_ring, 'gloves': acc_gloves, 'boots': acc_boots,
                'amulet': acc_amulet, 'cloak': acc_cloak}
