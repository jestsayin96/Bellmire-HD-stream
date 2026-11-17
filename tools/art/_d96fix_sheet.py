
import os, sys, json
import numpy as np
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__))))
import lordgen as G
REPO = sys.argv[sys.argv.index("--")+1]
root = os.path.join(REPO, "renders", "art", "minibosses")
keys = ["snuffer_chibi","gaoler_chibi","porter_chibi","sexton_chibi","stoker_chibi"]
views = ["hero_front.png","hero_side.png","hero_back.png"]
lab = 34
rep = {}
cells = {}
for k in keys:
    for v in views:
        p = os.path.join(root, k, v)
        cells[(k,v)] = G.read_png(p) if os.path.isfile(p) else None
h, w = 520, 760
S = 2
oh, ow = h//S, w//S
sh = np.zeros((len(keys)*(oh+lab), 3*ow, 4), dtype=np.float32)
sh[...,0:3] = np.array((0.055,0.060,0.075)); sh[...,3] = 1.0
blank = []
for r,k in enumerate(keys):
    reg = k.replace("_chibi","_register")
    try:
        d = json.load(open(os.path.join(root, "_fit_%s.json" % reg)))
        e = d["pairs"][k]; tag = "%s  ratio %.2f x hero  pair %.2f m  %s" % (k.upper(), e["ratio"], e["pair_w"], d.get("verdict","?"))
    except Exception as ex:
        tag = k.upper() + "  (no register entry)"
    for c,v in enumerate(views):
        a = cells[(k,v)]
        y0, x0 = r*(oh+lab), c*ow
        if a is None:
            blank.append((k,v,"missing")); continue
        n = int((a[...,3] > 0.02).sum())
        if n < 400:
            blank.append((k,v,"blank %d px" % n))
        b = a[::S,::S,:]
        al = b[...,3:4]
        dst = sh[y0:y0+oh, x0:x0+ow, 0:3]
        sh[y0:y0+oh, x0:x0+ow, 0:3] = b[...,0:3]*al + dst*(1.0-al)
        G.draw_text(sh, v.replace("hero_","").replace(".png","").upper(), x0+6, y0+6, 1, (0.46,0.52,0.60))
    sh[y0+oh:y0+oh+2, :, 0:3] = np.array((0.85,0.80,0.68))*0.35
    G.draw_text(sh, tag, 8, y0+oh+9, 2, (1.00,0.86,0.52))
    G.draw_text(sh, "HERO = KayKit Knight.glb, Idle, scale 1.0, 2.45 m. ONE ortho scale, ONE ground line.",
                8, y0+oh+26, 1, (0.46,0.52,0.60))
out = os.path.join(root, "_d96fix_pairs.png")
G.write_png(out, sh)
print("D96FIX_SHEET " + json.dumps({"out": out, "blank": blank, "shape": list(sh.shape)}))
