"""_s2_sidefix - the before-and-after picture for fault 4, in one image.

Top row: the OLD side camera (az +90, the hero's offhand side). Bottom row:
the NEW one (az -90, the carry side). Same six weapons, same body, same frame.
The register says the old camera scored seen 0.000 on 22 of 24 cells; this is
that number as a picture, because a number that nobody looks at is how the
lane got here.
"""
import os, sys, json, argparse
import bpy, numpy as np

CELLS = ["sword_rare", "dagger_rare", "staff_rare", "crossbow_rare", "axeDouble_rare", "shield_rare"]


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
    a = ap.parse_args(argv)
    rows, blanks = [], []
    for view in ("side_offhand", "side"):
        row = []
        for c in CELLS:
            p = os.path.join(a.dir, "%s_%s.png" % (c, view))
            img = rd(p)
            if int((img[:, :, 3] > 0.02).sum()) == 0:
                blanks.append(os.path.basename(p))
            row.append(img)
        rows.append(np.concatenate(row, axis=1))
    sheet = np.concatenate(rows, axis=0)
    bg = np.zeros_like(sheet)
    bg[:, :, :3] = 0.14
    bg[:, :, 3] = 1.0
    al = sheet[:, :, 3:4]
    out = bg * (1 - al) + np.concatenate([sheet[:, :, :3], np.ones_like(al)], axis=2) * al
    h, w, _ = out.shape
    for i in range(1, len(CELLS)):
        x = w * i // len(CELLS)
        out[:, x - 1:x + 1, :3] = 0.45
    out[h // 2 - 2:h // 2 + 2, :, :3] = 0.85
    p = os.path.join(a.dir, "_sheet_sidefix.png")
    wr(p, out)
    print("SIDEFIX", json.dumps(dict(path=p, size=[w, h], cells=CELLS, blank=blanks)))


main()
