"""_selfseen_sheet.py - THE LABELLED SELF-SEEN CONTACT SHEET.

  python3 tools/art/_selfseen_sheet.py --repo <repo> [--worst 8] [--bar 0.75]

WHY THIS FILE EXISTS AT ALL. The 03:58 sheet was built inline and thrown away,
and it carried NO PER-TILE LABELS. The team lead could read the pictures but
could not bind a single tile to a row of the register, and could not say which
cell was the second green bar. A contact sheet that only the lane that built it
can interpret is evidence for nobody. So:

  - EVERY TILE CARRIES ITS KEY, ITS VIEW, ITS VALUE AND ITS RANK, drawn on the
    tile, so the sheet reads standalone.
  - THE BAR COLOUR IS COMPUTED FROM THE BAR, NOT FROM THE WRITE-UP. red under
    `--bar`, green at or over it, no exceptions and no excused cells. The 03:58
    sheet drew boiler/side (0.7057) GREEN while the bar was 0.75, which is the
    one thing a reader cannot check without the labels.
  - THE BAR TRACK SHOWS WHERE THE BAR IS. A tick at `--bar` on every tile, so
    the colour can be checked against the geometry by eye.
  - THE SELECTION IS PRINTED, not described: `--worst N` takes the N worst
    cells by value, strictly, and the top-end reference tile is the single best
    cell. Both are named in the caption strip.

IT GOES RED, NOT BLIND:
  - a selected cell whose render PNG is missing  -> RED, named, no sheet
  - fewer cells in the register than requested   -> RED
  - a tile drawn with no bar (value absent)      -> RED
"""
import os
import json
import argparse

from PIL import Image, ImageDraw, ImageFont

BG = (23, 26, 31)
RED = (242, 89, 51)
GREEN = (89, 217, 115)
INK = (228, 230, 234)
DIM = (138, 144, 152)
TRACK = (52, 57, 65)


def _font(sz):
    try:
        return ImageFont.load_default(size=sz)
    except TypeError:                       # Pillow < 10.1
        return ImageFont.load_default()


def collect(reg, bar):
    cells = []
    for key, row in reg["rows"].items():
        for view, cell in (row.get("views") or {}).items():
            if "man_seen" not in cell:
                continue
            cells.append({"key": key, "view": view,
                          "value": float(cell["man_seen"])})
    cells.sort(key=lambda c: c["value"])
    for i, c in enumerate(cells):
        c["rank"] = i + 1
        c["under"] = c["value"] < bar
    return cells


def build(repo, worst, bar, out, skip=0):
    outdir = os.path.join(repo, "renders", "art", "minibosses", "_backread")
    with open(os.path.join(outdir, "_selfseen_all.json")) as fh:
        reg = json.load(fh)
    cells = collect(reg, bar)
    errors = []
    # *** --skip PAGES THROUGH THE RANKING. ADDED 24 Nov 11:4x CT. ***
    # The 21 Nov sheet could only ever show the WORST 8, so ranks 9+ had never
    # been looked at by anyone - and the under-bar list is now 21 cells long,
    # which means thirteen of the register's own named faults had no picture
    # behind them. A named cell nobody has seen is a number, not evidence.
    if skip < 0 or worst < 1:
        errors.append("skip %d / worst %d: nonsense window" % (skip, worst))
        return errors, None
    if len(cells) < skip + worst + 1:
        errors.append("register holds %d cells, need %d (skip %d + worst %d "
                      "+ 1 top-end tile)"
                      % (len(cells), skip + worst + 1, skip, worst))
        return errors, None
    pick = cells[skip:skip + worst] + [cells[-1]]
    for c in pick:
        c["png"] = os.path.join(outdir, "%s_ss_%s.png" % (c["key"], c["view"]))
        if not os.path.exists(c["png"]):
            errors.append("missing render %s" % os.path.basename(c["png"]))
        if not (0.0 <= c["value"] <= 1.0):
            errors.append("%s/%s value %r out of range"
                          % (c["key"], c["view"], c["value"]))
    if errors:
        return errors, None

    # LAYOUT, AND THE FIRST CUT OF THIS SHEET GOT IT WRONG TWICE - BOTH FOUND
    # BY LOOKING AT THE PICTURE, NOT BY A NUMBER. (a) the bar was drawn across
    # the TOP of its own tile, which put it directly under the PREVIOUS row's
    # caption, so a reader binds it to the wrong cell - the exact ambiguity
    # this sheet exists to remove. (b) the last row's second caption line fell
    # off the bottom edge and was clipped. So the bar and both caption lines
    # now sit together in a footer BELOW their own picture, there is a gutter
    # between rows, and the height is asserted against the real text extents.
    n = len(pick)
    cols = 3
    rows = (n + cols - 1) // cols
    T, PAD, BARH, GAP, HEAD = 380, 4, 12, 18, 50
    L1, L2 = 21, 19                       # caption line heights
    FOOT = BARH + 3 + L1 + L2 + 4
    W = cols * T
    H = HEAD + rows * (T + FOOT + GAP)
    sheet = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(sheet)
    f_hd, f_lb, f_sm = _font(20), _font(19), _font(15)

    n_under = sum(1 for c in cells if c["under"])
    head_lines = [
        "SELF-SEEN - cells ranked %d-%d of %d (worst first), plus the best "
        "cell as the top end.  bar %.2f: %d under it, across %d bodies."
        % (skip + 1, skip + worst, len(cells), bar, n_under, len(reg["rows"])),
        "Each tile: bar width IS the value, the white tick IS the bar, red is "
        "under it.  No cell is excused.",
    ]
    for li, line in enumerate(head_lines):
        dr.text((PAD + 6, 6 + li * 19), line, font=f_sm, fill=INK)
        hb = dr.textbbox((PAD + 6, 6 + li * 19), line, font=f_sm)
        if hb[2] > W - 2:
            errors.append("header line %d runs off the sheet: x=%d of %d"
                          % (li, hb[2], W))
    if errors:
        return errors, None

    deepest = 0
    for i, c in enumerate(pick):
        ci, cj = i // cols, i % cols
        ox = cj * T
        oy = HEAD + ci * (T + FOOT + GAP)
        im = Image.open(c["png"]).convert("RGBA").resize(
            (T - 2 * PAD, T - 2 * PAD), Image.LANCZOS)
        plate = Image.new("RGB", im.size, BG)
        plate.paste(im, (0, 0), im)
        sheet.paste(plate, (ox + PAD, oy))
        fy = oy + (T - 2 * PAD) + 3
        track_w = T - 2 * PAD
        col = RED if c["under"] else GREEN
        dr.rectangle([ox + PAD, fy, ox + PAD + track_w - 1, fy + BARH - 1],
                     fill=TRACK)
        bw = int(round(c["value"] * track_w))
        dr.rectangle([ox + PAD, fy, ox + PAD + max(1, bw) - 1, fy + BARH - 1],
                     fill=col)
        tx = ox + PAD + int(round(bar * track_w))
        dr.line([(tx, fy - 3), (tx, fy + BARH + 2)], fill=INK, width=2)
        last = (c is pick[-1])
        tag = "TOP END" if last else "#%d of %d" % (c["rank"], len(cells))
        y1 = fy + BARH + 3
        dr.text((ox + PAD + 2, y1),
                "%s  %s   %.4f" % (c["key"], c["view"], c["value"]),
                font=f_lb, fill=INK)
        y2 = y1 + L1
        dr.text((ox + PAD + 2, y2),
                "%s   %s bar %.2f" % (tag, "UNDER" if c["under"] else "over", bar),
                font=f_sm, fill=col if c["under"] else DIM)
        bb = dr.textbbox((ox + PAD + 2, y2), "%s   %s bar %.2f"
                         % (tag, "UNDER" if c["under"] else "over", bar),
                         font=f_sm)
        deepest = max(deepest, bb[3])

    # ASSERT THE SHEET IS NOT CLIPPING ITS OWN EVIDENCE. The first cut of this
    # file lost the bottom caption line off the canvas, which is the border
    # trap in a new coat: a clipped label is not a blank one.
    if deepest > H - 1:
        errors.append("caption clipped: ink reaches y=%d on a %d-tall sheet"
                      % (deepest, H))
        return errors, None

    sheet.save(out)
    return errors, {"out": out, "tiles": n, "cells": len(cells),
                    "under": n_under, "bar": bar, "skip": skip,
                    "picked": [(c["key"], c["view"], c["value"], c["rank"])
                               for c in pick]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--worst", type=int, default=8)
    ap.add_argument("--skip", type=int, default=0,
                    help="drop the N worst cells first, to page down the "
                         "ranking - the top-end tile is always appended")
    ap.add_argument("--bar", type=float, default=0.75)
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    out = a.out or os.path.join(a.repo, "renders", "art", "minibosses",
                                "_backread", "_selfseen_worst_sheet.png")
    errors, rep = build(a.repo, a.worst, a.bar, out, skip=a.skip)
    if errors:
        print("[sheet] RED:")
        for e in errors:
            print("   -", e)
        raise SystemExit(1)
    print("[sheet] %s" % json.dumps(rep, indent=1))


main()
