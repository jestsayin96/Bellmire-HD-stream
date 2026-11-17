"""_s2_sheet - one contact sheet per family: three tiers across, three views down.

Composited with numpy inside Blender (no PIL on this machine), images read as
Non-Color so sRGB bytes round-trip. Every cell is checked for opaque pixels as
it is pasted, so a sheet cannot be built out of blanks.
"""
import os, sys, json, argparse
import bpy, numpy as np

TIERS = ["common", "uncommon", "rare"]
VIEWS = ["front", "side", "back"]


def rd(p):
    im = bpy.data.images.load(p, check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(im)
    return a


def wr(p, a):
    h, w, _ = a.shape
    im = bpy.data.images.new("out", w, h, alpha=True)
    im.colorspace_settings.name = 'Non-Color'
    im.pixels = a[::-1].ravel().tolist()
    im.filepath_raw = p
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--fams", required=True)
    ap.add_argument("--prefix", default="")
    a = ap.parse_args(argv)
    rep = {}
    for fam in a.fams.split(","):
        cells, bad = [], []
        for v in VIEWS:
            row = []
            for t in TIERS:
                p = os.path.join(a.dir, "%s%s_%s_%s.png" % (a.prefix, fam, t, v))
                img = rd(p)
                if int((img[:, :, 3] > 0.02).sum()) == 0:
                    bad.append(os.path.basename(p))
                row.append(img)
            cells.append(np.concatenate(row, axis=1))
        sheet = np.concatenate(cells, axis=0)
        bg = np.zeros_like(sheet)
        bg[:, :, :3] = 0.14
        bg[:, :, 3] = 1.0
        al = sheet[:, :, 3:4]
        out = bg * (1 - al) + np.concatenate([sheet[:, :, :3], np.ones_like(al)], axis=2) * al
        # thin rules between the nine cells
        h, w, _ = out.shape
        for x in (w // 3, 2 * w // 3):
            out[:, x - 1:x + 1, :3] = 0.45
        for y in (h // 3, 2 * h // 3):
            out[y - 1:y + 1, :, :3] = 0.45
        p = os.path.join(a.dir, "_sheet_%s%s.png" % (a.prefix, fam))
        wr(p, out)
        rep[fam] = dict(path=os.path.basename(p), size=[w, h], blank_cells=bad)
    print("SHEETS", json.dumps(rep))


main()
