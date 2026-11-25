#!/usr/bin/env python3
"""_streamscale.py - DOES THE CUE SURVIVE THE SIZE IT IS ACTUALLY SHOWN AT,
AND HOW MANY SEPARATE MARKS SURVIVE WITH IT?

*** THIS IS THE ONE TOOL IN tools/art/ THAT DOES NOT RUN IN BLENDER. ***
It needs PIL, which cruzader's Blender does not have and which there is no
system Python to supply. It was written and run on the LINUX BRIDGE against
the mounted worktree. Do not try `blender -P` on it; it will ImportError. It
consumes PNGs that Blender already wrote, so the split is harmless, but it is
stated here so nobody loses a window finding out.

    python3 -I tools/art/_streamscale.py        # paths below, edit KEY

WHY IT EXISTS. Every number on a miniboss is taken on a 760x520 render. A
viewer never sees that. `scripts/spotlight.gd:22` - "Each pane is a SubViewport
at HALF resolution"; `:11` - "the 2x2 grid is the stream's RESTING state". So a
pane owns half the stream width on screen and is RENDERED into a quarter of it,
and across Twitch's tiers the 760 px frame lands at 480 / 320 / 213 / 160.

WHAT IT MEASURES, AND WHAT IT REFUSES TO. It area-averages both arms of an
existing A/B down to each rung - which is what a video scaler does - and counts
the pixels that MOVED at the house threshold of 8/255, then LABELS the
connected marks and prints their sizes and centroids.

*** THERE IS NO THRESHOLD HERE AND THERE MUST NOT BE ONE. *** The 05:58 ruling
of 25 Nov stands: no lane invents a MIN_CUE_PX. The only reading that means
anything on its own is ZERO, which says the cue has stopped existing at that
size. A non-zero count IS NOT A PASS. The output is for putting beside a
picture you actually looked at, and when the number and the picture disagree,
the picture is the evidence and the number is the suspect (pass 11, 17 Nov).

WHY THE LABELLING HALF IS THE POINT. On the collier, 25 Nov, a whole-body
picture at 760 px read FOUR vents to the register, to the team lead and to this
lane. The labelled marks were 38 / 460 / 449 / 152 px: three vents and a
sliver. A total pixel count cannot tell one fat blob from four specks, and a
body whose count IS its mechanic needs the count asked for directly.

FEED IT THE RIGHT ARM. `_cueC` turns off glow AND bone, so its biggest mark is
usually the pale geometry, not the emissive - on the collier that was a 2785 px
blob of plugs sitting where a vent was being looked for. Use `_cueB`
(MB_CUEOFF=glow) to count LIT marks, and re-render it if it is older than the
body: a stale arm attributes the cue to the wrong pass.
"""
import os, sys, json
from collections import deque
import numpy as np
from PIL import Image

W5    = os.environ.get("W5", os.path.expanduser("~/mnt/bellmire-art"))
KEY   = os.environ.get("MB_KEY", "collier")
ATAG  = os.environ.get("MB_ATAG", "_cueA")
BTAG  = os.environ.get("MB_BTAG", "_cueB")
VIEWS = ("hero_front.png", "hero_side.png", "hero_back.png")
THRESH = 8.0 / 255.0
RUNGS = [("full", 760), ("1080p", 480), ("720p", 320), ("480p", 213), ("360p", 160)]
ROOT  = os.path.join(W5, "renders", "art", "minibosses")


def load(p):
    im = Image.open(p).convert("RGBA")
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    return Image.alpha_composite(bg, im).convert("RGB")


def marks(m):
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    out = []
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True; px = []
                while q:
                    cy, cx = q.popleft(); px.append((cy, cx))
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                out.append(px)
    return sorted(out, key=len, reverse=True)


def main():
    rep = {"key": KEY, "arms": [ATAG, BTAG], "thresh_255": 8,
           "rungs_from": "spotlight.gd:22 half-res panes, :11 2x2 resting grid",
           "not_a_pass": "a non-zero count is NOT a pass; only ZERO is a "
                         "verdict on its own. No MIN_CUE_PX - 05:58 ruling, 25 Nov.",
           "views": {}, "errors": []}
    for v in VIEWS:
        pa = os.path.join(ROOT, KEY + ATAG, v)
        pb = os.path.join(ROOT, KEY + BTAG, v)
        if not (os.path.exists(pa) and os.path.exists(pb)):
            rep["errors"].append("%s: A/B pair missing" % v); continue
        a0, b0 = load(pa), load(pb)
        if a0.size != b0.size:
            rep["errors"].append("%s: shape mismatch" % v); continue
        w0, h0 = a0.size
        rows = {}
        for lab, W in RUNGS:
            H = int(round(h0 * W / w0))
            a = np.asarray(a0.resize((W, H), Image.BOX), np.float32) / 255.
            b = np.asarray(b0.resize((W, H), Image.BOX), np.float32) / 255.
            mk = marks(np.abs(a - b).max(axis=2) > THRESH)
            rows[lab] = {
                "moved_px": int(sum(len(p) for p in mk)),
                "marks": len(mk),
                "sizes_px": [len(p) for p in mk[:12]],
                "centroids": [[round(sum(q[1] for q in p)/len(p), 1),
                               round(sum(q[0] for q in p)/len(p), 1)] for p in mk[:12]],
            }
        rep["views"][v] = rows
    # RED ON EMPTY, the same arm _cueread.py carries: a run that compared
    # nothing, or a body that moves no pixel anywhere, is RED and never skipped.
    got = rep["views"]
    if not got:
        rep["errors"].append("no pairs compared - a run over zero pairs is RED")
    elif all(r["full"]["moved_px"] == 0 for r in got.values()):
        rep["errors"].append("cue moves zero pixels on every view at full size "
                             "- no cue, or the A/B did not take")
    rep["ok"] = not rep["errors"]
    out = os.path.join(ROOT, KEY + "_stream", "_streamscale.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(rep, open(out, "w"), indent=1)
    print(json.dumps(rep, indent=1))
    sys.exit(0 if rep["ok"] else 1)


main()
