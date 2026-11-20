import os, sys, glob, json
import numpy as np, bpy
sys.path.append(os.path.join(sys.argv[sys.argv.index("--")+1], "tools", "art"))
import lordgen as G
d = os.path.join(sys.argv[sys.argv.index("--")+1], "renders", "art", "minibosses", "_gaoler_ab")
blank, clip, rows = [], [], 0
for f in sorted(glob.glob(os.path.join(d, "*.png"))):
    a = G.read_png(f)
    al = a[..., 3]
    rows += 1
    if (al > 0.02).sum() < 500:
        blank.append(os.path.basename(f))
    b = max(al[0, :].max(), al[-1, :].max(), al[:, 0].max(), al[:, -1].max())
    if b > 0.02:
        clip.append([os.path.basename(f), round(float(b), 3)])
print("BLANKCHECK " + json.dumps({"n": rows, "blanks": blank, "border_touch": clip}))
