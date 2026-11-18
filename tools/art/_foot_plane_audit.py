"""IS THE FEET-OFF-THE-FLOOR FAULT ONE BODY'S, OR THE SET'S?

Found on the Rammer at pass 8: limb() sweeps a ring PERPENDICULAR to the
polyline, so a raked leg's bottom ring tilts and its lowest vertex sits
r*sin(tilt) BELOW the point the builder declared. minibossgen grounds the
merged body on its GLOBAL minimum z, so that dip becomes the floor and every
part the builder honestly placed at z=0.0 - feet, pile bases, anything meant
to touch the ground - is lifted that far INTO THE AIR.

This walks every builder and reports how far each body's lowest vertex sits
below z=0. That number IS the float: it is exactly how high everything the
builder put at z=0.0 ends up off the rendered floor.

GOES RED ON EMPTY: a builder that yields no items, or a set with no keys, is
an error and not a clean sheet.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import minibosses as M  # noqa: E402

# WHAT THIS MEASURES, AND WHAT IT DELIBERATELY DOES NOT.
# My first version of this audit reported "lowest vertex below z=0" and called
# that the float. THAT NUMBER IS A PROXY AND IT LIES. A builder is free to
# author its whole body below z=0 - the Quartermaster loads real pack geometry
# around the pack's own origin - and grounding then puts its true lowest point
# on the floor with NOTHING floating. The first run flagged it at 317 mm and
# that was my instrument's fault, not the body's.
# A body floats only when BOTH are true:
#   (a) it has geometry sitting at z=0.0 - a builder writing a literal 0.0 is
#       DECLARING "this touches the ground": feet, bases, planted things; and
#   (b) something else dips BELOW that, so grounding lifts the declared
#       contact off the floor by the difference.
# So the reported number is (declared-contact z) - (global min z), measured
# only on bodies that declare a contact at all. A body with no vertex near
# z=0 declares nothing and is not judged.
BAR = 0.005
NEAR0 = 0.0015  # a vertex this close to z=0 counts as a declared contact


def main():
    keys = list(M.ORDER)
    if not keys:
        raise SystemExit("RED: ORDER is empty - nothing audited")
    rows, err = [], []
    for k in keys:
        b = M.BUILDERS.get(k)
        if b is None:
            err.append((k, "NO BUILDER"))
            continue
        P = b()
        if not P.items:
            err.append((k, "RED: zero items"))
            continue
        zs = [v[2] for it in P.items for v in it[0]]
        if not zs:
            err.append((k, "RED: zero verts"))
            continue
        gmin = min(zs)
        declares = any(abs(z) <= NEAR0 for z in zs)
        rows.append((k, gmin, declares, (0.0 - gmin) if declares else None))

    judged = [r for r in rows if r[2]]
    if not judged:
        raise SystemExit("RED ON EMPTY: not one body declared a contact at "
                         "z=0 - this instrument measured nothing")
    bad = [r for r in judged if r[3] > BAR]

    print("FOOT-PLANE AUDIT - declared contact vs where grounding puts the floor")
    print("  bodies %d   declare a contact at z=0: %d   bar %.0f mm"
          % (len(rows), len(judged), BAR * 1000))
    for k, gmin, _d, f in sorted(bad, key=lambda r: -r[3]):
        print("    %-22s global min %+.4f  -> declared contact floats %5.1f mm"
              % (k, gmin, f * 1000))
    print("  OVER THE BAR : %d of %d judged" % (len(bad), len(judged)))
    print("  seated       : %d" % (len(judged) - len(bad)))
    print("  not judged (declare no contact at z=0): %d"
          % (len(rows) - len(judged)))
    for k, note in err:
        print("    ERROR %-18s %s" % (k, note))


main()
