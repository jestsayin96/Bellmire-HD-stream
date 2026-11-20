"""Blank-and-border over ALL SIX shipped Hooper PNGs, as its own arm.

minibossgen's own gate walks M.ORDER x G.VIEWS, which is front/three_quarter/
side only - the THREE HERO VIEWS minibossfit writes are not in it, and on the
Sealer run it reported files: 0 on the non-sheet path. A gate that does not
cover the files that ship is not covering them, so this arm names all six
explicitly and asserts a count, going RED if it checked fewer than six.
Border alpha is asserted on all four edges: a CLIPPED icon is not a BLANK one
and the opaque-pixel count cannot see the difference (System 1, 17 Nov).
"""
import os, sys, json
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
R = sys.argv[sys.argv.index("--") + 1]
d = os.path.join(R, "renders", "art", "minibosses", "hooper")
NAMES = ["front", "side", "three_quarter", "hero_front", "hero_side", "hero_back"]
rep = {"checked": [], "failures": [], "ok": True}
for n in NAMES:
    p = os.path.join(d, n + ".png")
    if not os.path.isfile(p):
        rep["failures"].append([n, "missing"]); rep["ok"] = False; continue
    a = G.read_png(p)
    op = int((a[..., 3] > 0.02).sum())
    edge = int(((a[0:2, :, 3] > 0.02).sum() + (a[-2:, :, 3] > 0.02).sum()
                + (a[:, 0:2, 3] > 0.02).sum() + (a[:, -2:, 3] > 0.02).sum()))
    rep["checked"].append({"view": n, "opaque_px": op, "border_px": edge,
                           "wh": [a.shape[1], a.shape[0]]})
    if op < 400:
        rep["failures"].append([n, "blank: %d opaque px" % op]); rep["ok"] = False
    if edge:
        rep["failures"].append([n, "frame clip: %d border px" % edge]); rep["ok"] = False
if len(rep["checked"]) != 6:
    rep["ok"] = False
    rep["failures"].append(["ARM", "RED ON EMPTY: checked %d of 6" % len(rep["checked"])])
with open(os.path.join(R, "renders", "art", "minibosses", "_hooper_blank.json"), "w") as f:
    json.dump(rep, f, indent=1)
print("HOOPER_BLANK " + json.dumps(rep))
