"""_bandblame_sheet.py - LABEL THE BAND-BLAME SHEET SO IT READS STANDALONE.

  python3 tools/art/_bandblame_sheet.py --repo <repo> --key fuller --view side

The 03:58 lesson, kept: a contact sheet only its author can interpret is
evidence for nobody. Every tile carries the key, the view, the value, the
noise floor and - per band - the survival fraction and the span the pixels
were measured to. Nothing on the strip is typed by hand; it is read out of
the JSON the renderer wrote.

RED, NOT BLIND: a missing JSON or a missing raw PNG stops the sheet.
"""
import os, json, argparse
from PIL import Image, ImageDraw, ImageFont

BG=(23,26,31); INK=(228,230,234); DIM=(138,144,152)
GREEN=(89,217,115); RED=(242,89,51); AMBER=(232,186,74)

def font(sz, bold=False):
    n = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    for p in ("/usr/share/fonts/truetype/dejavu/"+n, "C:/Windows/Fonts/arial.ttf"):
        try: return ImageFont.truetype(p, sz)
        except Exception: pass
    return ImageFont.load_default()

def build(repo, key, view, out):
    base = os.path.join(repo, "renders", "art", "minibosses", "_backread")
    jp = os.path.join(base, "_bandblame_%s_%s.json" % (key, view))
    rp = os.path.join(base, "_bandblame_%s_%s_raw.png" % (key, view))
    for p in (jp, rp):
        if not os.path.exists(p):
            raise SystemExit("[bandblame_sheet] RED missing %s" % p)
    d = json.load(open(jp))
    im = Image.open(rp).convert("RGB"); W, H = im.size
    PAD, CAP = 250, 86
    sheet = Image.new("RGB", (W+PAD, H+CAP), BG); sheet.paste(im, (0, CAP))
    dr = ImageDraw.Draw(sheet); f, fb = font(15), font(18, True)
    dr.text((10,8), "%s / %s   man_seen %.4f   man_alone %d px   noise floor %d px"
            % (key, view, d["man_seen_all"], d["man_alone_px"], d["floor_px"]), fill=INK, font=fb)
    dr.text((10,32), "LEFT: the view as rendered.  RIGHT: the man-alone mask - GREEN he survives, "
            "RED he is hidden.  White lines are band edges (band 0 = crown).", fill=DIM, font=f)
    dr.text((10,54), "hidden %d px: %d charged to a span, %d charged to NO span "
            "(in plain sight, buried by value, %.3f%% of him)"
            % (d["hidden_px"], d["hidden_by_a_span_px"], d["hidden_by_no_span_px"],
               100*d["hidden_by_no_span_frac"]), fill=DIM, font=f)
    for b in d["band_rows"]:
        r0, r1 = b["rows"]; y = CAP + (r0+r1)//2; s = b["survival"]
        col = DIM if s is None else GREEN if s >= 0.75 else RED if s < 0.40 else AMBER
        txt = "b%d  %s" % (b["band"], "n/a" if s is None else "%.3f" % s)
        if b.get("culprit"): txt += "  <- %s" % b["culprit"]
        dr.line([(W+4,y),(W+18,y)], fill=col, width=2)
        dr.text((W+24, y-9), txt, fill=col, font=f)
        dr.text((8, CAP+r0+2), str(r0), fill=(90,96,104), font=f)
    sheet.save(out); print("[bandblame_sheet] wrote %s" % out)

ap = argparse.ArgumentParser()
ap.add_argument("--repo", required=True); ap.add_argument("--key", default="fuller")
ap.add_argument("--view", default="side"); ap.add_argument("--out", default="")
a = ap.parse_args()
o = a.out or os.path.join(a.repo, "renders", "art", "minibosses", "_backread",
                          "_bandblame_%s_%s_sheet.png" % (a.key, a.view))
build(a.repo, a.key, a.view, o)
