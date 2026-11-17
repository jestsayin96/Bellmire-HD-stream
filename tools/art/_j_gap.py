"""_j_gap - the Jointer's own instrument, and it must be able to FAIL.

THE JOINTER'S WHOLE IDEA IS THAT IT COMES APART, so the thing to measure is
whether you can SEE THROUGH THE MIDDLE OF IT from the front. Pass 1 looked
split to the eye but the two rope lashings crossed the gap as flat slabs and
closed it, which is exactly the Scrapwright fault - the idea invisible before
the fight starts - so it gets a number instead of an opinion.

THREE MEASUREMENTS, taken separately because three things changed:
  OPEN   per image row in the body band, can you see through THE SEAM - a
         transparent run at least HOLE_MIN px wide lying inside a window round
         the figure's own centre of mass, with opaque pixels both left and
         right of it. Reported as the fraction of band rows open and the mean
         hole width in px.
         PASS 1 OF THIS INSTRUMENT TOOK THE WIDEST GAP ON THE ROW INSTEAD AND
         SCORED 0.90 OPEN ON A SEAM I COULD SEE WAS SHUT IN THE PICTURE - the
         widest gap on those rows is between the hanging mallet and the body,
         not the seam. The eye caught the instrument, which is the only reason
         this file now measures a WINDOW and not a row.
  SPREAD p90 - p10 luminance over opaque pixels. One grey body and one grey
         pin is a material failure you cannot see in a silhouette.
  BORDER any opaque pixel in the outer ring = the piece is CUT BY THE FRAME.
         The blank check cannot see this: a clipped icon is not a blank one.

RED ON EMPTY, and this is the point of writing it this way: a band with no
rows, or an image with no opaque pixels, scores NOTHING and returns RED. A
metric computed over zero rows reads green and means nothing (System 1).
"""
import json
import sys

import numpy as np
from PIL import Image

HOLE_MIN = 10          # px of clear air that counts as seeing through it
BORDER = 2             # px ring that must stay empty
WINDOW = 0.13          # half-width of the seam window, as a fraction of figure width


def measure(path, band=(0.18, 0.62)):
    im = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32) / 255.0
    h, w, _ = im.shape
    a = im[..., 3] > 0.02
    n = int(a.sum())
    out = {"file": path, "px": n, "h": h, "w": w, "verdict": "RED", "why": []}
    if n < 400:
        out["why"].append("blank or near-blank: %d opaque px" % n)
        return out
    edge = int(a[:BORDER].sum() + a[-BORDER:].sum()
               + a[:, :BORDER].sum() + a[:, -BORDER:].sum())
    out["border_px"] = edge
    rows = np.where(a.any(axis=1))[0]
    top, bot = int(rows.min()), int(rows.max())
    z0 = int(top + (bot - top) * band[0])
    z1 = int(top + (bot - top) * band[1])
    out["band_rows"] = int(max(0, z1 - z0))
    if out["band_rows"] <= 0:
        out["why"].append("EMPTY BAND: 0 rows measured, so OPEN means nothing")
        return out
    cols = np.where(a.any(axis=0))[0]
    cx = int(np.average(np.arange(w), weights=a.sum(axis=0)))
    half = max(HOLE_MIN, int(WINDOW * (cols.max() - cols.min())))
    x0, x1 = max(0, cx - half), min(w, cx + half)
    out["window"] = [int(x0), int(x1), int(cx)]
    open_rows, widths = 0, []
    for y in range(z0, z1):
        xs = np.where(a[y])[0]
        if xs.size < 2:
            continue
        run = 0
        best = 0
        for x in range(x0, x1):
            if a[y, x]:
                run = 0
            else:
                run += 1
                # only air with solid on BOTH sides of it counts as see-through
                if xs.min() < x - run and xs.max() > x:
                    best = max(best, run)
        if best >= HOLE_MIN:
            open_rows += 1
            widths.append(best)
    out["open_frac"] = round(open_rows / float(z1 - z0), 4)
    out["open_rows"] = open_rows
    out["hole_px_mean"] = round(float(np.mean(widths)), 1) if widths else 0.0
    lum = (0.2126 * im[..., 0] + 0.7152 * im[..., 1] + 0.0722 * im[..., 2])[a]
    out["lum_p10"] = round(float(np.percentile(lum, 10)), 4)
    out["lum_p90"] = round(float(np.percentile(lum, 90)), 4)
    out["spread"] = round(out["lum_p90"] - out["lum_p10"], 4)
    if edge > 0:
        out["why"].append("CUT BY THE FRAME: %d opaque px in the outer %d px" % (edge, BORDER))
        out["verdict"] = "RED"
    else:
        out["verdict"] = "GREEN"
    return out


if __name__ == "__main__":
    res = [measure(p) for p in sys.argv[1:]]
    print(json.dumps({"ok": all(r["verdict"] == "GREEN" for r in res), "n": len(res),
                      "results": res}, indent=1))
