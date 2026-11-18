"""THE KNOB WINDOW, DERIVED FROM WHERE THE PIXELS MOVED INSTEAD OF TYPED.

My first instrument reported window_base and window_knob IDENTICAL to four
decimals over 19,430 px - which is the Hurdleman's pass-11 fault again: a window
I TYPED from a guess at the frame fraction, big enough to be dominated by the
body and therefore unable to see the one object it existed to measure. It did
not go red; it went blind. The fix is to stop guessing where the knob is and ask
the A/B itself: the knob's pixels are exactly the pixels that MOVED when the
knob changed, so the mask locates the window and the window cannot miss.

Then the number that answers the fault: the knob is the AMBER core, the ground
is what is immediately outside the whole knob assembly, and the question is the
LUMINANCE GAP across that boundary. Amber on cream is a hue difference and
barely a value one - that was the fault.
"""
import os
import sys
import json

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402


def lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def grow(m, n=1):
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:, :] |= out[:-1, :]
        g[:-1, :] |= out[1:, :]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def report(path, bbox, label):
    """Inside the window: split the opaque pixels into the LIT CORE (the brass,
    which is the brightest, most saturated thing there) and everything else,
    and report the gap between the core and the ring just outside the whole
    assembly. GOES RED ON EMPTY - a core of zero pixels is not a pass."""
    a = G.read_png(path)
    y0, y1, x0, x1 = bbox
    sub = a[y0:y1, x0:x1]
    op = sub[..., 3] > 0.5
    if int(op.sum()) < 40:
        return {"EMPTY": True, "px": int(op.sum())}
    li = lum(sub)
    rgb = sub[..., :3]
    sat = rgb.max(axis=-1) - rgb.min(axis=-1)
    warm = (rgb[..., 0] - rgb[..., 2])
    core = op & (sat > 0.10) & (warm > 0.06)
    if int(core.sum()) < 20:
        return {"EMPTY_CORE": True, "core_px": int(core.sum()),
                "px": int(op.sum())}
    ring = grow(core, 3) & op & (~grow(core, 1))
    if int(ring.sum()) < 20:
        return {"EMPTY_RING": True, "ring_px": int(ring.sum())}
    cv, rv = li[core], li[ring]
    return {"label": label,
            "core_px": int(core.sum()), "ring_px": int(ring.sum()),
            "core_lum_mean": round(float(cv.mean()), 4),
            "ring_lum_mean": round(float(rv.mean()), 4),
            "gap": round(float(abs(cv.mean() - rv.mean())), 4),
            "ring_lum_max": round(float(rv.max()), 4),
            "worst_local_gap": round(float(abs(cv.mean() - rv.max())), 4)}


def main():
    repo = sys.argv[sys.argv.index("--") + 1]
    out = os.path.join(repo, "renders", "art", "minibosses", "_ab_beadle")
    pb = os.path.join(out, "base_side.png")
    pk = os.path.join(out, "knob_side.png")
    A, B = G.read_png(pb), G.read_png(pk)
    d = np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1)
    da = np.abs(A[..., 3] - B[..., 3])
    m = np.maximum(d, da) > 0.02
    assert m.sum() > 0, "RED: nothing moved - the knob change is invisible"
    ys, xs = np.nonzero(m)
    pad = 10
    bbox = (max(0, ys.min() - pad), min(A.shape[0], ys.max() + pad + 1),
            max(0, xs.min() - pad), min(A.shape[1], xs.max() + pad + 1))
    rep = {"moved_px": int(m.sum()),
           "bbox_yxyx": [int(v) for v in bbox],
           "bbox_frac": [round(bbox[0] / A.shape[0], 3), round(bbox[1] / A.shape[0], 3),
                         round(bbox[2] / A.shape[1], 3), round(bbox[3] / A.shape[1], 3)],
           "base": report(pb, bbox, "base"),
           "knob": report(pk, bbox, "knob")}
    # the same question on the FRONT view, where the knob already read well -
    # a fix that breaks the view that was working is not a fix.
    fb = os.path.join(out, "base_front.png")
    fk = os.path.join(out, "knob_front.png")
    Af, Bf = G.read_png(fb), G.read_png(fk)
    df = np.maximum(np.max(np.abs(Af[..., :3] - Bf[..., :3]), axis=-1),
                    np.abs(Af[..., 3] - Bf[..., 3])) > 0.02
    if df.sum() > 0:
        fy, fx = np.nonzero(df)
        fbx = (max(0, fy.min() - pad), min(Af.shape[0], fy.max() + pad + 1),
               max(0, fx.min() - pad), min(Af.shape[1], fx.max() + pad + 1))
        rep["front_base"] = report(fb, fbx, "front_base")
        rep["front_knob"] = report(fk, fbx, "front_knob")
        rep["front_moved_px"] = int(df.sum())
    print("GAP_JSON_BEGIN")
    print(json.dumps(rep))
    print("GAP_JSON_END")
    with open(os.path.join(out, "_knobgap.json"), "w") as fh:
        json.dump(rep, fh, indent=1)


main()
