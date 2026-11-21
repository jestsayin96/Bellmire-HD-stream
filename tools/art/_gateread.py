"""_gateread - DOES THE PALE BOARD READ AS A BARRED GATE?

  blender -b -noaudio -P tools/art/_gateread.py -- --repo <repo> [--sweep 1.00,0.50,0.00]
  blender -b -noaudio -P tools/art/_gateread.py -- --repo <repo> --measure <png>

THE QUESTION THIS ASKS, AND WHY IT IS NOT THE ONE THE EXISTING INSTRUMENTS ASK.
`_bandblame` asks WHICH PART survives in a band and `minibossgen` asks whether
the frame is blank or clipped. Neither can see the fault the Paviser's own
docstring bans in writing: pass 3 deleted the centre rib because the front view
had "two identical dark verticals and the board sat in a frame between them - a
GATE". Five dark verticals are on that face today (two seams, three splits) and
every number on the body is green.

So this measures the viewer's question: LONG DARK LINES LAID ACROSS A PALE
FIELD. Not "is there a dark pixel" - a bolt stub is a dark pixel and it is the
receipt the body is supposed to carry. A BAR is a dark run that crosses most of
the board's height, enclosed by pale above and below, which is exactly what a
grille looks like and exactly what a hit does not.

  board      the largest connected PALE component in the frame. The prop leg is
             pale too and is a separate, smaller component, so it drops out on
             its own rather than by a hand-typed exclusion.
  filled     per column, the span between the board's topmost and bottommost
             pale pixel. Holes punched by the dark marks are inside it, which
             is the point: the marks are measured against the board they are
             lying on, not against the pixels they left behind.
  mark       a dark, opaque run INSIDE that span with pale both above and
             below it in the same column. The man stands at the board's right
             edge and is not enclosed by it, so he cannot be charged here.
  bar        a mark run >= BAR_FRAC of that column's filled span.

RED ON EMPTY. A metric computed over zero board columns reads 0.0000 and means
nothing, so fewer than 20 board columns is an ERROR, not a pass. This lane
shipped `head_glow_px: 156` next to the sentence "the head has no face at all"
on 17 Nov because a number answered a question nobody had asked; the only
defence is to say in the file what the number cannot see.

WHAT THIS CANNOT SEE, said plainly: it cannot see a bar that is PALE on pale,
it cannot see a dark mark that reaches the board's outline (not enclosed, so
not counted - the two iron straps end 0.10 inboard on purpose and ARE counted,
but a strap run round onto the end would not be), and it says nothing at all
about the hinge post, the prop, the legs or the floor. It answers one question.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

PALE_L = 0.45          # luminance above this is board/prop
MARK_L = 0.30          # luminance below this is iron / a slot / a stub
BAR_FRAC = 0.50        # a run this tall, relative to the column, is a bar
MIN_COLS = 20          # fewer board columns than this and the read is VOID


def _largest_pale_component(pale):
    """flood fill, 4-connected, no scipy on this machine."""
    h, w = pale.shape
    lab = np.zeros((h, w), dtype=np.int32)
    best, best_n, nxt = 0, 0, 0
    ys, xs = np.nonzero(pale)
    for y0, x0 in zip(ys.tolist(), xs.tolist()):
        if lab[y0, x0]:
            continue
        nxt += 1
        stack = [(y0, x0)]
        lab[y0, x0] = nxt
        n = 0
        while stack:
            y, x = stack.pop()
            n += 1
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and pale[yy, xx] and not lab[yy, xx]:
                    lab[yy, xx] = nxt
                    stack.append((yy, xx))
        if n > best_n:
            best_n, best = n, nxt
    return (lab == best) if best else np.zeros_like(pale), best_n


def gate_read(path):
    a = G.read_png(path)
    h, w, _ = a.shape
    op = a[..., 3] > 0.5
    lum = a[..., 0:3].mean(axis=2)
    pale = op & (lum > PALE_L)
    comp, n_pale = _largest_pale_component(pale)
    out = {"png": os.path.basename(path), "res": [int(w), int(h)],
           "pale_px": int(n_pale), "errors": []}
    cols = np.nonzero(comp.any(axis=0))[0]
    if cols.size < MIN_COLS:
        out["errors"].append("VOID: only %d board columns, the read means nothing"
                             % int(cols.size))
        out["ok"] = False
        return out
    dark = op & (lum < MARK_L)
    ratios, runs_px = [], []
    for x in cols.tolist():
        ys = np.nonzero(comp[:, x])[0]
        y0, y1 = int(ys[0]), int(ys[-1])
        span = y1 - y0 + 1
        if span < 8:
            continue
        colm = dark[y0:y1 + 1, x]
        colp = comp[y0:y1 + 1, x]
        best = 0
        i = 0
        while i < span:
            if colm[i]:
                j = i
                while j < span and colm[j]:
                    j += 1
                # ENCLOSED: pale above and pale below, in this same column
                up = colp[:i].any()
                dn = colp[j:].any()
                if up and dn:
                    best = max(best, j - i)
                i = j
            else:
                i += 1
        ratios.append(best / float(span))
        runs_px.append(best)
    if not ratios:
        out["errors"].append("VOID: no usable board column had a span")
        out["ok"] = False
        return out
    r = np.array(ratios, dtype=np.float64)
    bar = r >= BAR_FRAC
    out.update(
        board_cols=int(r.size),
        bar_cols=int(bar.sum()),
        bar_share=round(float(bar.mean()), 4),
        max_run_frac=round(float(r.max()), 4),
        mean_run_frac=round(float(r.mean()), 4),
        p90_run_frac=round(float(np.percentile(r, 90)), 4),
        ok=True)
    return out


def render_front(objs, info, outdir, resx=700, resy=980):
    os.makedirs(outdir, exist_ok=True)
    written, eng, cam = G.render_views(objs, "paviser", outdir, resx, resy, info)
    return written


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--sweep", default="")
    ap.add_argument("--var", default="PAVISER_SEAMH",
                    help="env var the sweep drives; one variable per run")
    ap.add_argument("--measure", default="")
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)

    res = {"bar_frac": BAR_FRAC, "pale_l": PALE_L, "mark_l": MARK_L, "rows": []}
    if args.measure:
        res["rows"].append(dict(label="measured", **gate_read(args.measure)))
    tag = args.var.replace("PAVISER_", "").lower()
    for sv in [s for s in args.sweep.split(",") if s]:
        # ONE VARIABLE PER RUN. Every other hook is cleared to its shipped
        # default first, so a sweep can never silently ride on a leftover.
        for k in ("PAVISER_SEAMH", "PAVISER_SPLITH", "PAVISER_SPLITC"):
            os.environ.pop(k, None)
        os.environ[args.var] = sv
        G.purge()
        objs, info = MG.build_miniboss("paviser")
        outdir = os.path.join(args.repo, "renders", "art", "_sweep",
                              "paviser_%s%s" % (tag, sv))
        render_front(objs, info, outdir)
        row = gate_read(os.path.join(outdir, "front.png"))
        row["label"] = "%s=%s" % (args.var.replace("PAVISER_", ""), sv)
        row["dir"] = outdir
        res["rows"].append(row)
    out = args.out or os.path.join(args.repo, "renders", "art", "_sweep",
                                   "_gateread.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(res, f, indent=1)
    for r in res["rows"]:
        print("GATEREAD %-14s cols=%-4s bars=%-4s share=%-7s max=%-7s p90=%-7s %s"
              % (r.get("label"), r.get("board_cols"), r.get("bar_cols"),
                 r.get("bar_share"), r.get("max_run_frac"),
                 r.get("p90_run_frac"), ";".join(r.get("errors", [])) or "-"))
    print("GATEREAD WROTE %s" % out)


main()
