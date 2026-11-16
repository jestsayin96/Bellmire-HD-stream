"""icons - parametric shape families for D73, every named item gets a face.

Seven silhouettes cover all 454 named items: ring, amulet, cloak, boots,
gloves (the 230 accessories) and hat, banner (the 224 cosmetics that carry a
colour and nothing else). Nothing here is sculpted per item. Each icon is built
from the item's OWN data:

    slot / kind      picks the silhouette
    cost             drives ornateness and the metal it is made of
    colour           drives the palette where the item carries one
    the stat it adds drives the gem colour, so a viewer can learn to read it
                     (ac steel, saves violet, hp red, speed green, hit amber,
                      dmg orange) - accessories carry no colour of their own
    hash(key)        picks among the variants, so two rings are not one ring

Original geometry, same as the lords: raw vertex maths, no third-party asset.
"""
import math
from mathutils import Vector

import lordlib as L
from lords import Parts, aim

TAU = math.pi * 2.0
VARIANTS = 5


def ring_pts(r, n=26, z=0.0, axis='z'):
    out = []
    for k in range(n + 1):
        a = TAU * k / n
        if axis == 'z':
            out.append(Vector((r * math.cos(a), r * math.sin(a), z)))
        else:
            out.append(Vector((r * math.cos(a), z, r * math.sin(a))))
    return out


# ------------------------------------------------------------------------ ring
def build_ring(P, c):
    v, orn = c['variant'], c['orn']
    band = 0.055 + 0.03 * orn
    # the band stands in the XZ plane so a stone set at the top sits ON it
    if v == 2:      # twisted: two bands wound together
        for s in (-1, 1):
            pts = [Vector((0.5 * math.cos(TAU * k / 30),
                           s * 0.045 * math.sin(TAU * 5 * k / 30),
                           0.5 * math.sin(TAU * k / 30))) for k in range(31)]
            P.raw(L.tube(pts, band * 0.6, 8), 'metal')
    else:
        P.raw(L.tube(ring_pts(0.5, 26, 0.0, 'y'), band, 10), 'metal')
    if v == 1:      # signet
        P.add(L.box(0.34, 0.1, 0.30), 'metal', loc=(0, 0, 0.52))
        P.add(L.box(0.20, 0.06, 0.17), 'dark', loc=(0, -0.045, 0.52))
    elif v == 3:    # a stone set in claws
        P.add(L.sphere(0.17, 0.13, 0.17, 12, 8), 'gem', loc=(0, 0, 0.60))
        for k in range(4):
            a = TAU * k / 4 + 0.78
            P.raw(aim(L.cone(0.03, 0.0, 0.20, 6), (0.13 * math.cos(a), 0.0, 0.52 + 0.13 * math.sin(a)),
                      (math.cos(a), 0, math.sin(a))), 'metal')
    elif v == 4:    # engraved: two grooves cut around the band
        for y in (-band * 0.55, band * 0.55):
            P.raw(L.tube(ring_pts(0.5 + 0.014, 26, y, 'y'), band * 0.38, 7), 'dark')
    if orn > 0.45 and v != 1:
        for k in range(int(2 + 6 * orn)):
            a = TAU * k / max(1, int(2 + 6 * orn)) + 0.4
            P.add(L.sphere(0.035, 0.035, 0.035, 8, 6), 'gem',
                  loc=(0.5 * math.cos(a), 0.0, 0.5 * math.sin(a)))


# ---------------------------------------------------------------------- amulet
def build_amulet(P, c):
    v, orn = c['variant'], c['orn']
    for k in range(13):          # the chain
        a = math.pi * (0.12 + 0.76 * k / 12.0)
        x, z = 0.62 * math.cos(a), 0.52 * math.sin(a) + 0.34
        P.raw(L.tube(ring_pts(0.055, 10, 0.0, 'y'), 0.019, 6), 'metal')
        P.items[-1] = ([p + Vector((x, 0, z)) for p in P.items[-1][0]], P.items[-1][1], 'metal')
    P.raw(L.tube([(0, 0, 0.36), (0, 0, 0.22)], 0.03, 7), 'metal')
    if v == 0:      # teardrop
        P.add(L.sphere(0.21, 0.12, 0.26, 14, 10), 'gem', loc=(0, 0, -0.02))
        P.raw(aim(L.cone(0.09, 0.0, 0.22, 8), (0, 0, -0.22), (0, 0, -1)), 'gem')
    elif v == 1:    # disc
        P.raw(aim(L.cone(0.28, 0.26, 0.09, 18), (0, 0.045, 0.02), (0, -1, 0)), 'metal')
        P.add(L.sphere(0.11, 0.07, 0.11, 12, 8), 'gem', loc=(0, -0.06, 0.02))
    elif v == 2:    # crescent
        for k in range(11):
            a = math.pi * (0.18 + 0.64 * k / 10.0) + math.pi * 0.5
            r = 0.27
            P.add(L.sphere(0.055, 0.04, 0.055, 8, 6), 'metal',
                  loc=(r * math.cos(a), 0, r * math.sin(a) + 0.02))
    elif v == 3:    # a stoppered vial
        P.raw(aim(L.cone(0.12, 0.09, 0.34, 12), (0, 0, -0.22), (0, 0, 1)), 'gem')
        P.add(L.box(0.11, 0.11, 0.07), 'metal', loc=(0, 0, 0.16))
    else:           # locket
        P.add(L.box(0.30, 0.09, 0.34), 'metal', loc=(0, 0, 0.0))
        P.add(L.box(0.17, 0.05, 0.20), 'gem', loc=(0, -0.05, 0.0))
    if orn > 0.5:
        for s in (-1, 1):
            P.add(L.sphere(0.04, 0.03, 0.04, 8, 6), 'gem', loc=(0.30 * s, -0.02, 0.22))


# ----------------------------------------------------------------------- cloak
def build_cloak(P, c):
    """Five cloaks that are actually five shapes - a hooded one, a short mantle,
    a long sweep, a fur-collared one and a tattered one."""
    v, orn = c['variant'], c['orn']
    hem = (-0.72, -0.30, -0.86, -0.66, -0.74)[v]
    flare = (0.34, 0.26, 0.48, 0.38, 0.36)[v] + 0.10 * orn
    jag = 0.14 if v == 4 else 0.0
    loop = [(-0.32, 0, 0.66), (0.32, 0, 0.66), (flare + 0.30, 0.14, hem + 0.20)]
    for k in range(7):
        x = (flare + 0.26) * (1 - 2 * k / 6.0)
        loop.append((x, 0.18, hem + (jag if k % 2 else 0.0)))
    loop.append((-flare - 0.30, 0.14, hem + 0.20))
    P.raw(L.membrane(loop, 0.05), 'cloth')
    P.raw(L.membrane([(-0.11, -0.07, 0.60), (0.13, -0.07, 0.60),
                      (0.22, 0.02, hem + 0.16), (-0.20, 0.02, hem + 0.16)], 0.04), 'dark')
    if v == 0:      # a hood thrown back
        P.add(L.sphere(0.36, 0.30, 0.30, 14, 10), 'cloth', loc=(0, 0.26, 0.76))
        P.add(L.sphere(0.24, 0.22, 0.22, 12, 8), 'dark', loc=(0, 0.12, 0.74))
    elif v == 2:    # a long sweep, gathered at the shoulder
        for k in range(5):
            P.raw(L.tube([(-0.26 + 0.13 * k, -0.02, 0.60),
                          (-0.44 + 0.22 * k, 0.12, hem + 0.26)], [0.03, 0.055], 6), 'dark')
    elif v == 3:    # fur collar
        for k in range(8):
            P.add(L.sphere(0.12, 0.11, 0.11, 10, 7), 'dark',
                  loc=(-0.38 + 0.108 * k, -0.05, 0.69))
    elif v == 1:    # a short mantle with a scalloped edge
        for k in range(5):
            P.add(L.sphere(0.11, 0.05, 0.08, 10, 7), 'cloth',
                  loc=(-0.34 + 0.17 * k, 0.10, hem))
    P.raw(L.tube([(-0.34, -0.06, 0.66), (0.34, -0.06, 0.66)], 0.045, 8), 'metal')
    P.add(L.sphere(0.11, 0.08, 0.11, 12, 8), 'gem', loc=(0, -0.11, 0.66))
    if orn > 0.55:
        for k in range(4):
            P.add(L.sphere(0.035, 0.03, 0.035, 8, 6), 'metal',
                  loc=(-0.24 + 0.16 * k, -0.09, 0.58))


# ----------------------------------------------------------------------- boots
def build_boots(P, c):
    """The silhouette has to be an L - a toe reaching forward from a shaft at
    the heel. A shaft sitting on top of a box reads as a chimney, not a boot."""
    v, orn = c['variant'], c['orn']
    shaft = (0.26, 0.54, 0.80, 0.62, 0.44)[v]
    for s in (-1, 1):
        x = 0.30 * s
        P.add(L.box(0.28, 0.78, 0.10), 'dark', loc=(x, -0.16, -0.72))        # sole
        P.add(L.box(0.26, 0.26, 0.16), 'dark', loc=(x, 0.14, -0.70))         # heel
        P.add(L.box(0.25, 0.66, 0.24), 'cloth', loc=(x, -0.18, -0.56))       # foot
        P.raw(aim(L.cone(0.14, 0.12, 0.26, 10), (x, -0.46, -0.58), (0, -0.55, 1.0)), 'cloth')
        P.raw(L.tube([(x, 0.12, -0.62), (x, 0.14, -0.62 + shaft)], [0.165, 0.145], 10), 'cloth')
        if v == 4:   # a long pointed toe
            P.raw(aim(L.cone(0.10, 0.0, 0.30, 8), (x, -0.50, -0.60), (0, -1, 0.22)), 'cloth')
        if v == 3:   # fur cuff
            for k in range(7):
                a = TAU * k / 7
                P.add(L.sphere(0.08, 0.08, 0.07, 8, 6), 'dark',
                      loc=(x + 0.15 * math.cos(a), 0.14 + 0.15 * math.sin(a), -0.62 + shaft))
        else:
            P.raw(aim(L.cone(0.185, 0.17, 0.09, 12), (x, 0.13, -0.64 + shaft), (0, 0, 1)), 'dark')
        if v == 2 or orn > 0.5:   # buckles up the shaft
            for k in range(1 + int(2 * orn)):
                z = -0.52 + (shaft - 0.14) * (k / max(1.0, 1 + 2 * orn))
                P.add(L.box(0.36, 0.10, 0.06), 'metal', loc=(x, 0.13, z))
                P.add(L.sphere(0.05, 0.05, 0.05, 8, 6), 'gem', loc=(x, 0.01, z))


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


def sig(key, name=""):
    """FNV-1a over the item's key AND name - the two things only this item has."""
    hay = (str(key or "") + "|" + str(name or "")).lower()
    h = 2166136261
    for c in hay:
        h = ((h ^ ord(c)) * 16777619) & 0xFFFFFFFF
    return Dial(h)


# ----------------------------------------------- D94: THE GLOVE'S SILHOUETTE
# ONE SOURCE OF TRUTH, shared by the hub icon (build_gloves below) and the
# thing on the hand (showcase.acc_gloves), so the glove a viewer buys in the
# hub is the glove that turns up on the hero. That condition has held through
# every D94 fix and it holds through this one.
#
# WHY THIS EXISTS, so nobody re-derives it. The D94 proof sheet measured the
# gloves row at worst 0.00% / median 0.33% of the hero's own stream pixels:
# PARTLY TOO SMALL, 11 of 15 pairs. They were NOT duplicates - strip 1 showed
# six different objects. They were invisible, and the cause was a number:
#   measured on the KayKit body - fist 0.15 across, hand bone to fingertip
#   0.258, forearm (lowerarm -> wrist) 0.26, arm 0.30 thick
#   the glove was - hand shell 0.085 across, cuff 0.095 long
# A glove smaller than the hand inside it has no silhouette to tell apart.
# Mr. E, 16 Nov 04:56, verbatim: "gloves can be seen". So the three things that
# make a glove read from across a room all RIDE COST, which is the receipt a
# viewer paid for:
#   CUFF    how far up the forearm it reaches, as a fraction of the forearm
#   FLARE   how wide the cuff lip opens, as a multiple of the arm's radius
#   KNUCK   how far the back-of-hand plate stands off the fist
# SHELL is never below 1.0: the glove is always bigger than the hand.
# The CUT comes from the item's NAME first (NAME_HINTS) and from its hash only
# as a fallback, exactly as every other D94 derivation does.
GLOVE_CUTS = ("gauntlet", "mitt", "studded", "vambrace", "wrap")

# CUFF is a fraction of the FOREARM (0.26 m measured). FLARE is a multiple of
# the FOREARM RADIUS (0.055 m measured) and is what a viewer actually sees -
# the lip stands clear of the arm whatever the body is doing with its hands.
# SHELL is a multiple of the FIST RADIUS (0.075 m) and is never below 1.0.
#
# MR. E HAS RULED, 2026-11-16 10:24: "okay so fix them" - gloves must READ AT
# STREAM DISTANCE, and the fix is MORE DERIVED VARIATION, NOT A BIGGER GLOVE.
# A 2.0-3.3x bell mouth was already tried and backed out: it looked like
# dinner plates. SO NOTHING BELOW RAISES FLARE OR SHELL. What was actually
# wrong is measurable and was measured - d94g_front/side/back, 6 of 15 pairs
# PARTLY TOO SMALL and the worst pair at 0.00% of hero pixels, i.e. LITERALLY
# IDENTICAL at stream size. Every one of those pairs is a pair of the four
# SMALL cuts (vambrace, vambrace, studded, wrap): all four put the same little
# lump at the same place on the wrist, so at 1/3 scale only their COLOUR
# differs, and colour is not shape.
# THE FOUR DIALS THAT NOW SEPARATE THEM ARE SHAPE, AND ALL FOUR RIDE THE
# ITEM'S OWN KEY AS WELL AS ITS COST (D94b's rule):
#   REACH   how far up the forearm, and it is now a CUT IDENTITY - a vambrace
#           is a FOREARM piece (0.58-0.88 of it) and a wrap is a wrist piece
#           (0.20-0.40). Length along the arm costs no girth, so it buys
#           silhouette without buying dinner plates.
#   LAMES   segmentation: how many bands break the cuff up its length. Two
#           vambraces of the same price are a 3-lame and a 6-lame.
#   KNUCK_KIND  the treatment, not just the height: ridge / dome / spikes /
#           studs / none, chosen per cut from the key.
#   FPLATE  how far the plating runs down the fingers.
GLOVE_KNUCKS = ("none", "dome", "ridge", "spikes", "studs")
#            cut:  gauntlet  mitt  studded  vambrace  wrap
_G_CUFF0   = (0.34, 0.14, 0.26, 0.58, 0.16)
_G_CUFFK   = (0.30, 0.16, 0.26, 0.30, 0.14)
_G_FLARE0  = (1.70, 1.25, 1.40, 1.55, 1.18)
_G_FLAREK  = (0.95, 0.30, 0.55, 0.80, 0.26)
_G_KNUCK0  = (0.34, 0.10, 0.21, 0.15, 0.06)
_G_KNUCKK  = (0.52, 0.26, 0.44, 0.30, 0.22)
_G_SHELL0  = (1.46, 1.62, 1.38, 1.32, 1.26)
_G_PLATES  = ((3, 6), (0, 1), (2, 5), (1, 3), (0, 2))
_G_METAL   = (True, False, True, True, False)
_G_FINGERS = (4, 0, 4, 4, 4)
# segmentation up the cuff: (cheap, dear). A wrap is wound, not segmented.
_G_LAMES   = ((2, 5), (0, 2), (1, 4), (3, 7), (1, 3))
# which treatments this cut may wear. The key picks one; cost only decides
# whether the dearest of them is allowed at all.
_G_KNK     = ((2, 3, 1), (0, 1), (4, 3), (2, 0, 1), (0, 4))
# how many finger segments carry plate
_G_FPLATE  = ((2, 4), (0, 0), (1, 2), (0, 2), (0, 0))


def glove_form(variant, orn, D=None):
    """The dials for one glove, normalised so the icon and the worn piece can
    each scale them into their own space. orn is the item's cost quantile
    inside its slot - the same 0..1 that drives metal, gem and wear."""
    v = max(0, min(len(GLOVE_CUTS) - 1, int(variant)))
    o = max(0.0, min(1.0, float(orn)))
    # the item's own key moves proportion inside whatever the cut decided, so
    # two gauntlets at the same price are not one gauntlet (D94b's rule).
    j = (lambda i, lo, hi: D.u(i, lo, hi)) if D is not None else (lambda i, lo, hi: 1.0)
    cuff = _G_CUFF0[v] + _G_CUFFK[v] * o
    # REACH carries a wider key spread than anything else here, because reach
    # is the dial that showed up at stream size and two same-cut gloves have
    # to differ on it even at the same price.
    reach = max(0.10, min(0.94, cuff * j(0, 0.78, 1.22)))
    lo, hi = _G_LAMES[v]
    lames = lo + int(round((hi - lo) * o))
    if D is not None:                       # +-1 off the key, never below 0
        lames = max(0, min(hi + 1, lames + D.n(8, -1, 1)))
    # PASS 2, AND I FOUND IT BY LOOKING: seven thick rings up a flaring cone
    # is a STACK OF PANCAKES, not a vambrace - a lamp shade with ribs. Bellmire
    # is plain: a segmented forearm piece wears two to four bands, and they are
    # thin. The dial still separates two same-price gloves; it no longer reads
    # as machinery.
    lames = min(4, lames)
    kinds = _G_KNK[v]
    if D is not None:
        kind = kinds[D.d[9 % 12] % len(kinds)]
    else:
        kind = kinds[0]
    if kind == 3 and o < 0.45:              # spikes are the dear treatment
        kind = 2 if _G_METAL[v] else 4
    flo, fhi = _G_FPLATE[v]
    fplate = flo + int(round((fhi - flo) * o))
    return dict(
        cut=GLOVE_CUTS[v], variant=v,
        cuff=reach, reach=reach,
        flare=max(1.0, (_G_FLARE0[v] + _G_FLAREK[v] * o) * j(1, 0.93, 1.09)),
        knuck=max(0.0, (_G_KNUCK0[v] + _G_KNUCKK[v] * o) * j(2, 0.86, 1.18)),
        shell=max(1.02, _G_SHELL0[v] * j(3, 0.96, 1.10)),
        plates=(_G_PLATES[v][0] + int(round((_G_PLATES[v][1] - _G_PLATES[v][0]) * o))),
        metal=_G_METAL[v], fingers=_G_FINGERS[v],
        lames=lames, knuck_kind=GLOVE_KNUCKS[kind], fplate=fplate,
        # a stepped cuff is a straight sleeve with one shoulder in it; a bell
        # is the old profile. The key chooses, so same-cut pairs differ in
        # OUTLINE and not only in how many bands they wear.
        stepped=(D.bit(10, 0.45) if D is not None else False),
        # A WRAP IS WOUND CLOTH AND IT HAS A LOOSE END. The wrap and the
        # studded glove sat 0.02 of forearm apart in reach, which at stream
        # size is nothing, so the wrap earns the one direction no other cut
        # occupies: a tie hanging clear of the arm. Soft, not a plate.
        tail=((0.34 + 0.62 * (D.u(11) if D is not None else 0.5)) if v == 4 else 0.0),
        # a long reach gets a wider band at the elbow end - that is what makes
        # a forearm piece read as a forearm piece and not as a long tube.
        cop=(reach > 0.56),
        lip=(_G_FLARE0[v] + _G_FLAREK[v] * o) > 1.85)


# ---------------------------------------------------------------------- gloves
def build_gloves(P, c):
    """The hub icon. Same dials as the worn piece; icon space is ~2.0 across,
    the body is ~0.15 at the fist, so everything here is the worn number x 4.6.
    The cuff is the big silhouette - it runs DOWN the icon off the wrist.
    MR. E'S 10:24 RULING IS MIRRORED HERE AND NOT ONLY ON THE HAND: the icon
    carries the same reach, lames, cop, knuckle kind, finger plating and
    wrap-tie, because the glove in the satchel must be the glove on the hero.
    Flare and shell are untouched - the icon is not scaled up either."""
    F = glove_form(c['variant'], c['orn'], c.get('D'))
    orn = c['orn']
    K = 3.4                                   # icon units per metre of body
    cuff = 0.26 * F['cuff'] * K               # forearm 0.26 m (measured)
    hw = 0.074 * F['shell'] * K               # fist radius  = handlen x 0.50
    flare = 0.056 * F['flare'] * K            # forearm rad. = handlen x 0.38
    flen = (0.0, 0.30, 0.34, 0.30, 0.22)[F['variant']]
    mat = 'metal' if F['metal'] else 'dark'
    for s in (-1, 1):
        x = 0.36 * s
        top = -0.18
        # the cuff first and deepest: a tall cone running down off the wrist
        if F['stepped']:                      # a sleeve with one shoulder
            mid = flare * 0.62 + hw * 0.38
            P.raw(aim(L.cone(flare, hw * 0.92, cuff * 0.55, 14),
                      (x, 0, top - cuff * 0.55), (0, 0, 1)), mat)
            P.raw(aim(L.cone(mid * 1.04, mid, cuff * 0.45, 14),
                      (x, 0, top - cuff), (0, 0, 1)), mat)
        else:
            P.raw(aim(L.cone(flare, hw * 0.92, cuff, 14), (x, 0, top - cuff),
                      (0, 0, 1)), mat)
        if F['lip']:                          # a hard flared lip at the mouth
            P.raw(L.tube(ring_pts(flare * 1.02, 20, top - cuff), 0.055, 8), mat)
        # LAMES - the segmentation, the dial that tells two same-price gloves
        # of one cut apart
        for k in range(F['lames']):
            f = (k + 0.7) / (F['lames'] + 0.4)
            rr = hw * 0.96 + (flare - hw * 0.96) * f
            P.raw(L.tube(ring_pts(rr * 1.025, 18, top - cuff * f), 0.026, 7), mat)
        if F['cop']:                          # the elbow end of a long reach
            P.raw(aim(L.cone(flare * 1.16, flare, cuff * 0.16,
                             14), (x, 0, top - cuff * 1.14), (0, 0, 1)), mat)
        # the hand shell, always wider than the hand under it
        P.add(L.box(hw * 2.0, 0.17, 0.42), 'cloth', loc=(x, 0, -0.04))
        if F['fingers'] == 0:                 # a mitt: one pocket for four
            P.raw(aim(L.cone(hw * 0.95, hw * 0.62, 0.30, 12), (x, 0, 0.14),
                      (0, -0.05, 1)), 'cloth')
        else:
            for k in range(4):
                fx = x + (-0.13 + 0.087 * k) * s
                P.raw(L.tube([(fx, 0, 0.16), (fx, -0.01, 0.16 + flen)],
                             [0.048, 0.038], 7), 'cloth')
                for q in range(F['fplate']):
                    # SEATED ON THE FINGER, not floating in front of it - at
                    # icon size a 0.045 standoff read as sugar cubes hanging
                    # over the hand.
                    P.add(L.box(0.072, 0.050, 0.055), mat,
                          loc=(fx, -0.022, 0.20 + 0.088 * q))
            if F['variant'] == 4:             # fingerless: tips cut away
                for k in range(4):
                    fx = x + (-0.13 + 0.087 * k) * s
                    P.add(L.sphere(0.048, 0.048, 0.022, 8, 6), 'dark',
                          loc=(fx, -0.01, 0.16 + flen))
        P.raw(L.tube([(x + hw * 0.95 * s, 0, 0.02), (x + hw * 1.5 * s, -0.02, 0.20)],
                     [0.055, 0.042], 7), 'cloth')
        # THE KNUCKLE TREATMENT - kind, not only height
        kn = 0.15 * F['knuck'] * K
        kind = F['knuck_kind']
        if kind == 'ridge':
            for k in range(max(1, F['plates'])):
                z = 0.10 - 0.11 * k
                P.add(L.box(hw * 1.9, 0.07 + kn * 0.30, 0.085), mat,
                      loc=(x, -0.10 - kn, z))
            P.add(L.box(hw * 0.6, 0.06 + kn * 0.40, 0.34), mat,
                  loc=(x, -0.12 - kn, -0.02))
        elif kind == 'dome':
            # a LOW dome across the knuckles, not an egg standing on the cuff.
            r = max(0.045, kn * 0.38 + hw * 0.22)
            P.add(L.sphere(r * 1.55, r * 0.62, r * 0.95, 12, 8), mat,
                  loc=(x, -0.085 - r * 0.30, 0.02))
        elif kind == 'spikes':
            n = max(2, min(4, 1 + F['plates'] // 2))
            for k in range(n):
                fx = x + (-0.10 + (0.20 / max(1, n - 1)) * k) * s
                P.raw(aim(L.cone(0.055, 0.0, max(0.10, kn * 0.55 + 0.12), 7),
                          (fx, -0.10 - kn * 0.20, 0.02), (0, -1, 0)), mat)
            P.add(L.box(hw * 1.7, 0.06, 0.26), mat, loc=(x, -0.09, 0.02))
        elif kind == 'studs':
            for k in range(4):
                for q in range(2):
                    P.add(L.sphere(0.042, 0.042, 0.042, 7, 6), 'metal',
                          loc=(x + (-0.11 + 0.073 * k) * s, -0.095, 0.04 - 0.13 * q))
        if F['metal'] and kind in ('ridge', 'spikes'):
            P.add(L.sphere(0.075, 0.05, 0.075, 10, 7), 'gem',
                  loc=(x, -0.12 - kn, -0.18))
        elif kind == 'none' and orn > 0.45:
            P.add(L.sphere(0.06, 0.045, 0.06, 10, 7), 'gem', loc=(x, -0.10, -0.08))
        if F['variant'] == 2:                 # studs down the fingers
            for k in range(4):
                P.add(L.sphere(0.030, 0.030, 0.030, 6, 5), 'metal',
                      loc=(x + (-0.13 + 0.087 * k) * s, -0.050, 0.32))
        if F['tail'] > 0.0:                   # the wrap's loose end
            tl = cuff * F['tail'] + 0.22
            P.raw(L.tube([(x + 0.10 * s, 0.10, top - cuff * 0.75),
                          (x + 0.20 * s, 0.17, top - cuff * 0.75 - tl * 0.65),
                          (x + 0.13 * s, 0.11, top - cuff * 0.75 - tl)],
                         [0.085, 0.065, 0.035], 7), 'cloth')


# ------------------------------------------------------------------------- hat
def build_hat(P, c):
    v, orn = c['variant'], c['orn']
    if v == 5:      # a helm - metal, with a nasal and a brow band
        P.add(L.sphere(0.42, 0.44, 0.40, 16, 11), 'metal', loc=(0, 0, 0.02))
        P.raw(L.tube(ring_pts(0.425, 24, -0.06), 0.055, 8), 'dark')
        P.add(L.box(0.09, 0.10, 0.42), 'metal', loc=(0, -0.40, -0.10))
        P.raw(L.tube([(0, 0.30, 0.40), (0, 0.00, 0.50), (0, -0.30, 0.40)], 0.035, 7), 'dark')
        if orn > 0.45:          # a crest
            P.raw(L.membrane([(0, 0.34, 0.40), (0, 0.0, 0.56), (0, -0.34, 0.40),
                              (0, 0.0, 0.46)], 0.05), 'gem')
        for s in (-1, 1):       # cheek plates
            P.raw(aim(L.cone(0.17, 0.13, 0.06, 10), (0.38 * s, -0.10, -0.16), (s, -0.2, 0)), 'metal')
        return
    if v == 6:      # a visor or a mask - a face plate with two slots
        P.raw(aim(L.cone(0.40, 0.33, 0.12, 18), (0, -0.10, 0.0), (0, -1, 0.12)), 'metal')
        for s in (-1, 1):
            P.add(L.box(0.17, 0.08, 0.075), 'dark', loc=(0.16 * s, -0.20, 0.10))
        P.add(L.box(0.06, 0.08, 0.26), 'dark', loc=(0, -0.21, -0.06))
        P.raw(L.tube([(-0.38, 0.06, 0.08), (0, 0.22, 0.10), (0.38, 0.06, 0.08)], 0.04, 7), 'cloth')
        if orn > 0.5:
            for k in range(4):
                P.add(L.sphere(0.035, 0.035, 0.035, 6, 5), 'gem',
                      loc=(-0.21 + 0.14 * k, -0.19, -0.26))
        return
    if v == 7:      # a veil - a band with cloth hanging from it
        P.raw(L.tube(ring_pts(0.34, 24, 0.44), 0.045, 8), 'metal')
        P.raw(L.membrane([(-0.34, 0.10, 0.44), (0.34, 0.10, 0.44), (0.42, 0.20, -0.46),
                          (0.0, 0.26, -0.56), (-0.42, 0.20, -0.46)], 0.035), 'cloth')
        P.raw(L.membrane([(-0.30, -0.14, 0.42), (0.30, -0.14, 0.42), (0.26, -0.20, -0.18),
                          (-0.26, -0.20, -0.18)], 0.03), 'cloth')
        if orn > 0.4:
            P.add(L.sphere(0.075, 0.06, 0.075, 10, 7), 'gem', loc=(0, -0.36, 0.44))
        return
    if v == 3:      # a circlet, no crown at all
        P.raw(L.tube(ring_pts(0.46), 0.05 + 0.025 * orn, 10), 'metal')
        for k in range(int(3 + 5 * orn)):
            a = TAU * k / max(1, int(3 + 5 * orn))
            P.raw(aim(L.cone(0.05, 0.0, 0.16 + 0.14 * orn, 6),
                      (0.46 * math.cos(a), 0.46 * math.sin(a), 0.0), (0, 0, 1)), 'metal')
        P.add(L.sphere(0.08, 0.08, 0.08, 10, 7), 'gem', loc=(0, -0.46, 0.06))
        return
    if v == 4:      # a hood
        P.add(L.sphere(0.46, 0.44, 0.44, 16, 11), 'cloth', loc=(0, 0.04, 0.10))
        P.add(L.sphere(0.34, 0.34, 0.34, 14, 10), 'dark', loc=(0, -0.22, 0.02))
        P.raw(L.tube([(-0.42, 0.10, -0.28), (0, 0.20, -0.36), (0.42, 0.10, -0.28)], 0.09, 8), 'cloth')
        return
    brim = (0.74, 0.40, 0.46)[v if v < 3 else 0]
    P.raw(aim(L.cone(brim, brim * 0.92, 0.055, 22), (0, 0, -0.22), (0, 0, 1)), 'cloth')
    if v == 2:      # conical
        P.raw(aim(L.cone(0.30, 0.0, 0.86, 14), (0, 0, -0.17), (0, 0, 1)), 'cloth')
    elif v == 1:    # a close cap
        P.add(L.sphere(0.32, 0.32, 0.26, 16, 11), 'cloth', loc=(0, 0, -0.10))
    else:           # a crown with a flat top
        P.raw(aim(L.cone(0.31, 0.27, 0.40, 16), (0, 0, -0.18), (0, 0, 1)), 'cloth')
        P.raw(aim(L.cone(0.28, 0.26, 0.04, 16), (0, 0, 0.22), (0, 0, 1)), 'cloth')
    P.raw(L.tube(ring_pts(0.315, 24, -0.08), 0.045, 8), 'dark')
    if orn > 0.35:  # a feather, and only ever one
        P.raw(L.tube([(0.26, -0.06, -0.04), (0.44, -0.10, 0.30), (0.52, -0.12, 0.62)],
                     [0.035, 0.026, 0.008], 7), 'gem')
    if orn > 0.7:
        P.add(L.sphere(0.055, 0.04, 0.055, 10, 7), 'gem', loc=(0, -0.32, -0.08))


# ---------------------------------------------------------------------- banner
def build_banner(P, c):
    v, orn = c['variant'], c['orn']
    P.raw(L.tube([(-0.52, 0, -0.92), (-0.52, 0, 0.92)], 0.045, 8), 'dark')
    P.raw(aim(L.cone(0.05, 0.0, 0.20, 8), (-0.52, 0, 0.92), (0, 0, 1)), 'metal')
    top, bot, out = 0.80, -0.62, 0.58
    if v == 0:      # square
        loop = [(-0.50, 0, top), (out, 0, top), (out, 0, bot), (-0.50, 0, bot)]
    elif v == 1:    # swallowtail
        loop = [(-0.50, 0, top), (out, 0, top), (out, 0, bot + 0.30),
                (0.12, 0, bot + 0.06), (out, 0, bot - 0.22), (-0.50, 0, bot)]
    elif v == 2:    # pennant
        loop = [(-0.50, 0, top), (out + 0.18, 0, top - 0.46), (-0.50, 0, bot + 0.22)]
    elif v == 3:    # gonfalon, hung from a crossbar
        P.raw(L.tube([(-0.52, 0, top + 0.06), (out, 0, top + 0.06)], 0.035, 7), 'metal')
        loop = [(-0.46, 0, top), (out - 0.04, 0, top), (out - 0.04, 0, bot + 0.26),
                (0.06, 0, bot), (-0.46, 0, bot + 0.26)]
    else:           # triangular
        loop = [(-0.50, 0, top), (out, 0, top), (-0.50, 0, bot)]
    P.raw(L.membrane([Vector(p) for p in loop], 0.035), 'cloth')
    cx, cz = 0.02, 0.12
    if v == 2 or v == 4:
        cx, cz = -0.18, 0.22
    dev = P.rng.randrange(4)      # the charge on the cloth
    if dev == 0:
        P.raw(aim(L.cone(0.18, 0.16, 0.03, 16), (cx, -0.03, cz), (0, -1, 0)), 'metal')
    elif dev == 1:
        P.add(L.box(0.08, 0.03, 0.40), 'metal', loc=(cx, -0.03, cz))
        P.add(L.box(0.30, 0.03, 0.08), 'metal', loc=(cx, -0.03, cz + 0.08))
    elif dev == 2:
        for k in range(5):
            a = TAU * k / 5 - 0.3
            P.add(L.sphere(0.055, 0.02, 0.055, 8, 6), 'metal',
                  loc=(cx + 0.14 * math.cos(a), -0.03, cz + 0.14 * math.sin(a)))
    else:
        P.raw(aim(L.cone(0.17, 0.0, 0.34, 3), (cx, -0.03, cz - 0.16), (0, 0, 1)), 'metal')
    if orn > 0.5:   # a fringe along the bottom
        for k in range(6):
            x = -0.42 + 0.19 * k
            P.raw(L.tube([(x, 0, bot + 0.02), (x, 0, bot - 0.12)], [0.02, 0.008], 6), 'metal')


# A name that says what it is should get what it says - a Straw Hat is a wide
# brim and a Guild Hood is a hood, whatever the hash would otherwise have picked.
NAME_HINTS = {
    "ring":   {"signet": 1, "seal": 1, "twist": 2, "braid": 2, "plait": 2,
               "stone": 3, "gem": 3, "jewel": 3, "band": 0, "engrav": 4, "etch": 4},
    "amulet": {"locket": 4, "case": 4, "vial": 3, "phial": 3, "flask": 3,
               "crescent": 2, "moon": 2, "disc": 1, "medal": 1, "coin": 1,
               "pendant": 0, "tear": 0, "drop": 0},
    "cloak":  {"hood": 0, "mantle": 1, "short": 1, "half": 1, "long": 2, "sweep": 2,
               "fur": 3, "pelt": 3, "wolf": 3, "tatter": 4, "rag": 4, "ragged": 4},
    "boots":  {"clog": 0, "shoe": 0, "slipper": 0, "sandal": 0, "tall": 2, "rider": 2,
               "high": 2, "fur": 3, "winter": 3, "point": 4},
    "gloves": {"gauntlet": 0, "plate": 0, "mitt": 1, "mitten": 1, "wrap": 4,
               "fingerless": 4, "bracer": 3, "vambrace": 3, "stud": 2},
    # a hat is really eight things, and a Guard Helm must not render as a hood
    "hat":    {"helm": 5, "helmet": 5, "sallet": 5, "barbute": 5, "kettle": 5,
               "visor": 6, "mask": 6, "faceplate": 6,
               "veil": 7, "shroud": 7, "mourn": 7,
               "hood": 4, "cowl": 4, "circlet": 3, "crown": 3, "coronet": 3, "diadem": 3,
               "cap": 1, "coif": 1, "wrap": 1, "cone": 2, "conical": 2, "point": 2,
               "witch": 2, "wide": 0, "brim": 0, "straw": 0},
    "banner": {"swallow": 1, "fork": 1, "pennant": 2, "pennon": 2, "streamer": 2,
               "gonfalon": 3, "standard": 3, "triangle": 4, "wedge": 4, "square": 0},
}


def variant_for(fam, key, name, h):
    """The item's own name first; its hash only when the name says nothing."""
    hay = (name + " " + key).lower()
    for word, v in NAME_HINTS.get(fam, {}).items():
        if word in hay:
            return v
    return h % VARIANTS


FAMILIES = {"ring": build_ring, "amulet": build_amulet, "cloak": build_cloak,
            "boots": build_boots, "gloves": build_gloves,
            "hat": build_hat, "banner": build_banner}
ORDER = ["ring", "amulet", "cloak", "boots", "gloves", "hat", "banner"]

# the gem says what the thing does - accessories carry no colour of their own
STAT_GEM = {"ac": (0.52, 0.66, 0.92), "saves": (0.68, 0.46, 0.92),
            "hp": (0.86, 0.30, 0.32), "speed": (0.40, 0.84, 0.46),
            "hit": (0.95, 0.76, 0.32), "dmg": (0.95, 0.52, 0.22)}
STAT_ORDER = ["ac", "saves", "hp", "speed", "hit", "dmg"]
METALS = [(0.40, 0.42, 0.45), (0.56, 0.38, 0.20), (0.74, 0.76, 0.80), (0.87, 0.70, 0.28)]
METAL_NAMES = ["iron", "bronze", "silver", "gold"]

# ------------------------------------------------- C-61: THE BAND IS THE DATA
# C-61's rule is that every reader bands an accessory by the rarity STORED on
# the item, not by where its price happens to fall in its slot. Three readers
# in this lane banded by the cost quartile - icongen.context (the hub icon's
# metal AND its metal name), d94proof.acc_mats and showcasegen's worn mats -
# so a 300-gold legendary in a slot whose dearest item costs 900 was rendered
# in iron. All three now come through here.
# SIX RARITIES, FOUR METALS: 'very rare' and 'legendary' BOTH land on gold.
# A fifth metal would separate them, but METALS is mirrored in the game
# build's scripts/gear.gd, so adding one is not this lane's to do alone.
RARITY_LADDER = ("starting", "common", "uncommon", "rare", "very rare", "legendary")
_RARITY_Q = {"starting": 0, "common": 0, "uncommon": 1,
             "rare": 2, "very rare": 3, "legendary": 3}


def rarity_q(rarity, orn=0.0):
    """The metal band index 0..3 for one item. The STORED rarity decides it.
    The cost quartile is the fallback ONLY for things that carry no rarity at
    all - cosmetics do not have the key."""
    r = str(rarity or "").strip().lower()
    if r in _RARITY_Q:
        return _RARITY_Q[r]
    return min(3, int(max(0.0, min(1.0, float(orn))) * 4.0))


def build(key, fam, ctx):
    P = Parts(key)
    FAMILIES[fam](P, ctx)
    return P


# --------------------------------------------------------------- D94c: CLOTH
# ONE SOURCE OF TRUTH FOR CLOTH COLOUR, mirrored from scripts/gear.gd so the hub
# icon, the showcase hero and the proof sheet all land on the same object. The
# eight TONES below were copy-pasted into three generators; they live here now.
#
# A cloak does NOT take a leather tone. It is the largest single area of colour
# on a hero and 49 of them were reading as one brown-grey cape with a different
# collar, so it wears a DYE of its own: twelve period dyes, kept below full
# saturation so they sit in the HD palette. THE SHARED RULE, bit for bit:
#   hay   = (name + " " + key).lower()
#   dye_i = the FIRST entry of CLOAK_WORDS (in list order) whose word is in hay,
#           else (khash(key) >> 8) % 12   (the same bits the TONES used)
# Gloves and boots keep the TONES - they are leather. Values are Blender LINEAR;
# gear.gd holds the identical numbers and calls linear_to_srgb() on them.
TONES = ((0.30, 0.25, 0.20), (0.22, 0.19, 0.17), (0.36, 0.28, 0.20),
         (0.24, 0.26, 0.29), (0.31, 0.22, 0.22), (0.21, 0.26, 0.23),
         (0.38, 0.34, 0.27), (0.26, 0.23, 0.30))

CLOAK_DYES = ((0.42, 0.08, 0.07),    # 0  madder red
              (0.08, 0.14, 0.36),    # 1  woad blue
              (0.06, 0.20, 0.08),    # 2  woodland green
              (0.04, 0.035, 0.035),  # 3  walnut black
              (0.30, 0.29, 0.27),    # 4  grey wool
              (0.62, 0.56, 0.42),    # 5  undyed cream
              (0.52, 0.30, 0.04),    # 6  weld ochre
              (0.22, 0.06, 0.20),    # 7  wine / mulberry
              (0.04, 0.20, 0.20),    # 8  river teal
              (0.28, 0.10, 0.03),    # 9  russet
              (0.12, 0.08, 0.30),    # 10 scar violet (a dear dye)
              (0.18, 0.17, 0.06))    # 11 oilcloth / peat olive

CLOAK_DYE_NAMES = ["madder", "woad", "green", "walnut", "grey", "cream",
                   "ochre", "wine", "teal", "russet", "violet", "olive"]

CLOAK_WORDS = [
    ("scar", 10), ("red", 0), ("harl", 0), ("raid", 0), ("warhorn", 0),
    ("feast", 7), ("chronicl", 7), ("backstair", 7),
    ("caravan", 9), ("hurdl", 9), ("bowyer", 9),
    ("mourn", 4), ("grey", 4), ("fog", 4), ("ash", 4),
    ("sexton", 3), ("black", 3), ("ossuary", 3), ("grave", 3),
    ("green", 2), ("wood", 2), ("hedge", 2), ("orchard", 2), ("osier", 2),
    ("oilcloth", 11), ("peat", 11), ("turbary", 11), ("mire", 11),
    ("tanner", 9), ("butcher", 9),
    ("winter", 5), ("salt", 5), ("pilgrim", 5), ("lime", 5),
    ("lamp", 6), ("guild", 6), ("thatch", 6), ("crier", 6),
    ("commander", 1), ("constable", 1), ("watch", 1), ("wall", 1),
    ("ferry", 8), ("raft", 8), ("lighter", 8), ("lock", 8), ("crane", 8),
    ("wake", 8), ("deep", 8),
]


def khash(key):
    """gear.gd's d94_hash, bit for bit - the dial every derivation turns."""
    h = 0
    for ch in key:
        h = (h * 131 + ord(ch)) & 0xFFFFFFFF
    return h


def cloak_dye_i(key, name=""):
    hay = (name + " " + key).lower()
    for word, i in CLOAK_WORDS:
        if word in hay:
            return i
    return (khash(key) >> 8) % len(CLOAK_DYES)


# D94c-2: THE DYE IS NOT ENOUGH ON ITS OWN. Looked at the row - six cells came
# back russet, green, wine, GREEN, olive, GREEN, and the two greens with the same
# cut were one object again. Measured over all 49: fifteen cloaks share BOTH a dye
# and a cut with another cloak, six of them woad+mantle (every watch and wall
# cloak in Bellmire). That is correct in the world - a hedgeward and an orchardman
# both wear green, and the watch wears blue - so the answer is not to scatter the
# dyes. It is a SHADE STEP inside the dye, and it is assigned the way D94b assigned
# form: by POSITION IN THE COLLIDING GROUP, so it cannot collide by construction.
#   group = every cloak sharing (dye_i, variant), keys sorted as plain strings
#   shade_i = the key's index in that group, capped at 7; 0 leaves the dye alone
#   dye * CLOAK_SHADES[shade_i], clamped - same dye, lighter or darker bolt of it
# THE GAME LANE MUST MIRROR THIS in gear.gd beside cloak_dye_i, exactly as this
# lane mirrored the dye. Until it does, the first cloak of every group still
# matches the hero and the rest are off by a value step, never by a hue.
CLOAK_SHADES = (1.00, 0.72, 1.34, 0.56, 1.62, 0.88, 1.16, 0.44)

_cloak_shade = {}


def register_cloaks(accessories):
    """Build the shade table once from the whole accessory list. Callers that
    have items.json open call this before deriving any cloak."""
    _cloak_shade.clear()
    cloaks = sorted(k for k, v in accessories.items()
                    if isinstance(v, dict) and v.get("slot") == "cloak")
    groups = {}
    for k in cloaks:
        nm = accessories[k].get("name", "")
        sig = (cloak_dye_i(k, nm), variant_for("cloak", k, nm, khash(k)))
        n = groups.get(sig, 0)
        _cloak_shade[k] = min(n, len(CLOAK_SHADES) - 1)
        groups[sig] = n + 1
    return len(_cloak_shade)


def cloth_tone(fam, key, name=""):
    """The cloth colour for one accessory: a cloak takes a dye, leather a tone."""
    if fam == "cloak":
        c = CLOAK_DYES[cloak_dye_i(key, name)]
        k = CLOAK_SHADES[_cloak_shade.get(key, 0)]
        return tuple(min(0.95, max(0.02, v * k)) for v in c)
    return TONES[(khash(key) >> 8) % len(TONES)]
