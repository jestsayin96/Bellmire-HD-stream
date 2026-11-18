"""WHERE IS THE FLOOR, AND WHAT HANGS BELOW IT?

The 12:39 row says the Rammer's "pile shaft shows below the floor plane the
tripod feet stand on", and the team lead confirmed it by eye at 13:1x. The
SOURCE says the pile cone's base is at z=0.0 and the three legs' bottom points
are at z=0.0, so by the source nothing is below anything.

Both can be true, and this script is here to say which. minibossgen grounds the
merged body on its GLOBAL minimum z (minibossgen.py:~104, `ob.location.z - mn.z`).
So the rendered floor is NOT z=0 - it is whatever the single lowest vertex in the
whole build happens to be. If any part dips below z=0, EVERY OTHER PART RISES,
the tripod feet leave the floor, and the lowest thing in the picture is whatever
that part is. A viewer reads the floor off the three planted feet, because that
is what a tripod is for, so a part hanging under that line reads as sunk through
the floor whatever the grounding arithmetic did.

GOES RED ON EMPTY: if the item list is empty, or no item is identified as a
leg foot, it raises rather than printing a tidy zero.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import minibosses as M  # noqa: E402


def main():
    P = M.BUILDERS["rammer"]()
    items = P.items
    if not items:
        raise SystemExit("RED: builder returned zero items - nothing measured")

    rows = []
    for i, it in enumerate(items):
        verts = it[0]
        slot = it[2]
        zs = [v[2] for v in verts]
        xs = [v[0] for v in verts]
        ys = [v[1] for v in verts]
        rows.append(dict(i=i, slot=slot, zmin=min(zs), zmax=max(zs),
                         n=len(verts), xmid=(min(xs) + max(xs)) / 2.0,
                         ymid=(min(ys) + max(ys)) / 2.0))

    gmin = min(r["zmin"] for r in rows)

    # THE THREE LEG FEET. The legs are items 0,1,2 - the first three things the
    # builder adds - and each is a tube whose bottom ring sits at the polyline's
    # first point, z=0.0. Identify them by construction AND assert the shape, so
    # a reordered builder cannot make this instrument quietly measure the wrong
    # three things.
    legs = rows[0:3]
    for r in legs:
        if r["slot"] != "bone" or r["n"] < 16:
            raise SystemExit("RED: item %d is not a leg tube (slot=%s n=%d) - "
                             "builder order changed, fix this probe"
                             % (r["i"], r["slot"], r["n"]))
    foot_plane = min(r["zmin"] for r in legs)

    below = [r for r in rows if r["zmin"] < foot_plane - 1e-6]

    print("RAMMER FLOOR PROBE")
    print("  items                : %d" % len(rows))
    print("  global min z         : %+.4f  <- minibossgen grounds HERE" % gmin)
    print("  tripod foot plane    : %+.4f  <- what a viewer reads as the floor"
          % foot_plane)
    print("  feet stand off floor : %+.4f m" % (foot_plane - gmin))
    print("  parts below the feet : %d" % len(below))
    for r in sorted(below, key=lambda r: r["zmin"]):
        print("    item %3d slot %-5s zmin %+.4f (%+.4f under the feet) "
              "n=%3d at x%+.2f y%+.2f"
              % (r["i"], r["slot"], r["zmin"], r["zmin"] - foot_plane,
                 r["n"], r["xmid"], r["ymid"]))

    # the pile is the cone whose base the builder puts at z=0.0 on the head's
    # x/y. Find it by position rather than by index.
    pile = [r for r in rows if abs(r["xmid"]) < 0.02 and abs(r["ymid"] + 0.10) < 0.05
            and r["zmin"] < 0.05 and r["zmax"] < 0.6]
    print("  pile-ish parts       : %d" % len(pile))
    for r in pile:
        print("    item %3d zmin %+.4f zmax %+.4f (%+.4f under the feet)"
              % (r["i"], r["zmin"], r["zmax"], r["zmin"] - foot_plane))
    if not pile:
        print("    RED ON EMPTY: no pile part matched - do not read this as 'fine'")


main()
