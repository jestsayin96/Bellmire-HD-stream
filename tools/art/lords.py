"""lords - the eight lords of Bellmire, built procedurally (WORK_PLAN D75).

Canon comes from scripts/bestiary.gd BOSS_DEFS (title, height, tint, aura, the
note that prints when it rises) and data/bosses.json (shape notes + uniques).
Each lord is a DIFFERENT SILHOUETTE, not a rescaled adventurer:

  Hollow King   4.2m  an open ribcage and a crown, cold fire coming off it
  Grubmother    4.5m  a wall - wider than tall, segmented, loaded with brood
  Rattling Host 4.4m  one harness, seven skulls, six arms
  Nightwing     3.2m  nearly all wing; the body is an afterthought
  Gravewyrm     9.0m  a narrow tower of coil, dorsal plates, horned head on top
  Ossuary Lord  7.0m  shoulders of stacked skulls, a rib halo, sword planted
  Pale Duchess  4.6m  a collar fan and arms far too long, ending in blades
  Mourncoil    10.0m  a broad barrel coil webbed with frost, flat crowned head

Original geometry only (CC0 constraint; Quaternius Bestiary/QAL is forbidden).
"""
import math
import random
from mathutils import Vector, Matrix

import lordlib as L

TAU = math.pi * 2.0

# title, height(m), tint, aura, note  -- mirrors bestiary.gd BOSS_DEFS
CANON = {
    "hollow_king":  ("The Hollow King", 4.2, (1.00, 0.72, 0.45), (0.55, 0.75, 1.00), "wreathed in cold fire"),
    "grubmother":   ("The Grubmother", 4.5, (0.62, 0.95, 0.45), (0.50, 1.00, 0.30), "vast, slow, and patient"),
    "rattling_host": ("The Rattling Host", 4.4, (0.92, 0.92, 0.86), (0.90, 0.90, 0.80), "a hundred dead men in one harness"),
    "nightwing":    ("Nightwing", 3.2, (0.52, 0.40, 0.72), (0.50, 0.30, 0.90), "too fast to see coming"),
    "gravewyrm":    ("The Gravewyrm", 9.0, (0.82, 0.86, 0.78), (0.60, 1.00, 0.60), "the thing the dungeon was built to hold"),
    "ossuary_lord": ("The Ossuary Lord", 7.0, (0.98, 0.90, 0.60), (1.00, 0.85, 0.40), "it does not hurry; it does not need to"),
    "pale_duchess": ("The Pale Duchess", 4.6, (0.80, 0.62, 0.95), (0.85, 0.50, 1.00), "she opens throats, not doors"),
    "mourncoil":    ("Mourncoil", 10.0, (0.62, 0.84, 1.00), (0.50, 0.85, 1.00), "frost comes off it in sheets"),
}
ORDER = ["hollow_king", "grubmother", "rattling_host", "nightwing",
         "gravewyrm", "ossuary_lord", "pale_duchess", "mourncoil"]


def aim(vf, loc, direction, scale=(1, 1, 1)):
    """Place a +Z-built primitive with its axis along `direction`."""
    v, f = vf
    q = Vector(direction).normalized().to_track_quat('Z', 'Y')
    m = (Matrix.Translation(Vector(loc)) @ q.to_matrix().to_4x4()
         @ Matrix.Diagonal(Vector(scale).to_4d()))
    return [m @ Vector(x) for x in v], f


class Parts(object):
    """items stays a list of (verts, faces, slot) THREE-TUPLES. Vertex colours
    live in a PARALLEL dict keyed by item index (self.vcols) rather than as a
    fourth element, so every consumer that unpacks three - minibossgen,
    _metal_read, _trade_read, _colour_read, lordgen and every builder - keeps
    working untouched. A fourth element would have been tidier and would have
    broken all of them at once."""

    def __init__(self, key):
        self.key = key
        self.items = []
        self.vcols = {}
        self.rng = random.Random(key)

    # vcols is keyed by the ITEM TUPLE'S IDENTITY, not by its index, and that is
    # not an aesthetic choice. _metal_read and _trade_read measure a span by
    # REBUILDING THE BODY WITH THAT SPAN FILTERED OUT, so the item at index 7 of
    # a cut list is not the item at index 7 of the full one. An index key would
    # paint the wrong items and, worse, paint them the FILL colour - a silent
    # mis-paint that reads as "the fix is not there" rather than as an error.
    # Identity is sound here because self.items holds every tuple for the whole
    # build, so no id is ever reused underneath us.
    def _vc(self, item, vcol, n):
        if vcol is None:
            return item
        if len(vcol) != n:
            raise ValueError("%s: %d vertex colours for %d verts"
                             % (self.key, len(vcol), n))
        self.vcols[id(item)] = [tuple(c) for c in vcol]
        return item

    def add(self, vf, slot='body', loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1),
            vcol=None):
        v, f = vf
        item = (L.xform(v, loc, rot, scale), f, slot)
        self.items.append(self._vc(item, vcol, len(v)))

    def raw(self, vf, slot='body', vcol=None):
        v, f = vf
        item = ([Vector(x) for x in v], f, slot)
        self.items.append(self._vc(item, vcol, len(v)))

    def j(self, a):
        return self.rng.uniform(-a, a)


def _skull(P, loc, r=0.24, slot='bone', glow_eyes=True, face=-1.0):
    P.add(L.sphere(r, r * 1.12, r * 1.15, 14, 9), slot, loc=loc)
    P.add(L.box(r * 1.15, r * 1.25, r * 0.48), slot,
          loc=(loc[0], loc[1] + face * r * 0.45, loc[2] - r * 0.78))
    P.add(L.sphere(r * 0.42, r * 0.30, r * 0.34, 10, 7), 'dark',
          loc=(loc[0] - r * 0.42, loc[1] + face * r * 0.80, loc[2] + r * 0.10))
    P.add(L.sphere(r * 0.42, r * 0.30, r * 0.34, 10, 7), 'dark',
          loc=(loc[0] + r * 0.42, loc[1] + face * r * 0.80, loc[2] + r * 0.10))
    if glow_eyes:
        for s in (-1, 1):
            P.add(L.sphere(r * 0.20, r * 0.20, r * 0.20, 8, 6), 'glow',
                  loc=(loc[0] + s * r * 0.42, loc[1] + face * r * 0.88, loc[2] + r * 0.10))


# --------------------------------------------------------------- 1 HOLLOW KING
def hollow_king():
    """Silhouette pass 2: the HOLLOW must read in outline, so the cloak was
    split into two trailing side panels instead of a sheet behind the chest."""
    P = Parts("hollow_king")
    for s in (-1, 1):
        P.raw(L.tube([(0.26 * s, 0.04, 0.04), (0.31 * s, 0.10, 0.78), (0.26 * s, 0.00, 1.56)],
                     [0.16, 0.12, 0.14], 9), 'dark')
        P.add(L.box(0.32, 0.54, 0.14), 'dark', loc=(0.26 * s, -0.16, 0.07))
    P.add(L.sphere(0.40, 0.28, 0.26, 16, 10), 'dark', loc=(0, 0.02, 1.70))
    P.raw(L.tube([(0, 0.10, 1.70), (0, 0.16, 2.34), (0, 0.08, 2.98)], 0.11, 9), 'bone')
    for i, z in enumerate((1.92, 2.17, 2.42, 2.66, 2.86)):
        sweep = 0.56 - i * 0.03
        for s in (-1, 1):
            P.raw(L.tube([(0.04 * s, 0.11, z), (0.38 * s, -0.12, z - 0.06),
                          (sweep * s, -0.44, z - 0.22)], [0.055, 0.05, 0.036], 7), 'bone')
    P.raw(L.tube([(-0.68, 0.03, 3.02), (0, 0.07, 3.09), (0.68, 0.03, 3.02)], 0.16, 10), 'bone')
    for s in (-1, 1):
        P.raw(L.tube([(0.68 * s, 0.03, 3.00), (0.92 * s, -0.18, 2.28),
                      (0.80 * s, -0.34, 1.64)], [0.13, 0.10, 0.085], 8), 'dark')
        P.add(L.sphere(0.12, 0.10, 0.15, 10, 7), 'bone', loc=(0.80 * s, -0.36, 1.54))
    P.add(L.cone(0.13, 0.11, 0.24, 10), 'bone', loc=(0, 0.05, 3.06))
    _skull(P, (0, 0.00, 3.48), 0.26, 'bone')
    for k in range(9):
        a = TAU * k / 9.0
        tall = 0.92 if abs(math.sin(a)) < 0.35 and math.cos(a) < 0 else 0.52 + 0.30 * abs(math.cos(a))
        base = (0.28 * math.sin(a), 0.28 * math.cos(a) * 1.05, 3.66)
        P.raw(aim(L.cone(0.055, 0.0, tall, 7), base,
                  (math.sin(a) * 0.40, math.cos(a) * 0.40, 1.0)), 'bone')
    # two trailing panels, clear of the chest so the gap stays a gap
    for s in (-1, 1):
        P.raw(L.membrane([(0.60 * s, 0.14, 3.04), (0.78 * s, 0.20, 3.00),
                          (1.24 * s, 0.74, 0.92), (0.92 * s, 0.62, 0.16),
                          (0.60 * s, 0.86, 0.62), (0.40 * s, 0.54, 1.24)], 0.05), 'dark')
    P.raw(L.tube([(1.34, -0.26, 0.0), (1.37, -0.22, 2.0), (1.40, -0.18, 3.74)],
                 [0.07, 0.06, 0.055], 8), 'dark')
    ring = [Vector((1.40 + 0.26 * math.cos(TAU * k / 16), -0.18, 3.98 + 0.26 * math.sin(TAU * k / 16)))
            for k in range(16)]
    P.raw(L.tube(ring + [ring[0]], 0.05, 7), 'bone')
    P.add(L.sphere(0.14, 0.14, 0.14, 10, 7), 'glow', loc=(1.40, -0.18, 3.98))
    for k in range(7):
        a = TAU * k / 7.0 + 0.3
        bx, by = 0.56 * math.sin(a), 0.48 * math.cos(a)
        z0 = 3.02 if k % 2 else 3.14
        P.raw(L.tube([(bx, by, z0), (bx * 1.25 + 0.12, by * 1.2, z0 + 0.42),
                      (bx * 0.85 - 0.10, by * 0.9, z0 + 0.78), (bx * 1.1, by, z0 + 1.08)],
                     [0.13, 0.085, 0.048, 0.0], 7), 'glow')
    return P


# ---------------------------------------------------------------- 2 GRUBMOTHER
def grubmother():
    """Silhouette pass 2: the brood now breaks the outline instead of sinking
    into the sac - she must read as loaded, not as a boulder."""
    P = Parts("grubmother")
    RX, RY, RZ = 3.10, 1.72, 1.56
    P.add(L.sphere(RX, RY, RZ, 24, 14), 'body', loc=(0, 0.10, 1.74))
    for x in (-2.45, -1.80, -1.10, -0.35, 0.40, 1.15, 1.85, 2.48):
        t = max(0.0, 1.0 - (x / RX) ** 2) ** 0.5
        ry, rz = RY * t * 1.03, RZ * t * 1.03
        if ry < 0.25:
            continue
        ring = [Vector((x, 0.10 + ry * math.cos(TAU * k / 18), 1.74 + rz * math.sin(TAU * k / 18)))
                for k in range(18)]
        P.raw(L.tube(ring + [ring[0]], 0.13, 7), 'dark')
    # the brood has to sit PROUD of the sac or the whole thing reads as a boulder
    for k in range(20):
        a = P.rng.uniform(-1.0, 1.0)
        x = a * 2.85
        t = max(0.1, 1.0 - a * a) ** 0.5
        r = P.rng.uniform(0.42, 0.74)
        P.add(L.sphere(r, r * 1.05, r * 1.05, 12, 8), 'body',
              loc=(x, 0.45 + P.j(0.55), 1.74 + RZ * t * 1.04 + r * 0.92))
    for s in (-1, 1):
        for k in range(4):
            r = 0.46 - 0.06 * k
            P.add(L.sphere(r, r, r, 12, 8), 'body',
                  loc=(s * (3.22 + 0.30 * k), 0.30 + P.j(0.3), 1.85 + 0.58 * k))
    # a tapering abdomen so her outline is not an oval
    for k in range(4):
        r = 1.05 - 0.22 * k
        P.add(L.sphere(r * 1.05, r, r, 14, 9), 'body', loc=(0, 1.80 + 0.70 * k, 1.60 - 0.12 * k))
        if k:
            P.raw(aim(L.cone(0.11, 0.0, 0.74, 6), (0, 1.80 + 0.70 * k, 1.60 + r * 0.8),
                      (0, 0.55, 1.0)), 'bone')
    for z, r in ((3.10, 0.52), (3.62, 0.44), (4.04, 0.35), (4.36, 0.26), (4.60, 0.18)):
        P.add(L.sphere(r, r * 1.05, r, 12, 8), 'body', loc=(P.j(0.12), 0.22 + P.j(0.10), z))
    P.add(L.sphere(1.42, 0.86, 1.00, 18, 12), 'body', loc=(0, -1.30, 1.58))
    P.add(L.sphere(0.95, 0.80, 0.78, 16, 11), 'dark', loc=(0, -1.95, 1.32))
    for s in (-1, 1):
        P.raw(aim(L.cone(0.15, 0.0, 1.22, 8), (0.36 * s, -2.42, 1.08),
                  (0.34 * s, -1.0, -0.26)), 'bone')
        P.raw(aim(L.cone(0.12, 0.0, 0.94, 8), (0.62 * s, -2.30, 1.56),
                  (0.50 * s, -1.0, 0.16)), 'bone')
    for s in (-1, 1):
        for k, (dy, dz) in enumerate(((-2.42, 1.62), (-2.30, 1.40), (-2.12, 1.18))):
            P.add(L.sphere(0.095, 0.095, 0.095, 8, 6), 'glow', loc=(s * (0.18 + 0.16 * k), dy, dz))
    for s in (-1, 1):
        for x in (-2.35, -1.55, -0.70, 0.20, 1.05, 1.90, 2.45):
            P.raw(L.tube([(x, 0.10 + s * 1.10, 0.86), (x + 0.10, 0.10 + s * 1.62, 0.40),
                          (x + 0.14, 0.10 + s * 1.78, 0.02)], [0.16, 0.10, 0.065], 7), 'dark')
    for x in (-1.9, -0.95, 0.0, 0.95, 1.9):
        P.add(L.sphere(0.19, 0.19, 0.13, 10, 7), 'glow', loc=(x, 0.10, 0.34))
    return P


# ------------------------------------------------------------- 3 RATTLING HOST
def rattling_host():
    """Silhouette pass 2: arms thrown wide and the skulls stacked into a clear
    column, so it reads as many men in one harness rather than a blocky golem."""
    P = Parts("rattling_host")
    for s in (-1, 1):
        P.raw(L.tube([(0.34 * s, 0.02, 0.04), (0.40 * s, 0.08, 0.80), (0.34 * s, 0.0, 1.52)],
                     [0.24, 0.20, 0.22], 10), 'dark')
        P.add(L.box(0.44, 0.66, 0.18), 'dark', loc=(0.34 * s, -0.18, 0.09))
    P.add(L.sphere(0.72, 0.48, 0.38, 16, 10), 'dark', loc=(0, 0.02, 1.62))
    P.add(L.sphere(0.80, 0.52, 1.10, 18, 12), 'dark', loc=(0, 0.02, 2.44))
    for z, r in ((1.95, 0.80), (2.45, 0.82), (2.92, 0.66)):
        ring = [Vector((r * math.cos(TAU * k / 18), 0.02 + r * 0.66 * math.sin(TAU * k / 18), z))
                for k in range(18)]
        P.raw(L.tube(ring + [ring[0]], 0.085, 6), 'bone')
    for k in range(13):
        x = -0.66 + 0.11 * k
        P.raw(L.tube([(x, -0.32, 1.58), (x * 1.15, -0.46, 1.12), (x * 1.2, -0.42, 0.74)],
                     [0.055, 0.042, 0.022], 6), 'bone')
    P.raw(L.tube([(-1.04, 0.02, 2.99), (0, 0.06, 3.08), (1.04, 0.02, 2.99)], 0.15, 10), 'bone')
    tops = [(0.00, -0.08, 3.22), (-0.26, 0.10, 3.52), (0.27, 0.08, 3.58),
            (-0.12, -0.14, 3.86), (0.16, -0.06, 4.02), (-0.04, 0.08, 4.28), (0.03, -0.04, 4.54)]
    for i, t in enumerate(tops):
        _skull(P, t, 0.245 - i * 0.010, 'bone')
    sh = [(1.02, 2.98, 1.15, -0.95), (1.02, 2.42, 0.95, -0.25), (0.86, 1.96, 0.80, 0.35)]
    for s in (-1, 1):
        for (x, z, ln, lift) in sh:
            P.raw(L.tube([(x * s, 0.02, z), (x * 1.72 * s, -0.30, z - 0.34 * ln + lift * 0.3),
                          (x * 1.92 * s, -0.58, z - 0.92 * ln + lift)], [0.14, 0.105, 0.082], 8), 'dark')
            P.add(L.sphere(0.15, 0.13, 0.17, 10, 7), 'bone',
                  loc=(x * 1.92 * s, -0.62, z - 1.00 * ln + lift))
    P.raw(L.tube([(1.75, -0.60, 2.40), (1.80, -0.50, 3.50), (1.86, -0.42, 4.62)],
                 [0.075, 0.065, 0.055], 8), 'dark')
    for s in (-1, 1):
        P.raw(L.membrane([(1.84, -0.44, 4.40), (1.84, -0.44 + s * 0.92, 4.18),
                          (1.84, -0.44 + s * 1.06, 3.68), (1.84, -0.44 + s * 0.46, 3.48),
                          (1.84, -0.44, 3.68)], 0.08), 'bone')
    for s in (-1, 1):
        P.add(L.sphere(0.10, 0.10, 0.10, 8, 6), 'glow', loc=(0.42 * s, -0.44, 2.58))
    return P


# ----------------------------------------------------------------- 4 NIGHTWING
def nightwing():
    """Silhouette pass 2: scalloped trailing edge and raised ears, so it reads
    as a bat and not as a bowtie. The wings are deliberately asymmetric."""
    P = Parts("nightwing")
    P.add(L.sphere(0.33, 0.62, 0.42, 16, 11), 'body', loc=(0, 0.02, 1.90))
    P.add(L.sphere(0.28, 0.30, 0.29, 14, 10), 'body', loc=(0, -0.64, 2.14))
    P.add(L.cone(0.18, 0.07, 0.32, 10), 'dark', loc=(0, -0.64, 2.10), rot=(math.radians(-96), 0, 0))
    for s in (-1, 1):
        P.raw(aim(L.cone(0.11, 0.0, 1.06, 8), (0.14 * s, -0.50, 2.30),
                  (0.30 * s, 0.34, 1.0)), 'dark')
        P.add(L.sphere(0.06, 0.06, 0.06, 8, 6), 'glow', loc=(0.13 * s, -0.88, 2.16))
    for s in (-1, 1):
        fwd = 0.28 * s            # one wing swept forward, one back
        shoulder = (0.22 * s, 0.06, 2.06)
        wrist = (1.14 * s, 0.14 - fwd, 2.78)
        tips = [(1.98 * s, 0.86 - fwd, 3.22), (2.62 * s, 0.06 - fwd, 2.38),
                (2.30 * s, -0.60 - fwd, 1.44), (1.30 * s, -0.94 - fwd, 0.82)]
        P.raw(L.tube([shoulder, (0.68 * s, 0.10 - fwd, 2.46), wrist], [0.10, 0.085, 0.072], 8), 'dark')
        for t in tips:
            P.raw(L.tube([wrist, ((wrist[0] + t[0]) / 2, (wrist[1] + t[1]) / 2, (wrist[2] + t[2]) / 2), t],
                         [0.065, 0.045, 0.02], 7), 'dark')
        loop = [shoulder, wrist, tips[0]]
        for a, b in zip(tips, tips[1:]):
            mid = Vector(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2))
            w = Vector(wrist)
            loop.append(tuple(mid + (w - mid) * 0.26))   # the scallop
            loop.append(b)
        loop.append((0.20 * s, -0.14, 1.46))
        P.raw(L.membrane(loop, 0.035), 'body')
    for s in (-1, 1):
        P.raw(L.tube([(0.20 * s, 0.26, 1.68), (0.26 * s, 0.36, 1.38), (0.24 * s, 0.26, 1.18)],
                     [0.065, 0.05, 0.035], 7), 'dark')
        for k in range(3):
            P.raw(aim(L.cone(0.024, 0.0, 0.24, 6), (0.24 * s, 0.26, 1.18),
                      (0.3 * s * (k - 1), -0.5, -1.0)), 'bone')
    P.raw(L.tube([(0, 0.46, 1.80), (0, 1.00, 1.38), (0, 1.42, 0.94), (0, 1.64, 0.58)],
                 [0.11, 0.07, 0.045, 0.015], 7), 'dark')
    return P


# ----------------------------------------------------------------- 5 GRAVEWYRM
def gravewyrm():
    """Silhouette pass 2: the dorsal plates are twice the size and set every
    third segment, so the spine spikes the outline all the way up."""
    P = Parts("gravewyrm")
    path = L.helix(2.35, 0.10, 7.05, 1.78, 0.44, steps=84)
    radii = L.lerp_list(0.80, 0.30, len(path))
    neck = [Vector((0.30, -0.25, 7.45)), Vector((0.16, -0.70, 7.90)),
            Vector((0.04, -1.10, 8.22)), Vector((0.0, -1.44, 8.40))]
    P.raw(L.tube(path + neck, radii + [0.29, 0.28, 0.27, 0.26], 12), 'body')
    n = len(path)
    for i in range(4, n - 2, 3):
        p = path[i]
        out = Vector((p.x, p.y, 0.0))
        if out.length < 1e-6:
            out = Vector((1, 0, 0))
        out.normalize()
        t = i / float(n)
        P.raw(aim(L.cone(0.42 * (1.0 - 0.45 * t), 0.0, 1.42 * (1.0 - 0.50 * t), 7),
                  (p.x, p.y, p.z), (out.x * 0.42, out.y * 0.42, 1.0)), 'bone')
    P.add(L.sphere(0.58, 1.06, 0.50, 16, 11), 'body', loc=(0, -1.88, 8.44))
    P.add(L.box(0.52, 0.96, 0.16), 'dark', loc=(0, -1.94, 8.14))
    for s in (-1, 1):
        P.raw(L.tube([(0.28 * s, -1.50, 8.74), (0.54 * s, -0.80, 9.06), (0.66 * s, -0.10, 9.14)],
                     [0.12, 0.07, 0.022], 7), 'bone')
        P.add(L.sphere(0.10, 0.10, 0.10, 8, 6), 'glow', loc=(0.21 * s, -2.22, 8.56))
        for k in range(5):
            P.raw(aim(L.cone(0.05, 0.0, 0.26, 6),
                      (0.22 * s, -2.52 + k * 0.32, 8.20), (0, 0.1, -1.0)), 'bone')
    for k in range(5):
        P.add(L.sphere(0.15, 0.15, 0.11, 10, 7), 'glow',
              loc=(0.14 - k * 0.04, -1.34 + k * 0.22, 7.98 - k * 0.11))
    return P


# -------------------------------------------------------------- 6 OSSUARY LORD
def ossuary_lord():
    P = Parts("ossuary_lord")
    for s in (-1, 1):
        P.raw(L.tube([(0.52 * s, 0.04, 0.06), (0.60 * s, 0.12, 1.30), (0.52 * s, 0.0, 2.48)],
                     [0.40, 0.32, 0.34], 10), 'dark')
        P.add(L.box(0.60, 0.92, 0.22), 'dark', loc=(0.52 * s, -0.24, 0.11))
    P.add(L.sphere(0.74, 0.52, 0.42, 16, 10), 'dark', loc=(0, 0.02, 2.60))
    P.add(L.sphere(0.94, 0.64, 1.26, 18, 12), 'dark', loc=(0, 0.02, 3.74))
    for i, z in enumerate((3.00, 3.34, 3.68, 4.02, 4.32)):
        for s in (-1, 1):
            P.raw(L.tube([(0.06 * s, 0.16, z), (0.62 * s, -0.16, z - 0.04),
                          (0.80 * s, -0.48, z - 0.14)], [0.08, 0.07, 0.05], 7), 'bone')
    P.raw(L.tube([(-1.34, 0.02, 4.74), (0, 0.06, 4.82), (1.34, 0.02, 4.74)], 0.19, 10), 'bone')
    # pauldrons of stacked skulls
    for s in (-1, 1):
        for k, (dx, dy, dz) in enumerate(((0.0, -0.22, 4.40), (0.30, 0.16, 4.52),
                                          (-0.22, 0.18, 4.36), (0.10, -0.06, 4.76), (0.0, 0.12, 4.08))):
            _skull(P, (s * (1.30 + dx * s), dy, dz), 0.31 - k * 0.012, 'bone', glow_eyes=(k < 3))
        P.raw(aim(L.cone(0.62, 0.42, 0.26, 12), (1.30 * s, 0.0, 4.92), (0.28 * s, 0, 1.0)), 'bone')
        P.raw(L.tube([(1.30 * s, 0.02, 4.40), (1.58 * s, -0.30, 3.34), (1.36 * s, -0.56, 2.46)],
                     [0.21, 0.17, 0.15], 9), 'dark')
        P.add(L.sphere(0.22, 0.19, 0.24, 12, 8), 'bone', loc=(1.34 * s, -0.60, 2.34))
    _skull(P, (0, 0.0, 5.36), 0.44, 'bone')
    for k in range(5):
        a = -0.9 + 0.45 * k
        P.raw(aim(L.cone(0.07, 0.0, 0.40, 7), (0.30 * math.sin(a), 0.30 * math.cos(a) - 0.05, 5.68),
                  (math.sin(a) * 0.4, math.cos(a) * 0.4, 1.0)), 'bone')
    # the rib halo
    for k in range(9):
        a = -1.15 + 0.2875 * k
        sx = math.sin(a)
        P.raw(L.tube([(0.14 * sx, 0.48, 4.62), (1.00 * sx, 0.96, 5.86), (1.52 * sx, 0.80, 6.92)],
                     [0.115, 0.075, 0.03], 7), 'bone')
    # the sword it does not hurry to lift
    P.add(L.box(0.26, 0.09, 3.28), 'bone', loc=(1.06, -0.78, 1.66))
    P.raw(aim(L.cone(0.14, 0.0, 0.34, 6), (1.06, -0.78, 0.0), (0, 0, -1.0)), 'bone')
    P.add(L.box(0.94, 0.16, 0.16), 'bone', loc=(1.06, -0.78, 3.34))
    P.raw(L.tube([(1.06, -0.78, 3.42), (1.06, -0.78, 4.04)], 0.07, 8), 'dark')
    P.add(L.sphere(0.12, 0.12, 0.12, 10, 7), 'glow', loc=(1.06, -0.78, 4.12))
    # shield
    P.raw(aim(L.cone(0.86, 0.80, 0.14, 16), (-1.56, -0.62, 3.30), (-1.0, -0.12, 0.0)), 'dark')
    for k in range(6):
        a = TAU * k / 6.0
        P.raw(aim(L.cone(0.07, 0.0, 0.30, 6),
                  (-1.62, -0.62 + 0.55 * math.cos(a), 3.30 + 0.55 * math.sin(a)),
                  (-1.0, -0.1, 0.0)), 'bone')
    return P


# -------------------------------------------------------------- 7 PALE DUCHESS
def pale_duchess():
    P = Parts("pale_duchess")
    P.add(L.cone(1.02, 0.30, 2.56, 22), 'body', loc=(0, 0.06, 0.0))
    for k in range(14):
        a = TAU * k / 14.0
        P.raw(L.tube([(0.30 * math.sin(a), 0.06 + 0.30 * math.cos(a), 2.52),
                      (0.70 * math.sin(a), 0.06 + 0.70 * math.cos(a), 1.26),
                      (1.04 * math.sin(a), 0.06 + 1.04 * math.cos(a), 0.02)],
                     [0.028, 0.034, 0.042], 6), 'dark')
    P.raw(L.membrane([(-0.86, 0.52, 0.12), (0.86, 0.52, 0.12), (0.72, 2.00, 0.06),
                      (0.0, 2.52, 0.04), (-0.72, 2.00, 0.06)], 0.04), 'dark')
    P.add(L.sphere(0.33, 0.26, 0.22, 16, 10), 'dark', loc=(0, 0.04, 2.62))
    P.add(L.sphere(0.34, 0.27, 0.54, 16, 11), 'body', loc=(0, 0.02, 3.06))
    # the collar fan
    for k in range(11):
        a = -1.25 + 0.25 * k
        sx = math.sin(a)
        hgt = 1.44 - 0.34 * abs(a)
        P.raw(aim(L.cone(0.105, 0.0, hgt, 7), (0.08 * sx, 0.26, 3.22),
                  (sx * 0.90, 0.44, 1.0)), 'bone')
    P.add(L.sphere(0.21, 0.23, 0.26, 14, 10), 'bone', loc=(0, -0.02, 3.60))
    P.raw(L.membrane([(-0.20, -0.18, 3.78), (0.20, -0.18, 3.78), (0.17, -0.26, 3.36),
                      (0.0, -0.30, 3.24), (-0.17, -0.26, 3.36)], 0.03), 'dark')
    for s in (-1, 1):
        P.add(L.sphere(0.055, 0.055, 0.055, 8, 6), 'glow', loc=(0.09 * s, -0.22, 3.64))
    for k in range(3):
        P.add(L.sphere(0.05, 0.05, 0.05, 8, 6), 'glow', loc=(-0.14 + 0.14 * k, -0.14, 3.86))
    # arms far too long
    for s in (-1, 1):
        P.add(L.sphere(0.17, 0.15, 0.15, 12, 8), 'body', loc=(0.33 * s, 0.02, 3.26))
        hand = (1.52 * s, -0.72, 1.04)
        P.raw(L.tube([(0.33 * s, 0.02, 3.26), (0.96 * s, -0.36, 2.52),
                      (1.45 * s, -0.64, 1.54), hand], [0.125, 0.09, 0.068, 0.055], 8), 'body')
        for k in range(4):
            P.raw(aim(L.cone(0.048, 0.0, 0.82, 6), hand,
                      (s * (0.22 + 0.16 * k), -0.30 + 0.12 * k, -1.0)), 'bone')
    return P


# ----------------------------------------------------------------- 8 MOURNCOIL
def mourncoil():
    """Silhouette pass 2: the frost sheets were filling the coil and killing the
    read, so there are two of them now, set outside the loops, and the icicles
    are long enough to spike the outline."""
    P = Parts("mourncoil")
    path = L.helix(2.10, 0.12, 6.30, 2.56, 1.92, steps=76)
    radii = L.lerp_list(1.00, 0.44, len(path))
    neck = [Vector((1.10, -1.10, 6.90)), Vector((0.50, -1.90, 7.74)),
            Vector((0.14, -2.34, 8.56)), Vector((0.02, -2.48, 9.02))]
    P.raw(L.tube(path + neck, radii + [0.42, 0.38, 0.34, 0.31], 12), 'body')
    step = int(76 / 2.10)
    for i in (10, 40):
        if i + step + 6 >= len(path):
            continue
        a, b = path[i], path[i + 5]
        c, d = path[i + step + 5], path[i + step]
        out = Vector((a.x, a.y, 0)).normalized() * 0.55
        P.raw(L.membrane([a + out, b + out, c + out * 0.8, d + out * 0.8], 0.05), 'glow')
    for i in range(3, len(path), 2):
        p = path[i]
        out = Vector((p.x, p.y, 0.0))
        if out.length < 1e-6:
            out = Vector((1, 0, 0))
        out.normalize()
        t = i / float(len(path))
        P.raw(aim(L.cone(0.17 * (1 - 0.35 * t), 0.0, 1.15 + 0.55 * (1 - t), 6),
                  (p.x + out.x * 0.18, p.y + out.y * 0.18, p.z),
                  (out.x, out.y, -0.38)), 'glow')
    P.add(L.sphere(0.68, 1.10, 0.38, 18, 11), 'body', loc=(0, -2.78, 9.16))
    P.add(L.box(0.62, 1.00, 0.14), 'dark', loc=(0, -2.84, 8.92))
    for s in (-1, 1):
        for k in range(6):
            P.raw(aim(L.cone(0.038, 0.0, 0.20, 6),
                      (0.28 * s, -3.28 + k * 0.32, 8.98), (0, 0.1, -1.0)), 'bone')
        P.add(L.sphere(0.10, 0.10, 0.085, 8, 6), 'glow', loc=(0.26 * s, -3.24, 9.20))
    for k in range(7):
        a = -1.05 + 0.35 * k
        sx = math.sin(a)
        P.raw(aim(L.cone(0.13, 0.0, 1.45 + 0.45 * (1 - abs(a))), (0.32 * sx, -2.40, 9.30),
                  (sx * 0.56, 0.82, 0.90)), 'glow')
    for k in range(5):
        P.add(L.sphere(0.17, 0.17, 0.13, 10, 7), 'glow',
              loc=(0.10, -2.05 + k * 0.16, 8.34 - k * 0.30))
    return P


BUILDERS = {
    "hollow_king": hollow_king, "grubmother": grubmother,
    "rattling_host": rattling_host, "nightwing": nightwing,
    "gravewyrm": gravewyrm, "ossuary_lord": ossuary_lord,
    "pale_duchess": pale_duchess, "mourncoil": mourncoil,
}
