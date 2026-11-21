#!/usr/bin/env python3
"""_bagfacing.py - THE BAG-FACING INSTRUMENT, built 21 Nov 2026 for the Blower.

THE VIEWER'S QUESTION, NOT THE MODELLER'S: standing in front of this thing,
how much of what you see is the BELLOWS BAG, and is that bag where the FIGURE
is, or splayed out beside him like scenery?

It reads the SHIPPED RENDER. It needs no Blender scene, no materials and no
depsgraph, so it can be pointed at any pass's output afterwards and at an
archived one, which is how a pass is trended rather than remembered.

Three numbers per view:

  litpale_share    lit pale pixels / creature pixels.
  litpale_central  of those, the fraction inside the middle 50% of the
                   creature's own width. LOW means the pale sits in two wings
                   beside the body - the archway misread.
  outer_share      SILHOUETTE ONLY, no colour: creature pixels outside that
                   middle 50%, over all creature pixels. Lighting cannot
                   touch this one.

*** WHAT THIS INSTRUMENT CANNOT SEE, SAID OUT LOUD, BECAUSE SAYING IT IS THE
*** RULE THIS LANE LEARNED THE HARD WAY AT PASS 11 ON 17 NOV. ***
litpale_* classifies the bag by BRIGHTNESS, so it is a lighting measurement as
much as a material one: a band on the shadow side reads as body and is
UNDERCOUNTED, and the two eyes and the pale nozzle read as bag and are
OVERCOUNTED. I drew the classifier out as a magenta overlay and looked at it:
on the Blower's pass-5 front view the entire left wing of the bag is in shadow
and is scored as body. So use litpale_* for the FRONT-TO-BACK COMPARISON, where
both views are lit the same way and the ASYMMETRY is the signal. Do not read
either number as "this much of the creature is bag". outer_share carries no
such blindness and is the one to trend across a rebuild.

RED ON EMPTY: a view whose creature mask is under MIN_BODY_PX, or which has no
pale pixels at all, reports RED and not a green zero. A metric computed over
nothing is not a pass.

HOW THE CREATURE IS TOLD FROM THE HERO: the KayKit knight wears a saturated red
cape in every view and no miniboss carries that hue, so the column-run with red
in it is the hero and the other is the creature. If both runs carry red the
instrument says so and goes RED rather than guessing.

Run (container/linux, PIL present):
    python3 tools/art/_bagfacing.py renders/art/minibosses/blower
Run (cruzader, no system python - Blender's own python, which has numpy but
no PIL, so the bpy loader below is taken):
    blender -b -noaudio -P tools/art/_bagfacing.py -- <dir>
"""
import sys
import os
import json

import numpy as np

MIN_BODY_PX = 4000      # under this the view found no creature: RED
PALE_MIN = 0.62         # luminance 0..1 at or above this is a lit pale band
RED_SAT = 0.25          # saturation this high with a red hue = the hero's cape
ALPHA_MIN = 0.60        # the renders carry alpha; the contact shadow is soft
VIEWS = ("front", "side", "back")


def load(path):
    """Return straight RGB and alpha, both 0..1, float32.

    PIL where there is one. Where there is not - cruzader has no system python
    and Blender has no PIL - bpy reads the PNG as Non-Color so the sRGB bytes
    round-trip instead of being de-gamma'd under us.
    """
    try:
        from PIL import Image
        a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
        a /= 255.0
    except ImportError:
        import bpy
        img = bpy.data.images.load(path, check_existing=False)
        img.colorspace_settings.name = 'Non-Color'
        w, h = img.size
        buf = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(buf)
        a = buf.reshape(h, w, 4)[::-1]          # bpy rows run bottom-up
        bpy.data.images.remove(img)
    return a[:, :, :3], a[:, :, 3]


def components_by_column(mask, gap=12):
    """Split a mask into column-runs separated by >= `gap` empty columns."""
    cols = mask.any(axis=0)
    runs, start, blanks = [], None, 0
    for x, on in enumerate(cols):
        if on:
            if start is None:
                start = x
            blanks = 0
        elif start is not None:
            blanks += 1
            if blanks >= gap:
                runs.append((start, x - blanks + 1))
                start = None
    if start is not None:
        runs.append((start, len(cols)))
    return runs


def measure(path):
    rgb, alpha = load(path)
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)

    ink = alpha >= ALPHA_MIN
    runs = components_by_column(ink)
    name = os.path.basename(path)
    if not runs:
        return {"view": name, "verdict": "RED", "why": "no ink columns at all",
                "body_px": 0}

    redish = ((sat > RED_SAT)
              & (rgb[:, :, 0] > rgb[:, :, 1] + 0.10)
              & (rgb[:, :, 0] > rgb[:, :, 2] + 0.10))
    scored = []
    for (a, b) in runs:
        seg = ink[:, a:b]
        scored.append({"x0": a, "x1": b, "px": int(seg.sum()),
                       "red": int((redish[:, a:b] & seg).sum())})
    body = [s for s in scored if s["red"] < 200]
    if not body:
        return {"view": name, "verdict": "RED", "runs": scored,
                "why": "every column-run carries red - creature not isolated"}
    cre = max(body, key=lambda s: s["px"])

    a, b = cre["x0"], cre["x1"]
    seg = ink[:, a:b]
    body_px = int(seg.sum())
    if body_px < MIN_BODY_PX:
        return {"view": name, "verdict": "RED", "body_px": body_px,
                "why": "creature mask %d px under floor %d"
                       % (body_px, MIN_BODY_PX)}

    pale = seg & (lum[:, a:b] >= PALE_MIN)
    pale_px = int(pale.sum())
    if pale_px == 0:
        return {"view": name, "verdict": "RED", "body_px": body_px,
                "pale_px": 0,
                "why": "zero pale pixels - none of the bag is visible"}

    xs = np.where(seg.any(axis=0))[0]
    x_lo, x_hi = int(xs.min()), int(xs.max())
    span = x_hi - x_lo + 1
    c_lo = x_lo + int(round(span * 0.25))
    c_hi = x_lo + int(round(span * 0.75))
    mid = slice(c_lo, c_hi + 1)

    return {
        "view": name,
        "verdict": "OK",
        "body_px": body_px,
        "pale_px": pale_px,
        "litpale_share": round(pale_px / body_px, 4),
        "litpale_central": round(int(pale[:, mid].sum()) / pale_px, 4),
        "outer_share": round((body_px - int(seg[:, mid].sum())) / body_px, 4),
        "width_px": span,
        "crop_x": [a, b],
    }


def run(d):
    out = {"dir": d, "rows": [], "verdict": "GREEN", "errors": []}
    for v in VIEWS:
        p = os.path.join(d, "hero_%s.png" % v)
        if not os.path.exists(p):
            out["errors"].append("missing %s" % p)
            out["verdict"] = "RED"
            continue
        r = measure(p)
        out["rows"].append(r)
        if r["verdict"] != "OK":
            out["verdict"] = "RED"
            out["errors"].append("%s: %s" % (v, r.get("why")))
    if not out["rows"]:
        out["verdict"] = "RED"
        out["errors"].append("no views measured at all")
    print("BAGFACING " + json.dumps(out))
    return out


def main():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = argv[1:]
    if not argv:
        print("BAGFACING " + json.dumps(
            {"verdict": "RED", "errors": ["no directory given"]}))
        return
    for d in argv:
        run(d)


if __name__ == "__main__":
    main()
