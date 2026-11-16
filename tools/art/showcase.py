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
def _grip(p, z0, z1, r=0.030):
    p.raw(L.tube([Vector((0, 0, z0)), Vector((0, 0, z1))], r, 9), 'leather')
    p.add(L.sphere(r * 1.5, r * 1.5, r * 0.9, 10, 7), 'trim', loc=(0, 0, z0 - 0.02))


def weapon(name, family, tier, hint=""):
    """Held about the grip at the origin, pointing +Z. One of five families,
    and the NAME splits a family where the name says something (an arbalest is
    not a bow; a wand is not a staff)."""
    hay = (name + " " + hint).lower()
    p = Part("Weapon", "handslot.r", item=name, slot="weapon", touches=False)
    t = tier
    # A held weapon is carried, not swung through the owner. The driver moves
    # this to the POSED hand without the shoulder's rotation (pass 1 put every
    # blade horizontally through its owner's chest), so it is authored upright
    # and leaned out from the body here, about the grip.

    if family == 'blade':
        blen = 0.60 + 0.085 * t
        half = 0.150 + 0.022 * t
        _grip(p, -0.11, 0.13)
        p.raw(L.tube([Vector((-half, 0, 0.15)), Vector((half, 0, 0.15))],
                     [0.022, 0.030, 0.022] if t >= 2 else 0.024, 8), 'metal')
        if t >= 2:
            for s in (-1, 1):
                p.raw(aim(L.cone(0.026, 0.012, 0.085, 7), (half * s, 0, 0.155), (s * 0.5, 0, 1)), 'metal')
        w0, w1 = 0.075 + 0.006 * t, 0.030
        edge, back = [], []
        n = 9
        for i in range(n):
            u = i / (n - 1.0)
            z = 0.17 + blen * u
            ww = w0 + (w1 - w0) * (u ** 1.5)
            edge.append(Vector((ww, 0, z)))
            back.append(Vector((-ww, 0, z)))
        edge.append(Vector((0.0, 0, 0.17 + blen + 0.10)))
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
        hl = (1.26 if great else 0.86) + 0.05 * t
        p.raw(L.tube([Vector((0, 0, -0.22)), Vector((0, 0, hl * 0.6)), Vector((0, 0, hl))],
                     [0.034, 0.030, 0.027], 9), 'haft')
        for zz in (-0.12, 0.06):
            p.raw(L.tube([Vector((0, 0, zz - 0.045)), Vector((0, 0, zz + 0.045))], 0.040, 9), 'leather')
        ztop = hl
        beard = [Vector((0.030, 0, ztop - 0.30)), Vector((0.165 + 0.03 * t, 0, ztop - 0.33)),
                 Vector((0.230 + 0.04 * t, 0, ztop - 0.12)), Vector((0.175, 0, ztop + 0.05)),
                 Vector((0.030, 0, ztop + 0.03))]
        p.raw(L.membrane(beard, 0.040 + 0.006 * t), 'metal')
        p.raw(L.tube([Vector((0, 0, ztop - 0.34)), Vector((0, 0, ztop + 0.07))], 0.044, 9), 'metal')
        if t >= 3:
            p.raw(aim(L.cone(0.050, 0.0, 0.20, 7), (-0.030, 0, ztop - 0.10), (-1, 0, 0.15)), 'metal')
            p.add(L.sphere(0.034, 0.014, 0.034, 10, 7), 'glow', loc=(0.13, -0.028, ztop - 0.12))
        if t >= 4:
            mirror = [Vector((-q.x, q.y, q.z)) for q in beard]
            p.raw(L.membrane(mirror, 0.040), 'metal')
        if t >= 5:
            p.raw(aim(L.cone(0.038, 0.0, 0.26, 7), (0, 0, ztop + 0.05), (0, 0, 1)), 'glow')

    elif family == 'arcane':
        wand = any(k in hay for k in ("wand", "rod"))
        hl = (0.52 if wand else 1.58) + 0.03 * t
        p.raw(L.tube([Vector((0, 0, -0.18)), Vector((0, 0, hl * 0.5)), Vector((0, 0, hl))],
                     [0.028, 0.025, 0.021] if wand else [0.032, 0.028, 0.024], 9), 'haft')
        if not wand:
            p.raw(L.tube([Vector((0, 0, 0.0)), Vector((0, 0, 0.09))], 0.038, 9), 'leather')
        for s in (-1, 1):
            p.raw(L.tube([Vector((0, 0, hl - 0.10)), Vector((0.058 * s, 0, hl + 0.02)),
                          Vector((0.030 * s, 0, hl + 0.14))], [0.021, 0.017, 0.012], 7), 'metal')
        p.add(L.sphere(0.054 + 0.006 * t, 0.048, 0.062 + 0.006 * t, 12, 9),
              'glow' if t >= 3 else 'gem', loc=(0, 0, hl + 0.055))
        if t >= 3:
            for k, zz in enumerate((hl - 0.30, hl - 0.46)):
                r = 0.072 - 0.012 * k
                ring = [Vector((r * math.cos(TAU * i / 14.0), r * math.sin(TAU * i / 14.0), zz))
                        for i in range(15)]
                p.raw(L.tube(ring, 0.011, 6, caps=False), 'glow')
        if t >= 4:
            for k in range(3):
                p.add(L.sphere(0.020, 0.018, 0.026, 8, 6), 'gem',
                      loc=(0, -0.032, hl - 0.62 - 0.10 * k))

    elif family == 'ranged':
        bow = ("bow" in hay or "string" in hay or "thrum" in hay) and "crossbow" not in hay
        if bow:
            span = 0.78 + 0.05 * t
            for s in (-1, 1):
                p.raw(L.tube([Vector((0, 0.0, 0.0)), Vector((0, -0.05, span * 0.52 * s)),
                              Vector((0, 0.07, span * s))], [0.028, 0.022, 0.015], 8), 'haft')
            p.raw(L.tube([Vector((0, 0.07, span)), Vector((0, 0.07, -span))], 0.007, 5), 'cloth')
            p.raw(L.tube([Vector((0, 0, -0.10)), Vector((0, 0, 0.10))], 0.034, 9), 'leather')
            if t >= 3:
                p.add(L.sphere(0.030, 0.016, 0.030, 10, 7), 'glow', loc=(0, -0.034, 0.0))
            if t >= 4:
                for s in (-1, 1):
                    p.add(L.sphere(0.024, 0.020, 0.034, 8, 6), 'gem', loc=(0, 0.02, span * 0.70 * s))
        else:
            p.add(L.box(0.060, 0.70 + 0.03 * t, 0.055), 'haft', loc=(0, -0.10, 0.06))
            p.add(L.box(0.055, 0.17, 0.11), 'haft', loc=(0, 0.17, -0.02))
            p.raw(L.tube([Vector((-0.30 - 0.02 * t, -0.40, 0.09)), Vector((0, -0.46, 0.09)),
                          Vector((0.30 + 0.02 * t, -0.40, 0.09))], [0.017, 0.022, 0.017], 7), 'metal')
            p.raw(L.tube([Vector((-0.28, -0.39, 0.09)), Vector((0, -0.16, 0.09)),
                          Vector((0.28, -0.39, 0.09))], 0.006, 5), 'cloth')
            p.add(L.box(0.040, 0.10, 0.045), 'metal', loc=(0, 0.02, 0.10))
            p.raw(aim(L.cone(0.022, 0.016, 0.085, 7), (0, 0.07, 0.00), (0, 0.3, -1)), 'metal')
            if t >= 3:
                p.add(L.sphere(0.026, 0.026, 0.020, 10, 7), 'glow', loc=(0, -0.02, 0.115))
            if t >= 4:
                p.add(L.box(0.030, 0.16, 0.030), 'gem', loc=(0, -0.34, 0.115))
    else:
        p.raw(L.tube([Vector((0, 0, -0.60)), Vector((0, 0, 0.72))], [0.028, 0.028], 9), 'haft')
        for zz in (-0.46, 0.58):
            p.raw(L.tube([Vector((0, 0, zz - 0.05)), Vector((0, 0, zz + 0.05))], 0.036, 9), 'metal')
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
    h = anchors['hand.l']
    x = h.x + 0.052
    p = Part("Acc_Ring", "hand.l", item=name, slot="ring")
    rr, band = 0.052, 0.012 + 0.005 * ctx['orn']
    pts = [Vector((x, rr * math.cos(TAU * k / 18.0), h.z + rr * math.sin(TAU * k / 18.0)))
           for k in range(19)]
    if v == 2:
        for s in (-1, 1):
            tw = [Vector((x + s * 0.008 * math.sin(TAU * 4 * k / 18.0),
                          rr * math.cos(TAU * k / 18.0), h.z + rr * math.sin(TAU * k / 18.0)))
                  for k in range(19)]
            p.raw(L.tube(tw, band * 0.62, 6), 'metal')
    else:
        p.raw(L.tube(pts, band, 8), 'metal')
    top = Vector((x, 0.0, h.z + rr + 0.012))
    if v == 1:
        p.add(L.box(0.030, 0.034, 0.012), 'metal', loc=(top.x, top.y, top.z))
        p.add(L.box(0.017, 0.020, 0.010), 'dark', loc=(top.x - 0.008, top.y, top.z))
    elif v == 3:
        p.add(L.sphere(0.019, 0.017, 0.015, 10, 7), 'gem', loc=(top.x, top.y, top.z + 0.004))
        for k in range(4):
            a = TAU * k / 4 + 0.7
            p.add(L.sphere(0.006, 0.006, 0.006, 6, 5), 'metal',
                  loc=(top.x, top.y + 0.013 * math.cos(a), top.z + 0.013 * math.sin(a) - 0.004))
    elif v == 4:
        for dx in (-0.006, 0.006):
            p.raw(L.tube([Vector((pt.x + dx, pt.y, pt.z)) for pt in pts], band * 0.40, 6), 'dark')
    else:
        p.add(L.sphere(0.013, 0.012, 0.011, 10, 7), 'gem', loc=(top.x, top.y, top.z))
    return [p]


def acc_gloves(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    out = []
    for side in ('l', 'r'):
        sgn = 1.0 if side == 'l' else -1.0
        w = anchors['wrist.' + side]
        hd = anchors['hand.' + side]
        p = Part("Acc_Glove" + side.upper(), "hand." + side, item=name, slot="gloves")
        cuff = 0.20 if v == 3 else 0.095
        p.raw(aim(L.cone(0.070, 0.060, cuff, 12), (w.x - sgn * cuff * 0.35, w.y, w.z), (sgn, 0, 0)), 'leather')
        p.add(L.box(0.085, 0.072, 0.070), 'cloth', loc=(hd.x + sgn * 0.030, hd.y, hd.z))
        if v == 1:
            p.raw(aim(L.cone(0.040, 0.028, 0.065, 10), (hd.x + sgn * 0.090, hd.y, hd.z), (sgn, 0, 0)), 'cloth')
        elif v == 4:
            for k in range(3):
                p.add(L.box(0.016, 0.016, 0.018), 'dark',
                      loc=(hd.x + sgn * 0.072, hd.y - 0.020 + 0.020 * k, hd.z + 0.012))
        else:
            for k in range(3):
                p.raw(L.tube([Vector((hd.x + sgn * 0.058, hd.y - 0.020 + 0.020 * k, hd.z + 0.010)),
                              Vector((hd.x + sgn * 0.098, hd.y - 0.020 + 0.020 * k, hd.z + 0.006))],
                             [0.011, 0.009], 6), 'cloth')
        if v == 0:
            for k in range(3):
                p.add(L.box(0.020, 0.080, 0.020), 'metal',
                      loc=(hd.x + sgn * (0.010 + 0.030 * k), hd.y, hd.z + 0.042))
            p.add(L.sphere(0.017, 0.015, 0.012, 10, 7), 'gem', loc=(hd.x + sgn * 0.050, hd.y, hd.z + 0.050))
        elif v == 2:
            for k in range(3):
                p.add(L.sphere(0.009, 0.009, 0.009, 6, 5), 'metal',
                      loc=(hd.x + sgn * (0.020 + 0.028 * k), hd.y, hd.z + 0.040))
        elif orn > 0.45:
            p.add(L.sphere(0.015, 0.013, 0.011, 10, 7), 'gem', loc=(hd.x + sgn * 0.030, hd.y, hd.z + 0.044))
        out.append(p)
    return out


def acc_boots(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    out = []
    for side in ('l', 'r'):
        f = anchors['foot.' + side]
        toe = anchors['toes.' + side]
        p = Part("Acc_Boot" + side.upper(), "foot." + side, item=name, slot="boots")
        shaft = (0.10, 0.22, 0.40, 0.28, 0.16)[v]
        sole_z = 0.012
        p.add(L.box(0.125, 0.300, 0.028), 'dark', loc=(f.x, toe.y + 0.055, sole_z))
        p.add(L.box(0.115, 0.115, 0.055), 'dark', loc=(f.x, f.y + 0.010, sole_z + 0.040))
        p.add(L.box(0.112, 0.250, 0.085), 'cloth', loc=(f.x, toe.y + 0.065, sole_z + 0.070))
        if v == 4:
            p.raw(aim(L.cone(0.042, 0.0, 0.11, 8), (f.x, toe.y - 0.085, sole_z + 0.055), (0, -1, 0.25)), 'cloth')
        else:
            p.raw(aim(L.cone(0.052, 0.040, 0.055, 10), (f.x, toe.y - 0.045, sole_z + 0.060), (0, -0.8, 0.6)), 'cloth')
        p.raw(L.tube([Vector((f.x, f.y + 0.012, sole_z + 0.085)),
                      Vector((f.x, f.y + 0.014, sole_z + 0.085 + shaft))], [0.070, 0.062], 10), 'cloth')
        if v == 3:
            for k in range(6):
                a = TAU * k / 6
                p.add(L.sphere(0.030, 0.030, 0.026, 8, 6), 'dark',
                      loc=(f.x + 0.060 * math.cos(a), f.y + 0.012 + 0.060 * math.sin(a), sole_z + 0.085 + shaft))
        else:
            p.raw(aim(L.cone(0.076, 0.070, 0.030, 12), (f.x, f.y + 0.012, sole_z + 0.075 + shaft), (0, 0, 1)), 'dark')
        if v == 2 or orn > 0.5:
            for k in range(1 + int(2 * orn)):
                z = sole_z + 0.12 + (shaft - 0.05) * (k / max(1.0, 1 + 2 * orn))
                p.add(L.box(0.150, 0.040, 0.020), 'metal', loc=(f.x, f.y + 0.010, z))
                p.add(L.sphere(0.018, 0.014, 0.014, 8, 6), 'gem', loc=(f.x, f.y - 0.055, z))
        out.append(p)
    return out


def acc_amulet(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    neck = anchors['head'].z - 0.030
    chest = anchors['chest'].z
    p = Part("Acc_Amulet", "chest", item=name, slot="amulet")
    for k in range(13):
        a = math.pi * (-0.5) + math.pi * (-0.46 + 0.92 * k / 12.0)
        r = S.r(neck, a) + 0.016
        p.add(L.sphere(0.014, 0.014, 0.012, 6, 5), 'metal',
              loc=(r * math.cos(a), r * math.sin(a), neck - 0.018 * math.cos(math.pi * (k - 6) / 12.0)))
    front = S.r(chest + 0.07, -math.pi * 0.5) + 0.038
    py = -front
    p.raw(L.tube([Vector((0, py + 0.004, neck - 0.030)), Vector((0, py, chest + 0.095))], 0.009, 6), 'metal')
    z = chest + 0.065
    if v == 0:
        p.add(L.sphere(0.034, 0.020, 0.044, 12, 9), 'gem', loc=(0, py, z))
    elif v == 1:
        p.raw(aim(L.cone(0.046, 0.044, 0.014, 16), (0, py + 0.008, z), (0, -1, 0)), 'metal')
        p.add(L.sphere(0.018, 0.010, 0.018, 10, 7), 'gem', loc=(0, py - 0.008, z))
    elif v == 2:
        for k in range(9):
            a = math.pi * (0.16 + 0.68 * k / 8.0) + math.pi * 0.5
            p.add(L.sphere(0.012, 0.009, 0.012, 7, 5), 'metal',
                  loc=(0.044 * math.cos(a), py, z + 0.044 * math.sin(a)))
    elif v == 3:
        p.raw(aim(L.cone(0.021, 0.016, 0.062, 12), (0, py, z - 0.034), (0, 0, 1)), 'gem')
        p.add(L.box(0.019, 0.019, 0.013), 'metal', loc=(0, py, z + 0.034))
    else:
        p.add(L.box(0.050, 0.016, 0.058), 'metal', loc=(0, py, z))
        p.add(L.box(0.028, 0.010, 0.032), 'gem', loc=(0, py - 0.010, z))
    if orn > 0.5:
        for s in (-1, 1):
            p.add(L.sphere(0.010, 0.008, 0.010, 8, 6), 'gem', loc=(0.050 * s, py + 0.004, z + 0.038))
    return [p]


def acc_cloak(name, key, cost, ctx, anchors, S):
    v, orn = ctx['variant'], ctx['orn']
    sh = anchors['upperarm.l'].z + 0.055
    hem = (sh - 0.52, sh - 0.26, sh - 0.78, sh - 0.48, sh - 0.56)[v]
    p = Part("Acc_Cloak", "chest", item=name, slot="cloak")
    n = 11
    for k in range(n - 1):
        a0 = math.pi * 0.14 + (TAU * 0.72) * k / (n - 1.0)
        a1 = math.pi * 0.14 + (TAU * 0.72) * (k + 1) / (n - 1.0)
        quad = []
        for a, z, f in ((a0, sh, 1.0), (a1, sh, 1.0), (a1, hem, 1.30), (a0, hem, 1.30)):
            jag = 0.06 if (v == 4 and k % 2 and z == hem) else 0.0
            # hangs from the measured shoulder AND clears whatever the body is
            # doing at the hem's own height - hips and legs included
            r = max((S.r(min(z, sh), a) + 0.040) * f, r_clear(S, z, a, 0.042))
            quad.append(Vector((r * math.cos(a), r * math.sin(a), z - jag)))
        p.raw(L.membrane(quad, 0.022), 'cloth')
    if v == 0:
        hr = S.r(anchors['head'].z + 0.10, math.pi * 0.5) + 0.075
        p.add(L.sphere(0.145, 0.125, 0.115, 14, 10), 'cloth',
              loc=(0, hr * 0.62, anchors['head'].z + 0.10))
    elif v == 3:
        for k in range(7):
            a = math.pi * 0.20 + (TAU * 0.60) * k / 6.0
            r = S.r(sh - 0.02, a) + 0.055
            p.add(L.sphere(0.048, 0.044, 0.040, 9, 7), 'dark',
                  loc=(r * math.cos(a), r * math.sin(a), sh - 0.01))
    fr = S.r(sh - 0.03, -math.pi * 0.5) + 0.034
    p.raw(L.tube([Vector((-0.085, -fr, sh - 0.025)), Vector((0.085, -fr, sh - 0.025))], 0.016, 7), 'metal')
    p.add(L.sphere(0.028, 0.020, 0.028, 11, 8), 'gem', loc=(0, -fr - 0.012, sh - 0.025))
    if orn > 0.55:
        for k in range(3):
            p.add(L.sphere(0.012, 0.010, 0.012, 7, 5), 'metal',
                  loc=(-0.055 + 0.055 * k, -fr - 0.006, sh - 0.075))
    return [p]


def acc_helm(name, key, cost, ctx, anchors, S, headbox=None):
    """A helm, a circlet, a hood or a visor - from the item's NAME, as D73's
    hats do. It replaces the body's own hat, which the driver hides."""
    v, orn = ctx['variant'], ctx['orn']
    # headbox = (centre_z, radius) MEASURED off the body's own head mesh. The
    # head bone is at the NECK on this rig, which is why pass 2's helm was
    # buried in the chest.
    if headbox:
        cz, rr = headbox
    else:
        cz, rr = anchors['head'].z + 0.30, 0.30
    hz = cz - 0.115
    p = Part("Acc_Helm", "head", item=name, slot="hat")
    if v == 3:
        ring = [Vector((rr * 1.04 * math.cos(TAU * k / 20.0), rr * 1.04 * math.sin(TAU * k / 20.0),
                        cz + 0.10)) for k in range(21)]
        p.raw(L.tube(ring, 0.020 + 0.008 * orn, 7, caps=False), 'metal')
        for k in range(int(3 + 4 * orn)):
            a = TAU * k / max(1, int(3 + 4 * orn))
            p.raw(aim(L.cone(0.020, 0.0, 0.055 + 0.045 * orn, 6),
                      (rr * 1.04 * math.cos(a), rr * 1.04 * math.sin(a), cz + 0.10), (0, 0, 1)), 'metal')
        p.add(L.sphere(0.026, 0.020, 0.026, 10, 7), 'gem', loc=(0, -rr * 1.04, cz + 0.12))
    elif v == 4:
        vv, ff = L.sphere(rr * 1.12, rr * 1.14, rr * 1.06, 16, 11)
        hood = [Vector((q.x, q.y, max(q.z, -rr * 0.55))) for q in vv]
        p.add((hood, ff), 'cloth', loc=(0, 0.02, cz + 0.02))
        p.add(L.sphere(rr * 0.70, rr * 0.50, rr * 0.62, 13, 9), 'dark', loc=(0, -rr * 0.70, cz + 0.02))
    elif v == 6:
        p.raw(aim(L.cone(rr * 0.92, rr * 0.76, 0.035, 18), (0, -rr * 0.86, cz), (0, -1, 0.10)), 'metal')
        for s2 in (-1, 1):
            p.add(L.box(0.060, 0.022, 0.028), 'dark', loc=(0.070 * s2, -rr * 0.96, cz + 0.055))
    else:
        # A HELM LEAVES THE FACE. Pass 3 built a closed sphere the size of the
        # skull and it swallowed the man - on this body the head is half the
        # figure, so the helm is a skullcap that stops above the eyes, with a
        # neck guard behind and a nasal down the front.
        brow = cz + 0.045
        dv, df = L.sphere(rr * 1.06, rr * 1.08, rr * 1.02, 18, 12)
        cap = [Vector((q.x, q.y, max(q.z, 0.0))) for q in dv]
        p.add((cap, df), 'metal', loc=(0, 0, brow))
        band = [Vector((rr * 1.07 * math.cos(TAU * k / 24.0),
                        rr * 1.09 * math.sin(TAU * k / 24.0), brow)) for k in range(25)]
        p.raw(L.tube(band, 0.022, 7, caps=False), 'trim')
        # the neck guard: the back half, carried down behind the jaw
        n = 12
        for k in range(n):
            a0 = math.pi * (0.06 + 0.88 * k / float(n))
            a1 = math.pi * (0.06 + 0.88 * (k + 1) / float(n))
            quad = []
            for a, z, rf in ((a0, brow, 1.07), (a1, brow, 1.07),
                             (a1, cz - 0.30, 1.00), (a0, cz - 0.30, 1.00)):
                quad.append(Vector((rr * rf * math.cos(a), rr * rf * math.sin(a), z)))
            p.raw(L.membrane(quad, 0.024), 'metal')
        p.add(L.box(0.055, 0.045, 0.19), 'metal', loc=(0, -rr * 1.02, brow - 0.075))
        for s2 in (-1, 1):      # cheek plates, clear of the eyes
            p.raw(aim(L.cone(0.085, 0.060, 0.030, 10),
                      (rr * 0.92 * s2, -rr * 0.34, brow - 0.105), (s2, -0.25, 0)), 'metal')
        if orn > 0.40 or v == 5:
            prof = []
            m = 11
            for i in range(m):
                u = i / (m - 1.0)
                y = -rr * 0.92 + rr * 1.84 * u
                zb = brow + math.sqrt(max(0.0, 1.0 - (u * 2 - 1) ** 2)) * rr * 0.92
                prof.append((y, zb, zb + 0.075 + 0.055 * orn))
            top = [Vector((0, y, zt)) for y, zb, zt in prof]
            bot = [Vector((0, y, zb)) for y, zb, zt in prof]
            p.raw(L.membrane(top + bot[::-1], 0.028), 'trim')
    return [p]


ACC_BUILDERS = {'ring': acc_ring, 'gloves': acc_gloves, 'boots': acc_boots,
                'amulet': acc_amulet, 'cloak': acc_cloak}
