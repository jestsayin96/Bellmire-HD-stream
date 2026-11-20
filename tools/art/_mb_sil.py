"""SILHOUETTE STRIP FOR ANY MINIBOSS KEY - colour thrown away, three cells.

_beadle_sil.py is hardcoded to one key. This is the same test taking the key as
an argument, so a new body can be judged with colour thrown away on the run that
builds it instead of after it ships.

WHAT THIS CAN SEE: the OUTLINE. Whether the shape reads as itself with every
colour decision removed, and whether anything touches the frame edge.
WHAT THIS CANNOT SEE, and it is the reason the Beadle's facing fault survived a
clean register: anything INSIDE the outline. Two parts that overlap read as one
blob here whether they are told apart by colour or not, and a part that sits
inside the body's own alpha contributes nothing to this picture at all. A pass
on this sheet is a statement about the SHAPE and about nothing else.

usage: blender -b -P _mb_sil.py -- <repo> <key>
"""
import os
import sys

import numpy as np
import bpy  # noqa: F401

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
repo, key = argv[0], argv[1]
d = os.path.join(repo, "renders", "art", "minibosses", key)
cells, names = [], []
for fn in ("front.png", "three_quarter.png", "side.png"):
    p = os.path.join(d, fn)
    if not os.path.isfile(p):
        raise SystemExit("MISSING RENDER %s - a silhouette of nothing is not a pass" % p)
    cells.append(G.read_png(p))
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
    edge = max(float(c[0, :, 3].max()), float(c[-1, :, 3].max()),
               float(c[:, 0, 3].max()), float(c[:, -1, 3].max()))
    # RED ON EMPTY. A silhouette with no pixels in it is not a clean sheet, it
    # is a blank render, and a sheet that reports 0 and calls itself a pass is
    # the lying-instrument class this lane has shipped before.
    if int(a.sum()) == 0:
        raise SystemExit("RED %s: silhouette is EMPTY - nothing was rendered" % nm)
    rep.append((nm, int(a.sum()), round(edge, 4)))
    x += c.shape[1] + 24
G.write_png(os.path.join(d, "_%s_silhouette.png" % key), out)
clipped = [r for r in rep if r[2] > 0.01]
print("SIL", key, rep)
print("EDGE_CLIP", clipped if clipped else "none")
