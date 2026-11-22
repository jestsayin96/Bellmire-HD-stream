#!/usr/bin/env python3
"""BACK-LAMP CENSUS. Answers, per body and per view, with pixels:

  (a) IS THIS VIEW LIT BY THE EVEN-LIGHT RIG OR BY THE OLD WORLD-FIXED ONE?
      The old rig leaves ONE coloured lamp on the back (the aura rim), so the
      back view's chromaticity swings away from the front's. The even rig
      carries key+fill+rim round with the camera, so all three views share a
      chromaticity. Statistic: L1 distance between the view's chromaticity and
      the FRONT view's chromaticity, over opaque subject pixels only.
      CALIBRATED on beadle_world/ (old rig) vs beadle_even/ (even rig) - the
      same body, same everything, shot both ways. An instrument that cannot
      tell those two apart is not an instrument.

  (b) DOES THIS VIEW STAND ON A FLOOR? --ground composites dark semi-opaque
      pixels only where the beauty film is empty. Count pixels with
      0 < alpha < 0.99 whose RGB is darker than the ground ceiling. Zero means
      the subject is standing on nothing.

RED ON EMPTY: a view with no opaque pixels, or a body with no front view to
compare against, is an ERROR, never a clean zero.
"""
import json, os, sys
import numpy as np
# --- PNG READER WITH A FALLBACK, ADDED 21 NOV 2026 12:5x CT BY THE ART LANE ---
# THE FAULT THIS FIXES IS MY OWN GATE FAILING CLOSED WITHOUT SAYING SO.
# renders/art/minibosses/_tither_guard.log, committed beside the 45th body,
# reads `RC=0` on the wrapper and then
#     ModuleNotFoundError: No module named 'PIL'
# because the guard was launched through BLENDER, and Blender ships numpy and
# NOT PIL - the exact constraint this lane's own charter states in capitals.
# So the second art gate did not fail red and did not fail green: it did not
# RUN, and the wrapper's RC=0 made that look like a pass to anyone reading the
# log tail. An instrument that cannot run is not a pass, and one that cannot
# run while printing RC=0 is worse than one that is missing.
# The shim below gives the same `Image.open(p).convert("RGBA")` surface off
# bpy when PIL is absent, so the guard now runs under BOTH interpreters and
# the RGBA bytes are identical either way (bpy pixels are float 0..1 in
# bottom-up scanline order and are flipped and scaled back to uint8 here).
try:
    from PIL import Image                                    # noqa: F401
except ModuleNotFoundError:                                  # pragma: no cover
    import numpy as _np

    class _BpyRGBA(object):
        def __init__(self, arr):
            self._a = arr

        def convert(self, mode="RGBA"):
            if mode != "RGBA":
                raise ValueError("_BpyRGBA only serves RGBA, asked for %s" % mode)
            return self

        def __array__(self, dtype=None):
            return self._a if dtype is None else self._a.astype(dtype)

    class Image(object):
        @staticmethod
        def open(path):
            import bpy
            img = bpy.data.images.load(str(path), check_existing=False)
            try:
                w, h = img.size
                buf = _np.empty(w * h * 4, dtype=_np.float32)
                img.pixels.foreach_get(buf)
                a = buf.reshape(h, w, 4)[::-1]          # bpy is bottom-up
                return _BpyRGBA((_np.clip(a, 0.0, 1.0) * 255.0 + 0.5)
                                .astype(_np.uint8))
            finally:
                bpy.data.images.remove(img)

_HERE = os.path.dirname(os.path.abspath(__file__))        # <repo>/tools/art
W5 = os.path.dirname(os.path.dirname(_HERE))              # <repo>
ROOT = os.environ.get("MBFIT_RENDERS") or os.path.join(
    W5, "renders", "art", "minibosses")
if not os.path.isdir(ROOT):
    raise SystemExit("render root not found: %s" % ROOT)
VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
# GROUND_RGB (0.07,0.07,0.085) * GROUND_MAX_A 0.50 premultiplied-ish; measure
# generously and report the darkness so the number can be judged, not trusted.
GROUND_V_MAX = 0.28


def read(p):
    im = Image.open(p).convert("RGBA")
    a = np.asarray(im).astype(np.float64) / 255.0
    return a[..., :3], a[..., 3]


def chroma(rgb, alpha):
    m = alpha > 0.9
    n = int(m.sum())
    if n == 0:
        return None, 0, None
    mean = rgb[m].mean(axis=0)
    s = float(mean.sum())
    if s <= 1e-9:
        return None, n, mean
    return mean / s, n, mean


def _dilate(mask, r):
    """Binary dilation by r px, 4 shifts per step, numpy only."""
    m = mask.copy()
    for _ in range(r):
        o = m.copy()
        o[1:, :] |= m[:-1, :]
        o[:-1, :] |= m[1:, :]
        o[:, 1:] |= m[:, :-1]
        o[:, :-1] |= m[:, 1:]
        m = o
    return m


def ground_px(rgb, alpha):
    """A FLOOR, NOT A SILHOUETTE EDGE.

    The first build of this counted every dark partial-alpha pixel and fired
    2,904 on beadle_world/ - a body rendered BEFORE --ground existed and which
    therefore has no floor at all. It was counting the antialiased rim of a
    dark subject. An instrument that reads the same on both arms of a known
    A/B is not an instrument, so it is narrowed here: the composited floor is
    written ONLY where the beauty film is empty and is capped at
    GROUND_MAX_A = 0.50, so a floor pixel is dark, no more than half opaque,
    and NOT touching the silhouette. Edge pixels fail all three.
    """
    part = (alpha > 0.02) & (alpha <= 0.52)
    if not part.any():
        return 0, 0.0
    v = rgb.max(axis=2)
    near = _dilate(alpha > 0.52, 2)
    dark = part & (v < GROUND_V_MAX) & (~near)
    n = int(dark.sum())
    return n, (float(alpha[dark].max()) if n else 0.0)


def body(name):
    d = os.path.join(ROOT, name)
    row = {"key": name, "views": {}, "errors": []}
    ref = None
    for i, v in enumerate(VIEWS):
        p = os.path.join(d, v)
        tag = v.replace("hero_", "").replace(".png", "")
        if not os.path.exists(p):
            row["views"][tag] = {"missing": True}
            row["errors"].append("%s: missing" % tag)
            continue
        rgb, alpha = read(p)
        ch, n, mean = chroma(rgb, alpha)
        if n == 0 or ch is None:
            row["views"][tag] = {"opaque_px": n, "blank": True}
            row["errors"].append("%s: no opaque pixels (RED ON EMPTY)" % tag)
            continue
        gn, ga = ground_px(rgb, alpha)
        e = {"opaque_px": n,
             "mean_rgb": [round(float(x) * 255, 1) for x in mean],
             "chroma": [round(float(x), 5) for x in ch],
             "ground_px": gn, "ground_max_a": round(ga, 4)}
        if i == 0:
            ref = ch
            e["dist_from_front"] = 0.0
        elif ref is None:
            e["dist_from_front"] = None
            row["errors"].append("%s: no front view to compare against" % tag)
        else:
            e["dist_from_front"] = round(float(np.abs(ch - ref).sum()), 5)
        row["views"][tag] = e
    return row


if __name__ == "__main__":
    names = sys.argv[1:]
    if not names:
        names = sorted(x for x in os.listdir(ROOT)
                       if os.path.isdir(os.path.join(ROOT, x))
                       and not x.startswith("_") and "_chibi" not in x)
    out = {"bodies": [body(n) for n in names]}
    print(json.dumps(out, indent=1))
