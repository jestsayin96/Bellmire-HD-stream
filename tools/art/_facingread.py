#!/usr/bin/env python3
"""_facingread.py - CAN A VIEWER TELL WHICH WAY THIS BODY IS FACING?

*** THIS IS A LINUX-BRIDGE TOOL. It needs PIL, which cruzader's Blender does
not have. Do not run it with `blender -P`. Same split as _streamscale.py. ***

    MB_KEY=collier MB_TAG=_p15 python3 -I tools/art/_facingread.py

WHY IT EXISTS. FAULT 7 is a standing class in this file and it has now shipped
twice. The Beadle shipped a pale band that WRAPPED the head, so the figure read
the same from the front and the back. The collier shipped a face whose every
piece - brow, sockets, mouth cloth - sat about 0.03 m INSIDE the head sphere,
so almost nothing rendered on the front at all. Both passed every number in
their fit registers, because a register asks `is this piece visible` and this
question is a different one:

    PUT THE FRONT BESIDE THE MIRRORED BACK. IF THEY LOOK THE SAME, THE BODY HAS
    NO FACING, AND NO AMOUNT OF DETAIL ON THE FRONT CHANGES THAT.

That is the viewer's question and it is why this compares two VIEWS of one arm,
where _streamscale.py compares two ARMS of one view. The two are not
substitutes and both are cheap.

WHAT IT REFUSES TO DO. There is no MIN_FACING_PX and there must not be one -
the 05:58 ruling of 25 Nov applies here exactly as it does to _streamscale.
ONLY ZERO IS A VERDICT ON ITS OWN: it says the head is literally
indistinguishable front from back at that size. A non-zero count IS NOT A PASS.

WHAT THIS INSTRUMENT CANNOT SEE, AND IT IS A LOT:
  - It cannot tell a FACE from a SMUDGE. A dark blob in the right place and a
    face score the same. Only an eye on the picture settles that.
  - A body with different marks on the front and the back scores well here
    while still leaving a viewer unsure which way it points.
  - It compares the head window only. A facing carried by a shoulder, a tool
    or a stance is invisible to it and is not thereby absent.
  - It renders nothing. It reads PNGs another pass wrote, so a stale arm
    attributes the finding to the wrong pass. Check the mtimes.
"""
import os, sys, json
from collections import deque
import numpy as np
from PIL import Image

W5   = os.environ.get("W5", os.path.expanduser("~/mnt/bellmire-art"))
KEY  = os.environ.get("MB_KEY", "collier")
TAG  = os.environ.get("MB_TAG", "")
ROOT = os.path.join(W5, "renders", "art", "minibosses")
THRESH = 8.0 / 255.0
RUNGS = [("full", 760), ("1080p", 480), ("720p", 320), ("480p", 213), ("360p", 160)]
HEAD_W, HEAD_H, HEAD_UP = 124, 124, 6
MIN_HEAD_PX = 200


def load(p):
    im = Image.open(p).convert("RGBA")
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    return Image.alpha_composite(bg, im).convert("RGB"), np.asarray(im)[:, :, 3] > 40


def marks(m):
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    out = []
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True; n = 0
                while q:
                    cy, cx = q.popleft(); n += 1
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                out.append(n)
    return sorted(out, reverse=True)


CAPE_RG, CAPE_MIN = 90.0, 200


def subject_half(rgb, fg):
    """Which half holds the miniboss. The KayKit hero wears a SATURATED RED
    cape; the minibosses are earth brown.

    *** THE FIRST VERSION OF THIS FUNCTION USED mean(R-G) AND IT WAS WRONG. ***
    It put the head window on the HERO in all four arms, and the only reason
    that did not become a shipped number is the `both views picked the same
    half` guard below, which fired and voided the comparison. Earth brown is
    warm EVERYWHERE (R-G around +33 over the whole body), so a mean over a
    mostly-grey knight came out LOWER than a mean over a brown clamp. The cape
    is not brighter on average, it is SATURATED - so count the pixels that are
    strongly red instead of averaging the ones that are faintly warm."""
    a = np.asarray(rgb).astype(np.float32)
    W = a.shape[1]
    out = {}
    for name, sl in (("left", slice(0, W // 2)), ("right", slice(W // 2, W))):
        m = fg[:, sl]
        if m.sum() < 50:
            out[name] = -1; continue
        out[name] = int((((a[:, sl, 0] - a[:, sl, 1]) > CAPE_RG) & m).sum())
    hero = max(out, key=out.get)
    other = "right" if hero == "left" else "left"
    if out[hero] < CAPE_MIN or out[hero] < 3 * max(1, out[other]):
        return None, out
    return other, out


def head_only(mask):
    """Rows of the window that are the HEAD, not the shoulders.

    *** THE FIRST VERSION OF THIS TOOL COMPARED THE WHOLE WINDOW AND THE
    NUMBER WAS MEANINGLESS. *** It reported 8170 differing pixels of 15376 on
    the CONTROL arm - 53% - because a head window also holds the shoulders,
    the shovel arm and the hat brim, and all of those differ front-to-back on
    any body with a tool in its hand. A metric that reads 53% before the fix
    and 55% after it cannot see a face. The head is the blob ABOVE THE NECK:
    scan down from the top, take the widest row of the skull, then the
    narrowest row below it, and stop there."""
    widths = mask.sum(axis=1)
    if widths.max() < 4:
        return None
    top = int(np.argmax(widths[:60])) if widths[:60].max() > 0 else 0
    lo = widths[top:top + 46]
    if lo.size < 4:
        return None
    neck = top + int(np.argmin(lo[2:])) + 2
    out = np.zeros_like(mask)
    out[:neck + 1] = mask[:neck + 1]
    return out


def head_window(rgb, fg, half):
    W = fg.shape[1]
    m = fg.copy()
    if half == "right":
        m[:, :W // 2] = False
    else:
        m[:, W // 2:] = False
    rows = np.where(m.sum(axis=1) >= 2)[0]
    if rows.size == 0:
        return None, 0, None
    ytop = int(rows.min())
    band = m[ytop:ytop + 40]
    cols = np.where(band.any(axis=0))[0]
    cx = int((cols.min() + cols.max()) / 2)
    x0, y0 = cx - HEAD_W // 2, ytop - HEAD_UP
    box = (max(0, x0), max(0, y0), max(0, x0) + HEAD_W, max(0, y0) + HEAD_H)
    sub = m[box[1]:box[3], box[0]:box[2]]
    npx = int(sub.sum())
    return rgb.crop(box), npx, sub


def main():
    rep = {"key": KEY, "tag": TAG, "thresh_255": 8,
           "question": "front vs MIRRORED back, head window only - if they "
                       "match, the body has no facing",
           "not_a_pass": "a non-zero count is NOT a pass; only ZERO is a "
                         "verdict on its own. No MIN_FACING_PX - 05:58 ruling.",
           "cannot_see": ["a face vs a smudge", "facing carried outside the "
                          "head window", "whether the arm is stale"],
           "rungs": {}, "errors": []}
    base = os.path.join(ROOT, KEY + TAG)
    paths = {v: os.path.join(base, "hero_%s.png" % v) for v in ("front", "back")}
    for v, p in paths.items():
        if not os.path.exists(p):
            rep["errors"].append("%s missing: %s" % (v, p))
    if rep["errors"]:
        rep["ok"] = False
        print(json.dumps(rep, indent=1)); return 1
    crops, halves, inks, masks = {}, {}, {}, {}
    for v, p in paths.items():
        rgb, fg = load(p)
        half, scores = subject_half(rgb, fg)
        halves[v] = half
        if half is None:
            rep["errors"].append("%s: could not locate the hero's cape "
                                 "(red-pixel counts %r) - RED, not a guess"
                                 % (v, scores))
            continue
        rep.setdefault("half_scores", {})[v] = {"subject": half,
                                                "cape_px": scores}
        crop, npx, sub = head_window(rgb, fg, half)
        if crop is None or npx < MIN_HEAD_PX:
            rep["errors"].append("%s: head window holds %d px (<%d) - RED ON "
                                 "EMPTY, nothing was compared" % (v, npx, MIN_HEAD_PX))
            continue
        hm = head_only(sub)
        if hm is None or hm.sum() < MIN_HEAD_PX:
            rep["errors"].append("%s: head-only mask holds %s px (<%d) - RED "
                                 "ON EMPTY" % (v, None if hm is None else int(hm.sum()),
                                               MIN_HEAD_PX))
            continue
        rep.setdefault("head_px", {})[v] = int(hm.sum())
        crops[v] = crop
        masks[v] = hm
        g = np.asarray(crop.convert("L")).astype(np.float32) / 255.
        med = float(np.median(g[hm]))
        inks[v] = round(float((g[hm] < med - 0.08).mean()), 4)
    rep["face_ink_frac"] = inks
    if halves.get("front") == halves.get("back"):
        rep["errors"].append("both views picked the same half (%s) - the "
                             "subject was not located, the comparison is void"
                             % halves.get("front"))
    if len(crops) == 2 and not rep["errors"]:
        a0 = crops["front"]
        b0 = crops["back"].transpose(Image.FLIP_LEFT_RIGHT)
        # ONLY WHERE BOTH VIEWS HOLD HEAD. Outside that intersection the two
        # pictures are not comparable and a difference there says nothing
        # about facing.
        ma = masks["front"]
        mb = masks["back"][:, ::-1]
        inter = ma & mb
        rep["compared_px_full"] = int(inter.sum())
        if inter.sum() < MIN_HEAD_PX:
            rep["errors"].append("head masks overlap in %d px (<%d) - RED ON "
                                 "EMPTY, nothing comparable"
                                 % (int(inter.sum()), MIN_HEAD_PX))
            rep["ok"] = False
            print(json.dumps(rep, indent=1)); return 1
        w0, h0 = a0.size
        mi = Image.fromarray((inter * 255).astype(np.uint8))
        for lab, Wr in RUNGS:
            sc = Wr / 760.0
            W, H = max(1, int(round(w0 * sc))), max(1, int(round(h0 * sc)))
            a = np.asarray(a0.resize((W, H), Image.BOX), np.float32) / 255.
            b = np.asarray(b0.resize((W, H), Image.BOX), np.float32) / 255.
            k = np.asarray(mi.resize((W, H), Image.BOX)) > 160
            if k.sum() == 0:
                rep["rungs"][lab] = {"px": 0, "differ_px": 0, "marks": 0,
                                     "sizes_px": [], "note": "head vanishes at "
                                     "this size - RED ON EMPTY for this rung"}
                continue
            mk = marks((np.abs(a - b).max(axis=2) > THRESH) & k)
            rep["rungs"][lab] = {"px": int(k.sum()), "differ_px": int(sum(mk)),
                                 "marks": len(mk), "sizes_px": mk[:8],
                                 "differ_frac": round(sum(mk) / float(k.sum()), 4)}
        if rep["rungs"]["full"]["differ_px"] == 0:
            rep["errors"].append("front and mirrored back are IDENTICAL at full "
                                 "size - this body has NO FACING")
    elif not rep["errors"]:
        rep["errors"].append("fewer than two crops - RED ON EMPTY")
    rep["ok"] = not rep["errors"]
    print(json.dumps(rep, indent=1))
    return 0 if rep["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
