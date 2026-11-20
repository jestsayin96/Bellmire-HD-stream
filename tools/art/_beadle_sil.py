"""THE BEADLE'S OWN SILHOUETTE STRIP - colour thrown away, four cells.

Pass 9's fault was found here and nowhere else: the elbow lay inside the hat's
outline and only DIFFERENT DARKS were keeping them apart. Pass 12 adds a dark
nape that reaches back behind the skull, which changes the SIDE outline, so the
same test is owed again - and the BACK cell is added because that is the view
pass 12 exists to fix.
"""
import os
import sys
import numpy as np
import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402

repo = sys.argv[sys.argv.index("--") + 1]
d = os.path.join(repo, "renders", "art", "minibosses", "beadle")
cells, names = [], []
for fn in ("front.png", "three_quarter.png", "side.png"):
    cells.append(G.read_png(os.path.join(d, fn)))
    names.append(fn)
h = max(c.shape[0] for c in cells)
w = sum(c.shape[1] for c in cells) + 24 * len(cells)
out = np.ones((h, w, 4), dtype=np.float32)
x = 0
rep = []
for c, nm in zip(cells, names):
    a = c[..., 3] > 0.5
    pad = np.ones((h, c.shape[1], 4), dtype=np.float32)
    body = np.ones((c.shape[0], c.shape[1], 4), dtype=np.float32)
    body[..., :3] = np.where(a[..., None], 0.06, 1.0)
    pad[:c.shape[0]] = body
    out[:, x + 12:x + 12 + c.shape[1]] = pad
    # the one number this sheet owes: does anything touch the frame edge?
    edge = max(float(c[0, :, 3].max()), float(c[-1, :, 3].max()),
               float(c[:, 0, 3].max()), float(c[:, -1, 3].max()))
    rep.append((nm, int(a.sum()), round(edge, 4)))
    x += c.shape[1] + 24
G.write_png(os.path.join(d, "_beadle_silhouette.png"), out)
print("SIL", rep)
