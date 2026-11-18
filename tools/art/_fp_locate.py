"""WHICH PART DIPS? - name the geometry that sets a body's global minimum z.

The foot-plane audit says HOW FAR a body's declared contact floats. It cannot
say WHAT drags the floor down, so a fix is a guess until this runs. Every
Parts.add / Parts.raw call is wrapped to record the LINE IN minibosses.py that
made it, so the report names source lines, not anonymous item indices.

RED ON EMPTY: a body with no items, or a run that resolves no caller line, is
an error - a probe that attributes nothing must not read as a clean sheet.

usage: blender -b --factory-startup -P _fp_locate.py -- <key> [<key> ...]
"""
import os
import sys
import traceback

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import minibosses as M  # noqa: E402
from lords import Parts  # noqa: E402

HERE = os.path.basename(M.__file__)
_orig_add, _orig_raw = Parts.add, Parts.raw


def _where():
    for fr in reversed(traceback.extract_stack()[:-2]):
        if os.path.basename(fr.filename) == HERE:
            return "%s:%d  %s" % (HERE, fr.lineno, (fr.line or "").strip()[:72])
    return None


def _wrap(fn):
    def inner(self, *a, **k):
        n = len(self.items)
        fn(self, *a, **k)
        for it in self.items[n:]:
            self.origin = getattr(self, "origin", {})
            self.origin[id(it)] = _where()
    return inner


Parts.add, Parts.raw = _wrap(_orig_add), _wrap(_orig_raw)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
keys = argv or list(M.ORDER)
if not keys:
    raise SystemExit("RED: no keys to probe")

for key in keys:
    b = M.BUILDERS.get(key)
    if b is None:
        raise SystemExit("RED: no builder for %s" % key)
    P = b()
    if not P.items:
        raise SystemExit("RED: %s built zero items" % key)
    org = getattr(P, "origin", {})
    rows = []
    for it in P.items:
        zs = [v[2] for v in it[0]]
        if not zs:
            continue
        rows.append((min(zs), max(zs), it[2], org.get(id(it)), len(it[0])))
    if not rows:
        raise SystemExit("RED: %s yielded no vertices" % key)
    if not any(r[3] for r in rows):
        raise SystemExit("RED: %s - not one item resolved a caller line; this "
                         "probe attributed nothing" % key)
    gmin = min(r[0] for r in rows)
    print("\n%s - %d items, global min z %+.4f" % (key, len(rows), gmin))
    print("  EVERY ITEM REACHING BELOW z=0, deepest first:")
    below = [r for r in rows if r[0] < -0.0015]
    if not below:
        print("    (none)")
    for zmin, zmax, slot, where, nv in sorted(below)[:18]:
        print("    zmin %+.4f  zmax %+.4f  %-6s %3dv  %s"
              % (zmin, zmax, slot, nv, where or "UNATTRIBUTED"))
    at0 = [r for r in rows if abs(r[0]) <= 0.0015]
    print("  ITEMS DECLARING CONTACT (zmin within 1.5 mm of 0): %d" % len(at0))
    for zmin, zmax, slot, where, nv in sorted(at0, key=lambda r: -r[1])[:8]:
        print("    zmin %+.4f  zmax %+.4f  %-6s %3dv  %s"
              % (zmin, zmax, slot, nv, where or "UNATTRIBUTED"))
