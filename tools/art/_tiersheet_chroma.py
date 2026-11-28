"""Per-tier colour/material read off an ALREADY-RENDERED tier sheet.

28 Nov 2026, written with the Blender bridge down. This is the instrument
behind docs/art/WELL_TIER3_MATERIAL_READ.md.

WHERE IT RUNS. It needs numpy AND PIL. cruzader has NEITHER outside Blender
(no system Python, and Blender ships numpy but not PIL), so this runs on the
LINUX bridge container against staged copies of the sheet, not on the Windows
side. When it is promoted into townlib as a real gate it must be rewritten to
load the PNG with bpy.data.images.load and read .pixels as floats, which is
the established house pattern for reading images inside Blender.

WHY CROPS AND NOT SEGMENTATION. Three attempts at automatic per-tier
segmentation all failed the same way and it is worth recording so the next
seat does not repeat them: (1) clustering columns of non-white pixels merged
the caption band with tier 1; (2) clustering above the horizon line cut the
Fountain in half, because its wide basin sits BELOW the horizon - which is
itself a finding about how low that tier is; (3) excluding the modal ground
colour still merged all three tiers, because their ground-contact shadows and
pavers touch. The tiers are separated by EXPLICIT INTERIOR CROPS, read off the
picture by eye, deliberately inset so no boundary pixels bleed between tiers.
That is less elegant and more honest: a crop cannot silently capture the
neighbour the way a failed cluster did.

WHAT IT CANNOT SEE, said before the numbers:
  - WHERE the colour is. A tier whose richness is entirely in one small finial
    and a tier evenly warm all over can report the same mean. The well t3
    finial is exactly this case; only looking caught it.
  - whether the colour is APPROPRIATE. Rich and wrong passes every number.
  - geometry, wear, silhouette, scale, or anything ladder_gate covers.
  - RED ON EMPTY is the caller's job here - a crop that lands on background
    returns px=0 and every other figure is then meaningless. The gate version
    must refuse an empty crop rather than report 0.0 chroma as "not rich".
"""
import sys
import numpy as np
from PIL import Image

def tier_read(path, crops, slab_rgb=(127., 126., 125.), slab_tol=18.0,
              top_skip_frac=0.145, bottom_skip_frac=0.86):
    a = np.array(Image.open(path).convert('RGBA'))
    h, w, _ = a.shape
    r, g, b, al = [a[:, :, i].astype(float) for i in range(4)]
    slab = np.asarray(slab_rgb, dtype=float)
    dist = np.sqrt((r - slab[0])**2 + (g - slab[1])**2 + (b - slab[2])**2)
    subj = (al > 8) & (dist > slab_tol)
    subj[:int(h * top_skip_frac), :] = False      # caption band
    subj[int(h * bottom_skip_frac):, :] = False   # footer band
    out = []
    for name, c0, c1 in crops:
        m = np.zeros_like(subj)
        m[:, c0:c1] = subj[:, c0:c1]
        n = int(m.sum())
        if n == 0:
            out.append(dict(name=name, px=0, empty=True))
            continue
        rr, gg, bb = r[m], g[m], b[m]
        mx = np.maximum(np.maximum(rr, gg), bb)
        mn = np.minimum(np.minimum(rr, gg), bb)
        ch = mx - mn
        sat = np.where(mx > 0, ch / np.maximum(mx, 1), 0)
        out.append(dict(name=name, px=n, empty=False,
                        chroma_mean=float(ch.mean()),
                        chroma_p90=float(np.percentile(ch, 90)),
                        sat_mean=float(sat.mean()),
                        warm_frac=float((rr > bb + 12).mean()),
                        value_mean=float(mx.mean())))
    return out

# The crops used for renders/art/town/_tiers_side_by_side.png (1680x760).
WELL_CROPS = [("well_t1 (The Well)", 300, 500),
              ("well_t2 (The Well Kept)", 560, 790),
              ("well_t3 (The Fountain)", 870, 1180),
              ("HERO knight (reference)", 1250, 1410)]

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "renders/art/town/_tiers_side_by_side.png"
    for d in tier_read(path, WELL_CROPS):
        if d["empty"]:
            print("  %-26s *** EMPTY CROP - every figure below would be a lie ***" % d["name"])
        else:
            print("  %-26s px=%-6d chroma mean=%5.1f p90=%5.1f  sat=%.3f  warm%%=%.3f  val=%5.1f"
                  % (d["name"], d["px"], d["chroma_mean"], d["chroma_p90"],
                     d["sat_mean"], d["warm_frac"], d["value_mean"]))
